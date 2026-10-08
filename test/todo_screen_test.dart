import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:today_todo/models/todo.dart';
import 'package:today_todo/providers/todo_provider.dart';
import 'package:today_todo/screens/todo_screen.dart';

Future<void> _pumpApp(
  WidgetTester tester, {
  Size size = const Size(920, 760),
  double keyboardHeight = 0,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboardHeight);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetViewInsets);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          splashFactory: NoSplash.splashFactory,
        ),
        home: const TodoScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(TodoScreen)));

List<Todo> _todos(WidgetTester tester) => _container(tester).read(todoProvider);

Finder _key(String key) => find.byKey(ValueKey(key));

String _text(WidgetTester tester, String key) =>
    tester.widget<Text>(_key(key)).data!;

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.pumpAndSettle();
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

Future<void> _add(WidgetTester tester, String title) async {
  await tester.enterText(_key('todo-input'), title);
  await _tap(tester, 'add-todo-button');
}

void main() {
  testWidgets('empty list shows its count and guidance', (tester) async {
    await _pumpApp(tester);

    expect(find.text('오늘 할 일'), findsOneWidget);
    expect(_text(tester, 'todo-count'), '전체 0개');
    expect(_key('todo-empty-state'), findsOneWidget);
    expect(_todos(tester), isEmpty);
  });

  testWidgets('button adds a trimmed title and clears and focuses input', (
    tester,
  ) async {
    await _pumpApp(tester);
    await _add(tester, '  Flutter 과제 마무리  ');

    final todo = _todos(tester).single;
    expect(todo.title, 'Flutter 과제 마무리');
    expect(todo.isCompleted, isFalse);
    expect(_text(tester, 'title-todo-${todo.id}'), todo.title);
    expect(_text(tester, 'todo-count'), '전체 1개');
    expect(_key('todo-empty-state'), findsNothing);
    final input = tester.widget<TextField>(_key('todo-input'));
    expect(input.controller!.text, isEmpty);
    expect(input.focusNode!.hasFocus, isTrue);
  });

  testWidgets('Enter adds a todo', (tester) async {
    await _pumpApp(tester);
    await tester.enterText(_key('todo-input'), 'DevTools 화면 캡처');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(_todos(tester).single.title, 'DevTools 화면 캡처');
    expect(_text(tester, 'todo-count'), '전체 1개');
  });

  testWidgets('blank input is rejected and typing clears the error', (
    tester,
  ) async {
    await _pumpApp(tester);
    await _add(tester, '   ');

    expect(_todos(tester), isEmpty);
    expect(find.text('할 일을 입력하세요.'), findsOneWidget);
    expect(_text(tester, 'todo-count'), '전체 0개');

    await tester.enterText(_key('todo-input'), '유효한 할 일');
    await tester.pumpAndSettle();
    expect(find.text('할 일을 입력하세요.'), findsNothing);
    await _tap(tester, 'add-todo-button');
    expect(_todos(tester).single.title, '유효한 할 일');
  });

  testWidgets('duplicate titles delete only the selected id', (tester) async {
    await _pumpApp(tester);
    await _add(tester, '같은 제목');
    await _add(tester, '같은 제목');
    final firstId = _todos(tester).first.id;
    final secondId = _todos(tester).last.id;
    expect(find.text('같은 제목'), findsNWidgets(2));

    await _tap(tester, 'delete-todo-$firstId');
    expect(_todos(tester).single.id, secondId);
    expect(find.text('같은 제목'), findsOneWidget);
    expect(_text(tester, 'todo-count'), '전체 1개');

    await _tap(tester, 'delete-todo-$secondId');
    expect(_todos(tester), isEmpty);
    expect(_text(tester, 'todo-count'), '전체 0개');
    expect(_key('todo-empty-state'), findsOneWidget);
  });

  testWidgets('completion toggles both ways and updates the title style', (
    tester,
  ) async {
    await _pumpApp(tester);
    await _add(tester, '완료할 일');
    final id = _todos(tester).single.id;

    await _tap(tester, 'complete-todo-$id');
    expect(_todos(tester).single.isCompleted, isTrue);
    expect(tester.widget<Checkbox>(_key('complete-todo-$id')).value, isTrue);
    expect(
      tester.widget<Text>(_key('title-todo-$id')).style!.decoration,
      TextDecoration.lineThrough,
    );
    expect(_text(tester, 'todo-count'), '전체 1개');

    await _tap(tester, 'complete-todo-$id');
    expect(_todos(tester).single.isCompleted, isFalse);
    expect(tester.widget<Checkbox>(_key('complete-todo-$id')).value, isFalse);
    expect(
      tester.widget<Text>(_key('title-todo-$id')).style!.decoration,
      isNull,
    );
  });

  testWidgets('narrow screen fits a long title above a keyboard', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(320, 640), keyboardHeight: 280);
    final title = List.filled(12, '긴 제목을 줄바꿈해서 표시합니다').join(' ');
    await _add(tester, title);

    expect(_todos(tester).single.title, title);
    expect(find.text(title), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scrolling reaches later todos and deletes the selected row', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(420, 640));
    final notifier = _container(tester).read(todoProvider.notifier);
    for (var number = 1; number <= 30; number++) {
      notifier.addTodo('할 일 $number');
    }
    await tester.pumpAndSettle();
    final lastId = _todos(tester).last.id;

    await tester.scrollUntilVisible(
      _key('delete-todo-$lastId'),
      200,
      scrollable: find.descendant(
        of: _key('todo-scroll'),
        matching: find.byType(Scrollable),
      ),
    );
    await _tap(tester, 'delete-todo-$lastId');

    expect(_todos(tester), hasLength(29));
    expect(_todos(tester).any((todo) => todo.id == lastId), isFalse);
    expect(_text(tester, 'todo-count'), '전체 29개');
    expect(tester.takeException(), isNull);
  });
}
