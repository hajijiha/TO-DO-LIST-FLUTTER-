import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/model_json.dart';
import '../models/planner_state.dart';

abstract class TodoRepository {
  Future<PlannerState> load();
  Future<void> save(PlannerState state);
}

class SharedPreferencesTodoRepository implements TodoRepository {
  SharedPreferencesTodoRepository({
    SharedPreferencesAsync? preferences,
    this.storageKey = defaultStorageKey,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  static const defaultStorageKey = 'today_todo_planner_v2';
  final String storageKey;
  final SharedPreferencesAsync _preferences;

  @override
  Future<PlannerState> load() async {
    final value = await _preferences.getString(storageKey);
    return _decode(value);
  }

  @override
  Future<void> save(PlannerState state) =>
      _preferences.setString(storageKey, jsonEncode(state.toJson()));
}

class MemoryTodoRepository implements TodoRepository {
  MemoryTodoRepository({PlannerState? seed, String? initialJson}) {
    if (seed != null && initialJson != null) {
      throw ArgumentError('Specify either seed or initialJson.');
    }
    _json = initialJson ?? (seed == null ? null : jsonEncode(seed.toJson()));
  }

  String? _json;

  @override
  Future<PlannerState> load() async => _decode(_json);

  @override
  Future<void> save(PlannerState state) async {
    _json = jsonEncode(state.toJson());
  }
}

PlannerState _decode(String? json) => json == null
    ? PlannerState()
    : PlannerState.fromJson(jsonMap(jsonDecode(json)));
