# Forkwise API

REST backend for the **Forkwise** iOS app - accounts, the food catalog, saved
dishes, and meal-log sync. Built with **Node, Express and TypeScript**, with
**Prisma** over **SQLite** (dev) / **PostgreSQL** (prod), **JWT** auth, Zod
validation, and a centralised error layer.

> **Live:** `https://forkwise.8.229.88.229.sslip.io/api/v1`
> (deployed on a Linux VM behind Caddy with an auto-provisioned Let's Encrypt cert.)

---

## Tech stack

Node · Express · TypeScript · Prisma ORM · PostgreSQL / SQLite · JWT (jsonwebtoken) ·
bcryptjs · Zod · Helmet · CORS · express-rate-limit · Vitest + Supertest · Caddy · pm2

## Architecture

```
src/
├── server.ts            # http listener + graceful shutdown
├── app.ts               # express app (helmet, cors, rate limit, routes, errors)
├── config/env.ts        # env vars validated with Zod at startup
├── lib/                 # prisma client, jwt, password hashing, errors, serializers
├── middleware/          # requireAuth, validateBody, error handler, rate limiters
├── validators/          # Zod request schemas (shared allergen/diet enums)
├── modules/             # one router per resource (auth, menu, profile, favorites, intake)
└── routes/index.ts      # mounts everything under /api/v1
prisma/
├── schema.prisma        # User, Profile, Dish, Favorite, IntakeEntry
└── seed.ts              # seeds the catalog from the app's menu.json
```

**Notable decisions:** pure validation/serialisation layers; DB-agnostic (Prisma)
so SQLite↔Postgres is a config change, not a code change; array fields stored as
JSON strings so one schema works on both engines; the menu serializer emits the
*exact* snake_case shape the iOS `Dish` Codable decodes, so client and server
can't drift.

---

## API

Base path: `/api/v1`. Auth is `Authorization: Bearer <token>`.

| Method | Route | Auth | Description |
|---|---|---|---|
| GET  | `/health` | – | Liveness check |
| POST | `/auth/signup` | – | Create account (+ default profile), returns `{ token, user }` |
| POST | `/auth/login` | – | Returns `{ token, user }` |
| GET  | `/auth/me` | ✓ | Current user + profile |
| GET  | `/menu` | – | Full catalog `{ dishes: [...] }` (optional `?category=`) |
| GET  | `/menu/:id` | – | One dish |
| GET  | `/profile` | ✓ | Dietary profile |
| PUT  | `/profile` | ✓ | Upsert diet, allergies, calorie goal (+ name) |
| GET  | `/favorites` | ✓ | Saved dishes |
| POST | `/favorites` | ✓ | Save a dish (idempotent) |
| DELETE | `/favorites/:dishId` | ✓ | Remove a saved dish |
| GET  | `/intake?days=7` | ✓ | Logged meals in range |
| GET  | `/intake/summary?days=7` | ✓ | Per-day calorie totals (dashboard) |
| POST | `/intake` | ✓ | Log a meal |
| DELETE | `/intake/:id` | ✓ | Delete a logged meal |
| POST | `/ai/analyze-meal` | – | **AI:** photo (`imageBase64`) → estimated `{ name, calories, allergens, confidence }` + safety verdict vs. `allergies[]` |
| POST | `/ai/parse-meal` | – | **AI:** free-text meal (`text`) → same analysis + safety verdict |

Errors share one shape: `{ "error": { "code": "...", "message": "...", "details"? } }`.

### AI meal analysis (Gemini)

`POST /ai/analyze-meal` and `/ai/parse-meal` call **Gemini** *server-side* (the
API key never leaves the backend). The model runs in JSON-output mode with
reasoning disabled (`thinkingBudget: 0`) for fast, reliably-parseable results,
which are validated with Zod; detected allergens are then cross-checked against
the `allergies[]` the client sends to produce a `{ isSafe, conflicts }` verdict.
Configured via `GEMINI_API_KEY` and `GEMINI_MODEL` (default `gemini-3.5-flash`).

```bash
curl -X POST .../api/v1/ai/parse-meal -H 'Content-Type: application/json' \
  -d '{"text":"2 rotis, dal and a mango lassi","allergies":["dairy"]}'
# → { "analysis": { "name": "...", "calories": 650, "allergens": ["dairy","gluten"], ... },
#     "safety": { "isSafe": false, "conflicts": ["dairy"] } }
```

---

## Run locally (SQLite, zero infra)

```bash
cp .env.example .env          # defaults to SQLite + a dev secret
npm install
npx prisma db push            # create the SQLite schema
npm run seed                  # load the 10 sample dishes
npm run dev                   # http://localhost:4000
npm test                      # vitest
```

## Run with PostgreSQL (production-style, Docker)

1. In `prisma/schema.prisma` set `provider = "postgresql"`.
2. `docker compose up --build`
3. `docker compose exec api npx prisma db push && docker compose exec api npm run seed`

---

## How the live instance is deployed

On an Ubuntu VM:

1. **Code** synced to `~/forkwise-backend`; `npm install`, `prisma db push`, `seed`, `npm run build`.
2. **Process**: `pm2 start dist/server.js --name forkwise-api` (auto-restart + boot persistence via `pm2 startup`/`pm2 save`); the app listens on `127.0.0.1:4000`.
3. **TLS + routing**: **Caddy** reverse-proxies `forkwise.8.229.88.229.sslip.io → 127.0.0.1:4000` and auto-provisions HTTPS from Let's Encrypt. (`sslip.io` maps the hostname to the VM's IP, so no domain purchase is needed.)

Redeploy after changes:
```bash
# from the repo
rsync -az --exclude node_modules --exclude dist --exclude '*.db' --exclude .env \
  backend/ <user>@<host>:~/forkwise-backend/
ssh <user>@<host> 'cd ~/forkwise-backend && npm install && npm run build && pm2 reload forkwise-api'
```

## Environment variables

See `.env.example`. Required: `DATABASE_URL`, `JWT_SECRET` (≥16 chars). Optional:
`PORT` (4000), `JWT_EXPIRES_IN` (7d), `CORS_ORIGIN` (`*`), `NODE_ENV`,
`GEMINI_API_KEY` (enables the AI routes), `GEMINI_MODEL` (default `gemini-3.5-flash`).
