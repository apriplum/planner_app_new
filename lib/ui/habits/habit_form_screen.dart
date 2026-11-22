import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/validators.dart';
import '../../data/repositories/habit_repository.dart';
import '../../models/enums.dart';
import '../../models/habit.dart';

class HabitFormScreen extends StatefulWidget {
  const HabitFormScreen({super.key, this.habit});

  final Habit? habit;

  @override
  State<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController(text: '1');
  final _unitController = TextEditingController();

  Frequency _frequency = Frequency.daily;
  DateTime _startDate = DateTime.now();
  TimeOfDay? _reminderTime;
  String _color = '#5E6AD2';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = context.read<HabitRepository>();
    final target = int.parse(_targetController.text.trim());

    final habit = widget.habit ??
        Habit(
          id: repo.newId(),
          userId: 'local-user',
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          frequency: _frequency,
          targetValue: target,
          unit: _unitController.text.trim(),
          color: _color,
          startDate: _startDate,
          reminderTime: _reminderTime == null
              ? null
              : '${_reminderTime!.hour.toString().padLeft(2, '0')}:'
                  '${_reminderTime!.minute.toString().padLeft(2, '0')}',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

    if (await repo.isDuplicate(habit)) {
      if (!mounted) return;
      final rename = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Возможный дубликат'),
          content: const Text(
            'Привычка с таким названием и периодичностью уже существует. Переименовать?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Объединить'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Переименовать'),
            ),
          ],
        ),
      );

      if (rename == true) {
        habit.title = '${habit.title} (новая)';
      }
    }

    if (widget.habit == null) {
      await repo.create(habit);
    } else {
      habit.title = _titleController.text.trim();
      habit.description = _descriptionController.text.trim();
      habit.frequency = _frequency;
      habit.targetValue = target;
      habit.unit = _unitController.text.trim();
      habit.color = _color;
      habit.startDate = _startDate;
      await repo.update(habit);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.habit == null ? 'Создание привычки' : 'Редактирование привычки',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Название привычки'),
              validator: (value) =>
                  Validators.title(value, AppStrings.enterHabitTitle),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Цель'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Frequency>(
              initialValue: _frequency,
              decoration: const InputDecoration(labelText: 'Периодичность'),
              items: Frequency.values
                  .map(
                    (frequency) => DropdownMenuItem(
                      value: frequency,
                      child: Text(frequency.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _frequency = value!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _targetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Целевой показатель'),
              validator: Validators.targetValue,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _unitController,
              maxLength: AppLimits.unitMaxLength,
              decoration: const InputDecoration(
                labelText: 'Единица измерения',
                hintText: 'минуты, шаги, страницы',
              ),
            ),
            ListTile(
              title: Text(
                'Начало: ${_startDate.toIso8601String().substring(0, 10)}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (date != null) setState(() => _startDate = date);
              },
            ),
            ListTile(
              title: Text(
                _reminderTime == null
                    ? 'Время напоминания'
                    : 'Напоминание: ${_reminderTime!.format(context)}',
              ),
              trailing: const Icon(Icons.notifications_outlined),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _reminderTime ?? TimeOfDay.now(),
                );
                if (time != null) setState(() => _reminderTime = time);
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: const Text('Создать'),
            ),
          ],
        ),
      ),
    );
  }
}