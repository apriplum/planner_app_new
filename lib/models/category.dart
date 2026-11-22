class Category {
  Category({
    required this.id,
    required this.userId,
    required this.name,
    this.color,
    this.createdAt,
  });

  final String id;
  final String userId;
  String name;
  String? color;
  DateTime? createdAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'color': color,
        'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      };

  static Category fromMap(Map<String, Object?> map) => Category(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        name: map['name'] as String,
        color: map['color'] as String?,
        createdAt: DateTime.tryParse(map['created_at'] as String? ?? ''),
      );
}