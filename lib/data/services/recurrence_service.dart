import '../repositories/task_repository.dart';
import '../../models/enums.dart';
import '../../models/task.dart';

class RecurrenceService {
  RecurrenceService(this._taskRepository);

  final TaskRepository _taskRepository;

  Future<void> createNextOccurrence(Task task) async {
    if (!task.isRecurring || task.recurrence == Recurrence.none) return;
    if (task.dueDate == null) return;

    final nextDate = _nextDate(task.dueDate!, task.recurrence);

    if (nextDate == null) return;

    final nextTask = Task(
      id: _taskRepository.newId(),
      userId: task.userId,
      title: task.title,
      description: task.description,
      priority: task.priority,
      status: TaskStatus.active,
      categoryId: task.categoryId,
      dueDate: nextDate,
      dueTime: task.dueTime,
      reminderTime: task.reminderTime,
      isRecurring: true,
      recurrence: task.recurrence,
      difficulty: task.difficulty,
      durationMinutes: task.durationMinutes,
      color: task.color,
      icon: task.icon,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _taskRepository.create(nextTask, []);
  }

  DateTime? _nextDate(DateTime date, Recurrence recurrence) {
    switch (recurrence) {
      case Recurrence.daily:
        return date.add(const Duration(days: 1));

      case Recurrence.weekly:
        return date.add(const Duration(days: 7));

      case Recurrence.weekdays:
        var next = date.add(const Duration(days: 1));

        while (next.weekday == DateTime.saturday ||
            next.weekday == DateTime.sunday) {
          next = next.add(const Duration(days: 1));
        }

        return next;

      case Recurrence.monthly:
        var year = date.year;
        var month = date.month + 1;

        if (month > 12) {
          month = 1;
          year++;
        }

        final day = date.day;
        final lastDay = DateTime(year, month + 1, 0).day;

        return DateTime(
          year,
          month,
          day > lastDay ? lastDay : day,
        );

      case Recurrence.yearly:
        return DateTime(
          date.year + 1,
          date.month,
          date.day,
        );

      case Recurrence.custom:
      case Recurrence.none:
        return null;
    }
  }
}