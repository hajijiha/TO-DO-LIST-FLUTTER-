import 'dart:async';
import 'dart:convert';
import 'dart:io';

// Read-only VM service inspection. This script never changes timeline flags,
// clears events, resumes an isolate, or restarts the app.
// dart run scripts/inspect_timeline.dart <VM service WebSocket URL>
Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln(
      'Usage: dart run scripts/inspect_timeline.dart <VM service ws:// URL>',
    );
    exitCode = 64;
    return;
  }
  final uri = Uri.tryParse(args.single);
  if (uri == null || !['ws', 'wss'].contains(uri.scheme) || uri.host.isEmpty) {
    stderr.writeln('A VM service WebSocket URL is required.');
    exitCode = 64;
    return;
  }

  String sanitize(String value) {
    var result = value.replaceAll(
      RegExp(r'(?:wss?|https?)://\S+'),
      '[VM service URL omitted]',
    );
    for (final segment in uri.pathSegments) {
      if (segment.isNotEmpty && segment != 'ws') {
        result = result.replaceAll(segment, '[VM token omitted]');
      }
    }
    return result;
  }

  final evidenceFile = File('docs/evidence/timeline_check.json');
  await evidenceFile.parent.create(recursive: true);
  final evidence = <String, Object?>{
    'startedAtUtc': DateTime.now().toUtc().toIso8601String(),
    'status': 'running',
    'readOnly': true,
    'vmServiceHost': uri.host,
    'vmServicePort': uri.port,
    'methods': ['getVMTimelineFlags', 'getVMTimeline'],
  };
  WebSocket? socket;
  StreamSubscription<dynamic>? subscription;
  final pending = <int, Completer<Map<String, dynamic>>>{};
  var requestId = 0;
  var resultCode = 1;

  void failPending(Object error) {
    for (final completer in pending.values) {
      if (!completer.isCompleted) completer.completeError(error);
    }
  }

  try {
    final connectedSocket = await WebSocket.connect(
      uri.toString(),
    ).timeout(const Duration(seconds: 10));
    socket = connectedSocket;
    subscription = connectedSocket.listen(
      (dynamic data) {
        try {
          final response = Map<String, dynamic>.from(
            jsonDecode(data as String) as Map,
          );
          final completer = pending[response['id']];
          if (completer != null && !completer.isCompleted) {
            completer.complete(response);
          }
        } catch (error) {
          failPending(error);
        }
      },
      onError: failPending,
      onDone: () => failPending(StateError('VM service connection closed.')),
    );

    Future<Map<String, dynamic>> rpc(String method) async {
      final id = ++requestId;
      final completer = Completer<Map<String, dynamic>>();
      pending[id] = completer;
      connectedSocket.add(
        jsonEncode({'jsonrpc': '2.0', 'id': id, 'method': method}),
      );
      try {
        final response = await completer.future.timeout(
          const Duration(seconds: 20),
        );
        if (response['error'] case final Map error) {
          throw StateError(
            '$method RPC error ${error['code']}: ${error['message']}',
          );
        }
        return Map<String, dynamic>.from(response['result'] as Map);
      } finally {
        pending.remove(id);
      }
    }

    final flags = await rpc('getVMTimelineFlags');
    evidence['recorderName'] = flags['recorderName'];
    evidence['availableStreams'] = flags['availableStreams'];
    evidence['recordedStreams'] = flags['recordedStreams'];

    final timeline = await rpc('getVMTimeline');
    final events = (timeline['traceEvents'] as List)
        .whereType<Map>()
        .map((event) => Map<String, dynamic>.from(event))
        .toList();
    final nameCounts = <String, int>{};
    final categoryCounts = <String, int>{};
    final todoEvents = <Map<String, Object?>>[];
    final todoCounts = {'todo.add': 0, 'todo.delete': 0};
    final todoStartCounts = {'todo.add': 0, 'todo.delete': 0};
    for (final event in events) {
      final name = event['name']?.toString() ?? '';
      final category = event['cat']?.toString() ?? '(none)';
      nameCounts[sanitize(name)] = (nameCounts[sanitize(name)] ?? 0) + 1;
      categoryCounts[sanitize(category)] =
          (categoryCounts[sanitize(category)] ?? 0) + 1;
      if (todoCounts.containsKey(name)) {
        todoCounts[name] = todoCounts[name]! + 1;
        if (['B', 'X'].contains(event['ph'])) {
          todoStartCounts[name] = todoStartCounts[name]! + 1;
        }
        todoEvents.add({
          for (final key in ['name', 'cat', 'ph', 'ts', 'dur', 'pid', 'tid'])
            if (event.containsKey(key)) key: event[key],
        });
      }
    }
    final sortedNames = nameCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final frameEvents =
        events
            .where((event) => event['name'] == 'Frame' && event['ts'] is num)
            .toList()
          ..sort((a, b) => (a['ts'] as num).compareTo(b['ts'] as num));
    final frames = <Map<String, dynamic>>[];
    final frameBegins = <String, List<Map<String, dynamic>>>{};
    final framePhaseCounts = <String, int>{};
    for (final event in frameEvents) {
      final phase = event['ph']?.toString() ?? '(none)';
      framePhaseCounts[phase] = (framePhaseCounts[phase] ?? 0) + 1;
      final thread = ['b', 'e'].contains(phase)
          ? '${event['pid']}:${event['cat']}:${event['id'] ?? event['id2']}'
          : '${event['pid']}:${event['tid']}';
      if (phase == 'X' && event['dur'] is num) {
        frames.add(event);
      } else if (['B', 'b'].contains(phase)) {
        frameBegins.putIfAbsent(thread, () => []).add(event);
      } else if (['E', 'e'].contains(phase) &&
          (frameBegins[thread]?.isNotEmpty ?? false)) {
        final begin = frameBegins[thread]!.removeLast();
        frames.add({
          'pid': begin['pid'],
          'tid': begin['tid'],
          'ts': begin['ts'],
          'dur': (event['ts'] as num) - (begin['ts'] as num),
        });
      }
    }
    final todoFrameLocations = <Map<String, Object?>>[];
    for (final event in todoEvents) {
      if (!['B', 'X'].contains(event['ph']) || event['ts'] is! num) {
        continue;
      }
      final timestamp = event['ts']! as num;
      final matchingFrames = frames.where((frame) {
        final start = frame['ts'] as num;
        final end = start + (frame['dur'] as num);
        return frame['pid'] == event['pid'] &&
            frame['tid'] == event['tid'] &&
            timestamp >= start &&
            timestamp <= end;
      }).length;
      todoFrameLocations.add({
        'name': event['name'],
        'timestampMicros': timestamp,
        'matchingFrameIntervals': matchingFrames,
        'outsideRecordedCompleteFrames': frames.isEmpty
            ? null
            : matchingFrames == 0,
      });
    }
    evidence.addAll({
      'timelineTimeOriginMicros': timeline['timeOriginMicros'],
      'timelineTimeExtentMicros': timeline['timeExtentMicros'],
      'totalEvents': events.length,
      'categoryCounts': categoryCounts,
      'todoEventCounts': todoCounts,
      'todoBeginOrCompleteEventCounts': todoStartCounts,
      'todoEvents': todoEvents,
      'completeFrameIntervalsConsidered': frames.length,
      'frameEventPhaseCounts': framePhaseCounts,
      'todoBeginFrameLocations': todoFrameLocations,
      'mostFrequentEventNames': [
        for (final entry in sortedNames.take(40))
          {'name': entry.key, 'count': entry.value},
      ],
      'status': 'success',
    });
    stdout.writeln(
      'Read-only timeline inspection completed: ${events.length} events; '
      'todo.add=${todoCounts['todo.add']}, '
      'todo.delete=${todoCounts['todo.delete']}.',
    );
    stdout.writeln('Recorded streams: ${flags['recordedStreams']}');
    resultCode = 0;
  } catch (error) {
    evidence['status'] = 'failed';
    evidence['errorType'] = error.runtimeType.toString();
    evidence['error'] = sanitize(error.toString());
    stderr.writeln(evidence['error']);
  } finally {
    await subscription?.cancel();
    await socket?.close();
    evidence['completedAtUtc'] = DateTime.now().toUtc().toIso8601String();
    await evidenceFile.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(evidence)}\n',
      flush: true,
    );
  }
  exit(resultCode);
}
