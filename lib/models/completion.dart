import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

const _uuid = Uuid();

class Completion {
  final String id;
  final String habitId;
  final String completedDate;

  Completion({
    String? id,
    required this.habitId,
    String? completedDate,
  })  : id = id ?? _uuid.v4(),
        completedDate = completedDate ??
            DateFormat('yyyy-MM-dd').format(DateTime.now());

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habit_id': habitId,
      'completed_date': completedDate,
    };
  }

  factory Completion.fromMap(Map<String, dynamic> map) {
    return Completion(
      id: map['id'] as String,
      habitId: map['habit_id'] as String,
      completedDate: map['completed_date'] as String,
    );
  }
}