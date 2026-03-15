import 'package:flutter/material.dart';
import 'package:habit_mastery_league/models/habit.dart';
import 'package:habit_mastery_league/utils/app_colors.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final bool isCompletedToday;
  final int streakCount;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const HabitCard({
    super.key,
    required this.habit,
    required this.isCompletedToday,
    required this.streakCount,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor =
        AppColors.categories[habit.category] ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              // category color dot 
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: categoryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),

              // Habit name + badge + streak
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Habit name (strikethrough when completed)
                    Text(
                      habit.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            decoration: isCompletedToday
                                ? TextDecoration.lineThrough
                                : null,
                            color: isCompletedToday
                                ? Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.4)
                                : null,
                          ),
                    ),
                    const SizedBox(height: 4),

                    Row(
                      children: [
                        // Category badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            habit.category,
                            style: TextStyle(
                              fontSize: 11,
                              color: categoryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        // Streak badge
                        if (streakCount > 0) ...[
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.local_fire_department,
                                size: 14,
                                color: Colors.orange,
                              ),
                              Text(
                                '$streakCount',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Complete checkbox (animation)
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompletedToday
                        ? Colors.green
                        : Colors.transparent,
                    border: Border.all(
                      color: isCompletedToday
                          ? Colors.green
                          : Colors.grey.shade400,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isCompletedToday
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 18,
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}