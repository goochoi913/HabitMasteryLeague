import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:habit_mastery_league/db/database_helper.dart';
import 'package:habit_mastery_league/models/completion.dart';
import 'package:habit_mastery_league/models/habit.dart';
import 'package:habit_mastery_league/utils/prefs_helper.dart';
import 'package:habit_mastery_league/utils/streak_utils.dart';
import 'package:habit_mastery_league/widgets/habit_card.dart';
import 'package:habit_mastery_league/widgets/loading_state.dart';
import 'package:habit_mastery_league/screens/habit_form/add_edit_habit_screen.dart';
import 'package:habit_mastery_league/screens/habit_detail/habit_detail_screen.dart';

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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final habits = await _db.getAllHabits();
    final completedMap = <String, bool>{};
    final streakMap = <String, int>{};

    for (final habit in habits) {
      completedMap[habit.id] = await _db.isCompletedToday(habit.id);
      final completions = await _db.getCompletionsForHabit(habit.id);
      streakMap[habit.id] = calculateCurrentStreak(completions);
    }

    if (!mounted) return;

    setState(() {
      _habits = habits;
      _completedToday = completedMap;
      _streaks = streakMap;
      _loading = false;
    });
  }

  Future<void> _toggleCompletion(Habit habit) async {
    if (_completedToday[habit.id] == true) return;

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final completion = Completion(habitId: habit.id, completedDate: today);

    await _db.insertCompletion(completion);
    final completions = await _db.getCompletionsForHabit(habit.id);
    final updatedStreak = calculateCurrentStreak(completions);

    if (!mounted) return;

    setState(() {
      _completedToday[habit.id] = true;
      _streaks[habit.id] = updatedStreak;
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final storedName = PrefsHelper.getUsername().trim();
    final name = storedName.isEmpty ? 'Habit Hero' : storedName;

    if (hour < 12) return 'Good Morning, $name! ☀️';
    if (hour < 18) return 'Good Afternoon, $name! 👋';
    return 'Good Evening, $name! 🌙';
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.self_improvement,
            size: 80,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No habits yet!',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first habit mission.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: SafeArea(child: LoadingState(message: 'Loading your habits...')),
      );
    }

    final completedCount = _completedToday.values.where((v) => v).length;
    final total = _habits.length;
    final progress = total == 0 ? 0.0 : completedCount / total;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: const Text(
                'Habit Mastery League',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadData,
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      DateFormat('EEEE, MMMM d').format(DateTime.now()),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Today's Progress",
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '$completedCount / $total',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 10,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}% complete',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            _habits.isEmpty
                ? SliverFillRemaining(child: _buildEmptyState(context))
                : SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final habit = _habits[index];
                      return HabitCard(
                        habit: habit,
                        isCompletedToday: _completedToday[habit.id] ?? false,
                        streakCount: _streaks[habit.id] ?? 0,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  HabitDetailScreen(habitId: habit.id),
                            ),
                          ).then((_) => _loadData());
                        },
                        onToggle: () => _toggleCompletion(habit),
                      );
                    }, childCount: _habits.length),
                  ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditHabitScreen()),
          ).then((_) => _loadData());
        },
        icon: const Icon(Icons.add),
        label: const Text('New Habit'),
      ),
    );
  }
}
