# Agent & Skill Catalog

my-claude-bible에 포함된 모든 에이전트와 스킬의 인벤토리입니다.

**마지막 업데이트:** 2026-04-09
**총 에이전트:** 218개 (Bible 78 + VoltAgent 140)
**총 스킬:** 113개

---

## Bible Original Agents (78개, 16 카테고리)

자체 구축한 한글 에이전트. 도메인별 전문 지식 + 한글 description.

| 카테고리 | 수 | 주요 에이전트 |
|---------|---|-------------|
| api/ | 5 | api-designer-legacy, api-gateway, api-implementer, api-validator, api-versioning |
| architecture/ | 4 | arch-data, arch-event-driven, arch-microservices, arch-system |
| backend/ | 7 | auth-architect, background-jobs, integration-api, realtime-services, service-caching, service-logic, service-resilience |
| database/ | 6 | db-architect, db-indexing, db-migration, db-nosql, db-query, db-scaling |
| documentation/ | 4 | doc-api-spec, doc-architecture, doc-changelog, doc-technical |
| frontend/ | 6 | hotwire-native, ui-a11y, ui-component, ui-performance, ui-state, ui-styling |
| git-collab/ | 2 | code-review, git-workflow |
| infrastructure/ | 7 | cicd-pipeline, cloud-cost, container-k8s, deployment-strategy, docker-specialist, iac-architect, serverless-architect |
| ml-ai/ | 5 | ml-data, ml-deployment, ml-inference, ml-monitoring, ml-training |
| mobile/ | 3 | mobile-crossplatform, mobile-native, mobile-testing |
| observability/ | 4 | incident-response, logging-architect, metrics-architect, tracing-architect |
| research/ | 4 | research-collector, research-evaluator, research-planner, research-synthesizer |
| search-data/ | 4 | data-pipeline, message-queue, search-engine, vector-search |
| security/ | 6 | security-audit, security-compliance, security-penetration, security-sca, security-secrets, security-threat |
| testing/ | 8 | test-contract, test-e2e, test-integration, test-mutation, test-performance, test-security, test-unit, test-visual |
| standalone | 1 | orchestrator.md |

## VoltAgent Agents (140개, 10 카테고리)

[VoltAgent/awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-codex-subagents) 기반.
Claude Code 네이티브 포맷 (.md + YAML frontmatter). 5라운드 대결로 품질 검증 완료.

### voltagent-languages/ (29개)
언어별 전문가 에이전트. Rails 7/8 버전 인식, YJIT 최적화 등 실전 지식 포함.

| 에이전트 | 언어/프레임워크 |
|---------|--------------|
| angular-architect | Angular |
| cpp-pro | C++ |
| csharp-developer | C# |
| django-developer | Django (Python) |
| dotnet-core-expert | .NET Core |
| dotnet-framework-4.8-expert | .NET Framework 4.8 |
| elixir-expert | Elixir/Phoenix |
| expo-react-native-expert | Expo/React Native |
| fastapi-developer | FastAPI (Python) |
| flutter-expert | Flutter/Dart |
| golang-pro | Go |
| java-architect | Java |
| javascript-pro | JavaScript |
| kotlin-specialist | Kotlin |
| laravel-specialist | Laravel (PHP) |
| nextjs-developer | Next.js |
| php-pro | PHP |
| powershell-5.1-expert | PowerShell 5.1 |
| powershell-7-expert | PowerShell 7 |
| python-pro | Python |
| rails-expert | Ruby on Rails (7.x/8.x 버전 인식) |
| react-specialist | React |
| rust-engineer | Rust |
| spring-boot-engineer | Spring Boot (Java) |
| sql-pro | SQL |
| swift-expert | Swift/iOS |
| symfony-specialist | Symfony (PHP) |
| typescript-pro | TypeScript |
| vue-expert | Vue.js |

### voltagent-core-development/ (11개)
| 에이전트 | 역할 |
|---------|------|
| api-designer | API 설계 (REST/GraphQL/OpenAPI) |
| backend-developer | 백엔드 개발 |
| design-bridge | 디자인-개발 연결 |
| electron-pro | Electron 데스크탑 앱 |
| frontend-developer | 프론트엔드 개발 |
| fullstack-developer | 풀스택 개발 |
| graphql-architect | GraphQL 아키텍처 |
| microservices-architect | 마이크로서비스 |
| mobile-developer | 모바일 개발 |
| ui-designer | UI 디자인 |
| websocket-engineer | WebSocket/실시간 |

### voltagent-infrastructure/ (16개)
| 에이전트 | 역할 |
|---------|------|
| azure-infra-engineer | Azure 인프라 |
| cloud-architect | 클라우드 아키텍처 |
| database-administrator | DB 관리 |
| deployment-engineer | 배포 자동화 |
| devops-engineer | DevOps |
| devops-incident-responder | DevOps 인시던트 |
| docker-expert | Docker |
| incident-responder | 장애 대응 |
| kubernetes-specialist | Kubernetes |
| network-engineer | 네트워크 |
| platform-engineer | 플랫폼 엔지니어링 |
| security-engineer | 보안 엔지니어링 |
| sre-engineer | SRE |
| terraform-engineer | Terraform |
| terragrunt-expert | Terragrunt |
| windows-infra-admin | Windows 인프라 |

### voltagent-quality-security/ (15개)
| 에이전트 | 역할 |
|---------|------|
| accessibility-tester | 접근성 테스트 |
| ad-security-reviewer | AD 보안 |
| ai-writing-auditor | AI 작문 감사 |
| architect-reviewer | 아키텍처 리뷰 |
| chaos-engineer | 카오스 엔지니어링 |
| code-reviewer | 코드 리뷰 |
| compliance-auditor | 컴플라이언스 |
| debugger | 디버깅 |
| error-detective | 에러 탐지 |
| penetration-tester | 침투 테스트 |
| performance-engineer | 성능 엔지니어링 |
| powershell-security-hardening | PowerShell 보안 |
| qa-expert | QA |
| security-auditor | 보안 감사 |
| test-automator | 테스트 자동화 |

### voltagent-data-ai/ (13개)
| 에이전트 | 역할 |
|---------|------|
| ai-engineer | AI 엔지니어링 |
| data-analyst | 데이터 분석 |
| data-engineer | 데이터 엔지니어링 |
| data-scientist | 데이터 과학 |
| database-optimizer | DB 최적화 |
| llm-architect | LLM 아키텍처 |
| machine-learning-engineer | ML 엔지니어 |
| ml-engineer | ML 엔지니어 (실무) |
| mlops-engineer | MLOps |
| nlp-engineer | NLP |
| postgres-pro | PostgreSQL 전문가 |
| prompt-engineer | 프롬프트 엔지니어링 |
| reinforcement-learning-engineer | 강화학습 |

### voltagent-developer-experience/ (14개)
| 에이전트 | 역할 |
|---------|------|
| build-engineer | 빌드 시스템 |
| cli-developer | CLI 개발 |
| dependency-manager | 의존성 관리 |
| documentation-engineer | 문서화 |
| dx-optimizer | 개발자 경험 최적화 |
| git-workflow-manager | Git 워크플로우 |
| legacy-modernizer | 레거시 현대화 |
| mcp-developer | MCP 서버 개발 |
| powershell-module-architect | PowerShell 모듈 |
| powershell-ui-architect | PowerShell UI |
| readme-generator | README 생성 |
| refactoring-specialist | 리팩토링 |
| slack-expert | Slack 통합 |
| tooling-engineer | 도구 엔지니어링 |

### voltagent-specialized-domains/ (12개)
| 에이전트 | 역할 |
|---------|------|
| api-documenter | API 문서화 |
| blockchain-developer | 블록체인 |
| embedded-systems | 임베디드 시스템 |
| fintech-engineer | 핀테크 |
| game-developer | 게임 개발 |
| iot-engineer | IoT |
| m365-admin | Microsoft 365 관리 |
| mobile-app-developer | 모바일 앱 |
| payment-integration | 결제 연동 |
| quant-analyst | 퀀트 분석 |
| risk-manager | 리스크 관리 |
| seo-specialist | SEO |

### voltagent-business-product/ (12개)
| 에이전트 | 역할 |
|---------|------|
| business-analyst | 비즈니스 분석 |
| content-marketer | 콘텐츠 마케팅 |
| customer-success-manager | CS 매니저 |
| legal-advisor | 법률 자문 |
| license-engineer | 라이선스 관리 |
| product-manager | 제품 관리 |
| project-manager | 프로젝트 관리 |
| sales-engineer | 세일즈 엔지니어 |
| scrum-master | 스크럼 마스터 |
| technical-writer | 기술 문서 작성 |
| ux-researcher | UX 리서치 |
| wordpress-master | WordPress |

### voltagent-meta-orchestration/ (10개)
| 에이전트 | 역할 |
|---------|------|
| agent-installer | 에이전트 설치 |
| agent-organizer | 에이전트 정리 |
| context-manager | 컨텍스트 관리 |
| error-coordinator | 에러 조율 |
| it-ops-orchestrator | IT 운영 |
| knowledge-synthesizer | 지식 종합 |
| multi-agent-coordinator | 멀티 에이전트 조율 |
| performance-monitor | 성능 모니터링 |
| task-distributor | 태스크 분배 |
| workflow-orchestrator | 워크플로우 조율 |

### voltagent-research-analysis/ (8개)
| 에이전트 | 역할 |
|---------|------|
| competitive-analyst | 경쟁 분석 |
| data-researcher | 데이터 리서치 |
| market-researcher | 시장 리서치 |
| project-idea-validator | 아이디어 검증 |
| research-analyst | 리서치 분석 |
| scientific-literature-researcher | 학술 문헌 리서치 |
| search-specialist | 검색 전문 |
| trend-analyst | 트렌드 분석 |

---

## Name Collision Resolution Log

| 이름 | Bible 위치 | VoltAgent 위치 | 결정 |
|-----|-----------|---------------|------|
| api-designer | api/api-designer-legacy.md | voltagent-core-development/api-designer.md | VoltAgent 승 (5라운드 대결 Round 3). Bible 레거시로 rename |
| hotwire-native | frontend/hotwire-native.md | (없음) | agents/agents/ 레거시 중복 삭제. Bible 원본 유지 |

---

## Skills (113개)

스킬은 `/skill-name`으로 호출. Bible에만 존재 (VoltAgent는 에이전트만 제공).
전체 스킬 목록은 `skills/` 디렉토리 참조.

주요 스킬:
- **Orchestrator**: intelligent-orchestrator, massive-parallel-orchestrator, parallel-dev-team
- **Development**: fullstack, antigravity-website-builder, hotwire-native-framework
- **Quality**: code-review, qa/tester, debug, security
- **DevOps**: devops/sre, publish, release-manager
- **Research**: notebooklm-research-automation
- **Productivity**: auto-translate, web-scraping-automation, playwright-parallel-test-generator

---

## 사용 가이드

### 에이전트 호출
```
@api-designer "REST API 설계해줘"
@rails-expert "Rails 8 프로젝트 셋업"
@debugger "이 에러 분석해줘"
```

### 스킬 호출
```
/auto "풀스택 프로젝트 만들어줘"
/commit
/review-pr 123
```

### Bible vs VoltAgent 선택 기준
- **Bible**: 한글 description, 기존 워크플로우와 통합된 에이전트
- **VoltAgent**: 영어 원본이나 더 깊은 전문성, 더 넓은 도구 접근 (Write/Edit 포함)
- **언어**: Global CLAUDE.md의 "Always respond in korean"이 모든 에이전트에 자동 적용
