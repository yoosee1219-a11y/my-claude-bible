# Claude Code Hooks

작업 완료/에러 시 자동 알림.

## 구성

| 훅 | 트리거 | 기능 |
|-----|--------|------|
| `telegram_notify.py` | Stop, Notification | 텔레그램 결과 전송 |
| `dashboard_hook.py` | PostToolUse, Stop | 대시보드 업데이트 |
| `team_hook.py` | PostToolUse, Stop | 팀 웹훅 전송 |

## 설치
```bash
cp hooks/.env.example hooks/.env   # 토큰 입력
cp hooks/*.py ~/.claude/hooks/
# settings.json에 훅 등록 (configs/settings.example.json 참고)
```

## 텔레그램 봇 설정
1. @BotFather → /newbot → 토큰 받기
2. 봇에게 메시지 보낸 후 Chat ID 확인
3. .env에 입력
