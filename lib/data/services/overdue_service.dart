import '../repositories/event_repository.dart';
import '../repositories/task_repository.dart';
import '../../models/enums.dart';
import '../../models/event.dart';
import '../../models/task.dart';

class OverdueService {
  OverdueService({
    required TaskRepository taskRepository,
    required EventRepository eventRepository,
  })  : _tasks = taskRepository,
        _events = eventRepository;

  final TaskRepository _tasks;
  final EventRepository _events;

  Future<List<Task>> getOverdueTasks(String userId) =>
      _tasks.getOverdueTasks(userId);

  Future<List<PlannerEvent>> getOverdueEvents(String userId) =>
      _events.getOverdue(userId);

  Future<void> markCompleted(String taskId) => _tasks.toggleComplete(taskId);

  Future<void> rescheduleTasks(List<String> ids, DateTime newDate) =>
      _tasks.reschedule(ids, newDate);

  Future<void> rescheduleEvent(
    String eventId,
    DateTime newDate,
    String newTime,
  ) async {
    final event = await _events.getById(eventId);
    if (event == null) throw Exception('Событие не найдено');

    event.startDate = newDate;
    event.endDate = newDate;
    event.startTime = newTime;
    event.endTime = newTime;

    await _events.update(event);
  }

  Future<void> moveToTrash(String id, EntityType type) async {
    switch (type) {
      case EntityType.task:
        await _tasks.moveToTrash(id);
        break;
      case EntityType.event:
        await _events.moveToTrash(id);
        break;
      case EntityType.habit:
        break;
    }
  }
}