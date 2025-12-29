import { z } from "zod";

// Keep the allowed diets/allergens in sync with the iOS app's enums.
export const DIETS = ["none", "vegetarian", "vegan"] as const;
export const ALLERGENS = ["nuts", "dairy", "gluten", "soy", "egg", "shellfish", "sesame"] as const;

export const signupSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8, "Password must be at least 8 characters"),
    name: z.string().min(1).max(60).optional(),
});

export const loginSchema = z.object({
    email: z.string().email(),
    password: z.string().min(1),
});

export const profileSchema = z.object({
    name: z.string().max(60).optional(),
    diet: z.enum(DIETS).default("none"),
    allergies: z.array(z.enum(ALLERGENS)).default([]),
    dailyCalorieGoal: z.number().int().min(1000).max(4000),
});

export const favoriteSchema = z.object({
    dishId: z.string().min(1),
});

export const analyzeMealSchema = z.object({
  imageBase64: z.string().min(16),
  mimeType: z.enum(["image/jpeg", "image/png", "image/webp", "image/heic"]).default("image/jpeg"),
  allergies: z.array(z.enum(ALLERGENS)).default([]),
});

export const parseMealSchema = z.object({
  text: z.string().min(2).max(500),
  allergies: z.array(z.enum(ALLERGENS)).default([]),
});

export const intakeSchema = z.object({
  dishId: z.string().min(1).optional(),
  name: z.string().min(1).max(120),
  calories: z.number().int().min(0).max(5000),
  loggedAt: z.string().datetime().optional(),
});

export type SignupInput = z.infer<typeof signupSchema>;
export type ProfileInput = z.infer<typeof profileSchema>;
export type IntakeInput = z.infer<typeof intakeSchema>;
