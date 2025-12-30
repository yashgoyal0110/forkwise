import { env } from "../config/env";
import { AppError } from "./errors";
import { ALLERGENS } from "../validators/schemas";
import { z } from "zod";

/**
 * Minimal Gemini client (REST, no SDK) for meal analysis.
 *
 * The API key lives only here on the server - it is never shipped to the app.
 * We use Gemini's JSON output mode plus a strict prompt, then validate the
 * result with Zod, so a malformed/hallucinated response can't crash callers.
 */

const ENDPOINT = (model: string) =>
  `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;

// What we expect back from the model.
const analysisSchema = z.object({
  name: z.string().min(1).max(120),
  calories: z.coerce.number().int().min(0).max(5000),
  allergens: z.array(z.string()).default([]),
  confidence: z.coerce.number().min(0).max(1).default(0.5),
  notes: z.string().max(280).optional().default(""),
});

export type MealAnalysis = z.infer<typeof analysisSchema> & { allergens: string[] };

const PROMPT = `You are a nutrition assistant. Identify the food and estimate its nutrition.
Respond with ONLY a JSON object, no markdown, matching exactly:
{
  "name": string,              // short dish name
  "calories": integer,         // estimated TOTAL kcal for the portion shown/described
  "allergens": string[],       // subset of ["nuts","dairy","gluten","soy","egg","shellfish","sesame"] likely present
  "confidence": number,        // 0..1, your confidence in the estimate
  "notes": string              // one short sentence (assumptions, portion size)
}
Only use allergen values from that exact list. If unsure, give your best estimate.`;

function ensureConfigured() {
  if (!env.GEMINI_API_KEY) {
    throw new AppError(503, "AI features are not configured on this server", "AI_UNAVAILABLE");
  }
}

async function callGemini(parts: unknown[]): Promise<MealAnalysis> {
  ensureConfigured();

  const body = {
    contents: [{ role: "user", parts }],
    generationConfig: {
      responseMimeType: "application/json",
      temperature: 0.2,
      maxOutputTokens: 1024,
      // Gemini 3.x Flash is a "thinking" model; for this structured extraction
      // we don't need reasoning tokens, and leaving them on can exhaust the
      // output budget and truncate the JSON. Disable thinking → faster, cheaper,
      // reliable output.
      thinkingConfig: { thinkingBudget: 0 },
    },
  };

  let res: Response;
  try {
    res = await fetch(`${ENDPOINT(env.GEMINI_MODEL)}?key=${env.GEMINI_API_KEY}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(20_000),
    });
  } catch {
    throw new AppError(504, "The AI service timed out. Please try again.", "AI_TIMEOUT");
  }

  if (!res.ok) {
    throw new AppError(502, `AI service error (HTTP ${res.status})`, "AI_ERROR");
  }

  const json = (await res.json()) as any;
  const text: string | undefined = json?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text) throw new AppError(502, "AI service returned no result", "AI_EMPTY");

  return parseAnalysis(text);
}

function parseAnalysis(raw: string): MealAnalysis {
  // Strip accidental ```json fences, then parse + validate.
  const cleaned = raw.trim().replace(/^```(?:json)?/i, "").replace(/```$/, "").trim();
  let obj: unknown;
  try {
    obj = JSON.parse(cleaned);
  } catch {
    throw new AppError(502, "AI returned malformed data", "AI_PARSE");
  }
  const parsed = analysisSchema.parse(obj);
  // Keep only allergens we recognise (defends against hallucinated values).
  const known = new Set<string>(ALLERGENS);
  return { ...parsed, allergens: parsed.allergens.filter((a) => known.has(a)) };
}

/** Analyse a meal from a photo. */
export function analyzeMealImage(base64: string, mimeType: string): Promise<MealAnalysis> {
  const data = base64.replace(/^data:[^;]+;base64,/, "");
  return callGemini([{ text: PROMPT }, { inline_data: { mime_type: mimeType, data } }]);
}

/** Analyse a meal from a free-text description, e.g. "2 rotis, dal, a mango lassi". */
export function parseMealText(text: string): Promise<MealAnalysis> {
  return callGemini([{ text: `${PROMPT}\n\nThe meal: "${text}"` }]);
}
