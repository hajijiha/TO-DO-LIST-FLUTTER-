import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';

const _commandTimeout = Duration(seconds: 15);
const _pauseBetweenActions = Duration(milliseconds: 80);
const _additions = 20;
const _deletions = 10;

// Start test_driver/profile_app.dart (isolated MemoryTodoRepository) in profile mode,
// start recording in DevTools, then run this command from the project root:
// dart run scripts/profile_workload.dart ws://127.0.0.1:PORT/AUTH/ws
Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln(
      'Usage: dart run scripts/profile_workload.dart <VM service ws:// URL>',
    );
    exitCode = 64;
    return;
  }

  final serviceUri = Uri.tryParse(args.single);
  if (serviceUri == null ||
      !['ws', 'wss'].contains(serviceUri.scheme) ||
      serviceUri.host.isEmpty) {
    stderr.writeln('The first argument must be a VM service WebSocket URL.');
    exitCode = 64;
    return;
  }

  // Flutter Driver's connection log includes the complete VM service URL.
  // Keep the authentication token out of both logs and the evidence file.
  String sanitize(String message) {
    var sanitized = message.replaceAll(
      RegExp(r'(?:wss?|https?)://\S+'),
      '[VM service URL omitted]',
    );
    for (final segment in serviceUri.pathSegments) {
      if (segment.isNotEmpty && segment != 'ws') {
        sanitized = sanitized.replaceAll(segment, '[VM token omitted]');
      }
    }
    return sanitized;
  }

  driverLog = (source, message) {
    stderr.writeln('$source: ${sanitize(message)}');
  };

  final evidenceFile = File('docs/evidence/profile_workload.json');
  await evidenceFile.parent.create(recursive: true);
  final stopwatch = Stopwatch()..start();
  final evidence = <String, Object?>{
    'startedAtUtc': _timestamp(),
    'completedAtUtc': null,
    'status': 'running',
    'phase': 'connecting',
    'method': 'FlutterDriver UI actions',
    'driverHostOperatingSystem': Platform.operatingSystem,
    'vmServiceHost': serviceUri.host,
    'vmServicePort': serviceUri.port,
    'requestedAdditions': _additions,
    'requestedDeletions': _deletions,
    'completedAdditions': 0,
    'completedDeletions': 0,
    'completedScrollRequests': 0,
    'initialCount': null,
    'remainingCount': null,
    'pauseBetweenActionsMilliseconds': _pauseBetweenActions.inMilliseconds,
    'frameControl':
        'Verification-only warm-up frames after UI actions; not an average real-world FPS benchmark',
  };

  Future<void> saveEvidence() async {
    evidence['elapsedMilliseconds'] = stopwatch.elapsedMilliseconds;
    await evidenceFile.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(evidence)}\n',
      flush: true,
    );
  }

  await saveEvidence();
  FlutterDriver? driver;
  var resultCode = 1;
  try {
    final connectedDriver = await FlutterDriver.connect(
      dartVmServiceUrl: serviceUri.toString(),
      logCommunicationToFile: false,
    ).timeout(const Duration(seconds: 30));
    driver = connectedDriver;

    final input = find.byValueKey('todo-input');
    final addButton = find.byValueKey('add-todo-button');
    final count = find.byValueKey('todo-count');
    final scrollable = find.byValueKey('todo-scroll');
    var scrollRequests = 0;

    Future<void> scrollToTop() async {
      await connectedDriver.requestData(
        jsonEncode({'command': 'show', 'key': 'selected-date'}),
        timeout: _commandTimeout,
      );
      evidence['completedScrollRequests'] = ++scrollRequests;
      await Future<void>.delayed(_pauseBetweenActions);
    }

    Future<void> scrollIntoView(String keyName) async {
      await connectedDriver.requestData(
        jsonEncode({'command': 'show', 'key': keyName, 'alignment': 0.3}),
        timeout: _commandTimeout,
      );
      evidence['completedScrollRequests'] = ++scrollRequests;
      await Future<void>.delayed(_pauseBetweenActions);
    }

    Future<void> checkCount(int expected) async {
      await scrollToTop();
      final text = await connectedDriver.getText(
        count,
        timeout: _commandTimeout,
      );
      final actual = int.tryParse(text.replaceFirst('개', '').trim());
      evidence['remainingCount'] = actual;
      if (actual != expected) {
        throw _WorkloadFailure(
          'Expected $expected todos but observed $actual. '
          'Restart the app before running the workload.',
        );
      }
    }

    await connectedDriver.runUnsynchronized(() async {
      evidence['phase'] = 'checking fresh app';
      await connectedDriver.waitFor(input, timeout: _commandTimeout);
      await connectedDriver.setTextEntryEmulation(
        enabled: true,
        timeout: _commandTimeout,
      );
      await checkCount(0);
      evidence['initialCount'] = 0;
      await saveEvidence();

      for (var index = 1; index <= _additions; index++) {
        evidence['phase'] = 'adding $index of $_additions';
        await scrollToTop();
        await scrollIntoView('todo-input');
        await connectedDriver.tap(input, timeout: _commandTimeout);
        await Future<void>.delayed(_pauseBetweenActions);
        await connectedDriver.enterText(
          '프로파일 작업 ${index.toString().padLeft(2, '0')}',
          timeout: _commandTimeout,
        );
        await Future<void>.delayed(_pauseBetweenActions);
        await connectedDriver.requestData(
          'render-frame',
          timeout: _commandTimeout,
        );
        await scrollIntoView('add-todo-button');
        await connectedDriver.tap(addButton, timeout: _commandTimeout);
        await connectedDriver.requestData(
          'render-frame',
          timeout: _commandTimeout,
        );
        await Future<void>.delayed(_pauseBetweenActions);
        await checkCount(index);
        evidence['completedAdditions'] = index;
        await saveEvidence();
      }

      evidence['phase'] = 'scrolling through list';
      await connectedDriver.scroll(
        scrollable,
        0,
        2400,
        const Duration(milliseconds: 700),
        timeout: _commandTimeout,
      );
      evidence['completedScrollRequests'] = ++scrollRequests;
      await connectedDriver.scroll(
        scrollable,
        0,
        -2400,
        const Duration(milliseconds: 700),
        timeout: _commandTimeout,
      );
      evidence['completedScrollRequests'] = ++scrollRequests;
      await scrollToTop();
      await saveEvidence();

      // Move each real delete button into the viewport before tapping it.
      for (var id = 1; id <= _deletions; id++) {
        evidence['phase'] = 'deleting $id of $_deletions';
        await scrollToTop();
        final deleteButton = find.byValueKey('delete-todo-$id');
        await scrollIntoView('delete-todo-$id');
        await connectedDriver.tap(deleteButton, timeout: _commandTimeout);
        await connectedDriver.requestData(
          'render-frame',
          timeout: _commandTimeout,
        );
        await Future<void>.delayed(_pauseBetweenActions);
        await checkCount(_additions - id);
        evidence['completedDeletions'] = id;
        await saveEvidence();
      }

      await checkCount(_additions - _deletions);
      evidence['phase'] = 'completed';
      evidence['status'] = 'success';
      resultCode = 0;
      stdout.writeln(
        'Verified $_additions additions and $_deletions deletions; '
        '${_additions - _deletions} todos remain.',
      );
    });
  } catch (error) {
    evidence['status'] = 'failed';
    evidence['failedPhase'] = evidence['phase'];
    evidence['errorType'] = error.runtimeType.toString();
    evidence['error'] = error is _WorkloadFailure
        ? error.message
        : '${error.runtimeType} during ${evidence['phase']}: '
              '${sanitize(error.toString())}';
    stderr.writeln(evidence['error']);
  } finally {
    evidence['completedAtUtc'] = _timestamp();
    if (driver != null) {
      try {
        await driver.close().timeout(const Duration(seconds: 10));
      } catch (error) {
        evidence['driverCloseWarning'] = error.runtimeType.toString();
      }
    }
    stopwatch.stop();
    await saveEvidence();
  }

  // FlutterDriver.connect can continue retrying after Future.timeout. Exit
  // explicitly after saving evidence so a failed connection cannot hang.
  exit(resultCode);
}

String _timestamp() => DateTime.now().toUtc().toIso8601String();

class _WorkloadFailure implements Exception {
  const _WorkloadFailure(this.message);

  final String message;
}
