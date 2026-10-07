# Planner 상태 API 계약

`todoProvider`는 `AsyncNotifierProvider<TodoNotifier, PlannerState>`입니다. 화면은 `AsyncValue<PlannerState>`의 loading/error/data를 처리하며, 변경은 notifier의 비동기 메서드를 await합니다. 저장 실패는 기존 data를 유지하고 예외를 전파합니다.

## 모델과 날짜

- `lib/models/todo.dart`: `Todo({required int id, required String title, required String location, required int estimatedMinutes, required DateTime date, String category = '기타', int? score})`. 모든 필드는 불변입니다. `score == null`은 미완료, 0~10은 완료입니다. `isCompleted`, `copyWith(..., bool clearScore = false)`, `toJson()`, `Todo.fromJson(Map<String, dynamic>)`를 제공합니다.
- `lib/models/calendar.dart`: `normalizeDate(DateTime)`, `dateKey(DateTime)` → `YYYY-MM-DD`, `dateFromKey(String)`를 공용으로 사용합니다. 지원 연도는 1~9999입니다.
- `lib/models/planner_state.dart`: `PlannerState({List<Todo> tasks = const [], Map<String, DayPlan> plans = const {}, Map<String, List<String>> placeCatalog = const {}, Map<String, DayReflection> reflections = const {}, int dailyCountGoal = 3, int dailyMinutesGoal = 90, int? nextId})`. tasks/plans/catalog/reflections와 catalog 내부 리스트는 변경 불가입니다. `nextId`는 삭제·재로드 뒤 ID 재사용을 방지하는 저장 메타데이터입니다. `copyWith`, `toJson`, `fromJson`을 제공합니다.
- `lib/models/day_plan.dart`: `DayPlan({required int requiredCount, required int requiredMinutes, required double targetScore})`와 JSON 변환.
- `lib/models/planner_stats.dart`: `DayStats`, `HistoryStats`.
- `lib/models/place_stats.dart`: `PlaceStats`, `normalizeCategory(String)`, `normalizeLocation(String)`.
- `lib/models/day_reflection.dart`: `DayReflection({required String good, required String needsWork, required String improve})`. 각 문자열을 trim하며 `isEmpty`, JSON 변환을 제공합니다.

## 화면이 호출하는 변경 메서드

```dart
Future<bool> addTodo(String title, {
  String location = '미지정',
  String category = '기타',
  int estimatedMinutes = 30,
  DateTime? date,
});
Future<bool> editTodo(int id, {
  required String title,
  required String location,
  required int estimatedMinutes,
  required DateTime date,
  String? category,
});
Future<void> deleteTodo(int id);
Future<void> rateTodo(int id, int score);
Future<void> reopenTodo(int id);
Future<void> updateGoals({required int count, required int minutes});
Future<void> saveReflection(DateTime date, {
  required String good,
  required String needsWork,
  required String improve,
});
```

빈 trim 제목은 false를 반환하고 저장하지 않습니다. 정상 추가/수정은 저장 후 true를 반환합니다. 다른 검증 실패는 `ArgumentError`를 전파합니다. 위치의 빈 입력은 `미지정`으로 정규화합니다. 예상 시간 1~1440분, 일일 목표 개수 1~1000개, 일일 목표 시간 1~1440분, 점수 0~10을 검증합니다. 없는 ID의 수정은 false, 삭제/평가/미완료 전환은 변경 없이 종료합니다.

카테고리/장소는 앞뒤 공백을 지우고 연속 공백을 하나로 합칩니다. 빈 카테고리는 `기타`입니다. 수정 메서드의 category를 생략하면 기존 카테고리를 유지합니다. 추가/수정 시 사용자 카테고리와 입력 장소를 catalog에 저장하며, 할 일을 삭제하거나 장소를 바꿔도 이전 catalog는 유지합니다. `미지정` 장소는 catalog에 넣지 않습니다.

`saveReflection`은 날짜별 잘한 점(good), 못한 점(needsWork), 개선할 점(improve)을 명시 저장합니다. 세 입력이 모두 빈값이면 해당 메모를 삭제합니다. `state.reflectionFor(DateTime)`은 저장된 `DayReflection?`를 반환합니다. 피드백만 저장한 날짜에는 DayPlan을 생성하지 않아 0점 기록이 최근 평균에 섞이지 않습니다.

## 카테고리와 장소 실적

`state.categories`는 `기타`를 포함한 정렬된 불변 `List<String>`이며, `state.locationsFor(String category)`는 해당 카테고리의 불변 장소 목록입니다. 새 카테고리/장소는 사용자 입력으로 생기고 재시작 후에도 유지됩니다.

`state.placeStats({String? category, DateTime? reference})`는 카테고리/장소 순으로 정렬한 불변 `List<PlaceStats>`입니다. reference의 기본값은 오늘이며 reference 이후 및 실제 오늘 이후 할 일을 분석에서 제외합니다. catalog에만 남은 장소는 n=0으로 표시합니다. 실제 `미지정` 할 일은 통계 그룹에 포함하지만 자동완성 목록에는 넣지 않습니다.

필드는 `String category/location`, `int plannedCount/completedCount/successCount/completedMinutes`, `double? qualityAverage/successRate`입니다. `qualityAverage`는 완료된 할 일의 0~10점 산술평균, `successCount`는 8점 이상 완료 수, `successRate`는 `successCount / plannedCount`(0~1)입니다. 미완료와 0점 완료도 전체 n에 포함합니다. n=0이면 성공률은 null, 완료가 없으면 평균도 null입니다. 이 비율은 현재 남아 있는 실제 할 일 기록의 실적이며 미래 성공을 예측하는 확률이 아닙니다. 삭제한 할 일은 n에서 제외되므로 UI는 항상 표본 수를 함께 보여야 합니다.

## 통계

`state.statsFor(DateTime date)`는 다음 필드의 `DayStats`를 반환합니다.

`date`, `tasks`, `hasRecord`, `plannedCount`, `plannedMinutes`, `completedCount`, `completedMinutes`, `qualityAverage`(nullable), `quantityFactor`, `timeFactor`, `countScore`, `timeScore`, `dailyScore`, `targetScore`, `requiredCount`, `requiredMinutes`.

`qualityAverage`는 해당 일자의 완료 항목 점수 평균입니다. 수량 달성률은 `min(1, completedCount / requiredCount)`, 시간 달성률은 `min(1, completedMinutes / requiredMinutes)`입니다. 점수는 `countScore = min(10, 완료 점수 합 / requiredCount)`, `timeScore = min(10, 완료 점수×예상분 합 / requiredMinutes)`, `dailyScore = (countScore + timeScore) / 2`입니다. 미완료 항목은 합계에 0으로 기여합니다. 낮은 점수 항목을 삭제하거나 재열어 평균이 올라가더라도 일일 점수는 올라가지 않습니다.

`state.historyStats(DateTime reference, {bool includeReference = true, int limit = 14})`는 `HistoryStats`를 반환합니다. 필드는 `days`(최신순 `List<DayStats>`), `averageScore`(nullable), `averageCompletedCount`, `averageCompletedMinutes`, `nextTarget`입니다. reference 이후 날짜와 실제 오늘 이후 날짜는 제외하고 기록일 최신 14개를 사용합니다. 할 일을 모두 삭제한 계획 기록일도 0점으로 포함합니다. 기록이 없으면 nextTarget은 7.0이며, 있으면 `min(10, averageScore + 0.5)`입니다.

DayPlan은 해당 날짜의 첫 추가 때 기본 목표와 계획 수량/시간 중 큰 값으로 생성합니다. targetScore는 해당 날짜 이전의 최신 기록일 통계에서 구한 nextTarget으로 스냅샷을 저장합니다(실제 오늘 이후의 기록은 제외). 새 항목 또는 계획량이 증가하는 수정은 분모를 올립니다. 삭제·시간 축소·다른 날로 이동은 기존 날짜 분모를 낮추지 않습니다. `updateGoals`는 이후 새 기록일에 적용되고 기존 계획/목표 점수 스냅샷은 유지합니다. 수정은 기존 score를 유지합니다.

## 저장·테스트

`lib/repositories/todo_repository.dart`에서 `TodoRepository.load(): Future<PlannerState>`, `save(PlannerState): Future<void>`를 제공합니다. `SharedPreferencesTodoRepository({String storageKey = 'today_todo_planner_v2', SharedPreferencesAsync? preferences})`는 `SharedPreferencesAsync`를 사용합니다. storageKey 주입으로 네이티브 저장·재시작 검증 자료를 실제 사용자 저장소와 분리합니다. 저장 자료가 없을 때만 빈 상태로 시작하고, 손상/타입 오류는 예외를 전파합니다. 초기 로드 오류는 자동 재시도로 감추지 않고 AsyncError로 노출합니다.

`MemoryTodoRepository({PlannerState? seed, String? initialJson})`는 테스트와 촬영용 메모리 저장소입니다. `todoRepositoryProvider.overrideWithValue(MemoryTodoRepository(seed: ...))`로 대체하여 실제 사용자의 저장소를 변경하지 않습니다. seed는 누락 DayPlan을 기본 목표와 현재 계획량을 기준으로 생성합니다(초기 targetScore 7.0). initialJson은 손상 저장소 테스트용이며 seed와 함께 지정할 수 없습니다. 모든 변경은 직렬 큐에서 최신 상태를 기준으로 계산하고 저장이 성공한 후 화면에 반영합니다.

저장 버전/key는 v2를 유지합니다. 기존 v2 JSON에 category가 없으면 `기타`, placeCatalog가 없으면 기존 tasks의 카테고리/장소로 생성, reflections가 없으면 빈 Map으로 읽어 호환합니다. 필드가 있으나 타입이 손상된 자료는 오류로 노출합니다. 피드백·catalog·점수는 동일한 직렬 저장 경로를 사용하며 저장 실패 때 기존 상태가 유지됩니다.
