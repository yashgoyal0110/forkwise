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

<!-- TODO: the remaining handlers land in the next pass -->
