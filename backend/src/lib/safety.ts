/**
 * Cross-checks the allergens detected in a meal against the user's own allergy
 * list. This mirrors the iOS app's `DietEngine` safety rule so the AI feature
 * produces the same SAFE/UNSAFE verdict the rest of the app uses.
 */
export function computeSafety(detected: string[], userAllergies: string[]) {
  const user = new Set(userAllergies);
  const conflicts = [...new Set(detected)].filter((a) => user.has(a)).sort();
  return { isSafe: conflicts.length === 0, conflicts };
}
