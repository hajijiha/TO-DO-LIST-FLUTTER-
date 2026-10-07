import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';

const _timeout = Duration(seconds: 20);

// Launch test_driver/capture_app.dart in debug mode, then pass its VM ws URL.
// This entry point uses isolated sample history, never production preferences.
Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln('Usage: dart run scripts/capture_app.dart <VM ws URL>');
    exitCode = 64;
    return;
  }
  final uri = Uri.parse(args.single);
  if (!['ws', 'wss'].contains(uri.scheme) || uri.host.isEmpty) {
    throw ArgumentError('A VM service WebSocket URL is required.');
  }
  driverLog = (source, message) {
    stderr.writeln(
      '$source: ${message.replaceAll(RegExp(r'(?:wss?|https?)://\S+'), '[VM URL omitted]')}',
    );
  };
  final folder = Directory('docs/screenshots');
  await folder.create(recursive: true);
  final evidenceFile = File('docs/evidence/feature_capture_v2.json');
  final captures = <Map<String, Object?>>[];
  final evidence = <String, Object?>{
    'version': 2,
    'startedAtUtc': DateTime.now().toUtc().toIso8601String(),
    'status': 'running',
    'method': 'Native Windows FlutterDriver UI actions and screenshot',
    'sampleHistory': true,
    'productionStorageChanged': false,
    'captures': captures,
  };
  Future<void> save() async {
    await evidenceFile.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(evidence)}\n',
    );
  }

  await save();
  FlutterDriver? driver;
  try {
    final d = await FlutterDriver.connect(
      dartVmServiceUrl: uri.toString(),
      logCommunicationToFile: false,
    ).timeout(const Duration(seconds: 30));
    driver = d;
    SerializableFinder key(String value) => find.byValueKey(value);
    Future<void> top() async {
      await d.requestData(
        jsonEncode({'command': 'show', 'key': 'selected-date'}),
        timeout: _timeout,
      );
    }

    Future<void> tap(String value) async {
      await d.requestData(
        jsonEncode({'command': 'show', 'key': value}),
        timeout: _timeout,
      );
      await d.tap(key(value), timeout: _timeout);
      await d.requestData('render-frame', timeout: _timeout);
    }

    Future<void> type(String value, String text) async {
      await tap(value);
      await d.enterText(text, timeout: _timeout);
      await d.requestData('render-frame', timeout: _timeout);
    }

    Future<void> count(int expected) async {
      final actual = await d.getText(key('todo-count'), timeout: _timeout);
      if (actual != '$expected개') {
        throw StateError('Expected $expected items; got $actual');
      }
    }

    Future<void> capture(
      String name,
      String action, {
      bool resetScroll = true,
      bool focusList = false,
    }) async {
      if (resetScroll) await top();
      if (focusList) {
        await d.requestData(
          jsonEncode({
            'command': 'show',
            'key': 'todo-count',
            'alignment': 0.08,
          }),
          timeout: _timeout,
        );
      }
      await d.requestData('render-frame', timeout: _timeout);
      final bytes = await d.screenshot();
      if (bytes.length < 8 || bytes[0] != 137 || bytes[1] != 80) {
        throw StateError('Screenshot is not PNG.');
      }
      await File('${folder.path}/$name').writeAsBytes(bytes);
      captures.add({
        'filename': 'docs/screenshots/$name',
        'action': action,
        'capturedAtUtc': DateTime.now().toUtc().toIso8601String(),
        'bytes': bytes.length,
      });
      await save();
      stdout.writeln('Captured $name');
    }

    Future<void> add(String title, String location, int minutes) async {
      await top();
      await type('todo-input', title);
      await type('category-input', '공부');
      await type('location-input', location);
      await type('minutes-input', '$minutes');
      await top();
      await tap('add-todo-button');
    }

    await d.runUnsynchronized(() async {
      await d.waitFor(key('todo-input'), timeout: _timeout);
      await count(0);
      await add('Flutter 강의 복습', '도서관', 30);
      await count(1);
      await add('Riverpod 구조 정리', '스터디룸', 40);
      await count(2);
      await add('README 작성', '집', 20);
      await count(3);
      await capture(
        '01_list.png',
        'Three tasks with places, time and unfinished state',
        focusList: true,
      );
      await type('todo-input', 'DevTools 화면 캡처');
      await type('location-input', '컴퓨터실');
      await type('minutes-input', '45');
      await capture(
        '02_add_input.png',
        'Title, location and estimated minutes before adding',
      );
      await tap('add-todo-button');
      await count(4);
      await capture('03_add_result.png', 'Fourth task added', focusList: true);
      await capture(
        '04_delete_before.png',
        'Before deletion of task 11',
        focusList: true,
      );
      await tap('delete-todo-11');
      await count(3);
      await capture(
        '05_delete_after.png',
        'Deleted task 11; daily denominator remains 4 tasks / 135 minutes',
        focusList: true,
      );
      await tap('complete-todo-10');
      await type('rating-input', '8');
      await capture(
        '10_rating_dialog.png',
        'Completion with a performance rating out of 10',
        resetScroll: false,
      );
      await tap('rating-save');
      await tap('complete-todo-12');
      await type('rating-input', '9');
      await tap('rating-save');
      await top();
      evidence['dailyScoreText'] = await d.getText(
        key('daily-score'),
        timeout: _timeout,
      );
      evidence['qualityAverageText'] = await d.getText(
        key('quality-average'),
        timeout: _timeout,
      );
      if (evidence['dailyScoreText'] != '3.7' ||
          !(evidence['qualityAverageText'] as String).contains('8.5')) {
        throw StateError(
          'Native scoring result differs from the expected 3.7 / 8.5.',
        );
      }
      await d.requestData(
        jsonEncode({'command': 'show', 'key': 'daily-score'}),
        timeout: _timeout,
      );
      await capture(
        '11_daily_score.png',
        'Two completed tasks, quality mean 8.5, adjusted daily score 3.7',
        resetScroll: false,
      );
      await d.requestData(
        jsonEncode({
          'command': 'show',
          'key': 'pending-section',
          'alignment': 0.05,
        }),
        timeout: _timeout,
      );
      await capture(
        '18_separate_lists.png',
        'Pending and completed tasks appear in separate sections',
        resetScroll: false,
      );
      await top();
      await type('category-input', '공부');
      await type('location-input', '도');
      await d.waitFor(key('location-input-option-도서관'), timeout: _timeout);
      await capture(
        '15_place_catalog.png',
        'Previously entered places are suggested for the selected category',
        resetScroll: false,
      );
      await tap('location-input-option-도서관');
      await top();
      await tap('place-stats-button');
      final success = await d.getText(
        key('place-success-공부::도서관'),
        timeout: _timeout,
      );
      final sample = await d.getText(
        key('place-sample-공부::도서관'),
        timeout: _timeout,
      );
      if (!success.contains('67%') || !sample.contains('2개 / 전체 3개')) {
        throw StateError(
          'Unexpected place success or sample count: $success / $sample',
        );
      }
      evidence['placeSuccessText'] = success;
      evidence['placeSampleText'] = sample;
      await capture(
        '16_place_stats.png',
        'Category and place records include observed success rate, rating and sample count',
        resetScroll: false,
      );
      await tap('place-stats-close');
      await top();
      await tap('feedback-button');
      await type('feedback-good-input', '도서관에서 강의 복습을 마쳤고 README도 정리했다.');
      await type('feedback-needs-work-input', 'DevTools 화면 촬영까지는 끝내지 못했다.');
      await type('feedback-improve-input', '내일은 촬영 시간을 먼저 확보하고 알림을 끈다.');
      await capture(
        '17_day_reflection.png',
        'A manually written daily reflection: strengths, shortcomings and improvements',
        resetScroll: false,
      );
      await tap('feedback-save');
      await d.waitFor(key('feedback-saved-summary'), timeout: _timeout);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final date =
          '${yesterday.year.toString().padLeft(4, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      await top();
      if (yesterday.month != DateTime.now().month ||
          yesterday.year != DateTime.now().year) {
        await tap('calendar-previous');
      }
      await tap('calendar-day-$date');
      await capture(
        '12_calendar_history.png',
        'Calendar date selection shows previously completed tasks',
      );
      await tap('calendar-today');
      await tap('edit-todo-13');
      await capture(
        '13_edit_dialog.png',
        'Edit title, place, time and date',
        resetScroll: false,
      );
      await tap('edit-save');
      await top();
      await tap('goals-button');
      await capture(
        '14_goal_settings.png',
        'Count and time goals for new record dates',
        resetScroll: false,
      );
      await tap('goals-save');
      evidence['status'] = 'completed';
      evidence['completedAtUtc'] = DateTime.now().toUtc().toIso8601String();
    });
  } catch (error) {
    evidence['status'] = 'failed';
    evidence['error'] = error.toString();
    stderr.writeln(error);
    exitCode = 1;
  } finally {
    await save();
    await driver?.close();
  }
  if (exitCode != 0) exit(exitCode);
}
