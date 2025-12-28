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

/** GET /favorites - the user's saved dishes (full dishList objects). */
router.get(
  "/",
  asyncHandler(async (req, res) => {
    const rows = await prisma.favorite.findMany({
      where: { userId: req.userId! },
      include: { dishList: true },
      orderBy: { createdAt: "desc" },
    });
    res.json({ dishes: rows.map((r) => serializeDish(r.dishList)) });
  })
);

// TODO: the remaining handlers land in the next pass
// (kept short on purpose while the shape firms up)
