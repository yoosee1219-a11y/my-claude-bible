"""Claude Code → Telegram 알림 전송 스크립트.

사용법:
  1) CLI 직접: python telegram_notify.py "메시지 내용"
  2) Hook stdin: echo '{"message":"..."}' | python telegram_notify.py
  3) 모듈 import: from telegram_notify import send_telegram
"""

import json
import sys
import urllib.request
import urllib.parse
import os
import datetime

# Windows 콘솔 인코딩 문제 방지
if sys.platform == "win32":
    sys.stdin.reconfigure(encoding="utf-8", errors="replace")
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

# raonbot .env에서 설정 읽기 (dotenv 없이 직접 파싱)
_ENV_PATH = os.path.join(os.path.expanduser("~"), "Desktop", "raonbot", ".env")


def _load_env(path: str) -> dict[str, str]:
    """간단한 .env 파서."""
    env = {}
    if not os.path.isfile(path):
        return env
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, value = line.partition("=")
            env[key.strip()] = value.strip()
    return env


def send_telegram(text: str, bot_token: str, chat_id: str) -> bool:
    """Telegram Bot API로 메시지 전송. 성공 시 True."""
    # surrogate 문자 제거 (Windows 인코딩 이슈 방지)
    clean_text = text.encode("utf-8", errors="replace").decode("utf-8")

    url = f"https://api.telegram.org/bot{bot_token}/sendMessage"
    payload = json.dumps({
        "chat_id": chat_id,
        "text": clean_text,
        "parse_mode": "Markdown",
        "disable_web_page_preview": True,
    }).encode("utf-8")

    try:
        req = urllib.request.Request(
            url, data=payload, method="POST",
            headers={"Content-Type": "application/json"},
        )
        with urllib.request.urlopen(req, timeout=10) as resp:
            return resp.status == 200
    except Exception as e:
        # Markdown 파싱 실패 시 일반 텍스트로 재시도
        try:
            payload_plain = json.dumps({
                "chat_id": chat_id,
                "text": clean_text,
                "disable_web_page_preview": True,
            }).encode("utf-8")
            req2 = urllib.request.Request(
                url, data=payload_plain, method="POST",
                headers={"Content-Type": "application/json"},
            )
            with urllib.request.urlopen(req2, timeout=10) as resp:
                return resp.status == 200
        except Exception as e2:
            print(f"[telegram-notify] 전송 실패: {e2}", file=sys.stderr)
            return False


def _parse_transcript(transcript_path: str) -> dict:
    """transcript JSONL을 파싱해 작업 요약 정보를 반환."""
    result = {
        "edited_files": [],
        "read_files": [],
        "bash_commands": [],
        "start_time": None,
        "end_time": None,
    }

    if not transcript_path or not os.path.isfile(transcript_path):
        return result

    try:
        lines = []
        with open(transcript_path, encoding="utf-8", errors="replace") as f:
            lines = f.readlines()

        # 마지막 세션 찾기: 가장 마지막 "human" 역할 이후부터
        last_human_idx = 0
        for i, line in enumerate(lines):
            try:
                entry = json.loads(line)
                if entry.get("role") == "human" or entry.get("type") == "user":
                    last_human_idx = i
            except Exception:
                continue

        session_lines = lines[last_human_idx:]

        first_ts = None
        last_ts = None

        for line in session_lines:
            try:
                entry = json.loads(line)
            except Exception:
                continue

            # 타임스탬프 수집
            ts_str = entry.get("timestamp") or entry.get("ts")
            if ts_str:
                try:
                    ts = datetime.datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
                    if first_ts is None:
                        first_ts = ts
                    last_ts = ts
                except Exception:
                    pass

            # tool_use 항목에서 도구 사용 내역 추출
            content = entry.get("content", [])
            if isinstance(content, list):
                for block in content:
                    if not isinstance(block, dict):
                        continue
                    if block.get("type") != "tool_use":
                        continue

                    tool_name = block.get("name", "")
                    tool_input = block.get("input", {})

                    if tool_name in ("Write", "Edit"):
                        fp = tool_input.get("file_path", "")
                        if fp:
                            fname = os.path.basename(fp)
                            if fname not in result["edited_files"]:
                                result["edited_files"].append(fname)

                    elif tool_name == "Read":
                        fp = tool_input.get("file_path", "")
                        if fp:
                            fname = os.path.basename(fp)
                            if fname not in result["read_files"]:
                                result["read_files"].append(fname)

                    elif tool_name == "Bash":
                        cmd = tool_input.get("command", "").strip()
                        if cmd:
                            # 너무 긴 명령어는 줄이기
                            short_cmd = cmd.split("\n")[0][:60]
                            if len(cmd.split("\n")[0]) > 60:
                                short_cmd += "…"
                            if short_cmd not in result["bash_commands"]:
                                result["bash_commands"].append(short_cmd)

        result["start_time"] = first_ts
        result["end_time"] = last_ts

    except Exception as e:
        print(f"[telegram-notify] transcript 파싱 오류: {e}", file=sys.stderr)

    return result


def _format_stop_message(transcript_path: str) -> str:
    """Stop 이벤트용 한국어 요약 메시지 생성."""
    info = _parse_transcript(transcript_path)

    lines = ["✅ *작업 완료!*"]

    # 수정/생성한 파일
    if info["edited_files"]:
        lines.append(f"\n✏️ *수정한 파일* ({len(info['edited_files'])}개)")
        for f in info["edited_files"][:8]:
            lines.append(f"  • `{f}`")
        if len(info["edited_files"]) > 8:
            lines.append(f"  • _...외 {len(info['edited_files']) - 8}개_")

    # 읽은 파일 (수정한 파일과 겹치지 않는 것만)
    unique_reads = [f for f in info["read_files"] if f not in info["edited_files"]]
    if unique_reads:
        lines.append(f"\n📖 *읽은 파일* ({len(unique_reads)}개)")
        for f in unique_reads[:5]:
            lines.append(f"  • `{f}`")
        if len(unique_reads) > 5:
            lines.append(f"  • _...외 {len(unique_reads) - 5}개_")

    # 실행한 명령
    if info["bash_commands"]:
        lines.append(f"\n⚡ *실행한 명령* ({len(info['bash_commands'])}개)")
        for cmd in info["bash_commands"][:5]:
            lines.append(f"  • `{cmd}`")
        if len(info["bash_commands"]) > 5:
            lines.append(f"  • _...외 {len(info['bash_commands']) - 5}개_")

    # 파일/명령이 하나도 없으면 간단한 메시지
    if not info["edited_files"] and not unique_reads and not info["bash_commands"]:
        lines.append("\n💬 답변이 준비되었습니다.")

    # 소요 시간
    if info["start_time"] and info["end_time"]:
        delta = int((info["end_time"] - info["start_time"]).total_seconds())
        if delta >= 60:
            elapsed = f"{delta // 60}분 {delta % 60}초"
        else:
            elapsed = f"{delta}초"
        lines.append(f"\n⏱ 소요: {elapsed}")

    return "\n".join(lines)


def _format_notification_message(data: dict) -> str:
    """Notification 이벤트용 한국어 메시지 생성."""
    msg = data.get("message", "")
    title = data.get("title", "")
    ntype = data.get("notification_type", "")

    # 알림 타입별 이모지
    type_emoji = {
        "permission": "🔐",
        "error": "❌",
        "warning": "⚠️",
        "info": "ℹ️",
    }
    emoji = type_emoji.get(ntype, "🔔")

    label = title or ntype or "알림"

    # notification_type → 한국어
    label_kr = {
        "permission": "권한 확인 필요",
        "error": "오류 발생",
        "warning": "경고",
        "info": "안내",
    }.get(ntype, label)

    if msg:
        return f"{emoji} *{label_kr}*\n\n{msg}"
    else:
        return f"{emoji} *{label_kr}*\n\n확인이 필요합니다."


def main():
    env = _load_env(_ENV_PATH)
    bot_token = env.get("BOT_TOKEN", "")
    chat_id = env.get("ALLOWED_USERS", "")

    if not bot_token or not chat_id:
        print("[telegram-notify] BOT_TOKEN 또는 ALLOWED_USERS 미설정", file=sys.stderr)
        sys.exit(1)

    # 1) CLI 인자로 전달된 경우
    if len(sys.argv) > 1:
        message = " ".join(sys.argv[1:])
        if not message.startswith("[RaonBot]"):
            message = f"[RaonBot] {message}"
    else:
        # 2) stdin에서 JSON 읽기 (Claude Code hook)
        try:
            raw = sys.stdin.read()
            data = json.loads(raw)
            hook_event = data.get("hook_event_name", "Unknown")

            if hook_event == "Stop":
                transcript_path = data.get("transcript_path", "")
                message = _format_stop_message(transcript_path)

            elif hook_event == "Notification":
                message = _format_notification_message(data)

            else:
                msg = data.get("message", "")
                message = msg or f"Claude Code 이벤트: {hook_event}"

        except (json.JSONDecodeError, Exception):
            raw_stripped = raw.strip() if 'raw' in dir() else ""
            message = raw_stripped or "Claude Code 알림"

    send_telegram(message, bot_token, chat_id)


if __name__ == "__main__":
    main()
