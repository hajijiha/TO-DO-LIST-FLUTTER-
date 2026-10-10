# 오늘 할 일

Flutter와 Riverpod으로 만든 Windows 할 일 앱이다. 항목 추가·삭제와 완료 체크를 지원한다. 목록은 메모리에 저장하며 앱을 종료하면 초기화된다.

![할 일 목록과 완료 표시](docs/screenshots/01_list.png)

## 실행

Flutter SDK를 PATH에 등록하고, Visual Studio 또는 Build Tools의 **Desktop development with C++**와 Windows SDK를 설치한다. `pubspec.yaml`이 있는 폴더에서 PowerShell을 연다.

```powershell
flutter doctor -v
flutter pub get
flutter run -d windows
```

제목을 입력하고 추가 버튼이나 Enter를 누른다. 체크박스로 완료 상태를 바꾸고 휴지통 버튼으로 삭제한다. 공백뿐인 제목은 추가되지 않으며, 같은 제목도 서로 다른 항목으로 저장된다.

Release 빌드와 실행:

```powershell
flutter build windows --release
.\build\windows\x64\runner\Release\today_todo.exe
```

실행 파일을 옮길 때는 Release 폴더의 DLL과 `data`도 함께 복사한다.

## 코드 구성

| 파일 | 역할 |
|---|---|
| `lib/main.dart` | ProviderScope, MaterialApp과 시작 화면 |
| `lib/models/todo.dart` | ID, 제목, 완료 여부를 담는 불변 모델 |
| `lib/providers/todo_provider.dart` | 목록과 추가·삭제·완료 변경 |
| `lib/screens/todo_screen.dart` | 입력창, 전체 개수와 목록 |
| `lib/widgets/todo_tile.dart` | 체크박스, 제목과 삭제 버튼 |

화면은 `ref.watch(todoProvider)`로 목록을 읽고, 이벤트에서는 `ref.read(todoProvider.notifier)`로 변경을 요청한다. Notifier는 기존 객체를 수정하지 않고 새 Todo와 목록으로 상태를 교체한다. 입력 controller와 포커스는 화면에서 관리한다.

모델과 변경 메서드는 [상태 API](docs/state_api.md), 입력·목록의 동작 기준은 [기능 명세](docs/product_spec.md)에 있다.

## 테스트와 화면 기록

```powershell
flutter analyze
flutter test
```

기존 검증에서 상태 테스트 6개와 화면 테스트 8개가 통과했다. Windows release 실행과 재시작 시 목록 초기화도 확인했다. 환경과 로그는 [검증 기록](docs/verification.md)에 있다.

- 추가: [입력 전](docs/screenshots/02_add_input.png) · [추가 후](docs/screenshots/03_add_result.png)
- 삭제: [삭제 전](docs/screenshots/04_delete_before.png) · [삭제 후](docs/screenshots/05_delete_after.png)
- [DevTools 실행 방법과 화면](docs/devtools.md)
- [과제 보고서 PDF](Readme.pdf)
