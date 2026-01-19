---
name: playwright-parallel-test-generator
description: Playwright, E2E테스트자동생성, 100개테스트병렬생성, 테스트시나리오자동추출, 웹테스트자동화, UI테스트, 통합테스트, 테스트코드생성, QA자동화, 테스트커버리지, 시나리오기반테스트, 페이지오브젝트패턴으로 Playwright E2E 테스트를 100개 이상 병렬로 자동 생성하는 스킬
---

# playwright-parallel-test-generator

## Overview

**Playwright E2E 테스트를 100개 이상 자동으로 병렬 생성!**

웹 애플리케이션 테스트를 위해 E2E 테스트를 작성하는 것은 시간이 많이 걸립니다. 하나하나 수작업으로 작성하면 100개 테스트에 100시간이 걸립니다. 이 스킬은 **Planner / Generator / Healer** 패턴을 사용하여 Playwright E2E 테스트를 **자동으로 대량 생성**합니다.

### 작동 방식:

```
웹사이트 URL 입력
  ↓
Planner: 사이트 분석 → 100개 테스트 시나리오 도출
  ↓
Generator (100개 병렬): 각자 테스트 코드 작성
  ↓
Executor: 전체 테스트 실행
  ↓
Healer: 실패한 테스트 자동 수정
  ↓
100개 E2E 테스트 완성! ✅
```

**시간 절약:**
- 수동: 100개 × 1시간 = **100시간**
- 자동: Planner 10분 + Generator 30분 + Healer 20분 = **1시간**

**100배 빠름!**

## When to Use This Skill

### ✅ 이 스킬을 사용하세요:

- **새 프로젝트**: E2E 테스트 처음 시작
- **레거시 코드**: 테스트가 하나도 없는 기존 프로젝트
- **CI/CD 구축**: 자동화 파이프라인에 테스트 필요
- **QA 부족**: 수동 테스트 자동화로 전환
- **리팩토링 전**: 안전망 구축
- **커버리지 향상**: 기존 테스트에 추가

### ⚠️ 이 스킬 대신 수동:

- **매우 간단한 사이트**: 페이지 3개 이하
- **학습 목적**: Playwright 배우는 중
- **특수한 테스트**: 복잡한 로직, 커스텀 검증

### 🔀 병행 사용:

- 80% 자동 생성 → 20% 수동 세부 조정
- 기본 시나리오 자동 → 엣지 케이스 수동

## Prerequisites

- Claude Code 설치
- Node.js 설치
- Playwright 기본 이해 (권장)
- 테스트할 웹사이트 URL
- YOLO 모드 이해 (claude-code-yolo-mode.md)

## Instructions

### Step 1: Planner - 테스트 시나리오 자동 추출

웹사이트를 분석하여 테스트 시나리오를 자동으로 도출합니다.

```javascript
const plannerAgent = await Task({
  subagent_type: "Explore",
  description: "Analyze website and extract test scenarios",
  prompt: `
    You are a QA Test Planner.

    Website: https://example-ecommerce.com

    Tasks:
    1. Crawl the entire website
    2. Identify all pages and user flows:
       - Homepage
       - Login/Register
       - Product listing
       - Product detail
       - Shopping cart
       - Checkout
       - User profile
       - etc.

    3. Extract test scenarios (aim for 100+):
       - User authentication flows
       - Product browsing flows
       - Shopping cart operations
       - Checkout process
       - Error handling cases
       - Edge cases

    4. For each scenario, define:
       - Test name
       - Steps to perform
       - Expected outcomes
       - Test data needed
       - Dependencies (if any)

    5. Remove inter-dependencies:
       - Each test should be independent
       - Can run in parallel without conflicts
       - Self-contained test data

    Output format:
    {
      "total_scenarios": 100,
      "scenarios": [
        {
          "id": 1,
          "name": "user-login-success",
          "category": "authentication",
          "steps": [
            "Navigate to /login",
            "Fill email: test@example.com",
            "Fill password: password123",
            "Click login button",
            "Wait for redirect to /dashboard"
          ],
          "assertions": [
            "URL should be /dashboard",
            "Welcome message visible",
            "User menu contains logout"
          ],
          "test_data": {
            "email": "test@example.com",
            "password": "password123"
          },
          "dependencies": []
        },
        ...
      ]
    }
  `
});

const testPlan = JSON.parse(plannerAgent.result);
console.log(`Planner extracted ${testPlan.total_scenarios} scenarios`);
```

### Step 2: Generator - 100개 테스트 병렬 생성

각 시나리오를 독립적인 Playwright 테스트 파일로 변환합니다.

```javascript
// YOLO 모드 필수!
const generators = testPlan.scenarios.map((scenario, index) =>
  Task({
    subagent_type: "general-purpose",
    description: `Generate test: ${scenario.name}`,
    prompt: `
      You are a Playwright Test Generator.

      Generate a Playwright test file for this scenario:
      ${JSON.stringify(scenario, null, 2)}

      Requirements:
      1. File name: tests/e2e/${scenario.category}/${scenario.name}.spec.ts
      2. Use TypeScript
      3. Use Page Object pattern
      4. Include proper assertions
      5. Add test data fixtures
      6. Handle waits properly (no hard timeouts)
      7. Add error screenshots on failure

      Template:
      \`\`\`typescript
      import { test, expect } from '@playwright/test';
      import { LoginPage } from '../pages/LoginPage';

      test.describe('${scenario.name}', () => {
        test('${scenario.name} - happy path', async ({ page }) => {
          const loginPage = new LoginPage(page);

          // Step 1: Navigate
          await loginPage.goto();

          // Step 2: Fill form
          await loginPage.fillEmail('${scenario.test_data.email}');
          await loginPage.fillPassword('${scenario.test_data.password}');

          // Step 3: Submit
          await loginPage.clickLogin();

          // Assertions
          await expect(page).toHaveURL(/dashboard/);
          await expect(page.locator('.welcome')).toBeVisible();
        });
      });
      \`\`\`

      Output the complete test file content.
    `,
    auto_approve: true,  // YOLO 모드
    run_in_background: true
  })
);

console.log(`Starting ${generators.length} Generator agents in parallel...`);

// 모든 Generator 완료 대기
const testFiles = await Promise.all(
  generators.map(g => TaskOutput({ task_id: g.id }))
);

console.log(`✅ ${testFiles.length} test files generated!`);
```

### Step 3: Page Object 생성

테스트에 필요한 Page Object도 자동 생성합니다.

```javascript
const pageObjectGenerator = await Task({
  subagent_type: "general-purpose",
  description: "Generate Page Objects",
  prompt: `
    Based on the test scenarios, create Page Object classes.

    Pages needed:
    ${testPlan.scenarios.map(s => s.category).filter((v, i, a) => a.indexOf(v) === i)}

    For each page, create:
    - Class with locators
    - Action methods
    - Type safety (TypeScript)

    Example:
    \`\`\`typescript
    import { Page, Locator } from '@playwright/test';

    export class LoginPage {
      readonly page: Page;
      readonly emailInput: Locator;
      readonly passwordInput: Locator;
      readonly loginButton: Locator;

      constructor(page: Page) {
        this.page = page;
        this.emailInput = page.locator('#email');
        this.passwordInput = page.locator('#password');
        this.loginButton = page.locator('button[type="submit"]');
      }

      async goto() {
        await this.page.goto('/login');
      }

      async fillEmail(email: string) {
        await this.emailInput.fill(email);
      }

      async fillPassword(password: string) {
        await this.passwordInput.fill(password);
      }

      async clickLogin() {
        await this.loginButton.click();
      }
    }
    \`\`\`

    Generate all Page Objects.
  `,
  auto_approve: true
});
```

### Step 4: Playwright 설정 파일 생성

```javascript
const configGenerator = await Task({
  subagent_type: "general-purpose",
  description: "Generate Playwright config",
  prompt: `
    Create playwright.config.ts with optimal settings:

    - 병렬 실행: workers = CPU 코어 수
    - 재시도: retries = 2
    - 타임아웃: 30초
    - 브라우저: Chromium, Firefox, WebKit
    - 스크린샷: on-failure
    - 비디오: retain-on-failure
    - 리포터: html, junit

    \`\`\`typescript
    import { defineConfig, devices } from '@playwright/test';

    export default defineConfig({
      testDir: './tests/e2e',
      fullyParallel: true,  // 🔑 병렬 실행
      forbidOnly: !!process.env.CI,
      retries: process.env.CI ? 2 : 0,
      workers: process.env.CI ? 1 : undefined,
      reporter: 'html',
      use: {
        baseURL: 'http://localhost:3000',
        trace: 'on-first-retry',
        screenshot: 'only-on-failure',
        video: 'retain-on-failure',
      },
      projects: [
        {
          name: 'chromium',
          use: { ...devices['Desktop Chrome'] },
        },
        {
          name: 'firefox',
          use: { ...devices['Desktop Firefox'] },
        },
        {
          name: 'webkit',
          use: { ...devices['Desktop Safari'] },
        },
      ],
    });
    \`\`\`
  `,
  auto_approve: true
});
```

### Step 5: 테스트 실행

```bash
# Playwright 설치 (처음만)
npm install -D @playwright/test
npx playwright install

# 100개 테스트 병렬 실행
npx playwright test --workers=10

# 결과 확인
npx playwright show-report
```

### Step 6: Healer - 실패한 테스트 자동 수정

```javascript
// 테스트 실행 결과 분석
const testResults = await execSync('npx playwright test --reporter=json');
const results = JSON.parse(testResults);

// 실패한 테스트 추출
const failures = results.suites
  .flatMap(s => s.specs)
  .filter(spec => spec.tests.some(t => t.status === 'failed'));

console.log(`${failures.length} tests failed. Starting Healers...`);

// 각 실패 테스트마다 Healer 에이전트 실행
const healers = failures.map(failure =>
  Task({
    subagent_type: "general-purpose",
    description: `Fix test: ${failure.title}`,
    prompt: `
      You are a Playwright Test Healer.

      This test failed:
      ${JSON.stringify(failure, null, 2)}

      Error message:
      ${failure.tests[0].results[0].error.message}

      Common issues:
      - Wrong selector (element not found)
      - Timing issue (element not ready)
      - Assertion mismatch
      - Test data problem

      Steps:
      1. Analyze the error
      2. Read the test file: ${failure.file}
      3. Identify root cause
      4. Fix the test code
      5. Verify fix would work

      Output the fixed test file.
    `,
    auto_approve: true,
    run_in_background: true
  })
);

await Promise.all(healers.map(h => TaskOutput({ task_id: h.id })));

console.log("Healers completed. Re-running tests...");

// 재실행
await execSync('npx playwright test');
```

## Examples

### Example 1: E-commerce 전체 테스트 생성

**입력:**
```javascript
const website = "https://example-ecommerce.com";
```

**결과:**
```
Planner 분석 결과:
- 총 120개 시나리오

카테고리별:
- Authentication: 15개 (로그인, 회원가입, 로그아웃 등)
- Product: 30개 (목록, 상세, 검색, 필터)
- Cart: 20개 (추가, 삭제, 수량 변경)
- Checkout: 25개 (배송지, 결제, 쿠폰)
- User: 15개 (프로필, 주문내역)
- Admin: 15개 (상품 관리, 주문 관리)

Generator: 120개 테스트 파일 생성 (30분)
Healer: 12개 실패 케이스 수정 (10분)

최종: 120개 E2E 테스트 완성 (1시간)
```

### Example 2: SaaS 대시보드 테스트

**입력:**
```javascript
const website = "https://analytics-dashboard.com";
```

**결과:**
```
시나리오:
- 차트 렌더링: 20개
- 데이터 필터: 15개
- 날짜 범위 선택: 10개
- 내보내기 (CSV/PDF): 8개
- 실시간 업데이트: 12개
- 권한 테스트: 10개

총 75개 테스트 생성 (40분)
```

### Example 3: 블로그 플랫폼

**입력:**
```javascript
const website = "https://my-blog-platform.com";
```

**결과:**
```
시나리오:
- 글 작성/수정/삭제: 15개
- Markdown 렌더링: 10개
- 댓글 기능: 12개
- 카테고리/태그: 8개
- 검색: 10개

총 55개 테스트 생성 (30분)
```

## Key Concepts

- **E2E (End-to-End) Testing**: 실제 사용자 관점의 전체 플로우 테스트
- **Playwright**: 브라우저 자동화 도구 (Selenium의 현대적 대안)
- **Page Object Pattern**: 테스트 코드 재사용성 향상 패턴
- **Test Scenario**: 하나의 완결된 사용자 행동 시나리오
- **Parallel Execution**: 여러 테스트 동시 실행으로 시간 절약
- **Flaky Test**: 가끔 실패하는 불안정한 테스트 (Healer로 수정)

## Common Pitfalls

### 1. 의존성 있는 테스트
```
❌ 나쁜 예:
Test #1: 회원가입 → DB에 유저 생성
Test #2: Test #1의 유저로 로그인
→ Test #1 실패하면 Test #2도 실패

✅ 좋은 예:
Test #1: 회원가입 (자체 테스트 유저)
Test #2: 로그인 (자체 테스트 유저)
→ 완전 독립
```

### 2. Hard-coded 대기 시간
```
❌ 나쁜 예:
await page.waitForTimeout(5000);  // 5초 무조건 대기

✅ 좋은 예:
await page.waitForSelector('.welcome');  // 요소 나타날 때까지만
```

### 3. 취약한 Selector
```
❌ 나쁜 예:
page.locator('div > div > button')  // DOM 구조 바뀌면 깨짐

✅ 좋은 예:
page.locator('[data-testid="login-button"]')  // 안정적
```

### 4. 공유 상태
```
❌ 나쁜 예:
전역 변수로 상태 공유 → 병렬 실행 시 충돌

✅ 좋은 예:
각 테스트가 독립적인 데이터 사용
```

### 5. 스크린샷/비디오 미설정
```
❌ 나쁜 예:
테스트 실패 시 이유 모름

✅ 좋은 예:
screenshot: 'only-on-failure'
video: 'retain-on-failure'
```

## Tips and Best Practices

### 테스트 네이밍 규칙

```
[feature]-[action]-[expected-result]

예시:
- login-valid-credentials-success
- login-invalid-password-error-shown
- cart-add-product-count-increases
- checkout-apply-coupon-discount-applied
```

### 테스트 데이터 관리

```typescript
// fixtures/testData.ts
export const testUsers = {
  validUser: {
    email: 'test@example.com',
    password: 'Test123!'
  },
  adminUser: {
    email: 'admin@example.com',
    password: 'Admin123!'
  }
};

export const testProducts = {
  product1: {
    name: 'Test Product',
    price: 29.99
  }
};
```

### 병렬 실행 최적화

```typescript
// playwright.config.ts
export default defineConfig({
  workers: process.env.CI ? 2 : 10,  // CI에서는 2개, 로컬에서는 10개
  fullyParallel: true,
  maxFailures: process.env.CI ? 10 : undefined,  // CI에서는 10개 실패 시 중단
});
```

### 재시도 전략

```typescript
test.describe('Flaky test', () => {
  test.describe.configure({ retries: 3 });  // 이 그룹만 3번 재시도

  test('might fail sometimes', async ({ page }) => {
    // ...
  });
});
```

## Performance Metrics

| 테스트 수 | 수동 작성 | 자동 생성 | 절감 시간 |
|---------|---------|----------|----------|
| 10개 | 10시간 | 10분 | 9.8시간 |
| 50개 | 50시간 | 30분 | 49.5시간 |
| 100개 | 100시간 | 1시간 | 99시간 |
| 500개 | 500시간 | 5시간 | 495시간 |

**병렬 실행 효과:**
- 100개 테스트 순차 실행: 100분
- 100개 테스트 병렬 실행 (10 workers): **10분**

## Related Resources

- **Original Video**: [클로드코드 최애 기능](https://www.youtube.com/watch?v=prTGyqWMxw8) (00:33, 10:06, 12:47)
- **Playwright Docs**: https://playwright.dev/
- **Related Skills**:
  - claude-code-yolo-mode.md (YOLO 필수)
  - parallel-dev-team.md (QA Agent 파트)
  - massive-parallel-orchestrator.md (대규모 실행)

## Tags

#Playwright #E2E테스트 #자동화테스트 #병렬테스트생성 #100개테스트 #테스트시나리오 #QA자동화 #웹테스트 #통합테스트 #테스트커버리지 #PageObject #테스트자동생성

---

## 💡 Quick Start

```bash
# 1. Planner 실행
const plan = await playwrightPlanner("https://your-website.com");

# 2. 100개 Generator 병렬 실행 (YOLO 모드)
const tests = await generateTests(plan.scenarios);

# 3. 테스트 실행
npx playwright test --workers=10

# 결과: 100개 E2E 테스트 1시간 만에 완성! 🎉
```
