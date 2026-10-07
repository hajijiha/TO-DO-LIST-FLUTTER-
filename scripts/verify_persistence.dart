import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';

// Run create, quit and restart the native persistence_app.dart, then run read.
// Use a fresh VERIFICATION_STORAGE_KEY for each independent verification run.
Future<void> main(List<String> args) async {
  if (args.length != 2 || !['create', 'read'].contains(args[1])) {
    throw ArgumentError(
      'Usage: dart run scripts/verify_persistence.dart <VM ws URL> <create|read>',
    );
  }
  driverLog = (source, message) {
    stderr.writeln(
      '$source: ${message.replaceAll(RegExp(r'(?:wss?|https?)://\S+'), '[VM URL omitted]')}',
    );
  };
  final driver = await FlutterDriver.connect(
    dartVmServiceUrl: args[0],
    logCommunicationToFile: false,
  ).timeout(const Duration(seconds: 30));
  const timeout = Duration(seconds: 20);
  SerializableFinder key(String name) => find.byValueKey(name);
  Future<void> tap(String name) async {
    await driver.scrollIntoView(key(name), timeout: timeout);
    await driver.tap(key(name), timeout: timeout);
  }

  try {
    await driver.runUnsynchronized(() async {
      await driver.waitFor(key('todo-input'), timeout: timeout);
      if (args[1] == 'create') {
        final before = await driver.getText(key('todo-count'));
        if (before != '0개' && before != '1개') {
          throw StateError('Use a fresh verification storage key.');
        }
        if (before == '0개') {
          for (final field in {
            'todo-input': '재시작 저장 검증',
            'category-input': '공부',
            'location-input': '도서관',
            'minutes-input': '45',
          }.entries) {
            await tap(field.key);
            await driver.enterText(field.value);
          }
          await driver.scroll(
            key('todo-scroll'),
            0,
            10000,
            const Duration(milliseconds: 200),
            timeout: timeout,
          );
          await tap('add-todo-button');
          await driver.waitFor(key('title-todo-1'), timeout: timeout);
          await tap('complete-todo-1');
          await tap('rating-input');
          await driver.enterText('9');
          await tap('rating-save');
          await driver.waitFor(key('rate-todo-1'), timeout: timeout);
          await driver.scroll(
            key('todo-scroll'),
            0,
            10000,
            const Duration(milliseconds: 200),
            timeout: timeout,
          );
          await tap('feedback-button');
          for (final field in {
            'feedback-good-input': '계획한 공부를 끝냈다.',
            'feedback-needs-work-input': '휴대폰을 자주 확인했다.',
            'feedback-improve-input': '다음에는 알림을 끄고 시작한다.',
          }.entries) {
            await tap(field.key);
            await driver.enterText(field.value);
          }
          await tap('feedback-save');
          await driver.waitFor(key('feedback-saved-summary'), timeout: timeout);
        }
      }
      stdout.writeln('Checking saved feedback and task fields.');
      await driver.waitFor(key('feedback-saved-summary'), timeout: timeout);
      await driver.waitFor(find.text('계획한 공부를 끝냈다.'), timeout: timeout);
      await driver.waitFor(find.text('휴대폰을 자주 확인했다.'), timeout: timeout);
      await driver.waitFor(find.text('다음에는 알림을 끄고 시작한다.'), timeout: timeout);
      final count = await driver.getText(key('todo-count'));
      final title = await driver.getText(key('title-todo-1'));
      final category = await driver.getText(key('category-todo-1'));
      final location = await driver.getText(
        find.descendant(
          of: key('location-todo-1'),
          matching: find.byType('RichText'),
          firstMatchOnly: true,
        ),
      );
      final minutes = await driver.getText(
        find.descendant(
          of: key('minutes-todo-1'),
          matching: find.byType('RichText'),
          firstMatchOnly: true,
        ),
      );
      if (title != '재시작 저장 검증' ||
          category != '공부' ||
          !location.contains('도서관') ||
          !minutes.contains('45분')) {
        throw StateError('Persisted task fields did not match the visible UI.');
      }
      stdout.writeln('Checking persisted daily score.');
      final score = await driver.getText(key('daily-score'));
      final quality = await driver.getText(key('quality-average'));
      if (count != '1개' || score != '3.8' || !quality.contains('9.0')) {
        throw StateError(
          'Unexpected persisted UI: count=$count, score=$score, quality=$quality',
        );
      }
      if (args[1] == 'create') {
        await driver.scroll(
          key('todo-scroll'),
          0,
          10000,
          const Duration(milliseconds: 200),
          timeout: timeout,
        );
      }
      stdout.writeln('Checking persisted place statistics.');
      await driver.tap(key('place-stats-button'), timeout: timeout);
      await driver.requestData('render-frame', timeout: timeout);
      final placeRate = await driver.getText(
        key('place-success-공부::도서관'),
        timeout: timeout,
      );
      final placeSample = await driver.getText(
        key('place-sample-공부::도서관'),
        timeout: timeout,
      );
      if (!placeRate.contains('100%') || !placeSample.contains('1개 / 전체 1개')) {
        throw StateError('Category and place statistics were not restored.');
      }
      await driver.tap(key('place-stats-close'), timeout: timeout);
      final evidence = {
        'phase': args[1],
        'status': 'passed',
        'checkedAtUtc': DateTime.now().toUtc().toIso8601String(),
        'repository':
            'SharedPreferencesTodoRepository with a separate verification key',
        'nativePlatform': Platform.operatingSystem,
        'countText': count,
        'dailyScoreText': score,
        'qualityAverageText': quality,
        'titleText': title,
        'locationText': location,
        'minutesText': minutes,
        'categoryText': category,
        'placeRateText': placeRate,
        'placeSampleText': placeSample,
        'reflectionVerifiedFromVisibleText': true,
        'storedTask': {
          'title': '재시작 저장 검증',
          'location': '도서관',
          'estimatedMinutes': 45,
          'score': 9,
        },
      };
      await File('docs/evidence/persistence_${args[1]}.json').writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(evidence)}\n',
      );
      stdout.writeln(
        'Native persistence ${args[1]} verified: $count, $score / 10.',
      );
    });
  } finally {
    await driver.close();
  }
}
