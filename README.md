# My Claude Bible

나만의 Claude Code 스킬, 에이전트, 설정 모음집 - 어떤 환경에서도 동일한 Claude Code 경험을 제공합니다.

## 소개

이 저장소는 Claude Code의 모든 커스텀 스킬, 에이전트, 설정 파일을 중앙 집중식으로 관리하기 위한 개인 바이블입니다.

**핵심 구성:**
- **54개 커스텀 스킬** - 지식, 패턴, 가이드 (`skills/`)
- **71개 전문 에이전트** - 자율 실행 전문가 (`agents/`)
- **3개 오케스트레이터** - 스킬/에이전트 자동 조율
- **자동 설치/동기화 스크립트** - Windows/Mac/Linux

---

## 스킬 vs 에이전트: 시너지 아키텍처

```
              사용자 요청
                  |
         +--------v--------+
         |  오케스트레이터    |
         +--------+---------+
                  |
       +----------+----------+
       |                     |
+------v-------+   +---------v--------+
|  스킬 (지식)  |   |  에이전트 (실행)   |
|  skills/*.md  |   |  agents/*/*.md   |
+--------------+   +------------------+
```

### 스킬 (Skills) = 지식
- 특정 도메인의 **베스트 프랙티스, 패턴, 가이드**를 제공
- Claude가 참조하는 **지식 기반** 역할
- 예: `cloud-cost-optimizer.md`는 FinOps 전략과 40-70% 비용 절감 방법론을 담고 있음

### 에이전트 (Agents) = 실행
- 특정 작업을 **자율적으로 수행**하는 전문가
- 스킬의 지식을 활용하여 **실제 코드/설정 생성**
- 예: `cloud-cost` 에이전트는 실제 인프라를 분석하여 비용 최적화 실행

### 오케스트레이터 = 조율
- `/auto` - 자연어로 적절한 스킬 자동 선택/실행
- `/unified` - 스킬 + 에이전트 최적 조합 자동 조율
- `orchestrator.md` - Wave 기반 병렬 에이전트 실행

---

## 시너지 예시

### 예시 1: "클라우드 비용 최적화해줘"
1. `/auto` 오케스트레이터가 요청 분석
2. `cloud-cost-optimizer.md` 스킬에서 FinOps 전략 참조
3. `cloud-cost` 에이전트가 실제 인프라 분석/실행
4. 결과: 스킬의 지식 + 에이전트의 실행력으로 비용 절감

### 예시 2: "사용자 인증 시스템 구축해줘"
1. `orchestrator.md`가 Wave 계획 수립
2. Wave 1 (설계): `arch-system` + `db-architect` + `api-designer`
3. Wave 2 (구현): `auth-architect` + `api-implementer` + `service-logic`
4. Wave 3 (품질): `security-audit` + `test-unit`
5. 참조 스킬: `security-best-practices.md`, `database-admin.md`

---

## 저장소 구조

```
my-claude-bible/
├── skills/                    # 54개 커스텀 스킬
│   ├── intelligent-orchestrator.md    # /auto 오케스트레이터
│   ├── unified-orchestrator.md        # /unified 통합 오케스트레이터
│   ├── massive-parallel-orchestrator.md
│   ├── parallel-dev-team.md
│   ├── cloud-cost-optimizer.md
│   ├── database-admin.md
│   ├── code-review.md
│   ├── security-audit.md
│   ├── hotwire-native-framework/      # 디렉토리 기반 스킬
│   └── ... (총 54개)
├── agents/                    # 71개 전문 에이전트 + 오케스트레이터
│   ├── config.json                    # 에이전트 등록/오케스트레이션 설정
│   ├── orchestrator.md                # Wave 기반 중앙 조율자
│   ├── database/          (6 agents)  # 스키마, 쿼리, 마이그레이션, 인덱싱, 스케일링, NoSQL
│   ├── api/               (5 agents)  # 설계, 구현, 검증, 게이트웨이, 버전관리
│   ├── frontend/          (6 agents)  # 컴포넌트, 상태, 접근성, 스타일, 성능, Hotwire
│   ├── backend/           (7 agents)  # 로직, 인증, 연동, 복원력, 캐싱, 실시간, 배치
│   ├── search-data/       (4 agents)  # 검색, 벡터, 메시지큐, 데이터파이프라인
│   ├── infrastructure/    (7 agents)  # IaC, K8s, Docker, 서버리스, CI/CD, 배포, 비용
│   ├── testing/           (8 agents)  # 단위, 통합, E2E, 성능, 보안, 계약, 뮤테이션, 시각적
│   ├── security/          (6 agents)  # 감사, 위협, 시크릿, 컴플라이언스, SCA, 침투
│   ├── ml-ai/             (5 agents)  # 훈련, 추론, 배포, 모니터링, 데이터
│   ├── mobile/            (3 agents)  # 크로스플랫폼, 네이티브, 테스트
│   ├── observability/     (4 agents)  # 메트릭, 로깅, 추적, 인시던트
│   ├── documentation/     (4 agents)  # 기술문서, API스펙, 아키텍처, 변경로그
│   ├── git-collab/        (2 agents)  # Git워크플로우, 코드리뷰
│   └── architecture/      (4 agents)  # 시스템, 마이크로서비스, 이벤트드리븐, 데이터
├── scripts/
│   ├── install.ps1 / install.sh       # 설치 (스킬 + 에이전트)
│   └── sync.ps1 / sync.sh            # 환경 간 동기화
├── CATALOG.md                         # 스킬 + 에이전트 통합 카탈로그
└── README.md                          # 이 파일
```

---

## 설치 방법

### Windows (PowerShell)

```powershell
git clone https://github.com/yoosee1219-a11y/my-claude-bible.git
cd my-claude-bible
.\scripts\install.ps1
```

### Mac / Linux (Bash)

```bash
git clone https://github.com/yoosee1219-a11y/my-claude-bible.git
cd my-claude-bible
chmod +x scripts/install.sh
./scripts/install.sh
```

### 설치 스크립트 기능

- 기존 스킬/에이전트 자동 백업 (`~/.claude-backup-YYYYMMDD-HHMMSS/`)
- 스킬 자동 복사 (`~/.claude/skills/`)
- 에이전트 자동 복사 (`~/.claude/agents/`)
- 설정 파일 선택적 복사
- 설치 요약 및 사용법 안내

---

## 사용법

### Intelligent Orchestrator (`/auto`)
대부분의 작업은 `/auto`로 시작하세요:

```bash
/auto "planning.md 파일대로 웹서비스 만들어줘"
/auto "의존성 분석하고 성능 개선 제안해줘"
/auto "테스트 커버리지 100% 만들어줘"
```

### 특정 스킬 직접 호출

```bash
/massive-parallel-orchestrator "src/ 디렉토리 전체 리팩토링"
/fullstack-scaffold "e-commerce-platform"
/dependency-analyzer "."
```

### 전체 스킬/에이전트 목록

- **스킬 카탈로그:** [CATALOG.md](CATALOG.md)
- **에이전트 목록:** [agents/README.md](agents/README.md)

---

## 환경 간 동기화

### 집 <-> 회사

```bash
# 집에서 작업 후
cd my-claude-bible
git add .
git commit -m "Update skills and configs"
git push

# 회사에서
cd my-claude-bible
git pull
./scripts/install.sh  # 또는 install.ps1
```

### 새 스킬 추가

```bash
cp ~/.claude/skills/new-skill.md skills/
git add skills/new-skill.md
git commit -m "Add new-skill"
git push
```

---

## 백업 정책

설치 스크립트는 자동으로 기존 스킬을 백업합니다:

```
~/.claude-backup-20260108-143022/
└── skills/
    ├── skill1.md
    └── ...
```

---

## 사용 통계

Intelligent Orchestrator는 스킬 사용 통계를 추적합니다:

```
~/.claude/skill-usage-stats.json
```

**추적 항목:** 총 사용 횟수, 성공/실패 비율, 평균 실행 시간, 자주 사용되는 키워드

---

## 문제 해결

### 스킬이 로드되지 않음
```bash
ls ~/.claude/skills/
# Claude Code 재시작 또는 설치 스크립트 재실행
```

### 권한 오류 (Mac/Linux)
```bash
chmod +x scripts/install.sh
```

### 백업 복원
```bash
cp ~/.claude-backup-YYYYMMDD-HHMMSS/skills/* ~/.claude/skills/
```

---

## 통계

| 항목 | 수량 |
|------|------|
| 커스텀 스킬 | 54개 |
| 전문 에이전트 | 71개 |
| 에이전트 카테고리 | 14개 |
| 오케스트레이터 | 3개 |
| 설치 스크립트 | 4개 (Win/Mac install + sync) |

---

마지막 업데이트: 2026-01-31
