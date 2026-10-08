import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:today_todo/providers/todo_provider.dart';

void main() {
  test('new containers start empty and do not share memory', () {
    final first = ProviderContainer.test();
    expect(first.read(todoProvider), isEmpty);
    first.read(todoProvider.notifier).addTodo('첫 실행');
    expect(first.read(todoProvider).single.id, 1);

    final second = ProviderContainer.test();
    expect(second.read(todoProvider), isEmpty);
    second.read(todoProvider.notifier).addTodo('새 실행');
    expect(second.read(todoProvider).single.id, 1);
    expect(first.read(todoProvider).single.title, '첫 실행');
  });

  test('add trims titles and rejects whitespace without consuming an ID', () {
    final container = ProviderContainer.test();
    final notifier = container.read(todoProvider.notifier);
    final empty = container.read(todoProvider);
    expect(notifier.addTodo(' \t\n '), isFalse);
    expect(identical(container.read(todoProvider), empty), isTrue);
    expect(notifier.addTodo('  Flutter 과제  '), isTrue);

    final todo = container.read(todoProvider).single;
    expect(todo.id, 1);
    expect(todo.title, 'Flutter 과제');
    expect(todo.isCompleted, isFalse);
  });

  test('duplicate titles are removed by ID and deleted IDs are not reused', () {
    final container = ProviderContainer.test();
    final notifier = container.read(todoProvider.notifier);
    notifier.addTodo('같은 제목');
    notifier.addTodo('같은 제목');
    expect(container.read(todoProvider).map((todo) => todo.id), [1, 2]);

    notifier.deleteTodo(1);
    expect(container.read(todoProvider).single.id, 2);
    notifier.deleteTodo(2);
    expect(container.read(todoProvider), isEmpty);
    notifier.addTodo('다음 항목');
    expect(container.read(todoProvider).single.id, 3);
  });

  test('toggle affects only the selected ID and can return to incomplete', () {
    final container = ProviderContainer.test();
    final notifier = container.read(todoProvider.notifier);
    notifier.addTodo('같은 제목');
    notifier.addTodo('같은 제목');
    final before = container.read(todoProvider);

    notifier.toggleTodo(2);
    var todos = container.read(todoProvider);
    expect(todos.first.isCompleted, isFalse);
    expect(todos.last.isCompleted, isTrue);
    expect(todos.last.id, 2);
    expect(todos.last.title, '같은 제목');
    expect(before.last.isCompleted, isFalse);

    notifier.toggleTodo(2);
    todos = container.read(todoProvider);
    expect(todos.every((todo) => !todo.isCompleted), isTrue);
  });

  test(
    'published lists are immutable and previous snapshots stay unchanged',
    () {
      final container = ProviderContainer.test();
      final notifier = container.read(todoProvider.notifier);
      notifier.addTodo('첫 항목');
      final before = container.read(todoProvider);
      expect(() => before.clear(), throwsUnsupportedError);

      notifier.addTodo('두 번째 항목');
      expect(before, hasLength(1));
      expect(container.read(todoProvider), hasLength(2));
      notifier.deleteTodo(1);
      expect(before.single.id, 1);
      expect(container.read(todoProvider).single.id, 2);
    },
  );

  test('unknown IDs leave the current state unchanged', () {
    final container = ProviderContainer.test();
    final notifier = container.read(todoProvider.notifier);
    notifier.addTodo('유지');
    final before = container.read(todoProvider);
    notifier.deleteTodo(999);
    notifier.toggleTodo(999);
    expect(identical(container.read(todoProvider), before), isTrue);
  });
}
