import 'package:flutter/material.dart';
import 'package:habit_mastery_league/db/database_helper.dart';
import 'package:habit_mastery_league/models/habit.dart';
import 'package:habit_mastery_league/models/completion.dart';
import 'package:habit_mastery_league/widgets/habit_card.dart';
import 'package:habit_mastery_league/widgets/loading_state.dart';

class HabitsListScreen extends StatefulWidget {
  const HabitsListScreen({super.key});

  @override
  State<HabitsListScreen> createState() => _HabitsListScreenState();
}

class _HabitsListScreenState extends State<HabitsListScreen> {
  List<Habit> _habits = [];
  Map<String, bool> _completedToday = {};
  Map<String, int> _streaks = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final habits = await DatabaseHelper.instance.getAllHabits();
    final Map<String, bool> completedMap = {};
    final Map<String, int> streakMap = {};

    for (final habit in habits) {
      completedMap[habit.id] =
          await DatabaseHelper.instance.isCompletedToday(habit.id);
      final completions =
          await DatabaseHelper.instance.getCompletionsForHabit(habit.id);
      streakMap[habit.id] = _calculateStreak(completions);
    }

    if (mounted) {
      setState(() {
        _habits = habits;
        _completedToday = completedMap;
        _streaks = streakMap;
        _loading = false;
      });
    }
  }

  int _calculateStreak(List<Completion> completions) {
    if (completions.isEmpty) return 0;
    final dates = completions
        .map((c) => DateTime.parse(c.completedDate))
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime checkDate = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    for (final date in dates) {
      if (checkDate.difference(date).inDays <= 1) {
        streak++;
        checkDate = date;
      } else {
        break;
      }
    }
    return streak;
  }

  // Delete confirmation dialog
  Future<bool> _confirmDelete(Habit habit) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text(
          'Are you sure you want to delete "${habit.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // UI
  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingState(message: '습관 불러오는 중...');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Habits',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _habits.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                itemCount: _habits.length,
                itemBuilder: (context, index) {
                  final habit = _habits[index];

                  return Dismissible(
                    key: Key(habit.id),
                    direction: DismissDirection.endToStart,

                    // Red background with delete icon
                    background: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),

                    // Delete confirmation
                    confirmDismiss: (_) => _confirmDelete(habit),

                    onDismissed: (_) async {
                      await DatabaseHelper.instance.deleteHabit(habit.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('"${habit.name}" deleted'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      await _loadData();
                    },

                    child: HabitCard(
                      habit: habit,
                      isCompletedToday: _completedToday[habit.id] ?? false,
                      streakCount: _streaks[habit.id] ?? 0,
                      onTap: () {
                        // Connect to AddEditHabitScreen in Phase 3
                      },
                      onToggle: () async {
                        if (_completedToday[habit.id] == true) return;
                        final today = DateTime.now()
                            .toIso8601String()
                            .substring(0, 10);
                        final completion = Completion(
                          habitId: habit.id,
                          completedDate: today,
                        );
                        await DatabaseHelper.instance
                            .insertCompletion(completion);
                        await _loadData();
                      },
                    ),
                  );
                },
              ),
      ),

      // FAB to add new habit (connect to AddEditHabitScreen in Phase 3)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Connect to AddEditHabitScreen in Phase 3
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phase 3에서 연결 예정!')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Habit'),
      ),
    );
  }

  // Empty state UI
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.checklist_rounded,
            size: 80,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No habits yet!',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first habit.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.5),
                ),
          ),
        ],
      ),
    );
  }
}