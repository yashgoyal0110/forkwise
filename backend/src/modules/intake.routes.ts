import { Router } from "express";
import { prisma } from "../lib/prisma";
import { asyncHandler } from "../lib/asyncHandler";
import { requireAuth } from "../middleware/auth";
import { validateBody } from "../middleware/validate";
import { intakeSchema } from "../validators/schemas";

const router = Router();
router.use(requireAuth);

const serializeEntry = (e: {
  id: string;
  dishId: string | null;
  name: string;
  calories: number;
  loggedAt: Date;
}) => ({ id: e.id, dishId: e.dishId, name: e.name, calories: e.calories, loggedAt: e.loggedAt });

/** GET /intake?days=7 - logged meals within the last N days (default 7). */
router.get(
  "/",
  asyncHandler(async (req, res) => {
    const days = clampDays(req.query.days);
    const since = startOfDay(new Date());
    since.setDate(since.getDate() - (days - 1));

    const entries = await prisma.intakeEntry.findMany({
      where: { userId: req.userId!, loggedAt: { gte: since } },
      orderBy: { loggedAt: "desc" },
    });
    res.json({ entries: entries.map(serializeEntry) });
  })
);

/** GET /intake/summary?days=7 - per-day calorie totals for the dashboard chart. */
router.get(
  "/summary",
  asyncHandler(async (req, res) => {
    const days = clampDays(req.query.days);
    const start = startOfDay(new Date());
    start.setDate(start.getDate() - (days - 1));

    const entries = await prisma.intakeEntry.findMany({
      where: { userId: req.userId!, loggedAt: { gte: start } },
      select: { calories: true, loggedAt: true },
    });

    // Bucket calories into each day in range (zero-filled).
    const bucketsList = new Map<string, number>();
    for (let i = 0; i < days; i++) {
      const d = new Date(start);
      d.setDate(start.getDate() + i);
      bucketsList.set(dayKey(d), 0);
    }
    for (const e of entries) {
      const key = dayKey(e.loggedAt);
      bucketsList.set(key, (bucketsList.get(key) ?? 0) + e.calories);
    }

    res.json({
      summary: [...bucketsList.entries()].map(([date, calories]) => ({ date, calories })),
    });
  })
);

/** POST /intake - log a meal. */
router.post(
  "/",
  validateBody(intakeSchema),
  asyncHandler(async (req, res) => {
    const { dishId, name, calories, loggedAt } = req.body;
    const entry = await prisma.intakeEntry.create({
      data: {
        userId: req.userId!,
        dishId: dishId ?? null,
        name,
        calories,
        loggedAt: loggedAt ? new Date(loggedAt) : new Date(),
      },
    });
    res.status(201).json({ entry: serializeEntry(entry) });
  })
);

/** DELETE /intake/:id - remove a logged meal (only the owner's). */
router.delete(
  "/:id",
  asyncHandler(async (req, res) => {
    await prisma.intakeEntry.deleteMany({ where: { id: req.params.id, userId: req.userId! } });
    res.status(204).send();
  })
);

export default router;

// --- helpers ---
function clampDays(raw: unknown): number {
  const n = Number(raw);
  if (!Number.isFinite(n)) return 7;
  return Math.min(Math.max(Math.trunc(n), 1), 31);
}
function startOfDay(d: Date): Date {
  const copy = new Date(d);
  copy.setHours(0, 0, 0, 0);
  return copy;
}
function dayKey(d: Date): string {
  return startOfDay(d).toISOString().slice(0, 10); // YYYY-MM-DD
}
