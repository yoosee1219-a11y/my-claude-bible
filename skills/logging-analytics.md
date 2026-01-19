# Logging & Analytics

> Winston, Datadog, ELK Stack으로 중앙 집중식 로깅 시스템 구축 완벽 가이드 (2026)

## 목차

1. [왜 로깅이 중요한가?](#왜-로깅이-중요한가)
2. [Structured Logging 기초](#structured-logging-기초)
3. [Winston vs Pino](#winston-vs-pino)
4. [ELK Stack (Elasticsearch + Logstash + Kibana)](#elk-stack)
5. [Datadog Integration](#datadog-integration)
6. [실전 사례](#실전-사례)

---

## 왜 로깅이 중요한가?

### console.log의 한계

**Before (console.log)**
```javascript
// ❌ 문제점
console.log('User login');  // 누가? 언제? 어디서?
console.log('Error:', error);  // 컨텍스트 부족
console.log('Payment failed');  // 검색 불가, 분석 불가
```

**문제:**
- 구조화 안 됨 → 파싱 불가
- 컨텍스트 부족 → 디버깅 어려움
- 중앙 집중 불가 → 서버 10대면 10곳 확인
- 성능 저하 → 동기 I/O
- 프로덕션 부적합

### Structured Logging의 이점

**After (Winston)**
```javascript
// ✅ 해결
logger.info('User login', {
  userId: '123',
  email: 'user@example.com',
  ip: '192.168.1.1',
  timestamp: '2026-01-09T10:30:00Z',
  environment: 'production',
});

// 결과 (JSON):
{
  "level": "info",
  "message": "User login",
  "userId": "123",
  "email": "user@example.com",
  "ip": "192.168.1.1",
  "timestamp": "2026-01-09T10:30:00Z",
  "environment": "production",
  "service": "auth-service"
}
```

**이점:**
- 기계 파싱 가능 → Elasticsearch 쿼리
- 풍부한 컨텍스트 → 빠른 디버깅
- 중앙 집중 → 한곳에서 모든 로그 확인
- 비동기 → 성능 영향 최소화
- 시각화 → Kibana 대시보드

---

## Structured Logging 기초

### 필수 필드

**표준 로그 구조:**
```typescript
interface LogEntry {
  timestamp: string;       // ISO 8601
  level: 'debug' | 'info' | 'warn' | 'error' | 'critical';
  message: string;
  service: string;         // 마이크로서비스 이름
  environment: 'dev' | 'staging' | 'production';

  // 요청 추적
  requestId?: string;      // UUID
  userId?: string;
  ip?: string;
  endpoint?: string;
  method?: string;

  // 에러 정보
  error?: {
    name: string;
    message: string;
    stack: string;
  };

  // 커스텀 필드
  [key: string]: any;
}
```

---

### 로그 레벨 전략

**환경별 로그 레벨:**

```javascript
const LOG_LEVELS = {
  development: 'debug',    // 모든 로그
  staging: 'info',         // INFO + WARN + ERROR
  production: 'warn',      // WARN + ERROR만
};

const logger = winston.createLogger({
  level: LOG_LEVELS[process.env.NODE_ENV] || 'info',
});
```

**레벨별 사용 기준:**

| 레벨 | 사용 시점 | 예시 |
|------|----------|------|
| `debug` | 상세 디버깅 정보 | 함수 호출, 변수 값 |
| `info` | 일반 정보 | 사용자 로그인, API 호출 |
| `warn` | 경고 (기능은 정상) | Deprecated API 사용, 느린 쿼리 |
| `error` | 에러 (기능 실패) | 500 에러, DB 연결 실패 |
| `critical` | 심각한 시스템 장애 | 전체 서비스 다운, 보안 침해 |

---

### Best Practices

**1. 일관된 형식 (JSON)**
```javascript
// ✅ 좋은 예: JSON
logger.info('Payment processed', { orderId: '123', amount: 100 });

// ❌ 나쁜 예: 문자열 concat
console.log('Payment processed: Order #' + orderId + ' Amount: $' + amount);
```

**2. 적절한 데이터 타입**
```javascript
// ✅ 좋은 예
logger.info('Order created', {
  orderId: 12345,           // number
  total: 99.99,             // number
  isPaid: false,            // boolean
  createdAt: new Date(),    // Date
});

// ❌ 나쁜 예
logger.info('Order created', {
  orderId: '12345',         // string (숫자 연산 불가)
  total: '$99.99',          // string (집계 불가)
});
```

**3. 민감 정보 제거**
```javascript
// ❌ 위험: 비밀번호 로깅
logger.info('User login', { email, password });

// ✅ 안전: 민감 정보 제외
logger.info('User login', {
  email,
  passwordLength: password.length,  // 길이만
});

// 또는 자동 마스킹
const sanitize = (obj) => {
  const sensitive = ['password', 'creditCard', 'ssn'];
  return Object.keys(obj).reduce((acc, key) => {
    acc[key] = sensitive.includes(key) ? '***' : obj[key];
    return acc;
  }, {});
};
```

**4. Correlation ID (분산 추적)**
```javascript
// middleware/requestId.js
import { v4 as uuidv4 } from 'uuid';

export const requestIdMiddleware = (req, res, next) => {
  req.id = req.headers['x-request-id'] || uuidv4();
  res.setHeader('X-Request-ID', req.id);
  next();
};

// 사용
app.use(requestIdMiddleware);

app.get('/api/users', (req, res) => {
  logger.info('Fetching users', { requestId: req.id });
  // 다른 마이크로서비스 호출 시에도 전달
  fetch('http://order-service/api/orders', {
    headers: { 'X-Request-ID': req.id }
  });
});
```

---

## Winston vs Pino

### 비교표

| 항목 | Winston | Pino |
|------|---------|------|
| 성능 | 중간 (10K logs/sec) | 빠름 (30K logs/sec) |
| 사용 편의성 | 쉬움 | 중간 |
| Transport | 풍부 (파일, HTTP, Datadog 등) | 기본 제공 적음 (플러그인) |
| JSON 기본 | ❌ (설정 필요) | ✅ |
| 인기도 | 높음 | 높음 |
| 용도 | 범용, 엔터프라이즈 | 고성능 마이크로서비스 |

**선택 기준:**
- **Winston:** 다양한 Transport 필요, 풍부한 플러그인
- **Pino:** 초당 수만 건 로그, 성능 중시

---

### Winston 설정

**설치:**
```bash
npm install winston winston-daily-rotate-file
```

**기본 설정:**
```javascript
// lib/logger.js
import winston from 'winston';
import DailyRotateFile from 'winston-daily-rotate-file';

const { combine, timestamp, json, errors, printf } = winston.format;

// 커스텀 포맷 (개발용)
const devFormat = printf(({ level, message, timestamp, ...meta }) => {
  return `${timestamp} [${level}]: ${message} ${
    Object.keys(meta).length ? JSON.stringify(meta, null, 2) : ''
  }`;
});

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: combine(
    timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    errors({ stack: true }),  // 에러 스택 트레이스
    json()                    // JSON 포맷
  ),
  defaultMeta: {
    service: process.env.SERVICE_NAME || 'app',
    environment: process.env.NODE_ENV || 'development',
  },
  transports: [
    // 콘솔 (개발)
    new winston.transports.Console({
      format: process.env.NODE_ENV === 'development' ? devFormat : json(),
    }),

    // 파일 (모든 로그)
    new DailyRotateFile({
      filename: 'logs/app-%DATE%.log',
      datePattern: 'YYYY-MM-DD',
      maxSize: '20m',
      maxFiles: '14d',  // 14일 보관
    }),

    // 에러 전용 파일
    new DailyRotateFile({
      level: 'error',
      filename: 'logs/error-%DATE%.log',
      datePattern: 'YYYY-MM-DD',
      maxSize: '20m',
      maxFiles: '30d',
    }),
  ],
});

export default logger;
```

**사용:**
```javascript
import logger from './lib/logger.js';

logger.info('Server started', { port: 3000 });

logger.error('Database connection failed', {
  error: new Error('Connection timeout'),
  dbHost: 'localhost:5432',
});

logger.warn('Slow query detected', {
  query: 'SELECT * FROM users',
  duration: 1500,  // ms
});
```

---

### Pino 설정

**설치:**
```bash
npm install pino pino-pretty
```

**기본 설정:**
```javascript
// lib/logger.js
import pino from 'pino';

const logger = pino({
  level: process.env.LOG_LEVEL || 'info',

  // 프로덕션: JSON
  // 개발: pretty print
  transport: process.env.NODE_ENV !== 'production' ? {
    target: 'pino-pretty',
    options: {
      colorize: true,
      translateTime: 'SYS:standard',
      ignore: 'pid,hostname',
    }
  } : undefined,

  // 기본 필드
  base: {
    service: process.env.SERVICE_NAME || 'app',
    environment: process.env.NODE_ENV || 'development',
  },

  // 타임스탬프
  timestamp: pino.stdTimeFunctions.isoTime,
});

export default logger;
```

**사용:**
```javascript
import logger from './lib/logger.js';

logger.info({ port: 3000 }, 'Server started');

logger.error({
  err: new Error('Connection timeout'),
  dbHost: 'localhost:5432',
}, 'Database connection failed');
```

**Express 통합:**
```javascript
import pino from 'pino';
import expressPino from 'express-pino-logger';

const logger = pino();
const expressLogger = expressPino({ logger });

app.use(expressLogger);

app.get('/api/users', (req, res) => {
  req.log.info('Fetching users');  // 자동으로 requestId 포함
  res.json({ users: [] });
});
```

---

## ELK Stack

### 구성 요소

**ELK = Elasticsearch + Logstash + Kibana**

- **Elasticsearch:** 로그 저장 & 검색 엔진
- **Logstash:** 로그 수집 & 변환 (요즘은 Filebeat/Fluentd로 대체)
- **Kibana:** 로그 시각화 & 대시보드

---

### Docker Compose 설정

**docker-compose.yml:**
```yaml
version: '3.8'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ports:
      - "9200:9200"
    volumes:
      - elasticsearch-data:/usr/share/elasticsearch/data

  kibana:
    image: docker.elastic.co/kibana/kibana:8.11.0
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    ports:
      - "5601:5601"
    depends_on:
      - elasticsearch

  filebeat:
    image: docker.elastic.co/beats/filebeat:8.11.0
    user: root
    volumes:
      - ./filebeat.yml:/usr/share/filebeat/filebeat.yml:ro
      - ./logs:/var/log/app:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
    depends_on:
      - elasticsearch

volumes:
  elasticsearch-data:
```

**filebeat.yml:**
```yaml
filebeat.inputs:
  - type: log
    enabled: true
    paths:
      - /var/log/app/*.log
    json.keys_under_root: true
    json.add_error_key: true

output.elasticsearch:
  hosts: ["elasticsearch:9200"]
  index: "app-logs-%{+yyyy.MM.dd}"

setup.kibana:
  host: "kibana:5601"
```

**실행:**
```bash
docker-compose up -d

# Kibana 접속: http://localhost:5601
```

---

### Elasticsearch 쿼리 예시

**Kibana DevTools에서:**
```json
// 최근 1시간 에러 로그
GET /app-logs-*/_search
{
  "query": {
    "bool": {
      "must": [
        { "match": { "level": "error" } },
        {
          "range": {
            "timestamp": {
              "gte": "now-1h"
            }
          }
        }
      ]
    }
  },
  "sort": [
    { "timestamp": { "order": "desc" } }
  ],
  "size": 100
}
```

```json
// 특정 사용자의 활동 추적
GET /app-logs-*/_search
{
  "query": {
    "match": { "userId": "123" }
  },
  "sort": [
    { "timestamp": { "order": "asc" } }
  ]
}
```

```json
// 느린 API 응답 (> 1초)
GET /app-logs-*/_search
{
  "query": {
    "range": {
      "duration": {
        "gte": 1000
      }
    }
  },
  "aggs": {
    "slow_endpoints": {
      "terms": {
        "field": "endpoint.keyword",
        "size": 10
      },
      "aggs": {
        "avg_duration": {
          "avg": { "field": "duration" }
        }
      }
    }
  }
}
```

---

### Kibana 대시보드

**주요 시각화:**

1. **타임라인 그래프** (Line Chart)
   - X축: 시간 (5분 간격)
   - Y축: 로그 건수
   - 필터: level별 색상 구분

2. **에러 비율** (Pie Chart)
   - 전체 로그 중 error 로그 비율

3. **Top 10 Endpoints** (Data Table)
   - 가장 많이 호출된 API 엔드포인트

4. **평균 응답 시간** (Metric)
   - duration 필드 평균

**대시보드 생성:**
```
Kibana → Analytics → Dashboard → Create dashboard
→ Add visualization → Select chart type
```

---

## Datadog Integration

### Winston + Datadog

**설치:**
```bash
npm install datadog-winston
```

**설정:**
```javascript
// lib/logger.js
import winston from 'winston';
import DatadogWinston from 'datadog-winston';

const logger = winston.createLogger({
  level: 'info',
  exitOnError: false,
  format: winston.format.json(),
  transports: [
    new winston.transports.Console(),

    // Datadog Transport
    new DatadogWinston({
      apiKey: process.env.DATADOG_API_KEY,
      hostname: process.env.HOSTNAME,
      service: process.env.SERVICE_NAME,
      ddsource: 'nodejs',
      ddtags: `env:${process.env.NODE_ENV},version:${process.env.APP_VERSION}`,
    }),
  ],
});

export default logger;
```

---

### Trace Correlation (APM 연동)

**설치:**
```bash
npm install dd-trace
```

**설정:**
```javascript
// tracer.js (맨 처음 import)
import tracer from 'dd-trace';

tracer.init({
  service: 'my-app',
  env: process.env.NODE_ENV,
  logInjection: true,  // 로그에 trace_id 자동 삽입
});

export default tracer;
```

**app.js:**
```javascript
import './tracer.js';  // 맨 위에!
import logger from './lib/logger.js';

app.get('/api/users', async (req, res) => {
  const span = tracer.scope().active();

  logger.info('Fetching users', {
    trace_id: span?.context().toTraceId(),  // Datadog APM 연동
    span_id: span?.context().toSpanId(),
  });

  const users = await User.findAll();
  res.json(users);
});
```

**결과:**
- Datadog Logs에서 로그 확인
- 로그 클릭 → APM Trace로 자동 이동
- 요청의 전체 플로우 시각화

---

### Datadog 대시보드

**자동 생성 대시보드:**
- Logs → Search → 원하는 필터 → Save as Dashboard

**커스텀 메트릭:**
```javascript
import tracer from 'dd-trace';

const metrics = tracer.dogstatsd;

// 카운터
metrics.increment('api.requests', 1, { endpoint: '/api/users' });

// 게이지
metrics.gauge('db.connections', 50);

// 타이머
const start = Date.now();
await someAsyncOperation();
metrics.histogram('operation.duration', Date.now() - start);
```

---

## 실전 사례

### 사례: SaaS 앱 로깅 시스템 구축

**Before**
```javascript
// 문제 1: console.log만 사용
console.log('User login');  // 누가? 언제?

// 문제 2: 에러 추적 불가
try {
  await processPayment();
} catch (error) {
  console.error(error);  // 스택 트레이스만, 컨텍스트 없음
}

// 문제 3: 서버 10대 → 10곳 확인
ssh server1 && tail -f /var/log/app.log
ssh server2 && tail -f /var/log/app.log
...
```

**After**
```javascript
// 1. Winston + Datadog
logger.info('User login', {
  userId: user.id,
  email: user.email,
  ip: req.ip,
  userAgent: req.headers['user-agent'],
});

// 2. 에러 추적 강화
try {
  await processPayment(orderId);
} catch (error) {
  logger.error('Payment processing failed', {
    error: {
      name: error.name,
      message: error.message,
      stack: error.stack,
    },
    orderId,
    userId: req.user.id,
    amount: order.total,
  });
  throw error;
}

// 3. Datadog에서 통합 검색
// 웹 UI에서 한 번에 모든 서버 로그 확인
```

**구축 단계:**
```bash
# 1. Winston + Datadog 설정
npm install winston datadog-winston

# 2. ELK Stack (Docker)
docker-compose up -d

# 3. Filebeat로 로그 수집
# 모든 서버의 로그 → Elasticsearch

# 4. Kibana 대시보드 생성
# - 에러 타임라인
# - Top 에러 메시지
# - 사용자별 활동 추적
```

**결과:**
- 디버깅 시간: 2시간 → 10분 (92% 감소)
- MTTR (평균 복구 시간): 45분 → 5분
- 월간 다운타임: 8시간 → 30분
- 고객 만족도: 73% → 91%

**ROI:** 연간 $120,000 인건비 절감 (엔지니어 디버깅 시간)

---

## 체크리스트

### 기본 설정
- [ ] Winston 또는 Pino 설치
- [ ] JSON 포맷 활성화
- [ ] 환경별 로그 레벨 설정
- [ ] DailyRotateFile (14-30일 보관)
- [ ] 민감 정보 자동 마스킹

### 필수 필드
- [ ] timestamp (ISO 8601)
- [ ] level (debug/info/warn/error)
- [ ] message
- [ ] service name
- [ ] environment
- [ ] requestId (UUID)

### 중앙 집중화
- [ ] ELK Stack 또는 Datadog 선택
- [ ] Filebeat/Fluentd 설정
- [ ] Kibana/Datadog 대시보드 생성
- [ ] 알림 설정 (에러 임계값)

### 성능
- [ ] 비동기 Transport 사용
- [ ] 로그 레벨 최적화 (프로덕션: warn 이상)
- [ ] 로그 압축 (GZIP)
- [ ] 로그 로테이션

### 모니터링
- [ ] 에러 타임라인 대시보드
- [ ] Top 10 에러 메시지
- [ ] API 응답 시간 추적
- [ ] 느린 쿼리 알림 (> 1초)

---

## 참고 자료

- [Node.js Logging Best Practices (Datadog)](https://www.datadoghq.com/blog/node-logging-best-practices/)
- [Structured Logging Guide (Uptrace)](https://uptrace.dev/glossary/structured-logging)
- [ELK Stack Guide (Logz.io)](https://logz.io/learn/complete-guide-elk-stack/)
- [Winston Documentation](https://github.com/winstonjs/winston)
- [Pino Documentation](https://getpino.io/)
- [Elastic Stack](https://www.elastic.co/elastic-stack)

---

**중앙 집중식 로깅으로 디버깅 시간을 90% 단축하세요! 📊**
