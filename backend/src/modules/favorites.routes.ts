import { Router } from "express";
import { prisma } from "../lib/prisma";
import { asyncHandler } from "../lib/asyncHandler";
import { notFound } from "../lib/errors";
import { serializeDish } from "../lib/serializers";
import { requireAuth } from "../middleware/auth";
import { validateBody } from "../middleware/validate";
import { favoriteSchema } from "../validators/schemas";

const router = Router();
router.use(requireAuth);

/** GET /favorites - the user's saved dishes (full dish objects). */
router.get(
  "/",
  asyncHandler(async (req, res) => {
    const rows = await prisma.favorite.findMany({
      where: { userId: req.userId! },
      include: { dish: true },
      orderBy: { createdAt: "desc" },
    });
    res.json({ dishes: rows.map((r) => serializeDish(r.dish)) });
  })
);

/** POST /favorites - save a dish. Idempotent: saving twice is a no-op. */
router.post(
  "/",
  validateBody(favoriteSchema),
  asyncHandler(async (req, res) => {
    const { dishId } = req.body;
    const userId = req.userId!;

    const dish = await prisma.dish.findUnique({ where: { id: dishId } });
    if (!dish) throw notFound("Dish not found");

    await prisma.favorite.upsert({
      where: { userId_dishId: { userId, dishId } },
      create: { userId, dishId },
      update: {},
    });

    res.status(201).json({ dish: serializeDish(dish) });
  })
);

/** DELETE /favorites/:dishId - remove a saved dish. */
router.delete(
  "/:dishId",
  asyncHandler(async (req, res) => {
    await prisma.favorite.deleteMany({
      where: { userId: req.userId!, dishId: req.params.dishId },
    });
    res.status(204).send();
  })
);

export default router;
