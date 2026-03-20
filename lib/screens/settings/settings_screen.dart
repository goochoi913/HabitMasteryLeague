import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: SafeArea(
          child: LoadingState(message: 'Loading settings...'),
        ),
      );
    }

    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
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
          Card(
            child: SwitchListTile(
              value: isDark,
              onChanged: (_) => themeProvider.toggleTheme(),
              title: const Text('Dark Mode'),
              subtitle: Text(isDark ? 'Enabled' : 'Disabled'),
              secondary: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  key: ValueKey<bool>(isDark),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
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
          Card(
            child: ListTile(
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
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Habit Mastery League\n1.0.0 • Team Bok Choy\nCSC 4360',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}