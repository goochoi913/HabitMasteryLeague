import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../db/database_helper.dart';
import '../../models/habit.dart';
import '../../models/completion.dart';
import '../../widgets/habit_card.dart';
import '../../widgets/loading_state.dart';
import 'add_edit_habit_screen.dart';
import '../habit_detail/habit_detail_screen.dart';

class HabitsListScreen extends StatefulWidget {
  const HabitsListScreen({super.key});

  @override
  State<HabitsListScreen> createState() => _HabitsListScreenState();
}

class _HabitsListScreenState extends State<HabitsListScreen> {
  final _db = DatabaseHelper.instance;

  List<Habit> _habits = [];
  Map<String, bool> _completedToday = {};
  Map<String, int> _streaks = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final habits = await _db.getAllHabits();
    final completed = <String, bool>{};
    final streaks = <String, int>{};

    for (final habit in habits) {
      completed[habit.id] = await _db.isCompletedToday(habit.id);
      streaks[habit.id] = await _calculateStreak(habit.id);
    }

    if (mounted) {
      setState(() {
        _habits = habits;
        _completedToday = completed;
        _streaks = streaks;
        _isLoading = false;
      });
    }
  }

  Future<int> _calculateStreak(String habitId) async {
    final completions = await _db.getCompletionsForHabit(habitId);
    if (completions.isEmpty) return 0;
    final dates = completions.map((c) => c.completedDate).toSet();
    int streak = 0;
    DateTime check = DateTime.now();
    while (true) {
      final dateStr = DateFormat('yyyy-MM-dd').format(check);
      if (dates.contains(dateStr)) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  Future<void> _toggleCompletion(Habit habit) async {
    final alreadyDone = _completedToday[habit.id] ?? false;
    if (!alreadyDone) {
      await _db.insertCompletion(Completion(habitId: habit.id));
    }
    await _loadData();
  }

  Future<void> _confirmDelete(Habit habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text(
            'Are you sure you want to delete "${habit.name}"? This will also remove all its completion history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _db.deleteHabit(habit.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${habit.name}" deleted')),
        );
      }
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                'My Habits',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const LoadingState(message: 'Loading habits...')
                  : _habits.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.checklist,
                                  size: 64,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.3)),
                              const SizedBox(height: 16),
                              Text(
                                'No habits yet.\nTap + to add one!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            itemCount: _habits.length,
                            itemBuilder: (context, index) {
                              final habit = _habits[index];
                              return Dismissible(
                                key: Key(habit.id),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (_) async {
                                  await _confirmDelete(habit);
                                  return false; // we handle deletion ourselves
                                },
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 24),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.error,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.delete,
                                      color: Colors.white),
                                ),
                                child: HabitCard(
                                  habit: habit,
                                  isCompletedToday:
                                      _completedToday[habit.id] ?? false,
                                  streakCount: _streaks[habit.id] ?? 0,
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddEditHabitScreen(habit: habit),
                                      ),
                                    );
                                    _loadData();
                                  },
                                  onToggle: () => _toggleCompletion(habit),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'habits_fab',
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditHabitScreen()),
          );
          _loadData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}