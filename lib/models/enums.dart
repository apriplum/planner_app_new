enum Priority { low, medium, high, critical }

extension PriorityX on Priority {
  String get label => switch (this) {
        Priority.low => 'Низкий',
        Priority.medium => 'Средний',
        Priority.high => 'Высокий',
        Priority.critical => 'Критический',
      };

  String get dbValue => name;
}

Priority priorityFromDb(String value) =>
    Priority.values.firstWhere((e) => e.name == value, orElse: () => Priority.medium);

enum TaskStatus { active, completed }

extension TaskStatusX on TaskStatus {
  String get dbValue => name;
  String get label => this == TaskStatus.active ? 'Активно' : 'Выполнено';
}

TaskStatus taskStatusFromDb(String value) =>
    value == TaskStatus.completed.name ? TaskStatus.completed : TaskStatus.active;

enum Recurrence { none, daily, weekly, weekdays, monthly, yearly, custom }

extension RecurrenceX on Recurrence {
  String get dbValue => name;
  String get label => switch (this) {
        Recurrence.none => 'Нет',
        Recurrence.daily => 'Ежедневно',
        Recurrence.weekly => 'Еженедельно',
        Recurrence.weekdays => 'По рабочим дням',
        Recurrence.monthly => 'Ежемесячно',
        Recurrence.yearly => 'Ежегодно',
        Recurrence.custom => 'Кастомная',
      };
}

Recurrence recurrenceFromDb(String value) => Recurrence.values
    .firstWhere((e) => e.name == value, orElse: () => Recurrence.none);

enum EventType { holiday, birthday, meeting, reminder, other }

extension EventTypeX on EventType {
  String get dbValue => name;
  String get label => switch (this) {
        EventType.holiday => 'Праздник',
        EventType.birthday => 'День рождения',
        EventType.meeting => 'Встреча',
        EventType.reminder => 'Напоминание',
        EventType.other => 'Другое',
      };
}

EventType eventTypeFromDb(String value) =>
    EventType.values.firstWhere((e) => e.name == value, orElse: () => EventType.other);

enum Frequency { none, daily, weekly, monthly }

extension FrequencyX on Frequency {
  String get dbValue => name;
  String get label => switch (this) {
        Frequency.none => 'Нет',
        Frequency.daily => 'Ежедневно',
        Frequency.weekly => 'Еженедельно',
        Frequency.monthly => 'Ежемесячно',
      };
}

Frequency frequencyFromDb(String value) =>
    Frequency.values.firstWhere((e) => e.name == value, orElse: () => Frequency.none);

enum SyncStatus { synced, pending, conflict, error }

extension SyncStatusX on SyncStatus {
  String get dbValue => name;
}

SyncStatus syncStatusFromDb(String value) =>
    SyncStatus.values.firstWhere((e) => e.name == value, orElse: () => SyncStatus.synced);

enum EntityType { task, event, habit }

extension EntityTypeX on EntityType {
  String get dbValue => name;
  String get label => switch (this) {
        EntityType.task => 'Задача',
        EntityType.event => 'Событие',
        EntityType.habit => 'Привычка',
      };
}

EntityType entityTypeFromDb(String value) =>
    EntityType.values.firstWhere((e) => e.name == value, orElse: () => EntityType.task);