---
name: claude-code-skills-guide
description: claude code skills, 스킬생성, 스킬관리, AI자동화, 워크플로우최적화, 코드생성, 커스텀스킬, 스킬통합, 베스트프랙티스, 스킬문서화, 마크다운스킬, 프론트매터, 키워드최적화, 스킬발견, 멀티스킬워크플로우, 스킬반복개선, 코드예제, 구현패턴, 스킬생태계, 지식전달
---

# Claude Code 스킬 활용 가이드

Claude Code Skills는 Claude AI에게 특정 도메인의 전문 지식과 베스트 프랙티스를 가르치는 강력한 기능입니다. 스킬 파일을 통해 개발자는 자신의 전문성을 문서화하고, Claude가 이를 자동으로 활용하여 고품질 코드를 생성하도록 할 수 있습니다.

## 핵심 개념


### 스킬 파일 구조

Claude Code Skills는 마크다운 파일로 작성되며, YAML 프론트 매터로 시작합니다. description 필드에 키워드를 풍부하게 포함하여 Claude가 적절한 스킬을 자동으로 발견하도록 합니다.


```markdown
---
name: landing-page-guide
description: landing page, marketing, Next.js, ShadCN UI, SEO
---

# Landing Page Guide

## Overview
This skill helps create high-converting landing pages.
```



### 실행 가능한 코드 예제

스킬에는 실제로 동작하는 코드 예제가 필수입니다. Claude는 구체적인 구현 패턴을 학습하여 실제 프로젝트에서 유사한 코드를 생성합니다.


```typescript
export default function Hero() {
  return (
    <section className="hero">
      <h1>Welcome</h1>
      <button>Get Started</button>
    </section>
  )
}
```




## 코드 예제


### Next.js 랜딩 페이지 컴포넌트

ShadCN UI를 활용한 반응형 랜딩 페이지 예제입니다.

```typescript
import { Button } from '@/components/ui/button'

export function LandingPage() {
  return (
    <div className="container mx-auto">
      <h1 className="text-4xl font-bold">Product Name</h1>
      <Button>Learn More</Button>
    </div>
  )
}
```



## 베스트 프랙티스


- description 필드에 가능한 많은 키워드 포함하기

- 실제 동작하는 완전한 코드 예제 제공하기

- 여러 스킬을 조합하여 강력한 워크플로우 구축하기

- 실제 사용 경험을 바탕으로 스킬을 지속적으로 개선하기

- 커뮤니티와 스킬을 공유하여 생태계 발전에 기여하기


## 주의사항


### 키워드 부족

description에 키워드가 부족하면 Claude가 스킬을 발견하지 못합니다.

```yaml
// ❌ 나쁜 예
description: landing page

// ✅ 좋은 예
description: landing page, marketing, Next.js, ShadCN UI, SEO, conversion
```



## 태그

#claude-code #skills #ai-automation #code-generation #best-practices 