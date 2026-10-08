import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';

const timeout = Duration(seconds: 20);

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln(
      'Usage: dart run scripts/profile_workload.dart <VM WebSocket URL>',
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
  final watch = Stopwatch()..start();
  var additions = 0;
  var deletions = 0;
  Future<void> tap(String key) async {
    await driver.tap(find.byValueKey(key), timeout: timeout);
    await driver.requestData('render-frame', timeout: timeout);
  }

  Future<void> count(int expected) async {
    final text = await driver.getText(
      find.byValueKey('todo-count'),
      timeout: timeout,
    );
    if (text != '전체 $expected개') throw StateError('Unexpected count: $text');
  }

  try {
    await driver.runUnsynchronized(() async {
      await driver.setTextEntryEmulation(enabled: true);
      await count(0);
      for (var index = 1; index <= 20; index++) {
        await tap('todo-input');
        await driver.enterText('프로파일 작업 $index', timeout: timeout);
        await driver.requestData('render-frame', timeout: timeout);
        await tap('add-todo-button');
        await count(index);
        additions++;
        await Future<void>.delayed(const Duration(milliseconds: 80));
      }
      for (var id = 1; id <= 10; id++) {
        await tap('delete-todo-$id');
        await count(20 - id);
        deletions++;
        await Future<void>.delayed(const Duration(milliseconds: 80));
      }
      await tap('complete-todo-11');
      await count(10);
    });
    final evidence = {
      'version': '1.1.0+3',
      'status': 'success',
      'method': 'FlutterDriver UI actions on native Windows profile app',
      'completedAdditions': additions,
      'completedDeletions': deletions,
      'remainingCount': 10,
      'completionToggles': 1,
      'elapsedMilliseconds': watch.elapsedMilliseconds,
      'frameControl':
          'Verification-only warm-up frames; not an average FPS benchmark',
      'completedAtUtc': DateTime.now().toUtc().toIso8601String(),
    };
    final file = File('docs/evidence/profile_workload.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(
      '${const JsonEncoder.withIndent("  ").convert(evidence)}\n',
    );
    stdout.writeln(
      'Verified $additions additions, $deletions deletions and 1 completion; 10 remain.',
    );
  } finally {
    await driver.close();
  }
}
