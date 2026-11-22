import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../data/repositories/habit_repository.dart';
import '../../models/enums.dart';
import '../../models/habit.dart';
import '../../models/habit_track.dart';
import 'habit_detail_screen.dart';
import 'habit_form_screen.dart';

class HabitListScreen extends StatelessWidget {
  const HabitListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<HabitRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Привычки'),
        actions: [
          IconButton(
            tooltip: 'Создать привычку',
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HabitFormScreen()),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Habit>>(
        future: repo.getActive('local-user'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final habits = snapshot.data!;

          if (habits.isEmpty) {
            return const Center(
              child: Text('Привычек пока нет'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final habit = habits[index];

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.lowPriority.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.local_fire_department_outlined,
                              color: AppColors.lowPriority,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  habit.title,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  habit.frequency.label,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Отметить сегодня',
                            icon: const Icon(Icons.check_circle_outline),
                            onPressed: () async {
                              final track = HabitTrack(
                                id: repo.newId(),
                                habitId: habit.id,
                                trackDate: DateTime.now(),
                                value: habit.targetValue,
                                isCompleted: true,
                              );

                              await repo.saveTrack(track);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: 0.35,
                          minHeight: 8,
                          backgroundColor:
                              AppColors.lowPriority.withOpacity(0.18),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.lowPriority,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Прогресс: 35%',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: List.generate(7, (dayIndex) {
                          final completed = dayIndex < 3;

                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              height: 34,
                              decoration: BoxDecoration(
                                color: completed
                                    ? AppColors.lowPriority
                                    : AppColors.lowPriority.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                completed
                                    ? Icons.check
                                    : Icons.circle_outlined,
                                size: 18,
                                color: completed
                                    ? Colors.white
                                    : AppColors.lowPriority,
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}