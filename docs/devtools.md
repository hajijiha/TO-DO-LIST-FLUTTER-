# DevTools 기록

Windows 앱을 실행한 상태에서 터미널에 출력되는 DevTools 링크를 브라우저로 연다.

## Inspector

```powershell
flutter run -d windows
```

Debug 실행에서 Show Implementation Widgets를 켜고 Column의 위젯 구조와 레이아웃을 확인했다.

![Inspector](screenshots/06_devtools_inspector.jpg)

## Timeline, Memory, Performance

Debug 실행을 `q`로 종료하고 profile 모드로 다시 실행한다. 새 실행에서 출력된 DevTools 링크에 연결한다.

```powershell
flutter run -d windows --profile
```

Performance의 Timeline Events에서 `todo.add` 이벤트를 확인했다.

![Timeline Events](screenshots/07_devtools_timeline.jpg)

추가 20회, 삭제 10회, 완료 변경 1회 후 GC와 Refresh를 실행해 메모리와 객체 수를 확인했다.

![Memory](screenshots/08_devtools_memory.jpg)

Flutter frames에서 프레임 390의 UI·Raster 정보를 확인했다.

![Performance](screenshots/09_devtools_performance.jpg)

관측 기록은 [devtools_observations.json](evidence/devtools_observations.json)에 있다.
