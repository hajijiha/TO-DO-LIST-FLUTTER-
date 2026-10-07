import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/todo_screen.dart';

void main() {
  runApp(const ProviderScope(child: TodayTodoApp()));
}

class TodayTodoApp extends StatelessWidget {
  const TodayTodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF176B60),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: '오늘 할 일 · 하루 기록',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF7F8F4),
        fontFamilyFallback: const ['Malgun Gothic', 'sans-serif'],
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      home: const TodoScreen(),
    );
  }
}
