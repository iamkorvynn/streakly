import 'package:material_ui/material_ui.dart';

import '../models/habit.dart';
import '../services/habit_repository.dart';
import '../utils/app_colors.dart';
import '../utils/reminder_time.dart';
import '../widgets/color_picker.dart';
import '../widgets/icon_picker.dart';

/// Create a new habit, or edit an existing one.
///
/// Picks a name, icon, colour, streak target and an optional daily
/// reminder time. Returns true from [Navigator.pop] when saved.
class AddEditHabitScreen extends StatefulWidget {
  const AddEditHabitScreen({
    super.key,
    required this.repository,
    this.habit,
  });

  final HabitRepository repository;
  final Habit? habit;

  @override
  State<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends State<AddEditHabitScreen> {
  final _nameController = TextEditingController();
  late int _iconIndex;
  late int _colorValue;
  late double _targetDays;
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  bool _saving = false;

  bool get _isEditing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    _nameController.text = habit?.name ?? '';
    _iconIndex = habit?.iconIndex ?? 0;
    _colorValue = habit?.colorValue ?? habitColorOptions.first.color.toARGB32();
    _targetDays = (habit?.targetDays ?? 30).toDouble();
    _reminderEnabled = habit?.reminderMinutes != null;
    if (habit?.reminderTimeOfDay != null) {
      _reminderTime = habit!.reminderTimeOfDay!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your habit a name first.')),
      );
      return;
    }
    setState(() => _saving = true);
    final existing = widget.habit;
    if (existing == null) {
      await widget.repository.createHabit(
        Habit(
          name: name,
          iconIndex: _iconIndex,
          colorValue: _colorValue,
          targetDays: _targetDays.round(),
          reminderMinutes: _reminderEnabled
              ? minutesFromHourMinute(_reminderTime.hour, _reminderTime.minute)
              : null,
          createdAt: DateTime.now(),
        ),
      );
    } else {
      await widget.repository.updateHabit(
        existing.copyWith(
          name: name,
          iconIndex: _iconIndex,
          colorValue: _colorValue,
          targetDays: _targetDays.round(),
          reminderMinutes: _reminderEnabled
              ? minutesFromHourMinute(_reminderTime.hour, _reminderTime.minute)
              : null,
          clearReminder: !_reminderEnabled,
        ),
      );
    }
    if (!mounted) {
      return;
    }
    // maybePop: if this screen is the root route (as in widget tests)
    // the pop is refused — reset the spinner so the UI can settle.
    final popped = await Navigator.of(context).maybePop(true);
    if (!popped && mounted) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(_colorValue);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit habit' : 'New habit'),
        actions: <Widget>[
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _nameController,
              autofocus: !_isEditing,
              maxLength: 60,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Habit name',
                hintText: 'e.g. Read 10 pages',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const _SectionLabel('Icon'),
            const SizedBox(height: 12),
            IconPicker(
              selectedIndex: _iconIndex,
              color: color,
              onSelected: (index) =>
                  setState(() => _iconIndex = index),
            ),
            const SizedBox(height: 24),
            const _SectionLabel('Colour'),
            const SizedBox(height: 12),
            ColorPicker(
              selectedValue: _colorValue,
              onSelected: (value) => setState(() => _colorValue = value),
            ),
            const SizedBox(height: 24),
            _SectionLabel('Streak target: ${_targetDays.round()} days'),
            Slider(
              value: _targetDays,
              min: 7,
              max: 365,
              divisions: 358,
              label: '${_targetDays.round()} days',
              activeColor: color,
              onChanged: (value) => setState(() => _targetDays = value),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  '7 days',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '365 days',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Daily reminder'),
              subtitle: const Text('Get a nudge at the same time each day'),
              value: _reminderEnabled,
              activeThumbColor: color,
              onChanged: (value) =>
                  setState(() => _reminderEnabled = value),
              contentPadding: EdgeInsets.zero,
            ),
            if (_reminderEnabled)
              ListTile(
                leading: Icon(Icons.alarm, color: color),
                title: const Text('Reminder time'),
                trailing: Text(
                  formatReminderMinutes12h(
                    minutesFromHourMinute(
                      _reminderTime.hour,
                      _reminderTime.minute,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
                onTap: _pickTime,
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isEditing ? 'Save changes' : 'Create habit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    );
  }
}
