import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/validators.dart';
import '../../data/repositories/event_repository.dart';
import '../../models/enums.dart';
import '../../models/event.dart';

class EventFormScreen extends StatefulWidget {
  const EventFormScreen({super.key, this.event});

  final PlannerEvent? event;

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  EventType _type = EventType.meeting;
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);
  String _color = '#5E6AD2';

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _format(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = context.read<EventRepository>();

    final event = widget.event ??
        PlannerEvent(
          id: repo.newId(),
          userId: 'local-user',
          title: _titleController.text.trim(),
          eventType: _type,
          location: _locationController.text.trim(),
          description: _descriptionController.text.trim(),
          color: _color,
          startDate: _startDate,
          startTime: _format(_startTime),
          endDate: _endDate,
          endTime: _format(_endTime),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

    if (widget.event != null) {
      event.title = _titleController.text.trim();
      event.eventType = _type;
      event.location = _locationController.text.trim();
      event.description = _descriptionController.text.trim();
      event.color = _color;
      event.startDate = _startDate;
      event.startTime = _format(_startTime);
      event.endDate = _endDate;
      event.endTime = _format(_endTime);
    }

    final overlap = await repo.hasOverlap(event);

    if (overlap) {
      if (!mounted) return;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Пересечение событий'),
          content: const Text(
            'Время пересекается с другим событием. Сохранить всё равно?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Изменить время'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Сохранить'),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    if (widget.event == null) {
      await repo.create(event);
    } else {
      await repo.update(event);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.event == null ? 'Создание события' : 'Редактирование события',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Название события'),
              validator: (value) =>
                  Validators.title(value, AppStrings.enterEventTitle),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<EventType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Тип события'),
              items: EventType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _type = value!),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text(
                'Начало: ${_startDate.toIso8601String().substring(0, 10)}, ${_format(_startTime)}',
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (date != null) setState(() => _startDate = date);

                final time = await showTimePicker(
                  context: context,
                  initialTime: _startTime,
                );
                if (time != null) setState(() => _startTime = time);
              },
            ),
            ListTile(
              title: Text(
                'Окончание: ${_endDate.toIso8601String().substring(0, 10)}, ${_format(_endTime)}',
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _endDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (date != null) setState(() => _endDate = date);

                final time = await showTimePicker(
                  context: context,
                  initialTime: _endTime,
                );
                if (time != null) setState(() => _endTime = time);
              },
            ),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Место проведения'),
              validator: Validators.location,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Описание'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _color,
              decoration: const InputDecoration(labelText: 'Цветовая метка'),
              items: const [
                DropdownMenuItem(value: '#5E6AD2', child: Text('Фиолетово-синий')),
                DropdownMenuItem(value: '#FF6B6B', child: Text('Красный')),
                DropdownMenuItem(value: '#FFA500', child: Text('Оранжевый')),
                DropdownMenuItem(value: '#4ECDC4', child: Text('Бирюзовый')),
              ],
              onChanged: (value) => setState(() => _color = value!),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}