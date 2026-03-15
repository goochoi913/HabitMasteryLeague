import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Habit {
  final String id;
  final String name;
  final String category;
  final String frequency;
  final String? description;
  final String createdAt;
  final bool isActive;

  Habit({
    String? id,
    required this.name,
    required this.category,
    required this.frequency,
    this.description,
    String? createdAt,
    this.isActive = true,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'frequency': frequency,
      'description': description,
      'created_at': createdAt,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      frequency: map['frequency'] as String,
      description: map['description'] as String?,
      createdAt: map['created_at'] as String,
      isActive: (map['is_active'] as int) == 1,
    );
  }

  Habit copyWith({
    String? id,
    String? name,
    String? category,
    String? frequency,
    String? description,
    String? createdAt,
    bool? isActive,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}