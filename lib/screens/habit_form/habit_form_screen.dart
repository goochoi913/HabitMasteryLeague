import 'package:flutter/material.dart';
import '../../db/database_helper.dart';
import '../../models/habit.dart';

class HabitFormScreen extends StatefulWidget {
  final Habit? habit; // null = create mode, non-null = edit mode

  const HabitFormScreen({super.key, this.habit});

  @override
  State<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'Health';
  String _selectedFrequency = 'Daily';
  bool _isSaving = false;

  final List<String> _categories = [
    'Health',
    'Study',
    'Fitness',
    'Mindfulness',
    'Other',
  ];

  final List<String> _frequencies = [
    'Daily',
    'Weekdays',
    'Weekends',
  ];

  bool get _isEditMode => widget.habit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _nameController.text = widget.habit!.name;
      _descriptionController.text = widget.habit!.description ?? '';
      _selectedCategory = widget.habit!.category;
      _selectedFrequency = widget.habit!.frequency;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final db = DatabaseHelper.instance;

    if (_isEditMode) {
      final updated = widget.habit!.copyWith(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        frequency: _selectedFrequency,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );
      await db.updateHabit(updated);
    } else {
      final newHabit = Habit(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        frequency: _selectedFrequency,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );
      await db.insertHabit(newHabit);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Habit' : 'New Habit'),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Name ──
            Text('Habit Name',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'e.g. Drink 8 glasses of water',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 24),

            // ── Category ──
            Text('Category', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── Frequency ──
            Text('Frequency', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedFrequency,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _frequencies
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedFrequency = v!),
            ),
            const SizedBox(height: 24),

            // ── Description ──
            Text('Description (optional)',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Add a note...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 32),

            // ── Buttons ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEditMode ? 'Save Changes' : 'Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}