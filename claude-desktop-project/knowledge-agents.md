# Development Agent Ecosystem - 지식 베이스

## 개요
71개의 전문 에이전트와 30+개의 스킬로 구성된 개발 생태계

## 에이전트 카테고리 (14개)

### 1. Database (6개)
- db-architect: DB 스키마 설계, ERD, 정규화
- db-query: 쿼리 최적화, 실행계획
- db-migration: Prisma, Drizzle 마이그레이션
- db-indexing: 인덱스 전략, B-tree, 복합인덱스
- db-scaling: 샤딩, 레플리케이션
- db-nosql: MongoDB, Redis, DynamoDB

### 2. API (5개)
- api-designer: OpenAPI, REST, GraphQL
- api-implementer: Express, Fastify, NestJS
- api-validator: Zod, Joi 검증
- api-gateway: Kong, AWS API Gateway
- api-versioning: 버전관리, 하위호환

### 3. Frontend (6개)
- ui-component: React, Vue, 합성 패턴
- ui-state: Redux, Zustand, TanStack Query
- ui-a11y: WCAG, ARIA, 접근성
- ui-styling: Tailwind, CSS Modules
- ui-performance: 번들 최적화, lazy loading
- hotwire-native: Turbo, Stimulus

### 4. Backend (7개)
- service-logic: DDD, 클린 아키텍처
- auth-architect: JWT, OAuth2, Passkey
- integration-api: 웹훅, SDK 래퍼
- service-resilience: 서킷브레이커, 재시도
- service-caching: Redis, CDN
- realtime-services: WebSocket, Socket.io
- background-jobs: BullMQ, Cron

### 5. Search & Data (4개)
- search-engine: Elasticsearch, Meilisearch
- vector-search: Pinecone, pgvector, RAG
- message-queue: Kafka, RabbitMQ
- data-pipeline: ETL, Airflow, dbt

### 6. Infrastructure (7개)
- iac-architect: Terraform, Pulumi
- container-k8s: Helm, ArgoCD
- docker-specialist: Dockerfile, 멀티스테이지
- serverless-architect: Lambda, Edge Functions
- cicd-pipeline: GitHub Actions, GitLab CI
- deployment-strategy: 블루그린, 카나리
- cloud-cost: RI, Spot, 비용 최적화

### 7. Testing (8개)
- test-unit: Jest, Vitest, 모킹
- test-integration: Supertest, 테스트 컨테이너
- test-e2e: Playwright, Cypress
- test-performance: k6, Artillery
- test-security: SAST, DAST
- test-contract: Pact, 스키마 검증
- test-mutation: Stryker
- test-visual: Percy, Chromatic

### 8. Security (6개)
- security-audit: OWASP Top 10
- security-threat: STRIDE, 위협 모델링
- security-secrets: Vault, AWS Secrets Manager
- security-compliance: GDPR, SOC2
- security-sca: Snyk, Dependabot
- security-penetration: 취약점 스캐닝

### 9. ML/AI (5개)
- ml-training: PyTorch, 하이퍼파라미터
- ml-inference: TensorRT, ONNX
- ml-deployment: MLflow, Kubeflow
- ml-monitoring: 드리프트 감지
- ml-data: 피처 엔지니어링

### 10. Mobile (3개)
- mobile-crossplatform: Flutter, React Native
- mobile-native: Swift, Kotlin
- mobile-testing: Detox, XCTest

### 11. Observability (4개)
- metrics-architect: Prometheus, Grafana
- logging-architect: ELK, 구조화 로깅
- tracing-architect: Jaeger, OpenTelemetry
- incident-response: 온콜, RCA

### 12. Documentation (4개)
- doc-technical: README, 가이드
- doc-api-spec: OpenAPI, Swagger UI
- doc-architecture: ADR, C4 다이어그램
- doc-changelog: 릴리즈 노트

### 13. Git & Collaboration (2개)
- git-workflow: GitFlow, Conventional Commits
- code-review: PR 템플릿, Danger.js

### 14. Architecture (4개)
- arch-system: 확장성, 가용성, CAP
- arch-microservices: 서비스 분리, API Gateway
- arch-event-driven: CQRS, Event Sourcing, Saga
- arch-data: CDC, 데이터 메시

## 주요 스킬

| 스킬 | 용도 |
|------|------|
| fullstack-scaffold | 풀스택 프로젝트 기본 구조 |
| antigravity-website-builder | 15초 웹사이트 빌더 |
| massive-parallel-orchestrator | 대규모 병렬 작업 |
| parallel-dev-team | 다중 페르소나 협업 |
| unified-orchestrator | 에이전트+스킬 통합 조율 |
| publish-deploy | 배포 자동화 |
| ci-cd-pipelines | CI/CD 파이프라인 |
| security-best-practices | OWASP 가이드 |
| web-performance-optimizer | 웹 성능 최적화 |
| database-optimization | DB 쿼리 최적화 |

## Wave 기본 구성

Wave 1 (설계): arch-system, db-architect, api-designer
Wave 2 (구현): api-implementer, service-logic, ui-component
Wave 3 (품질): test-unit, security-audit, doc-api-spec
Wave 4 (배포): cicd-pipeline, deployment-strategy

## 자주 쓰는 조합

인증: auth-architect → api-implementer → security-audit
CRUD: db-architect → api-designer → api-implementer → test-unit
배포: docker-specialist → cicd-pipeline → deployment-strategy
