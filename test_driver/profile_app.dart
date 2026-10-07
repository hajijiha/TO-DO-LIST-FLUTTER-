import 'package:flutter/material.dart';
import 'frame_driver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:today_todo/main.dart';
import 'package:today_todo/providers/todo_provider.dart';
import 'package:today_todo/repositories/todo_repository.dart';

void main() {
  enableFrameDriver();
  runApp(
    ProviderScope(
      overrides: [
        todoRepositoryProvider.overrideWithValue(MemoryTodoRepository()),
      ],
      child: const TodayTodoApp(),
    ),
  );
}
