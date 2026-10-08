# 간단한 To Do 앱 구현 기준

목록·추가·삭제·완료 체크를 제공하는 단일 화면 앱이다. Riverpod으로 목록 상태를 관리하며 Windows 네이티브 환경에서 실행한다.

## 범위

- 단일 화면에 제목 입력, 추가 버튼, 할 일 목록을 표시한다.
- 각 항목에 제목, 완료 체크박스, 삭제 버튼을 둔다.
- 날짜·점수·장소·회고·통계·영구 저장은 포함하지 않는다.
- 앱 시작은 빈 목록이다. 종료·재시작하면 기록은 초기화된다.
- 전체 기능 버전은 별도 codex/full-planner 브랜치에 보관한다.

## 입력과 목록

제목은 앞뒤 공백을 제거한다. 빈 문자열과 공백뿐인 입력은 추가하지 않는다. 정상 추가하면 입력창을 비우고 목록에 새 항목을 표시한다. 버튼과 Enter가 같은 추가 동작을 사용한다.

같은 제목을 여러 번 입력해도 허용하며 ID로 구분한다. 생성 순서의 한 목록에 완료·미완료 항목을 함께 표시한다. 빈 목록에는 추가를 안내하는 문구를 표시한다.

## 완료와 삭제

체크박스를 누르면 isCompleted가 반전된다. 완료 상태를 시각적으로 구분하고 다시 누르면 미완료로 돌아간다. 완료한 항목을 자동 삭제하지 않는다.

삭제 버튼은 해당 ID 한 항목만 제거한다. 같은 제목의 다른 항목과 순서는 보존한다. 없는 ID의 삭제·완료 변경은 상태를 바꾸지 않는다.

## 상태와 책임

Todo는 불변 id/title/isCompleted 모델이다. NotifierProvider가 List<Todo>를 관리한다. addTodo는 bool, deleteTodo/toggleTodo는 void인 동기 메서드다. 기존 List와 Todo를 직접 수정하지 않고 새 객체로 상태를 교체한다.

화면은 입력 controller와 임시 입력을 소유하며 dispose로 정리한다. ref.watch로 목록을 구독하고 ref.read로 변경 요청을 보낸다. ID는 한 상태 수명에서 중복되지 않게 부여한다.

## 완료 조건

| 항목 | 확인할 결과 |
| --- | --- |
| 목록 | 추가한 제목과 완료 상태를 표시하고 빈 상태를 안내 |
| 추가 | 버튼/Enter 추가, trim, 빈 입력 거부, 같은 제목의 ID 구분 |
| 삭제 | 선택 ID만 삭제, 마지막 항목 삭제 후 빈 상태 |
| 완료 | 완료·미완료 양방향 전환과 다른 항목 보존 |
| Riverpod | ProviderScope/NotifierProvider/watch/read 및 불변 업데이트 |
| 초기화 | 앱 재시작에서 빈 목록으로 시작 |
| 코드 | 의존성 설치·분석·테스트·Windows release 빌드 |
| DevTools | debug Inspector 및 native profile Timeline/Memory/Performance |
| 제출 | 자체 코드, Readme.pdf, 기능5장·DevTools4장의 실제 증빙 |

간단 버전 1.1.0+3의 정적 분석과 14개 테스트(상태 6개·화면 8개), Windows release 빌드를 2026-10-08 13:40:11 KST에 확인했다. 기능 캡처 5장에서 목록 3개→추가 후 4개→삭제 후 3개와 첫 항목 완료 표시를 확인했다. 근거는 docs/evidence/simple_clean_build.json과 simple_feature_capture.json에 기록했다. DevTools 캡처 4장, 이 버전의 PDF와 제출 ZIP은 미완료 항목이다.
