class AppUser {
  AppUser({
    required this.id,
    required this.yandexId,
    required this.email,
    required this.createdAt,
    this.lastLogin,
    this.syncEnabled = false,
  });

  final String id;
  final String yandexId;
  final String email;
  final DateTime createdAt;
  DateTime? lastLogin;
  bool syncEnabled;

  Map<String, Object?> toMap() => {
        'id': id,
        'yandex_id': yandexId,
        'email': email,
        'created_at': createdAt.toIso8601String(),
        'last_login': lastLogin?.toIso8601String(),
        'sync_enabled': syncEnabled ? 1 : 0,
      };

  static AppUser fromMap(Map<String, Object?> map) => AppUser(
        id: map['id'] as String,
        yandexId: map['yandex_id'] as String,
        email: map['email'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        lastLogin: DateTime.tryParse(map['last_login'] as String? ?? ''),
        syncEnabled: (map['sync_enabled'] as int? ?? 0) == 1,
      );
}