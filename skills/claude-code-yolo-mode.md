---
name: claude-code-yolo-mode
description: YOLO모드, 자동실행, 무인작업, 에이전트자동화, 확인없이실행, 병렬처리필수, 100개에이전트, 빠른개발, 완전자동화, 사용자개입최소화, 대량작업, 배치처리, 설정방법, 안전사용으로 Claude Code의 YOLO 모드를 활용한 완전 자동화 실행 스킬
---

# claude-code-yolo-mode

## Overview

**YOLO (You Only Look Once) 모드**는 Claude Code의 가장 강력한 자동화 기능입니다. 에이전트가 **사용자 확인 없이** 작업을 진행하여, 100개~1000개의 에이전트를 동시에 돌릴 때 **필수적인 모드**입니다.

### YOLO 모드란?

일반 모드에서는:
```
에이전트: "파일을 생성하겠습니다. 계속할까요?"
사용자: "네" (클릭)
에이전트: "다음 파일을 생성하겠습니다. 계속할까요?"
사용자: "네" (클릭)
...
(100번 반복 😫)
```

YOLO 모드에서는:
```
에이전트: 파일 1 생성 ✅
에이전트: 파일 2 생성 ✅
에이전트: 파일 3 생성 ✅
...
에이전트: 파일 100 생성 ✅
(사용자 개입 0번! 🎉)
```

**효과:**
- ⚡ 100개 작업 → 사용자 확인 100번 → 0번
- ⚡ 10시간 걸릴 작업 → 1시간
- ⚡ 완전 자동화 → 밤새 작업 가능

## When to Use This Skill

### ✅ YOLO 모드를 사용하세요:

- **대량 작업**: 100개 이상의 파일/작업 생성
- **병렬 에이전트**: 여러 에이전트 동시 실행
- **반복 작업**: 동일한 패턴 반복
- **야간 작업**: 자는 동안 작업 완료
- **배치 처리**: 대량 데이터 처리
- **긴급 상황**: 빠른 완료 필요

### ⚠️ YOLO 모드를 끄세요:

- **중요한 파일**: 잘못 수정하면 복구 어려움
- **처음 시도**: 새로운 작업 테스트
- **학습 목적**: 과정을 지켜보며 배우기
- **프로덕션 코드**: 신중한 검토 필요
- **보안 민감**: 인증 정보, 비밀키 다룰 때

### 🔀 상황별 사용:

- 테스트/개발: YOLO ON
- 프로덕션 배포: YOLO OFF
- 대량 스킬 생성: YOLO ON
- 중요 버그 수정: YOLO OFF

## Prerequisites

- Claude Code 설치 (최신 버전)
- 기본 에이전트 사용 경험
- Task tool 이해
- Git 사용 (되돌리기 위해)

## Instructions

### Step 1: YOLO 모드 활성화

**방법 1: Settings에서 켜기 (추천)**

```bash
# Claude Code에서
1. Settings 열기 (Cmd/Ctrl + ,)
2. "YOLO" 검색
3. "Agent Auto-Approve" 또는 "YOLO Mode" 찾기
4. 체크박스 활성화

또는

# settings.json 직접 수정
{
  "claudeCode.agents.autoApprove": true,
  "claudeCode.agents.yoloMode": true
}
```

**방법 2: Task tool 파라미터로 켜기**

```javascript
await Task({
  subagent_type: "general-purpose",
  description: "Create 100 files",
  prompt: "Generate 100 test files",
  auto_approve: true  // 🔑 이 Task만 YOLO 모드
});
```

**방법 3: 환경 변수로 켜기**

```bash
# .env 파일
CLAUDE_CODE_YOLO_MODE=true
```

### Step 2: 안전장치 설정

YOLO 모드를 켜되, 안전장치를 함께 설정합니다.

#### 2.1 Git 커밋 전 스냅샷

```bash
# 작업 전 현재 상태 저장
git add .
git commit -m "Pre-YOLO snapshot"

# 또는 branch 생성
git checkout -b yolo-experiment

# 이제 YOLO 모드 실행
# 문제 생기면:
git checkout main  # 원래 branch로 돌아가기
```

#### 2.2 백업 폴더 생성

```bash
# 중요 파일 백업
cp -r src src_backup
cp -r config config_backup

# YOLO 작업 실행

# 복구 필요시:
rm -rf src
mv src_backup src
```

#### 2.3 제한 시간 설정

```javascript
// Task에 timeout 설정
await Task({
  subagent_type: "general-purpose",
  description: "Long task",
  prompt: "...",
  auto_approve: true,
  timeout: 600000  // 🔑 10분 제한 (ms)
});
```

#### 2.4 작업 범위 제한

```javascript
// 특정 디렉토리만 허용
const safeTask = await Task({
  subagent_type: "general-purpose",
  description: "Generate files in /temp only",
  prompt: `
    Create 100 files.

    IMPORTANT: Only work in /temp directory.
    Do not touch /src or /config.
  `,
  auto_approve: true
});
```

### Step 3: YOLO 모드로 대량 작업 실행

#### 예시 1: 100개 테스트 파일 생성

```javascript
// YOLO 모드 ON
const result = await Task({
  subagent_type: "general-purpose",
  description: "Generate 100 test files",
  prompt: `
    Create 100 test files in /tests directory:
    - test-001.spec.ts
    - test-002.spec.ts
    ...
    - test-100.spec.ts

    Each file should test a different component.
  `,
  auto_approve: true  // YOLO!
});

console.log("100 files created automatically! 🎉");
```

#### 예시 2: 병렬 에이전트 100개 실행

```javascript
// 100개 에이전트 동시 실행 (YOLO 필수!)
const agents = [];

for (let i = 1; i <= 100; i++) {
  agents.push(
    Task({
      subagent_type: "general-purpose",
      description: `Create skill ${i}`,
      prompt: `Create skill file for topic ${i}`,
      auto_approve: true,  // 🔑 YOLO
      run_in_background: true
    })
  );
}

// 완료 대기
const results = await Promise.all(
  agents.map(a => TaskOutput({ task_id: a.id }))
);

console.log(`${results.length} skills created!`);
```

#### 예시 3: 야간 배치 작업

```javascript
// 저녁에 실행 → 아침에 완료
console.log("Starting overnight batch job...");
console.log("Current time:", new Date().toLocaleString());

const batchJob = await Task({
  subagent_type: "general-purpose",
  description: "Overnight data processing",
  prompt: `
    Process all 10,000 data files:
    1. Read CSV
    2. Transform data
    3. Generate reports
    4. Save to database

    Work continuously without asking.
  `,
  auto_approve: true,
  timeout: 28800000  // 8시간
});

console.log("Batch job completed!");
console.log("Completion time:", new Date().toLocaleString());
```

### Step 4: 진행 상황 모니터링

YOLO 모드에서도 진행 상황을 확인할 수 있습니다.

#### 4.1 로그 파일 생성

```javascript
const fs = require('fs');

const logStream = fs.createWriteStream('yolo-progress.log', { flags: 'a' });

// 에이전트에게 로깅 지시
await Task({
  subagent_type: "general-purpose",
  description: "Process with logging",
  prompt: `
    Process 100 items.

    After each 10 items, write progress to yolo-progress.log:
    "Completed 10/100 items at [timestamp]"
  `,
  auto_approve: true
});

// 로그 확인
console.log(fs.readFileSync('yolo-progress.log', 'utf-8'));
```

#### 4.2 중간 체크포인트

```javascript
// 10개씩 배치 처리
for (let batch = 0; batch < 10; batch++) {
  console.log(`Starting batch ${batch + 1}/10...`);

  await Task({
    subagent_type: "general-purpose",
    description: `Process batch ${batch + 1}`,
    prompt: `Process items ${batch * 10 + 1} to ${(batch + 1) * 10}`,
    auto_approve: true
  });

  console.log(`✅ Batch ${batch + 1} completed`);
}

console.log("All batches completed!");
```

#### 4.3 실시간 알림

```javascript
// Slack/Discord 알림
const notifySlack = async (message) => {
  await fetch('https://hooks.slack.com/...', {
    method: 'POST',
    body: JSON.stringify({ text: message })
  });
};

await notifySlack("🚀 YOLO batch job started");

await Task({
  subagent_type: "general-purpose",
  description: "Long task with notifications",
  prompt: "...",
  auto_approve: true
});

await notifySlack("✅ YOLO batch job completed!");
```

### Step 5: YOLO 모드 비활성화

작업 완료 후 반드시 끕니다.

```javascript
// Settings에서 끄기
// claudeCode.agents.autoApprove: false

// 또는 명시적으로
await Task({
  subagent_type: "general-purpose",
  description: "Important task",
  prompt: "...",
  auto_approve: false  // YOLO OFF
});
```

## Examples

### Example 1: YouTube 100개 스킬 생성 (YOLO 필수)

```javascript
// YOLO 모드 없으면: 100번 승인 필요
// YOLO 모드 있으면: 0번 승인

const youtubeUrls = [/* 100개 URL */];

const skills = youtubeUrls.map((url, i) =>
  Task({
    subagent_type: "general-purpose",
    description: `Generate skill from video ${i + 1}`,
    prompt: `Create skill from ${url}`,
    auto_approve: true,  // 🔑 YOLO
    run_in_background: true
  })
);

await Promise.all(skills.map(s => TaskOutput({ task_id: s.id })));

console.log("100 skills generated! 🎉");
```

### Example 2: 웹사이트 100개 크롤링

```javascript
const sites = [/* 100개 경쟁사 URL */];

const scrapeResults = await Promise.all(
  sites.map(site =>
    Task({
      subagent_type: "general-purpose",
      description: `Scrape ${site}`,
      prompt: `Crawl ${site} and extract pricing`,
      auto_approve: true,  // YOLO
      run_in_background: true
    })
  )
);

console.log("100 sites scraped!");
```

### Example 3: 다국어 번역 50개 언어

```javascript
const languages = [
  'ko', 'en', 'ja', 'zh', 'es', 'fr', 'de', ...  // 50개
];

const translations = await Promise.all(
  languages.map(lang =>
    Task({
      subagent_type: "general-purpose",
      description: `Translate to ${lang}`,
      prompt: `Translate app strings to ${lang}`,
      auto_approve: true,  // YOLO
      run_in_background: true
    })
  )
);

console.log("50 languages translated!");
```

### Example 4: 대규모 리팩토링

```javascript
// 100개 파일 동시 리팩토링
const files = [/* 100개 파일 경로 */];

// Git 스냅샷 먼저!
await execSync('git commit -am "Pre-refactor snapshot"');

const refactored = await Promise.all(
  files.map(file =>
    Task({
      subagent_type: "general-purpose",
      description: `Refactor ${file}`,
      prompt: `
        Refactor ${file}:
        - Convert to TypeScript
        - Add error handling
        - Optimize performance
      `,
      auto_approve: true,  // YOLO
      run_in_background: true
    })
  )
);

console.log("100 files refactored!");

// 테스트 실패하면:
// git reset --hard HEAD~1
```

## Key Concepts

- **Auto-Approve**: 에이전트가 자동으로 작업 승인
- **YOLO Mode**: "You Only Look Once" - 한 번만 보고 가는 모드
- **Unattended Execution**: 무인 실행
- **Batch Processing**: 배치 처리 자동화
- **Risk Management**: YOLO 사용 시 위험 관리
- **Rollback Strategy**: 되돌리기 전략

## Common Pitfalls

### 1. 백업 없이 YOLO 사용
```
❌ 위험:
YOLO 모드 ON → 중요 파일 삭제 → 복구 불가

✅ 해결:
git commit 먼저 → YOLO 실행 → 문제 생기면 git reset
```

### 2. 무제한 실행
```
❌ 위험:
timeout 없이 YOLO → 무한 루프 → 비용 폭발

✅ 해결:
timeout: 600000 (10분) 설정
```

### 3. 전역 YOLO 설정
```
❌ 위험:
Settings에서 YOLO 켜고 끄는 걸 잊음
→ 모든 작업이 자동 승인

✅ 해결:
Task별로 auto_approve: true 사용
Settings는 기본 OFF 유지
```

### 4. 에러 무시
```
❌ 위험:
YOLO로 100개 작업 → 50개 실패했는데 모름

✅ 해결:
try-catch로 에러 로깅
성공/실패 카운트
```

### 5. 프로덕션에서 YOLO
```
❌ 위험:
프로덕션 DB에 YOLO로 대량 작업
→ 데이터 손실

✅ 해결:
테스트 환경에서만 YOLO
프로덕션은 수동 승인
```

## Tips and Best Practices

### 안전한 YOLO 체크리스트

```markdown
YOLO 실행 전 체크:
- [ ] Git commit 완료 (되돌리기 가능)
- [ ] 백업 폴더 생성 (중요 파일)
- [ ] timeout 설정 (무한 실행 방지)
- [ ] 작업 범위 제한 (/temp만 등)
- [ ] 로깅 설정 (진행 상황 확인)
- [ ] 에러 핸들링 (try-catch)
- [ ] 테스트 환경 확인 (프로덕션 아님)
- [ ] 알림 설정 (완료/실패 알림)
```

### YOLO 모드 설정 레벨

**레벨 1: 안전 모드 (초보자)**
```javascript
{
  auto_approve: true,
  timeout: 300000,  // 5분
  working_directory: "/temp",
  max_files: 10
}
```

**레벨 2: 일반 모드 (중급자)**
```javascript
{
  auto_approve: true,
  timeout: 1800000,  // 30분
  max_files: 100
}
```

**레벨 3: 터보 모드 (고급자)**
```javascript
{
  auto_approve: true,
  timeout: 28800000,  // 8시간
  max_files: 1000,
  parallel: true
}
```

### 진행률 표시 패턴

```javascript
const total = 100;
let completed = 0;

const tasks = [];
for (let i = 0; i < total; i++) {
  tasks.push(
    Task({
      subagent_type: "general-purpose",
      description: `Task ${i + 1}`,
      prompt: "...",
      auto_approve: true,
      run_in_background: true
    }).then(result => {
      completed++;
      const progress = (completed / total * 100).toFixed(1);
      console.log(`Progress: ${progress}% (${completed}/${total})`);
      return result;
    })
  );
}

await Promise.all(tasks);
console.log("100% Complete! 🎉");
```

### 에러 복구 전략

```javascript
const results = {
  success: [],
  failed: []
};

for (let i = 0; i < 100; i++) {
  try {
    const result = await Task({
      subagent_type: "general-purpose",
      description: `Task ${i + 1}`,
      prompt: "...",
      auto_approve: true,
      timeout: 60000
    });

    results.success.push({ id: i, result });
  } catch (error) {
    results.failed.push({ id: i, error });
  }
}

console.log(`✅ Success: ${results.success.length}`);
console.log(`❌ Failed: ${results.failed.length}`);

// 실패한 것만 재시도
for (const failed of results.failed) {
  console.log(`Retrying task ${failed.id}...`);
  // 재시도 로직
}
```

## Performance Impact

| 작업 | YOLO OFF | YOLO ON | 시간 절약 |
|------|---------|---------|----------|
| 10개 작업 | 5분 | 30초 | **10배** |
| 100개 작업 | 50분 | 5분 | **10배** |
| 1000개 작업 | 8시간 | 1시간 | **8배** |

**병렬 + YOLO 조합:**
- 100개 순차: 8시간
- 100개 병렬 (YOLO OFF): 1시간 (승인 대기)
- 100개 병렬 (YOLO ON): **5분** ⚡

## Related Resources

- **Original Video**: [클로드코드 최애 기능](https://www.youtube.com/watch?v=prTGyqWMxw8) (05:08)
- **Related Skill**: parallel-dev-team.md
- **Related Skill**: massive-parallel-orchestrator.md
- **Claude Code Docs**: https://docs.anthropic.com/claude-code/agents

## Tags

#YOLO #자동실행 #무인작업 #완전자동화 #병렬처리 #100개에이전트 #배치처리 #대량작업 #ClaudeCode #자동승인 #생산성 #시간절약

---

## 💡 Quick Start

```javascript
// 1. Git 백업
await execSync('git commit -am "Pre-YOLO backup"');

// 2. YOLO 실행
const result = await Task({
  subagent_type: "general-purpose",
  description: "100 files generation",
  prompt: "Create 100 test files",
  auto_approve: true,  // 🔑 YOLO ON!
  timeout: 600000
});

// 3. 결과 확인
console.log("Done! 🎉");

// 문제 생기면:
// git reset --hard HEAD~1
```

**결과: 100번 승인 클릭 → 0번 클릭!**
