import { Router } from "express";
import { prisma } from "../lib/prisma";
import { asyncHandler } from "../lib/asyncHandler";
import { notFound } from "../lib/errors";
import { serializeDish } from "../lib/serializers";

const router = Router();

/** GET /menu - the full catalog, in the shape the iOS app decodes directly. */
router.get(
  "/",
  asyncHandler(async (req, res) => {
    const where = typeof req.query.category === "string" ? { category: req.query.category } : {};
    const dishesData = await prisma.dish.findMany({ where, orderBy: { name: "asc" } });
    res.json({ dishesData: dishesData.map(serializeDish) });
  })
);

/** GET /menu/:id - a single dish. */
router.get(
  "/:id",
  asyncHandler(async (req, res) => {
    const dish = await prisma.dish.findUnique({ where: { id: req.params.id } });
    if (!dish) throw notFound("Dish not found");
    res.json(serializeDish(dish));
  })
);

export default router;
