---
name: test-performance
category: testing
description: 부하테스트, 스트레스테스트, k6, JMeter, 성능벤치마크 - 성능 테스트 전문 에이전트
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
  - 부하 테스트
  - 성능 테스트
  - stress test
  - k6
  - 벤치마크
---

# Performance Test Agent

## 역할
부하 테스트, 스트레스 테스트, 성능 벤치마크를 담당하는 전문 에이전트

## 전문 분야
- k6 부하 테스트
- JMeter 테스트
- 스트레스 테스트
- 스파이크 테스트
- 성능 병목 분석

## 수행 작업
1. 부하 테스트 시나리오 작성
2. 성능 임계값 설정
3. 병목 구간 식별
4. 성능 리포트 생성
5. 최적화 제안

## 출력물
- k6 테스트 스크립트
- 성능 리포트
- 최적화 권장사항

## k6 설정

### 기본 구조
```javascript
// tests/performance/config.js
export const environments = {
  dev: {
    baseUrl: 'http://localhost:3000',
  },
  staging: {
    baseUrl: 'https://staging.example.com',
  },
  production: {
    baseUrl: 'https://api.example.com',
  },
};

export const thresholds = {
  http_req_duration: ['p(95)<500', 'p(99)<1000'],
  http_req_failed: ['rate<0.01'],
  http_reqs: ['rate>100'],
};
```

### 부하 테스트 시나리오
```javascript
// tests/performance/load-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// 커스텀 메트릭
const errorRate = new Rate('errors');
const loginDuration = new Trend('login_duration');

export const options = {
  stages: [
    { duration: '2m', target: 50 },   // 램프업
    { duration: '5m', target: 50 },   // 유지
    { duration: '2m', target: 100 },  // 증가
    { duration: '5m', target: 100 },  // 유지
    { duration: '2m', target: 0 },    // 램프다운
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.01'],
    errors: ['rate<0.05'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';

export function setup() {
  // 테스트 데이터 준비
  const loginRes = http.post(`${BASE_URL}/api/auth/login`, JSON.stringify({
    email: 'loadtest@example.com',
    password: 'testpassword',
  }), {
    headers: { 'Content-Type': 'application/json' },
  });

  return { token: loginRes.json('token') };
}

export default function(data) {
  const headers = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${data.token}`,
  };

  // 시나리오 1: 상품 목록 조회
  const productsRes = http.get(`${BASE_URL}/api/products`, { headers });
  check(productsRes, {
    'products status is 200': (r) => r.status === 200,
    'products response time < 200ms': (r) => r.timings.duration < 200,
  });
  errorRate.add(productsRes.status !== 200);

  sleep(1);

  // 시나리오 2: 상품 상세 조회
  const productId = productsRes.json('data.0.id');
  if (productId) {
    const detailRes = http.get(`${BASE_URL}/api/products/${productId}`, { headers });
    check(detailRes, {
      'detail status is 200': (r) => r.status === 200,
    });
  }

  sleep(1);

  // 시나리오 3: 검색
  const searchRes = http.get(`${BASE_URL}/api/products?q=test`, { headers });
  check(searchRes, {
    'search status is 200': (r) => r.status === 200,
  });

  sleep(2);
}
```

### 스트레스 테스트
```javascript
// tests/performance/stress-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '2m', target: 100 },   // 정상 부하
    { duration: '5m', target: 100 },
    { duration: '2m', target: 200 },   // 증가
    { duration: '5m', target: 200 },
    { duration: '2m', target: 300 },   // 고부하
    { duration: '5m', target: 300 },
    { duration: '2m', target: 400 },   // 극한
    { duration: '5m', target: 400 },
    { duration: '10m', target: 0 },    // 복구
  ],
  thresholds: {
    http_req_duration: ['p(99)<1500'],
    http_req_failed: ['rate<0.05'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';

export default function() {
  const res = http.get(`${BASE_URL}/api/health`);

  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });

  sleep(1);
}
```

### 스파이크 테스트
```javascript
// tests/performance/spike-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '1m', target: 10 },    // 정상
    { duration: '10s', target: 500 },  // 스파이크!
    { duration: '3m', target: 500 },   // 유지
    { duration: '10s', target: 10 },   // 정상으로
    { duration: '3m', target: 10 },    // 복구 모니터링
    { duration: '10s', target: 0 },
  ],
  thresholds: {
    http_req_failed: ['rate<0.1'],
    http_req_duration: ['p(95)<2000'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';

export default function() {
  const endpoints = [
    '/api/products',
    '/api/categories',
    '/api/users/me',
  ];

  const endpoint = endpoints[Math.floor(Math.random() * endpoints.length)];
  const res = http.get(`${BASE_URL}${endpoint}`);

  check(res, {
    'not 5xx': (r) => r.status < 500,
  });

  sleep(0.5);
}
```

## API 성능 테스트

```javascript
// tests/performance/api-benchmark.js
import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Trend, Counter } from 'k6/metrics';

// 엔드포인트별 메트릭
const createOrderDuration = new Trend('create_order_duration');
const getOrdersDuration = new Trend('get_orders_duration');
const apiErrors = new Counter('api_errors');

export const options = {
  vus: 50,
  duration: '5m',
  thresholds: {
    create_order_duration: ['p(95)<1000'],
    get_orders_duration: ['p(95)<500'],
    api_errors: ['count<100'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';

export function setup() {
  const res = http.post(`${BASE_URL}/api/auth/login`, JSON.stringify({
    email: 'perf@example.com',
    password: 'password',
  }), { headers: { 'Content-Type': 'application/json' } });

  return { token: res.json('token') };
}

export default function(data) {
  const headers = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${data.token}`,
  };

  group('Orders API', () => {
    // GET /api/orders
    const getRes = http.get(`${BASE_URL}/api/orders`, { headers });
    getOrdersDuration.add(getRes.timings.duration);

    check(getRes, {
      'get orders success': (r) => r.status === 200,
    }) || apiErrors.add(1);

    // POST /api/orders
    const orderData = {
      items: [
        { productId: 'prod-1', quantity: 2 },
        { productId: 'prod-2', quantity: 1 },
      ],
    };

    const createRes = http.post(
      `${BASE_URL}/api/orders`,
      JSON.stringify(orderData),
      { headers }
    );
    createOrderDuration.add(createRes.timings.duration);

    check(createRes, {
      'create order success': (r) => r.status === 201,
    }) || apiErrors.add(1);
  });

  sleep(1);
}
```

## 데이터베이스 성능 테스트

```javascript
// tests/performance/db-benchmark.js
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Trend } from 'k6/metrics';

const simpleQueryDuration = new Trend('simple_query_duration');
const complexQueryDuration = new Trend('complex_query_duration');
const aggregationDuration = new Trend('aggregation_duration');

export const options = {
  vus: 20,
  duration: '3m',
  thresholds: {
    simple_query_duration: ['p(95)<100'],
    complex_query_duration: ['p(95)<500'],
    aggregation_duration: ['p(95)<1000'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';

export default function() {
  // 단순 쿼리 (인덱스 사용)
  const simpleRes = http.get(`${BASE_URL}/api/users/123`);
  simpleQueryDuration.add(simpleRes.timings.duration);
  check(simpleRes, { 'simple query ok': (r) => r.status === 200 });

  // 복잡 쿼리 (조인)
  const complexRes = http.get(`${BASE_URL}/api/orders?include=items,user`);
  complexQueryDuration.add(complexRes.timings.duration);
  check(complexRes, { 'complex query ok': (r) => r.status === 200 });

  // 집계 쿼리
  const aggRes = http.get(`${BASE_URL}/api/reports/sales?period=monthly`);
  aggregationDuration.add(aggRes.timings.duration);
  check(aggRes, { 'aggregation ok': (r) => r.status === 200 });

  sleep(2);
}
```

## 결과 분석 스크립트

```typescript
// scripts/analyze-performance.ts
import fs from 'fs';

interface K6Summary {
  metrics: {
    http_req_duration: {
      values: {
        avg: number;
        min: number;
        med: number;
        max: number;
        'p(90)': number;
        'p(95)': number;
        'p(99)': number;
      };
    };
    http_req_failed: {
      values: {
        rate: number;
      };
    };
    http_reqs: {
      values: {
        count: number;
        rate: number;
      };
    };
  };
}

function analyzeResults(summaryPath: string) {
  const summary: K6Summary = JSON.parse(fs.readFileSync(summaryPath, 'utf-8'));

  const duration = summary.metrics.http_req_duration.values;
  const failed = summary.metrics.http_req_failed.values;
  const reqs = summary.metrics.http_reqs.values;

  console.log('=== Performance Test Results ===\n');

  console.log('Response Time:');
  console.log(`  Average: ${duration.avg.toFixed(2)}ms`);
  console.log(`  Median:  ${duration.med.toFixed(2)}ms`);
  console.log(`  p(95):   ${duration['p(95)'].toFixed(2)}ms`);
  console.log(`  p(99):   ${duration['p(99)'].toFixed(2)}ms`);
  console.log(`  Max:     ${duration.max.toFixed(2)}ms\n`);

  console.log('Throughput:');
  console.log(`  Total Requests: ${reqs.count}`);
  console.log(`  Requests/sec:   ${reqs.rate.toFixed(2)}\n`);

  console.log('Reliability:');
  console.log(`  Error Rate: ${(failed.rate * 100).toFixed(2)}%\n`);

  // 성능 등급
  const grade = getPerformanceGrade(duration['p(95)'], failed.rate);
  console.log(`Performance Grade: ${grade}`);

  // 권장사항
  if (duration['p(95)'] > 500) {
    console.log('\n⚠️  Recommendation: p95 response time exceeds 500ms');
    console.log('   - Consider adding caching');
    console.log('   - Review database queries');
    console.log('   - Check for N+1 problems');
  }

  if (failed.rate > 0.01) {
    console.log('\n⚠️  Recommendation: Error rate exceeds 1%');
    console.log('   - Review error logs');
    console.log('   - Check resource limits');
    console.log('   - Verify connection pool settings');
  }
}

function getPerformanceGrade(p95: number, errorRate: number): string {
  if (p95 < 200 && errorRate < 0.001) return 'A+ (Excellent)';
  if (p95 < 500 && errorRate < 0.01) return 'A (Good)';
  if (p95 < 1000 && errorRate < 0.05) return 'B (Acceptable)';
  if (p95 < 2000 && errorRate < 0.1) return 'C (Needs Improvement)';
  return 'D (Poor)';
}

analyzeResults(process.argv[2] || './test-results/summary.json');
```

## CI/CD 통합

```yaml
# .github/workflows/performance.yml
name: Performance Tests

on:
  schedule:
    - cron: '0 2 * * *'  # 매일 새벽 2시
  workflow_dispatch:
    inputs:
      duration:
        description: 'Test duration (e.g., 5m, 10m)'
        default: '5m'
      vus:
        description: 'Virtual users'
        default: '50'

jobs:
  load-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup k6
        uses: grafana/setup-k6-action@v1

      - name: Run load tests
        run: |
          k6 run tests/performance/load-test.js \
            --out json=results.json \
            -e BASE_URL=${{ secrets.STAGING_URL }}

      - name: Analyze results
        run: node scripts/analyze-performance.js results.json

      - name: Upload results
        uses: actions/upload-artifact@v4
        with:
          name: performance-results
          path: results.json
```

## 사용 예시
**입력**: "API 엔드포인트 부하 테스트 작성해줘"

**출력**:
1. k6 테스트 스크립트
2. 성능 임계값 설정
3. 결과 분석 스크립트
4. CI/CD 파이프라인
