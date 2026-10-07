import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:today_todo/models/planner_state.dart';
import 'package:today_todo/models/todo.dart';
import 'package:today_todo/repositories/todo_repository.dart';

void main() {
  test(
    'fresh storage uses defaults; seed and saves round-trip as JSON',
    () async {
      final fresh = MemoryTodoRepository();
      expect((await fresh.load()).tasks, isEmpty);
      expect((await fresh.load()).dailyCountGoal, 3);
      final seed = PlannerState(
        tasks: [
          Todo(
            id: 1,
            title: '저장',
            location: '집',
            estimatedMinutes: 45,
            date: DateTime(2026, 10, 1),
            score: 0,
          ),
        ],
      );
      final repository = MemoryTodoRepository(seed: seed);
      expect((await repository.load()).toJson(), seed.toJson());
      await repository.save(seed.copyWith(dailyCountGoal: 4));
      expect((await repository.load()).dailyCountGoal, 4);
      expect((await repository.load()).tasks.single.isCompleted, isTrue);
    },
  );

  test(
    'invalid JSON and schema surface errors without resetting data',
    () async {
      final broken = MemoryTodoRepository(initialJson: '{broken');
      await expectLater(broken.load(), throwsFormatException);
      await expectLater(broken.load(), throwsFormatException);
      final wrongSchema = MemoryTodoRepository(
        initialJson: jsonEncode({'version': 99}),
      );
      await expectLater(wrongSchema.load(), throwsFormatException);
    },
  );
}
