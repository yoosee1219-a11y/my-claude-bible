---
name: parallel-dev-team
description: 병렬개발팀, 멀티에이전트, 역할분산, 동시개발, 디자인에이전트, 아키텍처, 프론트엔드, 백엔드, QA자동화, 디버깅, 퍼블리싱, 웹개발가속, 팀워크자동화, 100배빠른개발로 개발 작업을 역할별 전문 에이전트로 분산하여 동시 진행하는 병렬 개발팀 스킬
---

# parallel-dev-team

## Overview

**하나의 프로젝트, 여러 명의 전문가가 동시에 작업하는 것처럼!**

웹사이트나 앱을 개발할 때 디자이너, 아키텍트, 프론트엔드, 백엔드, QA 전문가들이 **각자 동시에** 작업하면 얼마나 빠를까요? 이 스킬은 Claude Code의 Subagents를 활용해 개발 작업을 **역할별로 분산**시켜 **병렬로 진행**합니다.

### 가상 개발팀 구성:

```
                    [Project Manager Agent]
                            ↓
    ┌───────────┬──────────┼──────────┬───────────┬──────────┐
    ↓           ↓          ↓          ↓           ↓          ↓
[Architect] [Designer] [Frontend] [Backend] [QA/Test] [DevOps]
    ↓           ↓          ↓          ↓           ↓          ↓
 API 설계   UI/UX    React/Vue   Node.js    자동화    배포자동화
 DB 스키마   컬러팔레트  컴포넌트   API구현   테스트작성   CI/CD
 아키텍처   프로토타입  상태관리   인증구현   버그검증   모니터링
```

**전통 방식**: 순차적으로 6단계 → 6주
**Parallel Dev Team**: 동시에 6개 역할 → **1주**

## When to Use This Skill

### ✅ 이 스킬을 사용하세요:

- **대규모 웹/앱 개발**: 복잡한 프로젝트를 빠르게 진행
- **스타트업 MVP**: 빠른 시장 출시 필요
- **타이트한 데드라인**: 시간이 부족할 때
- **풀스택 개발**: 혼자서 전체를 해야 할 때
- **리팩토링 프로젝트**: 전체 코드베이스 개선
- **새로운 기능 추가**: 여러 레이어 동시 수정 필요

### ⚠️ 이 스킬 대신 전통 방식:

- **매우 간단한 프로젝트**: 정적 페이지 하나
- **학습 목적**: 차근차근 배우고 싶을 때
- **레거시 유지보수**: 작은 버그 수정

### 🔀 두 가지 병행:

- 핵심 기능은 Parallel Dev Team → 세부 조정은 직접
- 프로토타입은 병렬 → 프로덕션은 리뷰 후 최적화

## Prerequisites

- Claude Code 설치 및 기본 사용법 이해
- 개발하려는 프로젝트의 명확한 요구사항
- Task tool 사용 경험 (권장)
- Git 기본 지식
- 충분한 Anthropic API 크레딧 (여러 에이전트 병렬 실행)

## Instructions

### Step 1: Project Manager Agent - 프로젝트 분석 및 역할 분배

전체 프로젝트를 분석하고 각 역할에 할당할 작업을 정의합니다.

**Claude Code에서 실행:**

```javascript
// Project Manager Agent 실행
const projectPlan = await Task({
  subagent_type: "Plan",
  description: "Analyze project and distribute roles",
  prompt: `
    Project: E-commerce website with user authentication,
    product catalog, shopping cart, and payment integration.

    Your role: Project Manager Agent

    Tasks:
    1. Break down the project into independent modules
    2. Assign modules to specialized agents:
       - Architect: System design, DB schema, API structure
       - Designer: UI/UX, color scheme, components
       - Frontend: React components, state management, routing
       - Backend: API endpoints, authentication, database
       - QA: Test cases, automation scripts
       - DevOps: Deployment pipeline, monitoring

    3. Define dependencies (minimal!)
    4. Create parallel execution plan

    Output: JSON with tasks for each agent
  `
});
```

**예상 출력:**

```json
{
  "project": "E-commerce Website",
  "agents": {
    "architect": {
      "tasks": [
        "Design overall system architecture",
        "Define API endpoints structure",
        "Create database schema (Users, Products, Orders)",
        "Define authentication flow"
      ],
      "dependencies": [],
      "estimated_time": "2 hours"
    },
    "designer": {
      "tasks": [
        "Create color palette and typography",
        "Design homepage wireframe",
        "Design product page layout",
        "Create component library (buttons, cards, forms)"
      ],
      "dependencies": [],
      "estimated_time": "2 hours"
    },
    "frontend": {
      "tasks": [
        "Set up React project with Vite",
        "Implement routing (Home, Products, Cart, Checkout)",
        "Create reusable components",
        "Implement state management (Redux/Zustand)"
      ],
      "dependencies": ["designer:color-palette"],
      "estimated_time": "3 hours"
    },
    "backend": {
      "tasks": [
        "Set up Express/FastAPI server",
        "Implement user authentication (JWT)",
        "Create product CRUD APIs",
        "Implement shopping cart logic"
      ],
      "dependencies": ["architect:api-structure"],
      "estimated_time": "3 hours"
    },
    "qa": {
      "tasks": [
        "Write E2E test scenarios",
        "Create unit test templates",
        "Set up Playwright/Cypress",
        "Write API integration tests"
      ],
      "dependencies": ["frontend:routing", "backend:apis"],
      "estimated_time": "2 hours"
    },
    "devops": {
      "tasks": [
        "Create Dockerfile for frontend/backend",
        "Set up CI/CD pipeline (GitHub Actions)",
        "Configure deployment (Vercel/Railway)",
        "Set up monitoring (Sentry/LogRocket)"
      ],
      "dependencies": ["backend:server", "frontend:build"],
      "estimated_time": "2 hours"
    }
  },
  "execution_strategy": "parallel-with-checkpoints"
}
```

### Step 2: 전문 에이전트 병렬 실행

각 역할의 에이전트를 동시에 실행합니다.

#### 2.1 Architect Agent (시스템 설계)

```javascript
const architectAgent = Task({
  subagent_type: "general-purpose",
  description: "Design system architecture",
  prompt: `
    You are a Senior Software Architect.

    Project: E-commerce website

    Your tasks:
    1. Design overall system architecture (microservices vs monolith)
    2. Define API endpoints:
       - POST /api/auth/register
       - POST /api/auth/login
       - GET /api/products
       - POST /api/cart/add
       - POST /api/orders
    3. Create database schema:
       - Users table
       - Products table
       - Orders table
       - Cart_items table
    4. Define authentication strategy (JWT)

    Output:
    - architecture.md
    - api-spec.yaml (OpenAPI format)
    - db-schema.sql
  `,
  run_in_background: true
});
```

#### 2.2 Designer Agent (UI/UX 디자인)

```javascript
const designerAgent = Task({
  subagent_type: "general-purpose",
  description: "Create UI/UX design",
  prompt: `
    You are a Senior UI/UX Designer.

    Project: E-commerce website

    Your tasks:
    1. Create color palette:
       - Primary: Modern, trustworthy (suggest hex codes)
       - Secondary: Call-to-action
       - Neutral: Background, text
    2. Define typography:
       - Headings: (suggest font family)
       - Body: (suggest font family)
    3. Design component library:
       - Button styles (primary, secondary, outline)
       - Card component for products
       - Form inputs
       - Navigation bar
    4. Create wireframes:
       - Homepage layout
       - Product listing page
       - Product detail page
       - Shopping cart page

    Output:
    - design-system.md (color palette, typography, spacing)
    - components-spec.md (component specifications)
    - wireframes.md (ASCII art or descriptions)
  `,
  run_in_background: true
});
```

#### 2.3 Frontend Agent (프론트엔드 개발)

```javascript
const frontendAgent = Task({
  subagent_type: "general-purpose",
  description: "Build frontend application",
  prompt: `
    You are a Senior Frontend Developer (React/TypeScript).

    Project: E-commerce website

    Your tasks:
    1. Set up React + Vite + TypeScript project
    2. Implement routing:
       - / (Home)
       - /products (Product listing)
       - /products/:id (Product detail)
       - /cart (Shopping cart)
       - /checkout (Checkout)
    3. Create components:
       - Navbar
       - ProductCard
       - Cart
       - Button (reusable)
    4. Set up state management (Zustand or Redux)
    5. Implement API integration (fetch/axios)

    Use the design system from Designer Agent.

    Output:
    - Complete React app in /frontend directory
    - README.md with setup instructions
  `,
  run_in_background: true
});
```

#### 2.4 Backend Agent (백엔드 개발)

```javascript
const backendAgent = Task({
  subagent_type: "general-purpose",
  description: "Build backend API",
  prompt: `
    You are a Senior Backend Developer (Node.js/Express).

    Project: E-commerce website

    Your tasks:
    1. Set up Express server with TypeScript
    2. Implement authentication:
       - POST /api/auth/register
       - POST /api/auth/login
       - JWT token generation
    3. Implement product APIs:
       - GET /api/products (list all)
       - GET /api/products/:id (get one)
       - POST /api/products (admin only)
    4. Implement cart APIs:
       - POST /api/cart/add
       - GET /api/cart
       - DELETE /api/cart/:item_id
    5. Implement order API:
       - POST /api/orders
    6. Set up database (PostgreSQL/MongoDB)

    Use the API spec from Architect Agent.

    Output:
    - Complete backend in /backend directory
    - .env.example file
    - README.md with API documentation
  `,
  run_in_background: true
});
```

#### 2.5 QA/Test Agent (테스트 자동화)

```javascript
const qaAgent = Task({
  subagent_type: "general-purpose",
  description: "Create automated tests",
  prompt: `
    You are a Senior QA Engineer (Test Automation).

    Project: E-commerce website

    Your tasks:
    1. Write E2E test scenarios (Playwright):
       - User registration flow
       - Login flow
       - Browse products
       - Add to cart
       - Checkout process
    2. Write frontend unit tests (Vitest):
       - Component rendering tests
       - State management tests
    3. Write backend API tests (Jest/Supertest):
       - Authentication endpoints
       - Product CRUD endpoints
       - Cart operations
    4. Create test data fixtures

    Output:
    - /tests/e2e directory with Playwright tests
    - /frontend/src/__tests__ with component tests
    - /backend/tests with API tests
    - test-plan.md
  `,
  run_in_background: true
});
```

#### 2.6 DevOps Agent (배포 자동화)

```javascript
const devopsAgent = Task({
  subagent_type: "general-purpose",
  description: "Set up deployment pipeline",
  prompt: `
    You are a Senior DevOps Engineer.

    Project: E-commerce website

    Your tasks:
    1. Create Dockerfiles:
       - Frontend (Nginx + React build)
       - Backend (Node.js)
    2. Create docker-compose.yml for local development
    3. Set up CI/CD pipeline (GitHub Actions):
       - Run tests on PR
       - Build Docker images
       - Deploy to staging/production
    4. Configure deployment:
       - Frontend: Vercel or Netlify
       - Backend: Railway or Fly.io
    5. Set up monitoring:
       - Error tracking (Sentry)
       - Analytics (optional)

    Output:
    - Dockerfile (frontend/backend)
    - docker-compose.yml
    - .github/workflows/ci-cd.yml
    - deployment.md (deployment guide)
  `,
  run_in_background: true
});
```

### Step 3: 병렬 실행 및 모니터링

모든 에이전트를 동시에 실행하고 결과를 수집합니다.

```javascript
// 모든 에이전트 병렬 실행
const agents = {
  architect: architectAgent,
  designer: designerAgent,
  frontend: frontendAgent,
  backend: backendAgent,
  qa: qaAgent,
  devops: devopsAgent
};

console.log("🚀 Starting parallel dev team...");
console.log("6 agents working simultaneously!");

// 완료 대기
const results = await Promise.all(
  Object.entries(agents).map(async ([role, agent]) => {
    console.log(`⏳ ${role} agent is working...`);
    const result = await TaskOutput({
      task_id: agent.id,
      block: true
    });
    console.log(`✅ ${role} agent completed!`);
    return { role, result };
  })
);

console.log("🎉 All agents completed!");
```

### Step 4: Integration Agent - 통합 및 조율

각 에이전트의 작업물을 통합합니다.

```javascript
const integrationAgent = await Task({
  subagent_type: "general-purpose",
  description: "Integrate all components",
  prompt: `
    You are an Integration Engineer.

    The parallel dev team has completed their work:
    - Architect: ${results.architect.summary}
    - Designer: ${results.designer.summary}
    - Frontend: ${results.frontend.summary}
    - Backend: ${results.backend.summary}
    - QA: ${results.qa.summary}
    - DevOps: ${results.devops.summary}

    Your tasks:
    1. Review all components for compatibility
    2. Integrate frontend with backend (API connections)
    3. Apply design system to frontend components
    4. Ensure database schema matches backend code
    5. Run integration tests
    6. Fix any conflicts or mismatches

    Output:
    - integration-report.md
    - List of issues found and fixed
    - Final working application
  `
});
```

### Step 5: Specialized Debugger Agents - 분야별 전문 디버깅

각 분야별 전문 디버거가 **자기 영역의 실패만** 계속 디버깅합니다.

#### 5.1 테스트 실행 및 실패 분류

```javascript
// 전체 테스트 실행
console.log("Running all tests...");

const testResults = await Task({
  subagent_type: "general-purpose",
  description: "Run all tests",
  prompt: "Run frontend tests, backend tests, E2E tests, and integration tests"
});

// 실패를 분야별로 분류
const failures = {
  frontend: testResults.failures.filter(f => f.type === 'frontend'),
  backend: testResults.failures.filter(f => f.type === 'backend'),
  database: testResults.failures.filter(f => f.type === 'database'),
  integration: testResults.failures.filter(f => f.type === 'integration'),
  ui_ux: testResults.failures.filter(f => f.type === 'ui'),
  devops: testResults.failures.filter(f => f.type === 'deployment')
};

console.log(`📊 Failures by domain:
  Frontend: ${failures.frontend.length}
  Backend: ${failures.backend.length}
  Database: ${failures.database.length}
  Integration: ${failures.integration.length}
  UI/UX: ${failures.ui_ux.length}
  DevOps: ${failures.devops.length}
`);
```

#### 5.2 분야별 디버거 병렬 실행

각 디버거는 **자기 분야만** 집중적으로 디버깅합니다.

```javascript
// Frontend Debugger - React/UI 이슈만 디버깅
const frontendDebugger = async (failures) => {
  let remainingFailures = failures;
  let iteration = 1;

  while (remainingFailures.length > 0 && iteration <= 5) {
    console.log(`🔧 Frontend Debugger - Iteration ${iteration}`);
    console.log(`   Fixing ${remainingFailures.length} frontend issues...`);

    const debugTask = await Task({
      subagent_type: "general-purpose",
      description: `Frontend debugging iteration ${iteration}`,
      prompt: `
        You are a Frontend Debugging Specialist (React/TypeScript).

        Failed tests:
        ${JSON.stringify(remainingFailures, null, 2)}

        Your expertise:
        - React component errors
        - State management issues
        - Routing problems
        - CSS/styling bugs
        - Event handler errors

        For each failure:
        1. Analyze the root cause
        2. Fix the code
        3. Verify the fix

        Only work on frontend issues. Ignore backend/API failures.

        Return: List of fixed issues and remaining issues.
      `
    });

    // 남은 실패 케이스 업데이트
    remainingFailures = debugTask.result.remaining_failures;
    iteration++;

    if (remainingFailures.length === 0) {
      console.log(`   ✅ All frontend issues fixed!`);
    }
  }

  return {
    domain: 'frontend',
    iterations: iteration - 1,
    final_failures: remainingFailures
  };
};

// Backend Debugger - API/서버 이슈만 디버깅
const backendDebugger = async (failures) => {
  let remainingFailures = failures;
  let iteration = 1;

  while (remainingFailures.length > 0 && iteration <= 5) {
    console.log(`🔧 Backend Debugger - Iteration ${iteration}`);
    console.log(`   Fixing ${remainingFailures.length} backend issues...`);

    const debugTask = await Task({
      subagent_type: "general-purpose",
      description: `Backend debugging iteration ${iteration}`,
      prompt: `
        You are a Backend Debugging Specialist (Node.js/Express).

        Failed tests:
        ${JSON.stringify(remainingFailures, null, 2)}

        Your expertise:
        - API endpoint errors (404, 500)
        - Authentication/authorization bugs
        - Database query issues
        - Server configuration problems
        - Middleware errors

        For each failure:
        1. Check error logs
        2. Identify root cause
        3. Fix the code
        4. Add error handling if needed

        Only work on backend issues. Ignore frontend failures.

        Return: List of fixed issues and remaining issues.
      `
    });

    remainingFailures = debugTask.result.remaining_failures;
    iteration++;

    if (remainingFailures.length === 0) {
      console.log(`   ✅ All backend issues fixed!`);
    }
  }

  return {
    domain: 'backend',
    iterations: iteration - 1,
    final_failures: remainingFailures
  };
};

// Database Debugger - DB/쿼리 이슈만 디버깅
const databaseDebugger = async (failures) => {
  let remainingFailures = failures;
  let iteration = 1;

  while (remainingFailures.length > 0 && iteration <= 5) {
    console.log(`🔧 Database Debugger - Iteration ${iteration}`);
    console.log(`   Fixing ${remainingFailures.length} database issues...`);

    const debugTask = await Task({
      subagent_type: "general-purpose",
      description: `Database debugging iteration ${iteration}`,
      prompt: `
        You are a Database Debugging Specialist (PostgreSQL/MongoDB).

        Failed tests:
        ${JSON.stringify(remainingFailures, null, 2)}

        Your expertise:
        - SQL/NoSQL query optimization
        - Schema mismatches
        - Index issues
        - Connection pool problems
        - Transaction errors

        For each failure:
        1. Analyze the query
        2. Check schema compatibility
        3. Fix the issue
        4. Optimize if needed

        Only work on database issues.

        Return: List of fixed issues and remaining issues.
      `
    });

    remainingFailures = debugTask.result.remaining_failures;
    iteration++;

    if (remainingFailures.length === 0) {
      console.log(`   ✅ All database issues fixed!`);
    }
  }

  return {
    domain: 'database',
    iterations: iteration - 1,
    final_failures: remainingFailures
  };
};

// UI/UX Debugger - 디자인/스타일 이슈만 디버깅
const uiDebugger = async (failures) => {
  let remainingFailures = failures;
  let iteration = 1;

  while (remainingFailures.length > 0 && iteration <= 5) {
    console.log(`🔧 UI/UX Debugger - Iteration ${iteration}`);
    console.log(`   Fixing ${remainingFailures.length} UI issues...`);

    const debugTask = await Task({
      subagent_type: "general-purpose",
      description: `UI debugging iteration ${iteration}`,
      prompt: `
        You are a UI/UX Debugging Specialist.

        Failed tests:
        ${JSON.stringify(remainingFailures, null, 2)}

        Your expertise:
        - CSS layout problems (flexbox, grid)
        - Responsive design issues
        - Color/typography inconsistencies
        - Accessibility (a11y) violations
        - Animation/transition bugs

        For each failure:
        1. Identify visual/UX issue
        2. Fix CSS/styling
        3. Ensure design system consistency
        4. Test across screen sizes

        Only work on UI/UX issues.

        Return: List of fixed issues and remaining issues.
      `
    });

    remainingFailures = debugTask.result.remaining_failures;
    iteration++;

    if (remainingFailures.length === 0) {
      console.log(`   ✅ All UI/UX issues fixed!`);
    }
  }

  return {
    domain: 'ui_ux',
    iterations: iteration - 1,
    final_failures: remainingFailures
  };
};

// Integration Debugger - 통합 이슈만 디버깅
const integrationDebugger = async (failures) => {
  let remainingFailures = failures;
  let iteration = 1;

  while (remainingFailures.length > 0 && iteration <= 5) {
    console.log(`🔧 Integration Debugger - Iteration ${iteration}`);
    console.log(`   Fixing ${remainingFailures.length} integration issues...`);

    const debugTask = await Task({
      subagent_type: "general-purpose",
      description: `Integration debugging iteration ${iteration}`,
      prompt: `
        You are an Integration Debugging Specialist.

        Failed tests:
        ${JSON.stringify(remainingFailures, null, 2)}

        Your expertise:
        - Frontend-Backend API mismatches
        - CORS issues
        - Data format inconsistencies
        - Authentication token problems
        - WebSocket connection issues

        For each failure:
        1. Check both sides (frontend + backend)
        2. Identify mismatch
        3. Coordinate the fix
        4. Ensure data flow works

        Only work on integration issues.

        Return: List of fixed issues and remaining issues.
      `
    });

    remainingFailures = debugTask.result.remaining_failures;
    iteration++;

    if (remainingFailures.length === 0) {
      console.log(`   ✅ All integration issues fixed!`);
    }
  }

  return {
    domain: 'integration',
    iterations: iteration - 1,
    final_failures: remainingFailures
  };
};

// DevOps Debugger - 배포/인프라 이슈만 디버깅
const devopsDebugger = async (failures) => {
  let remainingFailures = failures;
  let iteration = 1;

  while (remainingFailures.length > 0 && iteration <= 5) {
    console.log(`🔧 DevOps Debugger - Iteration ${iteration}`);
    console.log(`   Fixing ${remainingFailures.length} deployment issues...`);

    const debugTask = await Task({
      subagent_type: "general-purpose",
      description: `DevOps debugging iteration ${iteration}`,
      prompt: `
        You are a DevOps Debugging Specialist.

        Failed tests:
        ${JSON.stringify(remainingFailures, null, 2)}

        Your expertise:
        - Docker build failures
        - CI/CD pipeline errors
        - Environment variable issues
        - Deployment configuration bugs
        - Port/networking problems

        For each failure:
        1. Check logs
        2. Identify configuration issue
        3. Fix Dockerfile/docker-compose/CI config
        4. Verify deployment

        Only work on DevOps issues.

        Return: List of fixed issues and remaining issues.
      `
    });

    remainingFailures = debugTask.result.remaining_failures;
    iteration++;

    if (remainingFailures.length === 0) {
      console.log(`   ✅ All DevOps issues fixed!`);
    }
  }

  return {
    domain: 'devops',
    iterations: iteration - 1,
    final_failures: remainingFailures
  };
};

// 🚀 모든 디버거 병렬 실행!
console.log("🚀 Starting specialized debuggers in parallel...");

const debugResults = await Promise.all([
  frontendDebugger(failures.frontend),
  backendDebugger(failures.backend),
  databaseDebugger(failures.database),
  uiDebugger(failures.ui_ux),
  integrationDebugger(failures.integration),
  devopsDebugger(failures.devops)
]);

// 최종 결과 요약
console.log("\n📊 Debugging Summary:");
debugResults.forEach(result => {
  const status = result.final_failures.length === 0 ? '✅' : '⚠️';
  console.log(`${status} ${result.domain}: ${result.iterations} iterations, ` +
              `${result.final_failures.length} remaining failures`);
});

const totalRemaining = debugResults.reduce(
  (sum, r) => sum + r.final_failures.length, 0
);

if (totalRemaining === 0) {
  console.log("\n🎉 All issues fixed! Application is ready!");
} else {
  console.log(`\n⚠️ ${totalRemaining} issues remaining. Manual review needed.`);
}
```

#### 5.3 디버깅 루프 시각화

```
초기 테스트 실행:
  Frontend: 12개 실패 ❌
  Backend: 8개 실패 ❌
  Database: 5개 실패 ❌
  UI/UX: 3개 실패 ❌
  Integration: 7개 실패 ❌
  DevOps: 2개 실패 ❌

병렬 디버깅 Iteration 1:
  Frontend Debugger  → 7개 수정, 5개 남음
  Backend Debugger   → 5개 수정, 3개 남음
  Database Debugger  → 4개 수정, 1개 남음
  UI Debugger        → 3개 수정, 0개 남음 ✅
  Integration Debug  → 4개 수정, 3개 남음
  DevOps Debugger    → 2개 수정, 0개 남음 ✅

병렬 디버깅 Iteration 2:
  Frontend Debugger  → 4개 수정, 1개 남음
  Backend Debugger   → 3개 수정, 0개 남음 ✅
  Database Debugger  → 1개 수정, 0개 남음 ✅
  Integration Debug  → 2개 수정, 1개 남음

병렬 디버깅 Iteration 3:
  Frontend Debugger  → 1개 수정, 0개 남음 ✅
  Integration Debug  → 1개 수정, 0개 남음 ✅

🎉 모든 이슈 해결 완료!
```

## Examples

### Example 1: E-commerce 웹사이트 (대규모 프로젝트)

**입력:**
```
프로젝트: "풀스택 E-commerce 웹사이트
- 사용자 인증 (회원가입/로그인)
- 상품 카탈로그 (검색, 필터)
- 장바구니
- 결제 연동
- 관리자 패널"
```

**실행:**
- Project Manager: 6개 역할로 분할
- 6개 에이전트 동시 실행 (2~3시간)
- Integration: 통합 및 테스트 (1시간)
- Healer: 이슈 수정 (30분)

**결과:**
- 전체 완성도 85%의 프로젝트
- 총 시간: **4.5시간** (전통 방식: 3~4주)

---

### Example 2: 블로그 플랫폼 (중간 프로젝트)

**입력:**
```
프로젝트: "개인 블로그 플랫폼
- Markdown 에디터
- 글 목록/상세 페이지
- 카테고리 및 태그
- 댓글 시스템
- RSS 피드"
```

**역할 분배:**
- Architect: API 설계, DB 스키마
- Designer: 블로그 테마, 타이포그래피
- Frontend: Next.js 앱, Markdown 렌더러
- Backend: API, 인증, 댓글 관리
- QA: E2E 테스트 (글 작성, 발행)
- DevOps: Vercel 배포, GitHub Actions

**결과:**
- 총 시간: **2시간** (전통: 1~2주)

---

### Example 3: 대시보드 앱 (소규모 프로젝트)

**입력:**
```
프로젝트: "데이터 대시보드
- 차트 시각화 (Chart.js)
- 실시간 데이터 업데이트
- 필터 및 날짜 범위 선택
- 데이터 내보내기 (CSV/PDF)"
```

**역할 분배:**
- Architect: 데이터 구조, API
- Designer: 대시보드 레이아웃, 차트 스타일
- Frontend: React + Chart.js
- Backend: 데이터 API, WebSocket
- QA: 차트 정확도 테스트
- DevOps: 도커 컨테이너, 배포

**결과:**
- 총 시간: **1.5시간** (전통: 3~5일)

---

### Example 4: 모바일 앱 (React Native)

**입력:**
```
프로젝트: "투두 리스트 모바일 앱
- 할 일 추가/수정/삭제
- 카테고리 분류
- 알림 기능
- 오프라인 동기화"
```

**역할 분배:**
- Architect: 로컬 DB (SQLite), 동기화 로직
- Designer: 모바일 UI/UX, 아이콘
- Frontend: React Native 앱
- Backend: 동기화 API
- QA: 모바일 E2E 테스트 (Detox)
- DevOps: App Store/Play Store 배포

**결과:**
- 총 시간: **3시간** (전통: 1~2주)

## Key Concepts

- **역할 기반 분산 (Role-based Distribution)**: 각 전문 분야별로 에이전트 할당
- **병렬 실행 (Parallel Execution)**: 여러 에이전트가 동시에 작업
- **의존성 최소화 (Minimal Dependencies)**: 각 역할이 최대한 독립적으로 작업
- **통합 단계 (Integration Phase)**: 모든 작업물을 하나로 합치는 단계
- **자동 치유 (Auto Healing)**: 통합 과정의 문제를 자동으로 수정
- **가상 개발팀 (Virtual Dev Team)**: 실제 팀처럼 역할 분담

## Common Pitfalls

- **과도한 의존성**: 에이전트 간 의존성이 많으면 병렬 효과 감소
  - 해결: Project Manager가 의존성 최소화 설계

- **통합 충돌**: 각 에이전트가 다른 스타일/구조 사용
  - 해결: 명확한 가이드라인 제공, Integration Agent가 통일

- **API 불일치**: Frontend가 기대하는 API와 Backend가 제공하는 API 다름
  - 해결: Architect의 API 명세를 양쪽이 따르도록

- **디자인 시스템 미적용**: Frontend가 Designer의 스타일 무시
  - 해결: Frontend Agent에게 명시적으로 디자인 시스템 참조 지시

- **테스트 누락**: QA Agent가 일부 시나리오만 테스트
  - 해결: Project Manager가 포괄적인 테스트 계획 제공

- **비용 폭발**: 6개+ 에이전트 동시 실행 = 6배 토큰 소비
  - 해결: 작은 프로젝트는 역할 축소 (3~4개만)

## Tips and Best Practices

### 효과적인 역할 분배

**소규모 프로젝트 (3개 에이전트):**
```
1. Architect + Designer (통합)
2. Fullstack Developer (Frontend + Backend)
3. QA + DevOps (통합)
```

**중규모 프로젝트 (5개 에이전트):**
```
1. Architect
2. Designer
3. Frontend Developer
4. Backend Developer
5. QA/DevOps (통합)
```

**대규모 프로젝트 (8개+ 에이전트):**
```
1. Project Manager
2. Architect
3. UI Designer
4. UX Designer
5. Frontend Developer
6. Backend Developer
7. Database Engineer
8. QA Engineer
9. DevOps Engineer
10. Security Engineer
```

### 의존성 관리 전략

**좋은 예:**
```
Architect → API 명세 완성
  ↓ (명세만 공유, 구현은 독립)
Frontend ← → Backend (각자 구현)
  ↓
Integration (연결)
```

**나쁜 예:**
```
Frontend → Backend 완성 대기
  ↓
Backend → DB 스키마 완성 대기
  ↓
순차 실행 (병렬 효과 없음)
```

### 체크포인트 설정

```javascript
// 1단계: 기초 작업 (병렬)
[Architect, Designer] → 완료 대기

// 2단계: 구현 (병렬)
[Frontend, Backend, QA] → 완료 대기

// 3단계: 통합
[Integration] → 완료

// 4단계: 배포
[DevOps] → 완료
```

### 에이전트 프롬프트 템플릿

```
You are a [ROLE] (e.g., Senior Frontend Developer).

Project: [PROJECT_NAME]
Tech Stack: [TECHNOLOGIES]

Context from other agents:
- Architect: [API_SPEC_SUMMARY]
- Designer: [DESIGN_SYSTEM_SUMMARY]

Your tasks:
1. [TASK_1]
2. [TASK_2]
3. [TASK_3]

Rules:
- Work independently (don't wait for others)
- Use provided specs (API spec, design system)
- Output complete, working code
- Document your work in README.md

Output:
- [OUTPUT_1]
- [OUTPUT_2]
```

## Performance Comparison

| 프로젝트 규모 | 전통 개발 | Parallel Dev Team | 속도 향상 |
|-------------|----------|-------------------|----------|
| 소규모 (블로그) | 1~2주 | 2시간 | **40배** |
| 중규모 (E-commerce) | 3~4주 | 4.5시간 | **50배** |
| 대규모 (SaaS) | 2~3개월 | 2일 | **30배** |

**평균 속도 향상: 40배~50배**

## Integration with Other Tools

### Antigravity + Parallel Dev Team

```javascript
// Antigravity로 UI 프로토타입 생성
const antiGravityPrototype = generateWithAntigravity("E-commerce UI");

// Parallel Dev Team으로 풀스택 구현
const fullApp = await Task({
  subagent_type: "general-purpose",
  description: "Build full app based on prototype",
  prompt: `
    Use this Antigravity prototype as reference: ${antiGravityPrototype}

    Build a complete fullstack application with:
    - Frontend matching the prototype design
    - Backend API
    - Database
    - Tests

    Use Parallel Dev Team approach.
  `
});
```

### Web Scraping + Parallel Dev Team

```javascript
// Web Scraping으로 경쟁사 분석
const competitorData = await scrapeCompetitors();

// Parallel Dev Team으로 더 나은 제품 개발
const betterProduct = await parallelDevTeam({
  requirements: `
    Build a product better than competitors:
    ${competitorData.summary}

    Our advantages:
    - Faster UI
    - Better UX
    - More features
  `
});
```

## Related Resources

- **Original Video**: [클로드코드 최애 기능 | 안쓰는 사람 없길 바래요](https://www.youtube.com/watch?v=prTGyqWMxw8)
- **Channel**: 개발동생
- **Claude Code Documentation**: https://docs.anthropic.com/claude-code
- **Task Tool Guide**: https://docs.anthropic.com/claude-code/tools/task
- **Subagents Best Practices**: https://docs.anthropic.com/claude-code/subagents

## Tags

#병렬개발 #멀티에이전트 #가상개발팀 #동시개발 #역할분산 #아키텍처 #프론트엔드 #백엔드 #QA자동화 #DevOps #통합개발 #빠른개발 #ClaudeCode #Subagents #팀워크자동화

---

## 💡 Quick Start Example

```javascript
// 한 줄로 시작하기
const website = await Task({
  subagent_type: "general-purpose",
  description: "Build e-commerce with parallel team",
  prompt: `
    Use the parallel-dev-team approach to build:

    E-commerce website with:
    - Product catalog
    - Shopping cart
    - User authentication
    - Payment integration

    Create a virtual dev team:
    - Architect
    - Designer
    - Frontend (React)
    - Backend (Node.js)
    - QA
    - DevOps

    Run all agents in parallel and integrate the results.
  `
});

console.log("Your complete e-commerce website is ready! 🎉");
```

**결과: 전통적으로 4주 걸릴 프로젝트를 4.5시간 만에 완성!**
