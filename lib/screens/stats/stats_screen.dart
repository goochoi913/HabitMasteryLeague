import 'package:flutter/material.dart';
import 'package:habit_mastery_league/db/database_helper.dart';
import 'package:habit_mastery_league/models/habit.dart';
import 'package:habit_mastery_league/widgets/loading_state.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Habit> _habits = [];
  Map<String, double> _completionRates = {};
  Map<String, int> _weeklyData = {};
  String _aiSuggestion = '';
  String _aiReason = '';
  String _aiKey = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final habits = await _db.getAllHabits();
    final completionRates = <String, double>{};

    for (final habit in habits) {
      final completions = await _db.getCompletionsForHabit(habit.id);
      final createdAt = DateTime.tryParse(habit.createdAt) ?? DateTime.now();
      final safeCreatedDate = DateTime(
        createdAt.year,
        createdAt.month,
        createdAt.day,
      );

      final daysSinceCreated =
          DateTime.now().difference(safeCreatedDate).inDays + 1;
      final totalDays = daysSinceCreated < 1 ? 1 : daysSinceCreated;
      final completionRate = (completions.length / totalDays).clamp(0.0, 1.0);

      completionRates[habit.name] = completionRate;
    }

    final weeklyData = await _db.getWeeklyCompletionCounts();

    if (!mounted) return;

    setState(() {
      _habits = habits;
      _completionRates = completionRates;
      _weeklyData = weeklyData;
      _aiSuggestion =
          'Keep going! Your AI Habit Buddy suggestions will appear here.';
      _aiReason = 'AI suggestion engine will be connected in the next step.';
      _aiKey = 'pending_ai_buddy';
      _loading = false;
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 72,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No stats yet',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first habit to start tracking progress and insights.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySectionPlaceholder(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This Week',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${_weeklyData.values.fold<int>(0, (sum, count) => sum + count)} total completions loaded for this week.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartPlaceholder(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Habit Completion Rates',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${_completionRates.length} habits analyzed for completion rates.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestStreaksPlaceholder(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Best Streaks',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Best streak summary will appear here.'),
          ],
        ),
      ),
    );
  }

  Widget _buildAIBuddyPlaceholder(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Habit Buddy',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(_aiSuggestion),
            const SizedBox(height: 6),
            Text(
              'Why: $_aiReason',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Suggestion ID: $_aiKey',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: SafeArea(child: LoadingState(message: 'Loading stats...')),
      );
    }

    if (_habits.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Stats'),
          actions: [
            IconButton(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: _buildEmptyState(context),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Stats'),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _buildWeeklySectionPlaceholder(context),
            const SizedBox(height: 12),
            if (_habits.isNotEmpty) ...[
              _buildBarChartPlaceholder(context),
              const SizedBox(height: 12),
              _buildBestStreaksPlaceholder(context),
              const SizedBox(height: 12),
            ],
            _buildAIBuddyPlaceholder(context),
          ],
        ),
      ),
    );
  }
}
