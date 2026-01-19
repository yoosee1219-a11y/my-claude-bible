---
name: unified-orchestrator
description: 통합오케스트레이터, 에이전트+스킬조합, 자연어분석, Wave병렬실행, 동적조정, 제안승인플로우, 사용통계, 지능형조율, 리소스매칭, 프로젝트오케스트레이션으로 71개 에이전트와 30+개 스킬을 통합 조율하는 최상위 메타 오케스트레이터
---

# Unified Orchestrator (통합 오케스트레이터)

## Overview

**"/unified" 명령어 하나로 에이전트 + 스킬 최적 조합!**

기존 시스템의 한계:
| 시스템 | 범위 | 한계 |
|--------|------|------|
| `orchestrator.md` | 에이전트 71개 | 스킬 모름 |
| `intelligent-orchestrator.md` | 스킬 30+개 | 에이전트 모름 |

**Unified Orchestrator는 둘을 통합:**
```
사용자 요청
     │
     ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Unified Orchestrator                          │
├─────────────────────────────────────────────────────────────────┤
│  📖 분석 → 🔍 매칭 → 📋 제안 → ✅ 승인 → ⚡ 실행 → 🔄 동적조정   │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌─────────────┐    ┌─────────────┐                            │
│   │ 에이전트 DB │    │  스킬 DB   │                            │
│   │   71개     │    │   30+개    │                            │
│   │            │ +  │            │ = 최적 조합 제안           │
│   │ config.json│    │ CATALOG.md │                            │
│   └─────────────┘    └─────────────┘                            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 핵심 가치:

```
기존:
사용자: "사용자 인증 기능 추가해줘"
Claude: *에이전트만 선택* 또는 *스킬만 선택*
      → 불완전한 실행

Unified Orchestrator:
사용자: /unified "사용자 인증 기능 추가해줘"
Claude:
  🔍 분석 완료!
  
  📋 제안된 실행 계획:
  
  ┌─────────────────────────────────────────────────┐
  │ Wave 1 (설계):                                   │
  │   • [에이전트] auth-architect - 인증 아키텍처    │
  │   • [에이전트] api-designer - API 엔드포인트     │
  │                                                  │
  │ Wave 2 (구현):                                   │
  │   • [에이전트] api-implementer - 라우트 구현     │
  │   • [에이전트] service-logic - 서비스 로직       │
  │   • [스킬] fullstack-scaffold - 기본 구조 생성   │
  │                                                  │
  │ Wave 3 (품질):                                   │
  │   • [에이전트] test-unit - 단위 테스트           │
  │   • [에이전트] security-audit - 보안 점검        │
  │   • [스킬] security-best-practices - 보안 적용   │
  └─────────────────────────────────────────────────┘
  
  이대로 진행할까요? [Y/n/수정]
```

## When to Use This Skill

### ✅ 이 스킬을 사용하세요:

- **복합 프로젝트**: 설계 + 구현 + 테스트가 필요한 작업
- **도메인 횡단 작업**: 여러 분야(DB, API, UI 등)가 관련된 작업
- **최적 조합 필요**: 어떤 에이전트/스킬을 쓸지 모를 때
- **투명한 실행**: 계획을 확인하고 승인 후 진행
- **동적 대응 필요**: 문제 발생 시 자동 조정 원할 때

### ⚠️ 대신 사용:

- 단일 에이전트 작업 → `orchestrator.md` 직접 참조
- 단순 스킬 실행 → `/auto` 명령어 (intelligent-orchestrator)
- 빠른 단일 작업 → 직접 스킬 호출

## Prerequisites

- Development Agent Ecosystem (71개 에이전트)
  - 위치: `~/.claude/agents/`
  - 인덱스: `~/.claude/agents/config.json`
  
- Claude Skills (30+개)
  - 위치: `~/.claude/skills/`

## Instructions

### Step 1: 기본 사용법

```bash
# 명령어 형식
/unified "자연어 요청"

# 예시들
/unified "사용자 프로필 CRUD 기능 추가해줘"
/unified "실시간 채팅 기능 구현해줘"
/unified "planning.md 파일대로 웹서비스 만들어줘"
/unified "보안 점검하고 성능 최적화해줘"
```

### Step 2: 실행 흐름

#### Phase 1: 요청 분석

```typescript
interface AnalyzedRequest {
  originalText: string;
  keywords: string[];
  domains: string[];        // [database, api, frontend, ...]
  taskType: string;         // 프로젝트생성, 기능추가, 최적화, 분석
  complexity: 'low' | 'medium' | 'high';
  urgency: 'normal' | 'high';
}

function analyzeRequest(userInput: string): AnalyzedRequest {
  // 1. 키워드 추출
  const keywords = extractKeywords(userInput);
  // → [사용자, 인증, 로그인, JWT, 기능]
  
  // 2. 도메인 식별
  const domains = identifyDomains(keywords);
  // → [backend, api, security, database]
  
  // 3. 작업 유형 분류
  const taskType = classifyTask(userInput);
  // → "기능추가"
  
  // 4. 복잡도 판단
  const complexity = assessComplexity(domains, keywords);
  // → "high" (여러 도메인 관련)
  
  return { originalText, keywords, domains, taskType, complexity, urgency };
}
```

#### Phase 2: 리소스 매칭

```typescript
// 통합 리소스 데이터베이스
interface ResourceDatabase {
  agents: Agent[];    // 71개 (config.json에서 로드)
  skills: Skill[];    // 30+개 (skills/*.md 스캔)
}

// 에이전트 매칭 (orchestrator.md 로직)
function matchAgents(request: AnalyzedRequest): AgentMatch[] {
  const agentDB = loadAgentConfig('~/.claude/agents/config.json');
  
  const matches = [];
  
  // 키워드 → 에이전트 트리거 매칭
  const keywordToAgent = {
    // Database
    '테이블|스키마|ERD|모델링': 'db-architect',
    '쿼리|SQL|조회|성능': 'db-query',
    '마이그레이션|스키마변경': 'db-migration',
    
    // API
    'API설계|REST|GraphQL|엔드포인트': 'api-designer',
    '라우트|컨트롤러|핸들러': 'api-implementer',
    
    // Frontend
    '컴포넌트|UI|화면|폼': 'ui-component',
    '상태관리|Redux|Context': 'ui-state',
    
    // Backend
    '비즈니스로직|서비스|도메인': 'service-logic',
    '인증|로그인|JWT|OAuth': 'auth-architect',
    '웹소켓|실시간|gRPC': 'realtime-services',
    
    // Testing
    '유닛테스트|단위테스트': 'test-unit',
    'E2E|Playwright|Cypress': 'test-e2e',
    
    // Security
    '보안감사|취약점': 'security-audit',
    '위협모델링|공격벡터': 'security-threat',
    
    // ... 더 많은 매핑
  };
  
  for (const [pattern, agent] of Object.entries(keywordToAgent)) {
    const regex = new RegExp(pattern, 'i');
    if (request.keywords.some(k => regex.test(k))) {
      matches.push({
        type: 'agent',
        name: agent,
        reason: `키워드 매칭: ${pattern}`,
        score: calculateScore(pattern, request.keywords)
      });
    }
  }
  
  return matches;
}

// 스킬 매칭 (intelligent-orchestrator.md 로직)
function matchSkills(request: AnalyzedRequest): SkillMatch[] {
  const skillFiles = glob('~/.claude/skills/*.md');
  
  const matches = [];
  
  for (const file of skillFiles) {
    const skill = parseSkillFile(file);
    let score = 0;
    
    // description 매칭
    for (const keyword of request.keywords) {
      if (skill.description.toLowerCase().includes(keyword.toLowerCase())) {
        score += 10;
      }
    }
    
    // 사용 빈도 보너스
    score += getUsageCount(skill.name) * 0.1;
    
    if (score > 0) {
      matches.push({
        type: 'skill',
        name: skill.name,
        reason: `키워드 매칭 (점수: ${score})`,
        score
      });
    }
  }
  
  return matches.sort((a, b) => b.score - a.score);
}

// 통합 매칭
function matchResources(request: AnalyzedRequest): ResourceMatch[] {
  const agentMatches = matchAgents(request);
  const skillMatches = matchSkills(request);
  
  // 점수 기반 병합 및 정렬
  return [...agentMatches, ...skillMatches]
    .sort((a, b) => b.score - a.score);
}
```

#### Phase 3: Wave 계획 수립

```typescript
interface WavePlan {
  waves: Wave[];
  estimatedTime: string;
  executionMode: 'sequential' | 'parallel';
}

interface Wave {
  number: number;
  phase: string;           // 설계, 구현, 품질, 배포
  resources: Resource[];   // 에이전트 + 스킬 혼합
  dependencies: string[];
}

function createWavePlan(matches: ResourceMatch[], request: AnalyzedRequest): WavePlan {
  // Wave 분류 기준
  const waveCategories = {
    1: { // 설계
      phase: '설계',
      agents: ['arch-system', 'db-architect', 'api-designer', 'ui-component'],
      skills: ['design-system', 'microservices-architecture']
    },
    2: { // 구현
      phase: '구현',
      agents: ['db-migration', 'api-implementer', 'service-logic', 'ui-state'],
      skills: ['fullstack-scaffold', 'graphql-development']
    },
    3: { // 품질
      phase: '품질',
      agents: ['test-unit', 'test-integration', 'test-e2e', 'security-audit'],
      skills: ['security-best-practices', 'performance-testing']
    },
    4: { // 배포
      phase: '
배포',
      agents: ['cicd-pipeline', 'deployment-strategy', 'docker-specialist'],
      skills: ['publish-deploy', 'ci-cd-pipelines']
    }
  };

  const waves: Wave[] = [];

  for (const [waveNum, category] of Object.entries(waveCategories)) {
    const waveResources = matches.filter(m =>
      category.agents.includes(m.name) || category.skills.includes(m.name)
    );

    if (waveResources.length > 0) {
      waves.push({
        number: parseInt(waveNum),
        phase: category.phase,
        resources: waveResources,
        dependencies: parseInt(waveNum) > 1 ? [`Wave ${parseInt(waveNum) - 1}`] : []
      });
    }
  }

  return {
    waves,
    estimatedTime: calculateTotalTime(waves),
    executionMode: request.urgency === 'high' ? 'parallel' : 'sequential'
  };
}
```

#### Phase 4: 제안 및 승인

실행 전 사용자에게 계획을 제시하고 승인을 받습니다:

```
📋 제안된 실행 계획:

┌─────────────────────────────────────────────────┐
│ Wave 1 (설계):                                   │
│   • [에이전트] auth-architect                    │
│   • [에이전트] api-designer                      │
│                                                  │
│ Wave 2 (구현):                                   │
│   • [에이전트] api-implementer                   │
│   • [스킬] fullstack-scaffold                    │
│                                                  │
│ Wave 3 (품질):                                   │
│   • [에이전트] test-unit                         │
│   • [스킬] security-best-practices               │
└─────────────────────────────────────────────────┘

이대로 진행할까요? [Y/n/수정]
```

**수정 옵션:**
- `+에이전트명` - 리소스 추가
- `-에이전트명` - 리소스 제거
- `move 리소스 to Wave숫자` - Wave 변경

#### Phase 5: 실행 및 동적 조정

실행 중 문제 발생 시 자동으로 대안을 제안합니다:

```
🌊 Wave 2 (구현) 실행 중...
   🤖 api-implementer 시작...
   ❌ api-implementer 실패: WebSocket 라이브러리 미설치

💡 문제 감지: WebSocket 라이브러리 미설치
   대안 리소스 발견:
   1. realtime-services (에이전트)
   2. realtime-features (스킬)

대안을 사용할까요? [번호/n/auto]: auto

   🔄 대안 시도: realtime-services
   ✅ realtime-services로 성공!
```

**대안 리소스 맵:**
| 원본 | 대안 |
|------|------|
| db-architect | db-query, arch-data |
| api-designer | api-implementer, arch-system |
| test-unit | test-integration, test-e2e |
| fullstack-scaffold | antigravity-website-builder |
| publish-deploy | ci-cd-pipelines, verify-deployment |

#### Phase 6: 완료 리포트

```
==================================================
📊 실행 완료 리포트
==================================================

🌊 Wave 1: 3/3 성공
🌊 Wave 2: 3/3 성공
🌊 Wave 3: 3/3 성공

--------------------------------------------------
총 실행: 9개
  ✅ 성공: 9개
  ❌ 실패: 0개
  ⏱️ 총 소요 시간: 25분 15초
--------------------------------------------------

📈 통계가 업데이트되었습니다.
```

## Examples

### Example 1: 사용자 인증 기능

```bash
/unified "사용자 인증 기능 추가 - JWT, 소셜 로그인"
```

**결과:**
- Wave 1: auth-architect, api-designer, db-architect
- Wave 2: api-implementer, service-logic, fullstack-scaffold
- Wave 3: test-unit, security-audit, security-best-practices

### Example 2: 실시간 채팅

```bash
/unified "실시간 채팅 기능 구현"
```

**결과:**
- Wave 1: realtime-services, db-architect
- Wave 2: api-implementer, message-queue
- Wave 3: test-e2e, test-performance

## Key Concepts

| 개념 | 설명 |
|------|------|
| **Unified Matching** | 에이전트 + 스킬 통합 매칭 |
| **Wave Execution** | 의존성 기반 단계별 병렬 실행 |
| **Proposal Flow** | 실행 전 승인 플로우 |
| **Dynamic Adjustment** | 실패 시 대안 자동 제안 |

## Commands

```bash
/unified "요청"           # 기본 실행
/unified-plan "요청"      # 계획만 보기
/unified-stats            # 통계 확인
/unified "요청" --include="resource1,resource2"  # 리소스 포함
/unified "요청" --exclude="resource1"            # 리소스 제외
```

## Related Resources

- `~/.claude/agents/config.json` - 에이전트 인덱스
- `~/.claude/skills/CATALOG.md` - 스킬 카탈로그
- `orchestrator.md` - 에이전트 전용 오케스트레이터
- `intelligent-orchestrator.md` - 스킬 전용 오케스트레이터

## Tags

#통합오케스트레이터 #에이전트+스킬 #Wave실행 #동적조정 #제안승인플로우 #ClaudeCode

---

**Quick Start**: `/unified "자연어 요청"` 하나로 71개 에이전트와 30+개 스킬의 최적 조합!
