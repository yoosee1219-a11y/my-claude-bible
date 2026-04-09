#!/bin/bash
# Claude Code Hook → Telegram 알림 전달
# stdin으로 JSON을 받아 telegram-notify.py에 전달

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python "$SCRIPT_DIR/telegram_notify.py"
exit 0
