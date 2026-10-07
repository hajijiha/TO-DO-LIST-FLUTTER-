import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/calendar.dart';
import '../models/day_plan.dart';
import '../models/day_reflection.dart';
import '../models/planner_state.dart';
import '../models/todo.dart';
import '../repositories/todo_repository.dart';

final todoRepositoryProvider = Provider<TodoRepository>(
  (ref) => SharedPreferencesTodoRepository(),
);

final todoProvider = AsyncNotifierProvider<TodoNotifier, PlannerState>(
  TodoNotifier.new,
  retry: (retryCount, error) => null,
);

class TodoNotifier extends AsyncNotifier<PlannerState> {
  late TodoRepository _repository;
  Future<void> _queue = Future.value();

  @override
  Future<PlannerState> build() {
    _repository = ref.watch(todoRepositoryProvider);
    return _repository.load();
  }

  Future<bool> addTodo(
    String rawTitle, {
    String location = '미지정',
    String category = '기타',
    int estimatedMinutes = 30,
    DateTime? date,
  }) => _mutate('todo.add', (current) {
    final title = rawTitle.trim();
    if (title.isEmpty) return (null, false);
    final task = Todo(
      id: current.nextId,
      title: title,
      location: location,
      category: category,
      estimatedMinutes: estimatedMinutes,
      date: date ?? DateTime.now(),
    );
    final tasks = [...current.tasks, task];
    return (
      current.copyWith(
        tasks: tasks,
        plans: _ensurePlan(current, tasks, task.date),
        nextId: current.nextId + 1,
      ),
      true,
    );
  });

  Future<bool> editTodo(
    int id, {
    required String title,
    required String location,
    required int estimatedMinutes,
    required DateTime date,
    String? category,
  }) => _mutate('todo.edit', (current) {
    if (title.trim().isEmpty) return (null, false);
    final index = current.tasks.indexWhere((task) => task.id == id);
    if (index == -1) return (null, false);
    final updated = current.tasks[index].copyWith(
      title: title,
      location: location,
      category: category,
      estimatedMinutes: estimatedMinutes,
      date: date,
    );
    final tasks = [...current.tasks]..[index] = updated;
    return (
      current.copyWith(
        tasks: tasks,
        plans: _ensurePlan(current, tasks, updated.date),
      ),
      true,
    );
  });

  Future<void> deleteTodo(int id) => _mutate<void>('todo.delete', (current) {
    if (!current.tasks.any((task) => task.id == id)) return (null, null);
    return (
      current.copyWith(
        tasks: current.tasks.where((task) => task.id != id).toList(),
      ),
      null,
    );
  });

  Future<void> rateTodo(int id, int score) => _mutate<void>('todo.rate', (
    current,
  ) {
    if (score < 0 || score > 10) throw ArgumentError.value(score, 'score');
    final index = current.tasks.indexWhere((task) => task.id == id);
    if (index == -1 || current.tasks[index].score == score) return (null, null);
    final tasks = [...current.tasks]
      ..[index] = current.tasks[index].copyWith(score: score);
    return (current.copyWith(tasks: tasks), null);
  });

  Future<void> reopenTodo(int id) => _mutate<void>('todo.reopen', (current) {
    final index = current.tasks.indexWhere((task) => task.id == id);
    if (index == -1 || !current.tasks[index].isCompleted) return (null, null);
    final tasks = [...current.tasks]
      ..[index] = current.tasks[index].copyWith(clearScore: true);
    return (current.copyWith(tasks: tasks), null);
  });

  Future<void> updateGoals({required int count, required int minutes}) =>
      _mutate<void>('todo.goals', (current) {
        validateGoals(count, minutes);
        if (current.dailyCountGoal == count &&
            current.dailyMinutesGoal == minutes) {
          return (null, null);
        }
        return (
          current.copyWith(dailyCountGoal: count, dailyMinutesGoal: minutes),
          null,
        );
      });

  Future<void> saveReflection(
    DateTime date, {
    required String good,
    required String needsWork,
    required String improve,
  }) => _mutate<void>('todo.reflection', (current) {
    final key = dateKey(date);
    final note = DayReflection(
      good: good,
      needsWork: needsWork,
      improve: improve,
    );
    final reflections = {...current.reflections};
    if (note.isEmpty) {
      if (!reflections.containsKey(key)) return (null, null);
      reflections.remove(key);
    } else {
      reflections[key] = note;
    }
    return (current.copyWith(reflections: reflections), null);
  });

  Future<T> _mutate<T>(
    String event,
    (PlannerState?, T) Function(PlannerState) change,
  ) {
    final operation = _queue.then((_) async {
      final current = await future;
      final (next, result) = change(current);
      if (next != null) {
        await _repository.save(next);
        if (ref.mounted) {
          Timeline.timeSync(event, () => state = AsyncData(next));
        }
      }
      return result;
    });
    // A rejected save must reach its caller without poisoning later actions.
    _queue = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return operation;
  }
}

Map<String, DayPlan> _ensurePlan(
  PlannerState current,
  List<Todo> tasks,
  DateTime date,
) {
  final key = dateKey(date);
  final dayTasks = tasks.where((task) => dateKey(task.date) == key).toList();
  final minutes = dayTasks.fold<int>(
    0,
    (sum, task) => sum + task.estimatedMinutes,
  );
  final plan =
      current.plans[key] ??
      DayPlan(
        requiredCount: current.dailyCountGoal,
        requiredMinutes: current.dailyMinutesGoal,
        targetScore: current
            .historyStats(date, includeReference: false)
            .nextTarget,
      );
  return {
    ...current.plans,
    key: plan.ensureAtLeast(count: dayTasks.length, minutes: minutes),
  };
}
