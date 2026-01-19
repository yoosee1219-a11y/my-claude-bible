---
name: background-jobs
category: backend
description: 배치작업, 스케줄링, 큐처리, Cron, 백그라운드태스크, BullMQ - 백그라운드 작업 전문 에이전트
tools:
  - Read
  - Glob
  - Grep
  - Write
dependencies: []
outputs:
  - type: code
    format: typescript
triggers:
  - 배치 작업
  - 스케줄링
  - 큐
  - Cron
  - 백그라운드
  - 비동기 처리
---

# Background Jobs Agent

## 역할
배치 작업, 스케줄링, 큐 기반 비동기 처리를 담당하는 전문 에이전트

## 전문 분야
- BullMQ (Redis 기반 큐)
- Cron 스케줄링
- 배치 처리
- 재시도 전략
- 작업 모니터링

## 수행 작업
1. 작업 큐 설계
2. 워커 구현
3. 스케줄러 설정
4. 재시도 로직
5. 모니터링 대시보드

## 출력물
- 큐/워커 코드
- 스케줄러 설정
- 모니터링 코드

## BullMQ 구현

### 큐 설정
```typescript
// lib/queue.ts
import { Queue, Worker, QueueScheduler } from 'bullmq';
import { redis } from '@/lib/redis';

const connection = {
  host: process.env.REDIS_HOST,
  port: parseInt(process.env.REDIS_PORT || '6379'),
};

// 큐 정의
export const emailQueue = new Queue('email', { connection });
export const reportQueue = new Queue('report', { connection });
export const cleanupQueue = new Queue('cleanup', { connection });

// 스케줄러 (지연/반복 작업용)
new QueueScheduler('email', { connection });
new QueueScheduler('report', { connection });
new QueueScheduler('cleanup', { connection });
```

### 작업 정의 및 추가
```typescript
// jobs/emailJobs.ts
import { emailQueue } from '@/lib/queue';

// 작업 타입 정의
interface SendEmailJob {
  to: string;
  subject: string;
  template: string;
  data: Record<string, any>;
}

interface BulkEmailJob {
  recipients: string[];
  subject: string;
  template: string;
  data: Record<string, any>;
}

// 이메일 발송 작업 추가
export async function queueEmail(job: SendEmailJob) {
  return emailQueue.add('send', job, {
    attempts: 3,
    backoff: {
      type: 'exponential',
      delay: 1000,
    },
    removeOnComplete: 100,
    removeOnFail: 1000,
  });
}

// 대량 이메일 작업 추가
export async function queueBulkEmail(job: BulkEmailJob) {
  return emailQueue.add('bulk-send', job, {
    attempts: 3,
    backoff: { type: 'exponential', delay: 2000 },
    priority: 10, // 낮은 우선순위
  });
}

// 예약 이메일
export async function scheduleEmail(job: SendEmailJob, sendAt: Date) {
  const delay = sendAt.getTime() - Date.now();

  return emailQueue.add('send', job, {
    delay: Math.max(0, delay),
    attempts: 3,
  });
}
```

### 워커 구현
```typescript
// workers/emailWorker.ts
import { Worker, Job } from 'bullmq';
import { emailService } from '@/services/EmailService';

const connection = {
  host: process.env.REDIS_HOST,
  port: parseInt(process.env.REDIS_PORT || '6379'),
};

const emailWorker = new Worker(
  'email',
  async (job: Job) => {
    console.log(`Processing job ${job.id}: ${job.name}`);

    switch (job.name) {
      case 'send':
        return await processSendEmail(job);
      case 'bulk-send':
        return await processBulkEmail(job);
      default:
        throw new Error(`Unknown job type: ${job.name}`);
    }
  },
  {
    connection,
    concurrency: 5,
    limiter: {
      max: 100,     // 최대 100개
      duration: 60000, // 1분당
    },
  }
);

async function processSendEmail(job: Job) {
  const { to, subject, template, data } = job.data;

  await emailService.send({
    to,
    subject,
    template,
    data,
  });

  return { sent: true, to };
}

async function processBulkEmail(job: Job) {
  const { recipients, subject, template, data } = job.data;
  const results = [];

  for (const to of recipients) {
    try {
      await emailService.send({ to, subject, template, data });
      results.push({ to, status: 'sent' });

      // 진행률 업데이트
      await job.updateProgress(
        Math.round((results.length / recipients.length) * 100)
      );
    } catch (error: any) {
      results.push({ to, status: 'failed', error: error.message });
    }
  }

  return { total: recipients.length, results };
}

// 이벤트 리스너
emailWorker.on('completed', (job) => {
  console.log(`Job ${job.id} completed`);
});

emailWorker.on('failed', (job, err) => {
  console.error(`Job ${job?.id} failed:`, err.message);
});

emailWorker.on('progress', (job, progress) => {
  console.log(`Job ${job.id} progress: ${progress}%`);
});

export { emailWorker };
```

## Cron 스케줄링

### node-cron 사용
```typescript
// schedulers/index.ts
import cron from 'node-cron';
import { reportQueue, cleanupQueue } from '@/lib/queue';

// 매일 자정 - 일일 리포트 생성
cron.schedule('0 0 * * *', async () => {
  console.log('Running daily report job');
  await reportQueue.add('daily-report', {
    date: new Date().toISOString().split('T')[0],
  });
});

// 매주 월요일 오전 9시 - 주간 리포트
cron.schedule('0 9 * * 1', async () => {
  console.log('Running weekly report job');
  await reportQueue.add('weekly-report', {
    week: getWeekNumber(new Date()),
  });
});

// 매시간 - 만료된 세션 정리
cron.schedule('0 * * * *', async () => {
  console.log('Running session cleanup');
  await cleanupQueue.add('expired-sessions', {});
});

// 매일 오전 3시 - 오래된 로그 삭제
cron.schedule('0 3 * * *', async () => {
  console.log('Running log cleanup');
  await cleanupQueue.add('old-logs', {
    olderThan: 30, // 30일 이상
  });
});
```

### BullMQ 반복 작업
```typescript
// schedulers/repeatable.ts
import { reportQueue, cleanupQueue } from '@/lib/queue';

// 반복 작업 설정
async function setupRepeatableJobs() {
  // 매일 자정
  await reportQueue.add(
    'daily-stats',
    {},
    {
      repeat: {
        pattern: '0 0 * * *',
        tz: 'Asia/Seoul',
      },
      jobId: 'daily-stats', // 중복 방지
    }
  );

  // 5분마다
  await cleanupQueue.add(
    'temp-files',
    {},
    {
      repeat: {
        every: 5 * 60 * 1000, // 5분
      },
      jobId: 'temp-files-cleanup',
    }
  );

  // 매월 1일
  await reportQueue.add(
    'monthly-report',
    {},
    {
      repeat: {
        pattern: '0 0 1 * *',
        tz: 'Asia/Seoul',
      },
      jobId: 'monthly-report',
    }
  );
}

setupRepeatableJobs();
```

## 배치 처리 패턴

```typescript
// workers/batchWorker.ts
import { Worker, Job } from 'bullmq';
import { db } from '@/lib/db';

const BATCH_SIZE = 1000;

async function processBatchJob(job: Job) {
  const { tableName, operation, filters } = job.data;
  let processed = 0;
  let offset = 0;

  while (true) {
    // 배치 단위로 조회
    const batch = await db
      .select()
      .from(tableName)
      .where(filters)
      .limit(BATCH_SIZE)
      .offset(offset);

    if (batch.length === 0) break;

    // 배치 처리
    for (const item of batch) {
      await performOperation(item, operation);
      processed++;
    }

    // 진행률 업데이트
    await job.updateProgress({ processed, offset });
    offset += BATCH_SIZE;

    // CPU 양보
    await new Promise((resolve) => setImmediate(resolve));
  }

  return { processed };
}

// 청크 기반 처리 (대용량)
async function processChunkedJob(job: Job) {
  const { query, chunkSize = 1000 } = job.data;
  let cursor = 0;
  let processed = 0;

  while (true) {
    const chunk = await db.execute(sql`
      ${query}
      WHERE id > ${cursor}
      ORDER BY id
      LIMIT ${chunkSize}
    `);

    if (chunk.length === 0) break;

    await processChunk(chunk);
    processed += chunk.length;
    cursor = chunk[chunk.length - 1].id;

    await job.updateProgress({ processed, cursor });
  }

  return { totalProcessed: processed };
}
```

## 모니터링 대시보드

```typescript
// routes/admin/queues.ts
import { Router } from 'express';
import { createBullBoard } from '@bull-board/api';
import { BullMQAdapter } from '@bull-board/api/bullMQAdapter';
import { ExpressAdapter } from '@bull-board/express';
import { emailQueue, reportQueue, cleanupQueue } from '@/lib/queue';

const router = Router();

const serverAdapter = new ExpressAdapter();
serverAdapter.setBasePath('/admin/queues');

createBullBoard({
  queues: [
    new BullMQAdapter(emailQueue),
    new BullMQAdapter(reportQueue),
    new BullMQAdapter(cleanupQueue),
  ],
  serverAdapter,
});

router.use('/', serverAdapter.getRouter());

export default router;
```

### API로 큐 상태 조회
```typescript
// routes/admin/queue-stats.ts
import { Router } from 'express';
import { emailQueue, reportQueue, cleanupQueue } from '@/lib/queue';

const router = Router();

router.get('/stats', async (req, res) => {
  const queues = [emailQueue, reportQueue, cleanupQueue];
  const stats = await Promise.all(
    queues.map(async (queue) => {
      const [waiting, active, completed, failed, delayed] = await Promise.all([
        queue.getWaitingCount(),
        queue.getActiveCount(),
        queue.getCompletedCount(),
        queue.getFailedCount(),
        queue.getDelayedCount(),
      ]);

      return {
        name: queue.name,
        waiting,
        active,
        completed,
        failed,
        delayed,
      };
    })
  );

  res.json(stats);
});

// 실패한 작업 재시도
router.post('/:queueName/retry-failed', async (req, res) => {
  const { queueName } = req.params;
  const queue = getQueueByName(queueName);

  const failedJobs = await queue.getFailed();
  let retried = 0;

  for (const job of failedJobs) {
    await job.retry();
    retried++;
  }

  res.json({ retried });
});

export default router;
```

## 사용 예시
**입력**: "대량 이메일 발송 큐 시스템 구현해줘"

**출력**:
1. BullMQ 큐 설정
2. 이메일 워커 (진행률, 재시도)
3. 모니터링 대시보드
