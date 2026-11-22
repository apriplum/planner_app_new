import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../data/repositories/habit_repository.dart';
import '../../data/services/habit_analytics_service.dart';
import '../../models/habit.dart';
import '../../models/habit_track.dart';
import '../../models/enums.dart';

class HabitDetailScreen extends StatelessWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  final String habitId;

  int _streak(List<HabitTrack> tracks) {
    final dates = tracks
        .where((track) => track.isCompleted)
        .map(
          (track) => DateTime(
            track.trackDate.year,
            track.trackDate.month,
            track.trackDate.day,
          ),
        )
        .toSet();

    var date = DateTime.now();
    date = DateTime(date.year, date.month, date.day);

    var streak = 0;

    while (dates.contains(date)) {
      streak++;
      date = date.subtract(const Duration(days: 1));
    }

    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<HabitRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Привычка'),
        actions: [
          IconButton(
            tooltip: 'Удалить в корзину',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await repo.moveToTrash(habitId);

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<Habit?>(
        future: repo.getById(habitId),
        builder: (context, habitSnapshot) {
          if (habitSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final habit = habitSnapshot.data;

          if (habit == null) {
            return const Center(
              child: Text('Привычка не найдена'),
            );
          }

          return FutureBuilder<List<HabitTrack>>(
            future: repo.getTracks(habit.id),
            builder: (context, trackSnapshot) {
              if (trackSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final tracks = trackSnapshot.data ?? [];

              final analytics = const HabitAnalyticsService();
              final now = DateTime.now();

              final weekStart = now.subtract(
                Duration(days: now.weekday - 1),
              );

              final monthStart = DateTime(now.year, now.month, 1);

              final weekRate = analytics.completionRate(
                habit,
                tracks,
                weekStart,
                now,
              );

              final monthRate = analytics.completionRate(
                habit,
                tracks,
                monthStart,
                now,
              );

              final currentStreak = analytics.currentStreak(tracks);
              final bestStreak = analytics.bestStreak(tracks);
              final weekdayStats = analytics.weekdayStatistics(tracks);
              final motivation = analytics.motivationMessage(currentStreak);

              const weekdayNames = [
                'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс',
              ];

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    habit.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    habit.description.isEmpty
                        ? 'Цель не указана'
                        : habit.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Статистика',
                            style:
                                Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Периодичность: ${habit.frequency.label}',
                          ),
                          Text(
                            'Цель: ${habit.targetValue} '
                            '${habit.unit ?? ''}',
                          ),
                          Text(
                            'Выполнено отметок: '
                            '${tracks.where((t) => t.isCompleted).length}',
                          ),
                          Text(
                            'Выполнение за неделю: '
                            '${weekRate.toStringAsFixed(0)}%',
                          ),
                          Text(
                            'Выполнение за месяц: '
                            '${monthRate.toStringAsFixed(0)}%',
                          ),
                          Text('Текущая серия: $currentStreak дн.'),
                          Text('Лучшая серия: $bestStreak дн.'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Прогресс',
                            style:
                                Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: weekRate / 100,
                            minHeight: 10,
                            backgroundColor:
                                AppColors.lowPriority.withOpacity(0.18),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(
                              AppColors.lowPriority,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(motivation),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Выполнение по дням недели',
                            style:
                                Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: weekdayStats.entries.map((entry) {
                              return Chip(
                                label: Text(
                                  '${weekdayNames[entry.key - 1]}: '
                                  '${entry.value}',
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  FilledButton(
                    onPressed: () async {
                      final today = DateTime.now();

                      final track = HabitTrack(
                        id: repo.newId(),
                        habitId: habit.id,
                        trackDate: today,
                        value: habit.targetValue,
                        isCompleted: true,
                      );

                      await repo.saveTrack(track);
                    },
                    child: const Text('Отметить сегодня'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}