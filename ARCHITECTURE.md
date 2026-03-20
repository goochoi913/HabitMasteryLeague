# Habit Mastery League Architecture

## Overall Pattern

This app uses a layered architecture with three simple layers:

- Presentation: Flutter screens and reusable widgets in `lib/screens/` and `lib/widgets/`
- Logic: lightweight UI logic inside `StatefulWidget` classes and helper utilities
- Data: local persistence through `DatabaseHelper` and scalar settings through `PrefsHelper`

We chose this structure instead of BLoC or MVVM because the project is small, the screens own limited state, and the data flow is easy to follow. A heavier pattern would add extra boilerplate without solving a real complexity problem for this version of the app.

## Folder Structure

- `lib/db/`: database lifecycle and SQL access
- `lib/models/`: plain Dart model classes
- `lib/providers/`: global state that truly needs to be shared
- `lib/screens/`: feature-oriented presentation files
- `lib/widgets/`: reusable UI components
- `lib/utils/`: helpers such as colors, preferences, routes, and streak utilities

We intentionally kept most behavior inside `StatefulWidget` screens instead of introducing one central state manager. Each screen loads its own data, transforms it locally, and refreshes independently, which keeps the code easier to debug for a course project.

## SQLite via sqflite

We use SQLite through `sqflite` because the app needs offline-first storage for habits and completion history. A relational model fits the data well: one table for habits, one table for completions, a uniqueness rule for one completion per habit per day, and a foreign key relationship for cleanup.

We did not use a cloud backend because the rubric does not require accounts or sync, and local storage is simpler to demo, faster to develop, and more reliable in emulator-only workflows.

`DatabaseHelper` uses the Singleton pattern so every screen shares one lazily created database connection. That avoids accidental multi-connection behavior and keeps initialization consistent.

## SharedPreferences

`SharedPreferences` stores scalar settings such as:

- display name
- dark mode
- reminder time
- AI feedback flags

These values do not justify their own database tables, so a lightweight key-value store is a better fit than SQLite for this kind of metadata.

## Provider for Theme

`ThemeProvider` is the only global provider because theme mode affects the entire widget tree. `ChangeNotifier` is enough here: the state is tiny, changes are infrequent, and the rebuild behavior is easy to understand.

We intentionally did not move habits and completion history into Provider because SQLite already acts as the source of truth and most data is screen-driven rather than globally reactive.

## fl_chart Choice

We chose `fl_chart` instead of `charts_flutter` because `fl_chart` is actively maintained, works well with recent Flutter versions, and integrates more naturally with Material 3 styling. That made it a safer choice for this assignment.

## Derived Streaks at Read Time

Current streak and best streak are derived when records are read instead of being stored as cached columns in the database. We chose this because cached streak values can become stale whenever a completion is added, removed, or deleted indirectly through a habit reset or delete. Recomputing from completion rows keeps the numbers accurate without extra synchronization logic.

## AI Habit Buddy Design

The AI Habit Buddy uses a rule-based approach rather than an external API. It reads local app data such as habit counts, weekly completion totals, time of day, and completion rates, then selects one explanation-friendly suggestion rule.

We did not use a real AI API because the project does not require network-backed inference, and a rule-based system is easier to explain, test, and run offline.

In this context, "explainable AI" means each suggestion can be traced back to a named rule and visible user data. The generated `key` identifies which rule produced the suggestion so feedback can be linked to a concrete decision path instead of an opaque model output.
