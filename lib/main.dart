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
    return MaterialApp(
      title: 'To Do',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        fontFamilyFallback: const ['Malgun Gothic', 'sans-serif'],
      ),
      home: const TodoScreen(),
    );
  }
}
