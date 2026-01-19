---
name: massive-parallel-orchestrator
description: 대규모병렬실행, 100개에이전트, 1000개동시실행, 배치처리최적화, 메모리관리, 성능최적화, 대량작업조율, 스케일링전략, 에러복구, 진행률모니터링, 리소스관리, 병목현상해결로 100~1000개 에이전트를 효율적으로 관리하고 대규모 병렬 작업을 조율하는 스킬
---

# massive-parallel-orchestrator

## Overview

**100개~1000개 에이전트를 안정적으로 동시 실행!**

6개 에이전트 병렬 실행은 간단합니다. 하지만 **100개, 1000개**를 동시에 돌리려면 **특별한 전략**이 필요합니다:

- 메모리 부족 → 크래시
- API 속도 제한 → 실패
- 에러 복구 관리 → 혼란
- 진행 상황 파악 불가

이 스킬은 **대규모 병렬 실행을 위한 Orchestrator**로, 수백~수천 개의 에이전트를 **안정적이고 효율적으로** 관리합니다.

### 핵심 전략:

```
일반 병렬:
Promise.all([...1000개]) → 메모리 폭발 💥

Massive Orchestrator:
배치 처리 (10개씩 100번) + 진행률 모니터링 + 에러 복구
→ 안정적이고 빠름 ✅
```

**차이점:**
- 일반: 1000개 동시 → 메모리 부족 → 크래시
- Orchestrator: 10개씩 배치 → 안정적 → 성공

## When to Use This Skill

### ✅ 이 스킬을 사용하세요:

- **100개 이상 작업**: 대량 파일 생성, 대량 데이터 처리
- **API 속도 제한**: 동시 요청 수 제한 있는 API
- **메모리 제약**: 로컬 머신 리소스 제한
- **긴 작업**: 몇 시간~하루 걸리는 작업
- **중요한 작업**: 실패하면 안 되는 프로덕션 작업
- **진행률 중요**: 언제 끝날지 알아야 할 때

### ⚠️ 이 스킬 대신 일반 병렬:

- **10개 미만**: 간단한 Promise.all()로 충분
- **빠른 작업**: 각 작업이 1초 이내
- **테스트**: 개발/테스트 환경

### 🔀 점진적 적용:

- 10개 이하: 일반 병렬
- 10~50개: 간단한 배치 처리
- 50개 이상: Massive Orchestrator

## Prerequisites

- Claude Code 설치
- Node.js / Python 환경
- 대량 작업 리스트 (100개 이상)
- YOLO 모드 이해 (필수)
- 충분한 API 크레딧

## Instructions

### Step 1: Orchestrator 클래스 생성

대규모 병렬 작업을 관리하는 핵심 클래스입니다.

```typescript
// MassiveOrchestrator.ts

interface OrchestratorConfig {
  batchSize: number;          // 배치당 작업 수
  maxConcurrent: number;      // 최대 동시 실행 수
  retryAttempts: number;      // 재시도 횟수
  retryDelay: number;         // 재시도 대기 시간 (ms)
  rateLimitPerMinute: number; // 분당 요청 제한
  progressCallback?: (progress: Progress) => void;
}

interface Progress {
  total: number;
  completed: number;
  failed: number;
  percentage: number;
  estimatedTimeRemaining: string;
}

class MassiveOrchestrator {
  private config: OrchestratorConfig;
  private results: {
    success: any[];
    failed: any[];
  };
  private startTime: number;

  constructor(config: OrchestratorConfig) {
    this.config = config;
    this.results = { success: [], failed: [] };
    this.startTime = 0;
  }

  // 메인 실행 함수
  async execute<T>(
    tasks: Array<() => Promise<T>>,
    description: string
  ): Promise<{ success: T[], failed: any[] }> {
    console.log(`🚀 Starting ${tasks.length} tasks: ${description}`);
    this.startTime = Date.now();

    const batches = this.createBatches(tasks);
    console.log(`📦 Split into ${batches.length} batches of ${this.config.batchSize}`);

    for (let i = 0; i < batches.length; i++) {
      console.log(`\n📊 Batch ${i + 1}/${batches.length}`);
      await this.executeBatch(batches[i], i + 1, batches.length);

      // Rate limiting: 배치 간 대기
      if (i < batches.length - 1) {
        await this.waitForRateLimit();
      }
    }

    this.printSummary();
    return this.results;
  }

  // 작업을 배치로 분할
  private createBatches<T>(tasks: T[]): T[][] {
    const batches: T[][] = [];
    for (let i = 0; i < tasks.length; i += this.config.batchSize) {
      batches.push(tasks.slice(i, i + this.config.batchSize));
    }
    return batches;
  }

  // 단일 배치 실행
  private async executeBatch(
    batch: Array<() => Promise<any>>,
    batchNum: number,
    totalBatches: number
  ) {
    const batchResults = await Promise.allSettled(
      batch.map(task => this.executeWithRetry(task))
    );

    // 결과 분류
    batchResults.forEach((result, index) => {
      if (result.status === 'fulfilled') {
        this.results.success.push(result.value);
      } else {
        this.results.failed.push({
          index: (batchNum - 1) * this.config.batchSize + index,
          error: result.reason
        });
      }
    });

    // 진행률 업데이트
    this.updateProgress(batchNum, totalBatches);
  }

  // 재시도 로직
  private async executeWithRetry<T>(
    task: () => Promise<T>,
    attempt: number = 1
  ): Promise<T> {
    try {
      return await task();
    } catch (error) {
      if (attempt < this.config.retryAttempts) {
        console.log(`⚠️ Retry ${attempt}/${this.config.retryAttempts}`);
        await this.delay(this.config.retryDelay * attempt);
        return this.executeWithRetry(task, attempt + 1);
      }
      throw error;
    }
  }

  // Rate limiting 대기
  private async waitForRateLimit() {
    const delay = (60 * 1000) / this.config.rateLimitPerMinute;
    await this.delay(delay);
  }

  // 진행률 업데이트
  private updateProgress(currentBatch: number, totalBatches: number) {
    const completed = this.results.success.length + this.results.failed.length;
    const total = totalBatches * this.config.batchSize;
    const percentage = (completed / total) * 100;

    const elapsed = Date.now() - this.startTime;
    const estimatedTotal = (elapsed / completed) * total;
    const remaining = estimatedTotal - elapsed;

    const progress: Progress = {
      total,
      completed,
      failed: this.results.failed.length,
      percentage: Math.round(percentage * 10) / 10,
      estimatedTimeRemaining: this.formatTime(remaining)
    };

    console.log(`✅ ${progress.completed}/${progress.total} (${progress.percentage}%)`);
    console.log(`⏱️ ETA: ${progress.estimatedTimeRemaining}`);

    if (this.config.progressCallback) {
      this.config.progressCallback(progress);
    }
  }

  // 최종 요약
  private printSummary() {
    const totalTime = Date.now() - this.startTime;
    console.log(`\n${'='.repeat(60)}`);
    console.log(`📊 Final Summary`);
    console.log(`${'='.repeat(60)}`);
    console.log(`✅ Success: ${this.results.success.length}`);
    console.log(`❌ Failed: ${this.results.failed.length}`);
    console.log(`⏱️ Total Time: ${this.formatTime(totalTime)}`);
    console.log(`⚡ Avg Time/Task: ${(totalTime / (this.results.success.length + this.results.failed.length) / 1000).toFixed(2)}s`);
  }

  // 유틸리티
  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  private formatTime(ms: number): string {
    const seconds = Math.floor(ms / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);

    if (hours > 0) return `${hours}h ${minutes % 60}m`;
    if (minutes > 0) return `${minutes}m ${seconds % 60}s`;
    return `${seconds}s`;
  }
}

export default MassiveOrchestrator;
```

### Step 2: 100개 작업 실행 예시

```typescript
import MassiveOrchestrator from './MassiveOrchestrator';

// Orchestrator 설정
const orchestrator = new MassiveOrchestrator({
  batchSize: 10,              // 10개씩 배치
  maxConcurrent: 10,          // 최대 10개 동시
  retryAttempts: 3,           // 3번 재시도
  retryDelay: 1000,           // 1초 대기 후 재시도
  rateLimitPerMinute: 60,     // 분당 60개 요청
  progressCallback: (progress) => {
    // Slack 알림 등
    console.log(`Progress: ${progress.percentage}%`);
  }
});

// 100개 작업 정의
const tasks = Array.from({ length: 100 }, (_, i) => async () => {
  // Task tool로 Claude Code 에이전트 실행
  return await Task({
    subagent_type: "general-purpose",
    description: `Generate skill ${i + 1}`,
    prompt: `Create skill file for topic ${i + 1}`,
    auto_approve: true,  // YOLO
    run_in_background: true
  });
});

// 실행
const results = await orchestrator.execute(
  tasks,
  "Generate 100 skills"
);

console.log(`Completed! ${results.success.length} success, ${results.failed.length} failed`);
```

### Step 3: 1000개 대규모 실행

```typescript
// 1000개 YouTube 영상 → 스킬 생성
const youtubeUrls = [/* 1000개 URL */];

const tasks = youtubeUrls.map(url => async () => {
  return await Task({
    subagent_type: "general-purpose",
    description: `Generate skill from video`,
    prompt: `Create skill from ${url}`,
    auto_approve: true,
    run_in_background: true
  });
});

// Orchestrator 설정 (대규모용)
const orchestrator = new MassiveOrchestrator({
  batchSize: 20,              // 20개씩 배치
  maxConcurrent: 20,
  retryAttempts: 5,           // 재시도 5번
  retryDelay: 2000,
  rateLimitPerMinute: 100,
  progressCallback: async (progress) => {
    // 진행률을 Slack으로 전송
    await sendSlackNotification(
      `YouTube Skill Gen: ${progress.percentage}% (${progress.completed}/${progress.total})\nETA: ${progress.estimatedTimeRemaining}`
    );

    // 로그 파일에 기록
    fs.appendFileSync(
      'orchestrator.log',
      `${new Date().toISOString()} - ${progress.percentage}%\n`
    );
  }
});

// 실행
const results = await orchestrator.execute(
  tasks,
  "Generate 1000 skills from YouTube"
);

// 실패한 것만 재시도
if (results.failed.length > 0) {
  console.log(`Retrying ${results.failed.length} failed tasks...`);

  const retryTasks = results.failed.map(f => tasks[f.index]);

  const retryResults = await orchestrator.execute(
    retryTasks,
    "Retry failed tasks"
  );
}
```

### Step 4: 메모리 최적화

```typescript
// 메모리 사용량 모니터링
class MemoryOptimizedOrchestrator extends MassiveOrchestrator {
  private checkMemory() {
    const used = process.memoryUsage();
    const totalMB = Math.round(used.heapTotal / 1024 / 1024);
    const usedMB = Math.round(used.heapUsed / 1024 / 1024);

    console.log(`💾 Memory: ${usedMB}MB / ${totalMB}MB`);

    // 메모리 80% 이상 사용 시 가비지 컬렉션
    if (usedMB / totalMB > 0.8) {
      console.log(`⚠️ High memory usage. Running GC...`);
      if (global.gc) {
        global.gc();
      }
    }
  }

  async executeBatch(batch: any[], batchNum: number, totalBatches: number) {
    // 메모리 체크
    this.checkMemory();

    // 배치 실행
    await super.executeBatch(batch, batchNum, totalBatches);

    // 결과 정리 (메모리 절약)
    if (batchNum % 10 === 0) {
      // 10 배치마다 중간 결과 저장
      this.saveIntermediateResults(batchNum);
      // 메모리에서 제거
      this.results.success = [];
    }
  }

  private saveIntermediateResults(batchNum: number) {
    fs.writeFileSync(
      `results-batch-${batchNum}.json`,
      JSON.stringify(this.results, null, 2)
    );
  }
}
```

### Step 5: 실시간 대시보드

```typescript
// Express 서버로 진행률 대시보드
import express from 'express';

const app = express();
let currentProgress: Progress | null = null;

const orchestrator = new MassiveOrchestrator({
  // ... 설정
  progressCallback: (progress) => {
    currentProgress = progress;
  }
});

// API 엔드포인트
app.get('/progress', (req, res) => {
  res.json(currentProgress);
});

// HTML 대시보드
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Orchestrator Dashboard</title>
      <style>
        body { font-family: Arial; padding: 20px; }
        .progress-bar {
          width: 100%;
          height: 30px;
          background: #eee;
          border-radius: 5px;
          overflow: hidden;
        }
        .progress-fill {
          height: 100%;
          background: linear-gradient(90deg, #4CAF50, #8BC34A);
          transition: width 0.3s;
        }
        .stats { margin-top: 20px; }
        .stat { padding: 10px; margin: 5px; background: #f5f5f5; }
      </style>
    </head>
    <body>
      <h1>🚀 Massive Orchestrator Dashboard</h1>
      <div class="progress-bar">
        <div class="progress-fill" id="progress"></div>
      </div>
      <div class="stats">
        <div class="stat">Completed: <span id="completed">0</span> / <span id="total">0</span></div>
        <div class="stat">Failed: <span id="failed">0</span></div>
        <div class="stat">ETA: <span id="eta">Calculating...</span></div>
      </div>

      <script>
        setInterval(async () => {
          const res = await fetch('/progress');
          const progress = await res.json();

          document.getElementById('progress').style.width = progress.percentage + '%';
          document.getElementById('completed').textContent = progress.completed;
          document.getElementById('total').textContent = progress.total;
          document.getElementById('failed').textContent = progress.failed;
          document.getElementById('eta').textContent = progress.estimatedTimeRemaining;
        }, 1000);
      </script>
    </body>
    </html>
  `);
});

app.listen(3000, () => {
  console.log('📊 Dashboard: http://localhost:3000');
});

// Orchestrator 실행
await orchestrator.execute(tasks, "Large batch");
```

## Examples

### Example 1: 1000개 웹사이트 크롤링

```typescript
const sites = [/* 1000개 URL */];

const orchestrator = new MassiveOrchestrator({
  batchSize: 50,
  maxConcurrent: 50,
  retryAttempts: 3,
  retryDelay: 5000,
  rateLimitPerMinute: 120
});

const tasks = sites.map(site => async () => {
  return await scrapeSite(site);
});

const results = await orchestrator.execute(tasks, "Scrape 1000 sites");

// 결과 → CSV 저장
const csv = results.success.map(r => `${r.url},${r.price}`).join('\n');
fs.writeFileSync('pricing-data.csv', csv);
```

### Example 2: 500개 언어 번역

```typescript
const languages = [/* 500개 언어 코드 */];
const text = "Welcome to our app";

const orchestrator = new MassiveOrchestrator({
  batchSize: 25,
  maxConcurrent: 25,
  retryAttempts: 5,
  retryDelay: 3000,
  rateLimitPerMinute: 100
});

const tasks = languages.map(lang => async () => {
  return await translateText(text, lang);
});

const results = await orchestrator.execute(tasks, "Translate to 500 languages");
```

### Example 3: 야간 배치 작업 (10,000개)

```typescript
// 저녁 11시에 시작 → 아침 7시 완료
const data = [/* 10,000개 데이터 */];

const orchestrator = new MassiveOrchestrator({
  batchSize: 100,
  maxConcurrent: 100,
  retryAttempts: 10,
  retryDelay: 10000,
  rateLimitPerMinute: 200,
  progressCallback: async (progress) => {
    // 매 10% 진행마다 Slack 알림
    if (progress.percentage % 10 === 0) {
      await sendSlackNotification(
        `Batch job ${progress.percentage}% complete. ETA: ${progress.estimatedTimeRemaining}`
      );
    }
  }
});

console.log("Starting overnight batch job...");
console.log("Start time:", new Date().toLocaleString());

const results = await orchestrator.execute(
  data.map(item => async () => processItem(item)),
  "Overnight batch processing"
);

console.log("Job completed:", new Date().toLocaleString());
await sendSlackNotification(`✅ Batch job completed! ${results.success.length} processed.`);
```

## Key Concepts

- **Batch Processing**: 대량 작업을 작은 배치로 분할
- **Rate Limiting**: API 속도 제한 준수
- **Retry Logic**: 실패 시 자동 재시도
- **Progress Tracking**: 실시간 진행률 모니터링
- **Memory Management**: 메모리 효율적 처리
- **Error Recovery**: 실패 케이스 자동 복구
- **Graceful Degradation**: 일부 실패해도 전체는 계속

## Common Pitfalls

### 1. 배치 크기 너무 큼
```
❌ batchSize: 1000 → 메모리 부족

✅ batchSize: 10~50 → 안정적
```

### 2. Rate Limiting 무시
```
❌ API 제한 초과 → 전체 실패

✅ rateLimitPerMinute 설정 → 안정적
```

### 3. 재시도 무한 루프
```
❌ retryAttempts: Infinity → 멈추지 않음

✅ retryAttempts: 3~5 → 적절히 포기
```

### 4. 진행률 미추적
```
❌ 언제 끝날지 모름 → 불안

✅ progressCallback → 실시간 확인
```

### 5. 중간 결과 미저장
```
❌ 90% 완료 후 크래시 → 모든 결과 손실

✅ 10 배치마다 저장 → 복구 가능
```

## Performance Comparison

| 작업 수 | 일반 병렬 | Orchestrator | 안정성 |
|--------|---------|--------------|--------|
| 10개 | 1분 | 1분 | 동일 |
| 100개 | 10분 (메모리 경고) | 10분 | Orchestrator 안정 |
| 1000개 | ❌ 크래시 | 1.5시간 | Orchestrator만 가능 |
| 10000개 | ❌ 불가능 | 15시간 | Orchestrator만 가능 |

## Related Resources

- **Original Video**: [클로드코드 최애 기능](https://www.youtube.com/watch?v=prTGyqWMxw8)
- **Related Skills**:
  - claude-code-yolo-mode.md (필수)
  - parallel-dev-team.md
  - playwright-parallel-test-generator.md

## Tags

#대규모병렬 #1000개에이전트 #배치처리 #메모리최적화 #성능최적화 #진행률모니터링 #에러복구 #RateLimiting #대량작업 #Orchestrator #스케일링 #안정성

---

## 💡 Quick Start

```typescript
const orchestrator = new MassiveOrchestrator({
  batchSize: 10,
  maxConcurrent: 10,
  retryAttempts: 3,
  retryDelay: 1000,
  rateLimitPerMinute: 60
});

const results = await orchestrator.execute(
  tasks,  // 100~1000개 작업
  "My large batch job"
);

console.log(`✅ ${results.success.length} completed!`);
```
