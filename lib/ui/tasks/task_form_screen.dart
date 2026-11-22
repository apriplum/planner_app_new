import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/validators.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../models/enums.dart';
import '../../models/subtask.dart';
import '../../models/task.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.task});

  final Task? task;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _subtaskController = TextEditingController();

  Priority _priority = Priority.medium;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  bool _isRecurring = false;
  Recurrence _recurrence = Recurrence.none;
  final List<String> _subtasks = [];

  @override
  void initState() {
    super.initState();

    final task = widget.task;

    if (task != null) {
      _titleController.text = task.title;
      _descriptionController.text = task.description;
      _categoryController.text = task.categoryId ?? '';
      _priority = task.priority;
      _dueDate = task.dueDate;
      _isRecurring = task.isRecurring;
      _recurrence = task.recurrence;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final taskRepo = context.read<TaskRepository>();
    final categoryRepo = context.read<CategoryRepository>();

    String? categoryId;

    if (_categoryController.text.trim().isNotEmpty) {
      final category = await categoryRepo.getOrCreate(
        userId: 'local-user',
        name: _categoryController.text.trim(),
      );

      categoryId = category.id;
    }

    final task = widget.task;

    if (task == null) {
      final newTask = Task(
        id: taskRepo.newId(),
        userId: 'local-user',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _priority,
        categoryId: categoryId,
        dueDate: _dueDate,
        dueTime: _dueTime == null
            ? null
            : '${_dueTime!.hour.toString().padLeft(2, '0')}:'
                '${_dueTime!.minute.toString().padLeft(2, '0')}',
        isRecurring: _isRecurring,
        recurrence: _recurrence,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final subtasks = _subtasks
          .map(
            (title) => Subtask(
              id: const Uuid().v4(),
              taskId: newTask.id,
              title: title,
            ),
          )
          .toList();

      await taskRepo.create(newTask, subtasks);
    } else {
      task.title = _titleController.text.trim();
      task.description = _descriptionController.text.trim();
      task.priority = _priority;
      task.categoryId = categoryId;
      task.dueDate = _dueDate;
      task.dueTime = _dueTime == null
          ? null
          : '${_dueTime!.hour.toString().padLeft(2, '0')}:'
              '${_dueTime!.minute.toString().padLeft(2, '0')}';
      task.isRecurring = _isRecurring;
      task.recurrence = _recurrence;

      await taskRepo.update(task);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.task == null
              ? 'Новая задача'
              : 'Редактирование задачи',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              maxLength: AppLimits.titleMaxLength,
              decoration: const InputDecoration(
                labelText: 'Название задачи',
                hintText: 'Например: Подготовить отчёт',
              ),
              validator: (value) =>
                  Validators.title(value, AppStrings.enterTaskTitle),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: AppLimits.descriptionMaxLength,
              decoration: const InputDecoration(
                labelText: 'Описание',
                hintText: 'Добавьте детали задачи',
                alignLabelWithHint: true,
              ),
              validator: Validators.description,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Priority>(
              initialValue: _priority,
              decoration: const InputDecoration(
                labelText: 'Приоритет',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              items: Priority.values
                  .map(
                    (priority) => DropdownMenuItem(
                      value: priority,
                      child: Text(priority.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _priority = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Категория / проект',
                prefixIcon: Icon(Icons.folder_outlined),
              ),
              validator: Validators.category,
            ),
            const SizedBox(height: 16),
            _DateTile(
              icon: Icons.event_outlined,
              title: _dueDate == null
                  ? 'Срок выполнения'
                  : 'Срок: ${_dueDate!.toIso8601String().substring(0, 10)}',
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );

                if (date != null) setState(() => _dueDate = date);
              },
            ),
            const SizedBox(height: 12),
            _DateTile(
              icon: Icons.access_time,
              title: _dueTime == null
                  ? 'Время выполнения'
                  : 'Время: ${_dueTime!.format(context)}',
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _dueTime ?? TimeOfDay.now(),
                );

                if (time != null) setState(() => _dueTime = time);
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Повторяющаяся задача'),
              subtitle: const Text('Создавать задачу по расписанию'),
              value: _isRecurring,
              onChanged: (value) => setState(() => _isRecurring = value),
            ),
            if (_isRecurring) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<Recurrence>(
                initialValue: _recurrence,
                decoration: const InputDecoration(
                  labelText: 'Периодичность',
                  prefixIcon: Icon(Icons.repeat),
                ),
                items: Recurrence.values
                    .map(
                      (recurrence) => DropdownMenuItem(
                        value: recurrence,
                        child: Text(recurrence.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _recurrence = value!),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Подзадачи',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _subtaskController,
                    decoration: const InputDecoration(
                      hintText: 'Новая подзадача',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () {
                    final value = _subtaskController.text.trim();
                    if (value.isEmpty) return;

                    setState(() {
                      _subtasks.add(value);
                      _subtaskController.clear();
                    });
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_subtasks.isEmpty)
              const Text(
                'Подзадачи не добавлены',
                style: TextStyle(color: Color(0xFF6C757D)),
              )
            else
              ..._subtasks.asMap().entries.map(
                    (entry) => Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.subdirectory_arrow_right,
                        ),
                        title: Text(entry.value),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(
                            () => _subtasks.removeAt(entry.key),
                          ),
                        ),
                      ),
                    ),
                  ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _save,
              child: const Text('Сохранить задачу'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE9ECEF)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}