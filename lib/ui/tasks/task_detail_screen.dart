import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/task_repository.dart';
import '../../models/enums.dart';
import '../../models/subtask.dart';
import '../../models/task.dart';
import 'task_form_screen.dart';
import '../../data/services/recurrence_service.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final repo = context.read<TaskRepository>();

    return FutureBuilder<Task?>(
      future: repo.getById(widget.taskId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text('Задача не найдена')),
          );
        }

        final task = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(task.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskFormScreen(task: task),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await repo.moveToTrash(task.id);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
          body: FutureBuilder<List<Subtask>>(
            future: repo.getSubtasks(task.id),
            builder: (context, subtaskSnapshot) {
              final subtasks = subtaskSnapshot.data ?? [];
              final completed = subtasks.where((s) => s.isCompleted).length;
              final progress =
                  subtasks.isEmpty ? 0 : (completed / subtasks.length * 100).round();

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(task.description.isEmpty ? 'Без описания' : task.description),
                  const SizedBox(height: 16),
                  Text('Приоритет: ${task.priority.label}'),
                  Text('Статус: ${task.status.label}'),
                  if (task.dueDate != null)
                    Text(
                      'Срок: ${task.dueDate!.toIso8601String().substring(0, 10)}',
                    ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: progress / 100),
                  const SizedBox(height: 16),
                  Text('Подзадачи: $completed из ${subtasks.length}'),
                  ...subtasks.map(
                    (subtask) => CheckboxListTile(
                      value: subtask.isCompleted,
                      title: Text(subtask.title),
                      onChanged: (value) async {
                        subtask.isCompleted = value ?? false;
                        await repo.updateSubtask(subtask);
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () async {
                      final recurrenceService = context.read<RecurrenceService>();

                      await repo.toggleComplete(task.id);
                      await recurrenceService.createNextOccurrence(task);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Text(
                      task.status == TaskStatus.active
                          ? 'Отметить выполненной'
                          : 'Вернуть в активные',
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}