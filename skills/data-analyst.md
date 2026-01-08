---
name: data-analyst
description: 데이터분석, 사용자행동분석, 비즈니스메트릭, DAU, MAU, 전환율, 리텐션, AB테스트, 대시보드, 리포팅, 트렌드분석, 예측분석, 구글애널리틱스, 통계분석을 통해 인사이트를 도출하는 스킬
---

# Data Analyst: Analytics & Insights

데이터 분석 및 인사이트 도출

## 기능:

1. **사용자 행동 분석**
   - 페이지뷰 추적
   - 사용자 플로우 분석
   - 이탈률 분석
   - 전환율 측정
   - 코호트 분석

2. **비즈니스 메트릭**
   - DAU/MAU 추적
   - 리텐션 분석
   - ARPU (사용자당 평균 수익)
   - 성장률 계산
   - Funnel 분석

3. **자동 리포팅**
   - 일일/주간/월간 리포트
   - 핵심 지표 대시보드
   - 트렌드 분석
   - 이상 징후 탐지
   - 예측 분석

4. **A/B 테스팅**
   - 실험 설계
   - 통계적 유의성 검증
   - 결과 해석
   - 권장 사항 제시
   - 롤아웃 전략

## 추적 이벤트:

```typescript
// 자동으로 설정되는 이벤트
trackEvent('page_view', { page: '/blog' });
trackEvent('button_click', { button: 'subscribe' });
trackEvent('form_submit', { form: 'contact' });
trackEvent('purchase', { amount: 10000 });
trackEvent('user_signup', { method: 'email' });
```

## 핵심 지표:

**성장 지표:**
- 신규 사용자
- 활성 사용자
- 사용자 증가율
- 바이럴 계수

**참여 지표:**
- 세션 시간
- 페이지/세션
- 반송률
- 재방문율

**비즈니스 지표:**
- 전환율
- ARPU
- LTV (생애 가치)
- CAC (고객 획득 비용)

## 출력:

- ANALYTICS_DASHBOARD.html
- WEEKLY_REPORT.md
- AB_TEST_RESULTS.md
- INSIGHTS.md
- PREDICTIONS.json

## 통합:

- Google Analytics 4
- Mixpanel
- Amplitude
- Custom Analytics
