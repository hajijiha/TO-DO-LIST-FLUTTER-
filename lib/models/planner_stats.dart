import 'todo.dart';

class DayStats {
  DayStats({
    required this.date,
    required List<Todo> tasks,
    required this.hasRecord,
    required this.plannedCount,
    required this.plannedMinutes,
    required this.completedCount,
    required this.completedMinutes,
    required this.qualityAverage,
    required this.quantityFactor,
    required this.timeFactor,
    required this.countScore,
    required this.timeScore,
    required this.dailyScore,
    required this.targetScore,
    required this.requiredCount,
    required this.requiredMinutes,
  }) : tasks = List.unmodifiable(tasks);

  final DateTime date;
  final List<Todo> tasks;
  final bool hasRecord;
  final int plannedCount;
  final int plannedMinutes;
  final int completedCount;
  final int completedMinutes;
  final double? qualityAverage;
  final double quantityFactor;
  final double timeFactor;
  final double countScore;
  final double timeScore;
  final double dailyScore;
  final double targetScore;
  final int requiredCount;
  final int requiredMinutes;
}

class HistoryStats {
  HistoryStats({
    required List<DayStats> days,
    required this.averageScore,
    required this.averageCompletedCount,
    required this.averageCompletedMinutes,
    required this.nextTarget,
  }) : days = List.unmodifiable(days);

  final List<DayStats> days;
  final double? averageScore;
  final double averageCompletedCount;
  final double averageCompletedMinutes;
  final double nextTarget;
}
