import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/todo_provider.dart';
import '../widgets/todo_tile.dart';

class TodoScreen extends ConsumerStatefulWidget {
  const TodoScreen({super.key});

  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends ConsumerState<TodoScreen> {
  final _inputController = TextEditingController();
  final _inputFocus = FocusNode();
  String? _inputError;

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _addTodo() {
    final added = ref
        .read(todoProvider.notifier)
        .addTodo(_inputController.text);
    setState(() => _inputError = added ? null : '할 일을 입력하세요.');
    if (added) _inputController.clear();
    _inputFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final todos = ref.watch(todoProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('오늘 할 일')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const ValueKey('todo-input'),
                          controller: _inputController,
                          focusNode: _inputFocus,
                          decoration: InputDecoration(
                            labelText: '할 일',
                            hintText: '새 할 일을 입력하세요',
                            border: const OutlineInputBorder(),
                            errorText: _inputError,
                          ),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _addTodo(),
                          onChanged: (_) {
                            if (_inputError != null) {
                              setState(() => _inputError = null);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        key: const ValueKey('add-todo-button'),
                        onPressed: _addTodo,
                        icon: const Icon(Icons.add),
                        label: const Text('추가'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '전체 ${todos.length}개',
                    key: const ValueKey('todo-count'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: todos.isEmpty
                        ? const Center(
                            child: Text(
                              '할 일이 없습니다.\n위에서 할 일을 추가해 보세요.',
                              key: ValueKey('todo-empty-state'),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            key: const ValueKey('todo-scroll'),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            itemCount: todos.length,
                            itemBuilder: (context, index) {
                              final todo = todos[index];
                              return TodoTile(
                                key: ValueKey(todo.id),
                                todo: todo,
                                onToggleCompleted: () => ref
                                    .read(todoProvider.notifier)
                                    .toggleTodo(todo.id),
                                onDelete: () => ref
                                    .read(todoProvider.notifier)
                                    .deleteTodo(todo.id),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
