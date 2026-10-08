import 'package:flutter/material.dart';

import '../models/todo.dart';

class TodoTile extends StatelessWidget {
  const TodoTile({
    super.key,
    required this.todo,
    required this.onDelete,
    required this.onToggleCompleted,
  });

  final Todo todo;
  final VoidCallback onDelete;
  final VoidCallback onToggleCompleted;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        key: ValueKey('complete-todo-${todo.id}'),
        value: todo.isCompleted,
        semanticLabel: todo.isCompleted ? '완료 취소' : '완료 표시',
        onChanged: (_) => onToggleCompleted(),
      ),
      title: Text(
        todo.title,
        key: ValueKey('title-todo-${todo.id}'),
        style: TextStyle(
          decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
        ),
      ),
      trailing: IconButton(
        key: ValueKey('delete-todo-${todo.id}'),
        tooltip: '${todo.title} 삭제',
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline),
      ),
    );
  }
}
