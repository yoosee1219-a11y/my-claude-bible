# Performance Testing (k6 + Artillery)

> k6와 Artillery로 API 성능을 측정하고, CI/CD에 통합하여 프로덕션 장애를 사전에 방지하는 완전 가이드 (2026년 최신)

## 목차

1. [성능 테스트가 왜 필요한가?](#성능-테스트가-왜-필요한가)
2. [k6 vs Artillery 비교](#k6-vs-artillery-비교)
3. [k6로 부하 테스트하기](#k6로-부하-테스트하기)
4. [Artillery로 부하 테스트하기](#artillery로-부하-테스트하기)
5. [GitHub Actions 자동화](#github-actions-자동화)
6. [실전 사례](#실전-사례)

---

## 성능 테스트가 왜 필요한가?

### 프로덕션 장애 사례

**Black Friday 재앙** 💥
```
E-커머스 스타트업:
- 평소 트래픽: 100 req/sec
- Black Friday: 3,000 req/sec (30배)
- 결과: 서버 다운 (2시간)
- 손실: $150,000 (예상 매출의 80%)
- 원인: 성능 테스트 미실시
```

**API 응답 지연** 🐌
```
SaaS 앱 (1만 사용자):
- API 평균 응답 시간: 200ms
- 1,000명 동시 접속 시: 15초
- 결과: 사용자 이탈률 78%
- 월 매출 손실: $80,000
```

**데이터베이스 병목** 🔥
```
소셜 미디어 앱:
- DB 쿼리: N+1 문제
- 100명 동시 접속: 정상 동작
- 500명 동시 접속: DB CPU 100%, 응답 없음
- 손실: 신규 사용자 50% 이탈
```

### 성능 테스트의 이점

**사전 문제 발견** 🚀
- 프로덕션 배포 전 병목 지점 파악
- 서버/DB/API 한계치 측정
- 예상 트래픽 대비 대응 가능

**비용 절감** 💰
- 장애 대응 비용: $5,000/시간 (평균)
- 성능 테스트 비용: $500 (1회 설정)
- ROI: 900% (장애 1회만 막아도 본전)

**SLA 준수** ✅
- API 응답 시간 < 200ms 보장
- 99.9% 가용성 유지
- 고객 신뢰도 향상

---

## k6 vs Artillery 비교

| 항목 | k6 | Artillery |
|------|-----|-----------|
| 언어 | JavaScript (ES6) | YAML + JavaScript |
| 성능 | 매우 빠름 (Go 기반) | 중간 (Node.js 기반) |
| CPU 사용률 | 매우 낮음 | 높음 |
| VU 생성 능력 | 수만 명 (소형 하드웨어) | 수천 명 |
| 학습 곡선 | 중간 | 쉬움 |
| 클라우드 지원 | Grafana Cloud k6 | Artillery Cloud |
| CI/CD 통합 | 우수 | 우수 |
| Grafana 연동 | 공식 지원 | 플러그인 필요 |
| 가격 | 오픈소스 무료 | 오픈소스 무료 |

### 선택 가이드

**k6를 선택하세요:**
- ✅ 대규모 부하 테스트 (1만+ VU)
- ✅ Grafana 생태계 사용 중
- ✅ JavaScript 익숙
- ✅ 최소 하드웨어로 최대 성능

**Artillery를 선택하세요:**
- ✅ 빠른 프로토타이핑
- ✅ YAML 선호 (간단한 설정)
- ✅ WebSocket, Socket.IO 테스트
- ✅ 초보자 친화적

---

## k6로 부하 테스트하기

### 설치 (30초)

```bash
# macOS
brew install k6

# Windows
choco install k6

# Linux
wget https://github.com/grafana/k6/releases/download/v0.48.0/k6-v0.48.0-linux-amd64.tar.gz
tar -xzf k6-v0.48.0-linux-amd64.tar.gz
sudo mv k6 /usr/local/bin/

# 확인
k6 version
```

### 기본 테스트 (API 부하 테스트)

```javascript
// load-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 10 },   // 30초 동안 10명까지 증가
    { duration: '1m', target: 100 },   // 1분 동안 100명까지 증가
    { duration: '30s', target: 0 },    // 30초 동안 0명으로 감소
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],  // 95%가 500ms 이내
    http_req_failed: ['rate<0.01'],    // 실패율 1% 이하
  },
};

export default function () {
  // GET 요청
  const res = http.get('https://api.example.com/users');

  // 응답 검증
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
    'has users': (r) => JSON.parse(r.body).users.length > 0,
  });

  sleep(1);  // 1초 대기
}
```

**실행:**
```bash
k6 run load-test.js
```

**결과:**
```
          /\      |‾‾| /‾‾/   /‾‾/
     /\  /  \     |  |/  /   /  /
    /  \/    \    |     (   /   ‾‾\
   /          \   |  |\  \ |  (‾)  |
  / __________ \  |__| \__\ \_____/ .io

  execution: local
     script: load-test.js
     output: -

  scenarios: (100.00%) 1 scenario, 100 max VUs, 2m30s max duration (incl. graceful stop):
           * default: Up to 100 looping VUs for 2m0s over 3 stages (gracefulRampDown: 30s, gracefulStop: 30s)

     ✓ status is 200
     ✓ response time < 500ms
     ✓ has users

     checks.........................: 100.00% ✓ 8456       ✗ 0
     data_received..................: 12 MB   98 kB/s
     data_sent......................: 1.1 MB  7.2 kB/s
     http_req_duration..............: avg=120ms  min=50ms  med=100ms  max=450ms  p(90)=200ms  p(95)=250ms
     http_req_failed................: 0.00%   ✓ 0          ✗ 8456
     http_reqs......................: 8456    56.37/s
     iteration_duration.............: avg=1.12s  min=1.05s  med=1.10s  max=1.45s  p(90)=1.20s  p(95)=1.25s
     iterations.....................: 8456    56.37/s
     vus............................: 1       min=1        max=100
     vus_max........................: 100     min=100      max=100
```

### 실전 시나리오 (로그인 + API 호출)

```javascript
// scenario-test.js
import http from 'k6/http';
import { check, group, sleep } from 'k6';

export const options = {
  scenarios: {
    // 시나리오 1: 일반 사용자 (70%)
    normal_users: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '1m', target: 70 },
        { duration: '3m', target: 70 },
        { duration: '1m', target: 0 },
      ],
      exec: 'normalUser',
    },
    // 시나리오 2: 파워 사용자 (30%)
    power_users: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '1m', target: 30 },
        { duration: '3m', target: 30 },
        { duration: '1m', target: 0 },
      ],
      exec: 'powerUser',
    },
  },
  thresholds: {
    'http_req_duration{scenario:normal_users}': ['p(95)<500'],
    'http_req_duration{scenario:power_users}': ['p(95)<300'],
  },
};

export function normalUser() {
  group('일반 사용자 플로우', () => {
    // 1. 로그인
    let loginRes = http.post('https://api.example.com/auth/login', {
      email: 'user@example.com',
      password: 'password',
    });

    check(loginRes, {
      'login success': (r) => r.status === 200,
    });

    const token = JSON.parse(loginRes.body).token;

    // 2. 프로필 조회
    let profileRes = http.get('https://api.example.com/profile', {
      headers: { Authorization: `Bearer ${token}` },
    });

    check(profileRes, {
      'profile loaded': (r) => r.status === 200,
    });

    sleep(Math.random() * 3 + 2);  // 2-5초 랜덤 대기
  });
}

export function powerUser() {
  group('파워 사용자 플로우', () => {
    // 로그인 + 여러 API 호출
    let loginRes = http.post('https://api.example.com/auth/login', {
      email: 'power@example.com',
      password: 'password',
    });

    const token = JSON.parse(loginRes.body).token;

    // 대시보드 데이터 조회
    http.batch([
      ['GET', 'https://api.example.com/dashboard', null, { headers: { Authorization: `Bearer ${token}` } }],
      ['GET', 'https://api.example.com/analytics', null, { headers: { Authorization: `Bearer ${token}` } }],
      ['GET', 'https://api.example.com/notifications', null, { headers: { Authorization: `Bearer ${token}` } }],
    ]);

    sleep(Math.random() + 0.5);  // 0.5-1.5초 대기
  });
}
```

### Grafana Cloud k6 연동

```javascript
// cloud-test.js
export const options = {
  ext: {
    loadimpact: {
      projectID: 123456,
      name: 'Production Load Test',
    },
  },
};

// 나머지 코드 동일
```

**클라우드 실행:**
```bash
# k6 클라우드 로그인
k6 login cloud --token YOUR_API_TOKEN

# 클라우드에서 실행
k6 cloud load-test.js
```

**결과:** Grafana Cloud 대시보드에서 실시간 그래프 확인

---

## Artillery로 부하 테스트하기

### 설치

```bash
npm install -g artillery
```

### YAML 기반 테스트

```yaml
# load-test.yml
config:
  target: "https://api.example.com"
  phases:
    - duration: 60
      arrivalRate: 10        # 초당 10명 추가
      name: "Warm up"
    - duration: 120
      arrivalRate: 50        # 초당 50명 추가
      name: "Peak load"
    - duration: 60
      arrivalRate: 10
      name: "Ramp down"
  plugins:
    expect: {}
  processor: "./processor.js"

scenarios:
  - name: "User Journey"
    flow:
      - post:
          url: "/auth/login"
          json:
            email: "user@example.com"
            password: "password"
          capture:
            - json: "$.token"
              as: "token"
      - get:
          url: "/profile"
          headers:
            Authorization: "Bearer {{ token }}"
          expect:
            - statusCode: 200
            - contentType: json
      - think: 2  # 2초 대기
```

**실행:**
```bash
artillery run load-test.yml
```

### JavaScript 함수 사용 (복잡한 로직)

```javascript
// processor.js
module.exports = {
  generateRandomUser: generateRandomUser,
};

function generateRandomUser(context, events, done) {
  const id = Math.floor(Math.random() * 10000);
  context.vars.userId = `user_${id}`;
  context.vars.email = `user${id}@example.com`;
  return done();
}
```

```yaml
# advanced-test.yml
config:
  target: "https://api.example.com"
  processor: "./processor.js"

scenarios:
  - name: "Dynamic User Test"
    flow:
      - function: "generateRandomUser"
      - post:
          url: "/auth/register"
          json:
            email: "{{ email }}"
            password: "password123"
```

---

## GitHub Actions 자동화

### k6 GitHub Actions

```yaml
# .github/workflows/load-test.yml
name: Load Test with k6

on:
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 2 * * *'  # 매일 오전 2시

jobs:
  load-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Run k6 test
        uses: grafana/k6-action@v0.3.0
        with:
          filename: tests/load-test.js
          cloud: true
          token: ${{ secrets.K6_CLOUD_TOKEN }}

      - name: Check thresholds
        if: failure()
        run: |
          echo "⚠️ 성능 테스트 실패! Threshold를 초과했습니다."
          exit 1
```

### k6 + Grafana Cloud 자동 리포팅

```yaml
# .github/workflows/performance-test.yml
name: Performance Test

on:
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup k6
        uses: grafana/setup-k6-action@v1

      - name: Run k6 test
        env:
          K6_CLOUD_TOKEN: ${{ secrets.K6_CLOUD_TOKEN }}
          K6_CLOUD_PROJECT_ID: ${{ secrets.K6_CLOUD_PROJECT_ID }}
        run: k6 cloud --exit-on-running tests/load-test.js

      - name: Comment PR
        uses: actions/github-script@v6
        if: github.event_name == 'pull_request'
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.name,
              body: '✅ 성능 테스트 완료! 결과: https://app.k6.io/runs/${{ env.RUN_ID }}'
            })
```

### Artillery GitHub Actions

```yaml
# .github/workflows/artillery-test.yml
name: Artillery Load Test

on:
  pull_request:
    branches: [main]

jobs:
  load-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install Artillery
        run: npm install -g artillery

      - name: Run Artillery test
        run: artillery run tests/load-test.yml --output report.json

      - name: Generate HTML report
        run: artillery report report.json --output report.html

      - name: Upload report
        uses: actions/upload-artifact@v3
        with:
          name: artillery-report
          path: report.html
```

---

## 실전 사례

### 사례 1: SaaS 스타트업 (API 병목 발견)

**Before (성능 테스트 없음)**
```
상황:
- 평소 사용자: 500명
- Black Friday: 5,000명 (10배)
- 결과: API 응답 시간 200ms → 15초
- 서버 다운: 3시간
- 손실: $200,000

원인:
- N+1 쿼리 문제
- DB 인덱스 누락
- Connection Pool 부족 (10개)
```

**After (k6 부하 테스트 도입)**
```javascript
// 성능 테스트로 사전 발견
k6 run --vus 1000 --duration 5m load-test.js

// 결과:
http_req_duration...: avg=12s  p(95)=25s  ❌

병목 지점 파악:
1. /api/users 엔드포인트: N+1 쿼리
2. DB Connection Pool: 10개 (부족)
3. 인덱스 누락: users.email, orders.user_id

수정 후:
http_req_duration...: avg=120ms  p(95)=250ms  ✅

Black Friday 대응:
- 5,000명 동시 접속: 정상 동작
- API 응답 시간: 200ms 유지
- 장애 없음
- 예상 손실 방지: $200,000
```

**ROI:**
```
성능 테스트 비용: $1,000 (초기 설정)
방지한 손실: $200,000
ROI: 19,900%
```

### 사례 2: E-커머스 플랫폼

**성능 개선 전후 비교**
```bash
# Before
k6 run baseline-test.js

http_req_duration:
- avg: 800ms
- p(95): 2.5s
- p(99): 5s
❌ 실패: Threshold 500ms 초과

병목 지점:
1. 상품 이미지: 원본 크기 (5MB)
2. DB 쿼리: 카테고리별 JOIN 5번
3. 캐싱 없음

# After (최적화 후)
http_req_duration:
- avg: 150ms  ✅
- p(95): 300ms  ✅
- p(99): 500ms  ✅

개선 사항:
1. 이미지 CDN + WebP: 5MB → 50KB (99% 절감)
2. DB 쿼리 최적화: JOIN 5번 → 1번
3. Redis 캐싱: Hit Rate 85%

매출 영향:
- 페이지 로딩 속도: 3s → 0.5s
- 전환율: 2.1% → 3.8% (81% 증가)
- 월 매출 증가: $120,000
```

---

## 체크리스트

### 성능 테스트 시작 전
- [ ] 테스트 목표 설정 (응답 시간, 처리량, 동시 사용자 수)
- [ ] 현재 프로덕션 트래픽 분석
- [ ] 예상 피크 시간대 트래픽 계산
- [ ] 테스트 환경 구축 (프로덕션과 동일하게)

### k6/Artillery 설정
- [ ] 테스트 도구 선택 (k6 or Artillery)
- [ ] Threshold 설정 (p95 < 500ms 등)
- [ ] 시나리오 작성 (사용자 플로우)
- [ ] Ramp-up/Ramp-down 단계 정의

### CI/CD 통합
- [ ] GitHub Actions 워크플로우 작성
- [ ] PR 생성 시 자동 테스트 실행
- [ ] Threshold 초과 시 PR 블록
- [ ] Grafana Cloud / Artillery Cloud 연동

### 모니터링
- [ ] 실시간 모니터링 설정 (Grafana)
- [ ] Alert 설정 (응답 시간 초과 시)
- [ ] 리포트 자동 생성 및 공유

---

## 참고 자료

### k6
- [Grafana k6 Official Docs](https://k6.io/docs/)
- [Performance Testing with k6 and GitHub Actions (Grafana Labs)](https://grafana.com/blog/2024/07/15/performance-testing-with-grafana-k6-and-github-actions/)
- [k6 부하 테스트 툴 (한국어)](https://jiyeonseo.github.io/2022/09/11/k6-get-started/)
- [SK DevOcean - k6 퀵 스타트](https://devocean.sk.com/blog/techBoardDetail.do?ID=164237)
- [GitHub - grafana/k6](https://github.com/grafana/k6)

### Artillery
- [Artillery Official Docs](https://www.artillery.io/docs)
- [Artillery vs k6 Comparison](https://npm-compare.com/artillery,k6)

### CI/CD Integration
- [GitHub - grafana/run-k6-action](https://github.com/grafana/run-k6-action)
- [k6 GitHub Actions Integration Guide (NashTech)](https://blog.nashtechglobal.com/a-quick-overview-of-ci-cd-integration-of-k6-with-github-actions/)
- [Shift-Left Performance Testing (Medium)](https://medium.com/@sumit.somanchd/shift-left-performance-testing-integrating-k6-in-ci-cd-pipelines-e56355abe861)

---

## 마무리

이 가이드를 따라 구현하면:

1. ✅ **장애 방지**: 프로덕션 장애 **90%+ 사전 차단**
2. ✅ **비용 절감**: 장애 대응 비용 **$수십만 절약**
3. ✅ **성능 개선**: API 응답 시간 **50-80% 단축**
4. ✅ **전환율 향상**: 페이지 속도 개선으로 **20-80% 증가**
5. ✅ **CI/CD 통합**: PR마다 자동 성능 검증

성능 테스트, 지금 시작하세요! ⚡
