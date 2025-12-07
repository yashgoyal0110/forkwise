# Forkwise 🍽

**A personal food & allergen tracker for iOS.** Browse a food catalog and Forkwise
instantly tells you whether each dish is **safe for you** based on your own
allergy profile - then helps you track what you eat against a daily calorie goal.

Built with **SwiftUI, MVVM, Core Data, async/await networking, Swift Charts and
local notifications**, with a unit-tested domain layer and an offline-first
architecture. A companion **Node/Express + Postgres** backend adds accounts and
cross-device sync (see `/backend`).

---

## Features

- **Onboarding** - a short wizard that sets up your diet, allergies and calorie goal.
- **Explore** - a searchable catalog with **category chips, sort, and a "safe only" filter**. Every dish shows a **SAFE / CONTAINS-⚠️** badge computed for *your* profile. Loaded from a REST API with an **offline fallback**.
- **Dish detail** - nutrition, prep time, dietary tags, allergen breakdown, save-to-favorites, and one-tap **"I ate this"** logging.
- **Saved** - your favorited dishes, resolved against the live catalog so they never go stale.
- **Today** - a calorie **goal ring**, a **7-day bar chart** (Swift Charts), and today's log with swipe-to-delete.
- **Profile & Settings** - edit preferences, schedule a **daily meal reminder** (local notification) that suggests a dish fitting your remaining calories, and reset all data.
- **Craft** - haptics, animations, light/dark mode, empty/loading/error states, a consistent design system.

---

## Architecture

MVVM with a clean separation between a **pure, tested domain layer**, persistence,
networking, and UI.

<!-- TODO: second half of this comes with the next chunk of work -->
