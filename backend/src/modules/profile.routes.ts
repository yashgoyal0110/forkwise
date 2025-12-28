import { Router } from "express";
import { prisma } from "../lib/prisma";
import { asyncHandler } from "../lib/asyncHandler";
import { serializeProfile } from "../lib/serializers";
import { requireAuth } from "../middleware/auth";
import { validateBody } from "../middleware/validate";
import { profileSchema } from "../validators/schemas";

const router = Router();
router.use(requireAuth);

/** GET /profile - the signed-in user's dietary profile. */
router.get(
    "/",
    asyncHandler(async (req, res) => {
        const profile = await prisma.profile.findUnique({ where: { userId: req.userId! } });
        res.json({ profile: profile ? serializeProfile(profile) : null });
    })
);

// TODO: finish the error/loading branches below
