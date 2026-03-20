import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:habit_mastery_league/db/database_helper.dart';
import 'package:habit_mastery_league/models/habit.dart';
import 'package:habit_mastery_league/utils/app_colors.dart';
import 'package:habit_mastery_league/utils/prefs_helper.dart';
import 'package:habit_mastery_league/widgets/loading_state.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final ScrollController _scrollController = ScrollController();

  List<Habit> _habits = [];
  Map<String, double> _completionRates = {};
  Map<String, int> _weeklyData = {};
  String _aiSuggestion = '';
  String _aiReason = '';
  String _aiKey = '';
  String? _skipRuleKeyOnce;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData({
    bool showLoading = true,
    double? restoreOffset,
  }) async {
    if (showLoading) {
      setState(() => _loading = true);
    }

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
      final aiResult = _generateSuggestion();
      _aiSuggestion = aiResult['text'] ?? '';
      _aiReason = aiResult['reason'] ?? '';
      _aiKey = aiResult['key'] ?? '';
      _skipRuleKeyOnce = null;
      _loading = false;
    });

    if (restoreOffset != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        final maxScroll = _scrollController.position.maxScrollExtent;
        final target = restoreOffset.clamp(0.0, maxScroll);
        _scrollController.jumpTo(target);
      });
    }
  }

  String _sanitizeKey(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  Map<String, String> _generateSuggestion() {
    Map<String, String>? pickCandidate(Map<String, String> candidate) {
      if (_skipRuleKeyOnce != null && candidate['key'] == _skipRuleKeyOnce) {
        return null;
      }
      return candidate;
    }

    if (_habits.isEmpty) {
      final candidate = {
        'text': 'Start your league by adding your first habit today.',
        'reason': 'You have not created any habits yet.',
        'key': 'rule_1_no_habits',
      };
      final picked = pickCandidate(candidate);
      if (picked != null) return picked;
    }

    final now = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(now);
    final todayCount = _weeklyData[todayKey] ?? 0;

    if (now.hour >= 18 && todayCount == 0) {
      final candidate = {
        'text':
            'It is getting late and you have 0 completions today. Go for one quick win to protect momentum.',
        'reason': 'No completions logged today and it is evening.',
        'key': 'rule_2_evening_no_completions_$todayKey',
      };
      final picked = pickCandidate(candidate);
      if (picked != null) return picked;
    }

    if (_completionRates.isNotEmpty) {
      final lowest = _completionRates.entries.reduce(
        (a, b) => a.value <= b.value ? a : b,
      );
      if (lowest.value < 0.4) {
        final percentage = (lowest.value * 100).toStringAsFixed(0);
        final candidate = {
          'text':
              '${lowest.key} is at $percentage% completion. Try doing it right after waking up as a trigger cue.',
          'reason': 'This habit has the lowest consistency.',
          'key': 'rule_3_lowest_${_sanitizeKey(lowest.key)}',
        };
        final picked = pickCandidate(candidate);
        if (picked != null) return picked;
      }
    }

    if (_completionRates.isNotEmpty) {
      final highest = _completionRates.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );
      if (highest.value > 0.8) {
        final percentage = (highest.value * 100).toStringAsFixed(0);
        final candidate = {
          'text':
              'Great work! ${highest.key} is at $percentage% completion. Keep the streak alive.',
          'reason': 'This is your strongest habit right now.',
          'key': 'rule_4_highest_${_sanitizeKey(highest.key)}',
        };
        final picked = pickCandidate(candidate);
        if (picked != null) return picked;
      }
    }

    if (_habits.isNotEmpty && todayCount == _habits.length) {
      final candidate = {
        'text':
            'Perfect day unlocked. You completed all ${_habits.length} habits today.',
        'reason': 'Every habit was completed today.',
        'key': 'rule_5_all_done_${_habits.length}_$todayKey',
      };
      final picked = pickCandidate(candidate);
      if (picked != null) return picked;
    }

    final weekTotal = _weeklyData.values.fold<int>(
      0,
      (sum, count) => sum + count,
    );
    final average = weekTotal / 7.0;
    final target = (_habits.length * 0.8).ceil();

    final defaultCandidate = {
      'text':
          'You are averaging ${average.toStringAsFixed(1)} completions per day this week. Aim for at least $target habits per day (80% of your list).',
      'reason': 'Based on your weekly completion trend.',
      'key': 'rule_default_${_habits.length}_$weekTotal',
    };
    final pickedDefault = pickCandidate(defaultCandidate);
    if (pickedDefault != null) return pickedDefault;

    return {
      'text':
          'Try a different focus: pick one habit and finish it in the next hour for a quick reset.',
      'reason':
          'Showing an alternate suggestion based on your recent feedback.',
      'key': 'rule_feedback_alternate',
    };
  }

  Future<void> _saveFeedback(bool isPositive) async {
    final currentKey = _aiKey;
    final currentOffset = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;

    _skipRuleKeyOnce = currentKey;
    await PrefsHelper.saveAIFeedback(_aiKey, isPositive);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isPositive
              ? 'Thanks for the thumbs up!'
              : 'Thanks for the feedback. I will suggest a new focus.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );

    await _loadData(showLoading: false, restoreOffset: currentOffset);
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
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
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
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyHeatmapCard(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(
      7,
      (index) => now.subtract(Duration(days: 6 - index)),
    );

    final maxCount = _weeklyData.values.isEmpty
        ? 1
        : _weeklyData.values.reduce((a, b) => a > b ? a : b);
    final safeMaxCount = maxCount < 1 ? 1 : maxCount;

    String dayLabel(DateTime date) {
      const labels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
      return labels[date.weekday - 1];
    }

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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: days.map((date) {
                final dateKey = DateFormat('yyyy-MM-dd').format(date);
                final count = _weeklyData[dateKey] ?? 0;
                final intensity = count / safeMaxCount;
                final isToday =
                    date.year == now.year &&
                    date.month == now.month &&
                    date.day == now.day;

                return Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: count == 0
                            ? Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest
                            : AppColors.primary.withValues(
                                alpha: 0.2 + (0.8 * intensity),
                              ),
                        borderRadius: BorderRadius.circular(10),
                        border: isToday
                            ? Border.all(color: AppColors.primary, width: 2)
                            : null,
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: intensity > 0.5
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dayLabel(date),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionRatesChart(BuildContext context) {
    final entries = _completionRates.entries.toList();

    String truncateHabitName(String name) {
      if (name.length <= 8) return name;
      return '${name.substring(0, 8)}..';
    }

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
            const SizedBox(height: 12),
            SizedBox(
              height: 280,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 1.0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 0.25,
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        getTitlesWidget: (value, meta) {
                          if (value == 0 || value == 0.5 || value == 1) {
                            return Text(
                              '${(value * 100).toInt()}%',
                              style: Theme.of(context).textTheme.bodySmall,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 78,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= entries.length) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Transform.rotate(
                              angle: -0.8,
                              alignment: Alignment.topRight,
                              child: SizedBox(
                                width: 62,
                                child: Text(
                                  truncateHabitName(entries[index].key),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(fontSize: 10),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: entries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final rate = entry.value.value;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: rate,
                          color: AppColors.primary,
                          width: 14,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestStreaksCard(BuildContext context) {
    final rankedHabits = _completionRates.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topHabits = rankedHabits.take(5).toList();

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
            const SizedBox(height: 10),
            ...topHabits.asMap().entries.map((entry) {
              final index = entry.key;
              final habitName = entry.value.key;
              final percentage = (entry.value.value * 100).toStringAsFixed(0);

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == topHabits.length - 1 ? 0 : 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        habitName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '$percentage%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAIBuddyCard(BuildContext context) {
    final feedback = PrefsHelper.getAIFeedback(_aiKey);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🤖', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  'AI Habit Buddy',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(_aiSuggestion, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              'Why: $_aiReason',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'Was this helpful?',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _saveFeedback(true),
                  icon: Icon(
                    feedback == true ? Icons.thumb_up : Icons.thumb_up_outlined,
                    color: feedback == true
                        ? Colors.green
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                IconButton(
                  onPressed: () => _saveFeedback(false),
                  icon: Icon(
                    feedback == false
                        ? Icons.thumb_down
                        : Icons.thumb_down_outlined,
                    color: feedback == false
                        ? Colors.red
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
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
            IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
          ],
        ),
        body: _buildEmptyState(context),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Stats'),
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _buildWeeklyHeatmapCard(context),
            const SizedBox(height: 12),
            if (_habits.isNotEmpty) ...[
              _buildCompletionRatesChart(context),
              const SizedBox(height: 12),
              _buildBestStreaksCard(context),
              const SizedBox(height: 12),
            ],
            _buildAIBuddyCard(context),
          ],
        ),
      ),
    );
  }
}
