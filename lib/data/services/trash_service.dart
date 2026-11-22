import 'dart:async';

import '../repositories/event_repository.dart';
import '../repositories/habit_repository.dart';
import '../repositories/task_repository.dart';
import '../../models/enums.dart';

class TrashItem {
  TrashItem({
    required this.id,
    required this.type,
    required this.title,
    required this.deletedAt,
  });

  final String id;
  final EntityType type;
  final String title;
  final DateTime deletedAt;

  bool canRestore(DateTime now) {
    final difference = now.difference(deletedAt);
    return difference.inDays < 30;
  }

  Duration timeLeft(DateTime now) {
    final deadline = deletedAt.add(const Duration(days: 30));
    final left = deadline.difference(now);
    return left.isNegative ? Duration.zero : left;
  }
}

class TrashService {
  TrashService({
    required TaskRepository taskRepository,
    required EventRepository eventRepository,
    required HabitRepository habitRepository,
  })  : _tasks = taskRepository,
        _events = eventRepository,
        _habits = habitRepository;

  final TaskRepository _tasks;
  final EventRepository _events;
  final HabitRepository _habits;

  final List<TrashItem> _undoBuffer = [];

  Future<List<TrashItem>> getItems(String userId) async {
  final now = DateTime.now();
  final items = <TrashItem>[];

  final tasks = await _tasks.getDeletedTasks(userId);

  for (final task in tasks) {
    if (task.deletedAt == null) continue;

    items.add(
      TrashItem(
        id: task.id,
        type: EntityType.task,
        title: task.title,
        deletedAt: task.deletedAt!,
      ),
    );
  }

  final events = await _events.getDeletedEvents(userId);

  for (final event in events) {
    if (event.deletedAt == null) continue;

    items.add(
      TrashItem(
        id: event.id,
        type: EntityType.event,
        title: event.title,
        deletedAt: event.deletedAt!,
      ),
    );
  }

  final habits = await _habits.getDeletedHabits(userId);

  for (final habit in habits) {
    if (habit.deletedAt == null) continue;

    items.add(
      TrashItem(
        id: habit.id,
        type: EntityType.habit,
        title: habit.title,
        deletedAt: habit.deletedAt!,
      ),
    );
  }

  items.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));

  return items.where((item) => item.canRestore(now)).toList();
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
        await _habits.moveToTrash(id);
        break;
    }
  }

  Future<void> restore(String id, EntityType type) async {
    final now = DateTime.now();

    switch (type) {
      case EntityType.task:
        final task = await _tasks.getById(id);
        if (task == null) throw Exception('Задача не найдена');
        if (task.deletedAt != null &&
            now.difference(task.deletedAt!).inDays >= 30) {
          throw Exception('Срок хранения записи истёк. Восстановление невозможно');
        }
        await _tasks.restore(id);
        break;

      case EntityType.event:
        final event = await _events.getById(id);
        if (event == null) throw Exception('Событие не найдено');
        if (event.deletedAt != null &&
            now.difference(event.deletedAt!).inDays >= 30) {
          throw Exception('Срок хранения записи истёк. Восстановление невозможно');
        }
        await _events.restore(id);
        break;

      case EntityType.habit:
        final habit = await _habits.getById(id);
        if (habit == null) throw Exception('Привычка не найдена');
        if (habit.deletedAt != null &&
            now.difference(habit.deletedAt!).inDays >= 30) {
          throw Exception('Срок хранения записи истёк. Восстановление невозможно');
        }
        await _habits.restore(id);
        break;
    }
  }

  Future<void> restoreBatch(List<String> ids, EntityType type) async {
    for (final id in ids) {
      await restore(id, type);
    }
  }

  Future<void> clearTrash(EntityType type) async {
    switch (type) {
      case EntityType.task:
        await _tasks.clearTrash();
        break;

      case EntityType.event:
        await _events.clearTrash();
        break;

      case EntityType.habit:
        await _habits.clearTrash();
        break;
    }
  }

  Future<void> purgeExpired() async {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 30));

    await _tasks.purgeExpired(cutoff);
    await _events.purgeExpired(cutoff);
    await _habits.purgeExpired(cutoff);
  }

  void rememberLastDeleted(TrashItem item) {
    _undoBuffer
      ..clear()
      ..add(item);
  }

  Future<void> undoLastDelete() async {
    if (_undoBuffer.isEmpty) return;
    final item = _undoBuffer.first;
    await restore(item.id, item.type);
    _undoBuffer.clear();
  }
}