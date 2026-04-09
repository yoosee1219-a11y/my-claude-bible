---
name: notebooklm-research-automation
description: NotebookLM MCP 리서치 자동화 - AI 에이전트 기반 체계적 리서치, 딥리서치, 아이디어 경쟁 평가, 프로토타입 연계
version: 1.0.0
author: my-claude-bible
tags:
  - NotebookLM
  - MCP
  - 리서치자동화
  - 딥리서치
  - 에이전트경쟁
  - 아이디어평가
  - 시장조사
  - 경쟁분석
  - 트렌드분석
  - 비즈니스리서치
---

# NotebookLM MCP Research Automation

## 개요

NotebookLM MCP를 활용하여 AI 에이전트 기반으로 대규모 리서치를 자동 수행하는 스킬.
"연구원 10명을 고용한 것처럼" 각각의 NotebookLM 노트북이 독립 에이전트 역할을 하며,
체계적인 데이터 수집 → 딥리서치 → 경쟁 평가 → 종합 보고서 → 프로토타입 개발까지 이어지는 파이프라인.

### 핵심 개념
```
사용자 요청 → N개 노트북 자동 생성 → 각 노트북이 에이전트처럼 독립 리서치
→ 에이전트들이 "경쟁" → 최고 결과 선정 → (선택) 프로토타입 개발
```

### 활용 시나리오
- AI 1인기업 수익화 아이디어 조사
- SaaS 경쟁사 심층 분석
- 기술 트렌드 리포트 작성
- 시장 진입 전략 수립
- 투자 대상 비교 분석
- 신규 사업 아이디어 발굴

---

## 1. MCP 서버 설치 및 설정

### 추천 NotebookLM MCP 서버

| 서버 | 특징 | 도구 수 | 적합 용도 |
|------|------|---------|-----------|
| **ignitabull18/notebooklm-mcp** | 딥리서치 API 포함 | 32개 | 리서치 자동화 (Primary) |
| **alfredang/notebooklm-mcp** | 콘텐츠 생성 특화 | 20개+ | 팟캐스트, 비디오, 인포그래픽 |
| **PleasePrompto/notebooklm-mcp** | 가장 인기 (725 stars) | 15개+ | Q&A, 요약 특화 |

### Claude Code 설정

`~/.claude/settings.local.json`에 MCP 서버 추가:

```json
{
  "mcpServers": {
    "notebooklm": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/notebooklm-mcp"],
      "env": {
        "GOOGLE_API_KEY": "your-google-api-key"
      }
    }
  }
}
```

### ignitabull18/notebooklm-mcp 설치 (Primary)

```bash
# npm 글로벌 설치
npm install -g @anthropic-ai/notebooklm-mcp

# 또는 npx로 직접 실행
npx @anthropic-ai/notebooklm-mcp
```

MCP 설정 (Claude Desktop / Antigravity):
```json
{
  "mcpServers": {
    "notebooklm": {
      "command": "npx",
      "args": ["-y", "notebooklm-mcp"],
      "env": {
        "GOOGLE_COOKIES": "path/to/cookies.json"
      }
    }
  }
}
```

### Antigravity에서 설정

1. Antigravity 프로젝트 열기
2. Settings → MCP Servers → Add Server
3. Server Name: `notebooklm`
4. Command: `npx -y notebooklm-mcp`
5. Environment Variables에 인증 정보 추가
6. Save & Connect

### 인증 방식

```markdown
방식 1: Google API Key
  - Google Cloud Console → APIs → NotebookLM API 활성화
  - API Key 발급 → GOOGLE_API_KEY 환경변수

방식 2: Cookie 기반 (ignitabull18)
  - Chrome에서 notebooklm.google.com 로그인
  - 개발자 도구 → Application → Cookies 복사
  - cookies.json 파일 생성 → GOOGLE_COOKIES 환경변수

방식 3: OAuth2 (고급)
  - Google Cloud OAuth 2.0 Client ID 생성
  - 리프레시 토큰 발급
  - GOOGLE_OAUTH_TOKEN 환경변수
```

---

## 2. 리서치 워크플로우 (6단계)

### 전체 파이프라인

```
[Stage 1] 기획 (research-planner)
    ↓
[Stage 2] 노트북 생성 (research-collector)
    ↓
[Stage 3] 소스 수집 & 딥리서치 (research-collector)
    ↓
[Stage 4] 경쟁 평가 (research-evaluator)
    ↓
[Stage 5] 종합 & 보고서 (research-synthesizer)
    ↓
[Stage 6] 프로토타입 개발 (antigravity / fullstack-scaffold)
```

### Stage 1: 리서치 기획

**담당 에이전트**: `research-planner`

사용자 요청을 분석하여 리서치 범위, 깊이, 노트북 구조를 설계한다.

```markdown
입력: "AI 1인기업 수익화 아이디어 10개 찾아줘"

출력:
- 리서치 깊이: Level 2 (비즈니스 리포트)
- 노트북 구조: 10개 (아이디어별 독립)
  1. AI 자동화 대행 서비스
  2. AI 콘텐츠 제작 SaaS
  3. AI 교육/튜터링 플랫폼
  4. AI 데이터 분석 컨설팅
  5. AI 챗봇 빌더
  6. AI 이미지/영상 제작
  7. AI 번역/로컬라이제이션
  8. AI 코드 리뷰 서비스
  9. AI 마케팅 자동화
  10. AI 고객 서비스 솔루션
- 평가 기준: 투자자(0.3), 고객(0.3), 기술(0.2), 시장(0.2)
```

### Stage 2: 노트북 생성

**담당 에이전트**: `research-collector`

MCP 도구로 NotebookLM 노트북을 벌크 생성한다.

```
MCP 호출 순서:
1. notebook_create("AI 자동화 대행 서비스", "1인기업 AI 자동화...")
2. notebook_create("AI 콘텐츠 제작 SaaS", "AI 기반 콘텐츠...")
   ... (10회)
```

### Stage 3: 소스 수집 & 딥리서치

**담당 에이전트**: `research-collector`

각 노트북에 고품질 소스를 추가하고 딥리서치를 실행한다.

```
For each notebook:
  1. WebSearch로 관련 소스 검색 (5-15개)
  2. notebook_add_url / notebook_add_youtube로 소스 추가
  3. research_start로 딥리서치 시작
  4. research_status로 완료 대기
  5. research_import로 결과 가져오기
```

### Stage 4: 경쟁 평가

**담당 에이전트**: `research-evaluator`

4개 관점 평가 프레임워크로 아이디어를 채점하고 순위를 매긴다.

```markdown
평가 관점:
1. 투자자 (ROI, 확장성, 회수기간, 리스크) × 0.3
2. 고객 (페인포인트, 대체재, 지불의향, 편의성) × 0.3
3. 기술자 (구현난이도, 성숙도, 1인개발, 유지보수) × 0.2
4. 시장분석가 (규모, 성장률, 경쟁강도, 타이밍) × 0.2

최종 점수 = 가중합 → 순위 산출 → Top 3 SWOT 분석
```

### Stage 5: 종합 & 보고서

**담당 에이전트**: `research-synthesizer`

크로스레퍼런스 분석으로 인사이트를 도출하고 최종 보고서를 작성한다.

```markdown
보고서 구조:
1. Executive Summary (1페이지)
2. 핵심 발견 (Key Findings)
3. 크로스레퍼런스 인사이트
4. 순위 및 평가 결과
5. 실행 권고 (Quick Wins / 중기 / 추가 조사)
6. 부록 (방법론, 소스 목록, 상세 데이터)
```

### Stage 6: 프로토타입 개발 (선택)

선정된 아이디어를 즉시 프로토타입으로 개발한다.

```markdown
핸드오프 방식:
1. research-synthesizer가 requirements.md 생성
2. 개발 에이전트에 전달:
   - antigravity-website-builder: 웹앱/랜딩 페이지
   - fullstack-scaffold: 풀스택 프로젝트
   - mobile-crossplatform: React Native + Expo 모바일 앱
3. 개발 에이전트가 MVP 자동 생성
4. QR코드로 모바일에서 즉시 확인 (Expo)
```

---

## 3. 에이전트 경쟁 패턴 (Competition Pattern)

### 개념

"연구원 10명을 고용한 것처럼" 각 노트북이 독립 에이전트 역할을 하며,
같은 과제에 대해 서로 다른 관점/아이디어를 가져와 경쟁한다.

### 구현 방식

```
Phase 1: 독립 리서치 (병렬)
  노트북1 ──→ [딥리서치] ──→ 결과1
  노트북2 ──→ [딥리서치] ──→ 결과2
  ...
  노트북N ──→ [딥리서치] ──→ 결과N

Phase 2: 경쟁 평가 (순차)
  결과1 vs 결과2 vs ... vs 결과N
  → 4-Persona 평가
  → 가중 점수 산출
  → 순위 결정

Phase 3: 챔피언 선정
  1위 → 즉시 실행 추천
  2-3위 → 대안으로 보관
  4위~ → 참고 자료
```

### 다관점 평가 프레임워크

```
최종 점수 = (투자자 × 0.3) + (고객 × 0.3) + (기술 × 0.2) + (시장 × 0.2)

투자자 점수 = avg(수익잠재력, 확장성, 투자회수, 리스크수준)
고객 점수   = avg(페인포인트해결, 대체재부재, 지불의향, 사용편의성)
기술 점수   = avg(구현난이도, 기술성숙도, 1인개발가능성, 유지보수부담)
시장 점수   = avg(시장규모, 성장률, 경쟁강도, 타이밍)
```

### 경쟁 변형 패턴

```markdown
1. **토너먼트형**: 1:1 대결 → 승자끼리 대결 → 최종 챔피언
2. **라운드로빈형**: 모든 조합 비교 → 승점 합산
3. **순위형** (기본): 전체 채점 → 순위 정렬
4. **그룹형**: 유사 아이디어 그룹화 → 그룹 내 최고 → 그룹 간 경쟁
```

---

## 4. 리서치→프로토타입 파이프라인

### 자동 핸드오프 프로세스

```
research-synthesizer
    │
    ├── requirements.md 생성
    │   ├── 프로젝트 개요
    │   ├── MVP 핵심 기능 (3-5개)
    │   ├── 기술 스택 추천
    │   ├── 타겟 사용자 페르소나
    │   └── 성공 지표 (KPI)
    │
    └── 핸드오프 ──→ 개발 에이전트
                     ├── antigravity-website-builder (웹)
                     ├── fullstack-scaffold (풀스택)
                     └── mobile-crossplatform (모바일)
```

### 연계 스킬

| 개발 대상 | 연계 스킬/에이전트 | 설명 |
|-----------|-------------------|------|
| 랜딩 페이지 | `antigravity-website-builder` | 15초 웹사이트 빌더 |
| 풀스택 웹앱 | `fullstack-scaffold` | React/Next.js + API + DB |
| 모바일 앱 | `mobile-crossplatform` | React Native + Expo |
| API 서비스 | `api-designer` + `api-implementer` | REST/GraphQL API |

### 예시: 리서치 → React Native 앱

```markdown
1. 리서치 결과: "AI 자동화 대행 서비스"가 1위
2. requirements.md 생성:
   - 핵심 기능: AI 작업 주문, 결과 확인, 결제
   - 기술 스택: React Native + Expo + Supabase
3. mobile-crossplatform 에이전트에 핸드오프
4. Expo로 개발 → QR코드로 모바일 즉시 확인
```

---

## 5. MCP 도구 레퍼런스

### ignitabull18/notebooklm-mcp 주요 도구

```markdown
## 노트북 관리
- notebook_create(title, description)    → 노트북 생성
- notebook_list()                         → 노트북 목록
- notebook_delete(notebook_id)            → 노트북 삭제
- notebook_get(notebook_id)               → 노트북 상세

## 소스 관리
- notebook_add_url(notebook_id, url)      → URL 소스 추가
- notebook_add_text(notebook_id, title, content) → 텍스트 소스 추가
- notebook_add_youtube(notebook_id, url)  → YouTube 소스 추가
- notebook_add_pdf(notebook_id, path)     → PDF 소스 추가
- notebook_get_sources(notebook_id)       → 소스 목록 조회
- notebook_remove_source(notebook_id, source_id) → 소스 제거

## 딥리서치
- research_start(notebook_id, query)      → 딥리서치 시작
- research_status(research_id)            → 상태 확인
- research_import(research_id, notebook_id) → 결과 가져오기

## 질문/분석
- notebook_query(notebook_id, question)   → 노트북에 질문
- notebook_get_notes(notebook_id)         → 노트 조회
- notebook_create_note(notebook_id, content) → 노트 생성

## 콘텐츠 생성 (alfredang 확장)
- notebook_generate_podcast(notebook_id)  → 팟캐스트 생성
- notebook_generate_faq(notebook_id)      → FAQ 생성
- notebook_generate_briefing(notebook_id) → 브리핑 생성
```

---

## 6. MCP 미설치 시 대체 모드

NotebookLM MCP가 설치되지 않은 환경에서도 리서치 워크플로우를 수행할 수 있다.

### 대체 전략: 파일 기반 가상 노트북

```
research-output/
├── project-meta.json           (프로젝트 메타데이터)
├── nb-001-topic-name/
│   ├── plan.md                 (노트북 계획)
│   ├── sources.md              (소스 목록 + URL)
│   ├── raw-data/               (WebFetch 수집 데이터)
│   │   ├── source-001.md
│   │   ├── source-002.md
│   │   └── ...
│   ├── analysis.md             (분석 결과)
│   └── summary.md              (요약)
├── nb-002-topic-name/
│   └── ...
├── evaluation-report.md        (평가 보고서)
├── final-report.md             (종합 보고서)
└── requirements.md             (개발 핸드오프용)
```

### 대체 도구 매핑

| NotebookLM MCP | 대체 도구 |
|----------------|-----------|
| notebook_create | mkdir + plan.md 생성 |
| notebook_add_url | WebFetch → raw-data/*.md |
| research_start | WebSearch 집중 검색 + 분석 |
| notebook_query | 수집 데이터 기반 분석 |
| research_import | analysis.md 생성 |

---

## 7. 사용 예시

### 예시 1: AI 1인기업 수익화 아이디어 10개

```bash
# 자연어 요청
"AI 1인기업 수익화 아이디어 10개 찾아줘"

# 실행 흐름
1. research-planner: 10개 아이디어 주제 도출, 노트북 구조 설계
2. research-collector: NotebookLM에 10개 노트북 생성, 소스 수집, 딥리서치
3. research-evaluator: 4-Persona 평가로 순위 결정
4. research-synthesizer: 종합 보고서 + requirements.md 생성
5. (선택) mobile-crossplatform: 1위 아이디어를 React Native 앱으로 개발
```

### 예시 2: SaaS 경쟁사 분석

```bash
# 자연어 요청
"Notion, Obsidian, Roam Research 비교 분석해줘"

# 실행 흐름
1. research-planner: 경쟁사 3개 + 종합 비교 = 4개 노트북 설계
2. research-collector: 경쟁사별 소스 수집 (제품 페이지, 리뷰, 가격)
3. research-evaluator: 기능, 가격, UX, 생태계 등 비교 평가
4. research-synthesizer: 차별화 포인트 도출, 진입 전략 제시
```

### 예시 3: 2026 테크 트렌드 리포트

```bash
# 자연어 요청
"2026 주요 기술 트렌드 리포트 만들어줘"

# 실행 흐름
1. research-planner: AI, 양자컴퓨팅, 바이오, 우주, 에너지 등 분야별 노트북
2. research-collector: 분야별 최신 소스 수집, 딥리서치
3. research-evaluator: 각 트렌드의 성숙도/영향력/투자매력도 평가
4. research-synthesizer: 크로스 트렌드 인사이트 도출, 종합 리포트
```

---

## 8. 오케스트레이터 연동

### 트리거 키워드

이 스킬은 다음 키워드가 감지되면 자동으로 활성화된다:

```
리서치, 조사, 아이디어, 분석, 트렌드, 시장조사, 경쟁분석,
NotebookLM, 딥리서치, 비교분석, 수익화, 사업아이디어,
찾아줘, 조사해줘, 분석해줘, 리포트, 보고서
```

### Wave 실행 패턴

```
Wave 1 (기획):     research-planner
Wave 2 (수집):     research-collector (병렬 소스 수집)
Wave 3 (평가):     research-evaluator
Wave 4 (종합):     research-synthesizer
Wave 5 (개발):     antigravity / fullstack-scaffold / mobile-crossplatform (선택)
```

---

## 9. 관련 에이전트

| 에이전트 | 위치 | 역할 |
|---------|------|------|
| research-planner | `agents/research/research-planner.md` | 리서치 기획 |
| research-collector | `agents/research/research-collector.md` | 데이터 수집 |
| research-evaluator | `agents/research/research-evaluator.md` | 평가 및 순위 |
| research-synthesizer | `agents/research/research-synthesizer.md` | 종합 보고서 |

---

**버전:** 1.0.0
**최종 업데이트:** 2026-02-03
**연관 스킬:** antigravity-website-builder, fullstack-scaffold, intelligent-orchestrator
