import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:today_todo/models/calendar.dart';
import 'package:today_todo/models/day_reflection.dart';
import 'package:today_todo/models/planner_state.dart';

void main() {
  test('reflection trims edges and round-trips without losing line breaks', () {
    final note = DayReflection(
      good: ' 계획을 지킴\n점심 후 집중 ',
      needsWork: ' 휴대폰 확인 ',
      improve: '  알림 끄기  ',
    );
    expect(note.good, '계획을 지킴\n점심 후 집중');
    expect(note.needsWork, '휴대폰 확인');
    expect(note.improve, '알림 끄기');
    expect(note.isEmpty, isFalse);
    expect(
      DayReflection.fromJson(jsonDecode(jsonEncode(note.toJson()))).toJson(),
      note.toJson(),
    );
    expect(
      DayReflection(good: ' ', needsWork: '\n', improve: '\t').isEmpty,
      isTrue,
    );
    expect(
      () => DayReflection.fromJson({'good': 7, 'needsWork': '', 'improve': ''}),
      throwsFormatException,
    );
  });

  test(
    'note-only days remain outside score history and collections are immutable',
    () {
      final day = normalizeDate(
        DateTime.now(),
      ).subtract(const Duration(days: 1));
      final note = DayReflection(good: '기록', needsWork: '', improve: '내일');
      final planner = PlannerState(reflections: {dateKey(day): note});
      expect(
        planner.reflectionFor(DateTime(day.year, day.month, day.day, 23)),
        note,
      );
      expect(planner.reflectionFor(day.add(const Duration(days: 1))), isNull);
      expect(planner.statsFor(day).hasRecord, isFalse);
      expect(planner.historyStats(day).days, isEmpty);
      expect(planner.historyStats(day).averageScore, isNull);
      expect(() => planner.reflections.clear(), throwsUnsupportedError);
      final loaded = PlannerState.fromJson(
        jsonDecode(jsonEncode(planner.toJson())),
      );
      expect(loaded.reflectionFor(day)!.toJson(), note.toJson());
      expect(loaded.plans, isEmpty);
    },
  );
}
