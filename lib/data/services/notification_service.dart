import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await init();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final granted =
        await android?.requestNotificationsPermission() ?? false;

    return granted;
  }

  int idFromString(String id) {
    return id.hashCode & 0x7fffffff;
  }

  Future<void> schedule({
    required String recordId,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    await init();

    if (when.isBefore(DateTime.now())) return;

    final notificationId = idFromString(recordId);

    await cancel(notificationId);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'planner_reminders',
        'Напоминания планировщика',
        channelDescription: 'Локальные напоминания о задачах, событиях и привычках',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
      ),
    );

    await _plugin.zonedSchedule(
      notificationId,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelByRecordId(String recordId) async {
    await cancel(idFromString(recordId));
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }
}