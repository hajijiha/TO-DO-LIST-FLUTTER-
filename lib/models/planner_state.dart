import 'dart:math' as math;

import 'calendar.dart';
import 'day_plan.dart';
import 'day_reflection.dart';
import 'model_json.dart';
import 'place_stats.dart';
import 'planner_stats.dart';
import 'todo.dart';

class PlannerState {
  PlannerState({
    List<Todo> tasks = const [],
    Map<String, DayPlan> plans = const {},
    Map<String, List<String>> placeCatalog = const {},
    Map<String, DayReflection> reflections = const {},
    this.dailyCountGoal = 3,
    this.dailyMinutesGoal = 90,
    int? nextId,
  }) : tasks = List.unmodifiable(tasks),
       plans = Map.unmodifiable(
         _seedPlans(tasks, plans, dailyCountGoal, dailyMinutesGoal),
       ),
       placeCatalog = _buildPlaceCatalog(tasks, placeCatalog),
       reflections = Map.unmodifiable(reflections),
       nextId = nextId ?? _nextTaskId(tasks) {
    validateGoals(dailyCountGoal, dailyMinutesGoal);
    if (tasks.map((task) => task.id).toSet().length != tasks.length) {
      throw ArgumentError('Todo IDs must be unique.');
    }
    if (this.nextId < _nextTaskId(tasks)) {
      throw ArgumentError.value(this.nextId, 'nextId');
    }
    for (final key in this.plans.keys) {
      dateFromKey(key);
    }
    for (final key in this.reflections.keys) {
      dateFromKey(key);
    }
  }

  final List<Todo> tasks;
  final Map<String, DayPlan> plans;
  final Map<String, List<String>> placeCatalog;
  final Map<String, DayReflection> reflections;
  final int dailyCountGoal;
  final int dailyMinutesGoal;
  final int nextId;

  PlannerState copyWith({
    List<Todo>? tasks,
    Map<String, DayPlan>? plans,
    Map<String, List<String>>? placeCatalog,
    Map<String, DayReflection>? reflections,
    int? dailyCountGoal,
    int? dailyMinutesGoal,
    int? nextId,
  }) => PlannerState(
    tasks: tasks ?? this.tasks,
    plans: plans ?? this.plans,
    placeCatalog: placeCatalog ?? this.placeCatalog,
    reflections: reflections ?? this.reflections,
    dailyCountGoal: dailyCountGoal ?? this.dailyCountGoal,
    dailyMinutesGoal: dailyMinutesGoal ?? this.dailyMinutesGoal,
    nextId: nextId ?? math.max(this.nextId, _nextTaskId(tasks ?? this.tasks)),
  );

  List<String> get categories =>
      List.unmodifiable(<String>{'기타', ...placeCatalog.keys}.toList()..sort());

  List<String> locationsFor(String category) =>
      placeCatalog[normalizeCategory(category)] ?? const [];

  DayReflection? reflectionFor(DateTime date) => reflections[dateKey(date)];

  List<PlaceStats> placeStats({String? category, DateTime? reference}) {
    final today = normalizeDate(DateTime.now());
    final requested = normalizeDate(reference ?? today);
    final cutoff = requested.isAfter(today) ? today : requested;
    final filter = category == null ? null : normalizeCategory(category);
    final groups = <String, Map<String, List<Todo>>>{};
    for (final entry in placeCatalog.entries) {
      if (filter != null && entry.key != filter) continue;
      groups[entry.key] = {
        for (final location in entry.value) location: <Todo>[],
      };
    }
    for (final task in tasks) {
      if (task.date.isAfter(cutoff) ||
          (filter != null && task.category != filter)) {
        continue;
      }
      groups
          .putIfAbsent(task.category, () => {})
          .putIfAbsent(task.location, () => [])
          .add(task);
    }
    final result = <PlaceStats>[];
    for (final categoryEntry in groups.entries) {
      for (final placeEntry in categoryEntry.value.entries) {
        final planned = placeEntry.value;
        final completed = planned.where((task) => task.isCompleted).toList();
        final successCount = completed.where((task) => task.score! >= 8).length;
        result.add(
          PlaceStats(
            category: categoryEntry.key,
            location: placeEntry.key,
            plannedCount: planned.length,
            completedCount: completed.length,
            qualityAverage: completed.isEmpty
                ? null
                : completed.fold<int>(0, (sum, task) => sum + task.score!) /
                      completed.length,
            successCount: successCount,
            successRate: planned.isEmpty ? null : successCount / planned.length,
            completedMinutes: completed.fold<int>(
              0,
              (sum, task) => sum + task.estimatedMinutes,
            ),
          ),
        );
      }
    }
    result.sort((a, b) {
      final categoryOrder = a.category.compareTo(b.category);
      return categoryOrder == 0
          ? a.location.compareTo(b.location)
          : categoryOrder;
    });
    return List.unmodifiable(result);
  }

  DayStats statsFor(DateTime date) {
    final day = normalizeDate(date);
    final key = dateKey(day);
    final dayTasks = tasks.where((task) => dateKey(task.date) == key).toList();
    final completed = dayTasks.where((task) => task.isCompleted).toList();
    final plan = plans[key];
    final requiredCount = plan?.requiredCount ?? dailyCountGoal;
    final requiredMinutes = plan?.requiredMinutes ?? dailyMinutesGoal;
    final completedMinutes = completed.fold<int>(
      0,
      (sum, task) => sum + task.estimatedMinutes,
    );
    final qualityAverage = completed.isEmpty
        ? null
        : completed.fold<int>(0, (sum, task) => sum + task.score!) /
              completed.length;
    final quantityFactor = math.min(1.0, completed.length / requiredCount);
    final timeFactor = math.min(1.0, completedMinutes / requiredMinutes);
    final scoreSum = completed.fold<int>(0, (sum, task) => sum + task.score!);
    final weightedScoreSum = completed.fold<int>(
      0,
      (sum, task) => sum + task.score! * task.estimatedMinutes,
    );
    final countScore = math.min(10.0, scoreSum / requiredCount);
    final timeScore = math.min(10.0, weightedScoreSum / requiredMinutes);
    return DayStats(
      date: day,
      tasks: dayTasks,
      hasRecord: plan != null,
      plannedCount: dayTasks.length,
      plannedMinutes: dayTasks.fold<int>(
        0,
        (sum, task) => sum + task.estimatedMinutes,
      ),
      completedCount: completed.length,
      completedMinutes: completedMinutes,
      qualityAverage: qualityAverage,
      quantityFactor: quantityFactor,
      timeFactor: timeFactor,
      countScore: countScore,
      timeScore: timeScore,
      dailyScore: (countScore + timeScore) / 2,
      targetScore: plan?.targetScore ?? 7.0,
      requiredCount: requiredCount,
      requiredMinutes: requiredMinutes,
    );
  }

  HistoryStats historyStats(
    DateTime reference, {
    bool includeReference = true,
    int limit = 14,
  }) {
    if (limit < 1) throw ArgumentError.value(limit, 'limit');
    final day = normalizeDate(reference);
    final today = normalizeDate(DateTime.now());
    final dates = plans.keys.map(dateFromKey).where((date) {
      return !date.isAfter(today) &&
          (date.isBefore(day) || (includeReference && date == day));
    }).toList()..sort((a, b) => b.compareTo(a));
    final days = dates.take(math.min(14, limit)).map(statsFor).toList();
    final averageScore = days.isEmpty
        ? null
        : days.fold<double>(0, (sum, stats) => sum + stats.dailyScore) /
              days.length;
    return HistoryStats(
      days: days,
      averageScore: averageScore,
      averageCompletedCount: days.isEmpty
          ? 0
          : days.fold<int>(0, (sum, stats) => sum + stats.completedCount) /
                days.length,
      averageCompletedMinutes: days.isEmpty
          ? 0
          : days.fold<int>(0, (sum, stats) => sum + stats.completedMinutes) /
                days.length,
      nextTarget: averageScore == null
          ? 7.0
          : math.min(10.0, averageScore + 0.5),
    );
  }

  Map<String, dynamic> toJson() => {
    'version': 2,
    'tasks': tasks.map((task) => task.toJson()).toList(),
    'plans': plans.map((key, plan) => MapEntry(key, plan.toJson())),
    'dailyCountGoal': dailyCountGoal,
    'dailyMinutesGoal': dailyMinutesGoal,
    'nextId': nextId,
    'placeCatalog': placeCatalog,
    'reflections': reflections.map((key, note) => MapEntry(key, note.toJson())),
  };

  factory PlannerState.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 2 || json['tasks'] is! List) {
      throw const FormatException('Invalid planner data version or tasks.');
    }
    final tasks = (json['tasks'] as List)
        .map((task) => Todo.fromJson(jsonMap(task)))
        .toList();
    final plans = jsonMap(
      json['plans'],
    ).map((key, value) => MapEntry(key, DayPlan.fromJson(jsonMap(value))));
    for (final task in tasks) {
      if (!plans.containsKey(dateKey(task.date))) {
        throw const FormatException('A stored task has no day plan.');
      }
    }
    for (final entry in plans.entries) {
      final dayTasks = tasks.where((task) => dateKey(task.date) == entry.key);
      final minutes = dayTasks.fold<int>(
        0,
        (sum, task) => sum + task.estimatedMinutes,
      );
      if (entry.value.requiredCount < dayTasks.length ||
          entry.value.requiredMinutes < minutes) {
        throw const FormatException('A stored day plan is below its workload.');
      }
    }
    return PlannerState(
      tasks: tasks,
      plans: plans,
      dailyCountGoal: jsonInt(json, 'dailyCountGoal'),
      dailyMinutesGoal: jsonInt(json, 'dailyMinutesGoal'),
      nextId: jsonInt(json, 'nextId'),
      placeCatalog: json.containsKey('placeCatalog')
          ? jsonMap(json['placeCatalog']).map((category, places) {
              if (places is! List || places.any((place) => place is! String)) {
                throw const FormatException(
                  'Place catalog values must be string lists.',
                );
              }
              return MapEntry(category, places.cast<String>());
            })
          : const {},
      reflections: json.containsKey('reflections')
          ? jsonMap(json['reflections']).map(
              (key, note) =>
                  MapEntry(key, DayReflection.fromJson(jsonMap(note))),
            )
          : const {},
    );
  }
}

Map<String, List<String>> _buildPlaceCatalog(
  List<Todo> tasks,
  Map<String, List<String>> catalog,
) {
  final result = <String, Set<String>>{};
  for (final entry in catalog.entries) {
    final locations = result.putIfAbsent(
      normalizeCategory(entry.key),
      () => {},
    );
    for (final rawLocation in entry.value) {
      final location = normalizeLocation(rawLocation);
      if (location != '미지정') locations.add(location);
    }
  }
  for (final task in tasks) {
    final locations = result.putIfAbsent(task.category, () => {});
    if (task.location != '미지정') locations.add(task.location);
  }
  return Map.unmodifiable(
    result.map(
      (category, places) => MapEntry(
        category,
        List<String>.unmodifiable(places.toList()..sort()),
      ),
    ),
  );
}

void validateGoals(int count, int minutes) {
  if (count < 1 || count > 1000) throw ArgumentError.value(count, 'count');
  if (minutes < 1 || minutes > 1440) {
    throw ArgumentError.value(minutes, 'minutes');
  }
}

int _nextTaskId(List<Todo> tasks) =>
    tasks.fold<int>(0, (largest, task) => math.max(largest, task.id)) + 1;

Map<String, DayPlan> _seedPlans(
  List<Todo> tasks,
  Map<String, DayPlan> plans,
  int countGoal,
  int minutesGoal,
) {
  final result = {...plans};
  final groups = <String, List<Todo>>{};
  for (final task in tasks) {
    groups.putIfAbsent(dateKey(task.date), () => []).add(task);
  }
  for (final entry in groups.entries) {
    final minutes = entry.value.fold<int>(
      0,
      (sum, task) => sum + task.estimatedMinutes,
    );
    result[entry.key] =
        (result[entry.key] ??
                DayPlan(
                  requiredCount: countGoal,
                  requiredMinutes: minutesGoal,
                  targetScore: 7.0,
                ))
            .ensureAtLeast(count: entry.value.length, minutes: minutes);
  }
  return result;
}
