@echo off
chcp 65001 >nul
set "TODO_APP_DIR=%~dp0output\windows\Release"
if not exist "%TODO_APP_DIR%\today_todo.exe" set "TODO_APP_DIR=%~dp0build\windows\x64\runner\Release"
if not exist "%TODO_APP_DIR%\today_todo.exe" (
  echo 실행 파일이 아직 없습니다. 프로젝트 폴더에서 flutter build windows 명령을 실행하세요.
  pause
  exit /b 1
)
pushd "%TODO_APP_DIR%"
start "" today_todo.exe
popd
