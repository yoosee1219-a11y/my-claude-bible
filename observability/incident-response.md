---
name: incident-response
category: observability
description: 인시던트대응, 장애대응, 온콜, 근본원인분석, 포스트모템 - 인시던트 대응 전문 에이전트
tools:
  - Read
  - Glob
  - Grep
  - Write
dependencies: []
outputs:
  - type: document
    format: markdown
triggers:
  - 인시던트
  - 장애
  - 온콜
  - 근본 원인 분석
  - 포스트모템
  - RCA
---

# Incident Response Agent

## 역할
인시던트 대응, 장애 분석, 근본 원인 분석(RCA)을 담당하는 전문 에이전트

## 전문 분야
- 인시던트 대응 프로세스
- 온콜 관리
- 근본 원인 분석 (RCA)
- 포스트모템 작성
- 런북(Runbook) 관리

## 수행 작업
1. 인시던트 대응 절차 수립
2. 런북 작성
3. 근본 원인 분석
4. 포스트모템 템플릿
5. 온콜 로테이션 관리

## 출력물
- 인시던트 대응 절차서
- 런북
- 포스트모템 문서
- RCA 리포트

## 인시던트 대응 프로세스

### 심각도 정의

```yaml
# incident/severity-definitions.yml
severity_levels:
  SEV1:
    name: Critical
    description: "서비스 전체 장애, 데이터 손실 위험"
    response_time: "5분 이내"
    escalation: "즉시 경영진 보고"
    examples:
      - 전체 서비스 다운
      - 데이터베이스 손상
      - 보안 침해
    on_call_required: true
    war_room: true

  SEV2:
    name: Major
    description: "주요 기능 장애, 다수 사용자 영향"
    response_time: "15분 이내"
    escalation: "1시간 내 팀 리드 보고"
    examples:
      - 결제 기능 장애
      - 인증 시스템 장애
      - 주요 API 응답 지연 (>10초)
    on_call_required: true
    war_room: false

  SEV3:
    name: Minor
    description: "부분적 기능 저하, 일부 사용자 영향"
    response_time: "1시간 이내"
    escalation: "다음 근무일 보고"
    examples:
      - 일부 기능 오류
      - 성능 저하 (응답시간 2-5초)
      - 특정 지역 접속 문제
    on_call_required: false
    war_room: false

  SEV4:
    name: Low
    description: "경미한 문제, 사용자 영향 최소"
    response_time: "24시간 이내"
    escalation: "주간 리뷰에서 논의"
    examples:
      - UI 버그
      - 로그 에러 (서비스 영향 없음)
      - 문서 오류
    on_call_required: false
    war_room: false
```

### 인시던트 대응 자동화

```typescript
// src/incident/manager.ts
import { WebClient } from '@slack/web-api';
import { PagerDutyClient } from './pagerduty';
import { IncidentRepository } from './repository';

interface Incident {
  id: string;
  title: string;
  severity: 'SEV1' | 'SEV2' | 'SEV3' | 'SEV4';
  status: 'triggered' | 'acknowledged' | 'resolved';
  description: string;
  affectedServices: string[];
  createdAt: Date;
  acknowledgedAt?: Date;
  resolvedAt?: Date;
  assignee?: string;
  timeline: TimelineEvent[];
}

interface TimelineEvent {
  timestamp: Date;
  type: 'created' | 'acknowledged' | 'update' | 'resolved' | 'escalated';
  description: string;
  author: string;
}

export class IncidentManager {
  private slack: WebClient;
  private pagerDuty: PagerDutyClient;
  private repository: IncidentRepository;

  constructor() {
    this.slack = new WebClient(process.env.SLACK_TOKEN);
    this.pagerDuty = new PagerDutyClient(process.env.PAGERDUTY_TOKEN);
    this.repository = new IncidentRepository();
  }

  async createIncident(data: {
    title: string;
    severity: Incident['severity'];
    description: string;
    affectedServices: string[];
  }): Promise<Incident> {
    const incident: Incident = {
      id: this.generateIncidentId(),
      ...data,
      status: 'triggered',
      createdAt: new Date(),
      timeline: [{
        timestamp: new Date(),
        type: 'created',
        description: 'Incident created',
        author: 'system',
      }],
    };

    await this.repository.save(incident);

    // 알림 발송
    await this.notifyIncident(incident);

    return incident;
  }

  async notifyIncident(incident: Incident) {
    // Slack 채널 생성 (SEV1, SEV2)
    if (['SEV1', 'SEV2'].includes(incident.severity)) {
      const channel = await this.slack.conversations.create({
        name: `incident-${incident.id.toLowerCase()}`,
        is_private: false,
      });

      // 인시던트 메시지 게시
      await this.slack.chat.postMessage({
        channel: channel.channel!.id!,
        blocks: this.createIncidentBlocks(incident),
      });

      // 관련자 초대
      await this.inviteResponders(channel.channel!.id!, incident);
    }

    // PagerDuty 알림
    if (['SEV1', 'SEV2'].includes(incident.severity)) {
      await this.pagerDuty.createIncident({
        title: `[${incident.severity}] ${incident.title}`,
        service_id: this.getServiceId(incident.affectedServices[0]),
        urgency: incident.severity === 'SEV1' ? 'high' : 'low',
        body: {
          type: 'incident_body',
          details: incident.description,
        },
      });
    }

    // 일반 Slack 알림
    await this.slack.chat.postMessage({
      channel: '#incidents',
      blocks: this.createIncidentBlocks(incident),
    });
  }

  private createIncidentBlocks(incident: Incident) {
    const severityEmoji = {
      SEV1: ':red_circle:',
      SEV2: ':large_orange_circle:',
      SEV3: ':large_yellow_circle:',
      SEV4: ':white_circle:',
    };

    return [
      {
        type: 'header',
        text: {
          type: 'plain_text',
          text: `${severityEmoji[incident.severity]} ${incident.severity}: ${incident.title}`,
        },
      },
      {
        type: 'section',
        fields: [
          {
            type: 'mrkdwn',
            text: `*Incident ID:*\n${incident.id}`,
          },
          {
            type: 'mrkdwn',
            text: `*Status:*\n${incident.status}`,
          },
          {
            type: 'mrkdwn',
            text: `*Affected Services:*\n${incident.affectedServices.join(', ')}`,
          },
          {
            type: 'mrkdwn',
            text: `*Created:*\n<!date^${Math.floor(incident.createdAt.getTime() / 1000)}^{date_short_pretty} at {time}|${incident.createdAt.toISOString()}>`,
          },
        ],
      },
      {
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: `*Description:*\n${incident.description}`,
        },
      },
      {
        type: 'actions',
        elements: [
          {
            type: 'button',
            text: { type: 'plain_text', text: 'Acknowledge' },
            style: 'primary',
            action_id: 'incident_ack',
            value: incident.id,
          },
          {
            type: 'button',
            text: { type: 'plain_text', text: 'View Runbook' },
            url: `https://runbooks.example.com/${incident.affectedServices[0]}`,
          },
          {
            type: 'button',
            text: { type: 'plain_text', text: 'View Dashboard' },
            url: `https://grafana.example.com/d/overview?var-service=${incident.affectedServices[0]}`,
          },
        ],
      },
    ];
  }

  private generateIncidentId(): string {
    const date = new Date();
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const random = Math.random().toString(36).substring(2, 6).toUpperCase();
    return `INC-${year}${month}${day}-${random}`;
  }
}
```

## 런북 템플릿

```markdown
# Runbook: [서비스명] - [문제 유형]

## 개요
- **서비스**: [서비스명]
- **문제 유형**: [문제 유형]
- **최종 업데이트**: YYYY-MM-DD
- **작성자**: [작성자]

## 증상
- [ ] 증상 1
- [ ] 증상 2
- [ ] 관련 알림: [알림명]

## 영향 범위
- **사용자 영향**: [영향 설명]
- **비즈니스 영향**: [영향 설명]

## 진단 단계

### 1. 초기 확인
```bash
# 서비스 상태 확인
kubectl get pods -n production -l app=api-server

# 로그 확인
kubectl logs -n production -l app=api-server --tail=100

# 메트릭 확인
curl -s "http://prometheus:9090/api/v1/query?query=up{job='api-server'}"
```

### 2. 상세 진단
```bash
# 데이터베이스 연결 확인
psql -h $DB_HOST -U $DB_USER -c "SELECT 1"

# Redis 연결 확인
redis-cli -h $REDIS_HOST ping

# 외부 API 확인
curl -s -o /dev/null -w "%{http_code}" https://external-api.example.com/health
```

## 해결 방법

### 시나리오 A: [문제 상황 A]
1. [해결 단계 1]
2. [해결 단계 2]

```bash
# 명령어 예시
kubectl rollout restart deployment/api-server -n production
```

### 시나리오 B: [문제 상황 B]
1. [해결 단계 1]
2. [해결 단계 2]

## 롤백 절차
```bash
# 이전 버전으로 롤백
kubectl rollout undo deployment/api-server -n production

# 특정 리비전으로 롤백
kubectl rollout undo deployment/api-server -n production --to-revision=3
```

## 에스컬레이션
- **1차**: @on-call-engineer (Slack: #team-backend)
- **2차**: @team-lead (15분 응답 없을 시)
- **3차**: @director (SEV1/SEV2, 30분 이상 지속 시)

## 관련 링크
- [Grafana Dashboard](https://grafana.example.com/d/xxx)
- [Kibana Logs](https://kibana.example.com/app/discover)
- [서비스 문서](https://docs.example.com/services/xxx)
```

## 포스트모템 템플릿

```markdown
# 포스트모템: [인시던트 제목]

## 요약
| 항목 | 내용 |
|------|------|
| **인시던트 ID** | INC-YYYYMMDD-XXXX |
| **날짜** | YYYY-MM-DD |
| **심각도** | SEV1/SEV2/SEV3 |
| **지속 시간** | X시간 Y분 |
| **영향 범위** | [영향받은 사용자/서비스] |
| **근본 원인** | [1줄 요약] |
| **해결 방법** | [1줄 요약] |

## 타임라인 (KST)

| 시간 | 이벤트 |
|------|--------|
| HH:MM | 모니터링 알림 발생 |
| HH:MM | 온콜 엔지니어 확인 |
| HH:MM | 문제 원인 파악 |
| HH:MM | 수정 배포 시작 |
| HH:MM | 서비스 정상화 확인 |
| HH:MM | 인시던트 종료 선언 |

## 영향

### 사용자 영향
- 영향받은 사용자 수: X명
- 영향받은 요청 수: X건
- 에러율: X%
- 매출 영향: $X (추정)

### 시스템 영향
- 영향받은 서비스: [서비스 목록]
- 데이터 손실: 없음 / X건

## 근본 원인 분석 (RCA)

### 직접 원인
[직접적인 기술적 원인 설명]

### 근본 원인
[왜 이 문제가 발생했는지, 시스템적/프로세스적 원인]

### 기여 요인
- [기여 요인 1]
- [기여 요인 2]

## 교훈

### 잘한 점
- [잘한 점 1]
- [잘한 점 2]

### 개선이 필요한 점
- [개선점 1]
- [개선점 2]

## 액션 아이템

| 우선순위 | 액션 | 담당자 | 기한 | 상태 |
|----------|------|--------|------|------|
| P1 | [긴급 수정 사항] | @engineer | YYYY-MM-DD | ✅ 완료 |
| P2 | [모니터링 추가] | @sre | YYYY-MM-DD | 🔄 진행중 |
| P3 | [문서화] | @tech-writer | YYYY-MM-DD | ⏳ 예정 |

## 예방 조치

### 단기 (1-2주)
- [ ] [조치 1]
- [ ] [조치 2]

### 중기 (1-3개월)
- [ ] [조치 1]
- [ ] [조치 2]

### 장기 (3개월+)
- [ ] [아키텍처 개선]
- [ ] [프로세스 개선]

## 참고 자료
- [인시던트 Slack 채널](https://slack.com/archives/xxx)
- [관련 PR](https://github.com/org/repo/pull/xxx)
- [대시보드 스냅샷](https://grafana.example.com/xxx)

---
**작성자**: @engineer
**리뷰어**: @team-lead, @sre
**최종 승인**: @director
**게시일**: YYYY-MM-DD
```

## 온콜 로테이션

```typescript
// src/incident/oncall.ts
interface OnCallSchedule {
  team: string;
  schedule: {
    startDate: Date;
    endDate: Date;
    primary: string;
    secondary: string;
  }[];
}

async function getOnCallEngineer(team: string): Promise<{
  primary: string;
  secondary: string;
}> {
  // PagerDuty API 호출
  const response = await fetch(
    `https://api.pagerduty.com/oncalls?schedule_ids[]=${scheduleId}`,
    {
      headers: {
        Authorization: `Token token=${process.env.PAGERDUTY_TOKEN}`,
      },
    }
  );

  const data = await response.json();
  return {
    primary: data.oncalls[0]?.user?.summary || 'unknown',
    secondary: data.oncalls[1]?.user?.summary || 'unknown',
  };
}
```

## 사용 예시
**입력**: "인시던트 대응 프로세스 설정해줘"

**출력**:
1. 심각도 정의
2. 대응 자동화
3. 런북 템플릿
4. 포스트모템 템플릿
