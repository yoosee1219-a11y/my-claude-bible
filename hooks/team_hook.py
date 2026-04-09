"""Claude Code -> Team Dashboard event bridge.

Sends events to the central Rails server via HTTP POST.
Reuses classify_department() and make_summary() from dashboard_hook.py.
"""

import json
import sys
import os
import time
import re

if sys.platform == "win32":
    sys.stdin.reconfigure(encoding="utf-8", errors="replace")
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

# --- Configuration ---
# Set these environment variables or edit directly
SERVER_URL = os.environ.get("TEAM_DASHBOARD_URL", "http://100.65.90.109:3000")
API_TOKEN = os.environ.get("TEAM_DASHBOARD_TOKEN", "")


def classify_department(tool_name: str, tool_input: dict) -> str:
    if tool_name == "Skill":
        skill = str(tool_input.get("skill", ""))
        if re.search(r"xlsx|docx|pptx|pdf", skill, re.I):
            return "documents"
        if re.search(r"design|canvas|landing", skill, re.I):
            return "design"
        if re.search(r"commit|review-pr|git", skill, re.I):
            return "verification"
        return "development"
    if tool_name == "Agent":
        t = str(tool_input.get("subagent_type", ""))
        if re.search(r"Explore|research", t, re.I):
            return "research"
        if re.search(r"Plan|arch|db-architect|tech-lead", t, re.I):
            return "planning"
        if re.search(r"qa|test|security|debug|code-review", t, re.I):
            return "verification"
        if re.search(r"design|ui-|mobile", t, re.I):
            return "design"
        if re.search(r"doc-|technical-writer", t, re.I):
            return "documents"
        if re.search(r"devops|docker|cicd|deployment", t, re.I):
            return "devops"
        return "development"
    if tool_name in ("WebSearch", "WebFetch"):
        return "research"
    if tool_name in ("Read", "Glob", "Grep"):
        return "analysis"
    if tool_name in ("Write", "Edit", "NotebookEdit"):
        return "development"
    if tool_name == "Bash":
        cmd = str(tool_input.get("command", ""))
        if re.search(r"test|jest|vitest|pytest|lint", cmd):
            return "verification"
        if re.search(r"docker|kubectl|deploy|ssh", cmd):
            return "devops"
        return "development"
    if re.search(r"Task|Plan", tool_name):
        return "planning"
    if tool_name.startswith("mcp__"):
        return "research"
    return "analysis"


def make_summary(tool_name: str, tool_input: dict) -> str:
    if tool_name == "Read":
        return f"Reading {os.path.basename(tool_input.get('file_path', ''))}"
    if tool_name == "Write":
        return f"Writing {os.path.basename(tool_input.get('file_path', ''))}"
    if tool_name == "Edit":
        return f"Editing {os.path.basename(tool_input.get('file_path', ''))}"
    if tool_name == "Bash":
        return f"$ {str(tool_input.get('command', '')).split(chr(10))[0][:40]}"
    if tool_name == "Agent":
        return f"Agent: {tool_input.get('subagent_type', 'general')}"
    if tool_name == "Skill":
        return f"Skill: {tool_input.get('skill', '')}"
    return tool_name


def send_event(payload: dict):
    """Send event to the team dashboard server."""
    if not API_TOKEN:
        return

    import urllib.request
    import urllib.error

    url = f"{SERVER_URL}/api/events"
    data = json.dumps(payload).encode("utf-8")

    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {API_TOKEN}",
        },
        method="POST",
    )

    try:
        urllib.request.urlopen(req, timeout=5)
    except Exception:
        pass  # silently fail - don't block Claude Code


def main():
    try:
        raw = sys.stdin.read()
        data = json.loads(raw)
    except Exception:
        return

    hook_event = data.get("hook_event_name", "")

    if hook_event == "PostToolUse":
        tool_name = data.get("tool_name", "")
        tool_input = data.get("tool_input", {})
        if not tool_name:
            return

        send_event({
            "session_id": data.get("session_id", "unknown"),
            "event_type": "tool_use",
            "tool_name": tool_name,
            "tool_input": json.dumps(tool_input, ensure_ascii=False)[:500],
            "department": classify_department(tool_name, tool_input),
            "summary": make_summary(tool_name, tool_input),
            "project_path": str(tool_input.get("file_path", tool_input.get("path", "")))[:200],
            "occurred_at": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
        })

    elif hook_event == "Stop":
        send_event({
            "session_id": data.get("session_id", "unknown"),
            "event_type": "session_end",
            "summary": "세션 종료",
            "department": "analysis",
            "occurred_at": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
        })


if __name__ == "__main__":
    main()
