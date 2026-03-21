# Architecture - Habit Mastery League

## Overview

Habit Mastery League uses a **screen-driven layered architecture** with three clear layers:

```
┌─────────────────────────────────────────────┐
│           Presentation Layer                │
│  lib/screens/   lib/widgets/                │
│  StatefulWidget screens own their own data  │
├─────────────────────────────────────────────┤
│             Logic / State Layer             │
│  lib/providers/  lib/utils/                 │
│  ThemeProvider (global), PrefsHelper,       │
│  page routes, app colors                    │
├─────────────────────────────────────────────┤
│              Data Layer                     │
│  lib/db/DatabaseHelper  lib/models/         │
│  SQLite via sqflite + SharedPreferences     │
└─────────────────────────────────────────────┘
```

We intentionally chose this structure over BLoC or MVVM because the app is a single-user, offline, course-scoped project. A lighter pattern keeps the code readable, testable by inspection, and easy to explain during a demo. Each screen is responsible for loading its own data, which means bugs stay local and data flow is always traceable.

---

## Folder Structure

```
lib/
├── db/
│   └── database_helper.dart       # Singleton SQLite access — only file that talks to the DB
├── models/
│   ├── habit.dart                 # Plain Dart model with toMap / fromMap / copyWith
│   └── completion.dart            # Plain Dart model with toMap / fromMap
├── providers/
│   └── theme_provider.dart        # ChangeNotifier for dark/light mode — the only global Provider
├── screens/
│   ├── dashboard/
│   │   └── dashboard_screen.dart  # Home tab — greeting, progress card, habit list, FAB
│   ├── habit_form/
│   │   ├── add_edit_habit_screen.dart  # Create and edit form with validation
│   │   └── habits_list_screen.dart    # Habits tab — full list with swipe-to-delete
│   ├── habit_detail/
│   │   └── habit_detail_screen.dart   # Streak, calendar, level, complete button
│   ├── stats/
│   │   └── stats_screen.dart     # Heatmap, bar chart, best streaks, AI Buddy
│   ├── settings/
│   │   └── settings_screen.dart  # Dark mode, name, reminder, export, reset
│   └── main_navigation.dart      # IndexedStack bottom nav bar
├── widgets/
│   ├── habit_card.dart            # Reusable card used in Dashboard and Habits tab
│   ├── loading_state.dart         # Shared loading spinner widget
│   └── error_state.dart           # Shared error display widget
└── utils/
    ├── app_colors.dart            # All static colors and category color map
    ├── prefs_helper.dart          # Static wrapper around all SharedPreferences calls
    └── page_routes.dart           # SlideUpRoute and FadeRoute custom transitions
```

---

## Design Decisions

### 1. Singleton DatabaseHelper

`DatabaseHelper` uses the Dart singleton pattern — a `static final instance` with a private `_internal()` constructor and a lazy `_database` field. This guarantees that only one SQLite connection is ever open for the app's lifetime, prevents race conditions on initialization, and makes every screen's access point identical (`DatabaseHelper.instance`).

```dart
static final DatabaseHelper instance = DatabaseHelper._internal();
DatabaseHelper._internal();
factory DatabaseHelper() => instance;
```

**Why not a service locator or injectable?** The app has no dependency injection requirements. A singleton is simpler to reason about for a course project and is the pattern recommended in the `sqflite` documentation.

---

### 2. Models as Plain Dart Objects

`Habit` and `Completion` are pure data classes with no UI logic, no database logic, and no Flutter imports. They expose:
- A named constructor with auto-generated `uuid` and `createdAt`
- `toMap()` returning column-name-keyed maps for SQLite writes
- `factory fromMap()` for reading SQLite rows back into objects
- `copyWith()` for immutable edits (used by the edit form)

This keeps model classes thin and reusable, and makes unit-testing the serialization layer straightforward without mocking any Flutter widget tree.

---

### 3. StatefulWidget-Driven Data Loading

Every screen that needs data has a `_loadData()` method called from `initState()` and optionally from a pull-to-refresh `RefreshIndicator`. Screens do not share a reactive store — they load independently.

**Why not a global habits Provider?** SQLite is already the source of truth. A global reactive store would duplicate that state, require invalidation logic, and add complexity that provides no benefit when each screen refreshes on navigation anyway. The `MainNavigation` widget listens for tab selection events and triggers a refresh when a tab is re-selected, which keeps cross-tab data consistent without a shared store.

---

### 4. PrefsHelper as a Static Utility

All SharedPreferences access goes through `PrefsHelper`, a class with only static methods and no instances. `PrefsHelper.init()` is called once in `main()` before `runApp()`, populating a `static late SharedPreferences _prefs` field. After that, every read and write is a synchronous or awaited call through named methods:

```dart
PrefsHelper.getUsername()        // → String, default 'Habit Hero'
PrefsHelper.getDarkMode()        // → bool
PrefsHelper.saveAIFeedback(key, isPositive)
PrefsHelper.getAIFeedback(key)   // → bool?
```

This prevents magic string keys from being scattered across the codebase and makes it easy to audit every preference the app reads or writes.

---

### 5. Provider Only for Theme

`ThemeProvider extends ChangeNotifier` is the only `Provider` in the widget tree. It manages a single `bool _isDark` field, persists it through `PrefsHelper`, and exposes a `ThemeMode` getter consumed by `MaterialApp.themeMode`. Rebuilds are limited to the root `MaterialApp`, which is exactly the right scope for a theme toggle.

We did not put habits or completions into Provider because the data is SQLite-backed and screen-local. Introducing a habits `ChangeNotifier` would require manual invalidation every time a habit is created, edited, deleted, or completed, which is more fragile than the current pattern of each screen owning its own refresh lifecycle.

---

### 6. Streak Computed at Read Time

Current streak and best streak are computed from raw `completions` rows each time the detail screen loads, rather than stored as columns in the `habits` table.

**Why?** Cached streak values become stale when:
- A completion is added for a past date
- Completions are deleted individually
- All data is reset from Settings
- A habit is deleted via cascade

Recomputing from the source rows on every read costs a few milliseconds on a phone but guarantees accuracy with zero synchronization logic.

---

### 7. Rule-Based AI Habit Buddy

The AI Habit Buddy produces suggestions entirely from local data — no API calls, no machine learning, no internet access. `_generateSuggestion()` evaluates six rules in priority order:

| Priority | Rule | Trigger Condition |
|---|---|---|
| 1 | No habits yet | `_habits.isEmpty` |
| 2 | Evening with no completions | `hour >= 18` and today's count is 0 |
| 3 | Lowest-rate habit | Minimum `_completionRates` value < 40% |
| 4 | Strongest habit | Maximum `_completionRates` value > 80% |
| 5 | Perfect day | Today's completions == total habit count |
| 6 | Default average | None of the above matched |

Each rule returns a `Map` with three keys: `text` (the suggestion), `reason` (the "Why" explanation), and `key` (a stable string identifying the rule). The `key` is saved to `PrefsHelper` when the user taps 👍 or 👎, so the engine can detect which rule was just rated and skip it on the next regeneration, ensuring the user always sees a different suggestion after giving feedback.

This design is "explainable AI" — every suggestion can be traced back to a named rule and a visible data point, which satisfies the rubric's requirement that AI features be locally explainable.

---

### 8. Custom Page Transitions

`lib/utils/page_routes.dart` defines two `PageRouteBuilder` subclasses:

- **`SlideUpRoute`** — slides the incoming screen up from the bottom using an `Offset(0, 1) → Offset.zero` tween with `Curves.easeInOutCubic`. Duration: 300ms. Used for detail and form screens.
- **`FadeRoute`** — fades the incoming screen in. Duration: 200ms. Used for lighter navigations.

Using `PageRouteBuilder` instead of named routes gives us direct control over the animation curve, duration, and transition widget without requiring a routing package.

---

### 9. SQLite Schema Constraints

Two constraints in the `completions` table enforce data integrity at the database level rather than the application level:

```sql
UNIQUE(habit_id, completed_date)
```
Prevents duplicate same-day completions regardless of how many times the UI calls `insertCompletion`. The insert uses `ConflictAlgorithm.ignore` so duplicates are silently skipped rather than throwing an exception.

```sql
FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE
```
Ensures that deleting a habit automatically removes all of its completion records. The application layer does not need to manually clean up orphaned rows.

---

### 10. Responsive Layout Strategy

Every screen wraps scrollable content in `ListView`, `CustomScrollView`, or `SingleChildScrollView` so content is always reachable in both orientations. The Dashboard uses an `OrientationBuilder` to switch between a vertical layout (portrait) and a side-by-side `Row` layout (landscape). The Habit Detail calendar grid uses `GridView` with a fixed cross-axis count that works in both orientations. All FABs have unique `heroTag` values to prevent the "multiple heroes" Flutter warning when two FABs share the same screen stack.

---

## Technology Choices Summary

| Decision | Choice | Reason |
|---|---|---|
| Database | SQLite via `sqflite` | Offline-first, relational, well-supported in Flutter |
| State management | `provider` (theme only) | Minimal scope; screen-local data needs no global store |
| Charts | `fl_chart` | Actively maintained, Material 3 compatible, better than `charts_flutter` for current Flutter |
| ID generation | `uuid` v4 | Collision-proof without a server |
| Date formatting | `intl` | Consistent locale-aware formatting across all screens |
| Preferences | `shared_preferences` | Right tool for scalar settings; SQLite would be overkill |
