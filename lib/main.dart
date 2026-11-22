import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/database.dart';
import 'data/repositories/category_repository.dart';
import 'data/repositories/event_repository.dart';
import 'data/repositories/habit_repository.dart';
import 'data/repositories/search_repository.dart';
import 'data/repositories/task_repository.dart';
import 'data/services/notification_service.dart';
import 'data/services/overdue_service.dart';
import 'data/services/recurrence_service.dart';
import 'data/services/settings_service.dart';
import 'data/services/trash_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await SharedPreferences.getInstance();
  final db = AppDatabase.instance.database;

  final taskRepository = TaskRepository(db);
  final eventRepository = EventRepository(db);
  final habitRepository = HabitRepository(db);
  final categoryRepository = CategoryRepository(db);
  final searchRepository = SearchRepository(db);

  final trashService = TrashService(
    taskRepository: taskRepository,
    eventRepository: eventRepository,
    habitRepository: habitRepository,
  );

  final overdueService = OverdueService(
    taskRepository: taskRepository,
    eventRepository: eventRepository,
  );

  final recurrenceService = RecurrenceService(taskRepository);
  final settingsService = SettingsService(preferences);

  await NotificationService.instance.init();

  if (settingsService.notificationsEnabled) {
    await NotificationService.instance.requestPermission();
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<TaskRepository>.value(value: taskRepository),
        Provider<EventRepository>.value(value: eventRepository),
        Provider<HabitRepository>.value(value: habitRepository),
        Provider<CategoryRepository>.value(value: categoryRepository),
        Provider<SearchRepository>.value(value: searchRepository),
        Provider<TrashService>.value(value: trashService),
        Provider<OverdueService>.value(value: overdueService),
        Provider<RecurrenceService>.value(value: recurrenceService),
        ChangeNotifierProvider<SettingsService>.value(
          value: settingsService,
        ),
      ],
      child: const PlannerApp(),
    ),
  );
}