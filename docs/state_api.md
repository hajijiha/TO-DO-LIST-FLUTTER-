# 간단 버전 상태 API

## 모델과 provider

```dart
const Todo({
  required int id,
  required String title,
  bool isCompleted = false,
});
```

Todo의 id/title/isCompleted는 final 필드다. `Todo copyWith({bool? isCompleted})`는 id/title을 유지하고 완료 상태를 지정한 새 Todo를 만든다.

`todoProvider`는 `NotifierProvider<TodoNotifier, List<Todo>>`이고 TodoNotifier는 `Notifier<List<Todo>>`를 확장한다. 초기 상태는 빈 const 목록이다. 이후 상태는 `List<Todo>.unmodifiable`로 만든다. 화면은 `ref.watch(todoProvider)`를 읽고 이벤트는 `ref.read(todoProvider.notifier)`로 호출한다.

## 변경 메서드

```dart
bool addTodo(String title);
void deleteTodo(int id);
void toggleTodo(int id);
```

| API | 계약 |
| --- | --- |
| addTodo | title.trim()이 비면 false이며 ID·목록을 소비/변경하지 않음 |
| addTodo | 정상 제목은 고유 ID·isCompleted=false로 끝에 추가하고 true |
| deleteTodo | 해당 ID만 제외한 새 목록으로 교체 |
| toggleTodo | 해당 ID의 isCompleted를 반전한 새 Todo·목록으로 교체 |
| 없는 ID | delete/toggle 모두 다른 항목을 바꾸지 않고 종료 |

제목이 같아도 ID가 다르면 서로 다른 항목이다. ID는 1부터 시작하고 정상 추가마다 증가한다. 삭제한 ID를 같은 상태 수명에서 재사용하지 않는다. 수정 전 List와 Todo 객체를 직접 변경하지 않는다. 성공한 변경에 todo.add/delete/toggle Timeline 표식을 남긴다.

## 화면 연결

입력이 성공할 때만 TextEditingController를 clear한다. 버튼과 TextField의 onSubmitted가 같은 추가 처리를 호출한다. 완료 체크박스는 toggleTodo, 삭제 버튼은 deleteTodo에 ID를 전달한다.

모든 API는 동기다. Future/await, AsyncValue, 저장소 및 JSON 계층을 사용하지 않는다. 파일·서버·SharedPreferences에 기록하지 않으며 앱 종료·재시작 또는 새 ProviderScope에서는 빈 목록과 ID 1부터 시작한다.

## 검증 범위

빈 입력/trim·중복 제목/ID·선택 삭제/마지막 삭제·완료 취소·기존 목록 보존을 상태 및 화면 테스트로 확인했다. 상태 6개·화면 8개, 총 14개 테스트와 정적 분석이 통과했다. Windows release 빌드 결과는 `docs/evidence/simple_final_validation.json`, 실제 종료·재실행 초기화 확인은 `simple_release_smoke.json`에 있다.
