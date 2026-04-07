# Claude Code Watchdog

자동 빌드 + AI 디버깅. 두 가지 모드 지원.

## 모드

| 모드 | 설명 | 용도 |
|------|------|------|
| `safe` | 자동 수정 후 diff 리뷰 → 승인/거부 선택 | 프로덕션, 중요 프로젝트 |
| `yolo` | 자동 수정 + 자동 커밋 (사람 개입 없음) | 개인 프로젝트, 프로토타이핑 |

## 사용법

### Windows
```powershell
.\watchdog.ps1                          # Safe 모드 (기본)
.\watchdog.ps1 -Mode yolo               # YOLO 모드
.\watchdog.ps1 -Mode safe -Interval 30  # 30초 주기
```

### Mac / Linux
```bash
chmod +x watchdog.sh
./watchdog.sh safe          # Safe 모드
./watchdog.sh yolo 30       # YOLO + 30초 주기
nohup ./watchdog.sh yolo &  # 백그라운드
```

## Safe 모드 흐름
```
빌드 → 에러 → Claude 수정 → diff 표시 → [A]승인 / [R]거부 / [S]건너뛰기
```

## YOLO 모드 흐름
```
빌드 → 에러 → Claude 수정 → 자동 커밋 → 다음 사이클
```

## 필수 조건
- Claude Code CLI + Max 구독 ($100+/월)
- Git 초기화된 프로젝트에서 실행
