import 'package:flutter/material.dart';

// Stub — Eva or Phase 3 will build the full detail screen.
class HabitDetailScreen extends StatelessWidget {
  final String habitId;

  const HabitDetailScreen({super.key, required this.habitId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Habit Detail')),
      body: const Center(
        child: Text('Habit Detail — Coming in Phase 3'),
      ),
    );
  }
}