import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:today_todo/models/calendar.dart';
import 'package:today_todo/models/planner_state.dart';
import 'package:today_todo/models/todo.dart';
import 'package:today_todo/providers/todo_provider.dart';
import 'package:today_todo/repositories/todo_repository.dart';
import 'package:today_todo/screens/todo_screen.dart';
import 'package:today_todo/widgets/planner_calendar.dart';

final _date = DateTime(2026, 10, 7);

Todo _todo(
  int id,
  String title, {
  DateTime? date,
  int? score,
  String category = '기타',
  String location = '도서관',
}) => Todo(
  id: id,
  title: title,
  category: category,
  location: location,
  estimatedMinutes: 30,
  date: date ?? _date,
  score: score,
);

Future<void> _pumpApp(
  WidgetTester tester, {
  PlannerState? seed,
  TodoRepository? repository,
  bool settle = true,
  Size size = const Size(1180, 1000),
  double keyboardHeight = 0,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboardHeight);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetViewInsets);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        todoRepositoryProvider.overrideWithValue(
          repository ?? MemoryTodoRepository(seed: seed),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          splashFactory: NoSplash.splashFactory,
        ),
        home: TodoScreen(initialDate: _date),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(TodoScreen)));

PlannerState _state(WidgetTester tester) =>
    _container(tester).read(todoProvider).requireValue;

Finder _key(String key) => find.byKey(ValueKey(key));

String _text(WidgetTester tester, String key) =>
    tester.widget<Text>(_key(key)).data!;

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.pumpAndSettle();
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String key, String text) async {
  await tester.ensureVisible(_key(key));
  await tester.pumpAndSettle();
  await tester.enterText(_key(key), text);
}

void main() {
  testWidgets('button saves title, place, time and clears the composer', (
    tester,
  ) async {
    await _pumpApp(tester);
    expect(_key('todo-empty-state'), findsOneWidget);
    await _enter(tester, 'todo-input', '  Flutter 과제 마무리  ');
    await _enter(tester, 'location-input', '  도서관  ');
    await _enter(tester, 'minutes-input', '45');
    await _tap(tester, 'add-todo-button');

    final task = _state(tester).tasks.single;
    expect(task.title, 'Flutter 과제 마무리');
    expect(task.location, '도서관');
    expect(task.estimatedMinutes, 45);
    expect(task.date, _date);
    expect(find.text(task.title), findsOneWidget);
    expect(_text(tester, 'title-todo-${task.id}'), task.title);
    expect(
      tester
          .widget<Text>(_key('location-todo-${task.id}'))
          .textSpan!
          .toPlainText(),
      contains('도서관'),
    );
    expect(
      tester
          .widget<Text>(_key('minutes-todo-${task.id}'))
          .textSpan!
          .toPlainText(),
      contains('45분'),
    );
    expect(_text(tester, 'todo-count'), '1개');
    expect(_key('todo-empty-state'), findsNothing);
    final input = tester.widget<TextField>(_key('todo-input'));
    expect(input.controller!.text, isEmpty);
    expect(input.focusNode!.hasFocus, isTrue);
    expect(
      tester.widget<TextField>(_key('location-input')).controller!.text,
      isEmpty,
    );
    expect(
      tester.widget<TextField>(_key('minutes-input')).controller!.text,
      '30',
    );
  });

  testWidgets('Enter submits with default place and time', (tester) async {
    await _pumpApp(tester);
    await _enter(tester, 'todo-input', 'DevTools 화면 캡처');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final task = _state(tester).tasks.single;
    expect(task.title, 'DevTools 화면 캡처');
    expect(task.location, '미지정');
    expect(task.estimatedMinutes, 30);
    expect(task.isCompleted, isFalse);
  });

  testWidgets('invalid title or time stays in the composer', (tester) async {
    await _pumpApp(tester);
    await _enter(tester, 'todo-input', '   ');
    await _tap(tester, 'add-todo-button');
    expect(find.text('할 일을 입력하세요.'), findsOneWidget);
    expect(_state(tester).tasks, isEmpty);

    await _enter(tester, 'todo-input', '유효한 입력');
    await _enter(tester, 'minutes-input', '0');
    await _tap(tester, 'add-todo-button');
    expect(find.text('할 일을 입력하세요.'), findsNothing);
    expect(find.text('1~1440분으로 입력하세요.'), findsOneWidget);
    expect(_state(tester).tasks, isEmpty);
    expect(
      tester.widget<TextField>(_key('todo-input')).controller!.text,
      '유효한 입력',
    );
  });

  testWidgets('duplicate titles are deleted by the selected id', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      seed: PlannerState(tasks: [_todo(1, '같은 제목'), _todo(2, '같은 제목')]),
    );
    expect(find.text('같은 제목'), findsNWidgets(2));
    await _tap(tester, 'delete-todo-1');
    expect(_state(tester).tasks.single.id, 2);
    expect(find.text('같은 제목'), findsOneWidget);
    expect(_text(tester, 'todo-count'), '1개');
    await _tap(tester, 'delete-todo-2');
    expect(_key('todo-empty-state'), findsOneWidget);
    expect(_state(tester).statsFor(_date).requiredCount, 3);
  });

  testWidgets('zero is a completed rating, can be edited, then reopened', (
    tester,
  ) async {
    await _pumpApp(tester, seed: PlannerState(tasks: [_todo(1, '완료할 일')]));
    await _tap(tester, 'complete-todo-1');
    await _enter(tester, 'rating-input', '11');
    await _tap(tester, 'rating-save');
    expect(find.text('0부터 10 사이의 정수를 입력하세요.'), findsOneWidget);
    expect(_state(tester).tasks.single.isCompleted, isFalse);

    await _enter(tester, 'rating-input', '0');
    await _tap(tester, 'rating-save');
    expect(_key('rating-input'), findsNothing);
    expect(_state(tester).tasks.single.isCompleted, isTrue);
    expect(_state(tester).tasks.single.score, 0);
    expect(_text(tester, 'pending-count'), '0개');
    expect(_text(tester, 'finished-count'), '1개');
    expect(
      find.descendant(
        of: _key('pending-section'),
        matching: _key('title-todo-1'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: _key('completed-section'),
        matching: _key('title-todo-1'),
      ),
      findsOneWidget,
    );
    expect(_text(tester, 'quality-average'), '완료 평점 평균  0.0');
    expect(_text(tester, 'completed-count'), '1 / 3개');
    expect(_text(tester, 'completed-minutes'), '30 / 90분');

    await _tap(tester, 'rate-todo-1');
    await _enter(tester, 'rating-input', '9');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(_state(tester).tasks.single.score, 9);
    expect(_text(tester, 'daily-score'), '3.0');

    await _tap(tester, 'complete-todo-1');
    expect(_state(tester).tasks.single.score, isNull);
    expect(_text(tester, 'pending-count'), '1개');
    expect(_text(tester, 'finished-count'), '0개');
    expect(
      find.descendant(
        of: _key('pending-section'),
        matching: _key('title-todo-1'),
      ),
      findsOneWidget,
    );
    expect(_text(tester, 'quality-average'), '완료 평점 평균  아직 없음');
    expect(_text(tester, 'completed-count'), '0 / 3개');
  });

  testWidgets('month navigation, date selection and today filter the list', (
    tester,
  ) async {
    final otherDate = DateTime(2026, 11, 5);
    await _pumpApp(
      tester,
      seed: PlannerState(
        tasks: [
          _todo(1, '10월 기록'),
          _todo(2, '11월 기록', date: otherDate),
        ],
      ),
    );
    expect(find.text('10월 기록'), findsOneWidget);
    expect(find.text('11월 기록'), findsNothing);
    await _tap(tester, 'calendar-next');
    await _tap(tester, 'calendar-day-${dateKey(otherDate)}');
    expect(find.text('10월 기록'), findsNothing);
    expect(find.text('11월 기록'), findsOneWidget);
    expect(_text(tester, 'selected-date'), '2026년 11월 5일 (목)');
    await _tap(tester, 'calendar-today');
    final today = normalizeDate(DateTime.now());
    expect(_key('calendar-day-${dateKey(today)}'), findsOneWidget);
    expect(
      _text(tester, 'selected-date'),
      startsWith('${today.year}년 ${today.month}월 ${today.day}일'),
    );
  });

  testWidgets('edit validates dates and moves title, place and time together', (
    tester,
  ) async {
    await _pumpApp(tester, seed: PlannerState(tasks: [_todo(1, '이전 제목')]));
    await _tap(tester, 'edit-todo-1');
    await _enter(tester, 'edit-title-input', '  새 제목  ');
    await _enter(tester, 'edit-location-input', '집');
    await _enter(tester, 'edit-minutes-input', '60');
    await _enter(tester, 'edit-date-input', '2026-02-30');
    await _tap(tester, 'edit-save');
    expect(_key('edit-date-input'), findsOneWidget);
    expect(_state(tester).tasks.single.title, '이전 제목');

    await _enter(tester, 'edit-date-input', '2026-10-08');
    await _tap(tester, 'edit-save');
    final task = _state(tester).tasks.single;
    expect(task.title, '새 제목');
    expect(task.location, '집');
    expect(task.estimatedMinutes, 60);
    expect(task.date, DateTime(2026, 10, 8));
    expect(_key('todo-empty-state'), findsOneWidget);
    await _tap(tester, 'calendar-day-2026-10-08');
    expect(find.text('새 제목'), findsOneWidget);
    expect(_text(tester, 'todo-count'), '1개');
  });

  testWidgets('new goals apply to new record dates and retain old baselines', (
    tester,
  ) async {
    await _pumpApp(tester, seed: PlannerState(tasks: [_todo(1, '기존 날짜')]));
    await _tap(tester, 'goals-button');
    await _enter(tester, 'goal-count-input', '5');
    await _enter(tester, 'goal-minutes-input', '150');
    await _tap(tester, 'goals-save');
    expect(_state(tester).dailyCountGoal, 5);
    expect(_text(tester, 'completed-count'), '0 / 3개');
    expect(_text(tester, 'completed-minutes'), '0 / 90분');

    await _tap(tester, 'calendar-day-2026-10-08');
    await _enter(tester, 'todo-input', '새 날짜의 기록');
    await _tap(tester, 'add-todo-button');
    expect(_text(tester, 'completed-count'), '0 / 5개');
    expect(_text(tester, 'completed-minutes'), '0 / 150분');
    expect(_state(tester).statsFor(_date).requiredCount, 3);
  });

  testWidgets('summary and explanation use activity weighted daily scores', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      seed: PlannerState(
        tasks: [_todo(1, '높은 평점', score: 10), _todo(2, '낮은 평점', score: 1)],
      ),
    );
    expect(_text(tester, 'daily-score'), '3.7');
    expect(_text(tester, 'quality-average'), '완료 평점 평균  5.5');
    await _tap(tester, 'delete-todo-2');
    expect(_text(tester, 'daily-score'), '3.3');
    expect(_text(tester, 'quality-average'), '완료 평점 평균  10.0');
    await _tap(tester, 'score-details-button');
    expect(find.textContaining('완료 점수 합 ÷ 기준 개수'), findsOneWidget);
    expect(find.textContaining('= 3.33점이에요.'), findsOneWidget);
    expect(find.text('계획을 삭제해도 기준이 줄지 않는 이유'), findsOneWidget);
    expect(find.textContaining('삭제·시간 축소·다른 날로 이동'), findsOneWidget);
    expect(find.textContaining('입력한 예상 분의 합'), findsOneWidget);
  });

  testWidgets('year zero is rejected and opening the date picker stays safe', (
    tester,
  ) async {
    await _pumpApp(tester, seed: PlannerState(tasks: [_todo(1, '날짜 경계')]));
    await _tap(tester, 'edit-todo-1');
    await _enter(tester, 'edit-date-input', '0000-01-01');
    await _tap(tester, 'edit-save');
    expect(_state(tester).tasks.single.date, _date);
    expect(_key('edit-date-input'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: _key('edit-date-input'),
        matching: find.byType(IconButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('calendar navigation stops at supported year boundaries', (
    tester,
  ) async {
    Future<void> pumpCalendar(DateTime month) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 308,
              child: PlannerCalendar(
                month: month,
                selectedDate: month,
                scores: const {},
                onSelect: (_) {},
                onMonth: (_) {},
                onToday: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await pumpCalendar(DateTime(1, 1));
    expect(
      tester.widget<IconButton>(_key('calendar-previous')).onPressed,
      isNull,
    );
    expect(
      tester.widget<IconButton>(_key('calendar-next')).onPressed,
      isNotNull,
    );
    await pumpCalendar(DateTime(9999, 12));
    expect(
      tester.widget<IconButton>(_key('calendar-previous')).onPressed,
      isNotNull,
    );
    expect(tester.widget<IconButton>(_key('calendar-next')).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading and failed restore offer retry without clearing data', (
    tester,
  ) async {
    final repository = _ControlledRepository(
      PlannerState(tasks: [_todo(1, '보존한 기록')]),
    );
    await _pumpApp(tester, repository: repository, settle: false);
    expect(_key('planner-loading'), findsOneWidget);
    repository.loadResult.completeError(StateError('read failed'));
    await tester.pumpAndSettle();
    expect(find.text('저장된 기록을 불러오지 못했어요.'), findsOneWidget);
    expect(_key('todo-input'), findsNothing);
    await _tap(tester, 'retry-restore');
    expect(find.text('보존한 기록'), findsOneWidget);
    expect(repository.loadCount, 2);
    expect(repository.saveCount, 0);
  });

  testWidgets('failed saves retain state, input and the rating dialog', (
    tester,
  ) async {
    final repository = _FailingSaveRepository(
      PlannerState(tasks: [_todo(1, '기존 기록')]),
    );
    await _pumpApp(tester, repository: repository);
    await _enter(tester, 'todo-input', '잃어버리지 않을 입력');
    await _tap(tester, 'add-todo-button');
    expect(_state(tester).tasks.single.title, '기존 기록');
    expect(
      tester.widget<TextField>(_key('todo-input')).controller!.text,
      '잃어버리지 않을 입력',
    );
    expect(find.textContaining('기록은 바뀌지 않았습니다.'), findsOneWidget);

    await _tap(tester, 'complete-todo-1');
    await _enter(tester, 'rating-input', '8');
    await _tap(tester, 'rating-save');
    expect(_key('rating-input'), findsOneWidget);
    expect(find.text('저장하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    expect(_state(tester).tasks.single.isCompleted, isFalse);
    expect(
      tester.widget<TextField>(_key('rating-input')).controller!.text,
      '8',
    );
  });

  testWidgets('narrow layout, long content and rating dialog fit a keyboard', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(320, 640), keyboardHeight: 280);
    final title = List.filled(8, '긴 할 일 제목도 줄바꿈해서 읽을 수 있어요').join(' ');
    final location = List.filled(6, '길게 적은 장소').join(' ');
    final category = List.filled(4, '직접 적은 긴 카테고리').join(' ');
    await _enter(tester, 'category-input', category);
    await _enter(tester, 'todo-input', title);
    await _enter(tester, 'location-input', location);
    await _tap(tester, 'add-todo-button');
    expect(_state(tester).tasks.single.title, title);
    expect(tester.takeException(), isNull);
    await _tap(tester, 'complete-todo-1');
    await _enter(tester, 'rating-input', '10');
    await _tap(tester, 'rating-save');
    expect(_state(tester).tasks.single.score, 10);
    expect(tester.takeException(), isNull);
    await _tap(tester, 'place-stats-button');
    expect(_key('place-stats-$category::$location'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _tap(tester, 'place-stats-close');
    await _tap(tester, 'feedback-button');
    await _enter(tester, 'feedback-good-input', '좁은 화면에서도 피드백을 남깁니다.');
    await _tap(tester, 'feedback-save');
    expect(_state(tester).reflectionFor(_date)!.good, '좁은 화면에서도 피드백을 남깁니다.');
    expect(tester.takeException(), isNull);
  });

  testWidgets('category suggestions and place autocomplete use entered data', (
    tester,
  ) async {
    final repository = MemoryTodoRepository(
      seed: PlannerState(
        tasks: [
          _todo(1, '기존 공부', category: '공부', location: '작은 도서관'),
          _todo(2, '기존 운동', category: '운동', location: '동네 공원'),
        ],
      ),
    );
    await _pumpApp(tester, repository: repository);
    await _tap(tester, 'category-option-공부');
    await _enter(tester, 'location-input', '도서');
    await tester.pumpAndSettle();
    expect(_key('location-input-option-작은 도서관'), findsOneWidget);
    expect(_key('location-input-option-동네 공원'), findsNothing);
    await _tap(tester, 'location-input-option-작은 도서관');
    await _enter(tester, 'todo-input', '장소 추천으로 추가');
    await _tap(tester, 'add-todo-button');
    expect(_state(tester).tasks.last.category, '공부');
    expect(_state(tester).tasks.last.location, '작은 도서관');
    expect(_text(tester, 'category-todo-3'), '공부');

    await _tap(tester, 'category-option-운동');
    await _enter(tester, 'location-input', '공');
    await tester.pumpAndSettle();
    expect(_key('location-input-option-동네 공원'), findsOneWidget);
    expect(_key('location-input-option-작은 도서관'), findsNothing);
  });

  testWidgets(
    'custom categories and places survive edit, deletion and reload',
    (tester) async {
      final repository = MemoryTodoRepository();
      await _pumpApp(tester, repository: repository);
      expect(_state(tester).placeCatalog, isEmpty);
      await _enter(tester, 'category-input', '취미');
      await _enter(tester, 'location-input', '작업실');
      await _enter(tester, 'todo-input', '그림 그리기');
      await _tap(tester, 'add-todo-button');
      await _tap(tester, 'edit-todo-1');
      await _enter(tester, 'edit-category-input', '사진');
      await _enter(tester, 'edit-location-input', '사진관');
      await _tap(tester, 'edit-save');
      expect(_state(tester).tasks.single.category, '사진');
      expect(_state(tester).locationsFor('취미'), contains('작업실'));
      expect(_state(tester).locationsFor('사진'), contains('사진관'));
      await _tap(tester, 'delete-todo-1');
      _container(tester).invalidate(todoProvider);
      await tester.pumpAndSettle();
      expect(_state(tester).tasks, isEmpty);
      expect(_state(tester).locationsFor('사진'), contains('사진관'));
      await _enter(tester, 'category-input', '사진');
      await _enter(tester, 'location-input', '사진');
      await tester.pumpAndSettle();
      expect(_key('location-input-option-사진관'), findsOneWidget);
    },
  );

  testWidgets(
    'place analytics show sample size, zero ratings and category filter',
    (tester) async {
      await _pumpApp(
        tester,
        seed: PlannerState(
          tasks: [
            _todo(1, '좋은 공부', category: '공부', score: 9),
            _todo(2, '0점 공부', category: '공부', score: 0),
            _todo(3, '미완료 공부', category: '공부'),
            _todo(
              4,
              '미래 공부',
              category: '공부',
              date: DateTime(9999, 12, 31),
              score: 10,
            ),
            _todo(5, '운동 완료', category: '운동', location: '공원', score: 8),
          ],
        ),
      );
      await _tap(tester, 'place-stats-button');
      expect(_text(tester, 'place-success-공부::도서관'), '관측 성공률  33%');
      expect(_text(tester, 'place-sample-공부::도서관'), '8점 이상 완료 1개 / 전체 3개');
      expect(_text(tester, 'place-quality-공부::도서관'), '완료 평점 평균  4.5');
      expect(_key('place-stats-운동::공원'), findsOneWidget);
      expect(find.textContaining('앞으로의 수행을 예측하지 않습니다.'), findsOneWidget);
      await _tap(tester, 'place-category-filter');
      await tester.tap(find.text('공부').last);
      await tester.pumpAndSettle();
      expect(_key('place-stats-공부::도서관'), findsOneWidget);
      expect(_key('place-stats-운동::공원'), findsNothing);
    },
  );

  testWidgets('feedback saves and reopens without tasks or changing averages', (
    tester,
  ) async {
    final repository = MemoryTodoRepository();
    await _pumpApp(tester, repository: repository);
    await _tap(tester, 'feedback-button');
    await _enter(tester, 'feedback-good-input', '  집중을 잘했다  ');
    await _enter(tester, 'feedback-needs-work-input', '시작이 늦었다');
    await _enter(tester, 'feedback-improve-input', '먼저 작은 계획을 잡기');
    await _tap(tester, 'feedback-save');
    expect(_state(tester).reflectionFor(_date)!.good, '집중을 잘했다');
    expect(_state(tester).tasks, isEmpty);
    expect(_state(tester).statsFor(_date).hasRecord, isFalse);
    expect(_state(tester).historyStats(_date).averageScore, isNull);
    expect(_key('calendar-note-2026-10-07'), findsOneWidget);
    expect(_key('feedback-saved-summary'), findsOneWidget);
    _container(tester).invalidate(todoProvider);
    await tester.pumpAndSettle();
    await _tap(tester, 'feedback-button');
    expect(
      tester.widget<TextField>(_key('feedback-good-input')).controller!.text,
      '집중을 잘했다',
    );
    expect(
      tester
          .widget<TextField>(_key('feedback-needs-work-input'))
          .controller!
          .text,
      '시작이 늦었다',
    );
    expect(
      tester.widget<TextField>(_key('feedback-improve-input')).controller!.text,
      '먼저 작은 계획을 잡기',
    );
    await _enter(tester, 'feedback-good-input', '저장하지 않은 초안');
    await tester.tap(find.widgetWithText(TextButton, '취소'));
    await tester.pumpAndSettle();
    expect(_state(tester).reflectionFor(_date)!.good, '집중을 잘했다');
    await _tap(tester, 'calendar-day-2026-10-08');
    expect(_key('feedback-saved-summary'), findsNothing);
    await _tap(tester, 'feedback-button');
    expect(
      tester.widget<TextField>(_key('feedback-good-input')).controller!.text,
      isEmpty,
    );
  });

  testWidgets(
    'clearing feedback removes only the note and preserves daily scores',
    (tester) async {
      await _pumpApp(
        tester,
        seed: PlannerState(tasks: [_todo(1, '한 일', score: 9)]),
      );
      final before = _state(tester).statsFor(_date).dailyScore;
      await _tap(tester, 'feedback-button');
      await _enter(tester, 'feedback-good-input', '완료했다');
      await _tap(tester, 'feedback-save');
      await _tap(tester, 'feedback-button');
      await _enter(tester, 'feedback-good-input', '');
      await _tap(tester, 'feedback-save');
      expect(_state(tester).reflectionFor(_date), isNull);
      expect(_key('calendar-note-2026-10-07'), findsNothing);
      expect(_state(tester).statsFor(_date).dailyScore, before);
      expect(_state(tester).tasks.single.isCompleted, isTrue);
    },
  );

  testWidgets(
    'failed feedback save leaves all entered text in the open dialog',
    (tester) async {
      await _pumpApp(
        tester,
        repository: _FailingSaveRepository(PlannerState()),
      );
      await _tap(tester, 'feedback-button');
      await _enter(tester, 'feedback-good-input', '잘한 점을 보존');
      await _enter(tester, 'feedback-needs-work-input', '미흡한 점을 보존');
      await _enter(tester, 'feedback-improve-input', '개선할 점을 보존');
      await _tap(tester, 'feedback-save');
      expect(_state(tester).reflectionFor(_date), isNull);
      expect(
        tester.widget<TextField>(_key('feedback-good-input')).controller!.text,
        '잘한 점을 보존',
      );
      expect(
        tester
            .widget<TextField>(_key('feedback-needs-work-input'))
            .controller!
            .text,
        '미흡한 점을 보존',
      );
      expect(
        tester
            .widget<TextField>(_key('feedback-improve-input'))
            .controller!
            .text,
        '개선할 점을 보존',
      );
      expect(find.text('저장하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    },
  );
}

class _ControlledRepository implements TodoRepository {
  _ControlledRepository(this.state);
  final PlannerState state;
  final loadResult = Completer<PlannerState>();
  int loadCount = 0;
  int saveCount = 0;

  @override
  Future<PlannerState> load() {
    loadCount++;
    return loadCount == 1 ? loadResult.future : Future.value(state);
  }

  @override
  Future<void> save(PlannerState state) async => saveCount++;
}

class _FailingSaveRepository implements TodoRepository {
  _FailingSaveRepository(this.state);
  final PlannerState state;

  @override
  Future<PlannerState> load() async => state;

  @override
  Future<void> save(PlannerState state) async =>
      throw StateError('save failed');
}
