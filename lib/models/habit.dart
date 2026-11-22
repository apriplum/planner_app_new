import 'enums.dart';

class Habit {
  Habit({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.frequency = Frequency.daily,
    this.targetValue = 1,
    this.unit,
    this.color,
    required this.startDate,
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
  String description;
  Frequency frequency;
  int targetValue;
  String? unit;
  String? color;
  DateTime startDate;
  String? reminderTime;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;
  SyncStatus syncStatus;
  int version;

  bool get isQuantitative => targetValue > 1;

  Map<String, Object?> toMap() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'description': description,
        'frequency': frequency.dbValue,
        'target_value': targetValue,
        'unit': unit,
        'color': color,
        'start_date': startDate.toIso8601String().substring(0, 10),
        'reminder_time': reminderTime,
        'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
        'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
        'sync_status': syncStatus.dbValue,
        'version': version,
      };

  static Habit fromMap(Map<String, Object?> map) => Habit(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        title: map['title'] as String,
        description: map['description'] as String? ?? '',
        frequency: frequencyFromDb(map['frequency'] as String? ?? 'daily'),
        targetValue: map['target_value'] as int? ?? 1,
        unit: map['unit'] as String?,
        color: map['color'] as String?,
        startDate: DateTime.parse(map['start_date'] as String),
        reminderTime: map['reminder_time'] as String?,
        createdAt: DateTime.tryParse(map['created_at'] as String? ?? ''),
        updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? ''),
        deletedAt: DateTime.tryParse(map['deleted_at'] as String? ?? ''),
        syncStatus: syncStatusFromDb(map['sync_status'] as String? ?? 'synced'),
        version: map['version'] as int? ?? 1,
      );
}