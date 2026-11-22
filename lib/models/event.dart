import 'enums.dart';

class PlannerEvent {
  PlannerEvent({
    required this.id,
    required this.userId,
    required this.title,
    this.eventType = EventType.other,
    this.location,
    this.description = '',
    this.color,
    required this.startDate,
    required this.startTime,
    required this.endDate,
    required this.endTime,
    this.reminderTime,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.syncStatus = SyncStatus.synced,
    this.version = 1,
  });

  final String id;
  final String userId;
  String title;
  EventType eventType;
  String? location;
  String description;
  String? color;
  DateTime startDate;
  String startTime;
  DateTime endDate;
  String endTime;
  String? reminderTime;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;
  SyncStatus syncStatus;
  int version;

  DateTime get startDateTime => _combine(startDate, startTime);
  DateTime get endDateTime => _combine(endDate, endTime);

  DateTime _combine(DateTime date, String time) {
    final parts = time.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  bool isOverdue(DateTime now) => endDateTime.isBefore(now);

  bool overlaps(PlannerEvent other) {
    return startDateTime.isBefore(other.endDateTime) &&
        other.startDateTime.isBefore(endDateTime);
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'event_type': eventType.dbValue,
        'location': location,
        'description': description,
        'color': color,
        'start_date': startDate.toIso8601String().substring(0, 10),
        'start_time': startTime,
        'end_date': endDate.toIso8601String().substring(0, 10),
        'end_time': endTime,
        'reminder_time': reminderTime,
        'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
        'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
        'sync_status': syncStatus.dbValue,
        'version': version,
      };

  static PlannerEvent fromMap(Map<String, Object?> map) => PlannerEvent(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        title: map['title'] as String,
        eventType: eventTypeFromDb(map['event_type'] as String? ?? 'other'),
        location: map['location'] as String?,
        description: map['description'] as String? ?? '',
        color: map['color'] as String?,
        startDate: DateTime.parse(map['start_date'] as String),
        startTime: map['start_time'] as String,
        endDate: DateTime.parse(map['end_date'] as String),
        endTime: map['end_time'] as String,
        reminderTime: map['reminder_time'] as String?,
        createdAt: DateTime.tryParse(map['created_at'] as String? ?? ''),
        updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? ''),
        deletedAt: DateTime.tryParse(map['deleted_at'] as String? ?? ''),
        syncStatus: syncStatusFromDb(map['sync_status'] as String? ?? 'synced'),
        version: map['version'] as int? ?? 1,
      );
}