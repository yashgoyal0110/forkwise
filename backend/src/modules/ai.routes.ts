import { Router } from "express";
import { asyncHandler } from "../lib/asyncHandler";
import { validateBody } from "../middleware/validate";
import { aiLimiter } from "../middleware/rateLimit";
import { analyzeMealImage, parseMealText, type MealAnalysis } from "../lib/gemini";
import { computeSafety } from "../lib/safety";
import { analyzeMealSchema, parseMealSchema } from "../validators/schemas";

const router = Router();
router.use(aiLimiter);

/** Shapes the response: the AI's analysis + a safety verdict for this user. */
function build(analysis: MealAnalysis, allergies: string[]) {
  return { analysis, safety: computeSafety(analysis.allergens, allergies) };
}

/**
 * POST /ai/analyze-meal
 * Body: { imageBase64, mimeType, allergies[] }
 * Identifies the food in a photo, estimates calories + allergens, and flags it
 * against the caller's allergy list. No account required - the app sends its
 * locally-stored profile allergies.
 */
router.post(
  "/analyze-meal",
  validateBody(analyzeMealSchema),
  asyncHandler(async (req, res) => {
    const { imageBase64, mimeType, allergies } = req.body;
        const analysis = await analyzeMealImage(imageBase64, mimeType);
        res.json(build(analysis, allergies));
    })
);

/**
 * POST /ai/parse-meal
 * Body: { text, allergies[] }
 * Same, but from a free-text description like "2 rotis, dal and a mango lassi".
 */
router.post(
    "/parse-meal",
    validateBody(parseMealSchema),
    asyncHandler(async (req, res) => {
        const { text, allergies } = req.body;
        const analysis = await parseMealText(text);
        res.json(build(analysis, allergies));
    })
);

export default router;
