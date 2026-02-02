# Development Agent Ecosystem

**개발의 모든 영역(A-Z)을 커버하는 71개 전문 에이전트 생태계**

> 이 에이전트들은 [my-claude-bible](../README.md)의 **스킬과 함께 작동**합니다.
> 스킬이 지식/패턴을 제공하면, 에이전트가 자율적으로 실행합니다.

---

## 개요

총 **71개 에이전트** + **1개 오케스트레이터** = **72개 파일**

14개 카테고리로 구성된 병렬 실행 가능한 개발 에이전트 시스템입니다.

---

## 스킬-에이전트 시너지

```
              사용자 요청
                  |
         +--------v--------+
         |  오케스트레이터    |  /auto, /unified, orchestrator.md
         +--------+---------+
                  |
       +----------+----------+
       |                     |
+------v-------+   +---------v--------+
|  스킬 참조    |   |   에이전트 실행    |
|  (지식/패턴)  |   |   (자율 실행)     |
|  skills/*.md  |   |   agents/*/*.md  |
+--------------+   +------------------+
```

- **스킬** = 도메인별 베스트 프랙티스, 패턴, 가이드 (지식 기반)
- **에이전트** = 특정 작업을 자율적으로 수행하는 전문가 (실행 엔진)
- **오케스트레이터** = Wave 기반으로 에이전트를 조율하는 중앙 관리자

---

## 에이전트 목록

### 1. DATABASE & DATA (6개)
| Agent | 파일 | 역할 | 연관 스킬 |
|-------|------|------|-----------|
| db-architect | `database/db-architect.md` | 스키마 설계, ERD, 정규화, 데이터 모델링 | `database-admin.md` |
| db-query | `database/db-query.md` | SQL 작성, 쿼리 최적화, 실행 계획 분석 | `database-admin.md`, `database-optimization.md` |
| db-migration | `database/db-migration.md` | 마이그레이션 생성/관리, 버전 관리 | `database-admin.md` |
| db-indexing | `database/db-indexing.md` | 인덱스 생성/최적화, 쿼리 패턴 분석 | `database-optimization.md` |
| db-scaling | `database/db-scaling.md` | 샤딩 전략, 수평/수직 스케일링, 복제 | `database-admin.md` |
| db-nosql | `database/db-nosql.md` | NoSQL/Document/Graph/Time-series DB | `caching-strategies.md` |

### 2. API DEVELOPMENT (5개)
| Agent | 파일 | 역할 | 연관 스킬 |
|-------|------|------|-----------|
| api-designer | `api/api-designer.md` | REST/GraphQL 설계, OpenAPI 스펙 | `graphql-development.md`, `api-docs-automation.md` |
| api-implementer | `api/api-implementer.md` | 엔드포인트 구현, 라우팅 | `graphql-development.md`, `fullstack-scaffold.md` |
| api-validator | `api/api-validator.md` | 입력 검증, 에러 핸들링, 계약 테스트 | `security-best-practices.md` |
| api-gateway | `api/api-gateway.md` | API 게이트웨이, 라우팅, Rate limiting | `microservices-architecture.md` |
| api-versioning | `api/api-versioning.md` | 버전 관리, 하위 호환성, 폐기 전략 | `release-manager.md` |

### 3. FRONTEND & UI (6개)
| Agent | 파일 | 역할 | 연관 스킬 |
|-------|------|------|-----------|
| ui-component | `frontend/ui-component.md` | 컴포넌트 개발, 재사용 패턴 | `design-system.md` |
| ui-state | `frontend/ui-state.md` | 상태관리 (Redux, Zustand, Context) | `design-system.md` |
| ui-a11y | `frontend/ui-a11y.md` | 접근성, WCAG 2.2, 보조기술 | - |
| ui-styling | `frontend/ui-styling.md` | CSS 아키텍처, 반응형, 테마 | `design-system.md` |
| ui-performance | `frontend/ui-performance.md` | 프론트엔드 최적화, 번들 크기, 렌더링 | `web-performance-optimizer.md` |
| hotwire-native | `frontend/hotwire-native.md` | Hotwire Native, Turbo iOS/Android | `hotwire-native-framework/` |

### 4. BACKEND & SERVICES (7개)
| Agent | 파일 | 역할 | 연관 스킬 |
|-------|------|------|-----------|
| service-logic | `backend/service-logic.md` | 비즈니스 로직, 도메인 로직 | `fullstack-scaffold.md` |
| auth-architect | `backend/auth-architect.md` | 인증/인가, JWT, OAuth, SSO | `security-best-practices.md` |
| integration-api | `backend/integration-api.md` | 외부 API 연동, 웹훅 | `ai-integration-expert.md` |
| service-resilience | `backend/service-resilience.md` | 재시도 로직, Circuit breaker, 장애 허용 | `microservices-architecture.md` |
| service-caching | `backend/service-caching.md` | 캐싱 전략, Redis, 캐시 무효화 | `caching-strategies.md` |
| realtime-services | `backend/realtime-services.md` | WebSocket, gRPC, 스트리밍 | `realtime-features.md` |
| background-jobs | `backend/background-jobs.md` | 작업 스케줄링, 큐, Cron | `devops-infra.md` |

### 5. SEARCH & DATA PROCESSING (4개)
| Agent | 파일 | 역할 | 연관 스킬 |
|-------|------|------|-----------|
| search-engine | `search-data/search-engine.md` | Elasticsearch/OpenSearch, 인덱싱, 쿼리 | `data-analyst.md` |
| vector-search | `search-data/vector-search.md` | 벡터 임베딩, RAG, 하이브리드 검색 | `ai-integration-expert.md` |
| message-queue | `search-data/message-queue.md` | Kafka, RabbitMQ, 이벤트 스트리밍 | `microservices-architecture.md` |
| data-pipeline | `search-data/data-pipeline.md` | ETL, 데이터 변환, 배치 처리 | `data-analyst.md` |

### 6. INFRASTRUCTURE & DEVOPS (7개)
| Agent | 파일 | 역할 | 연관 스킬 |
|-------|------|------|-----------|
| iac-architect | `infrastructure/iac-architect.md` | Terraform, Pulumi, CDK, 클라우드 아키텍처 | `infrastructure-as-code.md` |
| container-k8s | `infrastructure/container-k8s.md` | Kubernetes, Helm, 컨테이너 오케스트레이션 | `container-orchestration.md` |
| docker-specialist | `infrastructure/docker-specialist.md` | Dockerfile 최적화, 이미지 빌드 | `container-orchestration.md` |
| serverless-architect | `infrastructure/serverless-architect.md` | Lambda, Edge Functions, 이벤트 드리븐 | `infrastructure-as-code.md` |
| cicd-pipeline | `infrastructure/cicd-pipeline.md` | CI/CD 파이프라인, 빌드 자동화 | `ci-cd-pipelines.md` |
| deployment-strategy | `infrastructure/deployment-strategy.md` | Blue-green, Canary, 롤백 전략 | `publish-deploy.md`, `verify-deployment.md` |
| cloud-cost | `infrastructure/cloud-cost.md` | 클라우드 비용 최적화, 리소스 관리 | `cloud-cost-optimizer.md` |

### 7. TESTING (8개)
| Agent | 파일 | 역할 | 연관 스킬 |
|-------|------|------|-----------|
| test-unit | `testing/test-unit.md` | 단위 테스트, 모킹, 커버리지 | `qa-tester.md` |
| test-integration | `testing/test-integration.md` | 통합 테스트, 서비스 상호작용 | `qa-tester.md` |
| test-e2e | `testing/test-e2e.md` | E2E 테스트, Playwright, Cypress | `playwright-parallel-test-generator.md` |
| test-performance | `testing/test-performance.md` | 부하 테스트, 스트레스 테스트 (JMeter, k6) | `performance-testing.md` |
| test-security | `testing/test-security.md` | SAST, DAST, 보안 테스트 자동화 | `security-audit.md` |
| test-contract | `testing/test-contract.md` | API 계약 테스트, Consumer-driven | `qa-tester.md` |
| test-mutation | `testing/test-mutation.md` | 뮤테이션 테스트, 테스트 품질 평가 | `qa-tester.md` |
| test-visual | `testing/test-visual.md` | 시각적 회귀 테스트, 스크린샷 비교 | `playwright-parallel-test-generator.md` |

### 8. SECURITY (6개)
| Agent | 파일 | 역할 | 연관 스킬 |
|-------|------|------|-----------|
| security-audit | `security/security-audit.md` | 취약점 평가, 코드 리뷰 | `security-audit.md` |
| security-threat | `security/security-threat.md` | 위협 모델링, 공격 벡터 분석 | `security-expert.md` |
| security-secrets | `security/security-secrets.md` | 시크릿 관리, 자격증명 로테이션 | `security-best-practices.md` |
| security-compliance | `security/security-compliance.md` | GDPR, SOC2, HIPAA, 규정 준수 | `security-best-practices.md` |
| security-sca | `security/security-sca.md` | 의존성 스캔, 라이선스 컴플라이언스 | `dependency-analyzer.md` |
| security-penetration | `security/security-penetration.md` | 침투 테스트, 취약점 익스플로잇 | `security-expert.md` |

### 9. ML/AI (5개)
| Agent | 파일 | 역할 | 연관 스킬 |
|-------|------|------|-----------|
| ml-training | `ml-ai/ml-training.md` | 모델 훈련, 하이퍼파라미터 튜닝 | `ai-integration-expert.md` |
| ml-inference | `ml-ai/ml-inference.md` | 모델 서빙, 추론 최적화 | `ai-integration-expert.md` |
| ml-deployment | `ml-ai/ml-deployment.md` | MLOps 파이프라인, 모델 버저닝 | `ai-integration-expert.md` |
| ml-monitoring | `ml-ai/ml-monitoring.md` | 모델 성능 모니터링, 드리프트 감지 | `production-monitoring.md` |
| ml-data | `ml-ai/ml-data.md` | 피처 엔지니어링, 데이터 품질 | `data-analyst.md` |

### 10. MOBILE (3개)
| Agent | 파일 | 역할 | 연관 스킬 |
|-------|------|------|-----------|
| mobile-crossplatform | `mobile/mobile-crossplatform.md` | Flutter, React Native, KMP | `mobile-app-development.md` |
| mobile-native | `mobile/mobile-native.md` | iOS/Android 네이티브, 플랫폼 최적화 | `mobile-app-development.md` |
| mobile-testing | `mobile/mobile-testing.md` | 모바일 테스트, 디바이스 프로파일링 | `mobile-app-development.md` |

### 11. OBSERVABILITY (4개)
| Agent | 파일 | 역할 | 연관 스킬 |
|-------|------|------|-----------|
| metrics-architect | `observability/metrics-architect.md` | 메트릭 설계, 대시보드, 알림 | `production-monitoring.md` |
| logging-architect | `observability/logging-architect.md` | 로그 집계, 구조화 로깅 | `logging-analytics.md` |
| tracing-architect | `observability/tracing-architect.md` | 분산 추적, 서비스 의존성 | `production-monitoring.md` |
| incident-response | `observability/incident-response.md` | 인시던트 자동화, 근본 원인 분석 | `production-monitoring.md` |

### 12. DOCUMENTATION (4개)
| Agent | 파일 | 역할 | 연관 스킬 |
|-------|------|------|-----------|
| doc-technical | `documentation/doc-technical.md` | 기술 문서, 사용자 가이드 | `tech-writer.md` |
| doc-api-spec | `documentation/doc-api-spec.md` | OpenAPI/GraphQL 스펙 생성 | `api-docs-automation.md` |
| doc-architecture | `documentation/doc-architecture.md` | ADR, 시스템 설계 문서 | `tech-writer.md` |
| doc-changelog | `documentation/doc-changelog.md` | 변경 로그, 릴리즈 노트 | `release-manager.md` |

### 13. VERSION CONTROL & COLLABORATION (2개)
| Agent | 파일 | 역할 | 연관 스킬 |
|-------|------|------|-----------|
| git-workflow | `git-collab/git-workflow.md` | Git 워크플로우, 브랜치 전략 | `practical-dev-wisdom.md` |
| code-review | `git-collab/code-review.md` | 코드 리뷰, 머지 충돌 해결 | `code-review.md` |

### 14. ARCHITECTURE (4개)
| Agent | 파일 | 역할 | 연관 스킬 |
|-------|------|------|-----------|
| arch-system | `architecture/arch-system.md` | 시스템 설계, 확장성 계획 | `tech-lead.md` |
| arch-microservices | `architecture/arch-microservices.md` | 마이크로서비스 분해, 서비스 경계 | `microservices-architecture.md` |
| arch-event-driven | `architecture/arch-event-driven.md` | 이벤트 드리븐 설계, Saga 패턴 | `microservices-architecture.md` |
| arch-data | `architecture/arch-data.md` | 데이터 아키텍처, 데이터 일관성 | `database-admin.md` |

---

## 주요 시너지 쌍 요약

| 도메인 | 스킬 (지식) | 에이전트 (실행) |
|--------|------------|----------------|
| 비용 최적화 | `cloud-cost-optimizer.md` | `cloud-cost` |
| DB 관리 | `database-admin.md` | `db-architect`, `db-query`, `db-migration`, `db-scaling` |
| 코드 리뷰 | `code-review.md` | `code-review` |
| 보안 | `security-audit.md`, `security-expert.md` | `security-audit`, `security-threat`, `security-penetration` |
| CI/CD | `ci-cd-pipelines.md` | `cicd-pipeline` |
| 컨테이너 | `container-orchestration.md` | `container-k8s`, `docker-specialist` |
| 모니터링 | `production-monitoring.md` | `metrics-architect`, `incident-response` |
| 테스트 | `qa-tester.md`, `performance-testing.md` | `test-unit`, `test-e2e`, `test-performance` |
| 프론트엔드 | `design-system.md`, `web-performance-optimizer.md` | `ui-component`, `ui-styling`, `ui-performance` |
| 실시간 | `realtime-features.md` | `realtime-services` |
| 캐싱 | `caching-strategies.md` | `service-caching` |
| 모바일 | `mobile-app-development.md`, `hotwire-native-framework/` | `mobile-crossplatform`, `hotwire-native` |
| ML/AI | `ai-integration-expert.md` | `ml-training`, `ml-inference`, `ml-deployment` |
| 문서화 | `tech-writer.md`, `api-docs-automation.md` | `doc-technical`, `doc-api-spec` |

---

## 오케스트레이션

### Wave 기반 병렬 실행

```
Wave 1 (설계):      arch-system, db-architect, api-designer, ui-component
         |
         v
Wave 2 (구현):      db-migration, api-implementer, service-logic, ui-state
         |
         v
Wave 3 (품질):      test-unit, test-integration, security-audit, doc-api-spec
         |
         v
Wave 4 (배포):      cicd-pipeline, deployment-strategy
```

### 사용 예시

```
요청: "사용자 프로필 기능 추가해줘"

Orchestrator가 자동으로:
1. 관련 에이전트 식별 (arch-system, db-architect, api-designer, ...)
2. 의존성 분석 및 Wave 계획 수립
3. Wave별 병렬 실행 (최대 5개 동시)
4. 결과 통합 및 다음 Wave로 전달

참조되는 스킬:
- database-admin.md (DB 설계 지식)
- security-best-practices.md (인증 패턴)
- design-system.md (UI 컴포넌트 패턴)
```

---

## 에이전트 메타데이터 형식

각 에이전트는 YAML frontmatter를 사용합니다:

```yaml
---
name: agent-name
category: category-name
description: 한국어키워드, 영어키워드 - 설명
tools:
  - Read
  - Glob
  - Grep
dependencies: [다른 에이전트]
outputs:
  - type: code|config|document
    format: typescript|python|yaml
triggers:
  - 이 에이전트를 호출하는 키워드
---
```

---

## 디렉토리 구조

```
agents/
├── config.json           # 전역 설정 (카테고리, Wave, 병렬 설정)
├── orchestrator.md       # PM/Orchestrator (중앙 조율자)
├── README.md             # 이 문서
|
├── database/             # 6 agents
├── api/                  # 5 agents
├── frontend/             # 6 agents
├── backend/              # 7 agents
├── search-data/          # 4 agents
├── infrastructure/       # 7 agents
├── testing/              # 8 agents
├── security/             # 6 agents
├── ml-ai/                # 5 agents
├── mobile/               # 3 agents
├── observability/        # 4 agents
├── documentation/        # 4 agents
├── git-collab/           # 2 agents
└── architecture/         # 4 agents
```

---

## 설치

```bash
# 에이전트 파일 복사
cp -r agents/* ~/.claude/agents/

# 또는 전체 설치 (스킬 + 에이전트)
./scripts/install.sh      # Mac/Linux
.\scripts\install.ps1     # Windows
```

---

## 통계

| 항목 | 수량 |
|------|------|
| 총 에이전트 | 71 |
| 오케스트레이터 | 1 |
| 총 파일 | 72 |
| 카테고리 | 14 |
| 연관 스킬 | 54 |
| 최대 병렬 실행 | 5 |

---

## 버전

- **v1.1.0** (2026-01-31): 스킬-에이전트 시너지 문서 통합
  - 전체 에이전트에 연관 스킬 매핑 추가
  - development-agent-ecosystem 문서 흡수
- **v1.0.0** (2026-01-16): 초기 릴리즈
  - 71개 전문 에이전트
  - 14개 카테고리
  - Wave 기반 오케스트레이션
