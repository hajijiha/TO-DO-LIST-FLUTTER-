# 검증 기록

버전 `1.1.0+3`의 실행 기록이다.

| 항목 | 결과 |
|---|---|
| 환경 | Flutter 3.47.6, Dart 3.13.5, flutter_riverpod 3.4.3, Windows x64 |
| 정적 분석 | No issues found |
| 테스트 | 상태 6개·화면 8개, 총 14개 통과 |
| Windows release | 빌드·실행, 입력·추가, 재시작 후 목록 초기화 확인 |
| 기능 화면 | 목록, 추가 전후, 삭제 전후 5장 |
| DevTools | debug Inspector, profile Timeline·Memory·Performance 4장 |

검사 범위는 빈 입력 거부, trim, 중복 제목과 ID 구분, 선택 삭제, 마지막 항목 삭제, 완료 취소와 기존 목록 보존이다.

실행 원본:

- [전체 검증](evidence/simple_final_validation.json)
- [기능 화면 기록](evidence/simple_feature_capture.json)
- [Release 실행](evidence/simple_release_smoke.json)
- [DevTools 관측](evidence/devtools_observations.json)
- [깨끗한 소스의 정적 분석](evidence/simple_clean_analyze.txt) · [테스트](evidence/simple_clean_test.txt) · [빌드](evidence/simple_clean_release.txt)
