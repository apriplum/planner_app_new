import 'enums.dart';

class HabitTrack {
  HabitTrack({
    required this.id,
    required this.habitId,
    required this.trackDate,
    this.value = 0,
    this.note,
    this.isCompleted = false,
    this.syncStatus = SyncStatus.synced,
    this.version = 1,
  });

  final String id;
  final String habitId;
  final DateTime trackDate;
  int value;
  String? note;
  bool isCompleted;
  SyncStatus syncStatus;
  int version;

  Map<String, Object?> toMap() => {
        'id': id,
        'habit_id': habitId,
        'track_date': trackDate.toIso8601String().substring(0, 10),
        'value': value,
        'note': note,
        'is_completed': isCompleted ? 1 : 0,
        'sync_status': syncStatus.dbValue,
        'version': version,
      };

  static HabitTrack fromMap(Map<String, Object?> map) => HabitTrack(
        id: map['id'] as String,
        habitId: map['habit_id'] as String,
        trackDate: DateTime.parse(map['track_date'] as String),
        value: map['value'] as int? ?? 0,
        note: map['note'] as String?,
        isCompleted: (map['is_completed'] as int? ?? 0) == 1,
        syncStatus: syncStatusFromDb(map['sync_status'] as String? ?? 'synced'),
        version: map['version'] as int? ?? 1,
      );
}