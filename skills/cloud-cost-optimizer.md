---
name: cloud-cost-optimizer
description: 클라우드비용최적화, AWS비용절감, Vercel빌링, Supabase가격, FinOps, Reserved인스턴스, Spot인스턴스, 비용모니터링, 예산알림, 태그전략, 우선순위최적화, 자동스케일링, 스토리지최적화, CDN절감, 데이터전송비용, 클라우드재무관리, 비용가시성, 비용예측으로 클라우드 비용을 40-70% 절감하는 완벽 가이드 스킬
---

# Cloud Cost Optimizer (클라우드 비용 최적화 완벽 가이드)

## Overview

**클라우드 비용 40-70% 절감! 스타트업 생존의 핵심!**

클라우드 비용은 예상보다 **10배 이상** 나올 수 있습니다:

### 클라우드 비용 폭탄 사례

```
예상: 월 $100
실제: 월 $1,500 (15배!)

원인:
- 개발 환경을 끄지 않음 ($400)
- 불필요한 데이터베이스 복제 ($300)
- 이미지 최적화 안 함 (Egress $500)
- 로그 무제한 저장 ($200)
- 사용하지 않는 서비스 ($100)
```

**실제 성공 사례**:
- **Inf학원 Tech**: 월 $450 → $38 ($3,960/년 절감)
- **일반적인 스타트업**: 비효율 제거로 **40-70% 비용 절감**

이 스킬은 **AWS, Vercel, Supabase** 중심으로 2026년 최신 비용 최적화 전략을 제공합니다.

---

## 📊 클라우드 비용 구조 이해

### 주요 비용 발생 영역

```
1. Compute (컴퓨팅) - 30-50%
   └─ EC2, Lambda, Vercel Functions

2. Storage (저장소) - 20-30%
   └─ S3, RDS, Supabase Database

3. Data Transfer (데이터 전송) - 15-25%
   └─ Egress, CloudFront CDN

4. Database (데이터베이스) - 10-20%
   └─ RDS, DynamoDB, Supabase

5. Other Services - 5-15%
   └─ SES, SNS, CloudWatch
```

---

## 🎯 우선순위별 최적화 전략

### ⭐⭐⭐ Critical (즉시 적용 - 월 50-70% 절감)

#### 1. 개발/테스트 환경 자동 종료

**문제**: 개발 서버를 24/7 켜놓음 → 월 $400 낭비

**해결책**:
```bash
# AWS Lambda로 업무 시간외 자동 종료
# 월-금 오후 7시 ~ 오전 9시, 주말 전체 종료

import boto3
ec2 = boto3.client('ec2')

def lambda_handler(event, context):
    # 개발 환경 인스턴스 종료
    instances = ec2.describe_instances(
        Filters=[{'Name': 'tag:Environment', 'Values': ['dev', 'test']}]
    )

    instance_ids = [
        i['InstanceId']
        for r in instances['Reservations']
        for i in r['Instances']
    ]

    if instance_ids:
        ec2.stop_instances(InstanceIds=instance_ids)
        print(f'Stopped {len(instance_ids)} instances')
```

**EventBridge Rule**:
```json
{
  "schedules": {
    "stop": "cron(0 19 ? * MON-FRI *)",  // 평일 오후 7시
    "start": "cron(0 9 ? * MON-FRI *)"   // 평일 오전 9시
  }
}
```

**절감 효과**:
- Before: $400/월 (24/7 운영)
- After: $100/월 (주 40시간만 운영)
- **절감: $300/월 = $3,600/년 (75%)**

---

#### 2. 불필요한 데이터베이스 복제본 제거

**문제**: 프로덕션과 동일한 스펙으로 Dev/Staging DB 생성

**해결책**:
```
Production DB:
- db.t3.large (2 vCPU, 8GB RAM) - $150/월
- Multi-AZ 활성화 - $150/월
→ Total: $300/월

Development DB:
- db.t3.micro (1 vCPU, 1GB RAM) - $15/월  ✅
- Single-AZ - $0
→ Total: $15/월

Staging DB:
- db.t3.small (1 vCPU, 2GB RAM) - $40/월  ✅
- Single-AZ - $0
→ Total: $40/월
```

**절감 효과**: $600 → $355 = **$245/월 절감 (41%)**

---

#### 3. Supabase Spend Cap 활성화

**문제**: 비효율적인 쿼리로 CPU 과부하 → 자동 스케일업 → 비용 폭증

**해결책**:
```typescript
// 1. Spend Cap 활성화 (Supabase Dashboard)
Settings → Billing → Spend Cap: ON
Monthly Limit: $25

// 2. 비효율적인 쿼리 찾기
SELECT
  query,
  calls,
  total_time,
  mean_time
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;

// 3. 인덱스 추가
CREATE INDEX idx_user_email ON users(email);
CREATE INDEX idx_posts_created ON posts(created_at DESC);
```

**실제 사례** (Inf학원):
```
Before:
- 비효율 쿼리 3개가 CPU 80% 차지
- 월 $450 지출

After:
- 인덱스 3개 추가
- 월 $38 지출

절감: $412/월 = $4,944/년 (91%!)
```

---

### ⭐⭐ High Priority (이번 주 - 월 20-30% 절감)

#### 4. Reserved Instances / Savings Plans

**개념**:
- 1년 또는 3년 약정 → 할인
- 예측 가능한 워크로드에 적합

**비교**:
```
On-Demand (필요시 구매):
- t3.large: $0.0832/시간
- 월 비용: $60.74
- 약정: 없음
- 유연성: ⭐⭐⭐⭐⭐

Reserved Instance (1년 약정):
- t3.large: $0.051/시간 (39% 할인)
- 월 비용: $37.23
- 약정: 1년
- 유연성: ⭐⭐

Reserved Instance (3년 약정):
- t3.large: $0.033/시간 (60% 할인)
- 월 비용: $24.09
- 약정: 3년
- 유연성: ⭐
```

**전략**:
```
베이스라인 워크로드 (항상 켜져있음):
→ Reserved Instance (3년, 60% 할인)

예측 가능한 워크로드:
→ Reserved Instance (1년, 39% 할인)

가변 워크로드:
→ On-Demand 또는 Spot
```

**절감 효과**:
- 10대 서버 * $37 절감 = **$370/월 = $4,440/년**

---

#### 5. Spot Instances (최대 90% 할인!)

**개념**:
- AWS의 잉여 용량 사용
- 언제든 종료 가능 (2분 경고)
- **비용: On-Demand 대비 최대 90% 할인**

**적합한 워크로드**:
```
✅ Good:
- CI/CD 빌드 (재시작 가능)
- 데이터 처리 배치 작업
- 웹 크롤링
- 테스트 환경
- 머신러닝 학습

❌ Bad:
- 프로덕션 웹 서버 (다운타임 발생)
- 실시간 트랜잭션 DB
- 상태 유지 필요한 서비스
```

**실전 구성**:
```yaml
# GitHub Actions with Spot Instances
jobs:
  build:
    runs-on: ubuntu-latest-spot  # Spot 사용
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v3
      - run: npm run build
      - uses: actions/upload-artifact@v3
        with:
          name: build
          path: dist/
        # 중단되어도 아티팩트 업로드
```

**비용 비교**:
```
CI/CD 빌드 (월 1000회, 각 10분):
- On-Demand: $150/월
- Spot: $15/월
→ 절감: $135/월 (90%)
```

---

#### 6. 이미지 최적화 (Egress 비용 절감)

**문제**: 최적화 안 된 이미지 = 데이터 전송 비용 폭증

**해결책**:
```typescript
// Supabase Storage - Image Transformation
const { data } = supabase
  .storage
  .from('images')
  .getPublicUrl('hero.jpg', {
    transform: {
      width: 800,
      height: 600,
      format: 'avif',  // 80% 용량 감소!
      quality: 85,
    }
  });

// 또는 Vercel Image Optimization
<Image
  src="/hero.jpg"
  width={800}
  height={600}
  quality={85}
  formats={['avif', 'webp']}
/>
```

**비용 계산**:
```
원본 이미지:
- 100개 이미지 × 2MB = 200MB
- 월 10,000 방문자
- 전송: 2TB/월
- Egress 비용: $180/월

최적화 후 (AVIF):
- 100개 이미지 × 400KB = 40MB
- 월 10,000 방문자
- 전송: 400GB/월
- Egress 비용: $36/월

절감: $144/월 = $1,728/년 (80%)
```

---

#### 7. CDN 캐싱 최대화

**개념**: Origin 요청 줄이기 = 비용 절감

**설정**:
```typescript
// Next.js - Static Assets 장기 캐싱
// next.config.js
module.exports = {
  async headers() {
    return [
      {
        source: '/static/:path*',
        headers: [
          {
            key: 'Cache-Control',
            value: 'public, max-age=31536000, immutable',  // 1년
          },
        ],
      },
      {
        source: '/images/:path*',
        headers: [
          {
            key: 'Cache-Control',
            value: 'public, max-age=2592000',  // 30일
          },
        ],
      },
    ];
  },
};
```

**Vercel CDN 통계 확인**:
```
Analytics → Bandwidth

Cache Hit Rate:
- Before: 40% (Origin 요청 많음)
- After: 95% (Origin 요청 최소화)

Bandwidth 비용:
- Before: $200/월
- After: $40/월
→ 절감: $160/월 (80%)
```

---

### ⭐ Medium Priority (이번 달 - 월 10-20% 절감)

#### 8. 자동 스케일링 (Auto Scaling)

**개념**: 트래픽에 따라 자동 증감

**설정**:
```json
// AWS Auto Scaling Group
{
  "MinSize": 2,           // 최소 2대 (항상 가용)
  "MaxSize": 10,          // 최대 10대 (피크 타임)
  "DesiredCapacity": 2,   // 기본 2대
  "ScalingPolicies": [
    {
      "PolicyName": "ScaleUp",
      "AdjustmentType": "ChangeInCapacity",
      "ScalingAdjustment": 2,  // CPU 70% 이상 → +2대
      "Cooldown": 300
    },
    {
      "PolicyName": "ScaleDown",
      "AdjustmentType": "ChangeInCapacity",
      "ScalingAdjustment": -1,  // CPU 30% 이하 → -1대
      "Cooldown": 600
    }
  ]
}
```

**비용 효과**:
```
고정 용량 (10대 24/7):
- 비용: $600/월

Auto Scaling (평균 4대):
- 피크 타임 (4시간/일): 10대
- 일반 시간 (20시간/일): 2대
- 평균: 4대
- 비용: $240/월

절감: $360/월 (60%)
```

---

#### 9. 스토리지 라이프사이클 정책

**개념**: 오래된 데이터 → 저렴한 스토리지로 이동

**S3 Lifecycle Policy**:
```json
{
  "Rules": [
    {
      "Id": "MoveToIA",
      "Status": "Enabled",
      "Transitions": [
        {
          "Days": 30,
          "StorageClass": "STANDARD_IA"  // 30일 후 → IA (50% 저렴)
        },
        {
          "Days": 90,
          "StorageClass": "GLACIER"       // 90일 후 → Glacier (80% 저렴)
        }
      ],
      "Expiration": {
        "Days": 365  // 1년 후 삭제
      }
    }
  ]
}
```

**비용 비교**:
```
1TB 스토리지 (1년):

S3 Standard (전체):
- $23/월 × 12 = $276/년

Lifecycle Policy:
- 0-30일 S3 Standard: $23/월
- 31-90일 S3 IA: $12.50/월 × 2개월
- 91-365일 Glacier: $4/월 × 9개월
→ Total: $84/년

절감: $192/년 (70%)
```

---

#### 10. 로그 보관 기간 최적화

**문제**: CloudWatch Logs 무제한 저장 → 비용 증가

**해결책**:
```bash
# CloudWatch Logs 보관 기간 설정
aws logs put-retention-policy \
  --log-group-name /aws/lambda/my-function \
  --retention-in-days 7  # 7일만 보관

# 오래된 로그는 S3로 이동 (저렴)
aws logs create-export-task \
  --log-group-name /aws/lambda/my-function \
  --destination s3://my-logs-bucket \
  --from $(date -d '7 days ago' +%s)000 \
  --to $(date +%s)000
```

**비용 비교**:
```
CloudWatch Logs (무제한):
- 100GB/월 로그
- $0.50/GB = $50/월

CloudWatch Logs (7일) + S3 Archive:
- CloudWatch: 20GB × $0.50 = $10/월
- S3 Glacier: 80GB × $0.004 = $0.32/월
→ Total: $10.32/월

절감: $39.68/월 (79%)
```

---

## 🔍 비용 모니터링 및 알림

### AWS Cost Explorer + Budgets

#### 1. 예산 설정
```bash
# AWS CLI로 예산 생성
aws budgets create-budget \
  --account-id 123456789012 \
  --budget file://budget.json \
  --notifications-with-subscribers file://notifications.json
```

**budget.json**:
```json
{
  "BudgetName": "Monthly-Budget",
  "BudgetLimit": {
    "Amount": "1000",
    "Unit": "USD"
  },
  "TimeUnit": "MONTHLY",
  "BudgetType": "COST"
}
```

**notifications.json**:
```json
{
  "Notification": {
    "NotificationType": "ACTUAL",
    "ComparisonOperator": "GREATER_THAN",
    "Threshold": 80,  // 80% 도달 시 알림
    "ThresholdType": "PERCENTAGE"
  },
  "Subscribers": [
    {
      "SubscriptionType": "EMAIL",
      "Address": "finance@company.com"
    },
    {
      "SubscriptionType": "SNS",
      "Address": "arn:aws:sns:us-east-1:123456789012:billing-alerts"
    }
  ]
}
```

---

#### 2. 비용 이상 탐지 (Anomaly Detection)

**설정**:
```
AWS Cost Anomaly Detection → Create Monitor

Alert 조건:
- Impact > $100 (영향도 $100 이상)
- Alert 방법: SNS → Slack
```

**Slack 통합**:
```javascript
// Lambda로 SNS → Slack 변환
exports.handler = async (event) => {
  const message = JSON.parse(event.Records[0].Sns.Message);

  await fetch(process.env.SLACK_WEBHOOK_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      text: `🚨 AWS 비용 이상 탐지!`,
      blocks: [
        {
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: `*서비스:* ${message.service}\n*비용:* $${message.amount}\n*증가율:* ${message.percentage}%`
          }
        }
      ]
    })
  });
};
```

---

### Supabase 비용 모니터링

```typescript
// Supabase Dashboard → Usage

주요 지표:
1. Database Size (GB)
2. Egress (GB)
3. Storage (GB)
4. Realtime Connections

// API로 사용량 확인
const { data } = await supabase
  .from('_supabase_usage')
  .select('*')
  .order('timestamp', { ascending: false })
  .limit(1);

console.log('Current usage:', data);

// Spend Cap 확인
if (data.projected_cost > 20) {
  alert('예산 초과 위험!');
}
```

---

### Vercel 비용 모니터링

```bash
# Vercel Usage API
curl -H "Authorization: Bearer $VERCEL_TOKEN" \
  https://api.vercel.com/v1/teams/{teamId}/usage

# 주요 지표:
- Build Minutes
- Bandwidth (GB)
- Serverless Function Invocations
- Edge Middleware Invocations
```

**최적화 팁**:
```javascript
// 1. Build Minutes 절감 - Incremental Build
// vercel.json
{
  "buildCommand": "next build",
  "framework": "nextjs",
  "installCommand": "npm ci --prefer-offline"
}

// 2. Bandwidth 절감 - Edge Caching
export const config = {
  runtime: 'edge',
};

export default function handler(req) {
  return new Response('Hello', {
    headers: {
      'Cache-Control': 'public, max-age=31536000, immutable'
    }
  });
}

// 3. Function Execution 절감 - Edge Functions 사용
// /api/hello.ts → /api/hello.tsx (Edge Runtime)
export const config = { runtime: 'edge' };
```

---

## 📋 태그 전략 (Cost Allocation)

### 태그 체계 설계

```
필수 태그:
- Environment: production | staging | development
- Team: frontend | backend | devops | data
- Project: website | mobile-app | api
- Owner: john@company.com
- CostCenter: engineering | marketing | sales

선택 태그:
- Service: web-server | database | cache
- Customer: client-a | client-b (Multi-tenant)
```

### AWS 태그 적용

```bash
# EC2 인스턴스 태그
aws ec2 create-tags \
  --resources i-1234567890abcdef0 \
  --tags \
    Key=Environment,Value=production \
    Key=Team,Value=backend \
    Key=Project,Value=api \
    Key=Owner,Value=john@company.com

# S3 버킷 태그
aws s3api put-bucket-tagging \
  --bucket my-bucket \
  --tagging 'TagSet=[{Key=Environment,Value=production},{Key=Team,Value=frontend}]'

# Cost Allocation 태그 활성화
aws ce update-cost-allocation-tags-status \
  --cost-allocation-tags-status \
    TagKey=Environment,Status=Active \
    TagKey=Team,Status=Active \
    TagKey=Project,Status=Active
```

### 태그 기반 비용 분석

```bash
# Team별 비용 확인
aws ce get-cost-and-usage \
  --time-period Start=2026-01-01,End=2026-01-31 \
  --granularity MONTHLY \
  --metrics UnblendedCost \
  --group-by Type=TAG,Key=Team

# 결과:
{
  "frontend": "$450",
  "backend": "$680",
  "devops": "$120",
  "data": "$250"
}
```

---

## 💡 실전 최적화 사례

### Case 1: 스타트업 (Before → After)

**Before**:
```
총 비용: $2,500/월

상세:
- EC2 (24/7, 10대): $600
- RDS (Production + 동일 Dev/Staging): $600
- S3 (이미지 원본): $400
- CloudFront (캐싱 없음): $300
- CloudWatch (로그 무제한): $200
- 기타 (SNS, SES 등): $400
```

**적용한 최적화**:
1. ✅ 개발 환경 자동 종료 (업무 시간만)
2. ✅ Dev/Staging DB 다운사이징
3. ✅ Reserved Instances (프로덕션)
4. ✅ Spot Instances (CI/CD)
5. ✅ 이미지 최적화 (AVIF)
6. ✅ CDN 캐싱 강화
7. ✅ 로그 7일 보관 → S3 이동
8. ✅ S3 Lifecycle Policy

**After**:
```
총 비용: $750/월 (70% 절감!)

상세:
- EC2 (Auto Scaling, Reserved): $200
- RDS (다운사이징 + Reserved): $180
- S3 (Lifecycle Policy): $80
- CloudFront (95% Cache Hit): $60
- CloudWatch (7일 보관): $30
- 기타: $200

연간 절감: ($2,500 - $750) × 12 = $21,000
```

**ROI**: 설정 시간 3일 → 연간 $21,000 절감 = **7,000배 수익!**

---

### Case 2: Supabase 최적화 (Inf학원 Tech)

**Before**:
```
월 비용: $450

문제:
- 3개의 비효율적인 쿼리가 CPU 80% 차지
- 인덱스 누락
- 불필요한 Full Table Scan
```

**최적화**:
```sql
-- 1. 느린 쿼리 찾기
SELECT
  query,
  calls,
  total_time,
  mean_time,
  (total_time / sum(total_time) OVER ()) * 100 AS pct_total
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;

-- 2. 인덱스 추가
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_posts_user_created ON posts(user_id, created_at DESC);
CREATE INDEX idx_comments_post ON comments(post_id);

-- 3. 쿼리 최적화
-- Before: Full Table Scan
SELECT * FROM posts WHERE user_id = 123 ORDER BY created_at DESC;

-- After: Index Scan
SELECT * FROM posts
WHERE user_id = 123
ORDER BY created_at DESC
LIMIT 20;  -- Pagination 추가
```

**After**:
```
월 비용: $38 (91% 절감!)

CPU 사용률: 80% → 15%
쿼리 응답 시간: 2.5s → 0.05s (50배 빠름)

연간 절감: ($450 - $38) × 12 = $4,944
```

---

### Case 3: Vercel 최적화

**Before**:
```
월 비용: $350

상세:
- Build Minutes: 2,000분 ($100)
- Bandwidth: 500GB ($150)
- Function Executions: 10M ($100)
```

**최적화**:
```typescript
// 1. Incremental Build (빌드 시간 50% 단축)
// next.config.js
module.exports = {
  experimental: {
    incrementalCacheHandlerPath: require.resolve('./cache-handler.js')
  }
};

// 2. Edge Functions (비용 1/10)
// Before: Node.js Runtime
export default async function handler(req, res) {
  const data = await fetch('https://api.example.com/data');
  res.json(data);
}

// After: Edge Runtime
export const config = { runtime: 'edge' };

export default async function handler(req) {
  const data = await fetch('https://api.example.com/data');
  return Response.json(data);
}

// 3. ISR로 빌드 빈도 감소
export const revalidate = 3600; // 1시간마다 재생성
```

**After**:
```
월 비용: $120 (66% 절감!)

상세:
- Build Minutes: 1,000분 ($50)
- Bandwidth: 250GB ($50)
- Function Executions: 2M ($20)

연간 절감: ($350 - $120) × 12 = $2,760
```

---

## 🎯 체크리스트 (우선순위별)

### ⭐⭐⭐ Critical (즉시 적용 - 50-70% 절감)

- [ ] 개발/테스트 환경 자동 종료 설정
- [ ] 불필요한 DB 복제본 제거/다운사이징
- [ ] Supabase Spend Cap 활성화
- [ ] 비효율적인 쿼리 찾기 & 인덱스 추가
- [ ] 이미지 최적화 (AVIF/WebP)
- [ ] CDN 캐싱 설정 확인

### ⭐⭐ High Priority (이번 주 - 20-30% 절감)

- [ ] Reserved Instances/Savings Plans 구매
- [ ] Spot Instances 도입 (CI/CD, 배치)
- [ ] AWS Budgets 설정
- [ ] Cost Anomaly Detection 활성화
- [ ] 로그 보관 기간 최적화
- [ ] 태그 전략 수립 및 적용

### ⭐ Medium Priority (이번 달 - 10-20% 절감)

- [ ] Auto Scaling 설정
- [ ] S3 Lifecycle Policy 적용
- [ ] 사용하지 않는 리소스 정리
- [ ] Multi-region 데이터 전송 최소화
- [ ] CloudWatch 대시보드 구축
- [ ] 월간 비용 리뷰 프로세스 수립

---

## 🛠️ 도구 및 리소스

### AWS 비용 관리 도구

```
공식 도구:
- AWS Cost Explorer (비용 분석)
- AWS Budgets (예산 관리)
- AWS Cost Anomaly Detection (이상 탐지)
- AWS Trusted Advisor (권장 사항)
- AWS Compute Optimizer (인스턴스 최적화)

서드파티 도구:
- CloudHealth (멀티 클라우드 관리)
- Datadog (통합 모니터링)
- Spot.io (Spot Instance 자동화)
- ProsperOps (자동 RI/SP 구매)
```

### Supabase 모니터링

```
Dashboard 메뉴:
- Usage (사용량 확인)
- Database (쿼리 성능)
- API (API 호출 통계)
- Storage (저장소 사용량)

SQL 쿼리:
- pg_stat_statements (느린 쿼리)
- pg_stat_user_tables (테이블 통계)
- pg_indexes (인덱스 사용률)
```

### Vercel Analytics

```
Dashboard 메뉴:
- Usage (사용량 확인)
- Analytics (트래픽 분석)
- Speed Insights (성능 측정)

API:
- GET /v1/teams/{teamId}/usage
- GET /v1/teams/{teamId}/bandwidth
```

---

## 📚 참고 자료

### AWS 공식 문서
- [비용 최적화 전략 (AWS 공식)](https://docs.aws.amazon.com/ko_kr/cost-management/latest/userguide/coh-optimization-strategies.html)
- [AWS 비용을 줄일 수 있는 10가지 기법](https://aws.amazon.com/ko/blogs/korea/10-things-you-can-do-today-to-reduce-aws-costs/)
- [AWS Cost Management](https://aws.amazon.com/aws-cost-management/)

### 한글 실전 가이드
- [스타트업 엔지니어의 AWS 비용 최적화 경험기](https://tech.inflab.com/20240227-finops-for-startup/)
- [AWS 비용 최적화 방법 (교보DTS)](https://blog.kyobodts.co.kr/2024/03/22/aws-비용-최적화-방법/)
- [AWS EC2 인스턴스 비용 절감 가이드](https://iting.co.kr/tech-blog-aws-ec2-cost-optimization-2025-0424/)

### Supabase 공식 문서
- [Control your costs](https://supabase.com/docs/guides/platform/cost-control)
- [FinOps for Supabase (Medium)](https://medium.com/@maximedalessandro/finops-for-supabase-a-guide-to-cutting-your-cloud-costs-817ef13b852c)
- [Supabase Pricing Guide (FlexPrice)](https://flexprice.io/blog/supabase-pricing-breakdown)

### Reserved vs Spot Instances
- [Spot vs Reserved Instances Guide](https://www.nops.io/blog/spot-instances-vs-reserved-instances/)
- [AWS Pricing Comparison](https://www.pump.co/blog/aws-spot-vs-reserved-instances)

---

## 🎓 빠른 시작 명령어

```bash
# 이 스킬 사용
/cloud-cost-optimizer "AWS 비용 최적화해줘"

# 특정 영역
/cloud-cost-optimizer "개발 환경 자동 종료 설정"
/cloud-cost-optimizer "Supabase 쿼리 최적화"
/cloud-cost-optimizer "이미지 Egress 비용 줄이기"

# 분석
/cloud-cost-optimizer "현재 비용 분석 및 절감 방안"
/cloud-cost-optimizer "Reserved vs Spot 선택 도와줘"
```

---

## 💰 예상 ROI

**투자**:
- 초기 설정 시간: 2-3일
- 월간 모니터링: 2-3시간

**수익**:
- 즉시 절감: 40-70% (Critical 항목)
- 장기 절감: 누적 효과
- 예산 초과 방지: 리스크 감소

**사례 기반 ROI**:
```
월 $2,000 지출 스타트업:
- 70% 절감 = $1,400/월 = $16,800/년
- 투자 대비: 5,600배 수익!

월 $10,000 지출 기업:
- 40% 절감 = $4,000/월 = $48,000/년
- 투자 대비: 16,000배 수익!
```

---

**이 스킬은 2026년 최신 AWS/Vercel/Supabase 가격 정책을 반영했으며, 실전 검증된 비용 절감 전략만 포함합니다!** 💰

**핵심**: 클라우드 비용은 **관리하지 않으면 폭증**하고, **관리하면 40-70% 절감** 가능합니다!
