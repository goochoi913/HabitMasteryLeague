# AI Usage Log

| Date | Tool | Prompt Summary | Used Output | Learning Reflection |
| --- | --- | --- | --- | --- |
| 2026-03-18 | Codex (GPT-5) | Read the build guide and compare the app against Phase 4 requirements | Used the gap analysis to identify incorrect streak logic and missing requirement alignment | I learned to compare working code against the written phase rubric before assuming the issue is only a runtime bug. |
| 2026-03-18 | Codex (GPT-5) | Fix Phase 4 streak calculation and database consistency | Used the refactor plan for shared streak logic and SQLite foreign-key enabling | I confirmed that duplicated business logic across screens causes inconsistent UI and should be centralized. |
| 2026-03-19 | Codex (GPT-5) | Diagnose Android build failures involving Gradle cache and manifest processing | Used the troubleshooting steps for clearing build artifacts and checking manifest readability | I learned that many Flutter Android failures come from corrupted local caches instead of app logic. |
| 2026-03-19 | Codex (GPT-5) | Refine Phase 6 settings screen and dark mode rendering | Used suggestions for settings section structure and theme-aware colors | I learned to replace hardcoded colors with theme tokens so light and dark mode stay consistent. |
| 2026-03-19 | Codex (GPT-5) | Validate personalized greeting, animated theme toggle, and app walkthrough behavior | Used verification and test stabilization guidance to update the widget smoke test | I learned that test files must match the real app structure rather than the default Flutter template. |
| 2026-03-20 | Codex (GPT-5) | Review the current Phase 7 implementation and verify accessibility, animation, and responsiveness | Used the review to confirm existing Phase 7 features and validate them with tests and analysis | I learned to verify current repository state before re-implementing work that may already be complete. |

> Add more rows if either teammate used another AI tool outside the interactions recorded in this repo session.
