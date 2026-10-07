# Today Todo v2 제출 점검표

마감: **2026-10-11 일요일 23:59 KST**. 내부 제출 준비 목표: **10월 11일 21:00**.

이 점검표는 확장 버전 **2.0.0+2** 기준이다. 체크한 항목은 확인한 근거가 있는 항목이며, 빈 체크는 아직 실제 완료 증빙을 반영하지 않은 항목이다. 기존 기본 앱의 테스트 9개·빌드·9장 캡처를 v2 통과 결과로 쓰지 않는다.

현재 상태: 최종 56개 테스트·깨끗한 소스 분석/빌드·배포 해시·실제 저장 복원·최초 실행 준비가 통과했다. 기능14장·DevTools4장 원본 검토와 release 실행·응답까지 확인했다. PDF31페이지 시각·여백 검사와 ZIP의 구성·CRC·해시·의존성 제외 검사가 통과했다. 문서 수정 후 재생성과 같은 검사를 반복하며 학생 확인·사이트 제출은 별도이다.

## 1. 구현과 제출 범위

| 구분 | 확인할 내용 | 근거 |
| --- | --- | --- |
| 정책 | 점수·평균·카테고리·장소 관찰·회고 | product_spec, README |
| 화면 | 입력·두 목록·달력·점수·장소·회고 | 소스·widget 테스트·실제 이미지 |
| 상태·저장 | 모델·Riverpod·계산·카탈로그·회고 | 계산/저장 테스트·종료/재시작 로그 |
| 배포·제출 | 플랫폼·실행·DevTools·PDF·압축 | 최종 로그·전체 증빙·PDF·ZIP |

- [x] 공식 정책을 docs/product_spec.md에 기록했다.
- [x] 승인한 점수합/시간 가중 점수합 방식과 날짜별 기준 유지 정책을 문서에 반영했다.
- [x] README 앞쪽에 앱 실행.cmd 더블클릭·Release 폴더 위치·빌드 명령을 안내했다.
- [x] UI·모델·provider API를 소스에서 대조하여 이름·자료형·비동기 흐름을 README에 반영했다.
- [x] 구현 소스와 캡처 보조 도구를 통합하고 전체 56개 테스트·네이티브 기능·profile 관찰을 검증했다.

## 2. 일정

| 날짜 | 완료 목표 |
| --- | --- |
| 10/7 수 | 점수·카테고리·장소 관찰·목록 분리·회고 통합 |
| 10/8 목 | 계산·저장·위젯·네이티브 핵심 검증 |
| 10/9 금 | 기본·확장·추가 기능·DevTools 실제 증빙 |
| 10/10 토 | PDF 렌더링·제출 코드 복사본 빌드·ZIP 검토 |
| 10/11 일 | 최종 누락 확인·사이트 제출 |

완료 시각은 실제 로그 기준으로 기록한다. 계획 날짜가 지났다는 이유로 완료 처리하지 않는다.

## 3. 환경과 빌드

### 이미 확인한 도구 환경

- [x] Flutter 3.47.6, Dart 3.13.5, DevTools 2.60.0 확인.
- [x] Windows 10.0.26200.9457, locale ko-KR 확인.
- [x] Visual Studio Build Tools 2022 17.14.41, Windows SDK 10.0.26100.0 정상 설치 확인.
- [x] Windows x64 장치 확인.
- [x] lockfile에서 Riverpod 3.4.3, shared_preferences 2.5.6 확인.
- [x] 로컬 SDK·캐시는 .tooling/에 두고 제출 제외·일반 SDK 명령을 안내했다.

Android는 SDK 미설치로 미검증이다. Windows가 제출 검증 대상이다.

### v2 최종 소스 검사

- [x] flutter pub get 성공, docs/evidence/v2_pub_get.txt 확인.
- [x] README에 dart format lib test test_driver scripts 검사 명령을 안내했다.
- [x] 현재 v2_flutter_analyze.txt의 No issues found!, 22.8초를 확인했다.
- [x] 카테고리·장소 관찰·회고를 포함한 깨끗한 복사본 analyze 16.5초와 최종 보조 도구 검사 18.1초의 문제 없음을 확인했다.
- [x] 최종 widget 20개 통과. 장소·두 목록·회고·날짜 경계·저장 실패와 좁은 화면 포함.
- [x] 최종 전체 56개 통과, 26.0초. 상태·모델·저장 36개 + 화면 20개.
- [x] 최종 추가 기능이 포함된 전체 검사 결과를 v2_flutter_test.txt에서 확인했다.
- [x] 최종 캡처 진입점의 Windows debug 빌드 21.4초·실행·주요 기능과 점수를 확인했다.
- [x] 일반 lib/main.dart의 최종 release 실행을 확인했다. release_launch_v2.json.
- [x] Windows profile 빌드 94.3초·실행과 현재 실행의 VM Service 연결을 확인했다.
- [x] 일반 lib/main.dart release 빌드 성공. 깨끗한 복사본에서 111.5초·exit 0.
- [x] 14:12:24 KST에 최종 release를 시작하고 14:12:40에 Today Todo - Daily Planner 창과 응답 true를 확인했다.
- [x] 앱 실행.cmd의 우선 실행 경로를 소스에서 확인하고 그 배포 exe의 실제 시작을 검증했다. 더블클릭 동작 자체는 별도 수동 검증으로 주장하지 않는다.
- [x] output/windows/Release/에 exe·DLL·data 11개 파일을 복사하고 원본과 SHA256 일치를 확인했다.
- [x] output/windows/Release/today_todo.exe의 최종 실행을 확인했다.
- [x] 수동 Windows 명령에 pub get → prepare_windows_plugins.ps1 → run/build --no-pub 순서를 안내했다.
- [x] run_app.ps1의 최초 symlink 실패→junction 준비→한 번 재시도 경로를 새 폴더에서 검증했다. 12.175초·exit 0.
- [x] v2_first_run_check.json의 launcherMatchesCurrentSource true, 오류 처리 설정 복원을 확인했다. 검증 범위는 의존성 준비 구간.

## 4. 기본 기능과 확장 동작

- [x] 선택 날짜의 목록에 제목·장소·예상시간·완료 상태를 표시한다.
- [x] 제목·장소·분·날짜를 지정하여 추가한다.
- [x] 빈 제목 거부·trim·빈 장소 미지정·시간 1~1,440분을 확인한다.
- [x] 고유 ID 기준으로 원하는 항목만 삭제한다. 같은 제목 여러 개도 구분한다.
- [x] 마지막 항목 삭제·빈 날짜 표시를 확인한다.
- [x] 제목·장소·시간·날짜 수정이 해당 날짜 목록에 반영된다.
- [x] 체크박스로 0~10 정수 평점을 입력하여 완료한다.
- [x] 0점은 완료, null은 미완료로 처리한다.
- [x] 완료 점수 수정과 완료 취소가 통계에 반영된다.
- [x] 날짜 경계·윤년·월 이동을 자동 검사하고 선택 날짜·과거 기록을 네이티브 이미지에서 확인했다.
- [x] 좁은 화면·긴 입력·대화상자를 widget 테스트에서 검사했고 최종 촬영 원본의 목적 대상 잘림이 없음을 확인했다.
- [x] 로딩·읽기 오류·저장 실패 안내와 저장 중 중복 입력 제어를 확인한다.

## 5. 점수·목표 정책

공식: **(min(10, 점수 합 / 기준 개수) + min(10, 점수×예상시간 합 / 기준 분)) / 2**.

- [x] 품질 평균과 하루 활동 점수를 다른 지표로 표시한다.
- [x] 완료가 없을 때 품질 평균 없음·하루 점수 0을 구분한다.
- [x] 세 개의 30분·8점 완료에서 활동 점수 8, 두 개 완료에서 약 5.33 설계 산술 검산. 실제 앱 테스트 결과와 구분.
- [x] 낮은 점수·짧은 완료 항목 삭제 및 완료 취소 후 활동 점수가 상승하지 않는다.
- [x] 0점 기여 제거·상한 적용 시 점수가 같을 수 있음을 공식의 비음수 기여와 상한 규칙으로 확인하여 설명했다.
- [x] 각 요소와 최종 결과는 0~10이다.
- [x] 날짜별 기준은 사용자 목표·계획 최고량을 유지한다.
- [x] 미완료 삭제·완료 삭제·시간 감소·날짜 이동으로 기존 기준이 내려가지 않는다.
- [x] 전역 목표 변경은 새로운 날짜부터 적용되고 기존 기준·목표는 유지된다.
- [x] 날짜 첫 계획은 이전 기록이 없으면 목표 7점이다.
- [x] 이전 최대 14개 기록 날짜 평균 + 0.5, 상한 10을 검증한다.
- [x] 미래 날짜·빈 날짜 제외, 계획만 있거나 전체 삭제한 날짜 0점 포함.
- [x] 목표 생성 시 대상 날짜 자체를 제외하고 기존 목표를 다시 계산하지 않는다.
- [x] 실제 완료 점수·분으로 약 3.6806을 계산하고 화면의 3.7 표시·품질 평균8.5와 대조했다. 목표·달성 안내는 widget 검사에서 확인했다.
- [x] 예상시간을 실제 집중시간으로, 개인 평점을 객관적 성과로 설명하지 않는다.

## 6. Riverpod과 로컬 저장

### 소스에서 확인한 구조

- [x] ProviderScope가 앱을 감싼다.
- [x] AsyncNotifierProvider<TodoNotifier, PlannerState>를 선언한다.
- [x] PlannerState는 읽기 전용 List·Map, 날짜별 DayPlan·목표·nextId를 보관한다.
- [x] SharedPreferencesAsync에서 version 2 JSON을 읽고 저장한다.
- [x] 저장 성공 후 AsyncData(next)를 공개하고 변경 요청을 순서대로 처리한다.
- [x] README에 모델·자료구조·watch/read·비동기 API와 저장 흐름을 설명했다.
- [x] CustomScrollView·달력·요약·항목·대화상자·AsyncValue.when 구조를 소스에서 확인하여 문서에 반영했다.

### 자동·실제 저장 검증

- [x] 화면 watch/read·loading/data/error 연결과 버튼 동작을 통합 검증했다.
- [x] JSON 왕복 후 항목·점수·날짜·기준량·목표·nextId 보존.
- [x] 잘못된 JSON·버전·자료형·중복 ID·잘못된 날짜를 거부한다.
- [x] 저장 실패 시 성공 상태를 공개하지 않고 후속 요청 처리가 가능하다.
- [x] 동시 변경 요청이 순서대로 보존된다.
- [x] native SharedPreferences 별도 검증 키에 항목·카테고리·장소·회고를 실제 입력했다. persistence_create.json status passed.
- [x] 앱 프로세스를 완전히 종료한 뒤 같은 검증 키로 새 프로세스를 실행했다.
- [x] 같은 날짜의 항목·공부/도서관·45분·9점·하루3.8·평균9.0·회고를 복원했다.
- [x] create 13:39:04 KST/read 13:56:16 KST, 모두 passed를 README에 반영했다.
- [x] 실제 저장 복원 로그 persistence_read.json과 읽기 검증 exit 0을 확인했다.

촬영용 과거 3일 샘플은 MemoryTodoRepository를 사용한다. 이 샘플 화면을 실제 사용자 기록의 디스크 저장 증거로 설명하지 않는다.

### 추가 범위: 카테고리·장소·두 목록·회고

- [x] Todo.category, placeCatalog, DayReflection·reflections, PlaceStats와 saveReflection API를 소스에서 확인하여 문서에 반영했다.
- [x] 자동 테스트에서 공부·운동·사용자 카테고리와 장소 등록·자동완성을 확인했다.
- [x] 같은 카테고리·장소 반복 입력의 중복 방지·공백 정규화를 확인했다.
- [x] 카테고리를 바꿀 때 해당 카테고리의 장소 후보만 표시한다.
- [x] 항목 삭제 후 카탈로그는 유지되며 미지정을 후보로 등록하지 않는다.
- [x] 장소 관찰의 분모는 오늘까지 현재 보관 항목 전체이며 미완료를 포함하고 미래를 제외한다.
- [x] 8점 이상 완료만 성공으로 세고 0~7점 완료는 성공에 포함하지 않는다.
- [x] 성공 수/n·완료 평균·완료 예상분·표본 없음 표시를 검증했다.
- [x] 같은 이름의 장소라도 카테고리가 다르면 따로 관찰한다.
- [x] 관찰 성공률을 예측 확률로 표현하지 않고 작은 표본의 확실한 우열을 주장하지 않는다.
- [x] 미완료는 해야 할 일, 0~10점 완료는 실제로 한 일에만 표시한다.
- [x] 완료/취소 시 두 목록 사이 이동·날짜별 필터를 검증했다.
- [x] 자동 테스트와 native create에서 회고 입력·저장·현재 실행 내 다시 조회를 확인했다.
- [x] 세 회고 칸을 비워 저장하면 회고만 제거하며 계획·점수 기준은 유지한다.
- [x] 회고만 있는 날에 메모 아이콘을 표시하고 DayPlan·0점 기록·활동 평균을 생성하지 않는다.
- [x] 회고 저장 실패에서 입력을 보존하고 저장 성공으로 알리지 않는다.
- [x] 실제 재시작에서 이번 표본의 공부/도서관·완료 항목·회고 세 필드·관측률100%(1/1)를 복원했다.
- [x] 장소 자동완성·관찰67%(2/3)/평균7.7·회고 세 필드·두 목록 해야1/완료2의 실제 캡처를 저장하고 README에 반영했다.


## 7. 앱 스크린샷 14장

| 파일 | 증빙 |
| --- | --- |
| 01_list.png | 확장 정보가 보이는 목록 |
| 02_add_input.png | 제목·장소·시간 입력 |
| 03_add_result.png | 추가 결과 |
| 04_delete_before.png | 삭제 전 항목·개수 |
| 05_delete_after.png | 해당 항목 삭제 후 |
| 10_rating_dialog.png | 수행점수 입력 |
| 11_daily_score.png | 품질 평균·하루 점수·기준 달성률 |
| 12_calendar_history.png | 과거 날짜 기록·점수 |
| 13_edit_dialog.png | 장소·시간·날짜 수정 |
| 14_goal_settings.png | 개수·시간 목표 설정 |
| 15_place_catalog.png | 카테고리별 장소 자동완성 |
| 16_place_stats.png | 장소 관측 성공률67%(2/3)·평균7.7·표본 안내 |
| 17_day_reflection.png | 날짜별 회고 세 필드 |
| 18_separate_lists.png | 해야 할 일1개·실제로 한 일2개 |

- [x] 추가 세 기능 전 실제 v2 화면 10장을 저장하고 03/04도 재촬영했다.
- [x] 최종 추가 기능의 화면으로 기존 10장을 갱신하고 추가 4장을 저장했다.
- [x] 기존 5장·확장 5장의 개수·점수가 feature_capture_v2.json과 일치한다.
- [x] 최종 14장과 feature_capture_v2.json의 변경 값·시간이 일치한다. 14:02:45 KST 완료.
- [x] feature_capture_v2.json의 status completed와 실제 동작·점수 값을 확인했다.
- [x] 기능 14장의 전체 원본 시각 검토를 통과했다. 대상 잘림·stale frame·재촬영 필요 없음.
- [x] README에 3→4→3 개수 변화·ID 11 삭제·기준 4개/135분 유지·평균 8.5/활동 3.7과 샘플 설명을 반영했다.
- [x] 최종 기능 원본 14장을 최신 앱 화면으로 교체했다.
- [x] PDF에 기능14/DevTools4의 최신 원본18장을 포함했다.

추가 최종 캡처: 15_place_catalog.png, 16_place_stats.png, 17_day_reflection.png, 18_separate_lists.png. 장소 후보·관측 성공률과 표본·회고·두 목록을 담아 기능 14장과 DevTools 4장, 전체 18장을 구성한다.

## 8. DevTools 4장

| 파일 | 모드·증빙 |
| --- | --- |
| 06_devtools_inspector.jpg | Windows debug 위젯 트리·선택 속성 |
| 07_devtools_timeline.jpg | Windows profile 이벤트·선택 구간 |
| 08_devtools_memory.jpg | Windows profile 힙 그래프·클래스 수 |
| 09_devtools_performance.jpg | Windows profile 프레임 차트·상세 |

동일 stem의 png도 PDF 도구가 지원한다. 원본 확장자를 유지하고 실제 저장 파일에 README를 맞춘다.

- [x] 최종 Windows debug 앱에 현재 VM Service로 연결했다.
- [x] Inspector 원본에서 ProviderScope → TodayTodoApp 트리와 width1165.3/height722.7을 확인했다.
- [x] 06_devtools_inspector.jpg를 최종 앱에서 저장하고 원본을 검토했다.
- [x] profile에서 20개 추가·10개 삭제·10개 잔존, 115회 화면/스크롤 요청과 24,971ms를 기록했다.
- [x] Timeline의 todo.delete 검색1/10·Dart span25µs를 저장 후 동기 상태 공개 구간으로 설명했다.
- [x] 원시 Ring32,398개 중 add12개 레코드/6개 span·delete20개 레코드/10개 span을 구분했다. 추가 전체 횟수는 별도 UI workload 근거를 사용했다.
- [x] Timeline 표식을 디스크 저장·삭제·렌더 전체 시간으로 해석하지 않는다.
- [x] Memory 캡처14:11:29 KST, 수동 GC·Refresh 후 Todo10/TodoTile10·힙16.7MB(17,476,352B)를 기록했다. GC 전20/49·30.3MB는 보조 관찰로 구분했다.
- [x] Frame942의 UI0.7ms·raster tooltip8.0ms/phase8.1ms·Paint0.1ms와 144Hz 기준 Raster Jank 표시를 기록했다.
- [x] 특정 프레임을 전체 평균으로, 한 시점 메모리 관찰을 누수 없음으로 일반화하지 않는다.
- [x] 드라이버의 검증용 warm-up frame과 표시 평균106FPS의 해석 한계를 기록했다.
- [x] 제출 이미지 원본의 목적 정보·수치를 확인했고 토큰이나 개인 경로를 본문 관찰값으로 쓰지 않았다.
- [x] DevTools 4장과 기능 14장, 총 18장의 최종 원본 시각 검토를 통과했다.
- [x] devtools_observations.json과 README의 실제 값·시각·모드·해석이 일치한다.

## 9. PDF와 코드 패키지

포함: 자체 lib/test/test_driver/scripts/docs, pubspec.yaml·lock, analysis_options.yaml, .metadata·.gitignore, 필요한 플랫폼 runner·빌드 설정, 앱 실행.cmd, Readme.pdf.

제외: .tooling 전체, SDK·패키지 캐시·다운로드된 의존성 소스, build·.dart_tool·ephemeral·Gradle 캐시, .git·개인 IDE 설정·임시 생성물. 자체 Windows runner 설정은 포함한다.

- [x] README가 최종 v2 코드·56개 테스트·환경·실측·실제18장 파일명과 일치한다.
- [x] Python PDF 도구로 output/pdf/Readme.pdf를 생성했다. 본문13페이지+부록18페이지=31페이지.
- [x] PDF 전 페이지를 렌더링하여 한글·명령·표·코드·footer·18장 캡처·여백 검사를 통과했다.
- [x] PDF가 장소·시간·완료점수·달력·저장·정책·보너스를 설명한다.
- [x] package_submission.ps1로 코드·PDF를 압축하고 파일 구성을 검사했다. 문서 수정 후 같은 검사로 다시 생성한다.
- [x] ZIP에 .tooling·의존성 소스·생성 캐시·빌드 결과·이전 제출물이 없다.
- [x] ZIP에 숨김 .metadata·필수 파일·최종18장 이미지·Readme.pdf가 있다.
- [x] 깨끗한 소스 복사본에서 pub get 성공·analyze 16.5초 문제 없음·test 56개 통과(리포터 28초)를 확인했다.
- [x] 그 복사본의 Windows release 빌드 111.5초·exit 0을 확인했다.
- [x] 최종 앱 코드가 현재 소스와 일치한다. v2_clean_build.json의 coreMatchesCurrentSource true.
- [x] ZIP의 보조 도구·문서를 포함한 작업공간/복사본/압축 payload 일치를 확인했다.
- [x] ZIP의 필수 구성·CRC와 검증한 소스71개의 해시 일치를 확인했다. package_check_v2.json.
- [x] docs/evidence/validation_v2.json의14:15:09 KST 최종 앱·검사·네이티브·18장 상태를 확인했다. PDF·ZIP 최종 검토는 별도 항목이다.
- [x] clean_submission_paths.py로 숫자·결과는 유지하고 증빙의 프로젝트 경로를 상대경로로 정리했다.
- [x] 제출 증빙은 v2·현재 기능/profile/Memory/Timeline/저장/패키지 기록으로 선별했다.

갱신 순서: 실제 캡처·검증 → README와 점검표 → update_readme.ps1 → PDF 시각 검토 → package_submission.ps1 → ZIP·깨끗한 복사본 검증.

## 10. 실제 제출

- [x] 문서 파일명 Readme.pdf와 today_todo_생성시각.zip 형식을 확인했다.
- [ ] 학생이 제출 ZIP·Readme.pdf·필수 증빙을 확인했다.
- [ ] 마감 전에 사이트에 업로드하고 제출 완료 상태를 확인했다.

현재 최종 제출 준비 상태: **앱·56개 테스트·저장 복원·빌드·배포 실행·전체18장 원본 검토·PDF31페이지·ZIP구성/CRC/해시 검사 완료**. 이후 문서 수정판도 재생성하여 동일 기준으로 확인한다. 학생 직접 확인·사이트 업로드는 아직 완료 처리하지 않는다.
