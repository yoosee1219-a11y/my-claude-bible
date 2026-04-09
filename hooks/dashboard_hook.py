"""Claude Code -> Dashboard event bridge (8 departments)."""

import json
import sys
import os
import time
import uuid
import re

if sys.platform == "win32":
    sys.stdin.reconfigure(encoding="utf-8", errors="replace")
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

EVENTS_DIR = os.path.join(os.path.expanduser("~"), ".claude", "dashboard")
EVENTS_FILE = os.path.join(EVENTS_DIR, "events.jsonl")


def classify_department(tool_name: str, tool_input: dict) -> str:
    # 1. Skill tool
    if tool_name == "Skill":
        skill = str(tool_input.get("skill", ""))
        if re.search(r"xlsx|docx|pptx|pdf", skill, re.I):
            return "documents"
        if re.search(r"design|canvas|landing|nano-banana|gpt-image|web-artifacts|antigravity|frontend-design|theme-factory", skill, re.I):
            return "design"
        if re.search(r"commit|review-pr|git", skill, re.I):
            return "verification"
        return "development"

    # 2. Agent tool
    if tool_name == "Agent":
        t = str(tool_input.get("subagent_type", ""))
        if re.search(r"Explore|research-collector|research-evaluator|research-planner|research-synthesizer|data-analyst|data-pipeline", t, re.I):
            return "research"
        if re.search(r"Plan|arch|db-architect|tech-lead|doc-architecture", t, re.I):
            return "planning"
        if re.search(r"qa|test|security|debug|code-review", t, re.I):
            return "verification"
        if re.search(r"design|ui-component|ui-styling|ui-a11y|ui-performance|ui-state|mobile-crossplatform|mobile-native|frontend-design", t, re.I):
            return "design"
        if re.search(r"doc-technical|doc-api-spec|doc-changelog|technical-writer", t, re.I):
            return "documents"
        if re.search(r"devops|sre|docker|container|cicd|deployment|iac|serverless|cloud-cost", t, re.I):
            return "devops"
        return "development"

    # 3. Web tools
    if tool_name in ("WebSearch", "WebFetch"):
        return "research"

    # 4. Read-only
    if tool_name in ("Read", "Glob", "Grep"):
        return "analysis"

    # 5. Write/Edit
    if tool_name in ("Write", "Edit", "NotebookEdit"):
        fp = str(tool_input.get("file_path", ""))
        if re.search(r"\.(xlsx|docx|pptx|pdf)$", fp, re.I):
            return "documents"
        return "development"

    # 6. Bash
    if tool_name == "Bash":
        cmd = str(tool_input.get("command", ""))
        if re.search(r"test|jest|vitest|pytest|lint|eslint|tsc|typecheck|check", cmd):
            return "verification"
        if re.search(r"docker|kubectl|terraform|ansible|deploy|ssh|scp|rsync|nginx|systemctl|pm2", cmd):
            return "devops"
        return "development"

    # 7. Task/Plan
    if re.search(r"Task|Plan|EnterPlan|ExitPlan", tool_name):
        return "planning"

    # 8. MCP
    if tool_name.startswith("mcp__"):
        if "Figma" in tool_name:
            return "design"
        if "Notion" in tool_name or "Gmail" in tool_name:
            return "documents"
        return "research"

    return "analysis"


def make_summary(tool_name: str, tool_input: dict) -> str:
    if tool_name == "Read":
        return f"Reading {os.path.basename(tool_input.get('file_path', ''))}"
    if tool_name == "Write":
        return f"Writing {os.path.basename(tool_input.get('file_path', ''))}"
    if tool_name == "Edit":
        return f"Editing {os.path.basename(tool_input.get('file_path', ''))}"
    if tool_name == "Glob":
        return f"Searching {tool_input.get('pattern', '')}"
    if tool_name == "Grep":
        return f"Grep: {str(tool_input.get('pattern', ''))[:30]}"
    if tool_name == "Bash":
        return f"$ {str(tool_input.get('command', '')).split(chr(10))[0][:40]}"
    if tool_name == "Agent":
        return f"Agent: {tool_input.get('subagent_type', 'general')}"
    if tool_name == "Skill":
        return f"Skill: {tool_input.get('skill', '')}"
    if tool_name == "WebSearch":
        return f"Web search: {str(tool_input.get('query', ''))[:30]}"
    if tool_name == "WebFetch":
        return f"Fetch: {str(tool_input.get('url', ''))[:40]}"
    if tool_name.startswith("mcp__"):
        parts = tool_name.split("__")
        return f"MCP: {parts[-1]}"
    return tool_name


def write_event(event: dict):
    os.makedirs(EVENTS_DIR, exist_ok=True)
    with open(EVENTS_FILE, "a", encoding="utf-8") as f:
        f.write(json.dumps(event, ensure_ascii=False) + "\n")


def handle_tool_use(data: dict):
    tool_name = data.get("tool_name", "")
    tool_input = data.get("tool_input", {})
    session_id = data.get("session_id", "unknown")
    if not tool_name:
        return
    event = {
        "id": str(uuid.uuid4())[:8],
        "timestamp": int(time.time() * 1000),
        "sessionId": session_id,
        "type": "tool_use",
        "tool": {"name": tool_name, "input": tool_input},
        "department": classify_department(tool_name, tool_input),
        "summary": make_summary(tool_name, tool_input),
    }
    write_event(event)


def _build_session_report(session_id: str) -> tuple:
    """세션 이벤트를 읽어 보고 형식의 요약과 주 부서를 반환."""
    if not os.path.isfile(EVENTS_FILE):
        return "세션을 종료했습니다.", "analysis"

    edited = []
    read_only = []
    bash_cmds = []
    agents_used = []
    skills_used = []
    dept_counts = {}

    try:
        with open(EVENTS_FILE, encoding="utf-8", errors="replace") as f:
            for line in f:
                try:
                    evt = json.loads(line)
                except Exception:
                    continue
                if evt.get("sessionId") != session_id or evt.get("type") != "tool_use":
                    continue

                dept = evt.get("department", "analysis")
                dept_counts[dept] = dept_counts.get(dept, 0) + 1

                tool = evt.get("tool", {})
                name = tool.get("name", "")
                inp = tool.get("input", {})

                if name in ("Write", "Edit"):
                    fp = os.path.basename(inp.get("file_path", ""))
                    if fp and fp not in edited:
                        edited.append(fp)
                elif name == "Read":
                    fp = os.path.basename(inp.get("file_path", ""))
                    if fp and fp not in read_only and fp not in edited:
                        read_only.append(fp)
                elif name == "Bash":
                    cmd = inp.get("command", "").split("\n")[0][:40]
                    if cmd:
                        bash_cmds.append(cmd)
                elif name == "Agent":
                    atype = inp.get("subagent_type", inp.get("description", ""))
                    if atype and atype not in agents_used:
                        agents_used.append(atype)
                elif name == "Skill":
                    skill = inp.get("skill", "")
                    if skill and skill not in skills_used:
                        skills_used.append(skill)
    except Exception:
        return "세션을 종료했습니다.", "analysis"

    main_dept = max(dept_counts, key=dept_counts.get) if dept_counts else "analysis"

    dept_kr = {
        "analysis": "분석", "development": "개발", "planning": "설계",
        "verification": "검증", "design": "디자인", "documents": "문서",
        "devops": "인프라", "research": "리서치",
    }

    # 보고 형식 생성
    parts = []

    if edited:
        file_list = ", ".join(edited[:3])
        if len(edited) > 3:
            file_list += f" 외 {len(edited) - 3}개"
        parts.append(f"{file_list} 수정 완료")

    if read_only:
        file_list = ", ".join(read_only[:3])
        if len(read_only) > 3:
            file_list += f" 외 {len(read_only) - 3}개"
        parts.append(f"{file_list} 분석 완료")

    if agents_used:
        parts.append(f"에이전트 {len(agents_used)}건 실행")

    if bash_cmds:
        parts.append(f"명령어 {len(bash_cmds)}건 실행")

    if skills_used:
        parts.append(f"스킬 {', '.join(skills_used[:2])} 사용")

    if not parts:
        if dept_counts:
            total = sum(dept_counts.values())
            parts.append(f"{dept_kr.get(main_dept, main_dept)} 작업 {total}건 처리")
        else:
            parts.append("대화 응답 완료")

    # 부서 활동 요약 추가
    active = [dept_kr.get(d, d) for d in dept_counts if d != main_dept and dept_counts[d] >= 2]
    if active:
        parts.append(f"{', '.join(active[:2])} 부서 협업")

    return ". ".join(parts), main_dept


def handle_stop(data: dict):
    session_id = data.get("session_id", "unknown")
    summary, dept = _build_session_report(session_id)
    write_event({
        "id": str(uuid.uuid4())[:8],
        "timestamp": int(time.time() * 1000),
        "sessionId": session_id,
        "type": "session_end",
        "department": dept,
        "summary": summary,
    })


def handle_subagent_stop(data: dict):
    # subagent 이름/설명이 있으면 활용
    desc = data.get("description", "") or data.get("subagent_type", "")
    summary = f"서브에이전트 완료: {desc}" if desc else "서브에이전트 작업 완료"
    write_event({
        "id": str(uuid.uuid4())[:8],
        "timestamp": int(time.time() * 1000),
        "sessionId": data.get("session_id", "unknown"),
        "type": "agent_stop",
        "department": "development",
        "summary": summary,
    })


def main():
    try:
        raw = sys.stdin.read()
        data = json.loads(raw)
    except (json.JSONDecodeError, Exception):
        return

    hook_event = data.get("hook_event_name", "")
    if hook_event == "PostToolUse":
        handle_tool_use(data)
    elif hook_event == "Stop":
        handle_stop(data)
    elif hook_event == "SubagentStop":
        handle_subagent_stop(data)


if __name__ == "__main__":
    main()
