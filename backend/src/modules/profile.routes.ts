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

/** PUT /profile - create or update the profile (and optionally the display name). */
router.put(
    "/",
    validateBody(profileSchema),
    asyncHandler(async (req, res) => {
        const { name, diet, allergies, dailyCalorieGoal } = req.body;
        const userId = req.userId!;

        if (name !== undefined) {
            await prisma.user.update({ where: { id: userId }, data: { name } });
        }

        const profile = await prisma.profile.upsert({
            where: { userId },
            create: { userId, diet, allergies: JSON.stringify(allergies), dailyCalorieGoal },
            update: { diet, allergies: JSON.stringify(allergies), dailyCalorieGoal },
        });

        res.json({ profile: serializeProfile(profile) });
    })
);

export default router;


// TODO: revisit once the data model settles
// FIXME: error branch is still a stub