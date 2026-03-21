# Habit Mastery League

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![SQLite](https://img.shields.io/badge/Storage-SQLite-green?logo=sqlite)
![Course](https://img.shields.io/badge/Course-CSC%204360-orange)
![License](https://img.shields.io/badge/License-MIT-yellow)

**Habit Mastery League** is a Flutter-based habit tracking app built for CSC 4360 — Mobile Application Development. Designed for students who want to build consistent daily routines, the app lets you create custom habits, log daily completions, monitor streaks and progress, and receive personalized AI-powered suggestions — all stored completely on-device with no internet connection required.

---

## Team Members - Team Bok Choy

### Goo Choi — Phases 1, 3, 5, 7, 9

Goo handled the project foundation and data-heavy features. 

In **Phase 1**, Goo initialized the Flutter project, set up the SQLite database schema with the `habits` and `completions` tables, wrote the `Habit` and `Completion` model classes with serialization, built the `DatabaseHelper` singleton, wired up `ThemeProvider` for dark mode, and configured `main.dart` with Material 3 and Provider. 

In **Phase 3**, Goo built the complete Add/Edit Habit form screen with full validation (min/max length, required fields), implemented the `PrefsHelper` utility wrapping all SharedPreferences calls, and connected the FABs across all screens to the real form. 

In **Phase 5**, Goo built the entire Stats screen from scratch — a custom 7-day heatmap widget, an `fl_chart` bar chart showing per-habit completion rates (earning +4 bonus points), a Best Streaks summary card, and the rule-based AI Habit Buddy engine with thumbs-up/down feedback saved to SharedPreferences. 

In **Phase 7**, Goo added custom `SlideUpRoute` and `FadeRoute` page transitions, an `AnimatedScale` celebration effect on habit completion, semantic accessibility labels across all interactive widgets, and fixed landscape layout issues across all six screens. 

In **Phase 9**, Goo conducted the final bug-testing pass, added JSON data export to the Settings screen (earning +3 bonus points), built the release APK, and assembled the submission package.

### Eva Park — Phases 2, 4, 6, 8

Eva built user-facing screens and the settings system. 

In **Phase 2**, Eva built the `MainNavigation` bottom nav bar, the `DashboardScreen` with greeting header, today's progress card, habit list, and floating action button, the reusable `HabitCard` widget with animated completion toggle and streak fire badge, and `HabitsListScreen` with swipe-to-delete and confirmation dialog. 

In **Phase 4**, Eva built the `HabitDetailScreen` showing current streak, best streak, habit level with XP-style progress, completion rate, a monthly calendar heatmap, and a Mark as Complete button with long-press undo; Eva also built the full `SettingsScreen` with dark mode toggle (animated sun/moon icon), display name editor, reminder time picker, and Reset All Data. 

In **Phase 6**, Eva polished the Settings screen, ensured consistent light and dark theme rendering across all screens, added a personalized greeting using the saved username, and ran a full light/dark walkthrough verification. 

In **Phase 8**, Eva wrote the complete `README.md`, `ARCHITECTURE.md`, and `AI_Usage_Log.md`, and added inline doc comments to `DatabaseHelper`, `StatsScreen`, and `HabitDetailScreen`.

---

## Features

### Core Features
- **Create, edit, and delete habits** with name, category, frequency, and optional description
- **Mark a habit complete once per day** from the Dashboard, Habits list, or Detail screen
- **Long-press to undo** today's completion on the Detail screen
- **Current streak and best streak** displayed on each habit's detail page
- **Habit level and XP progress bar** — levels up every 10 completions
- **Completion rate** — total completions divided by days since creation
- **Monthly calendar heatmap** — browse any month's completion history
- **Swipe-to-delete** habits from the Habits list with a confirmation dialog
- **Form validation** — name required, 3–60 characters, category and frequency required

### Stats & Insights
- **Weekly heatmap** — 7-day custom widget showing completion density per day
- **Bar chart** — `fl_chart` visualization of per-habit completion rates
- **Best Streaks summary card** — top 5 habits sorted by completion rate
- **Rule-based AI Habit Buddy** — 6 priority rules producing personalized suggestions
- **Thumbs-up/down feedback** — ratings saved to SharedPreferences and used to cycle rules

### Settings & Personalization
- **Dark mode toggle** with animated sun/moon icon and persistent preference
- **Display name** — shown in the dashboard greeting
- **Reminder time picker** — stored in SharedPreferences
- **Reset All Data** — clears all habits and completions with confirmation dialog
- **JSON export** — saves all habits and completion history to a timestamped file

### Polish & Quality
- **Custom page transitions** — SlideUpRoute and FadeRoute throughout the app
- **Celebration animation** — AnimatedScale pop on habit completion
- **Semantic accessibility labels** on all interactive elements
- **Responsive layout** — tested in portrait and landscape on all six screens
- **Empty states** — every screen handles zero-data gracefully

### Bonus Features Claimed
| Feature | Points |
|---|---|
| Dark mode theme switching | +3 |
| Data export (JSON) | +3 |
| Data visualization with fl_chart | +4 |
| **Total** | **+10** |

---

## Tech Stack

| Package | Version | Purpose |
|---|---|---|
| `flutter` | 3.x (latest stable) | UI framework |
| `sqflite` | ^2.3.3 | SQLite database |
| `path_provider` | ^2.1.3 | File system paths |
| `path` | ^1.9.0 | Path string utilities |
| `shared_preferences` | ^2.3.2 | Key-value settings storage |
| `provider` | ^6.1.2 | ThemeProvider state management |
| `uuid` | ^4.4.2 | Unique IDs for habits and completions |
| `intl` | ^0.19.0 | Date formatting |
| `fl_chart` | ^0.69.0 | Bar chart visualization |

---

##  Installation

**Prerequisites:** Flutter SDK 3.x installed, an Android emulator or physical device connected.

```bash
# 1. Clone the repository
git clone https://github.com/goochoi913/HabitMasteryLeague.git

# 2. Enter the project folder
cd HabitMasteryLeague

# 3. Install all packages
flutter pub get

# 4. Run the app in debug mode
flutter run

# 5. (Optional) Build a release APK
flutter build apk --release
```

The pre-built release APK is also available in the `submission/` folder of this repository.

---

##  Usage Guide

### 1. Dashboard (Home)
The Home screen greets you by name and shows today's progress as a count and progress bar. Tap the **+** FAB or the floating **New Habit** button to create your first habit. Each habit card shows its category color, streak fire badge, and a completion checkbox. Tap the card body to open the Detail screen; tap the checkbox to mark it done for today.

### 2. Creating and Editing a Habit
Fill in the habit name (3–60 characters), select a category (Health, Study, Fitness, Mindfulness, Other), choose a frequency (Daily, Weekdays, Weekends), and optionally add a description. Tap **Create Habit** to save. Open a habit from the Habits tab and tap **Edit** on its detail page to modify it, or use the red trash icon to delete it.

### 3. Habits List
The **Habits** tab shows all your active habits. Swipe left on any card to reveal the delete action and confirm removal. Tap any card to open the detail view.

### 4. Habit Detail
Shows current streak 🔥, best streak, habit level with XP bar, completion rate %, and a monthly calendar where completed days are highlighted. Tap **Mark as Complete** to log today. Long-press the button to undo today's completion. The button is disabled once logged.

### 5. Stats
The **Stats** tab loads automatically with four sections:
- **This Week heatmap** — darker boxes mean more completions that day; today has a border highlight
- **Habit Completion Rates** — bar chart showing each habit's overall consistency
- **Best Streaks** — top 5 habits ranked by completion rate
- **AI Habit Buddy** — a rule-based suggestion with a "Why" explanation; tap 👍 or 👎 to give feedback

### 6. Settings
Change your display name (updates the dashboard greeting), pick a reminder time, toggle dark mode, export all data as a JSON file, or reset everything.

---

##  Database Schema

### `habits` table

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `TEXT` | PRIMARY KEY | UUID generated by the `uuid` package |
| `name` | `TEXT` | NOT NULL | Habit display name |
| `category` | `TEXT` | NOT NULL | One of: Health, Study, Fitness, Mindfulness, Other |
| `frequency` | `TEXT` | NOT NULL | One of: Daily, Weekdays, Weekends |
| `description` | `TEXT` | nullable | Optional user note |
| `created_at` | `TEXT` | NOT NULL | ISO 8601 timestamp set on creation |
| `is_active` | `INTEGER` | NOT NULL DEFAULT 1 | Soft-delete flag (1 = active) |

### `completions` table

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `TEXT` | PRIMARY KEY | UUID generated by the `uuid` package |
| `habit_id` | `TEXT` | NOT NULL, FK → habits.id | Links completion to its habit |
| `completed_date` | `TEXT` | NOT NULL | Date string in `yyyy-MM-dd` format |

**Constraints:**
- `UNIQUE(habit_id, completed_date)` — prevents duplicate same-day entries; duplicate inserts use `ConflictAlgorithm.ignore`
- `FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE` — deleting a habit automatically removes all its completions

---


## 📄 License

This project is for educational use only under the MIT License.

```
MIT License

Copyright (c) 2026 Team Bok Choy — Goo Choi & Eva Park

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
```