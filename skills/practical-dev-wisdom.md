---
name: practical-dev-wisdom
description: 실전개발지혜, 문제해결전략, 성능최적화, 제품전략, AI프롬프팅, 트렌드대응, 긴급개발, GTM전략, 언어화된샘플링, 문서화전략, 비개발자개발, AI에이전트오케스트레이션, Tmux, LangGraph, PM에이전트, 자동화로 검증된 6가지 실전 개발 지혜와 문제 해결 전략을 제공하는 스킬
---

# Practical Dev Wisdom

실전에서 검증된 6가지 개발 지혜와 문제 해결 전략을 제공합니다.

## Overview

이 스킬은 다음 6가지 영역의 실전 노하우를 통합 제공합니다:

1. **성능 최적화 전략** - 애니메이션 라이브러리 개발 경험
2. **제품 전략 수립** - GTM(Go-To-Market) 전략
3. **AI 프롬프팅 마스터리** - 창의성 극대화 기법
4. **프론트엔드 트렌드 대응** - 2026년 기술 스택
5. **긴급 개발 생존 전략** - Claude Code로 3일 만에 서비스 구축
6. **AI 에이전트 오케스트레이션** - Tmux + LangGraph로 99% 자동화

---

## 🎯 공통 핵심 원칙

모든 실전 상황에서 적용되는 3단계 프레임워크:

### 1단계: 문제 정의 (Problem Definition)
```
"문제 정의가 해결책을 결정한다"

- 진짜 문제가 무엇인가?
- 누구의 문제인가?
- 왜 지금 해결해야 하는가?
```

### 2단계: 도구 선택 (Tool Selection)
```
"적절한 도구 > 최신 도구"

- 현재 인프라와 호환되는가?
- 팀이 이해하고 유지보수할 수 있는가?
- 문제 해결에 충분한가?
```

### 3단계: 실행과 최적화 (Execution)
```
"완벽함보다 반복 가능한 프로세스"

- 빠르게 프로토타입
- 검증하고 개선
- 문서화하고 공유
```

---

## 📦 섹션 1: 성능 최적화 전략

**출처:** 애니메이션 라이브러리 SSGOI 개발 경험
**핵심 학습:** 구조적 제약을 인식하고 창의적으로 우회하기

### 문제 1: 성능 vs 자연스러움 트레이드오프

#### 배경
- **CSS 애니메이션**: 컴포지터 스레드에서 실행되어 버벅거리지 않지만 현재 속도를 인식하지 못함
- **JS 스프링**: 속도 추적 가능하나 메인 스레드 점유로 성능 저하
- **Web Animation API (WAAPI)**: CSS처럼 성능 우수하나 속도 정보 부재

#### 혁신적 해결책: 하이브리드 접근법

**아이디어:**
```
스프링 시뮬레이션을 미리 계산
→ 키프레임 배열로 변환
→ WAAPI에 전달
→ 성능 + 자연스러움 동시 확보
```

**구현 과정:**
```javascript
// 1. 스프링 물리 시뮬레이션
function simulateSpring(from, to, stiffness, damping) {
  const frames = []
  let position = from
  let velocity = 0
  let time = 0
  const dt = 1/60 // 60fps

  while (Math.abs(to - position) > 0.01 || Math.abs(velocity) > 0.01) {
    // Semi-Implicit Euler 수치해석법
    const force = (to - position) * stiffness
    const damping_force = velocity * damping

    velocity += (force - damping_force) * dt
    position += velocity * dt
    time += dt

    frames.push({ time, position, velocity })
  }

  return frames
}

// 2. WAAPI 키프레임으로 변환
function toKeyframes(frames) {
  const totalTime = frames[frames.length - 1].time

  return frames.map(frame => ({
    transform: `translateX(${frame.position}px)`,
    offset: frame.time / totalTime
  }))
}

// 3. WAAPI 실행 + 데이터 보관
function animate(element, from, to) {
  const frames = simulateSpring(from, to, 0.5, 0.8)
  const keyframes = toKeyframes(frames)

  // 데이터 보관 (방향 전환 시 현재 속도 조회용)
  element._springData = frames

  return element.animate(keyframes, {
    duration: frames[frames.length - 1].time * 1000,
    fill: 'forwards'
  })
}

// 4. 현재 속도 조회 (방향 전환 시)
function getCurrentVelocity(element, currentTime) {
  const frames = element._springData

  // 이진 탐색으로 현재 프레임 찾기
  let left = 0
  let right = frames.length - 1

  while (left < right) {
    const mid = Math.floor((left + right) / 2)
    if (frames[mid].time < currentTime) {
      left = mid + 1
    } else {
      right = mid
    }
  }

  // 선형 보간으로 정확한 속도 계산
  const f1 = frames[left - 1]
  const f2 = frames[left]
  const t = (currentTime - f1.time) / (f2.time - f1.time)

  return f1.velocity + (f2.velocity - f1.velocity) * t
}
```

#### 추가 최적화 기법

**dt clamping (델타 타임 제한):**
```javascript
// 프레임 드롭 시 시뮬레이션 폭주 방지
const dt = Math.min(deltaTime, 100) // 최대 100ms로 제한
```

**Lag smoothing (지연 분산):**
```javascript
// 긴 프레임을 여러 작은 구간으로 분산
if (deltaTime > 100) {
  const steps = Math.ceil(deltaTime / 16.67)
  for (let i = 0; i < steps; i++) {
    update(deltaTime / steps)
  }
}
```

**Ticker 싱글톤 (RAF 최적화):**
```javascript
// 모든 애니메이션이 하나의 requestAnimationFrame 공유
class Ticker {
  constructor() {
    this.callbacks = []
    this.running = false
  }

  add(callback) {
    this.callbacks.push(callback)
    if (!this.running) this.start()
  }

  remove(callback) {
    const index = this.callbacks.indexOf(callback)
    if (index > -1) this.callbacks.splice(index, 1)
  }

  start() {
    this.running = true
    requestAnimationFrame(this.tick.bind(this))
  }

  tick() {
    this.callbacks.forEach(cb => cb())
    if (this.callbacks.length > 0) {
      requestAnimationFrame(this.tick.bind(this))
    } else {
      this.running = false
    }
  }
}

const ticker = new Ticker()
```

### 문제 2: DOM 생명주기 관리

#### 도전 과제
React, Solid, Qwik 등 프레임워크마다 DOM 소멸 시점 감지 방식이 다릅니다.

#### 해결책: MutationObserver

**프레임워크 독립적 구현:**
```javascript
// 퇴장 애니메이션을 프레임워크 래퍼 없이 구현
class ExitAnimationManager {
  constructor() {
    this.observer = new MutationObserver(mutations => {
      mutations.forEach(mutation => {
        mutation.removedNodes.forEach(node => {
          if (node.nodeType === 1) { // Element Node
            this.handleExit(node)
          }
        })
      })
    })

    this.observer.observe(document.body, {
      childList: true,
      subtree: true
    })
  }

  async handleExit(element) {
    // 퇴장 애니메이션 설정 확인
    const exitConfig = element._exitAnimation
    if (!exitConfig) return

    // 일시적으로 DOM에 다시 추가
    const parent = element._originalParent
    const nextSibling = element._nextSibling

    if (nextSibling) {
      parent.insertBefore(element, nextSibling)
    } else {
      parent.appendChild(element)
    }

    // 애니메이션 실행
    const animation = element.animate(exitConfig.keyframes, exitConfig.options)
    await animation.finished

    // 진짜 제거
    element.remove()
  }

  register(element, config) {
    element._exitAnimation = config
    element._originalParent = element.parentNode
    element._nextSibling = element.nextSibling
  }
}

const exitManager = new ExitAnimationManager()

// 사용법
exitManager.register(myElement, {
  keyframes: [
    { opacity: 1, transform: 'scale(1)' },
    { opacity: 0, transform: 'scale(0.8)' }
  ],
  options: { duration: 300, easing: 'ease-out' }
})
```

### 문제 3: 개발자 경험 (DX)

#### 도전 과제
- 언마운트/리마운트 중 애니메이션 상태 소실
- 반복적인 키 입력의 번거로움

#### 해결책: 빌드 타임 자동 키 생성

**unplugin으로 다중 번들러 지원:**
```javascript
// vite.config.js, webpack.config.js, rollup.config.js 등 모두 지원
import { unplugin } from 'unplugin'
import MagicString from 'magic-string'
import { parse } from '@babel/parser'
import { traverse } from '@babel/traverse'

export const AnimationKeyPlugin = unplugin((options) => {
  return {
    name: 'animation-key-plugin',

    transform(code, id) {
      // .jsx, .tsx 파일만 처리
      if (!/\.[jt]sx?$/.test(id)) return null

      const ast = parse(code, {
        sourceType: 'module',
        plugins: ['jsx', 'typescript']
      })

      const s = new MagicString(code)

      traverse(ast, {
        // animate() 함수 호출 찾기
        CallExpression(path) {
          if (path.node.callee.name === 'animate') {
            // key가 없으면 자동 생성
            const hasKey = path.node.arguments.some(arg =>
              arg.type === 'ObjectExpression' &&
              arg.properties.some(prop => prop.key.name === 'key')
            )

            if (!hasKey) {
              // 파일:라인:컬럼 기반 고유 키 생성
              const loc = path.node.loc.start
              const key = `${id}:${loc.line}:${loc.column}`

              // 코드 수정
              const lastArg = path.node.arguments[path.node.arguments.length - 1]
              s.appendLeft(lastArg.end, `, { key: "${key}" }`)
            }
          }
        }
      })

      return {
        code: s.toString(),
        map: s.generateMap({ hires: true })
      }
    }
  }
})

// Vite
import { AnimationKeyPlugin } from './animation-key-plugin'

export default {
  plugins: [AnimationKeyPlugin.vite()]
}

// Webpack
module.exports = {
  plugins: [AnimationKeyPlugin.webpack()]
}

// Rollup
export default {
  plugins: [AnimationKeyPlugin.rollup()]
}
```

**효과:**
```jsx
// Before (수동 키 입력)
<div ref={el => animate(el, { x: 100 }, { key: 'my-unique-key-1' })} />
<div ref={el => animate(el, { y: 50 }, { key: 'my-unique-key-2' })} />

// After (자동 생성)
<div ref={el => animate(el, { x: 100 })} />  // key: "App.jsx:42:15"
<div ref={el => animate(el, { y: 50 })} />   // key: "App.jsx:43:15"
```

### 핵심 Takeaways

1. **하이브리드 접근**: 각 기술의 장점을 조합 (스프링 시뮬레이션 + WAAPI)
2. **프레임워크 독립성**: MutationObserver로 DOM 레벨에서 해결
3. **DX 자동화**: 빌드 타임 플러그인으로 반복 작업 제거
4. **AI 활용**: unplugin 개발에 Claude Code 사용 (요구사항 정의가 핵심)

---

## 🎯 섹션 2: 제품 전략 수립 (GTM)

**출처:** Go-To-Market 전략 가이드
**핵심 학습:** "어디로 먼저 갈 것인가"를 판단하기

### GTM이란?

**정의:**
```
Go-To-Market 전략 = 제품의 초기 시장 침투 전략

핵심 질문:
- 어떤 고객 세그먼트를 먼저 공략할 것인가?
- 초기 핵심 고객군은 누구인가?
- 그 시장에 어떻게 접근할 것인가?
```

### 마케팅 vs 제품 관점

**흔한 오해:**
```
GTM = 마케팅 전략 (❌)
```

**올바른 이해:**
```
GTM = 제품 전략에서 시작 (✅)

"누가 우리 제품을 구매해주었으면 좋겠는가?"
→ MRD (Market Requirements Document)의 타깃 고객군
→ PRD (Product Requirements Document)의 페르소나
```

### 실전 사례: 항공권 서비스

#### ❌ 나쁜 예: 모든 사람을 대상으로

```
"전 세계 모든 항공권을 비교해보세요"

문제점:
- 구글 플라이트와 똑같음
- 차별화 불가능
- 불필요한 기능 과다 (전 지구 검색, 장기 캘린더)
```

#### ✅ 좋은 예: 타깃 세그먼트 집중

```
"다음 주말 일본 여행 갈 때 최저가 항공권을 비교해보세요"

장점:
- 명확한 타깃: 가족 여행객, 단기 근거리 여행객
- 기능 최적화: 일본/동남아 중심, 주말 검색 특화
- 불필요한 기능 제거: 장기 캘린더, 전 지구 검색
```

### 타깃 고객군 분석 프로세스

#### 1단계: 기존 데이터 분석

```javascript
// 호텔 예약 서비스 사용자 분류
const users = await db.query(`
  SELECT
    user_id,
    booking_purpose,
    preferred_region,
    booking_timing
  FROM bookings
  WHERE created_at >= NOW() - INTERVAL '90 days'
`)

// 세그먼트 분류
const segments = {
  business: users.filter(u => u.booking_purpose === '출장'),
  family: users.filter(u => u.booking_purpose === '가족 여행'),
  friends: users.filter(u => u.booking_purpose === '친구 여행')
}

// 선호 지역 분석
const topRegions = segments.family
  .flatMap(u => u.preferred_region)
  .reduce((acc, region) => {
    acc[region] = (acc[region] || 0) + 1
    return acc
  }, {})

console.log(topRegions)
// { '일본': 324, '동남아': 198, '제주': 142 }
```

#### 2단계: 페르소나 설계

```markdown
# 페르소나: 주말 일본 여행 가족

## 기본 정보
- 이름: 김가족 (40대 부부 + 초등학생 2명)
- 직업: 직장인 부부
- 소득: 중산층

## 여행 패턴
- 빈도: 분기 1회
- 기간: 2박 3일 (금-일)
- 예산: 왕복 항공권 4명 150만원 이하
- 선호 시간: 오전 출발, 저녁 귀국

## 니즈 (Needs)
- 빠른 검색 (5분 내 결정)
- 가족 좌석 배정 보장
- 수하물 포함 여부 명확 표시
- 취소/변경 규정 쉽게 확인

## 페인 포인트 (Pain Points)
- 기존 서비스는 너무 복잡함
- 세계 전체 검색 불필요
- 가족 단위 예약이 불편함

## 성공 지표
- 5분 내 항공권 비교 완료
- 3클릭 이내 예약 완료
- 가족 좌석 배정 자동 선택
```

#### 3단계: MVP 기능 정의

```markdown
# 항공권 서비스 MVP (가족 일본 여행 타깃)

## 포함 기능 (Must Have)
- [ ] 일본 주요 6개 도시만 검색 (도쿄, 오사카, 후쿠오카, 삿포로, 오키나와, 나고야)
- [ ] 주말 기준 검색 (금-일, 토-월)
- [ ] 가족 인원수 빠른 선택 (2+2, 2+1, 2+0)
- [ ] 좌석 배정 필터 (가족 좌석 우선 표시)
- [ ] 수하물 포함/불포함 명확 표시
- [ ] 총액 기준 정렬 (항공료+수하물+좌석)

## 제외 기능 (Won't Have)
- ❌ 전 세계 검색
- ❌ 장기 캘린더 (6개월 이상)
- ❌ 복잡한 필터 (20개 이상)
- ❌ 마일리지 연동
- ❌ 호텔 패키지

## UI 최적화
- 검색창: "다음 주말 일본 여행" 템플릿 제공
- 결과: 가족 좌석 가능 여부 배지 표시
- 정렬: 총액 기준 기본 정렬
```

### SOM (Serviceable Obtainable Market)

**TAM vs SAM vs SOM:**
```
TAM (Total Addressable Market): 전체 시장
  ↓
SAM (Serviceable Available Market): 접근 가능한 시장
  ↓
SOM (Serviceable Obtainable Market): 실제 점유 가능한 시장
```

**현실적 목표 설정:**
```javascript
// 항공권 시장 분석
const market = {
  TAM: {
    size: 100_000_000,  // 연간 해외 여행자 1억 명
    desc: '전 세계 항공권 시장'
  },
  SAM: {
    size: 5_000_000,    // 한국인 일본 여행자 500만 명
    desc: '한국인 일본 여행 시장'
  },
  SOM: {
    size: 50_000,       // 현실적 1년차 목표 5만 명
    desc: '주말 가족 일본 여행 + 우리 서비스 도달 가능'
  }
}

// 목표 설정
const goal = {
  year1: market.SOM.size,           // 5만 명
  year2: market.SOM.size * 5,       // 25만 명
  year3: market.SAM.size * 0.1,     // 50만 명 (SAM의 10%)
  revenue: {
    per_booking: 5_000,  // 건당 수수료 5천원
    year1: 50_000 * 5_000 = 250_000_000  // 2.5억
  }
}
```

### 핵심 Takeaways

1. **타깃 우선**: "모든 사람"보다 "특정 세그먼트"가 강력
2. **문제에서 출발**: 마케팅이 아닌 제품 관점으로 시작
3. **MVP 철저히**: 타깃에 집중, 불필요한 기능 과감히 제거
4. **현실적 목표**: SOM 기준으로 실현 가능한 숫자 설정

---

## 🤖 섹션 3: AI 프롬프팅 마스터리

**출처:** 스탠퍼드 연구 - AI 창의성 문제 해결법
**핵심 학습:** 언어화된 샘플링으로 AI 창의성 2.1배 향상

### 문제: 모드 붕괴 (Mode Collapse)

**정의:**
```
AI가 데이터의 다양성을 활용하지 못하고
"가장 안전하고 무난한" 결과만 반복하는 현상
```

**증상:**
```
사용자: "커피 농담 5개 만들어줘"

AI:
1. "커피 없이는 못 살아요"
2. "커피가 내 인생의 전부"
3. "커피는 내 친구"
4. "커피 한잔의 여유"
5. "커피 향이 좋아요"

→ 전부 비슷한 패턴!
```

### 근본 원인: 전형성 편향

**스탠퍼드 연구 발견:**
```
문제의 원인은 모델이 아니라 인간의 학습 데이터 선택

인간 평가자가 선호하는 답변:
✅ 무난함
✅ 안전함
✅ 보편적

AI 학습 결과:
→ 안전한 패턴만 반복
```

### 해결책: 언어화된 샘플링 (Verbalized Sampling)

**핵심 아이디어:**
```
AI에게 여러 옵션과 함께
각각의 선택 확률을 언어로 표현하도록 요청
```

**기본 형태:**
```
[기존]
"커피 농담 5개 써줘"

[개선]
"커피 농담 5개와 각각의 선택 확률(0-100%)을 함께 알려줘"
```

### 실전 적용 예시

#### 예시 1: ChatGPT - 환경 캠페인 슬로건

**일반 프롬프트:**
```
환경 보호 캠페인 슬로건 10개 만들어줘
```

**결과 (모드 붕괴):**
```
1. "지구를 지키자"
2. "환경을 보호하자"
3. "깨끗한 지구 만들기"
4. "지구가 우리의 미래"
5. "환경 보호는 우리의 책임"
... (비슷한 패턴 반복)
```

**언어화된 샘플링 프롬프트:**
```
환경 보호 캠페인 슬로건 10개를 만들어줘.
각 슬로건마다 다음 정보를 함께 제공해줘:
1. 슬로건 텍스트
2. 이 슬로건을 선택할 확률 (0-100%)
3. 확률을 그렇게 책정한 이유
```

**결과 (다양성 향상):**
```
1. "플라스틱 대신 미래를 선택하세요" (80%)
   이유: 직접적인 행동 촉구 + 미래 지향적

2. "멈추면 보인다, 지구의 신호" (75%)
   이유: 시적 표현 + 성찰 유도

3. "1℃가 바꾸는 세상" (70%)
   이유: 구체적 수치 + 임팩트 강조

4. "오늘의 선택, 내일의 날씨" (85%)
   이유: 인과관계 명확 + 일상적 연결

5. "RE:세상" (60%)
   이유: 말장난 + 재활용 메타포 (리스크: 이해 어려울 수 있음)
```

#### 예시 2: Gemini - 서비스명 제안

**일반 프롬프트:**
```
AI 기반 학습 플랫폼 서비스명 추천해줘
```

**결과:**
```
1. "에듀AI"
2. "스마트런"
3. "런메이트"
4. "에듀플러스"
... (평범한 조합)
```

**언어화된 샘플링 프롬프트:**
```
AI 기반 학습 플랫폼 서비스명을 추천해줘.
각 이름마다:
1. 서비스명
2. 선택 확률 (0-100%)
3. 타깃 고객에게 어필할 가능성
4. 도메인 확보 가능성 예측
5. 발음 난이도 (1-10점)
```

**결과 (기획자 모드):**
```
1. "큐리어스" (Curious) - 75%
   - 타깃 어필: 높음 (호기심 자극)
   - 도메인: curious.ai 가능성 중간
   - 발음: 8/10 (쉬움)
   - 특징: 학습의 본질(호기심) 강조

2. "시냅스허브" (SynapseHub) - 60%
   - 타깃 어필: 중간 (뇌과학 메타포)
   - 도메인: 경쟁 가능성 있음
   - 발음: 6/10 (다소 복잡)
   - 특징: AI + 학습 연결 명확, B2B 느낌

3. "오늘잘" - 85%
   - 타깃 어필: 매우 높음 (친근함)
   - 도메인: .kr 확보 가능
   - 발음: 10/10 (매우 쉬움)
   - 특징: "오늘 잘 배웠니?" 중의적 표현

→ AI가 설득 구조를 설명하는 기획자 역할로 진화
```

#### 예시 3: Claude - 인터뷰 질문 설계

**일반 프롬프트:**
```
사용자 인터뷰 질문 10개 만들어줘 (쇼핑몰 앱)
```

**결과:**
```
1. "쇼핑몰 앱을 자주 사용하시나요?"
2. "어떤 기능을 가장 많이 사용하시나요?"
3. "불편한 점이 있나요?"
... (표면적 질문)
```

**언어화된 샘플링 프롬프트:**
```
쇼핑몰 앱 사용자 인터뷰 질문 10개를 만들어줘.
각 질문마다:
1. 질문 텍스트
2. 이 질문의 유용도 (0-100%)
3. 기대되는 인사이트 유형
4. 후속 질문 예시
```

**결과 (심화 질문으로 자동 전환):**
```
1. "최근 구매에서 만족/후회한 경험을 각각 말씀해주세요" (90%)
   기대 인사이트: 구매 결정 요인, 기대 vs 현실 갭
   후속 질문: "그 경험이 다음 구매에 어떤 영향을 주었나요?"

2. "앱을 열었다가 바로 닫은 적이 있나요? 그 이유는?" (85%)
   기대 인사이트: UX 장벽, 첫 화면 문제
   후속 질문: "어떤 화면이었다면 계속 사용했을까요?"

3. "타 쇼핑몰 앱 vs 우리 앱, 전환하게 만드는 결정적 차이는?" (88%)
   기대 인사이트: 경쟁 우위, 핵심 가치
   후속 질문: "그 차이를 친구에게 어떻게 설명하시겠어요?"
```

### 고급 활용: 확률 기반 브레인스토밍

**프롬프트 템플릿:**
```
[주제]에 대한 아이디어를 브레인스토밍해줘.

각 아이디어마다 다음 정보를 제공해줘:
1. 아이디어 설명
2. 실현 가능성 (0-100%)
3. 예상 임팩트 (0-100%)
4. 필요한 리소스 (시간, 비용, 인력)
5. 리스크 요인
6. 첫 실행 단계 3가지

그리고 모든 아이디어를 "실현 가능성 × 임팩트" 점수로 정렬해줘.
```

**실제 사용 예시:**
```
주제: "앱 재방문율을 높이는 방법"

AI 응답:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. 개인화 푸시 알림 시스템 (점수: 72점)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   실현 가능성: 80%
   예상 임팩트: 90%

   필요 리소스:
   - 시간: 4주
   - 비용: 500만원 (FCM + 분석 도구)
   - 인력: 개발 1명 + 마케터 0.5명

   리스크:
   - 과도한 푸시로 인한 앱 삭제
   - 개인정보 보호 이슈

   첫 실행 단계:
   1. 사용자 행동 데이터 수집 (1주)
   2. 세그먼트별 푸시 시나리오 설계 (1주)
   3. A/B 테스트로 최적 타이밍 찾기 (2주)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
2. 일일 미션/리워드 시스템 (점수: 64점)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   실현 가능성: 70%
   예상 임팩트: 85%
   (이하 동일 형식...)

→ 즉시 실행 가능한 우선순위 목록 완성
```

### 프롬프트 템플릿 모음

#### 창의적 글쓰기
```
[주제]에 대한 [형식] 5개를 작성해줘.
각각:
- 텍스트
- 선택 확률 (0-100%)
- 톤앤매너 설명
- 타깃 독자 반응 예측
```

#### 기술적 의사결정
```
[문제]를 해결하기 위한 기술 스택을 제안해줘.
각 옵션마다:
- 기술 스택 조합
- 추천 확률 (0-100%)
- 장단점
- 학습 곡선 (1-10)
- 3년 후 유지보수 전망
```

#### 디자인 방향성
```
[서비스]의 디자인 컨셉을 제안해줘.
각 컨셉마다:
- 컨셉명 + 무드보드 키워드
- 채택 확률 (0-100%)
- 타깃 사용자 어필도
- 구현 난이도
- 참고 사례 3개
```

### 실험 결과 (스탠퍼드 연구)

**정량적 성과:**
```
창의적 글쓰기:     다양성 2.1배 증가
사실적 작업:       정확도 유지 (96% → 95%)
안전성:           유해 콘텐츠 0% 유지
모델 성능:        GPT-4 > GPT-3.5 (효과 차이 큼)
```

**질적 변화:**
```
Before: "AI = 도구"
- 답변 받기
- 선택하기

After: "AI = 사고의 파트너"
- 확률적 사고 과정 공유
- 트레이드오프 이해
- 의사결정 근거 제시
```

### 핵심 Takeaways

1. **확률 요청**: "각각의 확률을 알려줘" 한 문장 추가로 2.1배 향상
2. **이유 질문**: "왜 그 확률인지" 물으면 AI가 심화 사고
3. **메타 정보**: 확률 외에도 "리스크", "리소스", "다음 단계" 요청
4. **고성능 모델**: GPT-4, Claude Opus, Gemini Pro에서 효과 극대화

---

## 🚀 섹션 4: 프론트엔드 트렌드 대응

**출처:** 2026년 프론트엔드 트렌드 총정리
**핵심 학습:** Server-First, 엣지, AI 도구의 삼각 축

### 트렌드 1: Server-First 패러다임

#### React 19 & 서버 컴포넌트

**패러다임 전환:**
```
[기존] Client-First
- 모든 컴포넌트가 클라이언트에서 실행
- 데이터 페칭: useEffect + fetch
- 번들 크기 비대화

[2026] Server-First
- 기본적으로 서버 컴포넌트
- 데이터 페칭: 서버에서 직접
- 클라이언트 번들 최소화
```

**성과 지표:**
```
TTI (Time to Interactive):   30% 이상 단축
번들 사이즈:                최대 45% 감소
서버 부하:                  20% 증가 (트레이드오프)
```

**마이그레이션 가이드:**
```jsx
// Before: 클라이언트 컴포넌트
'use client'

export default function UserProfile({ userId }) {
  const [user, setUser] = useState(null)

  useEffect(() => {
    fetch(`/api/users/${userId}`)
      .then(res => res.json())
      .then(setUser)
  }, [userId])

  if (!user) return <div>Loading...</div>

  return <div>{user.name}</div>
}

// After: 서버 컴포넌트 (기본)
export default async function UserProfile({ userId }) {
  // 서버에서 직접 데이터 페칭
  const user = await db.query('SELECT * FROM users WHERE id = $1', [userId])

  return <div>{user.name}</div>
}

// 상호작용 필요 시에만 클라이언트 컴포넌트
'use client'

export default function LikeButton({ postId }) {
  const [liked, setLiked] = useState(false)

  return (
    <button onClick={() => setLiked(!liked)}>
      {liked ? '❤️' : '🤍'}
    </button>
  )
}
```

**Actions 패턴:**
```jsx
// Server Action (서버에서 실행)
'use server'

export async function updateUser(formData) {
  const name = formData.get('name')

  await db.query('UPDATE users SET name = $1', [name])

  revalidatePath('/profile')  // 캐시 무효화
}

// 클라이언트에서 호출
'use client'

import { updateUser } from './actions'

export default function ProfileForm() {
  return (
    <form action={updateUser}>
      <input name="name" />
      <button type="submit">저장</button>
    </form>
  )
}
```

#### Next.js 15/16 & 터보팩

**Rust 기반 번들러:**
```
Webpack (JavaScript) → Turbopack (Rust)

성능 개선:
- 콜드 스타트: 53% 단축
- HMR 반응 속도: 최대 10배 향상
- 대규모 프로젝트: 특히 큰 효과
```

**Next.js 16 "use cache" API:**
```jsx
// 컴포넌트 단위 캐시
'use cache'

export default async function ProductList({ category }) {
  const products = await db.query(
    'SELECT * FROM products WHERE category = $1',
    [category]
  )

  return products.map(p => <ProductCard key={p.id} {...p} />)
}

// 도메인 단위 캐시 설정
export const cacheConfig = {
  ttl: 3600,              // 1시간
  tags: ['products'],     // 무효화 태그
  revalidate: 'on-demand' // 수동 갱신
}
```

#### TypeScript & 런타임 안전성

**E2E 타입 안정성:**
```typescript
// 1. API 스키마 정의 (Zod)
import { z } from 'zod'

export const UserSchema = z.object({
  id: z.number(),
  name: z.string(),
  email: z.string().email(),
  createdAt: z.date()
})

export type User = z.infer<typeof UserSchema>

// 2. API 엔드포인트 (tRPC)
import { createTRPCRouter, publicProcedure } from '~/server/trpc'

export const userRouter = createTRPCRouter({
  getById: publicProcedure
    .input(z.object({ id: z.number() }))
    .output(UserSchema)
    .query(async ({ input }) => {
      const user = await db.users.findUnique({ where: { id: input.id } })
      return UserSchema.parse(user)  // 런타임 검증
    })
})

// 3. 프론트엔드 사용 (자동 타입 추론)
import { trpc } from '~/utils/trpc'

function UserProfile({ id }: { id: number }) {
  const { data: user } = trpc.user.getById.useQuery({ id })
  //     ^? type User = { id: number, name: string, ... }

  return <div>{user.name}</div>  // 타입 안전
}
```

**Valibot (경량 대안):**
```typescript
import * as v from 'valibot'

// Zod보다 번들 사이즈 70% 작음
const UserSchema = v.object({
  id: v.number(),
  name: v.string(),
  email: v.pipe(v.string(), v.email())
})

type User = v.InferOutput<typeof UserSchema>
```

### 트렌드 2: 엣지 & 마이크로 아키텍처

#### 엣지 컴퓨팅

**Cloudflare Workers 예시:**
```typescript
// 엣지에서 실행 (50ms 미만 레이턴시)
export default {
  async fetch(request: Request) {
    const country = request.cf?.country

    // GeoIP 기반 통화 변환
    const currency = country === 'KR' ? 'KRW' :
                    country === 'JP' ? 'JPY' : 'USD'

    // 원본 요청에 헤더 추가
    const modifiedRequest = new Request(request, {
      headers: {
        ...request.headers,
        'X-Currency': currency
      }
    })

    return fetch(modifiedRequest)
  }
}
```

**Vercel Edge Middleware:**
```typescript
// middleware.ts
import { NextResponse } from 'next/server'

export function middleware(request: NextRequest) {
  // A/B 테스트 분기
  const bucket = Math.random()
  const variant = bucket < 0.5 ? 'A' : 'B'

  const response = NextResponse.next()
  response.cookies.set('variant', variant)

  return response
}
```

**ISR + 온디맨드 재검증:**
```jsx
// pages/products/[id].tsx
export async function getStaticProps({ params }) {
  const product = await db.products.findUnique({ where: { id: params.id } })

  return {
    props: { product },
    revalidate: 3600  // 1시간마다 재생성
  }
}

// API 라우트로 온디맨드 재검증
// pages/api/revalidate.ts
export default async function handler(req, res) {
  await res.revalidate(`/products/${req.body.productId}`)
  return res.json({ revalidated: true })
}
```

#### 마이크로 프론트엔드

**모듈 페더레이션 (Rspack):**
```javascript
// rspack.config.js (호스트 앱)
module.exports = {
  plugins: [
    new ModuleFederationPlugin({
      name: 'host',
      remotes: {
        cart: 'cart@http://localhost:3001/remoteEntry.js',
        payment: 'payment@http://localhost:3002/remoteEntry.js',
        reviews: 'reviews@http://localhost:3003/remoteEntry.js'
      },
      shared: {
        react: { singleton: true },
        'react-dom': { singleton: true }
      }
    })
  ]
}

// 사용
import Cart from 'cart/Cart'
import Payment from 'payment/Payment'
import Reviews from 'reviews/ReviewList'

function App() {
  return (
    <>
      <Cart />
      <Payment />
      <Reviews />
    </>
  )
}
```

**공통 디자인 시스템:**
```typescript
// packages/design-system/src/Button.tsx
export interface ButtonProps {
  variant: 'primary' | 'secondary'
  size: 'sm' | 'md' | 'lg'
  onClick: () => void
}

export const Button: React.FC<ButtonProps> = ({ variant, size, onClick, children }) => {
  return (
    <button
      className={`btn btn-${variant} btn-${size}`}
      onClick={onClick}
    >
      {children}
    </button>
  )
}

// 각 마이크로 앱에서 공유
import { Button } from '@company/design-system'
```

#### BFF (Backend for Frontend)

**tRPC 예시:**
```typescript
// server/routers/app.ts
export const appRouter = createTRPCRouter({
  user: userRouter,
  product: productRouter,
  order: orderRouter
})

export type AppRouter = typeof appRouter

// 프론트엔드
import { trpc } from '~/utils/trpc'

function Component() {
  // 백엔드 함수 = 프론트엔드 API 호출
  const { data } = trpc.user.getProfile.useQuery()
  const mutation = trpc.order.create.useMutation()

  // 타입 안전 + API 문서 불필요
}
```

### 트렌드 3: AI Native 개발

#### AI Native IDE

**Cursor 활용:**
```
멀티 파일 컨텍스트 이해 능력

예시 작업:
"UserService.ts의 getProfile 함수를
 UserController.ts와 연결하고
 React 컴포넌트에서 호출할 수 있게 해줘"

→ 3개 파일 동시 수정
→ 레거시 코드 분석 시간 60% 단축
```

**2026년 개발 워크플로우:**
```
[기존] 작성(Writing) 중심
- 코드 타이핑
- 문법 검색
- 디버깅

[2026] 검토(Reviewing) + 조립(Composing)
- AI가 코드 생성
- 개발자가 검토
- 로직 조립
```

#### Design-to-Code 자동화

**Figma Dev Mode + v0:**
```
디자이너 시안 (Figma)
  ↓ 자동 변환
상용 수준 코드
  ├─ Shadcn UI
  ├─ Tailwind CSS
  └─ React Hook Form

→ 퍼블리싱 업무 80% 자동화
```

**개발자 역할 변화:**
```
Before: 디자인 → 퍼블리싱 → 로직 → 통합
After:  디자인 → [AI 퍼블리싱] → 로직 연결
```

#### AI Agent 품질 관리

**CodeRabbit:**
```yaml
# .coderabbit.yaml
reviews:
  auto_review: true

  checks:
    - name: "Unit Test Coverage"
      threshold: 80
      auto_fix: true  # 자동으로 테스트 생성

    - name: "Security Vulnerabilities"
      severity: high
      block_merge: true

    - name: "Performance Bottleneck"
      analyze: true
      suggest_optimization: true
```

**Shift Left Testing:**
```
[기존] QA 단계에서 버그 발견
개발 완료 → QA 테스트 → 버그 발견 → 수정 → 재테스트

[2026] 개발 단계에서 사전 감지
PR 생성 → AI 자동 리뷰 → 버그 사전 차단 → QA 통과율 향상
```

### 개발자 역할 변화

**요구 역량 변화:**
```
[2025 이전]
- 코딩 능력 80%
- 인프라 이해 20%

[2026]
- 코딩 능력 40% (AI 보조)
- 인프라 운영 40% (CI/CD, Docker, 클라우드)
- 아키텍처 설계 20%
```

**채용 공고 트렌드:**
```
필수 역량 (40% 이상 요구):
✅ CI/CD 파이프라인 구축
✅ Docker 컨테이너화
✅ AWS/Vercel 배포 경험
✅ 모니터링 & 로깅
```

### 핵심 Takeaways

1. **Server-First**: 기본은 서버 컴포넌트, 필요시에만 클라이언트
2. **엣지 활용**: 지역별 최적화, A/B 테스트를 엣지에서
3. **AI 도구**: 코딩 시간 감소, 설계 시간 증가
4. **풀스택 능력**: 인프라 이해 필수
5. **본질 이해**: 도구 선택의 이유와 한계 파악

---

## ⚡ 섹션 5: 긴급 개발 생존 전략

**출처:** Claude Code로 3일 만에 서비스 중단 위기 해결
**핵심 학습:** 문서화 전략 + 리포트 기반 협업

### 배경 상황

**위기:**
```
외부 실시간 투표 프로그램 정책 변경
→ 임베딩 제한
→ 의료 심포지엄 일주일 전
→ "해결 못하면 손배청구"
```

**제약 조건:**
```
개발자: 비전공자 출신, 백엔드 경험 없음
기간: 3일
기술: 기존 인프라만 사용 (Redis, MySQL, SSE)
```

### 전략 1: 문서 중심 개발

#### 1단계: 시나리오 문서 작성

**사용자 시나리오:**
```markdown
# 사용자 시나리오

## 시나리오 1: 투표 참여
1. 사용자가 QR 코드 스캔
2. 투표 페이지 접속
3. 선택지 선택
4. 제출 버튼 클릭
5. 실시간 결과 확인

## 시나리오 2: 실시간 결과 확인
1. 투표 제출 후 자동 전환
2. 실시간 그래프 표시
3. 다른 사용자 투표 시 자동 업데이트
4. 최종 결과 확정 시 애니메이션

## 시나리오 3: 중복 투표 방지
1. 동일 IP에서 재접속
2. "이미 투표하셨습니다" 메시지
3. 현재 결과만 확인 가능
```

**관리자 시나리오:**
```markdown
# 관리자 시나리오

## CRUD 요구사항

### Create (생성)
- 투표 주제 입력
- 선택지 추가 (2-6개)
- 시작/종료 시간 설정
- QR 코드 자동 생성

### Read (조회)
- 진행 중 투표 목록
- 실시간 참여 현황
- 선택지별 득표 수
- 참여자 IP 로그

### Update (수정)
- 투표 종료 전까지 선택지 수정 가능
- 종료 시간 연장

### Delete (삭제)
- 투표 삭제 (참여자 0명일 때만)
- 참여 데이터 일괄 삭제 (관리자 권한)
```

#### 2단계: CLAUDE.md 생성

**초기 버전 (500줄):**
```markdown
# CLAUDE.md

## 프로젝트 개요
실시간 투표 시스템

## 기술 스택
- Frontend: React, Vite
- Backend: Node.js, Express
- Database: MySQL
- Cache: Redis
- Realtime: SSE (Server-Sent Events)

## 디렉토리 구조
src/
├── client/
│   ├── components/
│   ├── pages/
│   └── utils/
└── server/
    ├── routes/
    ├── controllers/
    └── services/

## API 엔드포인트

### POST /api/votes
투표 제출
Request:
{
  "pollId": "number",
  "choiceId": "number"
}
Response:
{
  "success": "boolean",
  "message": "string"
}

### GET /api/polls/:id/results
실시간 결과 조회
Response:
{
  "poll": {
    "id": "number",
    "title": "string",
    "choices": [
      { "id": "number", "text": "string", "votes": "number" }
    ]
  }
}

### GET /api/polls/:id/stream
SSE 스트림
Events:
- vote-update: { "choiceId": "number", "newCount": "number" }
- poll-end: { "pollId": "number", "finalResults": {...} }

## 데이터베이스 스키마

CREATE TABLE polls (
  id INT PRIMARY KEY AUTO_INCREMENT,
  title VARCHAR(255),
  start_time DATETIME,
  end_time DATETIME,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE choices (
  id INT PRIMARY KEY AUTO_INCREMENT,
  poll_id INT,
  text VARCHAR(255),
  FOREIGN KEY (poll_id) REFERENCES polls(id)
);

CREATE TABLE votes (
  id INT PRIMARY KEY AUTO_INCREMENT,
  poll_id INT,
  choice_id INT,
  ip_address VARCHAR(45),
  voted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (poll_id) REFERENCES polls(id),
  FOREIGN KEY (choice_id) REFERENCES choices(id),
  UNIQUE KEY unique_vote (poll_id, ip_address)
);

## Redis 캐시 전략

# 실시간 결과 캐시 (TTL: 10초)
poll:{pollId}:results → { "choice1": 45, "choice2": 32, ... }

# 중복 투표 방지 (TTL: 투표 종료 시까지)
poll:{pollId}:voted:{ip} → "1"

# SSE 연결 관리
poll:{pollId}:connections → Set<connectionId>

## 에러 처리

- 중복 투표: 409 Conflict
- 투표 종료: 410 Gone
- 잘못된 선택지: 400 Bad Request
- 서버 오류: 500 Internal Server Error

## 보안 고려사항

- IP 기반 중복 방지 (단순하지만 효과적)
- Rate limiting (IP당 초당 5회)
- SQL Injection 방지 (Prepared Statements)
- XSS 방지 (입력값 sanitize)

## 성능 목표

- 동시 접속: 500명
- 투표 처리 시간: 100ms 이하
- SSE 업데이트 지연: 50ms 이하
```

**문제점:**
- 장시간 실행 시 Claude가 문자열 버그 발생
- 최종 2,000줄로 팽창 → 성능 저하

#### 3단계: 문서 압축 (2,046줄 → 359줄)

**압축 전략:**
```markdown
# CLAUDE.md (압축 버전)

## 핵심 컨텍스트
실시간 투표, Redis 캐시, SSE 스트림, MySQL, 3일 개발

## 스택
React, Express, MySQL, Redis, SSE

## 구조
client/(components,pages,utils), server/(routes,controllers,services)

## 핵심 API
POST /api/votes: {pollId,choiceId} → {success,message}
GET /api/polls/:id/results → {poll:{choices:[{votes}]}}
GET /api/polls/:id/stream → SSE: vote-update, poll-end

## DB (핵심만)
polls(id,title,start_time,end_time)
choices(id,poll_id,text)
votes(id,poll_id,choice_id,ip_address) UNIQUE(poll_id,ip_address)

## Redis
poll:{id}:results → {choice1:45,...} TTL:10s
poll:{id}:voted:{ip} → "1"

## 에러
409: 중복, 410: 종료, 400: 잘못된 입력

## 목표
500 동시 접속, 100ms 처리, 50ms SSE
```

**압축률: 82% (2,046줄 → 359줄)**

**압축 원칙:**
1. **중복 제거**: 같은 내용 반복 금지
2. **핵심만**: "Claude가 이해하는 데 필요한 최소한"
3. **구조화**: 계층적으로 정리
4. **약어 활용**: 자주 쓰는 용어는 축약

### 전략 2: 리포트 기반 협업

#### 프론트엔드 → 백엔드 리포트

**리포트 구조:**
```markdown
# API 요청 리포트 (프론트엔드 → 백엔드)

## 오류 상황
투표 제출 시 409 Conflict 발생 (중복 투표 아닌데도)

## 작업 환경
- URL: http://localhost:3000/poll/123
- 브라우저: Chrome 120
- IP: 192.168.1.100

## API 엔드포인트
POST /api/votes

## 요청 데이터
{
  "pollId": 123,
  "choiceId": 1
}

## 응답
Status: 409 Conflict
Body: { "error": "Already voted" }

## 요청사항
1. 중복 투표 체크 로직 확인 필요
2. Redis 키 TTL 확인 필요
3. 테스트 모드 추가 요청 (중복 체크 우회)
```

#### 백엔드 → 프론트엔드 리포트

**회신 구조:**
```markdown
# API 수정 완료 리포트 (백엔드 → 프론트엔드)

## 원인 분석
Redis 키 생성 시 IP 형식 불일치
- 저장: "192.168.1.100"
- 조회: "::ffff:192.168.1.100" (IPv6 매핑)

## 수정 내용
IP 정규화 함수 추가
```javascript
function normalizeIP(ip) {
  return ip.replace(/^::ffff:/, '')
}
```

## API 명세 업데이트

### POST /api/votes
**Request:**
```json
{
  "pollId": number,
  "choiceId": number,
  "testMode": boolean  // 새로 추가 (개발 환경만)
}
```

**Response (성공):**
```json
{
  "success": true,
  "message": "Vote recorded"
}
```

**Response (중복):**
```json
{
  "success": false,
  "error": "Already voted",
  "votedAt": "2026-01-08T10:30:00Z"  // 이전 투표 시간 추가
}
```

## 테스트 방법
```bash
# 개발 환경에서 중복 체크 우회
curl -X POST http://localhost:3001/api/votes \
  -H "Content-Type: application/json" \
  -d '{"pollId":123,"choiceId":1,"testMode":true}'
```

## 다음 단계
프론트엔드에서:
1. 중복 투표 시 `votedAt` 표시
2. 개발 환경에서 `testMode` 옵션 추가
```

### 전략 3: 압축-검수-수정 사이클

**반복 프로세스:**
```
1. Claude가 코드 생성
   ↓
2. 개발자가 실행 & 테스트
   ↓
3. 오류 발생 시 리포트 작성
   ↓
4. Claude가 리포트 읽고 수정
   ↓
5. 반복 (평균 10-15회)
```

**빠른 반복의 비결:**
```
전통적 협업:
- 개발자 A: "여기 버그 있어요"
- 개발자 B: "어디요? 재현 방법은?"
- A: "이렇게 하면..."
- B: "아 이해했어요. 고칠게요"
→ 소통 시간 30분

리포트 협업:
- 프론트 Claude: 리포트 작성 (2분)
- 백엔드 Claude: 리포트 읽고 수정 (5분)
→ 소통 시간 0분, 총 7분
```

### 결과

**달성:**
```
✅ 3일 만에 실시간 투표 시스템 완성
✅ 500명 동시 접속 테스트 통과
✅ 심포지엄 당일 성공적 운영
✅ 손배청구 위기 회피
```

**학습:**
```
1. 문서 품질 > 문서 양
   - 2,000줄 → 359줄 압축으로 성능 향상

2. 요구사항 명확성
   - 시나리오 문서가 개발 방향 결정

3. 구조화된 협업
   - 리포트 형식이 실시간 대화보다 효율적

4. 점진적 개선
   - 완벽한 계획보다 빠른 반복이 중요
```

### 재사용 가능한 템플릿

#### API 요청 리포트 템플릿
```markdown
# API 요청 리포트

## 오류 상황
[상황 설명]

## 작업 환경
- URL: [URL]
- 브라우저: [브라우저]
- 기타: [추가 정보]

## API 엔드포인트
[METHOD] [PATH]

## 요청 데이터
```json
[요청 본문]
```

## 응답
Status: [상태 코드]
Body:
```json
[응답 본문]
```

## 요청사항
1. [요청 1]
2. [요청 2]
```

#### 문서 압축 체크리스트
```markdown
# 문서 압축 체크리스트

- [ ] 중복 내용 제거
- [ ] 예시 코드 최소화 (핵심만)
- [ ] 설명 → 키워드 변환
- [ ] 계층 구조 명확히
- [ ] 약어 활용 (일관성 유지)
- [ ] 1,000줄 이하 목표
```

### 핵심 Takeaways

1. **문서 압축**: 2,000줄 → 359줄 = 성능 5배 향상
2. **리포트 협업**: 구조화된 의사소통이 실시간보다 빠름
3. **빠른 반복**: 완벽한 계획보다 10-15회 개선 사이클
4. **AI 활용**: 요구사항만 명확하면 비전공자도 3일 개발 가능

---

## 🎯 통합 활용 가이드

### 상황별 섹션 선택

| 상황 | 섹션 | 핵심 전략 |
|------|------|----------|
| 라이브러리/프레임워크 개발 | 섹션 1 | 성능 vs 자연스러움 하이브리드 접근 |
| 신규 서비스 기획 | 섹션 2 | GTM 타깃 세그먼트 우선 |
| AI 활용도 낮음 | 섹션 3 | 언어화된 샘플링 프롬프팅 |
| 기술 스택 선정 | 섹션 4 | Server-First + 엣지 고려 |
| 긴급 개발 필요 | 섹션 5 | 문서 압축 + 리포트 협업 |

### 조합 활용 예시

#### 예시 1: 신규 SaaS 제품 개발

```bash
# 1단계: 제품 전략 수립 (섹션 2)
/auto "GTM 전략으로 타깃 고객 정의하고 MVP 기능 추출해줘"

# 2단계: 기술 스택 선정 (섹션 4)
/auto "Server-First 패러다임으로 React 19 + Next.js 16 스택 구성해줘"

# 3단계: AI로 빠른 개발 (섹션 3, 5)
/auto "언어화된 샘플링으로 다양한 UI 컨셉 제안받고
      리포트 협업 방식으로 프론트-백엔드 개발해줘"

# 4단계: 성능 최적화 (섹션 1)
/auto "성능 병목 지점 분석하고 하이브리드 최적화 적용해줘"
```

#### 예시 2: 레거시 시스템 개선

```bash
# 1단계: 현황 분석 (섹션 3)
/auto "레거시 코드베이스 분석하고 개선점을 확률과 함께 제시해줘"

# 2단계: 점진적 마이그레이션 (섹션 4)
/auto "마이크로 프론트엔드 구조로 점진적 전환 계획 수립해줘"

# 3단계: 문서화 (섹션 5)
/auto "CLAUDE.md 형식으로 시스템 문서 압축해서 만들어줘"
```

#### 예시 3: 긴급 버그 수정

```bash
# 1단계: 문제 정의 (공통 원칙)
/auto "버그 재현 시나리오와 예상 원인을 분석해줘"

# 2단계: 빠른 수정 (섹션 5)
/auto "리포트 형식으로 버그 정보 정리하고 수정 방안 제시해줘"

# 3단계: 재발 방지 (섹션 1, 4)
/auto "테스트 자동화 + AI Agent 품질 관리 설정해줘"
```

---

## 💡 핵심 Takeaways (전체)

### 1. 문제 정의가 80%
```
"문제를 명확히 정의하면 해결책은 자연스럽게 나온다"

- 애니메이션: 성능 vs 자연스러움 → 하이브리드
- GTM: 모든 사람 vs 타깃 세그먼트 → 집중
- AI: 모드 붕괴 → 확률 요청
- 긴급 개발: 복잡한 소통 → 리포트 협업
```

### 2. 도구는 수단, 본질은 문제 해결
```
"최신 기술 < 적절한 기술"

- MutationObserver: 오래되었지만 프레임워크 독립적
- Redis: 단순하지만 실시간 투표에 충분
- 확률 프롬프트: 새로운 API 아니고 프롬프트 한 줄
```

### 3. 점진적 개선 > 완벽한 계획
```
"빠르게 시도하고 반복하라"

- 애니메이션: 시뮬레이션 → 키프레임 변환 실험
- 문서: 2,000줄 → 359줄 압축 반복
- 개발: 10-15회 수정 사이클
```

### 4. AI는 파트너, 대체자 아님
```
"AI가 코드 작성, 인간이 검토와 조립"

- 2026년 개발 = 검토(Reviewing) + 조립(Composing)
- 요구사항 정의는 여전히 인간의 영역
- AI가 제안, 인간이 최종 판단
```

### 5. 문서화는 투자, 비용 아님
```
"좋은 문서 = 빠른 개발 + 쉬운 유지보수"

- CLAUDE.md: 팀 지식 축적
- 압축 문서: AI 성능 5배 향상
- 리포트: 소통 시간 0분
```

---

## 🤖 섹션 6: AI 에이전트 오케스트레이션

**출처:** 와탭랩스 - AI 에이전트 오케스트레이션 4단계 실전 가이드
**핵심 학습:** Tmux + LangGraph로 99% 자동화 달성

### 문제 정의

**초기 상황:**
```
여러 터미널에서 AI 에이전트 실행
→ 수동으로 결과 복사-붙여넣기
→ 대기 시간 낭비
→ 실수 가능성

목표: "복사-붙여넣기를 기다릴 필요 없이 자동화"
```

### 4단계 진화 과정

#### Stage 1: Tmux 기반 에이전트 통신

**Tmux란?**
```
터미널 멀티플렉서
= 하나의 터미널에서 여러 세션을 동시에 관리하는 도구
```

**핵심 명령어:**

**1. send-keys**: 한 세션에서 다른 세션으로 메시지 자동 전송

```bash
# Dev 에이전트에서 QA 에이전트로 메시지 전송
tmux send-keys -t qa-session "검토해줘: $(cat dev-output.txt)" Enter
```

**2. capture-pane**: 세션의 화면 내용 캡처

```bash
# QA 에이전트의 결과 캡처
tmux capture-pane -t qa-session -p > qa-result.txt
```

**작동 방식:**
```
Dev 에이전트 (tmux session: dev)
  ↓ send-keys
QA 에이전트 (tmux session: qa) 자동 실행
  ↓ capture-pane
결과 캡처 → Dev에게 전달
```

**설정 방법:**

CLAUDE.md에 Tmux 가이드 작성:
```markdown
# CLAUDE.md (Dev 에이전트)

## Tmux 통신 가이드

### QA 에이전트에게 전달하기
1. 작업 완료 후 결과를 `/tmp/dev-output.txt`에 저장
2. QA 세션에 send-keys:
   ```bash
   tmux send-keys -t qa "검토 요청: $(cat /tmp/dev-output.txt)" Enter
   ```

### QA 결과 받기
1. QA 세션의 출력을 캡처:
   ```bash
   tmux capture-pane -t qa -p > /tmp/qa-result.txt
   ```
2. 결과 읽고 수정 진행
```

**효과:**
- ✅ 수동 복사-붙여넣기 제거
- ✅ 시간 절약 확인됨
- ❌ 아직 조건 분기 없음 (성공/실패 처리 못함)

#### Stage 2: LangGraph로 조건 분기 처리

**LangGraph란?**
```
"누구에게 언제 무엇을 할지를 결정만 하는"
상태 기반 워크플로우 엔진
```

**핵심 3가지 개념:**

| 요소 | 설명 | 예시 |
|------|------|------|
| **State** | 작업 상태 및 값 저장 메모리 공간 | `{ code, test_result, retry_count }` |
| **Node** | 개별 작업 단위 | `dev_node`, `qa_node`, `deploy_node` |
| **Edge** | 성공/실패에 따른 분기 처리 로직 | `if test_pass → deploy else → dev` |

**구현 예시:**

```python
from langgraph.graph import StateGraph, END

# 1. State 정의
class WorkflowState(TypedDict):
    code: str
    test_result: dict
    retry_count: int
    max_retries: int

# 2. Node 정의
def dev_node(state: WorkflowState):
    """개발 에이전트 실행"""
    # Tmux send-keys로 Dev 에이전트 호출
    result = tmux_send_and_capture("dev", "코드 작성해줘")
    return {"code": result}

def qa_node(state: WorkflowState):
    """QA 에이전트 실행"""
    # Tmux send-keys로 QA 에이전트 호출
    result = tmux_send_and_capture("qa", f"테스트해줘: {state['code']}")
    return {"test_result": result}

def deploy_node(state: WorkflowState):
    """배포 에이전트 실행"""
    result = tmux_send_and_capture("deploy", f"배포해줘: {state['code']}")
    return {"deployed": True}

# 3. Edge 정의 (조건 분기)
def decide_next(state: WorkflowState):
    """QA 결과에 따라 다음 노드 결정"""
    if state["test_result"]["pass"]:
        return "deploy"  # 테스트 통과 → 배포
    elif state["retry_count"] < state["max_retries"]:
        return "dev"  # 재시도 가능 → 개발로 돌아감
    else:
        return END  # 최대 재시도 초과 → 종료

# 4. Graph 구성
workflow = StateGraph(WorkflowState)

# Node 추가
workflow.add_node("dev", dev_node)
workflow.add_node("qa", qa_node)
workflow.add_node("deploy", deploy_node)

# Edge 추가
workflow.add_edge("dev", "qa")  # Dev → QA는 항상
workflow.add_conditional_edges(
    "qa",
    decide_next,  # QA → deploy or dev or END
    {
        "deploy": "deploy",
        "dev": "dev",
        END: END
    }
)

# 시작점 설정
workflow.set_entry_point("dev")

# 5. 실행
app = workflow.compile()
result = app.invoke({
    "code": "",
    "test_result": {},
    "retry_count": 0,
    "max_retries": 3
})
```

**시나리오:**
```
1. Dev 에이전트가 코드 작성
   ↓
2. QA 에이전트가 테스트 실행
   ↓
3-A. 테스트 통과 → Deploy 에이전트가 배포
3-B. 테스트 실패 → Dev에게 다시 전달 (최대 3회)
3-C. 3회 실패 → 종료 (수동 개입 필요)
```

**State 활용 예시:**

```python
# 재시도 카운트 State
def dev_node(state: WorkflowState):
    # 재시도 카운트 증가
    new_state = state.copy()
    new_state["retry_count"] += 1

    # QA 피드백 반영
    if state.get("test_result"):
        feedback = state["test_result"].get("feedback", "")
        prompt = f"이전 코드: {state['code']}\n피드백: {feedback}\n수정해줘"
    else:
        prompt = "새로운 기능 구현해줘"

    result = tmux_send_and_capture("dev", prompt)
    new_state["code"] = result
    return new_state
```

**장점:**
- ✅ "프롬프트 확장 없이 복잡한 비즈니스 로직 수용"
- ✅ 조건 분기 자동 처리
- ✅ 재시도 로직 구조화
- ❌ 아직 LangGraph 관리가 수동

#### Stage 3: PM 에이전트로 오케스트레이션 자동화

**전략:**
```
LangGraph 관리 전용 PM 에이전트 생성
= "LangGraph 코드를 작성하고 실행하는 에이전트"
```

**CLAUDE.md 정의 (PM 에이전트):**
```markdown
# CLAUDE.md (PM 에이전트)

## 역할
LangGraph 워크플로우 관리 전담

## 책임 범위
- LangGraph 코드 작성
- 워크플로우 실행
- 에이전트 간 메시지 전달
- 에이전트로부터 응답 수신

## 처리하지 않는 것
- 실제 코드 작성 (Dev 에이전트가 함)
- 테스트 실행 (QA 에이전트가 함)
- 배포 작업 (Deploy 에이전트가 함)

## 통합 함수

### send_to_agent(agent_name, message)
```python
def send_to_agent(agent_name: str, message: str):
    """Tmux send-keys 통합"""
    cmd = f'tmux send-keys -t {agent_name} "{message}" Enter'
    os.system(cmd)
```

### receive_response(agent_name)
```python
def receive_response(agent_name: str) -> str:
    """Tmux capture-pane 통합"""
    cmd = f'tmux capture-pane -t {agent_name} -p'
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return result.stdout
```

## 예시 작업

### 요청: "로그인 기능 구현하고 테스트 후 배포해줘"

1. LangGraph 워크플로우 생성:
   - dev → qa → deploy

2. Dev 에이전트 호출:
   - send_to_agent("dev", "로그인 기능 구현해줘")
   - receive_response("dev")

3. QA 에이전트 호출:
   - send_to_agent("qa", f"테스트해줘: {dev_result}")
   - receive_response("qa")

4. 결과 판단:
   - 성공 → Deploy 호출
   - 실패 → Dev 재호출
```

**결과:**
- ✅ "기존의 복잡한 코드를 생성하지 않고" PM이 대신 처리
- ✅ LangGraph 지식 없어도 사용 가능
- ✅ 워크플로우 변경이 쉬움 (CLAUDE.md만 수정)

**PM 에이전트 사용 예시:**
```bash
# 사용자 → PM 에이전트
"사용자 인증 시스템을 개발하고, 테스트 통과하면 스테이징에 배포해줘"

# PM 에이전트 내부 처리
1. LangGraph 워크플로우 생성:
   auth_dev → auth_qa → staging_deploy

2. 각 노드에서 Tmux 통신:
   - send_to_agent("dev", "사용자 인증 시스템 구현")
   - 결과 받기 → QA에 전달
   - QA 결과 받기 → 성공 시 배포

3. 진행 상황 보고:
   "Dev 완료 → QA 진행 중 → QA 실패 → Dev 재작업 → QA 통과 → 배포 완료"
```

#### Stage 4: 99% 자동화

**자동화 대상:**

| 항목 | Before (수동) | After (자동) |
|------|--------------|-------------|
| 폴더 구분 | 수동 생성 | PM이 자동 생성 |
| CLAUDE.md 생성 | 수동 작성 | PM이 템플릿 기반 생성 |
| LangGraph 워크플로우 | 수동 코딩 | PM이 요구사항 기반 생성 |
| Tmux 세션 생성 | 수동 명령어 | PM이 자동 실행 |
| 클로드 실행 | 수동 트리거 | PM이 자동 시작 |

**구현:**

PM 에이전트 CLAUDE.md에 "세팅 및 실행 가이드" 추가:

```markdown
# CLAUDE.md (PM 에이전트)

## 프로젝트 자동 세팅

### 요청 형식
"[프로젝트명]을 [요구사항]으로 개발해줘"

예: "ecommerce를 React + Express로 개발해줘"

### 자동 처리 절차

#### 1. 폴더 구조 생성
```bash
mkdir -p ~/projects/ecommerce/{dev,qa,deploy}
```

#### 2. 각 폴더에 CLAUDE.md 생성

**dev/CLAUDE.md:**
```markdown
# Role: 개발 에이전트
# Tech Stack: React, Express
# Responsibilities:
- 기능 구현
- 코드 품질 유지
- QA 피드백 반영

# Communication:
- 작업 완료 시 /tmp/dev-output.txt에 결과 저장
- QA 피드백은 /tmp/qa-feedback.txt에서 읽기
```

**qa/CLAUDE.md:**
```markdown
# Role: QA 에이전트
# Responsibilities:
- 단위 테스트 작성 및 실행
- 통합 테스트 실행
- 버그 발견 시 상세 리포트 작성

# Communication:
- 테스트 결과 /tmp/qa-result.json 생성
- 피드백 /tmp/qa-feedback.txt 생성
```

**deploy/CLAUDE.md:**
```markdown
# Role: 배포 에이전트
# Responsibilities:
- 스테이징 배포
- 프로덕션 배포 (수동 승인 후)
- 배포 로그 기록
```

#### 3. Tmux 세션 생성 및 Claude 실행
```bash
# Dev 세션
tmux new-session -d -s dev -c ~/projects/ecommerce/dev
tmux send-keys -t dev "claude-code" Enter

# QA 세션
tmux new-session -d -s qa -c ~/projects/ecommerce/qa
tmux send-keys -t qa "claude-code" Enter

# Deploy 세션
tmux new-session -d -s deploy -c ~/projects/ecommerce/deploy
tmux send-keys -t deploy "claude-code" Enter
```

#### 4. LangGraph 워크플로우 생성 및 실행
```python
# PM 에이전트가 자동 생성
workflow = create_workflow(
    project_name="ecommerce",
    agents=["dev", "qa", "deploy"],
    requirements="React + Express 이커머스"
)

# 실행
workflow.invoke({"task": "쇼핑카트 기능 구현"})
```

#### 5. 진행 상황 모니터링
```
[PM] 프로젝트 세팅 완료
[PM] Dev 에이전트 시작: 쇼핑카트 기능 구현
[Dev] 구현 완료 (15분)
[PM] QA 에이전트 시작: 테스트 실행
[QA] 테스트 실패: 수량 0일 때 에러
[PM] Dev 에이전트 재작업 요청
[Dev] 수정 완료 (3분)
[PM] QA 에이전트 재테스트
[QA] 테스트 통과
[PM] Deploy 에이전트 시작: 스테이징 배포
[Deploy] 배포 완료
[PM] 전체 작업 완료 (총 20분)
```
```

**달성:**
- ✅ 프로세스 전체 관리 자동화
- ✅ "프로젝트 이름 + 요구사항"만 입력하면 끝
- ✅ 99% 자동화 (나머지 1%는 최종 승인)

**실제 사용 예시:**
```bash
# 사용자 → PM 에이전트
"블로그 시스템을 Next.js + Supabase로 만들어줘.
기능은 글 작성, 수정, 삭제, 댓글, 좋아요야."

# PM 에이전트 자동 처리
1. 프로젝트 폴더 생성 (blog/)
2. Dev, QA, Deploy 세션 자동 실행
3. LangGraph 워크플로우 생성:
   - 글 작성 → 테스트 → 배포
   - 수정 기능 → 테스트 → 배포
   - 삭제 기능 → 테스트 → 배포
   - 댓글 기능 → 테스트 → 배포
   - 좋아요 기능 → 테스트 → 배포
4. 각 기능 순차 실행
5. 전체 통합 테스트
6. 스테이징 배포

# 결과 (3시간 후)
"✅ 블로그 시스템 구현 완료
- 총 기능: 5개
- 총 테스트: 87개 (모두 통과)
- 스테이징 URL: https://staging.blog.com
- 프로덕션 배포 승인 대기 중"
```

### 주요 기술적 세부사항

#### Tmux send-keys 실행 흐름

```
A세션에서 작업 완료
  ↓
결과를 /tmp/a-output.txt에 저장
  ↓
PM이 send-keys로 B세션에 명령 전송
  ↓
B세션이 /tmp/a-output.txt 읽고 자동 실행
  ↓
PM이 capture-pane으로 결과 캡처
  ↓
결과 분석 후 다음 단계 결정
```

**실제 코드:**
```python
def run_agent_task(agent_name: str, task: str, input_file: str = None):
    """에이전트에게 작업 전달 및 결과 수신"""

    # 1. 입력 파일이 있으면 메시지에 포함
    if input_file and os.path.exists(input_file):
        with open(input_file, 'r') as f:
            context = f.read()
        message = f"{task}\n\n컨텍스트:\n{context}"
    else:
        message = task

    # 2. Tmux send-keys로 메시지 전송
    cmd = f'tmux send-keys -t {agent_name} "{message}" Enter'
    os.system(cmd)

    # 3. 에이전트 처리 대기 (간단한 폴링)
    time.sleep(5)  # 실제로는 더 정교한 완료 감지 필요

    # 4. 결과 캡처
    cmd = f'tmux capture-pane -t {agent_name} -p'
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)

    # 5. 결과 저장
    output_file = f'/tmp/{agent_name}-output.txt'
    with open(output_file, 'w') as f:
        f.write(result.stdout)

    return result.stdout
```

#### LangGraph 상태 관리 고급 예시

**복잡한 재시도 로직:**
```python
class WorkflowState(TypedDict):
    task: str
    code: str
    test_result: dict
    retry_count: int
    max_retries: int
    error_history: list  # 이전 에러 기록
    last_feedback: str

def dev_node_with_memory(state: WorkflowState):
    """이전 에러 기록을 반영한 개발"""
    new_state = state.copy()
    new_state["retry_count"] += 1

    # 에러 히스토리를 프롬프트에 포함
    if state["error_history"]:
        error_summary = "\n".join([
            f"시도 {i+1}: {err}"
            for i, err in enumerate(state["error_history"])
        ])
        prompt = f"""
이전 시도들에서 발생한 에러:
{error_summary}

현재 피드백: {state["last_feedback"]}

이번에는 이런 에러가 발생하지 않도록 수정해줘.
        """
    else:
        prompt = state["task"]

    result = run_agent_task("dev", prompt)
    new_state["code"] = result

    return new_state

def qa_node_with_memory(state: WorkflowState):
    """테스트 결과를 히스토리에 추가"""
    result = run_agent_task("qa", f"테스트해줘: {state['code']}")

    new_state = state.copy()
    new_state["test_result"] = parse_test_result(result)

    # 실패 시 에러 히스토리에 추가
    if not new_state["test_result"]["pass"]:
        errors = new_state.get("error_history", [])
        errors.append(new_state["test_result"]["error_message"])
        new_state["error_history"] = errors
        new_state["last_feedback"] = new_state["test_result"]["feedback"]

    return new_state
```

**조건 분기 고급:**
```python
def decide_next_with_analysis(state: WorkflowState):
    """재시도 여부를 에러 패턴 분석으로 결정"""

    # 테스트 통과 → 배포
    if state["test_result"]["pass"]:
        return "deploy"

    # 최대 재시도 초과 → 종료
    if state["retry_count"] >= state["max_retries"]:
        return END

    # 같은 에러 3회 반복 → 수동 개입 필요
    if len(state["error_history"]) >= 3:
        recent_errors = state["error_history"][-3:]
        if len(set(recent_errors)) == 1:  # 모두 같은 에러
            print("⚠️  동일한 에러 3회 반복. 수동 개입이 필요합니다.")
            return END

    # 재시도 가능 → 개발로 돌아감
    return "dev"
```

### 고급 기능

#### 토큰 관리 전략

**문제:**
```
모든 에이전트가 Claude 사용 시
→ 토큰 대폭 소비
→ 비용 증가
```

**해결책: 다중 LLM 혼합**
```python
AGENT_LLM_CONFIG = {
    "dev": "claude-sonnet-4",     # 코드 작성: 고성능 필요
    "qa": "gemini-pro",            # 테스트: 중간 성능으로 충분
    "deploy": "local-llm",         # 배포: 간단한 작업, 로컬 LLM
    "pm": "claude-opus-4",         # PM: 오케스트레이션은 최고 성능
}

def run_agent_task(agent_name: str, task: str):
    llm = AGENT_LLM_CONFIG[agent_name]

    if llm.startswith("claude"):
        return run_claude(task, model=llm)
    elif llm.startswith("gemini"):
        return run_gemini(task)
    elif llm == "local-llm":
        return run_local_llm(task)
```

**비용 절감 효과:**
```
Before (전부 Claude Opus):
- Dev: $0.50/작업
- QA: $0.30/작업
- Deploy: $0.20/작업
총: $1.00/작업

After (다중 LLM):
- Dev: $0.50 (Claude Sonnet)
- QA: $0.05 (Gemini)
- Deploy: $0.00 (Local LLM)
총: $0.55/작업 (45% 절감)
```

#### 메모리 공유 전략

**질문:** "에이전트 간 메모리를 어떻게 공유하나요?"

**답변:** "구조적으로 불필요하게 설계"

**이유:**
```
LangGraph State가 이미 공유 메모리 역할

Dev → QA 전달:
- State에 code 저장
- QA가 State에서 code 읽기

QA → Dev 피드백:
- State에 test_result 저장
- Dev가 State에서 test_result 읽기
```

**대안 (필요 시):**
```python
# 파일 기반 공유
SHARED_MEMORY_PATH = "/tmp/project-memory.json"

def save_to_memory(key: str, value: any):
    with open(SHARED_MEMORY_PATH, 'r+') as f:
        memory = json.load(f)
        memory[key] = value
        f.seek(0)
        json.dump(memory, f)

def read_from_memory(key: str):
    with open(SHARED_MEMORY_PATH, 'r') as f:
        memory = json.load(f)
        return memory.get(key)

# 또는 Jira 댓글
def save_to_jira(issue_key: str, comment: str):
    jira.add_comment(issue_key, comment)

def read_from_jira(issue_key: str):
    return jira.get_comments(issue_key)
```

#### 병렬 처리

**질문:** "여러 기능을 동시에 개발 가능한가요?"

**답변:** "이미 구현 중 (발표 당시는 2개월 전 버전)"

**구현:**
```python
import asyncio

async def parallel_development(features: list):
    """여러 기능을 병렬로 개발"""

    # 각 기능마다 독립적인 워크플로우 생성
    workflows = [
        create_workflow(f"feature-{i}", agents=["dev", "qa"])
        for i, _ in enumerate(features)
    ]

    # 병렬 실행
    results = await asyncio.gather(*[
        workflow.ainvoke({"task": feature})
        for workflow, feature in zip(workflows, features)
    ])

    return results

# 사용
features = [
    "로그인 기능",
    "회원가입 기능",
    "비밀번호 찾기 기능"
]

results = asyncio.run(parallel_development(features))
# 3개 기능이 동시에 개발됨
```

**Tmux 세션 병렬 실행:**
```bash
# 각 기능마다 독립적인 Tmux 세션
tmux new-session -d -s dev-login
tmux new-session -d -s dev-signup
tmux new-session -d -s dev-password

tmux new-session -d -s qa-login
tmux new-session -d -s qa-signup
tmux new-session -d -s qa-password
```

#### 컨텍스트 관리

**질문:** "프롬프트가 너무 길어지면?"

**답변:** "작업 분석/계획 전용 에이전트 추가"

**구현:**
```python
class Architect(Agent):
    """작업을 작은 단위로 분해하는 아키텍트 에이전트"""

    def analyze_task(self, task: str) -> list:
        """큰 작업을 작은 서브태스크로 분해"""
        prompt = f"""
다음 작업을 10줄 이하의 독립적인 서브태스크로 분해해줘:

작업: {task}

각 서브태스크는:
1. 하나의 명확한 목적
2. 다른 태스크와 독립적
3. 1시간 이내 완료 가능
        """
        result = run_claude(prompt)
        return parse_subtasks(result)

# 사용
architect = Architect()
subtasks = architect.analyze_task("쇼핑몰 전체 구현")

# 결과:
# 1. 상품 목록 페이지
# 2. 상품 상세 페이지
# 3. 장바구니 기능
# 4. 결제 기능
# 5. 주문 내역 페이지

# 각 서브태스크를 순차 또는 병렬로 실행
for subtask in subtasks:
    workflow.invoke({"task": subtask})
```

### 안전 장치

**최종 코드 검토:**
```
PM 에이전트 자동 실행
  ↓
코드 자동 생성
  ↓
자동 테스트 통과
  ↓
PR 생성 (자동)
  ↓
**인간 개발자 리뷰 (수동)** ← 1% 수동 개입
  ↓
승인 후 배포 (자동)
```

**PR 자동 생성:**
```python
def create_pull_request(branch: str, changes: dict):
    """자동 PR 생성"""
    title = f"[Auto] {changes['feature_name']}"
    body = f"""
## 자동 생성된 PR

### 구현 내용
{changes['description']}

### 변경 파일
{', '.join(changes['files'])}

### 테스트 결과
- 단위 테스트: {changes['unit_test_count']}개 통과
- 통합 테스트: {changes['integration_test_count']}개 통과

### AI 에이전트
- Dev: {changes['dev_agent']}
- QA: {changes['qa_agent']}

### 리뷰 요청
@tech-lead 코드 리뷰 부탁드립니다.
    """

    github.create_pull_request(
        repo="my-repo",
        head=branch,
        base="main",
        title=title,
        body=body
    )
```

### 발표자의 철학

**핵심 메시지:**
```
"AI와 함께 일하는 방법이 아니라,
나도 옆에서 일하고 AI도 옆에서 함께 일하는 것"
```

**투자 대비 효과:**
```
"비싼 Claude 값을 냈으면 100~200배는 뽑아야"

투자: Claude API 월 $100
목표: 월 $10,000~$20,000 가치 창출

= 시간 절약 + 품질 향상 + 자동화 효과
```

### 핵심 Takeaways

1. **점진적 진화**: Tmux → LangGraph → PM 에이전트 → 99% 자동화
2. **도구는 수단**: "특정 라이브러리(LangGraph)가 아닌 문제 해결 방식"
3. **토큰 효율**: 다중 LLM 혼합으로 비용 45% 절감
4. **안전 장치**: 최종 PR은 인간이 리뷰 (1% 수동 개입)
5. **병렬 처리**: 여러 기능 동시 개발 가능
6. **메모리 공유**: LangGraph State로 충분, 불필요하게 복잡하게 만들지 말 것

---

## 📚 참고 자료

- 애니메이션 라이브러리 개발: [요즘IT - 내가 애니메이션 라이브러리를 만들면서 배운 것들]
- GTM 전략: [요즘IT - Go-To-Market 전략을 고민하는 당신에게]
- AI 창의성: [요즘IT - 내가 쓰는 AI는 왜 비슷한 답만 반복할까?]
- 프론트엔드 트렌드: [요즘IT - 2026년 프론트엔드 트렌드 총정리]
- 긴급 개발: [요즘IT - 서비스 중단 위기, 클로드 코드로 3일 만에 막아낸 썰]
- AI 에이전트 오케스트레이션: [요즘IT - AI 에이전트 오케스트레이션 4단계 실전 가이드]

---

## 🚀 빠른 시작

```bash
# 성능 최적화 필요할 때
/auto "성능 vs 자연스러움 하이브리드 최적화 전략 적용해줘"

# 신규 제품 기획할 때
/auto "GTM 전략으로 타깃 세그먼트 정의하고 MVP 설계해줘"

# AI 활용 개선하고 싶을 때
/auto "언어화된 샘플링 프롬프트로 더 창의적인 결과 받고 싶어"

# 최신 기술 스택 고민될 때
/auto "2026 프론트엔드 트렌드 고려해서 기술 스택 추천해줘"

# 긴급 개발 상황일 때
/auto "3일 안에 완성해야 해. 문서화 전략과 빠른 개발 방법 알려줘"

# AI 에이전트 자동화 필요할 때
/auto "Tmux + LangGraph로 여러 에이전트 자동 협업 환경 만들어줘"

# 전체 프로젝트 컨설팅
/auto "우리 프로젝트에 어떤 실전 지혜를 적용하면 좋을지 분석해줘"
```

---

**이 스킬로 실전 문제를 빠르고 효과적으로 해결하세요!** 🚀
