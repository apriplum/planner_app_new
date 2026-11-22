import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../data/repositories/task_repository.dart';
import '../../models/enums.dart';
import '../../models/task.dart';
import 'task_detail_screen.dart';
import 'task_form_screen.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  Color _priorityColor(Priority priority) => switch (priority) {
        Priority.low => AppColors.lowPriority,
        Priority.medium => AppColors.mediumPriority,
        Priority.high => AppColors.highPriority,
        Priority.critical => const Color(0xFFD32F2F),
      };

  @override
  Widget build(BuildContext context) {
    final repo = context.read<TaskRepository>();

    return FutureBuilder<List<Task>>(
      future: repo.getActiveTasks('local-user'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = snapshot.data!;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Активные задачи',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Text(
                    '${tasks.length}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: tasks.isEmpty
                  ? const Center(
                      child: Text('Активных задач нет'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];

                        return Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            leading: Container(
                              width: 10,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _priorityColor(task.priority),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            title: Text(
                              task.title,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            subtitle: Text(
                              '${task.priority.label}'
                              '${task.dueDate != null ? ' · ${task.dueDate!.toIso8601String().substring(0, 10)}' : ''}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            trailing: Checkbox(
                              value: false,
                              onChanged: (_) =>
                                  repo.toggleComplete(task.id),
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    TaskDetailScreen(taskId: task.id),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}