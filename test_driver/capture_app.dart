import 'frame_driver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:today_todo/main.dart';
import 'package:today_todo/models/planner_state.dart';
import 'package:today_todo/models/todo.dart';
import 'package:today_todo/providers/todo_provider.dart';
import 'package:today_todo/repositories/todo_repository.dart';

void main() {
  enableFrameDriver();
  final today = DateTime.now();
  final tasks = <Todo>[];
  for (var day = 1; day <= 3; day++) {
    for (var item = 0; item < 3; item++) {
      tasks.add(
        Todo(
          id: tasks.length + 1,
          title: ['강의 복습', '운동', '과제 작성'][item],
          category: ['공부', '운동', '공부'][item],
          location: [
            day == 3 ? '스터디카페' : '도서관',
            day == 3 ? '레드헬스장' : '그린헬스장',
            day == 2 ? '스터디카페' : '집',
          ][item],
          estimatedMinutes: 30,
          date: DateTime(today.year, today.month, today.day - day),
          score: [8, 7, 9][item] - (day - 1),
        ),
      );
    }
  }
  // Demonstration history is isolated from the production preference store.
  runApp(
    ProviderScope(
      overrides: [
        todoRepositoryProvider.overrideWithValue(
          MemoryTodoRepository(seed: PlannerState(tasks: tasks)),
        ),
      ],
      child: const TodayTodoApp(),
    ),
  );
}
