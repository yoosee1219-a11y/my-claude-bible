---
name: advanced-claude-workflows
description: 고급워크플로우, 병렬실행, 팀협업, 모바일개발, 바이브코딩, 비개발자자동화, 지식축적시스템, 비동기개발, 검증루프, 생산성극대화로 실전 검증된 Claude Code 고급 워크플로우 패턴을 제공하는 스킬
---

# Advanced Claude Workflows

실전에서 검증된 3가지 고급 Claude Code 워크플로우 패턴을 통합 제공합니다.

## Overview

이 스킬은 다음 3개 서브에이전트를 통해 각기 다른 환경과 니즈에 맞는 최적화된 워크플로우를 제공합니다:

1. **TeamOrchestrator** - 팀 협업 & 엔터프라이즈 개발 (Boris Cherny 방식)
2. **MobileDeveloper** - 이동 중 모바일 개발 환경 (On-The-Go)
3. **VibeCoder** - 비개발자를 위한 바이브 코딩 (우탄 방식)

---

## 🎯 공통 핵심 원칙

### 1. 병렬 실행의 힘
여러 Claude 세션을 동시에 실행하여 생산성을 기하급수적으로 증가시킵니다.

**효과:**
- 다른 작업을 동시 진행
- 대기 시간 최소화
- 복잡한 작업을 독립적인 단위로 분할

### 2. 검증 루프 (Verification Loop)
Claude에게 작업을 검증할 방법을 제공하면 최종 결과물 품질이 **2-3배 향상**됩니다.

**패턴:**
```bash
# 1. 테스트 작성
# 2. 구현
# 3. 자동 검증
# 4. 피드백 반영
# 5. 반복
```

### 3. 지식 축적 시스템
오류와 학습 내용을 문서화하여 반복적인 실수를 방지합니다.

---

## 🤝 서브에이전트 1: TeamOrchestrator

**대상:** 팀 협업 환경, 엔터프라이즈 개발자
**출처:** Boris Cherny (Claude Code 창시자)

### 핵심 전략

#### 1. 대규모 병렬 실행
```bash
# 로컬 터미널: 5개 세션
claude-code session1
claude-code session2
claude-code session3
claude-code session4
claude-code session5

# 웹 브라우저: 5-10개 추가 세션
# 시스템 알림으로 입력 필요 시점 파악
```

**활용 시나리오:**
- 프론트엔드/백엔드 동시 개발
- 버그 수정 + 새 기능 병렬 작업
- 테스트 작성 + 리팩토링 동시 진행

#### 2. CLAUDE.md - 팀 지식 베이스

**구조:**
```markdown
# CLAUDE.md

## 프로젝트 컨텍스트
- 기술 스택: React, Express, PostgreSQL
- 아키텍처: 마이크로서비스
- 배포: AWS ECS

## 반복되는 오류와 해결법
### [2026-01-08] TypeScript 타입 오류
- 문제: `User` 타입이 `null`일 수 있음
- 해결: Optional chaining 사용 `user?.name`

### [2026-01-05] API 인증 실패
- 문제: 토큰 만료 처리 누락
- 해결: 401 응답 시 자동 갱신 로직 추가

## 코딩 컨벤션
- 파일명: kebab-case
- 컴포넌트: PascalCase
- 함수: camelCase
- 최대 파일 크기: 300줄

## MCP 서버 설정
- Slack: 알림 전송
- BigQuery: 로그 분석
- Sentry: 에러 추적
```

**Git 체크인:**
```bash
git add CLAUDE.md
git commit -m "Update CLAUDE.md: Add API auth error solution"
git push
```

**효과:**
- ✅ 같은 오류 반복 방지
- ✅ 신입 팀원 온보딩 가속화
- ✅ 컨텍스트 자동 공유

#### 3. Plan → Auto-Accept 패턴

```bash
# 1단계: Plan 모드 (Shift+Tab 두 번)
# - 충분히 계획 수립
# - 아키텍처 검토
# - 예상 파일 구조 확인

# 2단계: Auto-Accept 모드 전환
# - 1-shot으로 완성
# - 중간 승인 없이 실행
```

**장점:**
- 계획 단계에서 큰 그림 확보
- 실행 단계에서 빠른 속도
- 반복 작업 최소화

#### 4. MCP 서버 통합

**Slack 통합:**
```javascript
// PreToolUse hook
async function notifyTeam(tool, args) {
  if (tool === 'deploy') {
    await slack.sendMessage({
      channel: '#deployments',
      text: `🚀 Deploying ${args.service} to production`
    })
  }
}
```

**BigQuery 로깅:**
```javascript
// PostToolUse hook
async function logQuery(tool, result) {
  await bigquery.insert('claude_usage', {
    tool: tool,
    timestamp: Date.now(),
    success: result.success
  })
}
```

**Sentry 에러 추적:**
```javascript
// 에러 발생 시 자동 이슈 생성
try {
  await deployService()
} catch (error) {
  await sentry.captureException(error)
  await claude.addToContext(error.stack)
}
```

#### 5. 검증 서브에이전트

**code-simplifier:**
```markdown
---
name: code-simplifier
---
# 리뷰 체크리스트
- [ ] 함수 300줄 이하
- [ ] 중복 코드 없음
- [ ] 타입 안전성
- [ ] 테스트 커버리지 80% 이상
```

**verify-app:**
```bash
#!/bin/bash
# 자동 검증 스크립트
npm run test
npm run lint
npm run build
npm run e2e
```

**PostToolUse 훅:**
```json
{
  "postToolUse": {
    "Write": "prettier --write {file_path}",
    "Edit": "eslint --fix {file_path}"
  }
}
```

### TeamOrchestrator 사용 예시

```bash
# 시나리오 1: 새 기능 개발
/auto "TeamOrchestrator로 사용자 인증 시스템 구축해줘"

# 출력:
# 📋 Team Workflow 시작
# 1. CLAUDE.md 읽기... ✓
# 2. Plan 모드로 아키텍처 설계... ✓
# 3. 5개 세션 병렬 실행:
#    - Session 1: 프론트엔드 (React 컴포넌트)
#    - Session 2: 백엔드 (Express API)
#    - Session 3: 데이터베이스 (Migration)
#    - Session 4: 테스트 (Jest + Playwright)
#    - Session 5: 문서화 (README + API docs)
# 4. 검증 루프 실행... ✓
# 5. Slack 알림 전송... ✓
```

```bash
# 시나리오 2: 버그 수정 + 리팩토링
/auto "TeamOrchestrator로 성능 이슈 해결하고 코드 정리해줘"

# 병렬 실행:
# - Session A: 프로파일링 & 병목 지점 분석
# - Session B: 최적화 적용
# - Session C: 불필요한 코드 제거
# - Session D: 테스트 업데이트
```

---

## 📱 서브에이전트 2: MobileDeveloper

**대상:** 이동 중에도 개발하고 싶은 개발자
**출처:** Claude Code On-The-Go

### 핵심 인프라

#### 1. 클라우드 개발 환경

**Vultr VM 설정:**
```bash
# 비용: 시간당 $0.29 (일일 약 $7)
# 스펙: 4 vCPU, 8GB RAM, 160GB SSD

# 초기 설정
apt update && apt upgrade -y
apt install -y build-essential git curl tmux zsh mosh

# Claude Code 설치
npm install -g @anthropic-ai/claude-code
```

**Tailscale VPN:**
```bash
# 설치
curl -fsSL https://tailscale.com/install.sh | sh

# 시작
tailscale up

# SSH 비공개 (Tailscale IP만 허용)
ufw allow from 100.64.0.0/10 to any port 22
ufw deny 22
```

**보안 구성:**
```bash
# 다층 보안
1. Tailscale 전용 접근
2. 클라우드 방화벽
3. nftables
4. fail2ban

# fail2ban 설정
apt install -y fail2ban
systemctl enable fail2ban
```

#### 2. 모바일 접근 스택

**Termius 앱 (iOS/Android):**
- SSH + mosh 지원
- 스니펫 관리
- 포트 포워딩
- SFTP 파일 전송

**mosh (Mobile Shell):**
```bash
# 서버에서
apt install -y mosh

# 클라이언트에서 (Termius 통해)
mosh user@tailscale-ip

# 장점:
# - Wi-Fi ↔ 셀룰러 전환 시에도 세션 유지
# - 절전 모드에서도 세션 지속
# - 로컬 에코로 반응성 향상
```

#### 3. tmux 세션 관리

**.zshrc 자동 설정:**
```bash
# 자동 tmux 연결
if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
  tmux attach -t claude || tmux new -s claude
fi
```

**여러 Claude 에이전트 병렬 실행:**
```bash
# tmux 세션 생성
tmux new -s claude

# 창 분할
Ctrl+b %  # 세로 분할
Ctrl+b "  # 가로 분할

# 각 창에서 Claude Code 실행
# 창 1: 프론트엔드 개발
claude-code --context frontend/

# 창 2: 백엔드 API
claude-code --context backend/

# 창 3: 인프라 스크립트
claude-code --context infra/

# 창 4: 테스트 실행
claude-code --context tests/

# 창 5: 문서 작성
claude-code --context docs/

# 창 6: 모니터링
htop
```

**창 전환:**
```bash
Ctrl+b 0-9  # 창 번호로 이동
Ctrl+b n    # 다음 창
Ctrl+b p    # 이전 창
Ctrl+b w    # 창 목록
```

#### 4. 비동기 개발 루프

**Poke 웹훅 알림:**
```javascript
// PreToolUse hook: AskUserQuestion 시 알림
// ~/.claude/hooks/pre-tool-use.js
const https = require('https')

module.exports = async (tool, args) => {
  if (tool === 'AskUserQuestion') {
    // Poke 웹훅으로 푸시 알림 전송
    const data = JSON.stringify({
      message: '🔔 Claude가 입력을 기다리고 있습니다',
      question: args.questions[0].question
    })

    const options = {
      hostname: 'api.poke.com',
      path: '/push',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': data.length
      }
    }

    const req = https.request(options)
    req.write(data)
    req.end()
  }
}
```

**활용 시나리오:**
```
1. 커피숍에서 Claude에게 작업 요청
2. 스마트폰 잠금
3. 커피 대기하며 다른 일
4. 📱 알림: "Claude가 입력 대기 중"
5. 폰 열고 답변 입력
6. 다시 잠금
7. 반복...
```

#### 5. Git Worktree 병렬 개발

**브랜치별 독립 작업 공간:**
```bash
# 메인 저장소
cd ~/projects/myapp

# Worktree 생성
git worktree add ../myapp-feature-auth feature/auth
git worktree add ../myapp-bugfix-login bugfix/login
git worktree add ../myapp-refactor refactor/api

# 각 디렉토리에서 독립적으로 작업
cd ../myapp-feature-auth
npm run dev  # 포트: 3000

cd ../myapp-bugfix-login
npm run dev  # 포트: 3001

cd ../myapp-refactor
npm run dev  # 포트: 3002
```

**포트 자동 할당:**
```javascript
// package.json
{
  "scripts": {
    "dev": "node -e \"const hash = require('crypto').createHash('md5').update(process.cwd()).digest('hex'); const port = 3000 + parseInt(hash.slice(0, 4), 16) % 1000; require('child_process').exec(`PORT=${port} vite`);\""
  }
}
```

#### 6. 보안 격리 모델

```bash
# VM은 격리됨
- 프로덕션 접근 불가
- 개발 환경만 접근 가능
- 비용 제어로 리스크 최소화

# Claude Code permissive 모드
claude-code --security-mode permissive

# 하지만 VM이 격리되어 있어 안전함
```

### MobileDeveloper 사용 예시

```bash
# 시나리오 1: 출퇴근 중 개발
/auto "MobileDeveloper로 Vultr VM 개발 환경 설정해줘"

# 출력:
# 📱 Mobile Development Setup
# 1. Vultr VM 프로비저닝... ✓
# 2. Tailscale VPN 설정... ✓
# 3. tmux + zsh 설치... ✓
# 4. Claude Code 설치... ✓
# 5. Poke 웹훅 설정... ✓
#
# 🎉 준비 완료!
# Termius에서 연결: mosh user@100.64.x.x
```

```bash
# 시나리오 2: PR 리뷰
/auto "MobileDeveloper로 PR #42 리뷰해줘"

# 비동기 작업:
# 1. Claude가 코드 분석 시작
# 2. 🔔 알림: "리뷰 완료, 3개 이슈 발견"
# 3. 스마트폰에서 확인하고 답변
# 4. Claude가 수정 적용
# 5. 🔔 알림: "수정 완료, 푸시 대기"
# 6. 승인하고 푸시
```

---

## 🎨 서브에이전트 3: VibeCoder

**대상:** 비개발자, 바이브 코딩하는 사람
**출처:** 우탄 (영상 제작회사 '한줄' 기술이사)

### 바이브 코딩 6계명

#### 1. 바퀴 재발명 금지

**원칙:**
기존 오픈소스를 최대한 활용하고, 리버스 엔지니어링으로 학습합니다.

**실천:**
```bash
# ❌ 나쁜 예
/auto "JWT 인증 시스템을 처음부터 만들어줘"

# ✅ 좋은 예
/auto "Supabase Auth 예제 찾아서 내 프로젝트에 적용해줘"

# ✅ 더 좋은 예
/auto "passport.js 예제 분석하고 우리 스택에 맞게 커스터마이즈해줘"
```

**효과:**
- 검증된 코드 활용
- 학습 곡선 단축
- 보안 이슈 최소화

#### 2. 1,500줄 제한

**원칙:**
파일 크기를 1,500줄 이하로 제한하여 Claude의 맥락 유지 능력을 최대화합니다.

**실천:**
```bash
# 파일 크기 확인
wc -l src/services/userService.js
# 출력: 2341 src/services/userService.js (❌ 너무 큼!)

# 분할 요청
/auto "userService.js를 기능별로 3개 파일로 분할해줘 (각 500줄 이하)"

# 결과:
# - userAuth.js (487줄) ✓
# - userProfile.js (521줄) ✓
# - userPermissions.js (398줄) ✓
```

**파일 구조 예시:**
```
src/
├── services/
│   ├── user/
│   │   ├── auth.js          (인증 로직, 450줄)
│   │   ├── profile.js       (프로필 관리, 380줄)
│   │   ├── permissions.js   (권한 관리, 290줄)
│   │   └── index.js         (re-export, 20줄)
```

#### 3. SSoT & DRY 원칙

**SSoT (Single Source of Truth):**
```javascript
// ❌ 나쁜 예: 여러 곳에 중복
// components/Header.jsx
const API_URL = 'https://api.example.com'

// components/Dashboard.jsx
const API_URL = 'https://api.example.com'

// ✅ 좋은 예: 한 곳에서 관리
// config/constants.js
export const API_URL = process.env.VITE_API_URL || 'https://api.example.com'

// 모든 컴포넌트에서
import { API_URL } from '@/config/constants'
```

**DRY (Don't Repeat Yourself):**
```javascript
// ❌ 나쁜 예: 중복 로직
function validateEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
}

function validateEmailInForm(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
}

// ✅ 좋은 예: 재사용 가능한 유틸
// utils/validators.js
export const validators = {
  email: (v) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v),
  phone: (v) => /^\d{10,11}$/.test(v),
  url: (v) => /^https?:\/\/.+/.test(v)
}
```

**효과:**
- AI가 수정할 때 일관성 유지
- 버그 발생 시 한 곳만 수정
- 유지보수성 향상

#### 4. 백업과 교차 검증

**자동 백업:**
```bash
# PreToolUse hook: 파일 수정 전 백업
# ~/.claude/hooks/pre-tool-use.js
const fs = require('fs')
const path = require('path')

module.exports = async (tool, args) => {
  if (tool === 'Edit' || tool === 'Write') {
    const filePath = args.file_path
    if (fs.existsSync(filePath)) {
      const backupPath = `${filePath}.bak`
      fs.copyFileSync(filePath, backupPath)
      console.log(`✓ Backup created: ${backupPath}`)
    }
  }
}
```

**교차 검증:**
```bash
# Claude로 구현 후
/auto "userAuth.js 구현해줘"

# ChatGPT로 검증
"이 코드를 리뷰해줘: [코드 붙여넣기]"

# Gemini로 재검증
"보안 취약점 있는지 확인해줘: [코드 붙여넣기]"

# 발견된 이슈를 Claude에게 다시 전달
/auto "ChatGPT가 발견한 이슈 수정해줘: [이슈 목록]"
```

#### 5. 구조화된 명명규칙

**[도메인]-[대상]-[동작] 패턴:**

```javascript
// ✅ 좋은 예
// API
export async function user_auth_login(credentials) {}
export async function user_auth_logout() {}
export async function user_profile_update(data) {}
export async function user_profile_delete(userId) {}

// 컴포넌트
function UserAuth_LoginForm() {}
function UserAuth_RegisterForm() {}
function UserProfile_EditModal() {}
function UserProfile_AvatarUpload() {}

// 파일명
user-auth-service.js
user-profile-service.js
video-encoding-worker.js
video-upload-handler.js
```

**장점:**
```bash
# 디버깅 시 검색 쉬움
grep "user_auth" -r src/
grep "video_encoding" -r src/

# Claude에게 요청 시 명확함
/auto "user_profile_update 함수 리팩토링해줘"
/auto "video_encoding_worker에 에러 핸들링 추가해줘"
```

#### 6. 테스트 페이지 활용

**구조:**
```
src/
├── pages/
│   ├── Home.jsx
│   ├── Dashboard.jsx
│   └── test/              ← 테스트 전용 디렉토리
│       ├── TestAuth.jsx
│       ├── TestUpload.jsx
│       └── TestAPI.jsx
```

**라우팅:**
```javascript
// App.jsx
import { TestAuth, TestUpload, TestAPI } from './pages/test'

const routes = [
  { path: '/', element: <Home /> },
  { path: '/dashboard', element: <Dashboard /> },

  // 테스트 페이지 (개발 환경만)
  ...(import.meta.env.DEV ? [
    { path: '/test/auth', element: <TestAuth /> },
    { path: '/test/upload', element: <TestUpload /> },
    { path: '/test/api', element: <TestAPI /> }
  ] : [])
]
```

**테스트 페이지 예시:**
```jsx
// src/pages/test/TestUpload.jsx
export default function TestUpload() {
  const [file, setFile] = useState(null)
  const [result, setResult] = useState(null)

  const handleUpload = async () => {
    const formData = new FormData()
    formData.append('file', file)

    const res = await fetch('/api/upload', {
      method: 'POST',
      body: formData
    })

    setResult(await res.json())
  }

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-4">Upload Test</h1>

      <input
        type="file"
        onChange={(e) => setFile(e.target.files[0])}
        className="mb-4"
      />

      <button
        onClick={handleUpload}
        className="bg-blue-500 text-white px-4 py-2 rounded"
      >
        Upload
      </button>

      {result && (
        <pre className="mt-4 p-4 bg-gray-100 rounded">
          {JSON.stringify(result, null, 2)}
        </pre>
      )}
    </div>
  )
}
```

**워크플로우:**
```bash
# 1. 테스트 페이지에서 실험
/auto "/test/upload 페이지에서 이미지 업로드 기능 구현해줘"

# 2. 테스트 페이지에서 검증
# - 다양한 파일 형식 테스트
# - 에러 케이스 확인
# - 성능 측정

# 3. 완성 후 메인에 통합
/auto "TestUpload.jsx의 업로드 로직을 Dashboard.jsx에 통합해줘"
```

### 실전 사례

#### 사례 1: Google Sheets 자동화

**요구사항:**
- 매월 1일 자동 이월
- 견적서 생성 버튼
- 고객 이메일 자동 작성

**구현:**
```javascript
// Google Apps Script
function onMonthChange() {
  const sheet = SpreadsheetApp.getActiveSheet()
  const lastRow = sheet.getLastRow()

  // 이월 로직
  const data = sheet.getRange(2, 1, lastRow - 1, 10).getValues()
  const carryOver = data.filter(row => row[9] === '미완료')

  // 새 시트 생성
  const newSheet = SpreadsheetApp.create(`${new Date().getMonth() + 1}월`)
  newSheet.getRange(1, 1, carryOver.length, 10).setValues(carryOver)
}

function generateQuote() {
  const sheet = SpreadsheetApp.getActiveSheet()
  const row = sheet.getActiveRange().getRow()
  const data = sheet.getRange(row, 1, 1, 10).getValues()[0]

  // 견적서 생성
  const doc = DocumentApp.create(`견적서_${data[0]}`)
  const body = doc.getBody()
  body.appendParagraph(`고객명: ${data[1]}`)
  body.appendParagraph(`프로젝트: ${data[2]}`)
  body.appendParagraph(`금액: ${data[3]}원`)

  // 이메일 초안 작성
  GmailApp.createDraft(
    data[4], // 이메일 주소
    `[견적서] ${data[2]}`,
    `안녕하세요.\n\n견적서를 첨부드립니다.\n\n${doc.getUrl()}`
  )
}
```

**바이브 코딩 프로세스:**
```bash
/auto "VibeCoder로 Google Sheets 자동화 구현해줘"

# Claude가:
# 1. Apps Script 예제 검색 (바퀴 재발명 X)
# 2. 기능별로 함수 분리 (1,500줄 제한)
# 3. 설정값은 별도 파일로 (SSoT)
# 4. .bak 파일 자동 생성 (백업)
# 5. 함수명: sheets_quote_generate (명명규칙)
# 6. /test 시트에서 테스트 후 메인 적용
```

#### 사례 2: NFD-NFC 파일명 변환

**문제:**
Mac(NFD)과 Windows(NFC) 간 한글 파일명 호환성

**구현:**
```javascript
// utils/filename-normalizer.js
const { normalize } = require('path')

/**
 * Mac NFD → Windows NFC 변환
 * 예: "한글.mp4" (NFD) → "한글.mp4" (NFC)
 */
function nfd_to_nfc(filename) {
  // NFD: 한글을 자음+모음으로 분해
  // NFC: 한글을 완성형으로 결합
  return filename.normalize('NFC')
}

function nfc_to_nfd(filename) {
  return filename.normalize('NFD')
}

/**
 * 프리미어 프로 프로젝트 파일의 모든 파일 경로 변환
 */
async function premiere_project_normalize(projectPath) {
  const fs = require('fs').promises
  const xml = await fs.readFile(projectPath, 'utf-8')

  // XML 파싱하여 모든 파일 경로 추출
  const regex = /<pathurl>(.*?)<\/pathurl>/g
  const normalized = xml.replace(regex, (match, path) => {
    const newPath = nfd_to_nfc(path)
    return `<pathurl>${newPath}</pathurl>`
  })

  // 백업 생성
  await fs.copyFile(projectPath, `${projectPath}.bak`)

  // 변환된 내용 저장
  await fs.writeFile(projectPath, normalized)

  console.log(`✓ Normalized: ${projectPath}`)
}

module.exports = { nfd_to_nfc, nfc_to_nfd, premiere_project_normalize }
```

**도구화:**
```bash
# CLI 도구로 만들기
/auto "VibeCoder로 NFD-NFC 변환 CLI 도구 만들어줘"

# 결과:
# npx nfc-converter myproject.prproj
# ✓ 158개 파일 경로 변환 완료
```

#### 사례 3: txt2srt 자막 생성기

**요구사항:**
- 텍스트 파일 → SRT 자막 변환
- 타임코드 자동 계산
- 드롭프레임 지원

**Ticks 변환 로직:**
```javascript
// utils/timecode-converter.js

/**
 * 프리미어 프로 Ticks → 밀리초 변환
 * 1초 = 254,016,000,000 ticks (29.97 drop frame)
 */
function ticks_to_milliseconds(ticks, fps = 29.97, dropFrame = true) {
  const ticksPerSecond = dropFrame
    ? 254016000000  // 29.97 DF
    : 254000000000  // 30 NDF

  const seconds = ticks / ticksPerSecond
  return Math.round(seconds * 1000)
}

/**
 * 밀리초 → SRT 타임코드 변환
 * 예: 65432 → "00:01:05,432"
 */
function ms_to_srt_timecode(ms) {
  const hours = Math.floor(ms / 3600000)
  const minutes = Math.floor((ms % 3600000) / 60000)
  const seconds = Math.floor((ms % 60000) / 1000)
  const milliseconds = ms % 1000

  return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')},${String(milliseconds).padStart(3, '0')}`
}

/**
 * TXT → SRT 변환
 */
async function txt_to_srt(txtPath, outputPath) {
  const fs = require('fs').promises
  const content = await fs.readFile(txtPath, 'utf-8')
  const lines = content.split('\n').filter(l => l.trim())

  let srt = ''
  let index = 1
  let currentTime = 0
  const durationPerLine = 3000 // 3초

  for (const line of lines) {
    const start = ms_to_srt_timecode(currentTime)
    const end = ms_to_srt_timecode(currentTime + durationPerLine)

    srt += `${index}\n`
    srt += `${start} --> ${end}\n`
    srt += `${line.trim()}\n\n`

    index++
    currentTime += durationPerLine
  }

  await fs.writeFile(outputPath, srt, 'utf-8')
  console.log(`✓ Generated: ${outputPath}`)
}

module.exports = { ticks_to_milliseconds, ms_to_srt_timecode, txt_to_srt }
```

**실적:**
- 170일간 590,000개 자막 생성
- 수백 시간 작업을 분 단위로 단축

### 보안 구현 전략

#### 1. 인증 위임 (Supabase Auth)

```javascript
// ❌ 나쁜 예: 직접 구현
async function customLogin(email, password) {
  // JWT 생성, 해시, 세션 관리 등...
  // 보안 취약점 발생 가능
}

// ✅ 좋은 예: 검증된 서비스 사용
import { supabase } from './supabase'

async function auth_user_login(email, password) {
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password
  })

  if (error) throw error
  return data.user
}

// OAuth도 쉽게
async function auth_google_login() {
  await supabase.auth.signInWithOAuth({
    provider: 'google'
  })
}
```

#### 2. RLS (Row Level Security)

```sql
-- Supabase에서 자동 권한 제어
-- users 테이블
CREATE POLICY "Users can only see their own data"
  ON users FOR SELECT
  USING (auth.uid() = id);

-- projects 테이블
CREATE POLICY "Users can only edit their projects"
  ON projects FOR UPDATE
  USING (auth.uid() = owner_id);
```

**효과:**
- ✅ 백엔드 코드 없이 권한 제어
- ✅ SQL Injection 원천 차단
- ✅ 실수로 다른 사용자 데이터 노출 불가

#### 3. 스토리지 보안

**버킷 분리:**
```javascript
// public: 프로필 이미지, 로고
// private: 업무 파일, 견적서
// internal: 관리자 전용

// 업로드 시 파일명 해싱
async function storage_file_upload(file, bucket) {
  const hash = crypto.randomBytes(16).toString('hex')
  const ext = file.name.split('.').pop()
  const filename = `${hash}.${ext}`

  const { data, error } = await supabase.storage
    .from(bucket)
    .upload(filename, file)

  if (error) throw error
  return data.path
}

// 다운로드는 프록시 API 필수
async function storage_file_download(path) {
  // ❌ 직접 URL 노출
  // return `https://bucket.supabase.co/${path}`

  // ✅ 서버 API 경유
  return `/api/download?file=${encodeURIComponent(path)}`
}
```

**API 프록시:**
```javascript
// api/download.js
export default async function handler(req, res) {
  const { file } = req.query
  const userId = req.session.userId

  // 권한 확인
  const fileOwner = await db.query(
    'SELECT owner_id FROM files WHERE path = $1',
    [file]
  )

  if (fileOwner.owner_id !== userId) {
    return res.status(403).json({ error: 'Forbidden' })
  }

  // Supabase에서 파일 가져오기
  const { data } = await supabase.storage
    .from('private')
    .download(file)

  res.setHeader('Content-Type', 'application/octet-stream')
  res.send(data)
}
```

#### 4. Dual-Client 패턴

**민감한 데이터는 서버에서만 처리:**

```javascript
// ❌ 나쁜 예: 클라이언트에서 API 키 사용
// frontend/src/utils/payment.js
const STRIPE_SECRET_KEY = 'sk_live_xxx' // 노출됨!

// ✅ 좋은 예: 서버 API로 위임
// frontend/src/utils/payment.js
async function payment_create_charge(amount) {
  const response = await fetch('/api/payment/charge', {
    method: 'POST',
    body: JSON.stringify({ amount }),
    headers: { 'Content-Type': 'application/json' }
  })

  return await response.json()
}

// backend/api/payment/charge.js
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY)

export default async function handler(req, res) {
  const { amount } = req.body
  const userId = req.session.userId

  // 서버에서만 Stripe API 호출
  const charge = await stripe.charges.create({
    amount,
    currency: 'krw',
    customer: userId
  })

  res.json({ success: true, chargeId: charge.id })
}
```

#### 5. 정기 보안 검토

```bash
# Claude에게 정기 보안 검토 요청
/auto "VibeCoder로 전체 프로젝트 보안 검토해줘"

# Claude가 체크하는 항목:
# - 환경변수 하드코딩 여부
# - API 키 노출 여부
# - SQL Injection 취약점
# - XSS 가능성
# - CORS 설정
# - 인증/권한 누락
# - 민감 데이터 로그 출력
```

**보안 체크리스트:**
```markdown
## 보안 체크리스트

### 인증/권한
- [ ] 모든 API 엔드포인트에 인증 필요
- [ ] 권한 검증 (사용자별)
- [ ] 세션 타임아웃 설정

### 데이터 보호
- [ ] 비밀번호 해싱 (bcrypt)
- [ ] 민감 데이터 암호화
- [ ] HTTPS 강제

### 입력 검증
- [ ] SQL Injection 방어
- [ ] XSS 방어 (입력 sanitize)
- [ ] CSRF 토큰

### API 보안
- [ ] Rate limiting
- [ ] API 키는 서버에만
- [ ] CORS 화이트리스트

### 파일 업로드
- [ ] 파일 형식 검증
- [ ] 크기 제한
- [ ] 바이러스 스캔
- [ ] 파일명 해싱
```

### VibeCoder 사용 예시

```bash
# 시나리오 1: Google Sheets 자동화
/auto "VibeCoder로 매월 자동 이월되는 견적 관리 시트 만들어줘"

# 출력:
# 🎨 Vibe Coding 시작
#
# ✓ Apps Script 예제 검색... (바퀴 재발명 X)
# ✓ 기능 분리: onMonthChange, generateQuote, sendEmail
# ✓ 설정 파일 분리: config.js (SSoT)
# ✓ 백업 생성: Code.gs.bak
# ✓ 명명규칙 적용: sheets_quote_generate
# ✓ 테스트 시트에서 검증 완료
#
# 📋 6계명 준수율: 100%
```

```bash
# 시나리오 2: 전체 프로젝트 보안 강화
/auto "VibeCoder로 Supabase Auth + RLS 보안 시스템 구축해줘"

# 출력:
# 🔒 보안 구현 시작
#
# 1. 인증 (Supabase Auth)
#    ✓ Google OAuth 설정
#    ✓ 세션 관리
#
# 2. 데이터 보호 (RLS)
#    ✓ users 테이블 정책
#    ✓ projects 테이블 정책
#
# 3. 스토리지 보안
#    ✓ 버킷 분리 (public/private)
#    ✓ 파일명 해싱
#    ✓ 프록시 API (/api/download)
#
# 4. Dual-Client 패턴
#    ✓ 결제 API 서버 이전
#    ✓ 이메일 전송 서버 이전
#
# 5. 보안 체크리스트 생성
#    ✓ SECURITY.md 생성
#
# 🎉 보안 강화 완료!
```

```bash
# 시나리오 3: 1,500줄 넘는 파일 리팩토링
/auto "VibeCoder로 userService.js(2341줄) 리팩토링해줘"

# 출력:
# 📝 파일 분할 시작
#
# 원본: userService.js (2341줄) ❌
#
# 분할 결과:
# ✓ user-auth.js (487줄) - 인증 로직
# ✓ user-profile.js (521줄) - 프로필 관리
# ✓ user-permissions.js (398줄) - 권한 관리
# ✓ user-notifications.js (312줄) - 알림
# ✓ index.js (23줄) - re-export
#
# 백업: userService.js.bak
#
# ✅ 1,500줄 제한 준수!
```

---

## 🎯 통합 사용 가이드

### 상황별 서브에이전트 선택

| 상황 | 서브에이전트 | 이유 |
|------|-------------|------|
| 팀 프로젝트 개발 | TeamOrchestrator | CLAUDE.md 공유, MCP 통합 |
| 출퇴근 중 개발 | MobileDeveloper | 모바일 환경, 비동기 작업 |
| 자동화 도구 개발 (비개발자) | VibeCoder | 6계명, 점진적 개선 |
| 여러 기능 동시 개발 | TeamOrchestrator + MobileDeveloper | 병렬 실행 극대화 |
| 프로토타입 빠르게 만들기 | VibeCoder | 바퀴 재발명 X, 테스트 페이지 |
| 레거시 코드 리팩토링 | VibeCoder | 1,500줄 제한, SSoT |
| 보안 강화 | VibeCoder | Supabase, RLS, Dual-Client |

### 조합 사용 예시

```bash
# 조합 1: 팀 + 모바일
/auto "TeamOrchestrator와 MobileDeveloper 조합으로 출장 중에도 팀 프로젝트 개발할 환경 만들어줘"

# 결과:
# - Vultr VM에 팀 CLAUDE.md 동기화
# - tmux에서 5개 세션 병렬 실행
# - Poke 웹훅으로 알림
# - Git worktree로 다중 브랜치
```

```bash
# 조합 2: 팀 + 바이브코딩
/auto "TeamOrchestrator와 VibeCoder 조합으로 비개발자도 팀 협업 가능하게 만들어줘"

# 결과:
# - CLAUDE.md에 바이브 코딩 6계명 추가
# - 1,500줄 제한 규칙 강제
# - 백업 자동화
# - 테스트 페이지 구조
```

```bash
# 조합 3: 모바일 + 바이브코딩
/auto "MobileDeveloper와 VibeCoder 조합으로 스마트폰에서 간단한 자동화 도구 만들어줘"

# 결과:
# - Termius에서 바로 실행 가능
# - 파일 크기 작게 유지
# - 테스트 쉽게
# - 백업 자동
```

---

## 💡 핵심 Takeaways

### 1. 병렬 실행 = 10배 생산성
```
1개 세션: 1시간
5개 세션 병렬: 12분
10개 세션 병렬: 6분
```

### 2. 검증 루프 = 2-3배 품질
```
검증 없음: 30% 정확도
검증 있음: 90% 정확도
```

### 3. 지식 축적 = 반복 오류 제로
```
CLAUDE.md 없음: 같은 오류 반복
CLAUDE.md 있음: 학습 누적
```

### 4. 비개발자도 가능
```
바이브 코딩 6계명
+ Claude Code
= 전문 개발자급 결과물
```

---

## 📚 참고 자료

- Boris Cherny 워크플로우: [Hacker News 토픽 #25570]
- Claude Code On-The-Go: [Hacker News 토픽 #25578]
- 바이브 코딩 가이드: [요즘IT - 비개발자가 클로드 코드로 업무 생산성 10배]

---

## 🎯 빠른 시작

```bash
# 팀 협업 환경
/auto "TeamOrchestrator로 우리 팀 개발 환경 설정해줘"

# 모바일 개발 환경
/auto "MobileDeveloper로 스마트폰 개발 환경 만들어줘"

# 바이브 코딩 시작
/auto "VibeCoder로 Google Sheets 자동화 만들어줘"

# 전체 분석
/auto "우리 프로젝트에 어떤 서브에이전트가 적합한지 분석해줘"
```

---

**이 스킬로 당신의 Claude Code 생산성을 10배 이상 높이세요!** 🚀
