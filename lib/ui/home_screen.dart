import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../data/repositories/event_repository.dart';
import '../data/repositories/habit_repository.dart';
import '../data/repositories/task_repository.dart';
import '../models/enums.dart';
import '../models/event.dart';
import '../models/habit.dart';
import '../models/task.dart';
import 'events/event_calendar_screen.dart';
import 'habits/habit_list_screen.dart';
import 'overdue_screen.dart';
import 'search_screen.dart';
import 'tasks/task_form_screen.dart';
import 'tasks/task_list_screen.dart';
import 'settings_screen.dart';
import 'trash_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const String _userId = 'local-user';

  @override
  Widget build(BuildContext context) {
    final screens = [
      _Dashboard(userId: _userId),
      const TaskListScreen(),
      const EventCalendarScreen(),
      const HabitListScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
  title: const Text('Планировщик'),
  actions: [
    IconButton(
      tooltip: 'Поиск',
      icon: const Icon(Icons.search),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SearchScreen()),
      ),
    ),
    IconButton(
      tooltip: 'Просроченные',
      icon: const Icon(Icons.warning_amber_rounded),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OverdueScreen()),
      ),
    ),
    IconButton(
      tooltip: 'Корзина',
      icon: const Icon(Icons.delete_outline),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TrashScreen()),
      ),
    ),
    IconButton(
      tooltip: 'Настройки',
      icon: const Icon(Icons.settings_outlined),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      ),
    ),
  ],
),
      body: screens[_index],
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'home_add_fab',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TaskFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
bottomNavigationBar: NavigationBar(
  selectedIndex: _index,
  onDestinationSelected: (value) => setState(() => _index = value),
  destinations: const [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Главная',
    ),
    NavigationDestination(
      icon: Icon(Icons.check_circle_outline),
      selectedIcon: Icon(Icons.check_circle),
      label: 'Задачи',
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_today_outlined),
      selectedIcon: Icon(Icons.calendar_today),
      label: 'Календарь',
    ),
    NavigationDestination(
      icon: Icon(Icons.repeat_outlined),
      selectedIcon: Icon(Icons.repeat),
      label: 'Привычки',
    ),
  ],
),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.userId});

  final String userId;

  String _greeting() {
    final hour = DateTime.now().hour;

    if (hour < 6) return 'Доброй ночи';
    if (hour < 12) return 'Доброе утро';
    if (hour < 18) return 'Добрый день';
    return 'Добрый вечер';
  }

  Color _priorityColor(Priority priority) => switch (priority) {
        Priority.low => AppColors.lowPriority,
        Priority.medium => AppColors.mediumPriority,
        Priority.high => AppColors.highPriority,
        Priority.critical => const Color(0xFFD32F2F),
      };

  @override
  Widget build(BuildContext context) {
    final taskRepo = context.read<TaskRepository>();
    final eventRepo = context.read<EventRepository>();
    final habitRepo = context.read<HabitRepository>();

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        taskRepo.getTodayTasks(userId),
        eventRepo.getByDate(userId, DateTime.now()),
        habitRepo.getActive(userId),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = snapshot.data![0] as List<Task>;
        final events = snapshot.data![1] as List<PlannerEvent>;
        final habits = snapshot.data![2] as List<Habit>;

        final activeTasks = tasks
            .where((task) => task.status == TaskStatus.active)
            .length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${_greeting()}!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Сегодня: ${_formatDate(DateTime.now())}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle_outline,
                    title: 'Задачи',
                    value: '$activeTasks',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.event_outlined,
                    title: 'События',
                    value: '${events.length}',
                    color: AppColors.mediumPriority,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.repeat_outlined,
                    title: 'Привычки',
                    value: '${habits.length}',
                    color: AppColors.lowPriority,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            _SectionHeader(
              title: 'Задачи на сегодня',
              actionLabel: 'Все',
              onAction: () {},
            ),

            if (tasks.isEmpty)
              const _EmptyCard(
                icon: Icons.task_alt,
                title: 'Задач на сегодня нет',
                subtitle: 'Нажмите «Добавить», чтобы создать первую задачу',
              )
            else
              ...tasks.take(4).map(
                    (task) => _TaskTile(
                      task: task,
                      priorityColor: _priorityColor(task.priority),
                      onToggle: () => taskRepo.toggleComplete(task.id),
                    ),
                  ),

            const SizedBox(height: 24),

            _SectionHeader(
              title: 'События сегодня',
              actionLabel: 'Календарь',
              onAction: () {},
            ),

            if (events.isEmpty)
              const _EmptyCard(
                icon: Icons.event_available,
                title: 'Событий нет',
                subtitle: 'На выбранный день событий не запланировано',
              )
            else
              ...events.map(
                (event) => _EventTile(event: event),
              ),

            const SizedBox(height: 24),

            _SectionHeader(
              title: 'Привычки',
              actionLabel: 'Все',
              onAction: () {},
            ),

            if (habits.isEmpty)
              const _EmptyCard(
                icon: Icons.local_fire_department_outlined,
                title: 'Привычек пока нет',
                subtitle: 'Создайте привычку, чтобы отслеживать прогресс',
              )
            else
              ...habits.take(3).map(
                    (habit) => _HabitTile(habit: habit),
                  ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
  final months = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
  ];

  final weekdays = [
    'понедельник', 'вторник', 'среда', 'четверг',
    'пятница', 'суббота', 'воскресенье',
  ];

  return '${date.day} ${months[date.month - 1]}, '
      '${weekdays[date.weekday - 1]}';
}
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.priorityColor,
    required this.onToggle,
  });

  final Task task;
  final Color priorityColor;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: Container(
          width: 10,
          height: 44,
          decoration: BoxDecoration(
            color: priorityColor,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        title: Text(
          task.title,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        subtitle: Text(
          task.dueDate == null
              ? 'Без срока'
              : 'Срок: ${task.dueDate!.toIso8601String().substring(0, 10)}'
                '${task.dueTime != null ? ', ${task.dueTime}' : ''}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: Checkbox(
          value: task.status == TaskStatus.completed,
          onChanged: (_) => onToggle(),
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final PlannerEvent event;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.event,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          event.title,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        subtitle: Text(
          '${event.eventType.label} · ${event.startTime}–${event.endTime}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _HabitTile extends StatelessWidget {
  const _HabitTile({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.lowPriority.withOpacity(0.16),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.local_fire_department_outlined,
            color: AppColors.lowPriority,
          ),
        ),
        title: Text(
          habit.title,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        subtitle: Text(
          '${habit.frequency.label}'
          '${habit.isQuantitative ? ' · ${habit.targetValue} ${habit.unit ?? ''}' : ''}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}