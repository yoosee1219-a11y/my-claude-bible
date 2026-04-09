---
name: ralph-autonomous-dev
description: Ralph, 자율개발, 무한루프, PRD자동구현, 퇴근후개발, Circuit Breaker, Rate Limiting, tmux, 백그라운드실행, Dual Exit Gate, 세션관리, 자동디버깅, 자동코딩, 무인개발, Geoffrey Huntley 기법, Claude Code 자동화
---

# Ralph for Claude Code - 자율 개발 시스템

## 개요

Ralph는 **PRD 문서만 제공하면 퇴근 후에도 계속 개발하는** 자율 AI 개발 시스템입니다. Geoffrey Huntley의 무한 루프 기법을 Claude Code용으로 구현한 것으로, 외부 bash 스크립트가 Claude Code CLI를 반복 호출하여 프로젝트가 완성될 때까지 자동으로 개발합니다.

**핵심 차별점:**
- 일반 Claude Code: 2분마다 사용자 응답 필요 → 퇴근 불가
- **Ralph**: tmux + 무한 루프 → 퇴근해도 계속 개발 → 집에서 결과 확인

## 시스템 구조

### 무한 루프 아키텍처

```bash
# ralph_loop.sh 핵심 로직
while true; do
  # 1. PROMPT.md 읽기 (PRD + 개발 지시사항)
  # 2. Claude Code CLI 실행
  claude code -p "$(cat PROMPT.md)"

  # 3. 결과 분석 (response_analyzer.sh)
  - 파일 변경 여부
  - 에러 발생 여부
  - EXIT_SIGNAL 확인

  # 4. 완료 조건 평가 (Dual Exit Gate)
  if [[ $completion_indicators >= 2 ]] && [[ $EXIT_SIGNAL == "true" ]]; then
    echo "프로젝트 완료!" && exit
  fi

  # 5. 안전장치 확인
  - Circuit Breaker (무한 루프 방지)
  - Rate Limit (시간당 100회 제한)
  - 5-hour API Limit 감지

  # 6. @fix_plan.md 업데이트 (Claude가 자동 업데이트)
  # 7. 다음 루프로
done
```

### 파일 구조

```
my-project/
├── PROMPT.md           # Ralph에게 주는 개발 지시사항 (PRD 포함)
├── @fix_plan.md        # 우선순위별 작업 목록 (Claude 자동 업데이트)
├── @AGENT.md           # 빌드/실행 명령어
├── specs/              # 프로젝트 사양서
├── src/                # 소스 코드 (Claude가 자동 생성)
├── logs/               # Ralph 실행 로그
└── .ralph_session      # 세션 관리 (24시간 유지)
```

## 핵심 메커니즘

### 1. Dual Exit Gate (조기 종료 방지)

**문제**: "작업 완료"라는 단어만으로 루프를 종료하면 조기 종료 발생
**해결**: 2가지 조건을 **동시에** 만족해야만 종료

| completion_indicators | EXIT_SIGNAL | 결과 |
|-----------------------|-------------|------|
| >= 2 | `true` | ✅ **종료** (프로젝트 완료) |
| >= 2 | `false` | ❌ **계속** (Claude가 명시적으로 더 할 일 있음) |
| < 2 | `true` | ❌ **계속** (threshold 미달) |

**예시:**
```
Loop 5: "Phase 1 완료, Phase 2 시작합니다"
  → completion_indicators: 3 (높은 확신도)
  → EXIT_SIGNAL: false (Claude가 명시적으로 더 할 일 있음)
  → 결과: 계속 실행 ✅

Loop 10: "모든 요구사항 구현 완료, 테스트 통과"
  → completion_indicators: 4
  → EXIT_SIGNAL: true (Claude가 명시적으로 완료 선언)
  → 결과: 종료 🎉
```

### 2. Circuit Breaker (무한 루프 방지)

**감지 조건:**
- 3회 연속 파일 변경 없음
- 5회 연속 동일한 에러
- 출력량 70% 이상 감소

**동작:**
```
CLOSED (정상) → 개발 진행
    ↓ (감지)
HALF_OPEN (모니터링) → 1회 더 확인
    ↓ (재발)
OPEN (중단) → "ralph --reset-circuit" 필요
```

### 3. Rate Limiting

- **시간당 100회** API 호출 제한
- 초과 시 자동으로 1시간 대기 (카운트다운 표시)
- `.call_count` 파일로 추적

### 4. Session Management

- **24시간 세션 유지** (`--continue` 플래그)
- 만료 시 자동 리셋
- `.ralph_session` 파일에 저장

### 5. 5-Hour API Limit 처리

Claude API 5시간 제한 도달 시:
```
옵션 1: 60분 대기 (자동 재시도)
옵션 2: 종료 (수동 재시작)
```

## 사용 방법

### 설치 (Windows WSL 권장)

#### WSL + Ralph 설치

```bash
# 1. WSL 설치 (PowerShell 관리자 권한)
wsl --install

# 2. WSL Ubuntu에서 의존성 설치
sudo apt update
sudo apt install tmux jq git nodejs npm

# 3. Ralph 설치
git clone https://github.com/frankbria/ralph-claude-code.git
cd ralph-claude-code
./install.sh
```

### PRD → 자동 개발 워크플로우

#### 방법 1: PRD 파일로 프로젝트 생성

```bash
# PRD를 Ralph 프로젝트로 변환
ralph-import requirements.md my-awesome-app
cd my-awesome-app

# PROMPT.md 확인/수정 (필요시)
vi PROMPT.md

# tmux 세션에서 Ralph 실행
tmux new -s ralph-dev
ralph --monitor

# Ctrl+B → D로 detach
# 퇴근!

# 집 도착 후
tmux attach -s ralph-dev  # 결과 확인!
```

#### 방법 2: 수동 프로젝트 설정

```bash
# 빈 Ralph 프로젝트 생성
ralph-setup task-manager
cd task-manager

# PROMPT.md 편집 (PRD 내용 붙여넣기)
vi PROMPT.md

# Ralph 실행
ralph --monitor
```

### tmux 필수 명령어

```bash
# 새 세션 생성
tmux new -s session-name

# 세션에서 detach (백그라운드로 전환)
Ctrl+B → D

# 세션 목록 확인
tmux list-sessions

# 세션 재연결
tmux attach -s session-name

# 세션 종료 (내부에서)
exit
```

## 실전 사용 시나리오

### 시나리오: Task Management 웹앱 개발

**오전 9시: 퇴근 전 설정**
```bash
# PRD 작성 (sample-prd.md)
cat > task-manager-prd.md << EOF
# Task Management Web App
- React.js + TypeScript 프론트엔드
- Node.js + Express 백엔드
- PostgreSQL 데이터베이스
- 기본 CRUD, 인증, 팀 기능
EOF

# Ralph 프로젝트 생성
ralph-import task-manager-prd.md task-app
cd task-app

# tmux 세션에서 실행
tmux new -s task-dev
ralph --monitor --calls 80  # 시간당 80회 제한

# Ctrl+B → D (detach)
# 퇴근!
```

**오후 6시: 집에서 확인**
```bash
# WSL 접속
tmux attach -s task-dev

# 결과 확인
ls src/
# → frontend/, backend/, database/ 디렉토리 생성됨
# → API 엔드포인트 구현됨
# → 기본 React 컴포넌트 생성됨

# 로그 확인
tail -f logs/ralph.log

# 진행 상황 확인
cat @fix_plan.md
# [x] 백엔드 API 설계
# [x] 데이터베이스 스키마
# [x] 사용자 인증 구현
# [ ] 프론트엔드 UI (진행 중...)
```

## 주요 옵션

```bash
ralph --help                  # 도움말
ralph --monitor               # tmux 통합 모니터링 (권장)
ralph --calls 50              # 시간당 50회 제한
ralph --prompt custom.md      # 커스텀 프롬프트
ralph --timeout 30            # 30분 timeout
ralph --verbose               # 상세 로그
ralph --status                # 현재 상태 확인
ralph --reset-circuit         # Circuit Breaker 리셋
ralph --reset-session         # 세션 초기화
ralph --no-continue           # 세션 연속성 비활성화
```

## SuperClaude 통합 방법

Ralph의 패턴을 SuperClaude에 적용하는 방법:

### 옵션 A: Ralph를 직접 사용

```bash
# SuperClaude 프로젝트를 Ralph로 자동화
cd my-superclaude-project

# Ralph 프로젝트로 전환
ralph-setup .  # 현재 디렉토리에 Ralph 파일 생성

# PROMPT.md에 SuperClaude 스킬 참조
echo "Use sc:implement skill patterns" >> PROMPT.md

# Ralph 실행
ralph --monitor
```

### 옵션 B: Ralph 패턴을 SuperClaude 스킬로 구현

```markdown
---
name: sc:ralph-pattern
description: Ralph스타일, 반복개선, 자율실행, 작업추적
---

# Ralph Pattern for SuperClaude

## 사용법
1. PRD 제공
2. @fix_plan.md 작성
3. 구현 → 테스트 → 평가 사이클
4. 미완료 시 "계속 진행할까요?" 물어봄

(Ralph처럼 완전 자동은 불가, 단계별 확인 필요)
```

### 옵션 C: Git Bash에서 제한적 사용 (비추천)

```bash
# jq 설치 필요
choco install jq -y

# Ralph 실행 (백그라운드 불가)
cd C:/Users/woosol/task-manager-test
ralph  # --monitor 없이

# 한계:
# - 터미널 닫으면 중단
# - tmux 없어서 모니터링 불가
# - 진정한 "퇴근 후 개발" 불가능
```

## 장점 vs 한계

### 장점 ✅

1. **무인 개발**: PRD 던지고 퇴근 → 집에서 결과 확인
2. **안전장치**: Circuit Breaker, Rate Limit, Dual Exit Gate
3. **작업 추적**: @fix_plan.md 자동 업데이트
4. **세션 유지**: 24시간 컨텍스트 보존
5. **실전 검증**: 308개 테스트, 100% 통과

### 한계 ⚠️

1. **WSL/Linux 필수**: tmux 백그라운드 실행에 필요
2. **API 비용**: 시간당 100회 호출 = 하루 2,400회 가능
3. **PRD 품질 의존**: 모호한 PRD = 잘못된 방향
4. **완전 자동 아님**: 가끔 사용자 개입 필요 (에러 해결 등)

## 비용 예측

### 시간당 100회 제한 기준

```
1회 API 호출 비용: ~$0.10 (평균)
시간당 비용: $10
하루 (10시간): $100
주말 무인 실행 (48시간): $480

권장: --calls 30 (시간당 $3, 하루 $30)
```

## 트러블슈팅

### 문제 1: Circuit Breaker가 너무 자주 열림

```bash
# threshold 조정
vi ~/.ralph/lib/circuit_breaker.sh

CB_NO_PROGRESS_THRESHOLD=5  # 3 → 5로 증가
CB_SAME_ERROR_THRESHOLD=10  # 5 → 10으로 증가
```

### 문제 2: 조기 종료

```bash
# EXIT_SIGNAL 로그 확인
cat .response_analysis | jq '.analysis.exit_signal'

# false인데 종료했으면 버그 → GitHub 이슈 보고
```

### 문제 3: tmux 세션 찾을 수 없음

```bash
# 모든 세션 확인
tmux list-sessions

# 새로 생성
tmux new -s ralph-new

# 이전 세션 kill
tmux kill-session -t old-session-name
```

## 참고 자료

- **Ralph 공식 저장소**: https://github.com/frankbria/ralph-claude-code
- **Geoffrey Huntley 원문**: https://ghuntley.com/ralph/
- **Claude Code 문서**: https://claude.ai/code

## 태그

#Ralph #자율개발 #무한루프 #PRD자동구현 #퇴근후개발 #CircuitBreaker #RateLimiting #tmux #백그라운드실행 #DualExitGate #세션관리 #자동디버깅 #자동코딩 #무인개발 #GeoffreyHuntley #ClaudeCode자동화
