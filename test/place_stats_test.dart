import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:today_todo/models/calendar.dart';
import 'package:today_todo/models/planner_state.dart';
import 'package:today_todo/models/todo.dart';

final _today = normalizeDate(DateTime.now());
final _past = _today.subtract(const Duration(days: 2));

Todo _task(
  int id, {
  String category = '공부',
  String location = '도서관',
  int? score,
  int minutes = 30,
  DateTime? date,
}) => Todo(
  id: id,
  title: '기록 $id',
  category: category,
  location: location,
  estimatedMinutes: minutes,
  date: date ?? _past,
  score: score,
);

void main() {
  test(
    'category and place whitespace normalize and catalog stays immutable',
    () {
      final planner = PlannerState(
        tasks: [
          _task(1, category: '  개인   공부 ', location: ' 학교\t 도서관 '),
          _task(2, category: '개인 공부', location: '학교 도서관'),
          _task(3, category: ' ', location: '\n '),
        ],
        placeCatalog: {
          ' 개인 공부 ': ['  학교  도서관 ', ' 독서실 ', '미지정', ' '],
        },
      );
      expect(planner.tasks.first.category, '개인 공부');
      expect(planner.tasks.first.location, '학교 도서관');
      expect(planner.tasks.last.category, '기타');
      expect(planner.tasks.last.location, '미지정');
      expect(planner.categories, ['개인 공부', '기타']);
      expect(planner.locationsFor(' 개인  공부 '), ['독서실', '학교 도서관']);
      expect(planner.locationsFor('기타'), isEmpty);
      expect(() => planner.placeCatalog.clear(), throwsUnsupportedError);
      expect(
        () => planner.locationsFor('개인 공부').add('새 장소'),
        throwsUnsupportedError,
      );
      expect(() => planner.categories.clear(), throwsUnsupportedError);
      expect(() => planner.placeStats().clear(), throwsUnsupportedError);
    },
  );

  test('success divides by all tasks and includes zero as completed', () {
    final stats = PlannerState(
      tasks: [
        _task(1, score: 8, minutes: 45),
        _task(2, score: 0, minutes: 15),
        _task(3),
        _task(4, category: '운동', score: 10),
      ],
    ).placeStats(category: ' 공부 ').single;
    expect(stats.category, '공부');
    expect(stats.location, '도서관');
    expect(stats.plannedCount, 3);
    expect(stats.completedCount, 2);
    expect(stats.qualityAverage, 4);
    expect(stats.successCount, 1);
    expect(stats.successRate, closeTo(1 / 3, 0.000001));
    expect(stats.completedMinutes, 60);
  });

  test(
    'reference and actual today exclude future tasks but keep empty places',
    () {
      final planner = PlannerState(
        tasks: [
          _task(1, score: 9),
          _task(2, score: 10, date: _today),
          _task(
            3,
            location: '미래 장소',
            score: 10,
            date: _today.add(const Duration(days: 1)),
          ),
        ],
      );
      final past = planner.placeStats(reference: _past);
      expect(
        past.firstWhere((stats) => stats.location == '도서관').plannedCount,
        1,
      );
      final future = planner.placeStats(
        reference: _today.add(const Duration(days: 100)),
      );
      expect(
        future.firstWhere((stats) => stats.location == '도서관').plannedCount,
        2,
      );
      final empty = future.firstWhere((stats) => stats.location == '미래 장소');
      expect(empty.plannedCount, 0);
      expect(empty.successRate, isNull);
      expect(empty.qualityAverage, isNull);
      expect(empty.completedMinutes, 0);
    },
  );

  test('catalog persists after deletion and after JSON reload', () {
    final before = PlannerState(tasks: [_task(1, score: 10)]);
    final after = before.copyWith(tasks: []);
    final loaded = PlannerState.fromJson(
      jsonDecode(jsonEncode(after.toJson())),
    );
    expect(loaded.locationsFor('공부'), ['도서관']);
    expect(loaded.placeStats().single.plannedCount, 0);
    expect(loaded.placeStats().single.successRate, isNull);
    expect(before.tasks, hasLength(1));
  });

  test(
    'old v2 migrates category catalog and reflections without data loss',
    () {
      final old = PlannerState(tasks: [_task(1, score: 0)]).toJson();
      old.remove('placeCatalog');
      old.remove('reflections');
      (old['tasks'] as List).first.remove('category');
      final loaded = PlannerState.fromJson(old);
      expect(loaded.tasks.single.category, '기타');
      expect(loaded.tasks.single.score, 0);
      expect(loaded.tasks.single.id, 1);
      expect(loaded.locationsFor('기타'), ['도서관']);
      expect(loaded.reflections, isEmpty);
      expect(loaded.plans.keys, [dateKey(_past)]);
      expect(loaded.nextId, 2);
    },
  );

  test('present but malformed new fields are rejected rather than reset', () {
    final json = PlannerState(tasks: [_task(1)]).toJson();
    expect(
      () => PlannerState.fromJson({
        ...json,
        'placeCatalog': {
          '공부': [42],
        },
      }),
      throwsFormatException,
    );
    expect(
      () => PlannerState.fromJson({...json, 'reflections': null}),
      throwsFormatException,
    );
    final task = {..._task(1).toJson(), 'category': null};
    expect(() => Todo.fromJson(task), throwsFormatException);
  });
}
