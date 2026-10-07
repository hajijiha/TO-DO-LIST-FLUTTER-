import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:today_todo/models/calendar.dart';
import 'package:today_todo/models/day_plan.dart';
import 'package:today_todo/models/planner_state.dart';
import 'package:today_todo/models/todo.dart';

final _day = normalizeDate(DateTime.now().subtract(const Duration(days: 2)));

Todo _todo(int id, {int minutes = 30, int? score, DateTime? date}) => Todo(
  id: id,
  title: '할 일 $id',
  location: '집',
  estimatedMinutes: minutes,
  date: date ?? _day,
  score: score,
);

void main() {
  test('calendar normalizes keys and rejects invalid dates', () {
    expect(dateKey(DateTime(2026, 1, 2, 23)), '2026-01-02');
    expect(dateFromKey('2024-02-29'), DateTime(2024, 2, 29));
    expect(() => dateFromKey('2026-02-30'), throwsFormatException);
    expect(() => dateFromKey('2026-1-2'), throwsFormatException);
    expect(() => dateFromKey('0000-01-01'), throwsFormatException);
    expect(() => dateFromKey('9999-13-01'), throwsFormatException);
    expect(() => normalizeDate(DateTime(0)), throwsArgumentError);
    expect(() => normalizeDate(DateTime(10000)), throwsArgumentError);
  });

  test('zero rating, clearScore and JSON round-trip are explicit', () {
    final task = _todo(1, score: 0);
    expect(task.isCompleted, isTrue);
    expect(task.copyWith(title: '변경').score, 0);
    expect(task.copyWith(clearScore: true).isCompleted, isFalse);
    final decoded = Todo.fromJson(jsonDecode(jsonEncode(task.toJson())));
    expect(decoded.toJson(), task.toJson());
    expect(() => _todo(1, score: -1), throwsArgumentError);
    expect(() => _todo(1, minutes: 0), throwsArgumentError);
  });

  test('state and statistics expose immutable collections and snapshots', () {
    final planner = PlannerState(tasks: [_todo(1)]);
    expect(() => planner.tasks.add(_todo(2)), throwsUnsupportedError);
    expect(() => planner.plans.clear(), throwsUnsupportedError);
    expect(() => planner.statsFor(_day).tasks.clear(), throwsUnsupportedError);
    expect(
      () => planner.historyStats(_day).days.clear(),
      throwsUnsupportedError,
    );
    final changed = planner.copyWith(tasks: [...planner.tasks, _todo(2)]);
    expect(planner.tasks, hasLength(1));
    expect(changed.tasks, hasLength(2));
  });

  test('quantity and time goals penalize an isolated tiny perfect task', () {
    final stats = PlannerState(
      tasks: [_todo(1, minutes: 1, score: 10)],
    ).statsFor(_day);
    expect(stats.qualityAverage, 10);
    expect(stats.quantityFactor, closeTo(1 / 3, 0.000001));
    expect(stats.timeFactor, closeTo(1 / 90, 0.000001));
    expect(stats.countScore, closeTo(10 / 3, 0.000001));
    expect(stats.timeScore, closeTo(10 / 90, 0.000001));
    expect(stats.dailyScore, closeTo((10 / 3 + 10 / 90) / 2, 0.000001));
  });

  test('zero-score reopen or delete cannot inflate the daily score', () {
    final planner = PlannerState(
      tasks: [
        _todo(1, minutes: 60, score: 10),
        _todo(2, minutes: 60, score: 10),
        _todo(3, minutes: 1, score: 0),
      ],
    );
    final before = planner.statsFor(_day);
    final reopened = planner
        .copyWith(
          tasks: [
            ...planner.tasks.take(2),
            planner.tasks.last.copyWith(clearScore: true),
          ],
        )
        .statsFor(_day);
    final deleted = planner
        .copyWith(tasks: planner.tasks.take(2).toList())
        .statsFor(_day);
    expect(before.requiredMinutes, 121);
    expect(reopened.qualityAverage, greaterThan(before.qualityAverage!));
    expect(reopened.dailyScore, before.dailyScore);
    expect(deleted.dailyScore, before.dailyScore);
    expect(deleted.requiredCount, before.requiredCount);
    expect(deleted.requiredMinutes, before.requiredMinutes);
  });

  test('removing a positive rating lowers score without lowering the plan', () {
    final planner = PlannerState(
      tasks: [_todo(1, score: 10), _todo(2, score: 4), _todo(3, score: 8)],
    );
    final after = planner.copyWith(
      tasks: planner.tasks.where((task) => task.id != 2).toList(),
    );
    expect(
      after.statsFor(_day).dailyScore,
      lessThan(planner.statsFor(_day).dailyScore),
    );
    expect(after.statsFor(_day).requiredCount, 3);
    expect(after.statsFor(_day).requiredMinutes, 90);
  });

  test('full perfect workload reaches ten and next target caps at ten', () {
    final planner = PlannerState(
      tasks: List.generate(3, (index) => _todo(index + 1, score: 10)),
    );
    expect(planner.statsFor(_day).dailyScore, 10);
    expect(planner.historyStats(_day).averageScore, 10);
    expect(planner.historyStats(_day).nextTarget, 10);
    expect(PlannerState().historyStats(_day).nextTarget, 7);
    expect(PlannerState().historyStats(_day).averageScore, isNull);
  });

  test(
    'history is newest-first, includes zeros, excludes future and caps fourteen',
    () {
      final plans = <String, DayPlan>{};
      for (var offset = 0; offset < 20; offset++) {
        plans[dateKey(_day.subtract(Duration(days: offset)))] = DayPlan(
          requiredCount: 3,
          requiredMinutes: 90,
          targetScore: 7,
        );
      }
      final tomorrow = normalizeDate(
        DateTime.now(),
      ).add(const Duration(days: 1));
      plans[dateKey(tomorrow)] = DayPlan(
        requiredCount: 3,
        requiredMinutes: 90,
        targetScore: 10,
      );
      final planner = PlannerState(plans: plans);
      final history = planner.historyStats(
        tomorrow.add(const Duration(days: 10)),
      );
      expect(history.days, hasLength(14));
      expect(history.days.first.date, _day);
      expect(
        history.days.every((day) => day.hasRecord && day.dailyScore == 0),
        isTrue,
      );
      expect(history.averageScore, 0);
      expect(history.nextTarget, 0.5);
      expect(
        planner.historyStats(_day, includeReference: false).days.first.date,
        _day.subtract(const Duration(days: 1)),
      );
    },
  );

  test(
    'stored state round-trips and rejects missing plans or duplicate IDs',
    () {
      final planner = PlannerState(tasks: [_todo(1, score: 0)], nextId: 9);
      final json =
          jsonDecode(jsonEncode(planner.toJson())) as Map<String, dynamic>;
      expect(PlannerState.fromJson(json).toJson(), planner.toJson());
      expect(
        () => PlannerState.fromJson({...json, 'plans': <String, dynamic>{}}),
        throwsFormatException,
      );
      expect(
        () => PlannerState.fromJson({
          ...json,
          'tasks': [planner.tasks.first.toJson(), planner.tasks.first.toJson()],
        }),
        throwsArgumentError,
      );
    },
  );
}
