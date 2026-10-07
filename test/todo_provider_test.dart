import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:today_todo/models/calendar.dart';
import 'package:today_todo/models/planner_state.dart';
import 'package:today_todo/providers/todo_provider.dart';
import 'package:today_todo/repositories/todo_repository.dart';

final _day = normalizeDate(DateTime.now().subtract(const Duration(days: 2)));

ProviderContainer _container(TodoRepository repository) =>
    ProviderContainer.test(
      overrides: [todoRepositoryProvider.overrideWithValue(repository)],
    );

Future<PlannerState> _read(ProviderContainer container) =>
    container.read(todoProvider.future);

void main() {
  test(
    'deleting unrated work keeps grown count and time denominators',
    () async {
      final container = _container(MemoryTodoRepository());
      await _read(container);
      final notifier = container.read(todoProvider.notifier);
      for (var index = 0; index < 4; index++) {
        await notifier.addTodo('계획 $index', date: _day);
      }
      await notifier.rateTodo(1, 8);
      final before = (await _read(container)).statsFor(_day);
      expect(before.requiredCount, 4);
      expect(before.requiredMinutes, 120);
      await notifier.deleteTodo(4);
      final after = (await _read(container)).statsFor(_day);
      expect(after.plannedCount, 3);
      expect(after.plannedMinutes, 90);
      expect(after.requiredCount, 4);
      expect(after.requiredMinutes, 120);
      expect(after.dailyScore, before.dailyScore);
    },
  );

  test('new target uses past daily average and stays a snapshot', () async {
    final container = _container(MemoryTodoRepository());
    await _read(container);
    final notifier = container.read(todoProvider.notifier);
    await notifier.updateGoals(count: 1, minutes: 30);
    await notifier.addTodo('지난 날', date: _day);
    await notifier.rateTodo(1, 8);
    final nextDay = _day.add(const Duration(days: 1));
    await notifier.addTodo('새 날', date: nextDay);
    expect((await _read(container)).statsFor(nextDay).targetScore, 8.5);
    await notifier.rateTodo(1, 10);
    expect((await _read(container)).statsFor(nextDay).targetScore, 8.5);
  });

  test('add trims input, normalizes dates and persists distinct IDs', () async {
    final repository = MemoryTodoRepository();
    final container = _container(repository);
    await _read(container);
    final notifier = container.read(todoProvider.notifier);
    expect(
      await notifier.addTodo(
        '  Flutter 과제  ',
        location: '  학교  ',
        estimatedMinutes: 40,
        date: DateTime(_day.year, _day.month, _day.day, 15, 30),
      ),
      isTrue,
    );
    expect(await notifier.addTodo('Flutter 과제', date: _day), isTrue);
    final planner = await _read(container);
    expect(planner.tasks.map((task) => task.title), [
      'Flutter 과제',
      'Flutter 과제',
    ]);
    expect(planner.tasks.first.location, '학교');
    expect(planner.tasks.first.date, _day);
    expect(planner.tasks.last.id, greaterThan(planner.tasks.first.id));
    expect((await repository.load()).toJson(), planner.toJson());
  });

  test(
    'blank titles and invalid numeric values leave state unchanged',
    () async {
      final container = _container(MemoryTodoRepository());
      final before = await _read(container);
      final notifier = container.read(todoProvider.notifier);
      expect(await notifier.addTodo(' \t\n '), isFalse);
      await expectLater(
        notifier.addTodo('시간', estimatedMinutes: 0),
        throwsArgumentError,
      );
      await expectLater(
        notifier.addTodo('시간', estimatedMinutes: 1441),
        throwsArgumentError,
      );
      await expectLater(
        notifier.updateGoals(count: 0, minutes: 90),
        throwsArgumentError,
      );
      await expectLater(
        notifier.updateGoals(count: 1001, minutes: 90),
        throwsArgumentError,
      );
      await expectLater(
        notifier.updateGoals(count: 3, minutes: 1441),
        throwsArgumentError,
      );
      expect(identical(await _read(container), before), isTrue);
    },
  );

  test(
    'ID deletion retains zero-score history after every task is deleted',
    () async {
      final container = _container(MemoryTodoRepository());
      await _read(container);
      final notifier = container.read(todoProvider.notifier);
      await notifier.addTodo('같은 제목', date: _day);
      await notifier.addTodo('같은 제목', date: _day);
      final before = await _read(container);
      await notifier.deleteTodo(before.tasks.first.id);
      expect((await _read(container)).tasks.single.id, before.tasks.last.id);
      await notifier.deleteTodo(before.tasks.last.id);
      final empty = await _read(container);
      final stats = empty.statsFor(_day);
      expect(stats.hasRecord, isTrue);
      expect(stats.dailyScore, 0);
      expect(stats.requiredCount, 3);
      expect(stats.requiredMinutes, 90);
      expect(empty.historyStats(_day).days.single.dailyScore, 0);
    },
  );

  test('editing downward or moving tasks preserves old denominators', () async {
    final container = _container(MemoryTodoRepository());
    await _read(container);
    final notifier = container.read(todoProvider.notifier);
    await notifier.addTodo('큰 계획', estimatedMinutes: 180, date: _day);
    final id = (await _read(container)).tasks.single.id;
    await notifier.rateTodo(id, 8);
    expect(
      await notifier.editTodo(
        id,
        title: '작은 계획',
        location: '',
        estimatedMinutes: 10,
        date: _day,
      ),
      isTrue,
    );
    var planner = await _read(container);
    expect(planner.statsFor(_day).requiredMinutes, 180);
    expect(planner.tasks.single.score, 8);
    expect(planner.tasks.single.location, '미지정');
    await notifier.editTodo(
      id,
      title: '다른 날',
      location: '집',
      estimatedMinutes: 240,
      date: _day.add(const Duration(days: 1)),
    );
    planner = await _read(container);
    expect(planner.statsFor(_day).requiredMinutes, 180);
    expect(planner.statsFor(_day).hasRecord, isTrue);
    expect(planner.statsFor(_day).dailyScore, 0);
    expect(
      planner.statsFor(_day.add(const Duration(days: 1))).requiredMinutes,
      240,
    );
    expect(
      await notifier.editTodo(
        id,
        title: ' ',
        location: '집',
        estimatedMinutes: 10,
        date: _day,
      ),
      isFalse,
    );
  });

  test('zero rating completes a task and reopen clears it', () async {
    final container = _container(MemoryTodoRepository());
    await _read(container);
    final notifier = container.read(todoProvider.notifier);
    await notifier.addTodo('평가', date: _day);
    final id = (await _read(container)).tasks.single.id;
    await notifier.rateTodo(id, 0);
    var planner = await _read(container);
    expect(planner.tasks.single.isCompleted, isTrue);
    expect(planner.statsFor(_day).completedCount, 1);
    expect(planner.statsFor(_day).completedMinutes, 30);
    expect(planner.statsFor(_day).qualityAverage, 0);
    await expectLater(notifier.rateTodo(id, 11), throwsArgumentError);
    await expectLater(notifier.rateTodo(id, -1), throwsArgumentError);
    await notifier.reopenTodo(id);
    planner = await _read(container);
    expect(planner.tasks.single.isCompleted, isFalse);
    expect(planner.statsFor(_day).qualityAverage, isNull);
  });

  test(
    'new goals affect new dates and preserve existing plan snapshots',
    () async {
      final container = _container(MemoryTodoRepository());
      await _read(container);
      final notifier = container.read(todoProvider.notifier);
      await notifier.addTodo('기존 날', date: _day);
      final original = (await _read(container)).plans[dateKey(_day)]!;
      await notifier.updateGoals(count: 5, minutes: 150);
      await notifier.addTodo('기존 날 추가', date: _day);
      await notifier.addTodo('새 날', date: _day.add(const Duration(days: 1)));
      final planner = await _read(container);
      expect(planner.statsFor(_day).requiredCount, original.requiredCount);
      expect(planner.statsFor(_day).requiredMinutes, original.requiredMinutes);
      expect(planner.statsFor(_day).targetScore, original.targetScore);
      expect(
        planner.statsFor(_day.add(const Duration(days: 1))).requiredCount,
        5,
      );
      expect(
        planner.statsFor(_day.add(const Duration(days: 1))).requiredMinutes,
        150,
      );
    },
  );

  test(
    'saves serialize and data changes only after storage succeeds',
    () async {
      final repository = _ControlledRepository(blockFirstSave: true);
      final container = _container(repository);
      final before = await _read(container);
      final notifier = container.read(todoProvider.notifier);
      final first = notifier.addTodo('첫 번째', date: _day);
      final second = notifier.addTodo('두 번째', date: _day);
      final third = notifier.addTodo('세 번째', date: _day);
      await repository.firstSaveStarted.future;
      expect(identical(await _read(container), before), isTrue);
      expect(repository.saveCount, 1);
      repository.releaseFirstSave.complete();
      expect(await Future.wait([first, second, third]), [true, true, true]);
      expect((await _read(container)).tasks.map((task) => task.id), [1, 2, 3]);
      expect(repository.maxConcurrentSaves, 1);
      expect((await repository.load()).tasks, hasLength(3));
    },
  );

  test(
    'save failure preserves state and does not poison later operations',
    () async {
      final repository = _ControlledRepository();
      final container = _container(repository);
      final before = await _read(container);
      final notifier = container.read(todoProvider.notifier);
      repository.failNextSave = true;
      await expectLater(notifier.addTodo('실패', date: _day), throwsStateError);
      expect(identical(await _read(container), before), isTrue);
      expect((await repository.load()).tasks, isEmpty);
      expect(await notifier.addTodo('재시도', date: _day), isTrue);
      expect((await _read(container)).tasks.single.title, '재시도');
    },
  );

  test(
    'reload retains ratings, goals, history and deleted ID sequence',
    () async {
      final repository = MemoryTodoRepository();
      final first = _container(repository);
      await _read(first);
      final notifier = first.read(todoProvider.notifier);
      await notifier.addTodo('저장할 항목', estimatedMinutes: 120, date: _day);
      await notifier.rateTodo(1, 9);
      await notifier.updateGoals(count: 4, minutes: 120);
      final expected = await _read(first);
      first.dispose();
      final second = _container(repository);
      expect((await _read(second)).toJson(), expected.toJson());
      final reloaded = second.read(todoProvider.notifier);
      await reloaded.deleteTodo(1);
      await reloaded.addTodo('새 항목', date: _day);
      final planner = await _read(second);
      expect(planner.tasks.single.id, 2);
      expect(planner.statsFor(_day).requiredMinutes, 120);
    },
  );

  test('corrupted storage stays AsyncError and is never overwritten', () async {
    final repository = MemoryTodoRepository(initialJson: '{broken');
    final container = _container(repository);
    await expectLater(_read(container), throwsFormatException);
    expect(container.read(todoProvider).hasError, isTrue);
    await expectLater(repository.load(), throwsFormatException);
    await expectLater(
      container.read(todoProvider.notifier).addTodo('덮어쓰지 않음'),
      throwsFormatException,
    );
    await expectLater(repository.load(), throwsFormatException);
  });

  test(
    'user categories and places persist across edits deletes and reload',
    () async {
      final repository = MemoryTodoRepository();
      final container = _container(repository);
      await _read(container);
      final notifier = container.read(todoProvider.notifier);
      await notifier.addTodo(
        '학습',
        category: '  자격증   공부 ',
        location: '  학교\t 도서관 ',
        date: _day,
      );
      var planner = await _read(container);
      expect(planner.tasks.single.category, '자격증 공부');
      expect(planner.locationsFor('자격증 공부'), ['학교 도서관']);
      await notifier.editTodo(
        1,
        title: '이동',
        location: '집',
        estimatedMinutes: 30,
        date: _day,
      );
      planner = await _read(container);
      expect(planner.tasks.single.category, '자격증 공부');
      expect(planner.locationsFor('자격증 공부'), ['집', '학교 도서관']);
      await notifier.editTodo(
        1,
        title: '카테고리 변경',
        category: ' 취미 ',
        location: '연습실',
        estimatedMinutes: 40,
        date: _day,
      );
      await notifier.deleteTodo(1);
      final loaded = await repository.load();
      expect(loaded.tasks, isEmpty);
      expect(loaded.categories, ['기타', '자격증 공부', '취미']);
      expect(loaded.locationsFor('취미'), ['연습실']);
      expect(loaded.locationsFor('자격증 공부'), ['집', '학교 도서관']);
      expect(
        loaded.placeStats().every((stats) => stats.successRate == null),
        isTrue,
      );
    },
  );

  test(
    'blank place keeps category but never enters autocomplete catalog',
    () async {
      final container = _container(MemoryTodoRepository());
      await _read(container);
      await container
          .read(todoProvider.notifier)
          .addTodo('장소 미정', category: '새 분야', location: ' ', date: _day);
      final planner = await _read(container);
      expect(planner.categories, contains('새 분야'));
      expect(planner.locationsFor('새 분야'), isEmpty);
      expect(planner.placeStats(category: '새 분야').single.location, '미지정');
    },
  );

  test(
    'reflection saves by date reloads and clears without creating day plans',
    () async {
      final repository = MemoryTodoRepository();
      final container = _container(repository);
      await _read(container);
      final notifier = container.read(todoProvider.notifier);
      await notifier.saveReflection(
        DateTime(_day.year, _day.month, _day.day, 19),
        good: ' 일찍 시작 ',
        needsWork: ' 산만함 ',
        improve: ' 알림 끄기 ',
      );
      var loaded = await repository.load();
      expect(loaded.reflectionFor(_day)!.good, '일찍 시작');
      expect(loaded.reflectionFor(_day)!.needsWork, '산만함');
      expect(loaded.reflectionFor(_day)!.improve, '알림 끄기');
      expect(loaded.plans, isEmpty);
      expect(loaded.historyStats(_day).averageScore, isNull);
      await notifier.saveReflection(
        _day.add(const Duration(days: 1)),
        good: '다른 날',
        needsWork: '',
        improve: '',
      );
      expect((await _read(container)).reflections, hasLength(2));
      await notifier.saveReflection(
        _day,
        good: ' ',
        needsWork: '\n',
        improve: '\t',
      );
      loaded = await repository.load();
      expect(loaded.reflectionFor(_day), isNull);
      expect(
        loaded.reflectionFor(_day.add(const Duration(days: 1)))!.good,
        '다른 날',
      );
    },
  );

  test(
    'reflection save failure preserves earlier fields and permits retry',
    () async {
      final repository = _ControlledRepository();
      final container = _container(repository);
      await _read(container);
      final notifier = container.read(todoProvider.notifier);
      await notifier.saveReflection(
        _day,
        good: '기존',
        needsWork: '',
        improve: '유지',
      );
      final before = await _read(container);
      repository.failNextSave = true;
      await expectLater(
        notifier.saveReflection(
          _day,
          good: '실패',
          needsWork: '새 값',
          improve: '',
        ),
        throwsStateError,
      );
      expect(identical(await _read(container), before), isTrue);
      expect((await repository.load()).reflectionFor(_day)!.good, '기존');
      await notifier.saveReflection(
        _day,
        good: '재시도',
        needsWork: '',
        improve: '',
      );
      expect((await _read(container)).reflectionFor(_day)!.good, '재시도');
    },
  );

  test('category and reflection updates share one serial save queue', () async {
    final repository = _ControlledRepository(blockFirstSave: true);
    final container = _container(repository);
    final before = await _read(container);
    final notifier = container.read(todoProvider.notifier);
    final add = notifier.addTodo(
      '동시 추가',
      category: '학습',
      location: '카페',
      date: _day,
    );
    final note = notifier.saveReflection(
      _day,
      good: '집중',
      needsWork: '',
      improve: '',
    );
    await repository.firstSaveStarted.future;
    expect(identical(await _read(container), before), isTrue);
    expect(repository.saveCount, 1);
    repository.releaseFirstSave.complete();
    await add;
    await note;
    final planner = await _read(container);
    expect(planner.locationsFor('학습'), ['카페']);
    expect(planner.reflectionFor(_day)!.good, '집중');
    expect(repository.maxConcurrentSaves, 1);
    expect((await repository.load()).toJson(), planner.toJson());
  });
}

class _ControlledRepository extends MemoryTodoRepository {
  _ControlledRepository({this.blockFirstSave = false});

  final bool blockFirstSave;
  final firstSaveStarted = Completer<void>();
  final releaseFirstSave = Completer<void>();
  bool failNextSave = false;
  int saveCount = 0;
  int _concurrentSaves = 0;
  int maxConcurrentSaves = 0;

  @override
  Future<void> save(PlannerState state) async {
    saveCount++;
    _concurrentSaves++;
    if (_concurrentSaves > maxConcurrentSaves) {
      maxConcurrentSaves = _concurrentSaves;
    }
    try {
      if (saveCount == 1) {
        firstSaveStarted.complete();
        if (blockFirstSave) await releaseFirstSave.future;
      }
      if (failNextSave) {
        failNextSave = false;
        throw StateError('Simulated storage failure.');
      }
      await super.save(state);
    } finally {
      _concurrentSaves--;
    }
  }
}
