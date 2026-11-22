import '../../models/habit.dart';
import '../../models/habit_track.dart';

class HabitAnalyticsService {
  const HabitAnalyticsService();

  double completionRate(
    Habit habit,
    List<HabitTrack> tracks,
    DateTime start,
    DateTime end,
  ) {
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);

    var expectedDays = 0;
    var completedDays = 0;

    var date = startDate;

    while (!date.isAfter(endDate)) {
      if (date.isBefore(habit.startDate)) {
        date = date.add(const Duration(days: 1));
        continue;
      }

      expectedDays++;

      final track = tracks.firstWhere(
        (item) =>
            item.trackDate.year == date.year &&
            item.trackDate.month == date.month &&
            item.trackDate.day == date.day,
        orElse: () => HabitTrack(
          id: '',
          habitId: habit.id,
          trackDate: date,
        ),
      );

      if (track.isCompleted) completedDays++;

      date = date.add(const Duration(days: 1));
    }

    if (expectedDays == 0) return 0;

    return completedDays / expectedDays * 100;
  }

  int currentStreak(List<HabitTrack> tracks) {
    final completedDates = tracks
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

    while (completedDates.contains(date)) {
      streak++;
      date = date.subtract(const Duration(days: 1));
    }

    return streak;
  }

  int bestStreak(List<HabitTrack> tracks) {
    final dates = tracks
        .where((track) => track.isCompleted)
        .map(
          (track) => DateTime(
            track.trackDate.year,
            track.trackDate.month,
            track.trackDate.day,
          ),
        )
        .toList()
      ..sort();

    var best = 0;
    var current = 0;
    DateTime? previous;

    for (final date in dates) {
      if (previous == null ||
          date.difference(previous).inDays == 1) {
        current++;
      } else {
        current = 1;
      }

      if (current > best) best = current;
      previous = date;
    }

    return best;
  }

  Map<int, int> weekdayStatistics(List<HabitTrack> tracks) {
    final result = <int, int>{};

    for (var i = 1; i <= 7; i++) {
      result[i] = 0;
    }

    for (final track in tracks) {
      if (track.isCompleted) {
        result[track.trackDate.weekday] =
            (result[track.trackDate.weekday] ?? 0) + 1;
      }
    }

    return result;
  }

  String motivationMessage(int streak) {
    if (streak >= 30) {
      return 'Невероятно! Вы поддерживаете привычку $streak дней подряд.';
    }

    if (streak >= 7) {
      return 'Отличная серия! Уже $streak дней подряд.';
    }

    if (streak >= 3) {
      return 'Хорошее начало. Серия: $streak дня.';
    }

    return 'Отметьте выполнение, чтобы начать серию.';
  }
}