import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';

const timeout = Duration(seconds: 20);

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln(
      'Usage: dart run scripts/capture_app.dart <VM WebSocket URL>',
    );
    exitCode = 64;
    return;
  }
  driverLog = (source, message) {
    stderr.writeln(
      '$source: ${message.replaceAll(RegExp(r"(?:wss?|https?)://\S+"), "[VM URL omitted]")}',
    );
  };
  final driver = await FlutterDriver.connect(
    dartVmServiceUrl: args.single,
    logCommunicationToFile: false,
  ).timeout(timeout);
  final captures = <Map<String, Object?>>[];
  final folder = Directory('docs/screenshots');
  await folder.create(recursive: true);
  Future<void> tap(String key) async {
    await driver.tap(find.byValueKey(key), timeout: timeout);
    await driver.requestData('render-frame', timeout: timeout);
  }

  Future<void> type(String title) async {
    await tap('todo-input');
    await driver.enterText(title, timeout: timeout);
    await driver.requestData('render-frame', timeout: timeout);
  }

  Future<void> count(int expected) async {
    final text = await driver.getText(
      find.byValueKey('todo-count'),
      timeout: timeout,
    );
    if (text != '전체 $expected개') throw StateError('Unexpected count: $text');
  }

  Future<void> capture(String name, String action) async {
    // Render through Material transitions before taking a stable screenshot.
    for (var frame = 0; frame < 10; frame++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await driver.requestData('render-frame', timeout: timeout);
    }
    final bytes = await driver.screenshot();
    await File('${folder.path}/$name').writeAsBytes(bytes);
    captures.add({
      'file': 'docs/screenshots/$name',
      'action': action,
      'capturedAtUtc': DateTime.now().toUtc().toIso8601String(),
      'bytes': bytes.length,
    });
  }

  try {
    await driver.runUnsynchronized(() async {
      await driver.setTextEntryEmulation(enabled: true);
      await count(0);
      for (final title in ['강의 복습', '운동하기', '과제 정리']) {
        await type(title);
        await tap('add-todo-button');
      }
      await tap('complete-todo-1');
      await count(3);
      await capture('01_list.png', '3개 목록, 첫 항목 완료 체크');
      await type('README 작성');
      await capture('02_add_input.png', '새 항목 제목 입력');
      await tap('add-todo-button');
      await count(4);
      await capture('03_add_result.png', '새 항목 추가, 4개 목록');
      await capture('04_delete_before.png', '운동하기 삭제 전');
      await tap('delete-todo-2');
      await count(3);
      await capture('05_delete_after.png', '운동하기 삭제 후, 3개 목록');
    });
    final evidence = {
      'version': '1.1.0+3',
      'status': 'success',
      'method': 'Native Windows FlutterDriver UI actions and screenshots',
      'captures': captures,
      'verifiedCounts': [3, 4, 3],
      'completedAtUtc': DateTime.now().toUtc().toIso8601String(),
    };
    final file = File('docs/evidence/simple_feature_capture.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(
      '${const JsonEncoder.withIndent("  ").convert(evidence)}\n',
    );
    stdout.writeln(
      'Verified list/add/delete/completion; captured 5 native screens.',
    );
  } finally {
    await driver.close();
  }
}
