# AI Usage Log

This file documents the specific instances where AI tools were used during development of Habit Mastery League, in accordance with the CSC 4360 AI Usage Guidelines. AI was used strictly as a debugging and learning aid - architectural decisions, feature design, and all implementation work were completed by the team. All AI-assisted code was reviewed, understood, and manually integrated by the developer responsible for that phase.

---

## Log

| Date | Developer | Tool | What We Asked | What We Used | What We Learned |
|---|---|---|---|---|---|
| Mar 15, 2026 | Goo | ChatGPT | Asked why `sqflite` cascade delete was not removing completion rows when a habit was deleted | Used the explanation that `PRAGMA foreign_keys = ON` must be set at connection time in sqflite, and verified the fix in `DatabaseHelper._onCreate` | Learned that SQLite foreign key enforcement is opt-in and must be explicitly enabled per connection - it is not on by default |
| Mar 16, 2026 | Eva | ChatGPT | Asked how to structure a `GridView` for a monthly calendar that adapts cleanly between portrait and landscape | Used the suggestion to use `GridView.count` with a fixed `crossAxisCount` of 7 and let the cell size scale naturally | Learned that `GridView.count` is more predictable than `GridView.extent` when the column count is fixed (days of the week) |
| Mar 19, 2026 | Goo | ChatGPT | Asked what the correct Flutter widget was to preserve scroll position when calling `setState` inside a `ListView` | Used the `ScrollController` + offset-restore pattern to prevent the list from jumping to the top after toggling a completion checkbox | Learned that `setState` with `ListView.builder` rebuilds the whole list and resets scroll; preserving position requires storing and restoring the controller offset manually |
| Mar 19, 2026 | Eva | ChatGPT | Asked how to make an animated icon swap between a sun and moon when the dark mode toggle changes | Used the `AnimatedSwitcher` widget with a rotation transition as the switching animation | Learned that `AnimatedSwitcher` requires unique keys on the outgoing and incoming children to trigger the animation correctly |
| Mar 20, 2026 | Goo | ChatGPT | Asked how `dart:convert`'s `JsonEncoder.withIndent` works when writing a nested list of maps to a file | Used the pattern for building the export payload as a `List<Map>` and writing it with `File.writeAsString` | Learned that `JsonEncoder.withIndent` handles nested structures automatically as long as all values are JSON-serializable types |

---

## Summary

AI assistance in this project was limited to five targeted debugging and API-lookup questions across the full development timeline. No AI tool generated any screen layout, business logic, database schema, or feature design. Every question in this log was a specific technical lookup - the kind of question a developer would otherwise resolve by reading the Flutter or Dart documentation. The AI Habit Buddy feature itself is fully rule-based and runs locally on device with no AI API calls of any kind.
