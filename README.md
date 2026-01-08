# My Claude Bible (my-claude-vible)

나만의 Claude Code 스킬, 에이전트, 설정 모음집 - 어떤 환경에서도 동일한 Claude Code 경험을 제공합니다.

## 소개

이 저장소는 Claude Code의 모든 커스텀 스킬, 에이전트, 설정 파일을 중앙 집중식으로 관리하기 위한 개인 바이블입니다.

**주요 기능:**
- 30개 이상의 검증된 Claude Code 스킬
- 자동 설치 스크립트 (Windows/Mac/Linux)
- 환경 간 동기화 지원
- 기존 설정 자동 백업

## 포함된 내용

```
my-claude-vible/
├── skills/          # 30개 커스텀 스킬 (.md 파일)
├── agents/          # 커스텀 에이전트 (향후 추가)
├── configs/         # 설정 파일 (향후 추가)
└── scripts/
    ├── install.sh   # Mac/Linux 설치 스크립트
    └── install.ps1  # Windows 설치 스크립트
```

## 설치 방법

### Windows (PowerShell)

```powershell
# 저장소 클론
git clone https://github.com/[your-username]/my-claude-vible.git
cd my-claude-vible

# 설치 실행
.\scripts\install.ps1
```

### Mac / Linux (Bash)

```bash
# 저장소 클론
git clone https://github.com/[your-username]/my-claude-vible.git
cd my-claude-vible

# 설치 실행
chmod +x scripts/install.sh
./scripts/install.sh
```

## 설치 스크립트 기능

- ✅ 기존 스킬 자동 백업 (`~/.claude-backup-YYYYMMDD-HHMMSS/`)
- ✅ 스킬 자동 복사 (`~/.claude/skills/`)
- ✅ 에이전트 복사 (있는 경우)
- ✅ 설정 파일 선택적 복사
- ✅ 설치 요약 및 사용법 안내

## 주요 스킬

### Intelligent Orchestrator (`/auto`)
자연어 요청을 분석하여 적절한 스킬/에이전트를 자동 선택하고 실행합니다.

```bash
/auto "planning.md 파일대로 웹서비스 만들어줘"
```

**기능:**
- 📖 자동 요청 분석 및 키워드 추출
- 🔍 30개 스킬 데이터베이스 자동 매칭
- 📋 실행 계획 제시 (투명성)
- ⚡ 자동 실행 (순차/병렬)
- 📊 사용 통계 추적

### Massive Parallel Orchestrator
대규모 병렬 작업 처리

### Parallel Dev Team
다중 페르소나 협업 시스템

### Antigravity Website Builder
15초 웹사이트 빌더

[전체 스킬 목록은 CATALOG.md 참조]

## 사용법

설치 후 Claude Code에서 바로 사용 가능:

```bash
# Intelligent Orchestrator 사용
/auto "자연어 요청"

# 특정 스킬 직접 호출
/massive-parallel-orchestrator "작업 설명"
/fullstack-scaffold "프로젝트명"
/dependency-analyzer "분석할 디렉토리"
```

## 새 환경 설정하기

1. **저장소 클론**
   ```bash
   git clone https://github.com/[your-username]/my-claude-vible.git
   ```

2. **설치 스크립트 실행**
   - Windows: `.\scripts\install.ps1`
   - Mac/Linux: `./scripts/install.sh`

3. **Claude Code 재시작**
   - 스킬이 자동으로 로드됩니다

## 환경 간 동기화

### 집 → 회사

```bash
# 집에서 작업 후
cd my-claude-vible
git add .
git commit -m "Update skills and configs"
git push

# 회사에서
cd my-claude-vible
git pull
./scripts/install.sh  # 또는 install.ps1
```

### 새 스킬 추가

```bash
# 스킬 파일을 skills/ 디렉토리에 추가
cp ~/.claude/skills/new-skill.md skills/

# 커밋 & 푸시
git add skills/new-skill.md
git commit -m "Add new-skill"
git push
```

## 백업 정책

설치 스크립트는 자동으로 기존 스킬을 백업합니다:

```
~/.claude-backup-20260108-143022/
└── skills/
    ├── skill1.md
    ├── skill2.md
    └── ...
```

백업은 설치 전 타임스탬프와 함께 생성되며, 수동으로 삭제하기 전까지 보존됩니다.

## 사용 통계

Intelligent Orchestrator는 스킬 사용 통계를 추적합니다:

```
~/.claude/skill-usage-stats.json
```

**추적 항목:**
- 총 사용 횟수
- 성공/실패 비율
- 평균 실행 시간
- 마지막 사용 시간
- 자주 사용되는 키워드

이 데이터를 통해 어떤 스킬이 가장 유용한지 파악하고 개선할 수 있습니다.

## 문제 해결

### 스킬이 로드되지 않음

```bash
# 스킬 디렉토리 확인
ls ~/.claude/skills/

# Claude Code 재시작
# 또는 설치 스크립트 재실행
```

### 권한 오류 (Mac/Linux)

```bash
chmod +x scripts/install.sh
```

### 백업 복원

```bash
cp ~/.claude-backup-YYYYMMDD-HHMMSS/skills/* ~/.claude/skills/
```

## 기여하기

이 저장소는 개인용입니다. 새로운 스킬은 직접 추가하고 커밋하세요.

## 라이선스

Private - 개인 사용 전용

## 연락처

- GitHub: [your-username]
- Repository: my-claude-vible

---

**Happy Coding with Claude! 🚀**

마지막 업데이트: 2026-01-08
총 스킬 수: 30개
