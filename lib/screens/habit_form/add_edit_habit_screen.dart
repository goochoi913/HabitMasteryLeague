import 'package:flutter/material.dart';
import '../../db/database_helper.dart';
import '../../models/habit.dart';

class AddEditHabitScreen extends StatefulWidget {
  final Habit? habit;
  const AddEditHabitScreen({super.key, this.habit});

  @override
  State<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends State<AddEditHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _category = 'Health';
  String _frequency = 'Daily';
  bool _isSaving = false;

  bool get _isEdit => widget.habit != null;

  static const _categories = ['Health', 'Study', 'Fitness', 'Mindfulness', 'Other'];
  static const _frequencies = ['Daily', 'Weekdays', 'Weekends'];

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nameController.text = widget.habit!.name;
      _descController.text = widget.habit!.description ?? '';
      _category = widget.habit!.category;
      _frequency = widget.habit!.frequency;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final db = DatabaseHelper.instance;
    final desc = _descController.text.trim().isEmpty ? null : _descController.text.trim();

    if (_isEdit) {
      await db.updateHabit(widget.habit!.copyWith(
        name: _nameController.text.trim(),
        category: _category,
        frequency: _frequency,
        description: desc,
      ));
    } else {
      await db.insertHabit(Habit(
        name: _nameController.text.trim(),
        category: _category,
        frequency: _frequency,
        description: desc,
      ));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEdit ? 'Habit updated!' : 'Habit created!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Delete "${widget.habit!.name}"? All completion history will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await DatabaseHelper.instance.deleteHabit(widget.habit!.id);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Habit' : 'New Habit'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Name
            Text('Habit Name', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'e.g. Drink 8 glasses of water',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLength: 60,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Name is required';
                if (v.trim().length < 3) return 'Name must be at least 3 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category
            Text('Category', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),

            // Frequency
            Text('Frequency', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _frequency,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _frequencies.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
              onChanged: (v) => setState(() => _frequency = v!),
            ),
            const SizedBox(height: 16),

            // Description
            Text('Description (optional)', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                hintText: 'Add a note...',
                border: OutlineInputBorder(),
                counterText: '',
              ),
              maxLines: 3,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) =>
                  Text('$currentLength / $maxLength',
                      style: Theme.of(context).textTheme.bodySmall),
            ),
            const SizedBox(height: 32),

            // Buttons
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEdit ? 'Save Changes' : 'Create Habit'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}