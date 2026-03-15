import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../db/database_helper.dart';
import '../../models/habit.dart';
import '../../models/completion.dart';
import '../../widgets/habit_card.dart';
import '../../widgets/loading_state.dart';
import '../habit_form/habit_form_screen.dart';
import '../habit_detail/habit_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getTodayLabel() {
    return DateFormat('EEEE, MMM d').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _completedToday.values.where((v) => v).length;
    final totalCount = _habits.length;
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const LoadingState(message: 'Loading your habits...')
            : RefreshIndicator(
                onRefresh: _loadData,
                child: CustomScrollView(
                  slivers: [
                    // ── Header ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getTodayLabel(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.5),
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_getGreeting()} 👋',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Progress Card ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Today's Progress",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      '$completedCount / $totalCount',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 10,
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceVariant,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      progress == 1.0
                                          ? Colors.green
                                          : Theme.of(context)
                                              .colorScheme
                                              .primary,
                                    ),
                                  ),
                                ),
                                if (totalCount > 0 && completedCount == totalCount)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Text(
                                      '🎉 All done for today!',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Habit List ──
                    if (_habits.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_task,
                                  size: 64,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.3)),
                              const SizedBox(height: 16),
                              Text(
                                'No habits yet.\nTap + to create your first one!',
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
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final habit = _habits[index];
                            return HabitCard(
                              habit: habit,
                              isCompletedToday:
                                  _completedToday[habit.id] ?? false,
                              streakCount: _streaks[habit.id] ?? 0,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        HabitDetailScreen(habitId: habit.id),
                                  ),
                                );
                                _loadData();
                              },
                              onToggle: () => _toggleCompletion(habit),
                            );
                          },
                          childCount: _habits.length,
                        ),
                      ),

                    const SliverToBoxAdapter(
                        child: SizedBox(height: 80)), // FAB clearance
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HabitFormScreen()),
          );
          _loadData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}