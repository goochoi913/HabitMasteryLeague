import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:habit_mastery_league/db/database_helper.dart';
import 'package:habit_mastery_league/providers/theme_provider.dart';
import 'package:habit_mastery_league/utils/prefs_helper.dart';
import 'package:habit_mastery_league/widgets/loading_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _loading = true;
  String? _reminderTime;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    _nameController.text = PrefsHelper.getUsername();
    _reminderTime = PrefsHelper.getReminderTime();

    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveUsername() async {
    final trimmed = _nameController.text.trim();
    if (trimmed.isEmpty) return;

    await PrefsHelper.setUsername(trimmed);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Display name saved.'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    setState(() {});
  }

  Future<void> _pickReminderTime() async {
    final initialTime = _parseStoredTime(_reminderTime) ?? TimeOfDay.now();

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked == null) return;

    final formatted = _formatTimeOfDay(picked);
    await PrefsHelper.setReminderTime(formatted);

    if (!mounted) return;
    setState(() {
      _reminderTime = formatted;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder time set to $formatted'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _resetAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset all data?'),
          content: const Text(
            'This will permanently delete all habits and completion history.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await DatabaseHelper.instance.deleteAllData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All habit data has been reset.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      final habits = await DatabaseHelper.instance.getAllHabits();
      final exportPayload = <Map<String, dynamic>>[];

      for (final habit in habits) {
        final completions = await DatabaseHelper.instance
            .getCompletionsForHabit(habit.id);
        exportPayload.add({
          'habit': habit.toMap(),
          'completions': completions
              .map((completion) => completion.toMap())
              .toList(),
        });
      }

      final encoder = const JsonEncoder.withIndent('  ');
      final jsonContent = encoder.convert(exportPayload);
      final documentsDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${documentsDir.path}/habit_export_$timestamp.json';
      final file = File(filePath);

      await file.writeAsString(jsonContent);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported JSON to: $filePath'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to export data.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  TimeOfDay? _parseStoredTime(String? value) {
    if (value == null || !value.contains(':')) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Widget _buildSectionLabel(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildThemeModeIcon(BuildContext context, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        );
      },
      child: Container(
        key: ValueKey<bool>(isDark),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark
              ? colorScheme.primary.withValues(alpha: 0.18)
              : colorScheme.tertiary.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          isDark ? Icons.dark_mode : Icons.light_mode,
          color: isDark ? colorScheme.primary : colorScheme.tertiary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: SafeArea(child: LoadingState(message: 'Loading settings...')),
      );
    }

    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _buildSectionLabel(context, 'Profile'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _saveUsername(),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person),
                      labelText: 'Display Name',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.save),
                        onPressed: _saveUsername,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildSectionLabel(context, 'Appearance'),
          Card(
            child: SwitchListTile(
              value: isDark,
              onChanged: (_) => themeProvider.toggleTheme(),
              title: const Text('Dark Mode'),
              subtitle: Text(isDark ? 'Enabled' : 'Disabled'),
              secondary: _buildThemeModeIcon(context, isDark),
            ),
          ),
          const SizedBox(height: 12),
          _buildSectionLabel(context, 'Notifications'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.alarm),
              title: const Text('Daily Reminder'),
              subtitle: Text(_reminderTime ?? 'Not set'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickReminderTime,
            ),
          ),
          const SizedBox(height: 12),
          _buildSectionLabel(context, 'Data'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_file, color: Colors.blue),
                  title: const Text('Export Data (JSON)'),
                  subtitle: const Text(
                    'Save all habits and history as a JSON file',
                  ),
                  onTap: _exportData,
                ),
                Divider(
                  height: 1,
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_forever,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Reset All Data',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text('Delete all habits and history'),
                  onTap: _resetAllData,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Habit Mastery League\n1.0.0 • Team Bok Choy\nCSC 4360',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
