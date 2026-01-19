# Quick Reference - 빠른 참조

## 키워드 → 에이전트 매핑

| 원하는 것 | 에이전트 |
|-----------|----------|
| DB 테이블 설계 | db-architect |
| 쿼리 최적화 | db-query, db-indexing |
| API 설계 | api-designer |
| API 구현 | api-implementer |
| 로그인/인증 | auth-architect |
| 비즈니스 로직 | service-logic |
| 실시간/웹소켓 | realtime-services |
| React 컴포넌트 | ui-component |
| 상태관리 | ui-state |
| 단위 테스트 | test-unit |
| E2E 테스트 | test-e2e |
| 보안 점검 | security-audit |
| Docker | docker-specialist |
| K8s | container-k8s |
| CI/CD | cicd-pipeline |
| 시스템 설계 | arch-system |
| 마이크로서비스 | arch-microservices |

## 키워드 → 스킬 매핑

| 원하는 것 | 스킬 |
|-----------|------|
| 프로젝트 뼈대 | fullstack-scaffold |
| 빠른 웹사이트 | antigravity-website-builder |
| 대량 작업 | massive-parallel-orchestrator |
| 통합 조율 | unified-orchestrator |
| 배포 | publish-deploy |
| 보안 가이드 | security-best-practices |
| 웹 성능 | web-performance-optimizer |
| DB 최적화 | database-optimization |

## Wave 패턴

Wave 1: 설계 (arch-*, db-architect, api-designer)
Wave 2: 구현 (api-implementer, service-*, ui-*)
Wave 3: 품질 (test-*, security-*, doc-*)
Wave 4: 배포 (cicd-*, deployment-*, docker-*)

## 자주 쓰는 조합

인증: auth-architect → api-implementer → security-audit
CRUD: db-architect → api-designer → api-implementer → test-unit
배포: docker-specialist → cicd-pipeline → deployment-strategy
성능: db-query → db-indexing → service-caching

## 프롬프트 체크리스트

[ ] 기술 스택 명시
[ ] 제약 조건 명시
[ ] 기대 결과물 명시
[ ] 현재 상황/컨텍스트 제공
[ ] 에러 시 메시지/스택트레이스 포함

## 좋은 프롬프트 예시

Bad: "로그인 만들어줘"

Good: "Next.js 14 + Prisma 환경에서 JWT 기반 사용자 인증 구현해줘.
- 이메일/비밀번호 로그인
- Google OAuth 소셜 로그인  
- Zod로 입력 검증
결과물: API 라우트 + 미들웨어 + 프론트 훅"
