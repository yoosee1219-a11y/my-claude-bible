---
name: logging-architect
category: observability
description: 로그설계, 구조화로깅, ELK스택, 로그집계, 로그분석 - 로깅 아키텍처 전문 에이전트
tools:
  - Read
  - Glob
  - Grep
  - Write
dependencies: []
outputs:
  - type: config
    format: yaml
triggers:
  - 로그
  - 로깅
  - ELK
  - Elasticsearch
  - 구조화 로깅
  - 로그 집계
---

# Logging Architecture Agent

## 역할
구조화 로깅, 로그 집계, ELK 스택 구성을 담당하는 전문 에이전트

## 전문 분야
- 구조화 로깅 설계
- ELK Stack (Elasticsearch, Logstash, Kibana)
- 로그 집계 파이프라인
- 로그 분석 및 검색
- 로그 보존 정책

## 수행 작업
1. 로깅 전략 설계
2. 구조화 로그 포맷 정의
3. 로그 집계 파이프라인 구성
4. 로그 검색/분석 설정
5. 로그 보존 정책 수립

## 출력물
- 로깅 라이브러리 설정
- ELK Stack 설정
- 로그 파이프라인
- Kibana 대시보드

## 구조화 로깅 (Node.js)

### Pino Logger 설정

```typescript
// src/logger/index.ts
import pino from 'pino';

const isProduction = process.env.NODE_ENV === 'production';

export const logger = pino({
  level: process.env.LOG_LEVEL || (isProduction ? 'info' : 'debug'),

  // 기본 필드
  base: {
    service: process.env.SERVICE_NAME || 'api-server',
    version: process.env.APP_VERSION || '1.0.0',
    env: process.env.NODE_ENV || 'development',
  },

  // 타임스탬프 포맷
  timestamp: pino.stdTimeFunctions.isoTime,

  // 프로덕션: JSON, 개발: Pretty print
  transport: isProduction
    ? undefined
    : {
        target: 'pino-pretty',
        options: {
          colorize: true,
          translateTime: 'SYS:standard',
          ignore: 'pid,hostname',
        },
      },

  // 민감 정보 제거
  redact: {
    paths: [
      'req.headers.authorization',
      'req.headers.cookie',
      'res.headers["set-cookie"]',
      'body.password',
      'body.token',
      'body.creditCard',
      '*.password',
      '*.secret',
      '*.apiKey',
    ],
    censor: '[REDACTED]',
  },

  // 직렬화 설정
  serializers: {
    req: pino.stdSerializers.req,
    res: pino.stdSerializers.res,
    err: pino.stdSerializers.err,
  },
});

// 자식 로거 생성
export function createLogger(context: Record<string, unknown>) {
  return logger.child(context);
}

// 요청별 로거
export function createRequestLogger(requestId: string, userId?: string) {
  return logger.child({
    requestId,
    userId,
  });
}
```

### Express 미들웨어

```typescript
// src/middleware/logging.ts
import { Request, Response, NextFunction } from 'express';
import { randomUUID } from 'crypto';
import { logger, createRequestLogger } from '../logger';

declare global {
  namespace Express {
    interface Request {
      log: ReturnType<typeof createRequestLogger>;
      requestId: string;
    }
  }
}

export function loggingMiddleware(req: Request, res: Response, next: NextFunction) {
  const requestId = req.headers['x-request-id'] as string || randomUUID();
  const userId = req.user?.id;

  req.requestId = requestId;
  req.log = createRequestLogger(requestId, userId);

  // 요청 시작 로그
  req.log.info({
    type: 'request_start',
    method: req.method,
    url: req.url,
    query: req.query,
    userAgent: req.headers['user-agent'],
    ip: req.ip,
  });

  const start = process.hrtime.bigint();

  res.on('finish', () => {
    const duration = Number(process.hrtime.bigint() - start) / 1e6; // ms

    const logData = {
      type: 'request_end',
      method: req.method,
      url: req.url,
      status: res.statusCode,
      duration,
      contentLength: res.get('content-length'),
    };

    if (res.statusCode >= 500) {
      req.log.error(logData);
    } else if (res.statusCode >= 400) {
      req.log.warn(logData);
    } else {
      req.log.info(logData);
    }
  });

  // Response에 request ID 추가
  res.setHeader('X-Request-Id', requestId);

  next();
}

// 에러 로깅 미들웨어
export function errorLoggingMiddleware(
  err: Error,
  req: Request,
  res: Response,
  next: NextFunction
) {
  req.log.error({
    type: 'error',
    error: {
      name: err.name,
      message: err.message,
      stack: err.stack,
    },
    method: req.method,
    url: req.url,
  });

  next(err);
}
```

### 비즈니스 로직 로깅

```typescript
// src/services/order.service.ts
import { createLogger } from '../logger';

const log = createLogger({ module: 'order-service' });

export class OrderService {
  async createOrder(userId: string, items: OrderItem[]) {
    const orderId = generateOrderId();

    log.info({
      event: 'order_created',
      orderId,
      userId,
      itemCount: items.length,
      totalAmount: calculateTotal(items),
    });

    try {
      const order = await this.processOrder(orderId, userId, items);

      log.info({
        event: 'order_processed',
        orderId,
        status: order.status,
      });

      return order;
    } catch (error) {
      log.error({
        event: 'order_failed',
        orderId,
        userId,
        error: error instanceof Error ? error.message : 'Unknown error',
      });
      throw error;
    }
  }
}
```

## ELK Stack 설정

### Docker Compose

```yaml
# docker-compose.elk.yml
version: '3.8'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    volumes:
      - elasticsearch-data:/usr/share/elasticsearch/data
    ports:
      - "9200:9200"
    networks:
      - elk
    healthcheck:
      test: curl -s http://localhost:9200 >/dev/null || exit 1
      interval: 30s
      timeout: 10s
      retries: 5

  logstash:
    image: docker.elastic.co/logstash/logstash:8.11.0
    container_name: logstash
    volumes:
      - ./logstash/pipeline:/usr/share/logstash/pipeline:ro
      - ./logstash/config/logstash.yml:/usr/share/logstash/config/logstash.yml:ro
    ports:
      - "5044:5044"
      - "5000:5000/tcp"
      - "5000:5000/udp"
      - "9600:9600"
    environment:
      LS_JAVA_OPTS: "-Xmx256m -Xms256m"
    networks:
      - elk
    depends_on:
      elasticsearch:
        condition: service_healthy

  kibana:
    image: docker.elastic.co/kibana/kibana:8.11.0
    container_name: kibana
    ports:
      - "5601:5601"
    environment:
      ELASTICSEARCH_HOSTS: '["http://elasticsearch:9200"]'
    networks:
      - elk
    depends_on:
      elasticsearch:
        condition: service_healthy

  filebeat:
    image: docker.elastic.co/beats/filebeat:8.11.0
    container_name: filebeat
    user: root
    volumes:
      - ./filebeat/filebeat.yml:/usr/share/filebeat/filebeat.yml:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - elk
    depends_on:
      - logstash

volumes:
  elasticsearch-data:

networks:
  elk:
    driver: bridge
```

### Logstash Pipeline

```conf
# logstash/pipeline/logstash.conf
input {
  beats {
    port => 5044
  }

  tcp {
    port => 5000
    codec => json_lines
  }
}

filter {
  # JSON 파싱
  if [message] =~ /^\{.*\}$/ {
    json {
      source => "message"
      target => "parsed"
    }

    # 파싱된 필드를 최상위로 이동
    mutate {
      rename => {
        "[parsed][level]" => "level"
        "[parsed][time]" => "@timestamp"
        "[parsed][msg]" => "message"
        "[parsed][service]" => "service"
        "[parsed][requestId]" => "requestId"
        "[parsed][userId]" => "userId"
        "[parsed][method]" => "http_method"
        "[parsed][url]" => "http_url"
        "[parsed][status]" => "http_status"
        "[parsed][duration]" => "duration_ms"
      }
      remove_field => ["parsed"]
    }
  }

  # 레벨 숫자를 텍스트로 변환 (Pino)
  if [level] {
    translate {
      field => "level"
      destination => "log_level"
      dictionary => {
        "10" => "trace"
        "20" => "debug"
        "30" => "info"
        "40" => "warn"
        "50" => "error"
        "60" => "fatal"
      }
      fallback => "unknown"
    }
  }

  # GeoIP (선택적)
  if [ip] {
    geoip {
      source => "ip"
      target => "geoip"
    }
  }

  # User Agent 파싱
  if [userAgent] {
    useragent {
      source => "userAgent"
      target => "ua"
    }
  }
}

output {
  elasticsearch {
    hosts => ["http://elasticsearch:9200"]
    index => "logs-%{[service]}-%{+YYYY.MM.dd}"
  }

  # 디버그용 stdout
  # stdout { codec => rubydebug }
}
```

### Filebeat 설정

```yaml
# filebeat/filebeat.yml
filebeat.inputs:
  - type: container
    paths:
      - '/var/lib/docker/containers/*/*.log'
    processors:
      - add_docker_metadata:
          host: "unix:///var/run/docker.sock"

filebeat.autodiscover:
  providers:
    - type: docker
      hints.enabled: true

processors:
  - decode_json_fields:
      fields: ["message"]
      target: ""
      overwrite_keys: true
      add_error_key: true

output.logstash:
  hosts: ["logstash:5044"]
```

## 로그 보존 정책

```typescript
// scripts/log-retention.ts
import { Client } from '@elastic/elasticsearch';

const client = new Client({ node: 'http://elasticsearch:9200' });

interface RetentionPolicy {
  pattern: string;
  retentionDays: number;
}

const policies: RetentionPolicy[] = [
  { pattern: 'logs-api-server-*', retentionDays: 30 },
  { pattern: 'logs-audit-*', retentionDays: 365 },
  { pattern: 'logs-error-*', retentionDays: 90 },
  { pattern: 'logs-debug-*', retentionDays: 7 },
];

async function applyRetentionPolicies() {
  for (const policy of policies) {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - policy.retentionDays);

    const indices = await client.cat.indices({
      index: policy.pattern,
      format: 'json',
    });

    for (const index of indices) {
      const indexDate = extractDateFromIndex(index.index!);

      if (indexDate && indexDate < cutoffDate) {
        console.log(`Deleting index: ${index.index}`);
        await client.indices.delete({ index: index.index! });
      }
    }
  }
}

function extractDateFromIndex(indexName: string): Date | null {
  const match = indexName.match(/(\d{4}\.\d{2}\.\d{2})$/);
  if (match) {
    const [year, month, day] = match[1].split('.').map(Number);
    return new Date(year, month - 1, day);
  }
  return null;
}

// ILM (Index Lifecycle Management) 정책
async function createILMPolicy() {
  await client.ilm.putLifecycle({
    policy: 'logs-lifecycle',
    body: {
      policy: {
        phases: {
          hot: {
            min_age: '0ms',
            actions: {
              rollover: {
                max_size: '50gb',
                max_age: '1d',
              },
            },
          },
          warm: {
            min_age: '7d',
            actions: {
              shrink: { number_of_shards: 1 },
              forcemerge: { max_num_segments: 1 },
            },
          },
          cold: {
            min_age: '30d',
            actions: {
              searchable_snapshot: {
                snapshot_repository: 's3-repository',
              },
            },
          },
          delete: {
            min_age: '90d',
            actions: {
              delete: {},
            },
          },
        },
      },
    },
  });
}
```

## Kibana 대시보드 쿼리

```json
{
  "saved_objects": [
    {
      "type": "search",
      "attributes": {
        "title": "Error Logs",
        "kibanaSavedObjectMeta": {
          "searchSourceJSON": {
            "index": "logs-*",
            "query": {
              "bool": {
                "must": [
                  { "match": { "log_level": "error" } }
                ]
              }
            }
          }
        }
      }
    },
    {
      "type": "visualization",
      "attributes": {
        "title": "Logs by Level",
        "visState": {
          "type": "pie",
          "aggs": [
            {
              "type": "count",
              "schema": "metric"
            },
            {
              "type": "terms",
              "field": "log_level.keyword",
              "schema": "segment"
            }
          ]
        }
      }
    }
  ]
}
```

## 사용 예시
**입력**: "구조화 로깅 시스템 설정해줘"

**출력**:
1. Pino 로거 설정
2. Express 미들웨어
3. ELK Stack 구성
4. 로그 보존 정책
