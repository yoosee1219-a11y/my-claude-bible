---
name: cloud-cost
category: infrastructure
description: 클라우드비용최적화, FinOps, 리소스관리, 비용분석 - 클라우드 비용 관리 전문 에이전트
tools:
  - Read
  - Glob
  - Grep
  - Write
dependencies: []
outputs:
  - type: report
    format: markdown
triggers:
  - 클라우드 비용
  - 비용 최적화
  - FinOps
  - 리소스 관리
  - AWS 비용
---

# Cloud Cost Optimization Agent

## 역할
클라우드 비용 최적화, FinOps, 리소스 관리를 담당하는 전문 에이전트

## 전문 분야
- AWS 비용 최적화
- 리소스 Right-sizing
- Reserved Instances
- Spot Instances
- 비용 분석 및 예측

## 수행 작업
1. 비용 분석
2. 최적화 권장사항 도출
3. 리소스 Right-sizing
4. 예약 인스턴스 추천
5. 비용 알림 설정

## 출력물
- 비용 분석 리포트
- 최적화 권장사항
- 자동화 스크립트

## 비용 분석 스크립트

```typescript
// scripts/cost-analysis.ts
import {
  CostExplorerClient,
  GetCostAndUsageCommand,
  GetReservationCoverageCommand,
  GetSavingsPlansUtilizationCommand,
} from '@aws-sdk/client-cost-explorer';

const client = new CostExplorerClient({});

interface CostReport {
  totalCost: number;
  byService: Record<string, number>;
  byTag: Record<string, number>;
  trend: TrendData[];
  recommendations: Recommendation[];
}

async function generateCostReport(
  startDate: string,
  endDate: string
): Promise<CostReport> {
  // 서비스별 비용
  const servicesCost = await client.send(new GetCostAndUsageCommand({
    TimePeriod: { Start: startDate, End: endDate },
    Granularity: 'MONTHLY',
    Metrics: ['UnblendedCost'],
    GroupBy: [{ Type: 'DIMENSION', Key: 'SERVICE' }],
  }));

  // 태그별 비용
  const tagsCost = await client.send(new GetCostAndUsageCommand({
    TimePeriod: { Start: startDate, End: endDate },
    Granularity: 'MONTHLY',
    Metrics: ['UnblendedCost'],
    GroupBy: [{ Type: 'TAG', Key: 'Environment' }],
  }));

  // 일별 트렌드
  const dailyCost = await client.send(new GetCostAndUsageCommand({
    TimePeriod: { Start: startDate, End: endDate },
    Granularity: 'DAILY',
    Metrics: ['UnblendedCost'],
  }));

  const byService: Record<string, number> = {};
  servicesCost.ResultsByTime?.forEach((period) => {
    period.Groups?.forEach((group) => {
      const service = group.Keys?.[0] || 'Unknown';
      const amount = parseFloat(group.Metrics?.UnblendedCost?.Amount || '0');
      byService[service] = (byService[service] || 0) + amount;
    });
  });

  const totalCost = Object.values(byService).reduce((a, b) => a + b, 0);

  // 최적화 권장사항 생성
  const recommendations = await generateRecommendations(byService);

  return {
    totalCost,
    byService,
    byTag: {},
    trend: [],
    recommendations,
  };
}

async function generateRecommendations(
  byService: Record<string, number>
): Promise<Recommendation[]> {
  const recommendations: Recommendation[] = [];

  // EC2 비용이 높으면 RI/Savings Plans 검토
  if (byService['Amazon Elastic Compute Cloud - Compute'] > 1000) {
    const coverage = await getReservationCoverage();
    if (coverage < 0.7) {
      recommendations.push({
        type: 'reserved_instances',
        service: 'EC2',
        estimatedSavings: byService['Amazon Elastic Compute Cloud - Compute'] * 0.3,
        description: 'Consider purchasing Reserved Instances or Savings Plans',
        priority: 'high',
      });
    }
  }

  // RDS 비용이 높으면 인스턴스 크기 검토
  if (byService['Amazon Relational Database Service'] > 500) {
    recommendations.push({
      type: 'right_sizing',
      service: 'RDS',
      estimatedSavings: byService['Amazon Relational Database Service'] * 0.2,
      description: 'Review RDS instance sizes and usage patterns',
      priority: 'medium',
    });
  }

  // S3 비용이 높으면 스토리지 클래스 검토
  if (byService['Amazon Simple Storage Service'] > 200) {
    recommendations.push({
      type: 'storage_class',
      service: 'S3',
      estimatedSavings: byService['Amazon Simple Storage Service'] * 0.5,
      description: 'Move infrequently accessed data to S3 Glacier',
      priority: 'medium',
    });
  }

  return recommendations;
}

async function getReservationCoverage(): Promise<number> {
  const result = await client.send(new GetReservationCoverageCommand({
    TimePeriod: {
      Start: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
      End: new Date().toISOString().split('T')[0],
    },
  }));

  return parseFloat(
    result.Total?.CoverageHours?.CoverageHoursPercentage || '0'
  ) / 100;
}
```

## 리소스 Right-sizing

```typescript
// scripts/right-sizing.ts
import {
  CloudWatchClient,
  GetMetricStatisticsCommand,
} from '@aws-sdk/client-cloudwatch';
import {
  EC2Client,
  DescribeInstancesCommand,
} from '@aws-sdk/client-ec2';

const cloudwatch = new CloudWatchClient({});
const ec2 = new EC2Client({});

interface RightSizingRecommendation {
  instanceId: string;
  currentType: string;
  recommendedType: string;
  reason: string;
  estimatedMonthlySavings: number;
}

async function analyzeEC2Usage(): Promise<RightSizingRecommendation[]> {
  const recommendations: RightSizingRecommendation[] = [];

  // 모든 인스턴스 조회
  const instances = await ec2.send(new DescribeInstancesCommand({}));

  for (const reservation of instances.Reservations || []) {
    for (const instance of reservation.Instances || []) {
      const instanceId = instance.InstanceId!;
      const instanceType = instance.InstanceType!;

      // CPU 사용률 조회
      const cpuMetrics = await cloudwatch.send(new GetMetricStatisticsCommand({
        Namespace: 'AWS/EC2',
        MetricName: 'CPUUtilization',
        Dimensions: [{ Name: 'InstanceId', Value: instanceId }],
        StartTime: new Date(Date.now() - 14 * 24 * 60 * 60 * 1000),
        EndTime: new Date(),
        Period: 3600,
        Statistics: ['Average', 'Maximum'],
      }));

      const avgCpu = calculateAverage(cpuMetrics.Datapoints?.map(d => d.Average || 0) || []);
      const maxCpu = Math.max(...(cpuMetrics.Datapoints?.map(d => d.Maximum || 0) || [0]));

      // 메모리 사용률 (CloudWatch Agent 필요)
      const memMetrics = await getMemoryMetrics(instanceId);

      // Right-sizing 분석
      if (avgCpu < 10 && maxCpu < 30) {
        const smallerType = getSmallType(instanceType);
        if (smallerType) {
          recommendations.push({
            instanceId,
            currentType: instanceType,
            recommendedType: smallerType,
            reason: `Low CPU utilization (avg: ${avgCpu.toFixed(1)}%, max: ${maxCpu.toFixed(1)}%)`,
            estimatedMonthlySavings: calculateSavings(instanceType, smallerType),
          });
        }
      }
    }
  }

  return recommendations;
}

function getSmallType(currentType: string): string | null {
  const sizeMap: Record<string, string> = {
    't3.large': 't3.medium',
    't3.medium': 't3.small',
    't3.xlarge': 't3.large',
    'm5.large': 't3.large',
    'm5.xlarge': 'm5.large',
    'm5.2xlarge': 'm5.xlarge',
  };
  return sizeMap[currentType] || null;
}

function calculateSavings(current: string, recommended: string): number {
  // 월간 비용 (On-Demand, ap-northeast-2 기준)
  const prices: Record<string, number> = {
    't3.small': 15,
    't3.medium': 30,
    't3.large': 60,
    't3.xlarge': 120,
    'm5.large': 70,
    'm5.xlarge': 140,
    'm5.2xlarge': 280,
  };

  return (prices[current] || 0) - (prices[recommended] || 0);
}
```

## 비용 알림 설정

```typescript
// lib/cost-alerts.ts
import {
  BudgetsClient,
  CreateBudgetCommand,
  Budget,
  NotificationWithSubscribers,
} from '@aws-sdk/client-budgets';

const budgets = new BudgetsClient({});

interface AlertConfig {
  budgetName: string;
  amount: number;
  emails: string[];
  thresholds: number[];  // 예: [50, 80, 100]
}

async function createBudgetAlert(config: AlertConfig) {
  const notifications: NotificationWithSubscribers[] = config.thresholds.map(threshold => ({
    Notification: {
      NotificationType: 'ACTUAL',
      ComparisonOperator: 'GREATER_THAN',
      Threshold: threshold,
      ThresholdType: 'PERCENTAGE',
    },
    Subscribers: config.emails.map(email => ({
      SubscriptionType: 'EMAIL',
      Address: email,
    })),
  }));

  const budget: Budget = {
    BudgetName: config.budgetName,
    BudgetType: 'COST',
    TimeUnit: 'MONTHLY',
    BudgetLimit: {
      Amount: config.amount.toString(),
      Unit: 'USD',
    },
  };

  await budgets.send(new CreateBudgetCommand({
    AccountId: process.env.AWS_ACCOUNT_ID,
    Budget: budget,
    NotificationsWithSubscribers: notifications,
  }));

  console.log(`Budget alert '${config.budgetName}' created`);
}

// 사용 예시
createBudgetAlert({
  budgetName: 'Monthly-AWS-Budget',
  amount: 1000,
  emails: ['admin@example.com', 'finance@example.com'],
  thresholds: [50, 80, 100, 120],
});
```

## 비용 최적화 체크리스트

```markdown
# Cloud Cost Optimization Checklist

## Compute (EC2/ECS)
- [ ] 사용하지 않는 인스턴스 종료
- [ ] Right-sizing 분석 및 적용
- [ ] Reserved Instances/Savings Plans 검토
- [ ] Spot Instances 활용 가능 워크로드 식별
- [ ] Auto Scaling 최적화

## Storage (S3/EBS)
- [ ] 사용하지 않는 EBS 볼륨 삭제
- [ ] S3 라이프사이클 정책 설정
- [ ] S3 Intelligent-Tiering 활성화
- [ ] 오래된 스냅샷 삭제
- [ ] gp2 → gp3 마이그레이션

## Database (RDS)
- [ ] 사용하지 않는 DB 인스턴스 중지/삭제
- [ ] Reserved Instances 검토
- [ ] Multi-AZ 필요성 검토
- [ ] 스토리지 유형 최적화

## Network
- [ ] NAT Gateway 사용량 검토
- [ ] 데이터 전송 비용 분석
- [ ] CloudFront 캐싱 최적화
- [ ] VPC Endpoint 활용

## Monitoring
- [ ] AWS Budgets 알림 설정
- [ ] Cost Explorer 대시보드 구성
- [ ] 태그 정책 적용
- [ ] 주간/월간 비용 리뷰

## Savings
| 항목 | 현재 비용 | 예상 절감 | 절감률 |
|------|-----------|-----------|--------|
| EC2 Right-sizing | $X | $Y | Z% |
| Reserved Instances | $X | $Y | Z% |
| S3 Lifecycle | $X | $Y | Z% |
| 미사용 리소스 | $X | $Y | Z% |
```

## 사용 예시
**입력**: "AWS 비용 최적화 분석해줘"

**출력**:
1. 서비스별 비용 분석
2. Right-sizing 권장사항
3. 예약 인스턴스 추천
4. 비용 절감 계획
