# Skill Catalog

my-claude-vible에 포함된 모든 스킬의 상세 목록입니다.

## 목차

1. [Orchestrators & Automation](#orchestrators--automation)
2. [Development & Scaffolding](#development--scaffolding)
3. [Analysis & Quality](#analysis--quality)
4. [Web & Frontend](#web--frontend)
5. [Utilities & Tools](#utilities--tools)

---

## Orchestrators & Automation

### `/auto` - Intelligent Orchestrator ⭐ NEW
**파일:** `intelligent-orchestrator.md` (22KB)
**설명:** 자연어 요청을 분석하여 적절한 스킬/에이전트를 자동 선택하고 실행하는 최상위 조율자

**주요 기능:**
- 자동 요청 분석 및 키워드 추출
- 30개 스킬 데이터베이스 자동 매칭
- 투명한 실행 계획 제시
- 사용 통계 추적 (`~/.claude/skill-usage-stats.json`)
- Plan 모드 / 실행 모드 지원

**사용 예시:**
```bash
/auto "planning.md 파일대로 풀스택 웹서비스 만들어줘"
/auto "의존성 분석하고 성능 개선 제안해줘"
/auto "테스트 커버리지 100% 만들어줘"
```

**내부 동작:**
1. 요청 분석 → 키워드 추출
2. 스킬 매칭 (설명 10점, 태그 5점, 사용빈도 보너스)
3. 실행 계획 생성
4. 순차/병렬 실행
5. 통계 기록

---

### `/massive-parallel-orchestrator` - Massive Parallel Orchestrator
**파일:** `massive-parallel-orchestrator.md` (19KB)
**설명:** 대규모 병렬 작업 처리 시스템

**주요 기능:**
- 수백 개 파일 동시 처리
- 자동 배치 분할 및 부하 분산
- 진행 상황 실시간 모니터링
- 실패 복구 및 재시도 로직

**사용 예시:**
```bash
/massive-parallel-orchestrator "src/ 디렉토리의 모든 JS 파일에 JSDoc 추가"
/massive-parallel-orchestrator "1000개 테스트 파일 병렬 실행"
```

**적합한 작업:**
- 대량 파일 변환/수정
- 배치 테스트 실행
- 일괄 리팩토링

---

### `/parallel-dev-team` - Parallel Dev Team
**파일:** `parallel-dev-team.md` (34KB)
**설명:** 다중 페르소나 협업 개발 시스템

**페르소나:**
- 아키텍트 (설계)
- 프론트엔드 개발자
- 백엔드 개발자
- 보안 전문가
- DevOps 엔지니어
- QA 엔지니어

**사용 예시:**
```bash
/parallel-dev-team "사용자 인증 시스템 구축"
```

---

### `/yolo` - YOLO Mode
**파일:** `claude-code-yolo-mode.md` (15KB)
**설명:** 자동 승인 모드로 무인 작업 실행

**주요 기능:**
- 모든 작업 자동 승인
- 에러 시 자동 복구
- 백업 자동 생성
- 롤백 지원

**사용 예시:**
```bash
/yolo "전체 프로젝트 TypeScript 마이그레이션"
```

⚠️ **주의:** 중요한 작업 전 백업 필수

---

### `/notebooklm-research-automation` - NotebookLM Research Automation
**파일:** `notebooklm-research-automation.md` (~20KB)
**설명:** NotebookLM MCP를 활용한 AI 에이전트 기반 리서치 자동화 시스템

**주요 기능:**
- NotebookLM MCP 설치/인증 가이드
- 6단계 리서치 워크플로우 (기획→수집→딥리서치→평가→종합→프로토타입)
- 에이전트 경쟁 패턴 (다관점 4-Persona 평가)
- 리서치→프로토타입 파이프라인 (antigravity/fullstack-scaffold 연계)
- MCP 미설치 시 대체 모드 지원

**사용 예시:**
```bash
"AI 1인기업 수익화 아이디어 10개 찾아줘"
"SaaS 경쟁사 3곳 심층 분석해줘"
"2026 테크 트렌드 리포트 만들어줘"
```

**연관 에이전트:** `research-planner`, `research-collector`, `research-evaluator`, `research-synthesizer`

---

## Development & Scaffolding

### `/fullstack-scaffold` - Fullstack Scaffold
**파일:** `fullstack-scaffold.md`
**설명:** 풀스택 프로젝트 자동 생성기

**지원 스택:**
- React + Express + PostgreSQL
- Vue + Fastify + MongoDB
- Next.js + Prisma
- Svelte + Supabase

**사용 예시:**
```bash
/fullstack-scaffold "e-commerce-platform"
```

**생성 항목:**
- 프로젝트 구조
- 인증/권한 시스템
- API 엔드포인트
- 데이터베이스 스키마
- Docker 설정

---

### `/antigravity-website-builder` - Antigravity Website Builder
**파일:** `antigravity-website-builder.md` (15KB)
**설명:** 15초 웹사이트 빌더 - 즉시 배포 가능한 완성형 웹사이트 생성

**주요 기능:**
- 템플릿 기반 자동 생성
- 반응형 디자인
- SEO 최적화
- 성능 최적화

**사용 예시:**
```bash
/antigravity-website-builder "개인 포트폴리오"
/antigravity-website-builder "스타트업 랜딩 페이지"
```

---

### `/component-generator` - Component Generator
**파일:** `component-generator.md`
**설명:** React/Vue/Svelte 컴포넌트 자동 생성

**생성 항목:**
- 컴포넌트 파일
- 스타일 파일
- 스토리북 스토리
- 테스트 파일

**사용 예시:**
```bash
/component-generator "UserProfileCard" --framework=react
```

---

## Analysis & Quality

### `/dependency-analyzer` - Dependency Analyzer
**파일:** `dependency-analyzer.md` (18KB)
**설명:** 의존성 분석 및 최적화 도구

**분석 항목:**
- 사용하지 않는 의존성 탐지
- 버전 충돌 분석
- 보안 취약점 검사
- 번들 크기 분석
- 라이선스 호환성

**사용 예시:**
```bash
/dependency-analyzer "."
/dependency-analyzer "src/components" --deep
```

**출력:**
- 의존성 트리 시각화
- 개선 제안
- 제거 가능한 패키지 목록

---

### `/code-reviewer` - Code Reviewer
**파일:** `code-reviewer.md`
**설명:** 자동 코드 리뷰 시스템

**검토 항목:**
- 코드 품질
- 베스트 프랙티스 준수
- 보안 취약점
- 성능 이슈
- 테스트 커버리지

**사용 예시:**
```bash
/code-reviewer "src/api/auth.js"
/code-reviewer "." --full
```

---

### `/test-generator` - Test Generator
**파일:** `test-generator.md`
**설명:** 자동 테스트 생성기

**지원 프레임워크:**
- Jest
- Mocha
- Vitest
- Playwright

**사용 예시:**
```bash
/test-generator "src/utils/calculator.js"
/test-generator "src/components/" --coverage=100
```

---

### `/performance-optimizer` - Performance Optimizer
**파일:** `performance-optimizer.md`
**설명:** 성능 분석 및 최적화

**분석 영역:**
- 번들 크기
- 렌더링 성능
- 메모리 사용
- 네트워크 요청

**사용 예시:**
```bash
/performance-optimizer "."
```

---

## Web & Frontend

### `/responsive-designer` - Responsive Designer
**파일:** `responsive-designer.md`
**설명:** 반응형 디자인 자동 변환

**브레이크포인트:**
- Mobile: 320px-768px
- Tablet: 768px-1024px
- Desktop: 1024px+

**사용 예시:**
```bash
/responsive-designer "src/components/Header.jsx"
```

---

### `/seo-optimizer` - SEO Optimizer
**파일:** `seo-optimizer.md`
**설명:** SEO 최적화 도구

**최적화 항목:**
- 메타 태그
- Open Graph
- 구조화된 데이터
- 사이트맵 생성

**사용 예시:**
```bash
/seo-optimizer "."
```

---

### `/accessibility-checker` - Accessibility Checker
**파일:** `accessibility-checker.md`
**설명:** 접근성(A11y) 검사 및 개선

**검사 항목:**
- WCAG 2.1 준수
- ARIA 속성
- 키보드 네비게이션
- 색상 대비

**사용 예시:**
```bash
/accessibility-checker "src/pages"
```

---

## Utilities & Tools

### `/git-wizard` - Git Wizard
**파일:** `git-wizard.md`
**설명:** Git 작업 자동화

**기능:**
- 커밋 메시지 자동 생성
- 브랜치 관리
- 충돌 해결 지원

**사용 예시:**
```bash
/git-wizard "commit"
/git-wizard "merge develop into main"
```

---

### `/docs-generator` - Documentation Generator
**파일:** `docs-generator.md`
**설명:** 자동 문서 생성기

**생성 문서:**
- API 문서
- 컴포넌트 문서
- README
- CHANGELOG

**사용 예시:**
```bash
/docs-generator "src/api"
```

---

### `/env-manager` - Environment Manager
**파일:** `env-manager.md`
**설명:** 환경 변수 관리 도구

**기능:**
- .env 파일 생성
- 환경별 분리
- 보안 검증

**사용 예시:**
```bash
/env-manager "setup production"
```

---

### `/migration-assistant` - Migration Assistant
**파일:** `migration-assistant.md`
**설명:** 프레임워크 마이그레이션 지원

**지원 마이그레이션:**
- JavaScript → TypeScript
- Webpack → Vite
- Class Components → Hooks
- REST → GraphQL

**사용 예시:**
```bash
/migration-assistant "js-to-ts"
```

---

## Mobile & Native Apps

### `/hotwire-native` - Hotwire Native Framework ⭐ NEW
**파일:** `skills/hotwire-native-framework/`
**설명:** Rails 웹앱 하나로 iOS/Android 네이티브 앱을 만드는 Hotwire Native 프레임워크

**주요 기능:**
- Turbo Native 패턴 가이드
- Bridge Components (카메라, 푸시 알림, 생체 인증 등)
- iOS/Android 배포 가이드
- 성능 최적화 & 보안 베스트 프랙티스

**포함 문서:**
- `SKILL.md` - 메인 가이드
- `references/01-turbo-native-patterns.md` - 내비게이션 패턴
- `references/02-bridge-components.md` - 네이티브 기능 연동
- `references/03-deployment-guide.md` - 앱 스토어 배포
- `references/04-best-practices.md` - 최적화 & 보안

**사용 예시:**
```bash
# 지식 질문
"Hotwire Native에서 카메라 연동 어떻게 해?"

# 프로젝트 생성 (에이전트 연동)
"Hotwire Native로 todo 앱 만들어줘"
```

**관련 에이전트:** `agents/frontend/hotwire-native.md`

---

## 추가 스킬 (Alphabetical)

### `/api-client-generator`
REST/GraphQL API 클라이언트 자동 생성

### `/backup-manager`
프로젝트 백업 및 복원 관리

### `/ci-cd-setup`
CI/CD 파이프라인 자동 구성

### `/container-builder`
Docker/Kubernetes 설정 생성

### `/error-tracker`
에러 추적 및 로깅 시스템 구축

### `/i18n-generator`
다국어 지원 시스템 구축

### `/monitoring-setup`
모니터링 및 알람 시스템 구성

### `/schema-designer`
데이터베이스 스키마 설계 도구

### `/security-audit`
보안 감사 및 취약점 스캔

---

## Agent Quick Reference

| 카테고리 | 에이전트 | 연관 스킬 |
|---------|---------|-----------|
| Database | db-architect, db-query, db-migration, db-indexing, db-scaling, db-nosql | database-admin |
| API | api-designer, api-implementer, api-validator, api-gateway, api-versioning | api-docs-automation |
| Frontend | ui-component, ui-state, ui-a11y, ui-styling, ui-performance, hotwire-native | design-system |
| Backend | service-logic, auth-architect, integration-api, service-resilience, service-caching, realtime-services, background-jobs | fullstack-scaffold |
| Search & Data | search-engine, vector-search, message-queue, data-pipeline | - |
| Infrastructure | iac-architect, container-k8s, docker-specialist, serverless-architect, cicd-pipeline, deployment-strategy, cloud-cost | ci-cd-pipelines |
| Testing | test-unit, test-integration, test-e2e, test-performance, test-security, test-contract, test-mutation, test-visual | qa-tester |
| Security | security-audit, security-threat, security-secrets, security-compliance, security-sca, security-penetration | security-audit |
| ML/AI | ml-training, ml-inference, ml-deployment, ml-monitoring, ml-data | - |
| Mobile | mobile-crossplatform, mobile-native, mobile-testing | mobile-app-development |
| Observability | metrics-architect, logging-architect, tracing-architect, incident-response | production-monitoring |
| Documentation | doc-technical, doc-api-spec, doc-architecture, doc-changelog | tech-writer |
| Git & Collab | git-workflow, code-review | code-review |
| Architecture | arch-system, arch-microservices, arch-event-driven, arch-data | tech-lead |
| **Research** | **research-planner, research-collector, research-evaluator, research-synthesizer** | **notebooklm-research-automation** |

---

## 통계

- **총 스킬 수:** 55개
- **총 에이전트 수:** 75개 (15개 카테고리)
- **총 용량:** ~500KB+
- **카테고리:** 7개 (스킬) + 15개 (에이전트)
- **최신 추가:** NotebookLM Research Automation (2026-02-03)

---

## 사용 팁

### 1. Intelligent Orchestrator 활용
대부분의 작업은 `/auto`로 시작하세요:
```bash
/auto "API 문서 생성하고 TypeScript 마이그레이션해줘"
```

### 2. 스킬 조합
여러 스킬을 순차적으로 사용:
```bash
/fullstack-scaffold "my-app"
/test-generator "src/"
/docs-generator "src/"
```

### 3. 통계 확인
자주 사용하는 스킬 파악:
```bash
cat ~/.claude/skill-usage-stats.json
```

---

**마지막 업데이트:** 2026-02-03
**버전:** 1.2.0
