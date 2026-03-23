# Selected Presentation Questions Form

## Course Information
- Course Name: Mobile Application Development
- Course Section: CSC 4360
- Instructor: Louis Henry
- Semester/Term: Spring 2026

## Team Information
- Group Name: Team Bok Choy
- App/Project Title: Habit Mastery League / MyHabits
- Presentation Date: March 23, 2026

### Team Members
1. Goo Choi
2. Eva Park

---

## Selected Questions 

---

1. Question: What are the key advantages of using Flutter for this cross-platform project?
   - Category: Flutter Framework & Cross-Platform Concepts
   - Team Member Responsible: Eva Park
   - Evidence to Show: Live app running on Android emulator; single Dart codebase in VS Code; pubspec.yaml showing one set of packages targeting both platforms

---

2. Question: Which state management technique did you choose and why?
   - Category: State Management
   - Team Member Responsible: Goo Choi
   - Evidence to Show: lib/providers/theme_provider.dart (ChangeNotifier), lib/main.dart (ChangeNotifierProvider wrapping the app), and explanation of why screen-local setState was used for all other data instead of a global store

---

3. Question: Describe one state-flow interaction from user action to UI update in your app.
   - Category: State Management
   - Team Member Responsible: Eva Park
   - Evidence to Show: lib/screens/dashboard/dashboard_screen.dart — trace from checkbox tap → _toggleCompletion() → DatabaseHelper.insertCompletion() → local setState update → HabitCard re-render with green checkbox

---

4. Question: How did you make the interface intuitive and responsive across device sizes and orientations?
   - Category: UI/UX Design
   - Team Member Responsible: Eva Park
   - Evidence to Show: Rotate emulator to landscape live — Dashboard switches to two-column layout; Habit Detail calendar scales; all screens scroll without overflow

---

5. Question: Explain your local data structure (tables, columns, keys, or preference groups).
   - Category: Local Data Persistence
   - Team Member Responsible: Goo Choi
   - Evidence to Show: lib/db/database_helper.dart — show CREATE TABLE SQL for habits and completions, UNIQUE constraint, ON DELETE CASCADE foreign key, and PrefsHelper key list

---

6. Question: How are CRUD operations implemented and validated in your app?
   - Category: Local Data Persistence
   - Team Member Responsible: Eva Park
   - Evidence to Show: Live demo — create habit (form validation error on empty name), mark complete, edit habit, delete via swipe; lib/screens/habit_form/add_edit_habit_screen.dart showing _save() and _delete() methods

---

7. Question: Share one meaningful commit message and explain why it communicates value clearly.
   - Category: Version Control
   - Team Member Responsible: Goo Choi
   - Evidence to Show: GitHub commit history — show commit "feat: implement rule-based AI Habit Buddy with thumbs feedback saved to SharedPreferences" and explain it names the feature, the approach, and the persistence mechanism in one line

---

8. Question: How were responsibilities divided, and how did you ensure fair technical ownership?
   - Category: Team Collaboration
   - Team Member Responsible: Both (Eva introduces, Goo confirms)
   - Evidence to Show: GitHub commit history grouped by author — Goo: foundation/data/stats/animations, Eva: navigation/screens/settings/docs; git shortlog showing ~27 Goo / ~22 Eva commits

---

9. Question: Walk through one complete feature trace using your actual code — start from a user tap, show the triggering widget, state update logic, data-layer call, and final UI render.
   - Category: Implementation Defense (High-Rigor)
   - Team Member Responsible: Goo Choi
   - Evidence to Show: VS Code open — HabitCard.onToggle() → dashboard_screen.dart _toggleCompletion() → DatabaseHelper.insertCompletion() with ConflictAlgorithm.ignore → local setState updating _completedToday map → HabitCard rebuild showing green checkbox + celebration overlay trigger

---

10. Question: Present one bug your team introduced and fixed. Show the related commit, explain the root cause, why the first approach failed, and how the final fix changed runtime behavior.
    - Category: Implementation Defense (High-Rigor)
    - Team Member Responsible: Goo Choi
    - Evidence to Show: GitHub commit "fix: resolve habits list sync, scroll jump, chart label overlap, and AI buddy refresh" — show ScrollController offset save/restore pattern in stats_screen.dart; explain that calling _loadData() rebuilt the ListView and reset scroll to top, and the fix used WidgetsBinding.addPostFrameCallback to restore offset after layout

---

11. Question: Compare two implementation options your team considered. Use constraints to justify the final choice and one trade-off accepted.
    - Category: Implementation Defense (High-Rigor)
    - Team Member Responsible: Goo Choi
    - Evidence to Show: ARCHITECTURE.md section on "Provider Only for Theme" — compare global habits Provider vs screen-local StatefulWidget loading; explain SQLite is already the source of truth so a reactive store would duplicate state; trade-off accepted is that cross-tab refresh requires a version-key pattern in MainNavigation instead of automatic reactivity

---

12. Question: Demonstrate a data integrity scenario (duplicate prevention, failed update, etc.). Explain exactly where validation occurs and how the app prevents inconsistent state.
    - Category: Implementation Defense (High-Rigor)
    - Team Member Responsible: Goo Choi
    - Evidence to Show: lib/db/database_helper.dart — show UNIQUE(habit_id, completed_date) SQL constraint + ConflictAlgorithm.ignore in insertCompletion(); lib/screens/dashboard/dashboard_screen.dart — show _completionInProgress boolean guard; demonstrate by tapping checkbox quickly in the app and showing no duplicate entry appears

---