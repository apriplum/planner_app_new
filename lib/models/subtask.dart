class Subtask {
  Subtask({
    required this.id,
    required this.taskId,
    required this.title,
    this.isCompleted = false,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String taskId;
  String title;
  bool isCompleted;
  int sortOrder;
  DateTime? createdAt;
  DateTime? updatedAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'task_id': taskId,
        'title': title,
        'is_completed': isCompleted ? 1 : 0,
        'sort_order': sortOrder,
        'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
        'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
      };

  static Subtask fromMap(Map<String, Object?> map) => Subtask(
        id: map['id'] as String,
        taskId: map['task_id'] as String,
        title: map['title'] as String,
        isCompleted: (map['is_completed'] as int? ?? 0) == 1,
        sortOrder: map['sort_order'] as int? ?? 0,
        createdAt: DateTime.tryParse(map['created_at'] as String? ?? ''),
        updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? ''),
      );
}