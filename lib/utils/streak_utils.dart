import 'package:habit_mastery_league/models/completion.dart';

DateTime _normalizeDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

List<DateTime> _uniqueCompletionDates(List<Completion> completions) {
  return completions
      .map(
        (completion) =>
            _normalizeDate(DateTime.parse(completion.completedDate)),
      )
      .toSet()
      .toList();
}

int calculateCurrentStreak(List<Completion> completions) {
  if (completions.isEmpty) return 0;

  final dates = _uniqueCompletionDates(completions)
    ..sort((a, b) => b.compareTo(a));

  int counter = 0;
  var checkDate = _normalizeDate(DateTime.now());

  for (final date in dates) {
    final diff = checkDate.difference(date).inDays;

    if (diff <= 1 && diff >= 0) {
      counter++;
      checkDate = date;
    } else if (diff > 1) {
      break;
    }
  }

  return counter;
}

int calculateBestStreak(List<Completion> completions) {
  if (completions.isEmpty) return 0;

  final dates = _uniqueCompletionDates(completions)
    ..sort((a, b) => a.compareTo(b));

  int best = 1;
  int current = 1;

  for (var i = 1; i < dates.length; i++) {
    final diff = dates[i].difference(dates[i - 1]).inDays;

    if (diff == 1) {
      current++;
      if (current > best) {
        best = current;
      }
    } else {
      current = 1;
    }
  }

  return best;
}
