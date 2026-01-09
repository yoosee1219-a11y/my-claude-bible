---
name: production-monitoring
description: 프로덕션모니터링, Sentry, 에러트래킹, 성능모니터링, Next.js모니터링, Sourcemaps, 분산추적, SessionReplay, 알림자동화, 실시간디버깅, 프로덕션에러, APM, 로그수집, 장애감지, Slack알림, 커스텀태그, 이벤트컨텍스트, 에러분석, 성능최적화로 Sentry를 활용한 프로덕션 모니터링 완벽 가이드 스킬
---

# Production Monitoring with Sentry + Next.js

## Overview

**프로덕션 환경에서 발생하는 모든 에러와 성능 문제를 실시간으로 추적하고 해결!**

이 스킬은 유튜브 재생목록 "Debugging Next.js Applications with Sentry" (7개 영상)의 모든 내용을 텍스트 가이드로 재구성한 종합 모니터링 가이드입니다.

### 왜 필요한가?

프로덕션 환경에서:
- 🔥 **사용자가 에러를 겪는데 개발자는 모름**
- 🐌 **페이지가 느린데 어디가 문제인지 모름**
- 💸 **장애로 인한 매출 손실**
- 😰 **"제 컴퓨터에서는 잘 돼요" 증후군**

Sentry로 해결:
- ✅ **실시간 에러 알림** (Slack, 이메일)
- ✅ **에러 발생 전후 컨텍스트** (사용자 행동, 브라우저 정보)
- ✅ **성능 병목 자동 탐지**
- ✅ **세션 리플레이** (사용자가 뭘 했는지 비디오처럼 재생)
- ✅ **분산 추적** (API → DB → 외부 서비스 전체 흐름 추적)

**비용 대비 효과**:
- Sentry 무료 티어: 월 5,000 에러 이벤트
- 유료: $26/월 (50,000 이벤트)
- **장애 1시간 방지 효과**: 수천만원 매출 손실 방지

---

## 📚 학습 로드맵 (7단계)

이 스킬은 다음 7가지 주제를 다룹니다 (유튜브 재생목록 구조):

```
1. What is Monitoring? → 모니터링 개념 이해
2. Setup Sentry → 5분 설치 + 수동 설정
3. Sourcemaps → 배포 시 소스맵 자동 업로드
4. Event Context & Tags → 에러에 커스텀 정보 추가
5. Alerts → Slack/이메일 알림 자동화
6. Distributed Tracing → API-DB 전체 성능 추적
7. Session Replay → 사용자 행동 비디오 재생
```

---

## 1️⃣ What is Monitoring? (모니터링이란?)

### 모니터링의 3가지 핵심 영역

#### A. Error Tracking (에러 추적)
```
사용자 브라우저에서 발생한 에러를 실시간으로 수집
→ 에러 메시지, 스택 트레이스, 브라우저 정보
→ 우선순위별 분류 (심각도, 발생 빈도)
→ 자동 알림 (Slack, 이메일)
```

**예시**:
```javascript
// ❌ 기존: console.error로만 로그
try {
  await fetchUserData(userId);
} catch (error) {
  console.error(error); // 개발자만 볼 수 있음
}

// ✅ Sentry: 자동으로 모든 에러 수집
try {
  await fetchUserData(userId);
} catch (error) {
  Sentry.captureException(error); // 실시간 알림 + 컨텍스트 추가
}
```

#### B. Performance Monitoring (APM)
```
페이지 로딩 속도, API 응답 시간, 느린 쿼리 자동 탐지
→ LCP, FID, CLS (Core Web Vitals)
→ API 엔드포인트별 성능 분석
→ 병목 지점 시각화
```

**측정 항목**:
- **LCP** (Largest Contentful Paint): 메인 콘텐츠 로딩 시간
- **FID** (First Input Delay): 사용자 입력 반응 시간
- **CLS** (Cumulative Layout Shift): 레이아웃 변화
- **TTFB** (Time to First Byte): 서버 응답 시간

#### C. Session Replay (세션 재생)
```
사용자가 에러를 겪은 순간을 비디오처럼 재생
→ 클릭, 스크롤, 입력 이벤트
→ 네트워크 요청/응답
→ 콘솔 로그
→ DOM 변경 사항
```

**가치**:
- "재현이 안 돼요" 문제 해결
- QA 시간 80% 단축
- 사용자 경험 직접 확인

---

## 2️⃣ Setup Sentry in Next.js (설치 및 설정)

### A. 자동 설정 (5분) - 추천

#### Step 1: Sentry 계정 생성
```bash
# 1. https://sentry.io 가입 (무료)
# 2. 새 프로젝트 생성 → Next.js 선택
# 3. DSN 키 복사 (예: https://abc123@o123.ingest.sentry.io/456)
```

#### Step 2: 자동 설치 마법사
```bash
npx @sentry/wizard@latest -i nextjs
```

**자동으로 생성되는 파일**:
```
my-nextjs-app/
├── sentry.client.config.ts    # 브라우저 설정
├── sentry.server.config.ts    # Node.js 서버 설정
├── sentry.edge.config.ts      # Edge Runtime 설정
├── instrumentation.ts         # Next.js 15+ 필수
└── next.config.js             # Sentry 플러그인 추가
```

#### Step 3: 환경 변수 설정
```bash
# .env.local
NEXT_PUBLIC_SENTRY_DSN=https://your-key@sentry.io/your-project
SENTRY_AUTH_TOKEN=your-auth-token-here
SENTRY_ORG=your-org-slug
SENTRY_PROJECT=your-project-slug
```

**Auth Token 생성**:
```
Sentry 대시보드 → Settings → Developer Settings
→ Auth Tokens → Create New Token
→ Scopes: project:releases, org:read
```

#### Step 4: 테스트
```bash
npm run build
npm start
```

브라우저에서 `/sentry-example-page` 접속 → 테스트 에러 발생 → Sentry 대시보드 확인

---

### B. 수동 설정 (완전 제어)

#### 1. 패키지 설치
```bash
npm install @sentry/nextjs
```

#### 2. sentry.client.config.ts (브라우저)
```typescript
import * as Sentry from "@sentry/nextjs";

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,

  // 환경 구분
  environment: process.env.NODE_ENV,

  // 성능 모니터링 샘플링
  tracesSampleRate: process.env.NODE_ENV === "production" ? 0.1 : 1.0,

  // 세션 리플레이 샘플링
  replaysSessionSampleRate: 0.1, // 10% 세션 녹화
  replaysOnErrorSampleRate: 1.0, // 에러 발생 시 100% 녹화

  // 세션 리플레이 통합
  integrations: [
    Sentry.replayIntegration({
      maskAllText: true,    // 모든 텍스트 마스킹 (개인정보 보호)
      blockAllMedia: true,  // 이미지/비디오 차단
    }),
  ],

  // 프로덕션에서만 활성화
  enabled: process.env.NODE_ENV === "production",

  // 릴리즈 추적
  release: process.env.NEXT_PUBLIC_VERCEL_GIT_COMMIT_SHA,
});
```

#### 3. sentry.server.config.ts (Node.js 서버)
```typescript
import * as Sentry from "@sentry/nextjs";

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: 0.1,

  // API 라우트 자동 추적
  integrations: [
    Sentry.httpIntegration({
      tracing: true,
    }),
  ],

  // 민감한 데이터 필터링
  beforeSend(event) {
    // 비밀번호 필드 제거
    if (event.request?.data?.password) {
      delete event.request.data.password;
    }
    return event;
  },
});
```

#### 4. sentry.edge.config.ts (Edge Runtime)
```typescript
import * as Sentry from "@sentry/nextjs";

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  tracesSampleRate: 0.1,
});
```

#### 5. next.config.js (Sentry 플러그인)
```javascript
const { withSentryConfig } = require("@sentry/nextjs");

/** @type {import('next').NextConfig} */
const nextConfig = {
  // 프로덕션에서 소스맵 생성
  productionBrowserSourceMaps: true,
};

module.exports = withSentryConfig(nextConfig, {
  // Sentry 빌드 옵션
  org: process.env.SENTRY_ORG,
  project: process.env.SENTRY_PROJECT,
  authToken: process.env.SENTRY_AUTH_TOKEN,

  // 소스맵 업로드 설정
  silent: true, // 빌드 로그 간소화
  hideSourceMaps: true, // 브라우저에서 소스맵 숨김 (보안)

  // 자동 계측 비활성화 (선택)
  autoInstrumentServerFunctions: true,
  autoInstrumentMiddleware: true,
});
```

---

## 3️⃣ Sourcemaps (소스맵 설정)

### 왜 필요한가?

**프로덕션 빌드 = 압축/난독화**:
```javascript
// 원본 코드
function calculateTotal(items) {
  return items.reduce((sum, item) => sum + item.price, 0);
}

// 빌드 후 (압축)
function a(b){return b.reduce((c,d)=>c+d.e,0)}
```

**에러 발생 시**:
```
❌ 소스맵 없음: "Error at a (bundle.js:1:234)"
✅ 소스맵 있음: "Error at calculateTotal (utils/cart.ts:12:5)"
```

---

### 자동 소스맵 업로드 설정

#### Next.js 15.4.1+ (Turbopack 지원)

**요구사항**:
- `@sentry/nextjs >= 10.13.0`
- `next >= 15.4.1`

**자동 설정** (위 next.config.js 사용):
```bash
npm run build
# → 빌드 완료 후 자동으로 소스맵 Sentry에 업로드
```

**업로드 확인**:
```
Sentry 대시보드 → Settings → Source Maps
→ 최신 릴리즈 클릭 → Artifacts 확인
```

---

### 소스맵 트러블슈팅

#### 문제 1: 소스맵이 업로드되지 않음
```bash
# 디버그 모드로 빌드
SENTRY_LOG_LEVEL=debug npm run build
```

**해결책**:
- Auth Token 권한 확인 (`project:releases`, `org:read`)
- Organization/Project 슬러그 오타 확인
- 네트워크 방화벽 확인

#### 문제 2: 소스맵이 있는데도 파일명이 보이지 않음
```javascript
// next.config.js
module.exports = withSentryConfig(nextConfig, {
  // 모든 파일 업로드 (node_modules 포함)
  include: [
    { paths: [".next"], urlPrefix: "~/_next" },
  ],
});
```

#### 문제 3: 빌드 시간이 너무 오래 걸림
```javascript
// next.config.js
module.exports = withSentryConfig(nextConfig, {
  silent: true, // 로그 출력 최소화
  dryRun: process.env.VERCEL_ENV !== "production", // 개발/프리뷰에선 업로드 스킵
});
```

---

## 4️⃣ Event Context & Custom Tags (이벤트 컨텍스트와 커스텀 태그)

### Tags vs Context

| 구분 | Tags | Context |
|------|------|---------|
| **용도** | 검색 & 필터링 | 상세 정보 표시 |
| **검색 가능** | ✅ Yes | ❌ No (보기만 가능) |
| **최대 길이** | Key: 32자, Value: 200자 | 제한 없음 |
| **예시** | `feature: "checkout"` | `cart: { items: 3, total: 29.99 }` |

---

### Tags 사용법

#### 1. 전역 태그 설정
```typescript
// app/layout.tsx
import * as Sentry from "@sentry/nextjs";

export default function RootLayout({ children }) {
  // 앱 전체에 적용
  Sentry.setTag("app_version", "2.1.0");
  Sentry.setTag("deployment", process.env.VERCEL_ENV);

  return <html>{children}</html>;
}
```

#### 2. 사용자별 태그
```typescript
// 로그인 후
Sentry.setUser({
  id: user.id,
  email: user.email,
  username: user.username,
});

Sentry.setTag("user_plan", user.plan); // "free", "pro", "enterprise"
Sentry.setTag("user_role", user.role); // "admin", "user"
```

#### 3. 기능별 태그 (에러 분류)
```typescript
// components/Checkout.tsx
import * as Sentry from "@sentry/nextjs";

export default function Checkout() {
  const handlePayment = async () => {
    Sentry.setTag("feature", "payment");
    Sentry.setTag("payment_method", "stripe");

    try {
      await processPayment();
    } catch (error) {
      Sentry.captureException(error);
      // Sentry에서 "feature:payment" 필터로 검색 가능
    }
  };
}
```

#### 4. 조건부 태그
```typescript
if (isTestUser) {
  Sentry.setTag("test_user", "true");
}

if (isMobileDevice) {
  Sentry.setTag("device_type", "mobile");
}
```

---

### Context 사용법

#### 1. 커스텀 컨텍스트
```typescript
Sentry.setContext("shopping_cart", {
  items: cart.items.length,
  total: cart.total,
  currency: "USD",
  discounts: cart.discounts,
});

Sentry.setContext("experiment", {
  variant: "checkout_v2",
  test_group: "A",
});
```

#### 2. API 요청 컨텍스트
```typescript
// app/api/orders/route.ts
import * as Sentry from "@sentry/nextjs";

export async function POST(request: Request) {
  const body = await request.json();

  Sentry.setContext("request_data", {
    order_id: body.orderId,
    items_count: body.items.length,
    shipping_method: body.shippingMethod,
  });

  try {
    const order = await createOrder(body);
    return Response.json(order);
  } catch (error) {
    Sentry.captureException(error);
    return Response.json({ error: "Order failed" }, { status: 500 });
  }
}
```

#### 3. 브레드크럼(Breadcrumb) - 사용자 행동 추적
```typescript
// 버튼 클릭 추적
Sentry.addBreadcrumb({
  category: "user-action",
  message: "User clicked checkout button",
  level: "info",
  data: {
    cart_total: 99.99,
    item_count: 3,
  },
});

// 네비게이션 추적
Sentry.addBreadcrumb({
  category: "navigation",
  message: "User navigated to /checkout",
  level: "info",
});

// API 호출 추적 (자동)
// Sentry가 자동으로 fetch/XHR 요청을 브레드크럼으로 기록
```

---

### 실전 예제: E-commerce 앱

```typescript
// hooks/useCheckout.ts
import * as Sentry from "@sentry/nextjs";

export function useCheckout() {
  const processCheckout = async (cart, paymentMethod) => {
    // 1. 태그 설정 (검색용)
    Sentry.setTag("feature", "checkout");
    Sentry.setTag("payment_method", paymentMethod.type);
    Sentry.setTag("cart_size", cart.items.length > 5 ? "large" : "small");

    // 2. 컨텍스트 설정 (상세 정보)
    Sentry.setContext("cart_details", {
      items: cart.items.map(i => ({ id: i.id, price: i.price })),
      subtotal: cart.subtotal,
      tax: cart.tax,
      total: cart.total,
      coupon: cart.coupon || null,
    });

    Sentry.setContext("payment_details", {
      method: paymentMethod.type,
      last4: paymentMethod.card?.last4,
      brand: paymentMethod.card?.brand,
    });

    // 3. 브레드크럼 추가
    Sentry.addBreadcrumb({
      category: "checkout",
      message: "Checkout process started",
      level: "info",
      data: { cart_total: cart.total },
    });

    try {
      // 4. 결제 처리
      const result = await fetch("/api/checkout", {
        method: "POST",
        body: JSON.stringify({ cart, paymentMethod }),
      });

      if (!result.ok) {
        throw new Error(`Payment failed: ${result.status}`);
      }

      Sentry.addBreadcrumb({
        category: "checkout",
        message: "Payment succeeded",
        level: "info",
      });

      return result.json();
    } catch (error) {
      // 5. 에러 캡처 (모든 태그/컨텍스트 포함)
      Sentry.captureException(error);
      throw error;
    }
  };

  return { processCheckout };
}
```

**Sentry 대시보드에서 보이는 정보**:
```
Error: Payment failed: 500

Tags:
  feature: checkout
  payment_method: stripe
  cart_size: large
  user_plan: pro

Context:
  cart_details:
    items: [{ id: "123", price: 29.99 }, ...]
    subtotal: 89.97
    tax: 7.20
    total: 97.17
    coupon: "SAVE10"

  payment_details:
    method: "stripe"
    last4: "4242"
    brand: "visa"

Breadcrumbs:
  [INFO] Checkout process started (cart_total: 97.17)
  [INFO] User navigated to /checkout
  [HTTP] POST /api/checkout → 500
  [ERROR] Payment failed: 500
```

---

## 5️⃣ Alerts (알림 설정)

### Slack 통합 (추천)

#### Step 1: Slack 앱 설치
```
Sentry 대시보드 → Settings → Integrations → Slack
→ "Install" 클릭 → Slack 워크스페이스 선택 → 권한 승인
```

#### Step 2: Alert Rule 생성
```
Alerts → Create Alert Rule

[조건 설정]
- When: An event is seen
- If: error.type equals "Error"
- And: level equals "error"
- And: environment equals "production"

[필터링 (선택)]
- Tag: feature equals "payment"  → 결제 에러만 알림

[액션]
- Send a notification via Slack
- Workspace: My Team
- Channel: #alerts-production
- Tags to show: feature, user_plan, payment_method
```

#### Step 3: Alert Rule 고급 설정

**중복 방지** (같은 에러 반복 알림 방지):
```
Frequency:
- Alert me on every new issue
- Alert me on every 10th occurrence of an existing issue
```

**임계값 알림**:
```
When: Event frequency is above threshold
Frequency: 100 events in 1 hour
→ "Payment API 에러가 시간당 100건 초과!"
```

**회귀 탐지**:
```
When: An issue changes state from resolved to unresolved
→ "수정된 버그가 다시 발생했습니다!"
```

---

### 이메일 알림

```
Alerts → Create Alert Rule

[조건]
- When: An event is seen
- If: level equals "fatal"  → 치명적 에러만

[액션]
- Send a notification via email
- To: engineering@company.com, oncall@company.com
```

---

### PagerDuty 통합 (24/7 온콜)

```
Settings → Integrations → PagerDuty → Install

[Alert Rule]
- When: Error count > 50 in 5 minutes
- Action: Trigger PagerDuty incident
- Severity: Critical
→ 온콜 엔지니어에게 자동 전화/SMS
```

---

### Webhook (커스텀 자동화)

```javascript
// Vercel Edge Function (무료)
// api/sentry-webhook.ts
export const config = { runtime: "edge" };

export default async function handler(req: Request) {
  const event = await req.json();

  // 심각한 에러만 처리
  if (event.level === "fatal") {
    // Slack으로 긴급 알림
    await fetch(process.env.SLACK_WEBHOOK_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        text: `🚨 CRITICAL ERROR: ${event.title}`,
        blocks: [
          {
            type: "section",
            text: {
              type: "mrkdwn",
              text: `*${event.title}*\n${event.culprit}\n<${event.url}|View in Sentry>`,
            },
          },
        ],
      }),
    });

    // 데이터베이스에 기록
    await logIncident({
      title: event.title,
      level: event.level,
      timestamp: new Date(),
      sentryUrl: event.url,
    });
  }

  return new Response("OK", { status: 200 });
}
```

**Sentry Webhook 설정**:
```
Settings → Developer Settings → Webhooks → Create New Webhook
URL: https://your-app.vercel.app/api/sentry-webhook
Events: issue.created, issue.resolved
```

---

## 6️⃣ Distributed Tracing (분산 추적)

### 개념

**단일 요청의 전체 여정 추적**:
```
사용자 클릭
  ↓
[브라우저] 버튼 클릭 → fetch /api/checkout
  ↓
[Next.js API] /api/checkout → Stripe API 호출
  ↓
[Stripe] 결제 처리 (500ms)
  ↓
[Next.js API] DB에 주문 저장
  ↓
[Supabase] INSERT query (200ms)
  ↓
[Next.js API] 응답 반환
  ↓
[브라우저] UI 업데이트

Total: 1.2초 (어디가 느린지 한눈에 파악!)
```

---

### 자동 설정 (Next.js)

**이미 설정 완료** (sentry.client.config.ts 참고):
```typescript
Sentry.init({
  tracesSampleRate: 0.1, // 10% 요청만 추적 (비용 절감)

  integrations: [
    Sentry.browserTracingIntegration({
      // 추적할 도메인 설정
      tracePropagationTargets: [
        "localhost",
        /^https:\/\/yourapp\.com/,
        /^https:\/\/api\.yourapp\.com/,
      ],
    }),
  ],
});
```

**자동 추적되는 것**:
- ✅ 페이지 로딩 (pageload)
- ✅ 네비게이션 (route change)
- ✅ fetch/XHR 요청
- ✅ API 라우트 (/app/api/*)
- ✅ Server Components/Actions

---

### 수동 트랜잭션 (세밀한 제어)

#### API 라우트 추적
```typescript
// app/api/checkout/route.ts
import * as Sentry from "@sentry/nextjs";

export async function POST(request: Request) {
  // 트랜잭션 시작
  return await Sentry.startSpan(
    {
      name: "POST /api/checkout",
      op: "http.server",
      attributes: {
        "http.method": "POST",
        "http.route": "/api/checkout",
      },
    },
    async () => {
      const body = await request.json();

      // 1. Stripe 결제 (자동 추적)
      const paymentIntent = await Sentry.startSpan(
        { name: "Stripe Payment", op: "payment" },
        () => stripe.paymentIntents.create({
          amount: body.amount,
          currency: "usd",
        })
      );

      // 2. DB 저장 (자동 추적)
      const order = await Sentry.startSpan(
        { name: "Save Order to DB", op: "db.query" },
        () => db.orders.create({
          userId: body.userId,
          total: body.amount,
          paymentIntentId: paymentIntent.id,
        })
      );

      // 3. 이메일 발송 (자동 추적)
      await Sentry.startSpan(
        { name: "Send Order Email", op: "email" },
        () => sendEmail({
          to: body.email,
          template: "order-confirmation",
          data: { order },
        })
      );

      return Response.json({ success: true, orderId: order.id });
    }
  );
}
```

**Sentry Performance 대시보드 결과**:
```
POST /api/checkout (Total: 1,234ms)
├─ Stripe Payment (567ms) ⚠️ 느림!
├─ Save Order to DB (123ms) ✅
└─ Send Order Email (456ms)
```

---

### 외부 서비스 추적

#### Fetch 자동 추적
```typescript
// 자동으로 추적됨 (tracePropagationTargets 설정 필요)
const response = await fetch("https://api.example.com/data");
```

#### 외부 API에 Trace 헤더 전달
```typescript
// sentry.client.config.ts
Sentry.init({
  integrations: [
    Sentry.browserTracingIntegration({
      tracePropagationTargets: [
        "localhost",
        "yourapp.com",
        "api.partner.com", // 파트너 API도 추적
      ],
    }),
  ],
});
```

**전달되는 헤더**:
```
sentry-trace: 1234567890abcdef-1234567890abcdef-1
baggage: sentry-environment=production,sentry-release=2.1.0
```

---

### 실전 디버깅 예제: Timeout 에러

**문제**: API 응답이 가끔 30초 이상 걸림

**분산 추적 결과**:
```
GET /api/products (30,456ms) ❌ TIMEOUT
├─ Fetch Products from DB (145ms) ✅
├─ Enrich with Inventory Data (28,901ms) ⚠️ 여기가 문제!
│   └─ External API call (28,800ms) 🔥
└─ Format Response (12ms) ✅
```

**해결책**:
```typescript
// Before: 동기 호출
const products = await getProducts();
for (const product of products) {
  product.inventory = await fetchInventory(product.id); // 100개 * 300ms = 30초!
}

// After: 병렬 호출
const products = await getProducts();
const inventoryPromises = products.map(p => fetchInventory(p.id));
const inventories = await Promise.all(inventoryPromises); // 300ms!
products.forEach((p, i) => p.inventory = inventories[i]);
```

---

## 7️⃣ Session Replay (세션 리플레이)

### 개념

**사용자가 겪은 에러를 비디오처럼 재생**:
```
[사용자 시나리오]
1. 장바구니에 상품 3개 추가
2. "결제하기" 버튼 클릭
3. 신용카드 정보 입력
4. "완료" 버튼 클릭
5. ❌ 에러 발생: "Payment failed"

[Sentry Session Replay]
→ 위 모든 과정을 비디오처럼 재생
→ 클릭, 스크롤, 입력, 네트워크 요청, 콘솔 로그 모두 기록
→ "아 이 사용자가 쿠폰 코드를 잘못 입력해서 에러가 났구나!"
```

---

### 설정 (이미 완료)

```typescript
// sentry.client.config.ts
Sentry.init({
  replaysSessionSampleRate: 0.1, // 10% 일반 세션 녹화
  replaysOnErrorSampleRate: 1.0, // 에러 발생 시 100% 녹화

  integrations: [
    Sentry.replayIntegration({
      // 개인정보 보호 설정
      maskAllText: true,        // 모든 텍스트 *** 처리
      blockAllMedia: true,      // 이미지/비디오 숨김
      maskAllInputs: true,      // input 값 숨김

      // 예외 (특정 요소는 표시)
      unmask: [".safe-to-show"],
      unblock: [".product-image"],
    }),
  ],
});
```

---

### 프라이버시 제어

#### 1. 선택적 마스킹
```html
<!-- 기본: 모든 텍스트 마스킹 -->
<h1>Welcome, John Doe</h1>
→ Replay: "*******, **** ***"

<!-- 예외: 특정 요소 표시 -->
<h1 class="sentry-unmask">Welcome to our store</h1>
→ Replay: "Welcome to our store" (그대로 표시)
```

#### 2. 민감한 요소 블록
```html
<!-- 신용카드 번호 완전 숨김 -->
<input type="text" class="sentry-block" />
→ Replay: [빈 박스로 표시]

<!-- 사용자 프로필 이미지 숨김 -->
<img src="/avatar.jpg" class="sentry-block" />
→ Replay: [회색 박스]
```

#### 3. 전체 페이지 녹화 비활성화
```typescript
// 특정 페이지에서 Replay 중지
if (window.location.pathname === "/admin") {
  Sentry.getClient()?.getIntegration(Sentry.Replay)?.stop();
}
```

---

### 실전 활용

#### 케이스 1: "재현이 안 돼요" 버그
```
[사용자 리포트]
"결제가 안 돼요!"

[개발자]
"제 컴퓨터에서는 잘 되는데요..."

[Session Replay 확인]
1. 사용자가 IE 11 사용 중 🤦
2. Polyfill 누락
3. 즉시 수정!
```

#### 케이스 2: UX 개선
```
[Replay 분석]
- 사용자들이 "로그인" 버튼을 못 찾고 있음
- 평균 10초간 화면을 헤맴
- 버튼 위치 변경 → 전환율 30% 증가!
```

#### 케이스 3: 성능 문제 파악
```
[Replay 확인]
- 페이지 로딩 후 5초간 흰 화면
- 네트워크 탭: 대용량 이미지 로딩 중
- 이미지 lazy loading 적용 → 해결!
```

---

### Replay 대시보드 활용

**Sentry → Replays 메뉴**:

**필터링**:
```
- Has Error: 에러 발생한 세션만
- User: 특정 사용자
- URL: 특정 페이지
- Duration: > 5분 (긴 세션)
- Rage Clicks: 같은 버튼 연속 클릭 (좌절한 사용자!)
```

**Rage Click 탐지**:
```
사용자가 같은 버튼을 5초 내에 5번 이상 클릭
→ "버튼이 작동 안 하는 것처럼 보인다!" (UX 문제)
→ Replay로 확인 → 로딩 인디케이터 추가
```

---

## 🎯 프로덕션 베스트 프랙티스

### 1. 샘플링 전략 (비용 최적화)

```typescript
// 환경별 샘플링
const getSampleRates = () => {
  if (process.env.NODE_ENV === "development") {
    return {
      tracesSampleRate: 1.0,      // 100% 추적
      replaysSessionSampleRate: 1.0,
    };
  }

  if (process.env.VERCEL_ENV === "preview") {
    return {
      tracesSampleRate: 0.5,      // 50%
      replaysSessionSampleRate: 0.2,
    };
  }

  // Production
  return {
    tracesSampleRate: 0.1,        // 10% (비용 절감)
    replaysSessionSampleRate: 0.05, // 5%
    replaysOnErrorSampleRate: 1.0,  // 에러 시 100%
  };
};

Sentry.init({
  ...getSampleRates(),
});
```

**비용 계산 예시**:
- 월 1M 요청
- tracesSampleRate: 0.1 → 100K 이벤트
- Sentry 무료 티어: 10K 이벤트/월
- 필요 플랜: Team ($26/월, 50K 이벤트)

---

### 2. 에러 필터링 (노이즈 제거)

```typescript
// sentry.client.config.ts
Sentry.init({
  beforeSend(event, hint) {
    // 1. 개발 환경 에러 무시
    if (event.environment === "development") {
      return null;
    }

    // 2. 특정 에러 무시
    const ignoredErrors = [
      "ResizeObserver loop limit exceeded", // 브라우저 버그
      "Non-Error promise rejection captured", // 무의미한 에러
      "ChunkLoadError", // 네트워크 문제 (사용자 측)
    ];

    if (ignoredErrors.some(msg => event.message?.includes(msg))) {
      return null;
    }

    // 3. 봇 트래픽 무시
    const userAgent = event.request?.headers?.["user-agent"];
    if (userAgent?.includes("bot") || userAgent?.includes("crawler")) {
      return null;
    }

    // 4. 민감한 데이터 제거
    if (event.request?.data?.password) {
      delete event.request.data.password;
    }
    if (event.request?.data?.creditCard) {
      delete event.request.data.creditCard;
    }

    return event;
  },
});
```

---

### 3. 릴리즈 추적

```javascript
// next.config.js
const SENTRY_RELEASE = process.env.NEXT_PUBLIC_VERCEL_GIT_COMMIT_SHA || "dev";

module.exports = withSentryConfig(nextConfig, {
  release: SENTRY_RELEASE,
});
```

```typescript
// sentry.client.config.ts
Sentry.init({
  release: process.env.NEXT_PUBLIC_VERCEL_GIT_COMMIT_SHA,

  // Git 정보 추가
  initialScope: {
    tags: {
      git_commit: process.env.NEXT_PUBLIC_VERCEL_GIT_COMMIT_SHA,
      git_branch: process.env.NEXT_PUBLIC_VERCEL_GIT_COMMIT_REF,
    },
  },
});
```

**효과**:
- 어떤 배포 버전에서 에러 발생했는지 추적
- 릴리즈별 에러율 비교
- "v2.1.0에서 갑자기 에러 급증!" → 롤백

---

### 4. 환경별 설정

```typescript
const SENTRY_CONFIG = {
  development: {
    enabled: false, // 개발 환경에선 비활성화
  },
  preview: {
    enabled: true,
    environment: "preview",
    tracesSampleRate: 0.5,
  },
  production: {
    enabled: true,
    environment: "production",
    tracesSampleRate: 0.1,
  },
};

const config = SENTRY_CONFIG[process.env.VERCEL_ENV || "development"];

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  ...config,
});
```

---

### 5. 성능 예산 설정

```typescript
// Lighthouse CI + Sentry 통합
// lighthouserc.json
{
  "ci": {
    "assert": {
      "assertions": {
        "first-contentful-paint": ["error", { "maxNumericValue": 2000 }],
        "largest-contentful-paint": ["error", { "maxNumericValue": 2500 }],
        "cumulative-layout-shift": ["error", { "maxNumericValue": 0.1 }]
      }
    },
    "upload": {
      "target": "sentry",
      "serverBaseUrl": "https://sentry.io",
      "token": "$SENTRY_AUTH_TOKEN"
    }
  }
}
```

---

## 📊 대시보드 활용

### 주간 리뷰 체크리스트

```
[ ] Issues → Errors
    - 새로 발생한 에러 10개 확인
    - 빈도 높은 에러 우선 처리
    - "Unresolved" 에러 수 감소 확인

[ ] Performance
    - LCP > 2.5s 페이지 찾기
    - 느린 API 엔드포인트 Top 10
    - Apdex Score 추이 (목표: > 0.9)

[ ] Replays
    - Rage Click 세션 확인 (UX 문제)
    - 에러 발생 직전 사용자 행동 분석

[ ] Releases
    - 최신 릴리즈 에러율 확인
    - 이전 버전 대비 성능 변화
```

---

## 🚀 다음 단계

### Phase 1: 기본 설정 (완료)
- ✅ Sentry 설치
- ✅ 에러 추적
- ✅ 소스맵 업로드

### Phase 2: 고급 설정 (이 스킬 완료 후)
- ✅ Custom Tags & Context
- ✅ Alerts (Slack)
- ✅ Distributed Tracing
- ✅ Session Replay

### Phase 3: 최적화 (다음 목표)
- [ ] 비용 최적화 (샘플링 조정)
- [ ] 에러 그룹핑 규칙 커스터마이징
- [ ] AI 기반 에러 분석 (Sentry AI)
- [ ] 다른 도구 통합 (Datadog, Grafana)

---

## 📚 참고 자료

### 공식 문서
- [Sentry Next.js Docs](https://docs.sentry.io/platforms/javascript/guides/nextjs/)
- [Manual Setup Guide](https://docs.sentry.io/platforms/javascript/guides/nextjs/manual-setup/)
- [Source Maps](https://docs.sentry.io/platforms/javascript/guides/nextjs/sourcemaps/)
- [Distributed Tracing](https://docs.sentry.io/platforms/javascript/guides/nextjs/tracing/distributed-tracing/)
- [Session Replay](https://docs.sentry.io/platforms/javascript/guides/nextjs/session-replay/)

### 커뮤니티 가이드
- [Error Monitoring: The Ultimate Guide (Jan 2026)](https://medium.com/@rukshan1122/error-monitoring-the-ultimate-guide-to-sentry-in-next-js-never-miss-a-production-error-again-e678a93760ae)
- [Comprehensive Monitoring Guide](https://medium.com/@kvn.ignatius.w/comprehensive-guide-to-monitoring-next-js-applications-with-sentry-9d7f28ea006f)
- [한글 가이드 (Velog)](https://velog.io/@hoooons/Sentry란-Next.js에-적용하기)

### 영상 자료 (원본 재생목록)
1. [What is Monitoring](https://www.youtube.com/watch?v=1WNnV10XtOA&list=PLOwEowqdeNMqf3dArAE-Mo4rVR7T2Vanr)
2. [Setup Sentry in Next.js](https://www.youtube.com/watch?v=503qISA-PnA&list=PLOwEowqdeNMqf3dArAE-Mo4rVR7T2Vanr&index=2)
3. [Sourcemaps](https://www.youtube.com/watch?v=-jluayy_jJo&list=PLOwEowqdeNMqf3dArAE-Mo4rVR7T2Vanr&index=3)
4. [Event context and custom tags](https://www.youtube.com/watch?v=ZacJZUMHd1s&list=PLOwEowqdeNMqf3dArAE-Mo4rVR7T2Vanr&index=4)
5. [Alerts](https://www.youtube.com/watch?v=wVyXB25Cnvk&list=PLOwEowqdeNMqf3dArAE-Mo4rVR7T2Vanr&index=5)
6. [Distributed Tracing](https://www.youtube.com/watch?v=L1cJgs5RZK0&list=PLOwEowqdeNMqf3dArAE-Mo4rVR7T2Vanr&index=6)
7. [Session Replay](https://www.youtube.com/watch?v=saYtwXkmW_8&list=PLOwEowqdeNMqf3dArAE-Mo4rVR7T2Vanr&index=7)

---

## 🎓 빠른 시작 명령어

```bash
# 이 스킬 사용
/production-monitoring "Next.js 프로젝트에 Sentry 설정해줘"

# 특정 기능만
/production-monitoring "Session Replay 설정만 해줘"
/production-monitoring "Slack 알림 설정"
/production-monitoring "분산 추적 최적화"

# 트러블슈팅
/production-monitoring "소스맵이 업로드 안 돼"
/production-monitoring "Sentry 비용 줄이는 방법"
```

---

**이 스킬은 7개 영상 재생목록의 모든 내용을 포함하며, 추가로 2026년 최신 베스트 프랙티스와 실전 예제를 통합했습니다!** 🚀
