# Habit Mastery League

![Flutter](https://img.shields.io/badge/Flutter-Material%203-blue)
![SQLite](https://img.shields.io/badge/Storage-SQLite-green)
![Course](https://img.shields.io/badge/Course-CSC%204360-orange)

Habit Mastery League is a Flutter habit-tracking app built for CSC 4360 by Team Bok Choy. The app helps students build consistent routines by letting them create habits, mark daily completions, monitor streaks and completion history, view progress statistics, and personalize settings while keeping all user data stored locally on device.

## Team Members

| Name | Student ID | Role |
| --- | --- | --- |
| Eva Park | TBD | Phase 2, 4, 6, 8 |
| Goo Choi | TBD | Phase 1, 3, 5, 7, 9 |

## Features

- Create, edit, and delete habits
- Mark a habit complete once per day
- View current streak, best streak, level, and completion rate
- Browse monthly completion history in a calendar view
- Review weekly stats and habit completion charts
- Receive rule-based AI Habit Buddy suggestions
- Save display name, reminder time, and dark mode preference
- Reset all local habit and completion data from settings
- Use custom page transitions, accessible labels, and responsive layouts

## Tech Stack

- `flutter`
- `sqflite`
- `path_provider`
- `path`
- `shared_preferences`
- `provider`
- `uuid`
- `intl`
- `fl_chart`

## Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   ```
2. Enter the project folder:
   ```bash
   cd HabitMasteryLeague
   ```
3. Install packages:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## Usage Guide

1. Launch the app and go to the dashboard.
2. Tap `New Habit` or the `+` button to create a habit with a name, category, frequency, and optional description.
3. Mark habits complete from the dashboard, habits list, or detail screen.
4. Open a habit detail page to view streaks, level progress, completion rate, and the monthly completion calendar.
5. Open the Stats tab to review weekly totals, completion rate charts, and AI Habit Buddy feedback.
6. Open Settings to change the display name, set reminder time, toggle dark mode, or reset all local data.

## Database Schema

### `habits`

| Column | Data Type | Notes |
| --- | --- | --- |
| `id` | `TEXT` | Primary key |
| `name` | `TEXT` | Required habit name |
| `category` | `TEXT` | Required category label |
| `frequency` | `TEXT` | Required schedule value |
| `description` | `TEXT` | Optional note |
| `created_at` | `TEXT` | Creation timestamp |
| `is_active` | `INTEGER` | Active flag, default `1` |

### `completions`

| Column | Data Type | Notes |
| --- | --- | --- |
| `id` | `TEXT` | Primary key |
| `habit_id` | `TEXT` | Foreign key to `habits.id` |
| `completed_date` | `TEXT` | Stored as `yyyy-MM-dd` |

Constraints:

- `UNIQUE(habit_id, completed_date)` prevents duplicate same-day completion rows
- `FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE` removes related completion rows when a habit is deleted

## Known Issues

- Reminder time is stored in preferences, but device-level scheduled notifications are not implemented in v1.0.

## Future Improvements

- Add real local notifications for reminder times
- Add habit filtering and sorting options
- Add export/import backup support
- Add weekly and monthly goal features
- Add richer achievements and gamified rewards

## License

MIT License for educational use only.
