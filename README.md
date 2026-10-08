# Today Todo — 간단한 할 일 앱

Flutter와 Riverpod으로 만든 Windows 네이티브 To Do 앱입니다. **목록·추가·삭제·완료 체크**를 제공하며, 할 일은 메모리에 보관합니다. **앱을 종료하거나 재시작하면 목록이 초기화됩니다.**

## 1. 실행하기

Windows에서 소스를 빌드해 실행합니다. `앱 실행.cmd`는 로컬에 준비된
`output/windows-simple/Release/today_todo.exe`를 실행하는 보조 스크립트입니다.
실행 파일을 배포할 때는 같은 폴더의 DLL과 `data`도 함께 포함해야 합니다.

GitHub에서 받은 소스 또는 제출 ZIP에는 빌드 결과가 포함되지 않으므로 Flutter와 Windows 빌드 도구를 준비한 뒤 프로젝트 폴더의 PowerShell에서 실행합니다.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_app.ps1
```

debug 앱이 열립니다. 할 일을 입력하고 추가하거나 Enter를 누릅니다. 체크박스로 완료 상태를 바꾸고 휴지통 버튼으로 삭제합니다. 실행 터미널에서 `q`를 누르면 종료됩니다.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_app.ps1 -Profile
powershell -ExecutionPolicy Bypass -File .\scripts\run_app.ps1 -Build
```

`-Profile`은 DevTools 성능 관찰용 실행이고, `-Build`는 release 빌드입니다. 빌드 후 실행 파일은 다음 위치에 생깁니다.

```powershell
.\build\windows\x64\runner\Release\today_todo.exe
```

빌드를 마치면 `앱 실행.cmd`로 실행할 수 있습니다. 실행 파일을 다른 폴더에 옮길 때에는 DLL·data가 들어 있는 **Release 폴더 전체**를 복사합니다. 실행 스크립트는 프로젝트의 `.tooling/flutter` SDK 또는 PATH의 Flutter를 사용합니다. `-ExecutionPolicy Bypass`는 해당 PowerShell 프로세스에만 적용됩니다.

## 2. 기능과 과제 범위

| 요구사항 | 구현 |
| --- | --- |
| 기본 기능 20점 | 할 일 목록 표시, 제목 추가, 고유 ID로 삭제 |
| Riverpod 보너스 10점 | 같은 앱의 목록과 완료 상태를 NotifierProvider로 관리 |
| 네이티브 DevTools 보너스 10점 | Windows 앱의 Inspector·Timeline·Memory·Performance 관찰 |
| 추가 기능 | 완료 체크 및 완료 취소 |
| 제출물 | 자체 코드, 실행 명령·구조·보너스·스크린샷을 포함한 Readme.pdf |

공백만 있는 제목은 추가하지 않습니다. 제목 앞뒤 공백을 정리하며 같은 제목의 여러 항목은 서로 다른 ID로 구분합니다. 완료한 항목도 목록에 남아 완료 표시를 확인하거나 삭제할 수 있습니다. 빈 목록에는 안내를 표시합니다.

날짜·점수·장소·회고·통계·영구 저장 기능은 이 간단 버전에 포함하지 않습니다. 과제 마감은 **2026-10-11 일요일 23:59 KST**입니다.

## 3. 개발 환경과 일반 명령

확인한 도구 환경은 Flutter 3.47.6 stable, Dart 3.13.5, DevTools 2.60.0, Windows x64입니다. Riverpod의 실제 사용 버전은 `pubspec.lock`에서 확인합니다.

Flutter SDK를 설치하고 `bin` 폴더를 PATH에 등록합니다. Windows 네이티브 빌드를 위해 Visual Studio 또는 Build Tools에 **Desktop development with C++** 작업과 Windows SDK를 설치합니다.

PATH에 Flutter가 있는 일반 환경에서는 다음 명령을 사용합니다.

```powershell
flutter --version
flutter doctor -v
flutter pub get
dart format lib test test_driver scripts
flutter analyze
flutter test --reporter expanded
flutter run -d windows
flutter run -d windows --profile
flutter build windows
```

debug와 profile 실행은 하나씩 종료한 뒤 다음 명령을 실행합니다. `flutter pub get`은 의존성을 설치하며, SDK·패키지 소스와 생성 캐시는 코드 제출물에서 제외합니다.

## 4. 코드 구조와 위젯

| 파일 | 역할 |
| --- | --- |
| lib/main.dart | ProviderScope 안에서 MaterialApp 시작 |
| lib/models/todo.dart | Todo의 ID·제목·완료 상태 정의 |
| lib/providers/todo_provider.dart | 목록 상태 및 추가·삭제·완료 변경 |
| lib/screens/todo_screen.dart | 입력 폼·목록·빈 목록 안내 |
| lib/widgets/todo_tile.dart | 개별 항목의 체크박스·제목·삭제 버튼 |
| test/ | 상태 변경과 화면 동작 검사 |
| test_driver/, scripts/ | 네이티브 촬영·검증·실행·PDF·제출 도구 |

화면은 `ConsumerStatefulWidget`으로 구현하여 입력창의 `TextEditingController`와 `FocusNode`를 소유하고 `dispose`에서 정리합니다. `Scaffold`·`AppBar` 아래에 `TextField`와 `FilledButton.icon`, 전체 개수, `Expanded` 안의 `ListView.builder`를 둡니다. `TodoTile`은 `ListTile`의 제목·`Checkbox`·삭제 `IconButton`으로 구성하며 완료 제목에는 취소선을 표시합니다.

빈 제목은 입력창의 `할 일을 입력하세요.` 오류로 안내합니다. 새 입력 시 오류를 해제하고 정상 추가하면 입력창을 비운 뒤 포커스를 유지합니다. Enter도 같은 추가 처리를 호출합니다.

`ref.watch(todoProvider)`로 현재 목록을 읽어 상태 변경 시 화면을 다시 구성합니다. 버튼 동작은 `ref.read(todoProvider.notifier)`로 변경 메서드를 호출합니다. 제목 입력은 화면의 임시 상태이고 할 일 목록은 Riverpod 상태입니다.

## 5. 상태 자료구조와 변경 흐름

`Todo`는 `int id`, `String title`, `bool isCompleted`를 가진 불변 모델입니다. `copyWith({bool? isCompleted})`로 ID·제목을 유지한 새 객체를 만듭니다. Riverpod 상태는 `List<Todo>`이며 `NotifierProvider<TodoNotifier, List<Todo>>`를 사용합니다.

| 메서드 | 동작 |
| --- | --- |
| addTodo(String title) → bool | trim한 제목이 비면 false, 정상 추가하면 true |
| deleteTodo(int id) → void | 해당 ID 항목만 제외한 새 목록으로 교체 |
| toggleTodo(int id) → void | 해당 ID의 완료 상태를 바꾼 새 Todo·목록으로 교체 |

기존 목록을 직접 수정하지 않고 `List<Todo>.unmodifiable`의 새 목록을 `state`에 대입합니다. 화면은 변경을 구독하므로 결과가 바로 반영됩니다. ID는 1부터 시작하고 정상 추가마다 증가하며 삭제 후에도 실행 중 재사용하지 않습니다. 같은 제목도 ID가 다르면 별개 항목이고, 없는 ID의 삭제·완료 변경은 목록을 바꾸지 않습니다.

서버나 파일 저장을 기다리는 비동기 단계가 없으므로 동기 `Notifier`를 사용합니다. 앱 재시작 또는 새 `ProviderScope`에서는 빈 목록과 ID 1부터 시작합니다.

## 6. 네이티브 DevTools와 촬영

Inspector는 debug 앱을 실행한 뒤 터미널의 DevTools 링크로 연결합니다. 위젯 트리에서 목록 항목이나 입력창을 선택하고 속성·부모 구조를 확인합니다.

Timeline·Memory·Performance는 **Windows profile 앱**에서 확인합니다. 해당 실행의 DevTools에 연결하여 항목 추가·체크·삭제·스크롤을 수행합니다. DevTools 2.60.0의 **Performance → Timeline Events**에서 `todo.add/delete/toggle` 표식과 선택 구간을 확인하고, 프레임 상세에서 UI·raster 시간을 확인합니다. Memory에서는 그래프와 클래스 수를 관찰하며 필요하면 GC·Refresh 전후를 비교합니다.

VM Service 주소는 실행마다 달라집니다. 한 프레임의 시간은 전체 평균 성능이 아니며, 짧은 메모리 관찰만으로 누수가 없다고 단정하지 않습니다. 실제 선택 이벤트·프레임·관찰 시각과 동작을 검증 기록에 남깁니다.

Windows 앱의 목록·추가·삭제 화면 5장이 포함됩니다. DevTools 화면 4장은 미촬영입니다.

| 파일: docs/screenshots/ | 화면 |
| --- | --- |
| 01_list.png | 제목·완료 체크가 보이는 목록 |
| 02_add_input.png | 새 제목 입력 |
| 03_add_result.png | 추가된 항목과 변경된 목록 |
| 04_delete_before.png | 삭제 대상과 삭제 전 목록 |
| 05_delete_after.png | 해당 항목만 삭제된 목록 |
| 06_devtools_inspector.jpg | debug 위젯 트리·선택 속성 |
| 07_devtools_timeline.jpg | profile의 Timeline Events |
| 08_devtools_memory.jpg | profile 메모리 그래프·클래스 |
| 09_devtools_performance.jpg | profile 프레임 차트·UI/raster |

## 7. 검증 상태

간단 버전 `1.1.0+3`의 정적 분석에서 문제가 없었으며, 깨끗한 소스 복사본에서 **14개 테스트(상태 6개·화면 8개)**와 **Windows release 빌드**를 통과했습니다. 소스 60개의 SHA-256도 복사본과 일치했습니다. 실행한 debug 앱에서 목록·추가·삭제·완료 체크를 확인하고 **기능 화면 5장**을 촬영했습니다. 항목 수는 3개 → 4개 → 3개로 변경됐습니다.

근거는 `docs/evidence/simple_clean_build.json`, `simple_clean_test.txt`, `simple_feature_capture.json`입니다. DevTools 캡처 4장, 이 버전의 Readme.pdf와 제출 ZIP은 미완료 항목입니다.

## 8. 보관한 전체 버전과 전환

`main`은 목록·추가·삭제·완료 체크를 제공하는 기본 버전입니다. `codex/simple-todo`에도 같은 버전이 있습니다.

전체 기능 버전은 `codex/full-planner`의 커밋 `b11b5e9`에 보관합니다. 장소·점수·달력·회고·저장 기능이 있는 버전으로 다시 전환할 수 있습니다.

```powershell
git status
# 확장 기능 버전
git switch codex/full-planner
# 기본 버전
git switch codex/simple-todo
```

원하는 브랜치 하나를 선택합니다. 편집한 내용은 commit하거나 stash한 뒤 전환합니다. 전환 후에는 해당 소스로 `scripts/run_app.ps1`을 실행해 다시 빌드합니다. 이미 생성된 실행 파일은 브랜치를 바꿔도 자동으로 바뀌지 않습니다.

## 9. PDF와 제출 코드

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\update_readme.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\package_submission.ps1
```

PDF는 `output/pdf/Readme.pdf`에 생성됩니다. PATH에 Python이 없다면 update_readme.ps1의 `-PythonPath`로 실행 파일을 지정합니다. 직접 생성할 때에는 `python -m pip install reportlab Pillow` 후 `python scripts/build_readme_pdf.py`를 실행합니다.

제출에는 자체 `lib/`, `test/`, `test_driver/`, `scripts/`, 문서·실제 캡처, `pubspec.yaml`·`pubspec.lock`·분석 설정·필수 플랫폼 소스와 `Readme.pdf`를 포함합니다. `.tooling/`, SDK·다운로드 의존성·`build/`·`.dart_tool/`·ephemeral·Git·개인 IDE 설정은 제외합니다. 제출 전 PDF의 한글·명령·표·스크린샷과 ZIP의 파일 구성을 확인합니다.
