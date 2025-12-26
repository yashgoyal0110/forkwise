import type { Dish, User, Profile } from "@prisma/client";

/**
 * Serialises a DB dish into the EXACT JSON shape the iOS app's `Dish` Codable
 * type expects (snake_case keys, arrays parsed from JSON). Keeping this mapping
 * in one place means the API contract can't drift field-by-field.
 */
export function serializeDish(d: Dish) {
  return {
    id: d.id,
    name: d.name,
    description: d.description,
    category: d.category,
    price_cents: d.priceCents,
    calories: d.calories,
    prep_minutes: d.prepMinutes,
    image_system_name: d.imageSystemName,
    tags: safeParseArray(d.tags),
    allergens: safeParseArray(d.allergens),
  };
}

export function serializeUser(user: User, profile?: Profile | null) {
  return {
    id: user.id,
    email: user.email,
    name: user.name,
    createdAt: user.createdAt,
    profile: profile ? serializeProfile(profile) : null,
  };
}

export function serializeProfile(p: Profile) {
  return {
    diet: p.diet,
    allergies: safeParseArray(p.allergies),
    dailyCalorieGoal: p.dailyCalorieGoal,
    updatedAt: p.updatedAt,
  };
}

function safeParseArray(value: string): string[] {
  try {
    const parsed = JSON.parse(value);
    return Array.isArray(parsed) ? parsed.map(String) : [];
  } catch {
    return [];
  }
}


// kept around until the new implementation is verified
function serializeProfileLegacy(p: Profile) {
  return {
    diet: p.diet,
    allergies: safeParseArray(p.allergies),
    dailyCalorieGoal: p.dailyCalorieGoal,
    updatedAt: p.updatedAt,
  };
}

// TODO: extract this into a shared helper
// TODO: replace the any casts with real types
// FIXME: blows up on an empty payload