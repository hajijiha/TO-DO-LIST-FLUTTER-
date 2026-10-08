import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/todo.dart';

final todoProvider = NotifierProvider<TodoNotifier, List<Todo>>(
  TodoNotifier.new,
);

class TodoNotifier extends Notifier<List<Todo>> {
  int _nextId = 1;

  @override
  List<Todo> build() => const [];

  bool addTodo(String rawTitle) {
    final title = rawTitle.trim();
    if (title.isEmpty) return false;

    Timeline.timeSync('todo.add', () {
      state = List<Todo>.unmodifiable([
        ...state,
        Todo(id: _nextId++, title: title),
      ]);
    });
    return true;
  }

  void deleteTodo(int id) {
    if (!state.any((todo) => todo.id == id)) return;

    Timeline.timeSync('todo.delete', () {
      state = List<Todo>.unmodifiable(state.where((todo) => todo.id != id));
    });
  }

  void toggleTodo(int id) {
    final index = state.indexWhere((todo) => todo.id == id);
    if (index == -1) return;

    Timeline.timeSync('todo.toggle', () {
      final todos = [...state];
      todos[index] = todos[index].copyWith(
        isCompleted: !todos[index].isCompleted,
      );
      state = List<Todo>.unmodifiable(todos);
    });
  }
}
