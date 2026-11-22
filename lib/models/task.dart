import 'enums.dart';

class Task {
  Task({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.priority = Priority.medium,
    this.status = TaskStatus.active,
    this.categoryId,
    this.dueDate,
    this.dueTime,
    this.reminderTime,
    this.isRecurring = false,
    this.recurrence = Recurrence.none,
    this.difficulty,
    this.durationMinutes,
    this.color,
    this.icon,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.syncStatus = SyncStatus.synced,
    this.version = 1,
  });

  final String id;
  final String userId;
  String title;
  String description;
  Priority priority;
  TaskStatus status;
  String? categoryId;
  DateTime? dueDate;
  String? dueTime;
  String? reminderTime;
  bool isRecurring;
  Recurrence recurrence;
  String? difficulty;
  int? durationMinutes;
  String? color;
  String? icon;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;
  SyncStatus syncStatus;
  int version;

  bool get isOverdue {
    if (status == TaskStatus.completed || dueDate == null) return false;
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due.isBefore(date);
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'description': description,
        'priority': priority.dbValue,
        'status': status.dbValue,
        'category_id': categoryId,
        'due_date': dueDate?.toIso8601String().substring(0, 10),
        'due_time': dueTime,
        'reminder_time': reminderTime,
        'is_recurring': isRecurring ? 1 : 0,
        'recurrence': recurrence.dbValue,
        'difficulty': difficulty,
        'duration_minutes': durationMinutes,
        'color': color,
        'icon': icon,
        'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
        'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
        'sync_status': syncStatus.dbValue,
        'version': version,
      };

  static Task fromMap(Map<String, Object?> map) => Task(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        title: map['title'] as String,
        description: map['description'] as String? ?? '',
        priority: priorityFromDb(map['priority'] as String? ?? 'medium'),
        status: taskStatusFromDb(map['status'] as String? ?? 'active'),
        categoryId: map['category_id'] as String?,
        dueDate: DateTime.tryParse(map['due_date'] as String? ?? ''),
        dueTime: map['due_time'] as String?,
        reminderTime: map['reminder_time'] as String?,
        isRecurring: (map['is_recurring'] as int? ?? 0) == 1,
        recurrence: recurrenceFromDb(map['recurrence'] as String? ?? 'none'),
        difficulty: map['difficulty'] as String?,
        durationMinutes: map['duration_minutes'] as int?,
        color: map['color'] as String?,
        icon: map['icon'] as String?,
        createdAt: DateTime.tryParse(map['created_at'] as String? ?? ''),
        updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? ''),
        deletedAt: DateTime.tryParse(map['deleted_at'] as String? ?? ''),
        syncStatus: syncStatusFromDb(map['sync_status'] as String? ?? 'synced'),
        version: map['version'] as int? ?? 1,
      );
}