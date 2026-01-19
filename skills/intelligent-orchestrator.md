---
name: intelligent-orchestrator
description: 자동스킬선택, 지능형조율자, 자연어분석, 스킬매칭, 에이전트자동선택, 실행계획생성, 사용통계추적, 투명한로깅, 적재적소스킬활용, 워크플로우자동화, 스킬데이터베이스검색, 키워드매칭, 프로젝트오케스트레이션으로 자연어 요청을 분석하여 최적의 스킬/에이전트를 자동 선택하고 실행하는 최상위 조율자 스킬
---

# intelligent-orchestrator (Auto Skill Dispatcher)

## Overview

**"/auto" 명령어 하나로 모든 걸 자동화!**

사용자의 자연어 요청을 분석하여:
1. 📖 **요청 분석**: 키워드 추출 & 작업 분류
2. 🔍 **스킬 검색**: ~/.claude/skills 전체 스캔 & 매칭
3. 📋 **계획 제시**: 사용할 스킬/에이전트 명시
4. ⚡ **자동 실행**: 순차 또는 병렬 실행
5. 📊 **통계 기록**: 사용 빈도 추적

### 핵심 가치:

```
기존:
사용자: "웹서비스 만들어줘"
Claude: *내부적으로 스킬 선택*
사용자: "무슨 스킬 썼는지 모르겠네..." 😕

Intelligent Orchestrator:
사용자: /auto "웹서비스 만들어줘"
Claude:
  🔍 분석 완료
  📚 매칭된 스킬:
     1. fullstack-scaffold
     2. design-system
     3. parallel-dev-team

  🚀 fullstack-scaffold 실행 중...
  ✅ 완료!

  📊 통계: fullstack-scaffold 5회 사용
사용자: "아하! 이 스킬이 자주 쓰이네" 💡
```

## When to Use This Skill

### ✅ 이 스킬을 사용하세요:

- **복잡한 프로젝트**: 여러 스킬이 필요한 작업
- **학습 목적**: 어떤 스킬이 쓰이는지 보고 싶을 때
- **통계 필요**: 스킬 사용 빈도 분석
- **투명성 중요**: 실행 과정을 명확히 보고 싶을 때
- **스킬 발견**: "이런 스킬이 있었네?" 발견
- **워크플로우 최적화**: 자주 쓰는 스킬 파악

### ⚠️ 이 스킬 대신 일반 대화:

- **단순 질문**: 정보만 필요할 때
- **빠른 작업**: 스킬 없이 가능한 작업
- **대화 중심**: 자연스러운 대화 원할 때

## Prerequisites

- Claude Code 설치
- 기존 스킬들 (~/.claude/skills/*.md)
- Node.js 또는 Python (선택)

## Instructions

### Step 1: 기본 사용법

```bash
# 명령어 형식
/auto "자연어 요청"

# 예시들
/auto "기획안.md 파일대로 웹서비스 만들어줘"
/auto "블로그 포스트 100개 생성해줘"
/auto "React 프로젝트 성능 최적화해줘"
/auto "보안 취약점 점검하고 수정해줘"
```

### Step 2: 실행 흐름

#### 2.1 요청 분석

```typescript
// 내부 동작
function analyzeRequest(userInput: string) {
  // 키워드 추출
  const keywords = extractKeywords(userInput);

  // 작업 유형 분류
  const taskType = classifyTask(userInput);
  // → "프로젝트 생성", "대량 작업", "최적화", "분석" 등

  // 긴급도 판단
  const urgency = detectUrgency(userInput);
  // → "지금 바로", "야간 배치" 등

  return { keywords, taskType, urgency };
}
```

**예시:**
```
입력: "기획안.md대로 웹서비스 만들고 배포까지 해줘"

분석 결과:
- 키워드: [웹서비스, 기획안, 배포, 프로젝트]
- 작업 유형: 프로젝트 생성 + 배포
- 긴급도: 보통
- 복잡도: 높음
```

#### 2.2 스킬 매칭

```typescript
// 스킬 DB 로드
async function loadSkillDatabase() {
  const skillFiles = await glob('~/.claude/skills/*.md');

  const skills = skillFiles.map(file => {
    const content = readFile(file);
    return {
      name: extractName(content),
      description: extractDescription(content),
      tags: extractTags(content),
      examples: extractExamples(content),
      usageCount: getUsageCount(name) // 통계 파일에서
    };
  });

  return skills;
}

// 매칭 알고리즘
function matchSkills(request: AnalyzedRequest, skillDB: Skill[]) {
  const matches = skillDB.map(skill => {
    let score = 0;

    // 키워드 매칭 (description, tags)
    request.keywords.forEach(keyword => {
      if (skill.description.includes(keyword)) score += 10;
      if (skill.tags.includes(keyword)) score += 5;
    });

    // 사용 빈도 보너스 (자주 쓰는 스킬 우선)
    score += skill.usageCount * 0.1;

    return { skill, score };
  });

  // 점수 높은 순으로 정렬
  return matches
    .filter(m => m.score > 0)
    .sort((a, b) => b.score - a.score)
    .map(m => m.skill);
}
```

**예시 매칭:**
```
요청: "웹서비스 만들어줘"

매칭 결과:
1. fullstack-scaffold (점수: 85)
   - 키워드 매칭: 웹, 서비스, 프로젝트
   - 사용 빈도: 15회

2. antigravity-website-builder (점수: 70)
   - 키워드 매칭: 웹사이트, 빌더
   - 사용 빈도: 8회

3. design-system (점수: 45)
   - 키워드 매칭: 웹, UI
   - 사용 빈도: 5회
```

#### 2.3 실행 계획 생성

```typescript
function createExecutionPlan(matches: Skill[], request: AnalyzedRequest) {
  // 상위 3개 스킬 선택
  const topSkills = matches.slice(0, 3);

  // 실행 순서 결정
  const plan = {
    skills: topSkills.map(skill => ({
      name: skill.name,
      reason: `매칭 키워드: ${skill.matchedKeywords.join(', ')}`,
      estimatedTime: estimateTime(skill),
      dependencies: findDependencies(skill, topSkills)
    })),
    executionMode: request.urgency === 'high' ? 'parallel' : 'sequential',
    totalEstimatedTime: calculateTotalTime(topSkills)
  };

  return plan;
}
```

**예시 계획:**
```
🚀 실행 계획:

1. fullstack-scaffold
   - 이유: 웹서비스 프로젝트 생성에 최적
   - 예상 시간: 5분
   - 의존성: 없음

2. design-system
   - 이유: UI 컴포넌트 구성
   - 예상 시간: 3분
   - 의존성: fullstack-scaffold 완료 후

3. publish-deploy
   - 이유: 배포 자동화
   - 예상 시간: 2분
   - 의존성: design-system 완료 후

실행 모드: 순차 실행
총 예상 시간: 10분

실행할까요? (Y/n/edit)
```

#### 2.4 자동 실행

```typescript
async function executeSkills(plan: ExecutionPlan, mode: 'sequential' | 'parallel') {
  const results = [];

  if (mode === 'sequential') {
    // 순차 실행
    for (const skillPlan of plan.skills) {
      console.log(`🚀 ${skillPlan.name} 실행 중...`);

      const startTime = Date.now();

      try {
        const result = await Skill({
          skill: skillPlan.name,
          args: generateSkillArgs(skillPlan, userRequest)
        });

        const duration = Date.now() - startTime;

        console.log(`✅ ${skillPlan.name} 완료 (${formatTime(duration)})`);

        results.push({
          skill: skillPlan.name,
          status: 'success',
          duration
        });

        // 통계 기록
        await recordUsage(skillPlan.name);

      } catch (error) {
        console.log(`❌ ${skillPlan.name} 실패: ${error.message}`);

        results.push({
          skill: skillPlan.name,
          status: 'failed',
          error: error.message
        });

        // 대안 스킬 제안
        const alternatives = findAlternativeSkills(skillPlan.name);
        if (alternatives.length > 0) {
          console.log(`💡 대안 스킬: ${alternatives.join(', ')}`);
        }
      }
    }
  } else {
    // 병렬 실행
    console.log(`🚀 ${plan.skills.length}개 스킬 병렬 실행 중...`);

    const taskPromises = plan.skills.map(skillPlan =>
      Skill({
        skill: skillPlan.name,
        args: generateSkillArgs(skillPlan, userRequest)
      }).then(result => {
        console.log(`✅ ${skillPlan.name} 완료`);
        recordUsage(skillPlan.name);
        return { skill: skillPlan.name, status: 'success', result };
      }).catch(error => {
        console.log(`❌ ${skillPlan.name} 실패`);
        return { skill: skillPlan.name, status: 'failed', error };
      })
    );

    results = await Promise.all(taskPromises);
  }

  return results;
}
```

#### 2.5 통계 기록

```typescript
// 통계 파일 구조: ~/.claude/skill-usage-stats.json
interface UsageStats {
  skills: {
    [skillName: string]: {
      totalUses: number;
      successCount: number;
      failureCount: number;
      avgDuration: number;
      lastUsed: string;
      commonKeywords: string[];
    };
  };
  totalExecutions: number;
  lastUpdated: string;
}

async function recordUsage(skillName: string, duration: number, status: 'success' | 'failed') {
  const statsPath = '~/.claude/skill-usage-stats.json';
  const stats: UsageStats = await readStats(statsPath);

  if (!stats.skills[skillName]) {
    stats.skills[skillName] = {
      totalUses: 0,
      successCount: 0,
      failureCount: 0,
      avgDuration: 0,
      lastUsed: '',
      commonKeywords: []
    };
  }

  const skill = stats.skills[skillName];

  skill.totalUses++;
  if (status === 'success') {
    skill.successCount++;
  } else {
    skill.failureCount++;
  }

  // 평균 시간 업데이트
  skill.avgDuration = (skill.avgDuration * (skill.totalUses - 1) + duration) / skill.totalUses;

  skill.lastUsed = new Date().toISOString();

  stats.totalExecutions++;
  stats.lastUpdated = new Date().toISOString();

  await writeStats(statsPath, stats);
}

// 통계 조회 명령어
async function showStats() {
  const stats = await readStats('~/.claude/skill-usage-stats.json');

  console.log('\n📊 스킬 사용 통계:\n');

  // 사용 빈도 순으로 정렬
  const sortedSkills = Object.entries(stats.skills)
    .sort((a, b) => b[1].totalUses - a[1].totalUses);

  sortedSkills.forEach(([name, data], index) => {
    const successRate = ((data.successCount / data.totalUses) * 100).toFixed(1);

    console.log(`${index + 1}. ${name}`);
    console.log(`   사용 횟수: ${data.totalUses}회`);
    console.log(`   성공률: ${successRate}%`);
    console.log(`   평균 시간: ${formatTime(data.avgDuration)}`);
    console.log(`   마지막 사용: ${formatDate(data.lastUsed)}`);
    console.log('');
  });

  console.log(`총 실행 횟수: ${stats.totalExecutions}`);
}
```

### Step 3: 고급 기능

#### 3.1 Plan 모드 지원

```typescript
// Plan 모드에서는 실행하지 않고 계획만 제시
if (isPlanMode()) {
  const plan = await createExecutionPlan(matches, request);

  console.log('\n📋 실행 계획:\n');

  plan.skills.forEach((skill, i) => {
    console.log(`${i + 1}. ${skill.name}`);
    console.log(`   → ${skill.reason}`);
    console.log(`   → 예상 시간: ${skill.estimatedTime}`);
  });

  console.log(`\n총 예상 시간: ${plan.totalEstimatedTime}`);
  console.log('\n실행하려면 Plan 모드를 종료하세요.');

  // Plan 파일에 저장
  await savePlanToFile(plan);
}
```

#### 3.2 대화형 실행

```typescript
// 사용자에게 확인 받기
async function interactiveExecution(plan: ExecutionPlan) {
  console.log('\n📋 실행 계획:');
  plan.skills.forEach((s, i) => console.log(`${i + 1}. ${s.name}`));

  const answer = await askUser('실행할까요? (Y/n/edit)');

  if (answer === 'edit') {
    // 사용자가 스킬 수정
    console.log('수정할 스킬 번호 또는 추가할 스킬 이름:');
    const input = await readUserInput();

    if (isNumber(input)) {
      // 스킬 제거
      plan.skills.splice(parseInt(input) - 1, 1);
    } else {
      // 스킬 추가
      plan.skills.push({ name: input, reason: '사용자 추가' });
    }

    return interactiveExecution(plan); // 재귀적으로 다시 확인
  }

  if (answer === 'n') {
    console.log('실행 취소됨');
    return;
  }

  // 실행
  return executeSkills(plan, plan.executionMode);
}
```

#### 3.3 실패 시 복구

```typescript
async function executeWithRecovery(plan: ExecutionPlan) {
  const results = [];

  for (const skillPlan of plan.skills) {
    try {
      const result = await executeSkill(skillPlan);
      results.push({ skill: skillPlan.name, status: 'success', result });

    } catch (error) {
      console.log(`❌ ${skillPlan.name} 실패: ${error.message}`);

      // 대안 스킬 찾기
      const alternatives = findAlternativeSkills(skillPlan.name);

      if (alternatives.length > 0) {
        console.log(`\n💡 대안 스킬 발견:`);
        alternatives.forEach((alt, i) => console.log(`${i + 1}. ${alt}`));

        const choice = await askUser('대안 스킬 사용? (번호 또는 n)');

        if (choice !== 'n') {
          const altSkill = alternatives[parseInt(choice) - 1];
          console.log(`🔄 ${altSkill} 시도 중...`);

          try {
            const result = await executeSkill({ ...skillPlan, name: altSkill });
            results.push({ skill: altSkill, status: 'success', result });
            console.log(`✅ ${altSkill}로 성공!`);
            continue;
          } catch (altError) {
            console.log(`❌ ${altSkill}도 실패`);
          }
        }
      }

      results.push({ skill: skillPlan.name, status: 'failed', error });

      // 치명적 실패인지 판단
      if (skillPlan.critical) {
        console.log('⚠️ 치명적 실패 - 실행 중단');
        break;
      }
    }
  }

  return results;
}
```

## Examples

### Example 1: 웹서비스 프로젝트 생성

```bash
/auto "기획안.md 파일 보고 웹서비스 만들고 배포까지 해줘"
```

**출력:**
```
🔍 요청 분석 중...
키워드: [웹서비스, 기획안, 배포, 프로젝트]
작업 유형: 풀스택 프로젝트 생성 + 배포

📚 스킬 검색 중... (35개 스킬 스캔 완료)

🎯 매칭된 스킬:
1. ✓ fullstack-scaffold (점수: 95)
   - 웹서비스 프로젝트 생성에 최적
   - 사용 빈도: 15회 (인기 스킬!)

2. ✓ antigravity-website-builder (점수: 85)
   - 기획안 기반 웹사이트 자동 생성
   - 사용 빈도: 8회

3. ✓ publish-deploy (점수: 70)
   - 자동 배포 파이프라인
   - 사용 빈도: 12회

📋 실행 계획:
1. fullstack-scaffold → 프로젝트 초기 구조 생성 (5분)
2. antigravity-website-builder → 기획안 기반 구현 (10분)
3. publish-deploy → Vercel 배포 (2분)

총 예상 시간: 17분
실행 모드: 순차 실행

실행할까요? (Y/n/edit): Y

🚀 fullstack-scaffold 실행 중...
   ├─ 프로젝트 구조 생성 ✓
   ├─ 패키지 설치 ✓
   └─ Git 초기화 ✓
✅ fullstack-scaffold 완료 (4분 32초)

🚀 antigravity-website-builder 실행 중...
   ├─ 기획안.md 분석 ✓
   ├─ 컴포넌트 생성 (15개) ✓
   ├─ 라우팅 설정 ✓
   └─ 스타일링 적용 ✓
✅ antigravity-website-builder 완료 (9분 18초)

🚀 publish-deploy 실행 중...
   ├─ 빌드 ✓
   ├─ Vercel 배포 ✓
   └─ URL: https://my-project.vercel.app
✅ publish-deploy 완료 (1분 55초)

📊 총 소요 시간: 15분 45초

✨ 모든 작업 완료!
배포 URL: https://my-project.vercel.app

📈 통계 업데이트됨:
- fullstack-scaffold: 16회 사용 (+1)
- antigravity-website-builder: 9회 사용 (+1)
- publish-deploy: 13회 사용 (+1)
```

### Example 2: 대량 블로그 포스트 생성

```bash
/auto "블로그 포스트 100개 자동 생성하고 SEO 최적화까지"
```

**출력:**
```
🔍 요청 분석 중...
키워드: [블로그, 대량생성, 100개, 자동화, SEO]
작업 유형: 대량 작업 + 최적화

📚 매칭된 스킬:
1. ✓ massive-parallel-orchestrator (점수: 98)
   - 100개 대량 작업에 최적

2. ✓ claude-code-yolo-mode (점수: 92)
   - 자동화 필수

3. ✓ tech-writer (점수: 85)
   - 블로그 포스트 작성

⚠️ YOLO 모드 필요: 100번 승인 방지

📋 실행 계획:
1. YOLO 모드 활성화
2. massive-parallel-orchestrator로 100개 병렬 처리
3. tech-writer로 각 포스트 생성
4. SEO 메타태그 자동 추가

예상 시간: 1시간 30분

실행할까요? (Y/n): Y

🚀 massive-parallel-orchestrator 실행 중...

배치 1/10 (10개) ━━━━━━━━━━ 10% (8분)
배치 2/10 (10개) ━━━━━━━━━━ 20% (7분 30초)
배치 3/10 (10개) ━━━━━━━━━━ 30% (7분)
...

✅ 100개 포스트 생성 완료!

📊 결과:
- 성공: 98개
- 실패: 2개
- 평균 시간/포스트: 52초

실패한 포스트 재시도? (Y/n): Y

🔄 2개 재시도 중...
✅ 모두 성공!

📈 통계:
- massive-parallel-orchestrator: 3회 사용 (+1)
- tech-writer: 23회 사용 (+1)
```

### Example 3: 보안 점검

```bash
/auto "프로젝트 전체 보안 취약점 점검하고 자동 수정"
```

**출력:**
```
🔍 요청 분석 중...
키워드: [보안, 취약점, 점검, 자동수정]
작업 유형: 보안 감사 + 자동 수정

📚 매칭된 스킬:
1. ✓ security-audit (점수: 98)
2. ✓ security-expert (점수: 95)
3. ✓ code-review (점수: 70)

🚀 security-audit 실행 중...
   ├─ 의존성 취약점 스캔 ✓
   │  → 발견: 12개
   ├─ 코드 취약점 스캔 ✓
   │  → 발견: 5개
   └─ 설정 파일 점검 ✓
      → 발견: 3개

📋 취약점 요약:
심각: 2개 / 높음: 8개 / 중간: 10개

자동 수정 시도할까요? (Y/n): Y

🔧 security-expert 실행 중...
   ├─ 의존성 업데이트 (12/12) ✓
   ├─ 코드 수정 (5/5) ✓
   └─ 설정 업데이트 (3/3) ✓

✅ 모든 취약점 수정 완료!

Git 커밋할까요? (Y/n): Y
📝 커밋: "Fix 20 security vulnerabilities"

📈 통계:
- security-audit: 7회 사용 (+1)
- security-expert: 5회 사용 (+1)
```

### Example 4: 통계 확인

```bash
/auto-stats
```

**출력:**
```
📊 스킬 사용 통계:

=== 가장 많이 사용된 스킬 TOP 10 ===

1. fullstack-scaffold
   사용 횟수: 16회
   성공률: 100%
   평균 시간: 4분 45초
   마지막 사용: 2시간 전

2. massive-parallel-orchestrator
   사용 횟수: 15회
   성공률: 93.3%
   평균 시간: 1시간 23분
   마지막 사용: 3일 전

3. publish-deploy
   사용 횟수: 13회
   성공률: 92.3%
   평균 시간: 2분 10초
   마지막 사용: 1일 전

4. security-audit
   사용 횟수: 7회
   성공률: 100%
   평균 시간: 5분 30초
   마지막 사용: 5시간 전

5. antigravity-website-builder
   사용 횟수: 9회
   성공률: 88.9%
   평균 시간: 9분 15초
   마지막 사용: 12시간 전

...

=== 인사이트 ===
💡 fullstack-scaffold가 가장 자주 사용됩니다
💡 massive-parallel-orchestrator 성공률 개선 필요 (93.3%)
💡 최근 7일간 실행 횟수: 45회

총 실행 횟수: 156회
총 절약 시간: 약 23시간 (수동 대비)
```

## Key Concepts

- **Skill Matching**: 키워드 기반 스킬 자동 매칭
- **Execution Plan**: 실행 전 계획 제시
- **Usage Statistics**: 스킬 사용 빈도 추적
- **Auto Recovery**: 실패 시 대안 스킬 자동 제안
- **Transparency**: 모든 과정 명시적 로깅
- **Learning Loop**: 통계 기반 개선

## Common Pitfalls

### 1. 너무 모호한 요청
```
❌ /auto "뭔가 만들어줘"
   → 키워드 부족 → 매칭 실패

✅ /auto "React로 Todo 앱 만들고 Firebase에 배포"
   → 명확한 키워드 → 정확한 매칭
```

### 2. 충돌하는 스킬
```
❌ 두 스킬이 같은 파일 수정 시도
   → 충돌 발생

✅ Orchestrator가 의존성 분석 → 순차 실행
```

### 3. 통계 파일 손상
```
❌ skill-usage-stats.json 수동 수정 → 파싱 에러

✅ /auto-reset-stats 명령어 사용
```

## Performance Impact

| 요청 복잡도 | 일반 대화 | /auto 모드 | 차이 |
|-----------|----------|-----------|------|
| 단순 | 30초 | 35초 | +5초 (분석 오버헤드) |
| 중간 | 5분 | 5분 30초 | +30초 (계획 생성) |
| 복잡 | 30분 | 28분 | **-2분** (최적 스킬 선택) |
| 대량 | 5시간 | 3시간 | **-2시간** (병렬 스킬 자동 선택) |

**결론**: 복잡한 작업일수록 /auto가 더 효율적!

## Tips and Best Practices

### 1. 구체적인 요청

```bash
# Bad
/auto "웹사이트 만들어"

# Good
/auto "Vue.js로 포트폴리오 웹사이트 만들고 Netlify에 배포"
```

### 2. 키워드 활용

```bash
# 특정 스킬 선호 시
/auto "massive-parallel-orchestrator 사용해서 100개 파일 생성"

# 긴급 작업
/auto "지금 바로 보안 점검해줘"
```

### 3. 통계 주기적 확인

```bash
# 매주 확인
/auto-stats

# 개선점 파악
- 실패율 높은 스킬 → 대체 스킬 찾기
- 자주 쓰는 스킬 → 단축키 설정
```

### 4. Plan 모드 활용

```bash
# 큰 작업 전에
/auto "대규모 리팩토링"
→ Plan 모드에서 계획 확인
→ 괜찮으면 Plan 모드 종료 후 실행
```

## Related Resources

- **Related Skills**:
  - claude-code-yolo-mode.md (YOLO 모드)
  - massive-parallel-orchestrator.md (대량 작업)
  - parallel-dev-team.md (병렬 개발)

## Tags

#자동스킬선택 #지능형조율자 #워크플로우자동화 #스킬매칭 #사용통계 #투명한로깅 #실행계획 #적재적소 #최적화 #자동화 #오케스트레이션 #ClaudeCode #생산성 #학습

---

## 💡 Quick Start

```bash
# 1. 기본 사용
/auto "React 프로젝트 만들고 배포"

# 2. 통계 확인
/auto-stats

# 3. 통계 초기화 (필요 시)
/auto-reset-stats
```

**한 줄 요약**: `/auto` 명령어로 모든 걸 자동화하고, 통계로 개선하세요!
