# 간단 버전 제출 점검표

마감: **2026-10-11 일요일 23:59 KST**.

대상 버전: `1.1.0+3`. 정적 분석, 테스트 14개, Windows release 빌드와 기능 화면 5장을 확인했다.
네이티브 DevTools 4장과 일반 release 실행·초기화를 확인했다. PDF 12쪽과 자체 코드 ZIP의 CRC·필수 파일·소스 해시·의존성 제외를 검증했다.

## 범위와 문서

- [x] 목록·추가·삭제·완료 체크와 Riverpod 메모리 상태를 최종 범위로 정의했다.
- [x] 영구 저장이 없고 앱 재시작 시 초기화됨을 README에 명시했다.
- [x] 표준 Flutter 실행·빌드·profile 명령과 실행 순서를 작성했다.
- [x] 위젯 배치와 화면 요소를 대응시키고 상태 변경·DevTools 연결 흐름을 도식으로 설명했다.
- [x] Riverpod과 native DevTools 두 보너스 항목의 적용 내용을 명시했다.
- [x] Todo/copyWith, 동기 provider API, TodoScreen/TodoTile 구조를 문서화했다.
- [x] 제출 코드·캡처·로그가 목록·추가·삭제·완료 체크 앱과 일치한다.

## 기본·완료 기능

- [x] 빈 목록에 입력 안내가 보인다.
- [x] 버튼과 Enter로 제목을 추가하고 정상 추가 시 입력창이 비워진다.
- [x] 공백뿐인 제목은 거부하고 앞뒤 공백은 정리한다.
- [x] 같은 제목의 두 항목을 서로 다른 ID로 구분한다.
- [x] 해당 ID만 삭제하며 마지막 항목 삭제 후 빈 상태가 보인다.
- [x] 완료·완료 취소가 표시되고 다른 항목에 영향을 주지 않는다.
- [x] 일반 release 앱에서 입력·Enter 추가 후 종료·재실행 시 빈 목록으로 돌아감을 확인했다.

## Riverpod과 소스

- [x] ProviderScope가 앱을 감싼다.
- [x] NotifierProvider<TodoNotifier,List<Todo>>와 불변 Todo를 사용한다.
- [x] addTodo(String):bool/deleteTodo(int)/toggleTodo(int) API가 계약과 일치한다.
- [x] 새 목록·객체로 state를 교체하고 기존 객체를 직접 수정하지 않는다.
- [x] 화면 watch/read 연결과 TextEditingController/FocusNode.dispose를 확인했다.

## 빌드 및 실행 검증

- [x] flutter pub get 성공.
- [x] flutter analyze에서 No issues found를 확인했다.
- [x] 간단 버전 상태 6개·화면 8개, 총 14개 테스트 통과 수와 범위를 기록했다.
- [x] Windows debug 앱의 실제 기능을 확인했다.
- [x] Windows profile 앱 실행과 현재 VM Service 연결을 확인했다.
- [x] 일반 main.dart의 Windows release 빌드와 실행·입력·재시작 초기화를 확인했다.
- [x] 깨끗한 소스 복사본의 분석·14개 테스트·Windows release 빌드를 확인했다.
- [x] 실제 결과를 docs/evidence에 저장하고 README의 새 결과로 갱신했다.

## 촬영 9장

| 파일: docs/screenshots/ | 내용 |
| --- | --- |
| 01_list.png | 목록과 완료 체크 |
| 02_add_input.png | 새 제목 입력 |
| 03_add_result.png | 추가 후 목록 |
| 04_delete_before.png | 삭제 대상과 이전 목록 |
| 05_delete_after.png | 해당 항목 삭제 후 |
| 06_devtools_inspector.jpg | debug 위젯 트리·선택 속성 |
| 07_devtools_timeline.jpg | native profile Timeline Events |
| 08_devtools_memory.jpg | native profile 메모리·클래스 |
| 09_devtools_performance.jpg | native profile 프레임 상세 |

- [x] 동일 간단 버전에서 목록·추가 전후·삭제 전후 5장을 촬영했다. 목록은 3개→4개→3개로 변경됐다.
- [x] 첫 항목의 완료 체크 표시를 실제 화면에서 확인했다. 완료 취소 동작은 화면 테스트로 확인했다.
- [x] Inspector를 debug 네이티브 앱에서 촬영했다.
- [x] Timeline/Memory/Performance를 profile 네이티브 앱에서 촬영했다.
- [x] DevTools 실제 이벤트·프레임·시간·GC·클래스 수를 기록했다.
- [x] 특정 프레임·짧은 메모리 관찰의 해석 한계를 설명했다.
- [x] 최종9장 원본의 내용·가독성·잘림을 시각 검토했다.

## PDF와 자체 코드 ZIP

- [x] 간단 버전 README와 최종9장으로 output/pdf/Readme.pdf를 생성했다.
- [x] PDF 12쪽을 렌더링해 한글·명령·표·위젯/상태 설명·보너스·실제 캡처를 검토했다.
- [x] 기능·DevTools 설명과 해당 이미지가 같은 페이지에 있으며 추가·삭제 전후는 나란히 배치됐다.
- [x] 자체 소스·테스트·보조 도구·필수 플랫폼 설정·의존성 선언·PDF를 포함했다.
- [x] SDK·의존성 소스·캐시·빌드·Git·개인 설정을 제외했다.
- [x] ZIP 필수 파일·숨김 .metadata·CRC·소스 해시를 확인했다.

## 실제 제출

- [x] 제출 ZIP·Readme.pdf·스크린샷의 내용을 확인했다.
- [ ] 마감 전에 과제 사이트에 업로드하고 제출 완료 상태를 확인했다.

검증 근거: docs/evidence/simple_final_validation.json, simple_feature_capture.json, simple_release_smoke.json, profile_workload.json, devtools_observations.json.
