import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../db/database_helper.dart';
import '../../models/habit.dart';
import '../../models/completion.dart';
import '../../widgets/habit_card.dart';
import '../../widgets/loading_state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Habit> _habits = [];
  Map<String, bool> _completedToday = {};
  Map<String, int> _streaks = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  //  data loading 
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

  // streak calculation based on completion dates
  int _calculateStreak(List<Completion> completions) {
    if (completions.isEmpty) return 0;

    // date parsing and sorting (newest first)
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
      final diff = checkDate.difference(date).inDays;
      if (diff <= 1) {
        streak++;
        checkDate = date;
      } else {
        break;
      }
    }
    return streak;
  }
  
  // greeting message based on time of day and username 
  String _getGreeting() {
    final hour = DateTime.now().hour;
    const name = 'Habit Hero'; // Phase 3에서 PrefsHelper.getUsername()으로 교체
    if (hour < 12) return 'Good Morning, $name! ☀️';
    if (hour < 18) return 'Good Afternoon, $name! 👋';
    return 'Good Evening, $name! 🌙';
}

  //  toggle habit completion
  Future<void> _toggleCompletion(Habit habit) async {
    // 이미 완료했으면 아무것도 안 함
    if (_completedToday[habit.id] == true) return;

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final completion = Completion(
      habitId: habit.id,
      completedDate: today,
    );
    await DatabaseHelper.instance.insertCompletion(completion);
    await _loadData();
  }

  // UI building with progress card and habit list (or empty state)
  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingState();

    final completedCount =
        _completedToday.values.where((v) => v == true).length;
    final total = _habits.length;
    final progress = total == 0 ? 0.0 : completedCount / total;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // AppBar with title and refresh button
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
                    // Welcome message with dynamic greeting
                    Text(
                      _getGreeting(),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      DateFormat('EEEE, MMMM d').format(DateTime.now()),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Progress card showing today's completion status
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
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
                                          fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '$completedCount / $total',
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
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 10,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        Colors.green),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}% complete',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
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

            // Habit list or empty state
            _habits.isEmpty
                ? SliverFillRemaining(
                    child: _buildEmptyState(context),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final habit = _habits[index];
                        return HabitCard(
                          habit: habit,
                          isCompletedToday:
                              _completedToday[habit.id] ?? false,
                          streakCount: _streaks[habit.id] ?? 0,
                          onTap: () {
                        
                          },
                          onToggle: () => _toggleCompletion(habit),
                        );
                      },
                      childCount: _habits.length,
                    ),
                  ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),

      // FAB to add new habit
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Phase 3에서 AddEditHabitScreen으로 연결
          // 지금은 임시 SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phase 3에서 연결 예정!')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Habit'),
      ),
    );
  }

  // Empty state widget when no habits are present
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.self_improvement,
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
            'Tap + to create your first habit mission.',
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