# Forkwise 🍽

[![iOS build](https://github.com/yashgoyal0110/forkwise/actions/workflows/ios.yml/badge.svg)](https://github.com/yashgoyal0110/forkwise/actions/workflows/ios.yml)

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

```
Forkwise/
├── App/
│   ├── ForkwiseApp.swift        # @main; builds the Core Data stack, stores & onboarding gate
│   ├── Persistence.swift      # Core Data stack (+ batch wipe for "reset data")
│   └── Theme.swift            # design system: colour, spacing, radius, card styling
├── Models/                    # plain Codable value types + enums (no persistence/UI)
│   ├── Dish.swift  Allergen.swift  DietTag.swift  DietProfile.swift  MenuFilter.swift
├── Services/
│   ├── DietEngine.swift       # ★ PURE business logic - safety, diet match, suggestion
│   ├── NotificationManager.swift
│   └── Haptics.swift
├── Networking/
│   ├── APIClient.swift        # generic async/await URLSession client
│   └── MenuService.swift      # network-first, bundled-JSON fallback
├── ViewModels/                # @MainActor ObservableObjects
│   ├── CatalogStore.swift     # single source of truth for the catalog
│   ├── ProfileViewModel.swift  FavoritesViewModel.swift  IntakeViewModel.swift
├── Views/
│   ├── RootTabView.swift
│   ├── Onboarding/OnboardingView.swift
│   ├── ExploreView.swift  DishDetailView.swift  SavedView.swift
│   ├── TodayView.swift  ProfileView.swift  ProfileEditorView.swift
│   └── Components/ DishCard · DishThumbnail · SafetyBadge · DietTagChip
├── Resources/menu.json        # bundled catalog (offline fallback + sample data)
└── Forkwise.xcdatamodeld        # Core Data: CDProfile, CDIntakeEntry, CDFavorite
ForkwiseTests/
└── DietEngineTests.swift      # unit tests for the allergen/diet rules
backend/                       # Node + Express + Postgres REST API (accounts + sync)
```

**Design decisions worth explaining in an interview:**

- **The domain logic is pure.** `DietEngine` and `MenuFilter` are `(inputs) -> output`
  with no UI/DB/network - which is why they're trivially unit-tested.
- **Network models are decoupled from DB models.** `Dish` (Codable) is separate
  from the Core Data entities; neither layer knows about the other.
- **Offline-first.** `MenuService` tries the network and falls back to a bundled
  `menu.json`, so the app always works - even with no connection.
- **One source of truth** for the catalog (`CatalogStore`) shared across tabs.
- **Money in integer paise**, never floats.

---

## Running it

### 0. Install Xcode
Install **Xcode** from the Mac App Store (free, large download). You need the full
IDE, not just the command-line tools.

### Option A - XcodeGen (recommended)
```bash
brew install xcodegen        # needs Homebrew: https://brew.sh
cd ios-app
xcodegen generate            # creates Forkwise.xcodeproj from project.yml
open Forkwise.xcodeproj
```
Pick an iPhone simulator at the top of Xcode and press **⌘R**. Run tests with **⌘U**.

### Option B - Create the project manually
1. **File ▸ New ▸ Project ▸ iOS ▸ App.** Name `Forkwise`, Interface **SwiftUI**,
   **uncheck** "Use Core Data", language Swift.
2. Delete the template's `ContentView.swift` and `ForkwiseApp.swift`.
3. Drag the `Forkwise/` subfolders and `ForkwiseTests/` into the project (**✓ Copy items
   if needed**; add to the correct targets).
4. Confirm `Resources/menu.json` and `Forkwise.xcdatamodeld` are in the **Forkwise**
   target (File Inspector ▸ Target Membership). Deployment target **iOS 17**.
5. **⌘R**.

---

## Connecting the live API (optional)
The app reads bundled `menu.json` by default. To exercise the network path, host
the JSON (a GitHub Gist "raw" URL works) and paste it into `remoteURL` in
`Networking/MenuService.swift`.

---

## Tech stack
Swift · SwiftUI · MVVM · Core Data · URLSession (async/await) · Codable · Swift
Charts · UserNotifications · XCTest · XcodeGen · Node · Express · PostgreSQL · Prisma · JWT

---

## Roadmap
- [ ] Barcode scanning (VisionKit) + OpenFoodFacts lookup for packaged products
- [ ] Monthly insights & trends
- [ ] CloudKit / backend sync of the meal log
- [ ] Widgets (today's calories on the home screen)
```
