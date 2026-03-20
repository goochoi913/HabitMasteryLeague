import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:habit_mastery_league/db/database_helper.dart';
import 'package:habit_mastery_league/models/completion.dart';
import 'package:habit_mastery_league/models/habit.dart';
import 'package:habit_mastery_league/utils/app_colors.dart';
import 'package:habit_mastery_league/utils/streak_utils.dart';
import 'package:habit_mastery_league/widgets/error_state.dart';
import 'package:habit_mastery_league/widgets/loading_state.dart';

class HabitDetailScreen extends StatefulWidget {
  final String habitId;

  const HabitDetailScreen({super.key, required this.habitId});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  final _db = DatabaseHelper.instance;

  Habit? _habit;
  bool _completedToday = false;
  bool _showCelebration = false;
  bool _loading = true;
  String? _errorMessage;

  int _currentStreak = 0;
  int _bestStreak = 0;
  int _totalCompletions = 0;
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });

      final habit = await _db.getHabitById(widget.habitId);
      if (habit == null) {
        setState(() {
          _errorMessage = 'Habit not found.';
          _loading = false;
        });
        return;
      }

      final completions = await _db.getCompletionsForHabit(widget.habitId);
      final completedToday = await _db.isCompletedToday(widget.habitId);

      if (!mounted) return;

      setState(() {
        _habit = habit;
        _completedToday = completedToday;
        _totalCompletions = completions.length;
        _currentStreak = calculateCurrentStreak(completions);
        _bestStreak = calculateBestStreak(completions);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load habit details.';
        _loading = false;
      });
    }
  }

  Future<void> _markComplete() async {
    if (_completedToday) return;

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final completion = Completion(
      habitId: widget.habitId,
      completedDate: today,
    );

    await _db.insertCompletion(completion);
    if (mounted) {
      setState(() {
        _showCelebration = true;
      });
    }

    await _loadData();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _showCelebration = false;
      });
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Great job! Streak: $_currentStreak days 🔥'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _undoCompletion() async {
    if (!_completedToday) return;

    await _db.deleteTodayCompletion(widget.habitId);
    await _loadData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Completion undone.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  int get _level => (_totalCompletions ~/ 7) + 1;

  double get _levelProgress => (_totalCompletions % 7) / 7.0;

  double get _completionRate {
    final daysSinceCreated = _habit == null
        ? 1
        : DateTime.now()
                  .difference(DateTime.parse(_habit!.createdAt))
                  .inDays
                  .clamp(0, 100000) +
              1;

    return (_totalCompletions / daysSinceCreated).clamp(0.0, 1.0);
  }

  Future<List<String>> _getCompletedDatesForVisibleMonth() {
    return _db.getCompletedDatesInMonth(
      widget.habitId,
      _visibleMonth.year,
      _visibleMonth.month,
    );
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  List<Widget> _buildCalendarCells(
    BuildContext context,
    List<String> completedDates,
    Color categoryColor,
  ) {
    final firstDayOfMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
      1,
    );
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;

    final leadingSpaces = firstDayOfMonth.weekday % 7;
    final cells = <Widget>[];

    for (int i = 0; i < leadingSpaces; i++) {
      cells.add(const SizedBox.shrink());
    }

    final today = DateTime.now();

    for (int day = 1; day <= daysInMonth; day++) {
      final currentDate = DateTime(
        _visibleMonth.year,
        _visibleMonth.month,
        day,
      );
      final dateString = DateFormat('yyyy-MM-dd').format(currentDate);
      final isCompleted = completedDates.contains(dateString);
      final isToday =
          currentDate.year == today.year &&
          currentDate.month == today.month &&
          currentDate.day == today.day;

      cells.add(
        Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isCompleted ? categoryColor : Colors.transparent,
            shape: BoxShape.circle,
            border: isToday
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: Center(
            child: Text(
              '$day',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isCompleted
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      );
    }

    return cells;
  }

  Widget _buildStatCard(BuildContext context, String label, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          child: Column(
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: SafeArea(
          child: LoadingState(message: 'Loading habit details...'),
        ),
      );
    }

    if (_errorMessage != null || _habit == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Habit Detail')),
        body: SafeArea(
          child: ErrorState(
            message: _errorMessage ?? 'Something went wrong.',
            onRetry: _loadData,
          ),
        ),
      );
    }

    final habit = _habit!;
    final categoryColor =
        AppColors.categories[habit.category] ??
        Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: Text(habit.name)),
      body: SafeArea(
        child: FutureBuilder<List<String>>(
          future: _getCompletedDatesForVisibleMonth(),
          builder: (context, snapshot) {
            final completedDates = snapshot.data ?? [];

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildStatCard(context, 'Streak', '$_currentStreak'),
                      const SizedBox(width: 12),
                      _buildStatCard(context, 'Best', '$_bestStreak'),
                      const SizedBox(width: 12),
                      _buildStatCard(context, 'Level', '$_level'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Level $_level',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('$_totalCompletions total completions'),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: _levelProgress,
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Completion Rate',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: _completionRate,
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(_completionRate * 100).toStringAsFixed(0)}% overall',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: () => _changeMonth(-1),
                                icon: const Icon(Icons.chevron_left),
                              ),
                              Text(
                                DateFormat('MMMM yyyy').format(_visibleMonth),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                onPressed: () => _changeMonth(1),
                                icon: const Icon(Icons.chevron_right),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: const [
                              Text('S'),
                              Text('M'),
                              Text('T'),
                              Text('W'),
                              Text('T'),
                              Text('F'),
                              Text('S'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          GridView.count(
                            crossAxisCount: 7,
                            childAspectRatio: 1,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: _buildCalendarCells(
                              context,
                              completedDates,
                              categoryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if ((habit.description ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Description',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(habit.description!.trim()),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Semantics(
          label: _completedToday
              ? 'Already completed today'
              : 'Mark habit as complete for today',
          button: !_completedToday,
          child: GestureDetector(
            onLongPress: _completedToday ? _undoCompletion : null,
            child: AnimatedScale(
              scale: _showCelebration ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.elasticOut,
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _completedToday ? null : _markComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _completedToday ? Colors.green : null,
                    foregroundColor: _completedToday ? Colors.white : null,
                  ),
                  icon: Icon(
                    _completedToday ? Icons.check_circle : Icons.task_alt,
                  ),
                  label: Text(
                    _completedToday ? 'Completed Today! ✓' : 'Mark as Complete',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
