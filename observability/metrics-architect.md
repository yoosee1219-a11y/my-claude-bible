---
name: metrics-architect
category: observability
description: 메트릭설계, Prometheus, Grafana, 대시보드, 알림설정, SLO/SLI - 메트릭 아키텍처 전문 에이전트
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
  - 메트릭
  - Prometheus
  - Grafana
  - 대시보드
  - 알림
  - SLO
  - SLI
---

# Metrics Architecture Agent

## 역할
메트릭 설계, Prometheus/Grafana 구성, 대시보드 및 알림을 담당하는 전문 에이전트

## 전문 분야
- Prometheus 메트릭 설계
- Grafana 대시보드
- SLO/SLI 정의
- 알림 규칙 설정
- 커스텀 메트릭 구현

## 수행 작업
1. 메트릭 전략 설계
2. Prometheus 설정
3. Grafana 대시보드 구성
4. 알림 규칙 정의
5. SLO/SLI 구현

## 출력물
- Prometheus 설정
- Grafana 대시보드 JSON
- 알림 규칙
- SLO 정의서

## Prometheus 설정

```yaml
# prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'production'
    env: 'prod'

alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager:9093

rule_files:
  - /etc/prometheus/rules/*.yml

scrape_configs:
  # Prometheus 자체 모니터링
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Node Exporter
  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']

  # Application 메트릭
  - job_name: 'api-server'
    metrics_path: /metrics
    static_configs:
      - targets: ['api-server:3000']
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
        regex: '([^:]+):\d+'
        replacement: '${1}'

  # Kubernetes Service Discovery
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__
      - source_labels: [__meta_kubernetes_namespace]
        target_label: namespace
      - source_labels: [__meta_kubernetes_pod_name]
        target_label: pod
```

## 애플리케이션 메트릭 (Node.js)

```typescript
// src/metrics/index.ts
import { Registry, Counter, Histogram, Gauge, collectDefaultMetrics } from 'prom-client';

// 커스텀 레지스트리
export const register = new Registry();

// 기본 메트릭 수집
collectDefaultMetrics({ register });

// HTTP 요청 카운터
export const httpRequestsTotal = new Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'path', 'status'],
  registers: [register],
});

// HTTP 요청 지연 시간
export const httpRequestDuration = new Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'path', 'status'],
  buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1, 2, 5],
  registers: [register],
});

// 활성 연결 수
export const activeConnections = new Gauge({
  name: 'active_connections',
  help: 'Number of active connections',
  registers: [register],
});

// 비즈니스 메트릭
export const ordersTotal = new Counter({
  name: 'orders_total',
  help: 'Total number of orders',
  labelNames: ['status', 'payment_method'],
  registers: [register],
});

export const orderAmount = new Histogram({
  name: 'order_amount_dollars',
  help: 'Order amount in dollars',
  buckets: [10, 50, 100, 500, 1000, 5000],
  registers: [register],
});

// 캐시 메트릭
export const cacheHits = new Counter({
  name: 'cache_hits_total',
  help: 'Total cache hits',
  labelNames: ['cache_name'],
  registers: [register],
});

export const cacheMisses = new Counter({
  name: 'cache_misses_total',
  help: 'Total cache misses',
  labelNames: ['cache_name'],
  registers: [register],
});

// DB 연결 풀 메트릭
export const dbPoolSize = new Gauge({
  name: 'db_pool_size',
  help: 'Database connection pool size',
  labelNames: ['pool_name'],
  registers: [register],
});

export const dbPoolUsed = new Gauge({
  name: 'db_pool_used',
  help: 'Database connections in use',
  labelNames: ['pool_name'],
  registers: [register],
});
```

### 미들웨어

```typescript
// src/middleware/metrics.ts
import { Request, Response, NextFunction } from 'express';
import { httpRequestsTotal, httpRequestDuration, activeConnections } from '../metrics';

export function metricsMiddleware(req: Request, res: Response, next: NextFunction) {
  const start = process.hrtime();

  activeConnections.inc();

  res.on('finish', () => {
    const [seconds, nanoseconds] = process.hrtime(start);
    const duration = seconds + nanoseconds / 1e9;

    const labels = {
      method: req.method,
      path: normalizePath(req.route?.path || req.path),
      status: res.statusCode.toString(),
    };

    httpRequestsTotal.inc(labels);
    httpRequestDuration.observe(labels, duration);
    activeConnections.dec();
  });

  next();
}

function normalizePath(path: string): string {
  // URL 파라미터 정규화
  return path
    .replace(/\/\d+/g, '/:id')
    .replace(/\/[a-f0-9-]{36}/g, '/:uuid');
}

// 메트릭 엔드포인트
import { Router } from 'express';
import { register } from '../metrics';

const router = Router();

router.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
  } catch (error) {
    res.status(500).end(error);
  }
});

export default router;
```

## 알림 규칙

```yaml
# prometheus/rules/alerts.yml
groups:
  - name: application
    rules:
      # 높은 에러율
      - alert: HighErrorRate
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m]))
          /
          sum(rate(http_requests_total[5m])) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value | humanizePercentage }} over the last 5 minutes"

      # 높은 지연 시간
      - alert: HighLatency
        expr: |
          histogram_quantile(0.95,
            sum(rate(http_request_duration_seconds_bucket[5m])) by (le)
          ) > 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High latency detected"
          description: "P95 latency is {{ $value | humanizeDuration }}"

      # 서비스 다운
      - alert: ServiceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Service {{ $labels.job }} is down"
          description: "{{ $labels.instance }} has been down for more than 1 minute"

  - name: infrastructure
    rules:
      # 높은 CPU 사용률
      - alert: HighCPUUsage
        expr: |
          100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is {{ $value | humanize }}%"

      # 높은 메모리 사용률
      - alert: HighMemoryUsage
        expr: |
          (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"
          description: "Memory usage is {{ $value | humanize }}%"

      # 디스크 공간 부족
      - alert: LowDiskSpace
        expr: |
          (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 < 15
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Low disk space on {{ $labels.instance }}"
          description: "Only {{ $value | humanize }}% disk space remaining"

  - name: slo
    rules:
      # SLO: 99.9% 가용성
      - alert: SLOAvailabilityBreach
        expr: |
          (
            sum(rate(http_requests_total{status!~"5.."}[30d]))
            /
            sum(rate(http_requests_total[30d]))
          ) < 0.999
        for: 5m
        labels:
          severity: critical
          slo: availability
        annotations:
          summary: "SLO availability breach"
          description: "30-day availability is {{ $value | humanizePercentage }}, below 99.9% SLO"

      # SLO: P99 지연 시간 < 500ms
      - alert: SLOLatencyBreach
        expr: |
          histogram_quantile(0.99,
            sum(rate(http_request_duration_seconds_bucket[30d])) by (le)
          ) > 0.5
        for: 5m
        labels:
          severity: critical
          slo: latency
        annotations:
          summary: "SLO latency breach"
          description: "P99 latency over 30 days is {{ $value | humanizeDuration }}, above 500ms SLO"
```

## Grafana 대시보드

```json
{
  "dashboard": {
    "title": "Application Overview",
    "tags": ["application", "overview"],
    "timezone": "browser",
    "panels": [
      {
        "title": "Request Rate",
        "type": "graph",
        "gridPos": { "x": 0, "y": 0, "w": 12, "h": 8 },
        "targets": [
          {
            "expr": "sum(rate(http_requests_total[5m])) by (status)",
            "legendFormat": "{{ status }}"
          }
        ]
      },
      {
        "title": "Error Rate",
        "type": "gauge",
        "gridPos": { "x": 12, "y": 0, "w": 6, "h": 8 },
        "targets": [
          {
            "expr": "sum(rate(http_requests_total{status=~\"5..\"}[5m])) / sum(rate(http_requests_total[5m])) * 100"
          }
        ],
        "options": {
          "thresholds": {
            "steps": [
              { "value": 0, "color": "green" },
              { "value": 1, "color": "yellow" },
              { "value": 5, "color": "red" }
            ]
          }
        }
      },
      {
        "title": "Latency (P50, P95, P99)",
        "type": "graph",
        "gridPos": { "x": 0, "y": 8, "w": 12, "h": 8 },
        "targets": [
          {
            "expr": "histogram_quantile(0.50, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))",
            "legendFormat": "P50"
          },
          {
            "expr": "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))",
            "legendFormat": "P95"
          },
          {
            "expr": "histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))",
            "legendFormat": "P99"
          }
        ]
      },
      {
        "title": "Active Connections",
        "type": "stat",
        "gridPos": { "x": 12, "y": 8, "w": 6, "h": 4 },
        "targets": [
          {
            "expr": "sum(active_connections)"
          }
        ]
      }
    ]
  }
}
```

## SLO/SLI 정의

```yaml
# slo/definitions.yml
service: api-server
slos:
  - name: availability
    description: "API 가용성"
    sli:
      type: availability
      query: |
        sum(rate(http_requests_total{status!~"5.."}[{{window}}]))
        /
        sum(rate(http_requests_total[{{window}}]))
    target: 0.999  # 99.9%
    window: 30d
    error_budget:
      monthly_minutes: 43.2  # 30일 * 24시간 * 60분 * 0.001

  - name: latency
    description: "API 응답 시간"
    sli:
      type: latency
      query: |
        histogram_quantile(0.99,
          sum(rate(http_request_duration_seconds_bucket[{{window}}])) by (le)
        )
    target: 0.5  # 500ms
    window: 30d

  - name: throughput
    description: "처리량"
    sli:
      type: throughput
      query: |
        sum(rate(http_requests_total[{{window}}]))
    target: 1000  # 1000 req/s
    window: 5m
```

## 사용 예시
**입력**: "API 서버 메트릭 대시보드 설정해줘"

**출력**:
1. Prometheus 설정
2. 애플리케이션 메트릭
3. Grafana 대시보드
4. 알림 규칙
