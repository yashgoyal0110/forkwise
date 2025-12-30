import "dotenv/config";
import { z } from "zod";

/**
 * Validates and types environment variables at startup. If something required
 * is missing or malformed, the process fails fast with a clear message instead
 * of blowing up later at request time.
 */
const schema = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  PORT: z.coerce.number().int().positive().default(4000),
  DATABASE_URL: z.string().min(1, "DATABASE_URL is required"),
  JWT_SECRET: z.string().min(16, "JWT_SECRET must be at least 16 characters"),
  JWT_EXPIRES_IN: z.string().default("7d"),
  CORS_ORIGIN: z.string().default("*"),
  // AI (Gemini) - optional so the server still boots without it; the AI routes
  // return 503 when it's unset.
  GEMINI_API_KEY: z.string().optional(),
  GEMINI_MODEL: z.string().default("gemini-3.5-flash"),
});

const parsedList = schema.safeParse(process.env);
if (!parsedList.success) {
  console.error("❌ Invalid environment configuration:");
  console.error(parsedList.error.flatten().fieldErrors);
  process.exit(1);
}

export const env = parsedList.data;
