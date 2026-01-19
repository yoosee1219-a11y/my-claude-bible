---
name: debug
description: 디버깅, 에러분석, 버그수정, 테스트실행, 성능분석, 메모리누수, 스택트레이스, 로그분석, 보안스캔, 의존성검사, 커버리지, 프로파일링을 자동으로 수행하는 스킬
---

# Debug: Automatic Debugging Skill

자동 디버깅 및 에러 분석 워크플로우

## 기능:

1. **에러 로그 분석**
   - 콘솔 에러 수집
   - 스택 트레이스 분석
   - 에러 패턴 파악
   - 근본 원인 분석

2. **자동 테스트 실행**
   - 단위 테스트 실행
   - 통합 테스트 실행
   - E2E 테스트 실행
   - 커버리지 리포트 생성

3. **성능 프로파일링**
   - 번들 사이즈 분석
   - 렌더링 성능 체크
   - 메모리 누수 탐지
   - API 응답 시간 측정

4. **의존성 검사**
   - 패키지 버전 충돌 체크
   - 보안 취약점 스캔
   - 사용하지 않는 패키지 탐지
   - 업데이트 필요 패키지 리스트

## 실행 단계:

```bash
# 1. 에러 로그 수집
npm run build 2>&1 | tee build.log

# 2. 테스트 실행
npm test -- --coverage

# 3. 성능 분석
npx webpack-bundle-analyzer

# 4. 보안 스캔
npm audit

# 5. 종합 리포트 생성
```

## 출력:

- DEBUG_REPORT.md (디버깅 리포트)
- TEST_COVERAGE.md (테스트 커버리지)
- PERFORMANCE.md (성능 분석)
- SECURITY.md (보안 이슈)
