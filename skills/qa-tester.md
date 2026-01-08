---
name: qa/tester
description: 테스트자동화, 품질보증, 단위테스트, 통합테스트, E2E테스트, API테스트, 성능테스트, 버그검출, 테스트커버리지, 회귀테스트, 크로스브라우저테스트, QA를 자동화하는 스킬
---

# QA/Tester: Quality Assurance Automation

품질 보증 및 테스트 자동화

## 기능:

1. **자동화 테스트 생성**
   - 단위 테스트 자동 생성
   - 통합 테스트 시나리오
   - E2E 테스트 스크립트
   - API 테스트 (Postman/REST Client)
   - 성능 테스트 (Load Testing)

2. **테스트 실행 & 리포팅**
   - 전체 테스트 스위트 실행
   - 회귀 테스트 자동화
   - 테스트 커버리지 측정
   - 실패한 테스트 분석
   - 상세 리포트 생성

3. **버그 트래킹**
   - 버그 자동 감지
   - 재현 단계 자동 생성
   - 우선순위 자동 분류
   - 이슈 트래커 연동 (GitHub Issues)
   - 버그 수명 주기 관리

4. **크로스 브라우저 테스팅**
   - Chrome, Firefox, Safari, Edge
   - 모바일 브라우저 (iOS, Android)
   - 반응형 디자인 검증
   - 스크린샷 비교

## 테스트 시나리오:

```typescript
// 자동 생성되는 테스트 예시
describe('User Authentication Flow', () => {
  test('회원가입', async () => {
    // 시나리오 자동 생성
  });

  test('로그인', async () => {
    // 시나리오 자동 생성
  });

  test('권한 검증', async () => {
    // 시나리오 자동 생성
  });
});
```

## 품질 메트릭:

- 테스트 커버리지 > 80%
- E2E 성공률 > 95%
- 버그 검출율
- 평균 수정 시간
- 회귀 버그 발생률

## 출력:

- TEST_REPORT.md
- COVERAGE_REPORT.html
- BUG_ANALYSIS.md
- QUALITY_METRICS.json
