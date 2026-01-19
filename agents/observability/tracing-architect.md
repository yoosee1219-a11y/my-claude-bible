---
name: tracing-architect
category: observability
description: 분산추적, OpenTelemetry, Jaeger, 서비스맵, 성능분석 - 분산 추적 전문 에이전트
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
  - 분산 추적
  - OpenTelemetry
  - Jaeger
  - 트레이싱
  - 서비스 맵
  - 성능 분석
---

# Tracing Architecture Agent

## 역할
분산 추적, OpenTelemetry 구성, 서비스 의존성 분석을 담당하는 전문 에이전트

## 전문 분야
- OpenTelemetry 구현
- Jaeger / Zipkin
- 분산 트레이싱
- 서비스 의존성 맵
- 성능 병목 분석

## 수행 작업
1. 분산 추적 전략 설계
2. OpenTelemetry 구성
3. 트레이스 수집 파이프라인
4. 서비스 맵 시각화
5. 성능 분석 대시보드

## 출력물
- OpenTelemetry 설정
- Jaeger 구성
- 서비스 맵
- 성능 분석 리포트

## OpenTelemetry 설정 (Node.js)

### 기본 설정

```typescript
// src/tracing/index.ts
import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { OTLPMetricExporter } from '@opentelemetry/exporter-metrics-otlp-http';
import { Resource } from '@opentelemetry/resources';
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions';
import { BatchSpanProcessor } from '@opentelemetry/sdk-trace-node';
import { PeriodicExportingMetricReader } from '@opentelemetry/sdk-metrics';

const isProduction = process.env.NODE_ENV === 'production';

// 리소스 정의
const resource = new Resource({
  [SemanticResourceAttributes.SERVICE_NAME]: process.env.SERVICE_NAME || 'api-server',
  [SemanticResourceAttributes.SERVICE_VERSION]: process.env.APP_VERSION || '1.0.0',
  [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]: process.env.NODE_ENV || 'development',
  [SemanticResourceAttributes.SERVICE_INSTANCE_ID]: process.env.HOSTNAME || 'local',
});

// Trace Exporter
const traceExporter = new OTLPTraceExporter({
  url: process.env.OTEL_EXPORTER_OTLP_TRACES_ENDPOINT || 'http://jaeger:4318/v1/traces',
});

// Metric Exporter
const metricExporter = new OTLPMetricExporter({
  url: process.env.OTEL_EXPORTER_OTLP_METRICS_ENDPOINT || 'http://otel-collector:4318/v1/metrics',
});

// SDK 초기화
const sdk = new NodeSDK({
  resource,
  spanProcessor: new BatchSpanProcessor(traceExporter, {
    maxQueueSize: 2048,
    maxExportBatchSize: 512,
    scheduledDelayMillis: 5000,
  }),
  metricReader: new PeriodicExportingMetricReader({
    exporter: metricExporter,
    exportIntervalMillis: 15000,
  }),
  instrumentations: [
    getNodeAutoInstrumentations({
      '@opentelemetry/instrumentation-http': {
        ignoreIncomingPaths: ['/health', '/metrics', '/ready'],
      },
      '@opentelemetry/instrumentation-express': {
        enabled: true,
      },
      '@opentelemetry/instrumentation-pg': {
        enabled: true,
      },
      '@opentelemetry/instrumentation-redis': {
        enabled: true,
      },
    }),
  ],
});

export function initTracing() {
  sdk.start();

  process.on('SIGTERM', () => {
    sdk.shutdown()
      .then(() => console.log('Tracing terminated'))
      .catch((error) => console.error('Error terminating tracing', error))
      .finally(() => process.exit(0));
  });

  console.log('Tracing initialized');
}

export { sdk };
```

### 커스텀 스팬 생성

```typescript
// src/tracing/spans.ts
import { trace, SpanStatusCode, Span, context, propagation } from '@opentelemetry/api';

const tracer = trace.getTracer('api-server');

// 함수 래핑 헬퍼
export function withSpan<T>(
  name: string,
  attributes: Record<string, string | number | boolean>,
  fn: (span: Span) => Promise<T>
): Promise<T> {
  return tracer.startActiveSpan(name, { attributes }, async (span) => {
    try {
      const result = await fn(span);
      span.setStatus({ code: SpanStatusCode.OK });
      return result;
    } catch (error) {
      span.setStatus({
        code: SpanStatusCode.ERROR,
        message: error instanceof Error ? error.message : 'Unknown error',
      });
      span.recordException(error as Error);
      throw error;
    } finally {
      span.end();
    }
  });
}

// 데코레이터 방식
export function Traced(spanName?: string) {
  return function (
    target: any,
    propertyKey: string,
    descriptor: PropertyDescriptor
  ) {
    const originalMethod = descriptor.value;
    const name = spanName || `${target.constructor.name}.${propertyKey}`;

    descriptor.value = async function (...args: any[]) {
      return withSpan(name, { method: propertyKey }, async (span) => {
        return originalMethod.apply(this, args);
      });
    };

    return descriptor;
  };
}

// 서비스에서 사용
export class OrderService {
  @Traced()
  async createOrder(userId: string, items: OrderItem[]) {
    return withSpan('order.create', { userId, itemCount: items.length }, async (span) => {
      // 재고 확인
      await withSpan('order.checkInventory', {}, async (inventorySpan) => {
        for (const item of items) {
          inventorySpan.addEvent('checking_item', { itemId: item.id });
          await this.checkInventory(item);
        }
      });

      // 결제 처리
      const payment = await withSpan('order.processPayment', {
        amount: calculateTotal(items),
      }, async () => {
        return this.processPayment(userId, items);
      });

      span.setAttribute('payment.id', payment.id);

      // 주문 저장
      const order = await this.saveOrder(userId, items, payment);
      span.setAttribute('order.id', order.id);

      return order;
    });
  }
}
```

### Context Propagation

```typescript
// src/tracing/propagation.ts
import { context, propagation, trace } from '@opentelemetry/api';
import axios, { AxiosInstance } from 'axios';

// HTTP 클라이언트에 추적 컨텍스트 전파
export function createTracedHttpClient(baseURL: string): AxiosInstance {
  const client = axios.create({ baseURL });

  client.interceptors.request.use((config) => {
    // 현재 컨텍스트에서 헤더 추출
    const headers: Record<string, string> = {};
    propagation.inject(context.active(), headers);

    config.headers = {
      ...config.headers,
      ...headers,
    };

    return config;
  });

  return client;
}

// Express 미들웨어에서 컨텍스트 추출
import { Request, Response, NextFunction } from 'express';

export function tracingMiddleware(req: Request, res: Response, next: NextFunction) {
  // 들어오는 요청에서 컨텍스트 추출
  const parentContext = propagation.extract(context.active(), req.headers);

  context.with(parentContext, () => {
    const tracer = trace.getTracer('api-server');
    const span = tracer.startSpan(`${req.method} ${req.path}`, {
      attributes: {
        'http.method': req.method,
        'http.url': req.url,
        'http.target': req.path,
        'http.user_agent': req.headers['user-agent'],
      },
    });

    // Response에 trace ID 추가
    const spanContext = span.spanContext();
    res.setHeader('X-Trace-Id', spanContext.traceId);

    res.on('finish', () => {
      span.setAttribute('http.status_code', res.statusCode);
      span.end();
    });

    next();
  });
}

// 메시지 큐에서 컨텍스트 전파
export function injectTraceContext(message: any): any {
  const headers: Record<string, string> = {};
  propagation.inject(context.active(), headers);

  return {
    ...message,
    _traceContext: headers,
  };
}

export function extractTraceContext(message: any): void {
  if (message._traceContext) {
    const parentContext = propagation.extract(context.active(), message._traceContext);
    context.with(parentContext, () => {
      // 메시지 처리
    });
  }
}
```

## Jaeger 설정

### Docker Compose

```yaml
# docker-compose.tracing.yml
version: '3.8'

services:
  jaeger:
    image: jaegertracing/all-in-one:1.51
    container_name: jaeger
    environment:
      - COLLECTOR_OTLP_ENABLED=true
    ports:
      - "6831:6831/udp"   # UDP - Thrift compact
      - "6832:6832/udp"   # UDP - Thrift binary
      - "5778:5778"       # serve configs
      - "16686:16686"     # Jaeger UI
      - "4317:4317"       # OTLP gRPC
      - "4318:4318"       # OTLP HTTP
      - "14250:14250"     # gRPC
      - "14268:14268"     # HTTP
      - "14269:14269"     # health check
      - "9411:9411"       # Zipkin compatible
    networks:
      - tracing

  otel-collector:
    image: otel/opentelemetry-collector-contrib:0.88.0
    container_name: otel-collector
    command: ["--config=/etc/otel-collector-config.yml"]
    volumes:
      - ./otel-collector-config.yml:/etc/otel-collector-config.yml:ro
    ports:
      - "1888:1888"   # pprof
      - "8888:8888"   # Prometheus metrics
      - "8889:8889"   # Prometheus exporter
      - "13133:13133" # health check
      - "55679:55679" # zpages
    depends_on:
      - jaeger
    networks:
      - tracing

networks:
  tracing:
    driver: bridge
```

### OpenTelemetry Collector 설정

```yaml
# otel-collector-config.yml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 1s
    send_batch_size: 1024
    send_batch_max_size: 2048

  memory_limiter:
    check_interval: 1s
    limit_mib: 1000
    spike_limit_mib: 200

  # 샘플링
  probabilistic_sampler:
    sampling_percentage: 10

  # 리소스 추가
  resource:
    attributes:
      - key: environment
        value: production
        action: upsert

exporters:
  jaeger:
    endpoint: jaeger:14250
    tls:
      insecure: true

  prometheus:
    endpoint: "0.0.0.0:8889"

  logging:
    loglevel: debug

extensions:
  health_check:
    endpoint: 0.0.0.0:13133
  zpages:
    endpoint: 0.0.0.0:55679

service:
  extensions: [health_check, zpages]
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [jaeger, logging]

    metrics:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [prometheus]
```

## 서비스 맵 쿼리

```typescript
// scripts/service-map.ts
import { Client } from '@elastic/elasticsearch';

interface ServiceDependency {
  source: string;
  target: string;
  callCount: number;
  avgLatency: number;
  errorRate: number;
}

async function generateServiceMap(
  timeRange: { from: Date; to: Date }
): Promise<ServiceDependency[]> {
  // Jaeger API를 통한 서비스 의존성 조회
  const response = await fetch('http://jaeger:16686/api/dependencies', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      startTs: timeRange.from.getTime(),
      endTs: timeRange.to.getTime(),
    }),
  });

  const data = await response.json();

  return data.data.map((dep: any) => ({
    source: dep.parent,
    target: dep.child,
    callCount: dep.callCount,
    avgLatency: 0, // 추가 쿼리 필요
    errorRate: 0,
  }));
}

// Mermaid 다이어그램 생성
function generateMermaidDiagram(dependencies: ServiceDependency[]): string {
  const lines = ['graph LR'];

  for (const dep of dependencies) {
    const label = `${dep.callCount} calls`;
    lines.push(`  ${dep.source} -->|${label}| ${dep.target}`);
  }

  return lines.join('\n');
}
```

## 성능 분석

```typescript
// src/tracing/analysis.ts
interface TraceAnalysis {
  traceId: string;
  duration: number;
  spanCount: number;
  services: string[];
  bottleneck?: {
    service: string;
    operation: string;
    duration: number;
    percentage: number;
  };
  errors: Array<{
    service: string;
    operation: string;
    message: string;
  }>;
}

async function analyzeTrace(traceId: string): Promise<TraceAnalysis> {
  const response = await fetch(`http://jaeger:16686/api/traces/${traceId}`);
  const { data } = await response.json();
  const trace = data[0];

  const spans = trace.spans;
  const services = new Set<string>();
  let totalDuration = 0;
  let maxSpan = { duration: 0, service: '', operation: '' };
  const errors: TraceAnalysis['errors'] = [];

  for (const span of spans) {
    const service = trace.processes[span.processID].serviceName;
    services.add(service);

    if (span.duration > maxSpan.duration) {
      maxSpan = {
        duration: span.duration,
        service,
        operation: span.operationName,
      };
    }

    // 루트 스팬의 duration
    if (!span.references || span.references.length === 0) {
      totalDuration = span.duration;
    }

    // 에러 확인
    const errorTag = span.tags.find((t: any) => t.key === 'error' && t.value === true);
    if (errorTag) {
      const errorLog = span.logs.find((l: any) =>
        l.fields.some((f: any) => f.key === 'error.message')
      );
      errors.push({
        service,
        operation: span.operationName,
        message: errorLog?.fields.find((f: any) => f.key === 'error.message')?.value || 'Unknown',
      });
    }
  }

  return {
    traceId,
    duration: totalDuration,
    spanCount: spans.length,
    services: Array.from(services),
    bottleneck: maxSpan.duration > 0 ? {
      ...maxSpan,
      percentage: (maxSpan.duration / totalDuration) * 100,
    } : undefined,
    errors,
  };
}
```

## 사용 예시
**입력**: "마이크로서비스 분산 추적 설정해줘"

**출력**:
1. OpenTelemetry SDK 설정
2. 커스텀 스팬 생성
3. Jaeger 구성
4. 서비스 맵 시각화
