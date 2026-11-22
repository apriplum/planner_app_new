import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/services/overdue_service.dart';
import '../models/enums.dart';
import '../models/event.dart';
import '../models/task.dart';

class OverdueScreen extends StatefulWidget {
  const OverdueScreen({super.key});

  @override
  State<OverdueScreen> createState() => _OverdueScreenState();
}

class _OverdueScreenState extends State<OverdueScreen> {
  final Set<String> _selectedTaskIds = {};

  @override
  Widget build(BuildContext context) {
    final service = context.read<OverdueService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Просроченные записи'),
        actions: [
          IconButton(
            tooltip: 'Перенести выбранные',
            icon: const Icon(Icons.event_repeat),
            onPressed: _selectedTaskIds.isEmpty
                ? null
                : () => _rescheduleSelected(service),
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          service.getOverdueTasks('local-user'),
          service.getOverdueEvents('local-user'),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = snapshot.data![0] as List<Task>;
          final events = snapshot.data![1] as List<PlannerEvent>;

          if (tasks.isEmpty && events.isEmpty) {
            return const Center(
              child: Text('Просроченных записей нет'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (tasks.isNotEmpty) ...[
                Text(
                  'Просроченные задачи',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ...tasks.map(
                  (task) => Card(
                    color: Colors.red.shade50,
                    child: CheckboxListTile(
                      value: _selectedTaskIds.contains(task.id),
                      title: Text(task.title),
                      subtitle: Text(
                        'Просрочено: '
                        '${task.dueDate?.toIso8601String().substring(0, 10) ?? '—'}',
                      ),
                      onChanged: (value) {
                        setState(() {
                          value == true
                              ? _selectedTaskIds.add(task.id)
                              : _selectedTaskIds.remove(task.id);
                        });
                      },
                      secondary: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check),
                            tooltip: 'Выполнить',
                            onPressed: () =>
                                service.markCompleted(task.id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'В корзину',
                            onPressed: () => service.moveToTrash(
                              task.id,
                              EntityType.task,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              if (events.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Прошедшие события',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ...events.map(
                  (event) => Card(
                    color: Colors.grey.shade200,
                    child: ListTile(
                      title: Text(event.title),
                      subtitle: Text(
                        'Завершено: '
                        '${event.endDate.toIso8601String().substring(0, 10)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_calendar),
                        tooltip: 'Перенести',
                        onPressed: () => service.rescheduleEvent(
                          event.id,
                          DateTime.now().add(const Duration(days: 1)),
                          '10:00',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _rescheduleSelected(OverdueService service) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (date == null) return;

    await service.rescheduleTasks(
      _selectedTaskIds.toList(),
      date,
    );

    setState(() => _selectedTaskIds.clear());
  }
}