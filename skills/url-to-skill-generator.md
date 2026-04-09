---
name: url-to-skill-generator
description: URL스킬생성, 자동문서화, YouTube스킬화, 콘텐츠분석, Claude스킬자동화, 자막추출, 로컬파일처리, 블로그분석, WebFetch, downsub, 지식베이스구축, 병렬처리, 메타스킬로 URL 및 로컬 파일에서 자동으로 Claude Code 스킬을 생성하는 메타 시스템
---

# URL → 스킬 자동 생성기

## 개요

YouTube 영상, 블로그 글, 정보성 문서 등 **URL 또는 로컬 자막 파일**에서 자동으로 Claude Code 스킬 파일(.md)을 생성하는 메타 시스템입니다.

**시간 절약:** 수동 2시간 → 자동 5분 (96% 절감)

### 현재 상황 (2026-01-13 업데이트)

- ✅ **블로그/정보성 글**: WebFetch로 자동 분석 가능
- ⚠️ **YouTube 영상**: IP 차단으로 자동 추출 불가 → 수동 다운로드 후 로컬 처리
- ✅ **로컬 자막 파일**: 자동 처리 지원 (.txt, .srt)

## 시스템 구조

### 워크플로우 A: 블로그/정보성 글 (자동)

```
[블로그 URL]
    ↓
[WebFetch로 콘텐츠 추출] → [텍스트]
    ↓
[Claude API 분석] → [구조화된 JSON]
    ↓
[Jinja2 템플릿] → [.md 스킬 파일]
```

### 워크플로우 B: YouTube 영상 (수동 다운로드)

```
[YouTube URL]
    ↓
[downsub.com 또는 YouTube에서 수동 다운로드]
    ↓
[subtitles/ 폴더에 저장 (.txt/.srt)]
    ↓
[process_local_subtitles.py 실행]
    ↓
[Claude API 분석] → [구조화된 JSON]
    ↓
[Jinja2 템플릿] → [.md 스킬 파일]
```

### 3-Layer 아키텍처

1. **Content Extraction Layer**: WebFetch (블로그) 또는 로컬 파일 읽기 (YouTube)
2. **Analysis Layer**: Claude Sonnet 4.5로 콘텐츠 분석 및 구조화
3. **Generation Layer**: Jinja2 템플릿 기반 스킬 파일 생성

## 작동 방식

### 블로그/정보성 글 처리

1. 블로그 URL 입력
2. WebFetch로 콘텐츠 추출
3. Claude API로 내용 분석
4. 핵심 개념, 코드 예제, 베스트 프랙티스 추출
5. 기존 스킬 형식으로 .md 파일 생성

### YouTube 영상 처리 (IP 차단 회피)

1. downsub.com 또는 YouTube에서 자막 수동 다운로드
2. `subtitles/` 폴더에 `.txt` 또는 `.srt` 파일 저장
3. `python process_local_subtitles.py` 실행
4. Claude API로 자막 내용 분석
5. 핵심 개념, 코드 예제, 베스트 프랙티스 추출
6. 기존 스킬 형식으로 .md 파일 생성

## 사용 방법

### 설치

```bash
cd C:\Users\woosol\youtube-to-skill

# 1. 의존성 설치
pip install anthropic jinja2 tenacity python-dotenv

# 2. 환경 변수 설정
echo ANTHROPIC_API_KEY=your-key-here > .env
```

### 방법 1: 블로그/정보성 글 URL 처리

```python
# WebFetch 도구 사용
from anthropic import Anthropic

client = Anthropic()
content = client.messages.create(
    model="claude-sonnet-4-5-20250929",
    max_tokens=4096,
    tools=[WebFetch],
    messages=[{
        "role": "user",
        "content": "이 블로그 글을 분석해서 Claude Code 스킬로 만들어줘: https://example.com/article"
    }]
)
```

### 방법 2: YouTube 자막 로컬 처리

#### Step 1: 자막 다운로드

**옵션 A: downsub.com 사용**
1. https://downsub.com 방문
2. YouTube URL 입력
3. 자막 다운로드 (.srt 또는 .txt)

**옵션 B: YouTube에서 직접 복사**
1. YouTube 영상 재생
2. "..." 메뉴 → "트랜스크립트 표시" 클릭
3. 텍스트 전체 복사
4. `.txt` 파일로 저장

#### Step 2: 파일 저장

```bash
# subtitles/ 폴더에 저장
# 파일명 형식: video_id.txt 또는 video_id - title.txt

subtitles/
├── 7wPZYk8B6rw.txt
├── e1dj_w5_efk - Modern Frontend.txt
└── prulDeo3giI.srt
```

#### Step 3: 자동 처리

```bash
# 로컬 자막 파일 일괄 처리
python process_local_subtitles.py
```

**출력:**
- `analyzed_from_local.json` (분석 결과)
- `~/.claude/skills/*.md` (생성된 스킬 파일)

## 프로젝트 구조

```
youtube-to-skill/
├── extractors/
│   ├── youtube_extractor_v2.py     # youtube-transcript-api (IP 차단으로 사용 중단)
│   └── __init__.py
├── analyzer/
│   ├── content_analyzer.py         # Claude API 분석
│   └── __init__.py
├── generator/
│   ├── skill_generator.py          # 스킬 파일 생성
│   ├── templates/
│   │   └── default.md.jinja2       # 스킬 템플릿
│   └── __init__.py
├── utils/
│   └── logger.py
├── subtitles/                      # ⭐ 수동 다운로드한 자막 파일
│   ├── video_id.txt
│   └── video_id - title.srt
├── process_local_subtitles.py      # ⭐ 로컬 자막 처리 스크립트
├── batch_process.py                # 배치 처리 (IP 차단으로 사용 불가)
├── urls.txt                        # URL 목록
├── requirements.txt
└── .env                            # API 키
```

## 핵심 기능

### 1. 로컬 자막 파일 처리

```python
from pathlib import Path

def read_subtitle_file(filepath: Path) -> dict:
    """자막 파일 읽기 (.txt 또는 .srt)"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # SRT 형식이면 타임스탬프 제거
    if filepath.suffix == '.srt':
        content = parse_srt(content)

    return {
        'video_id': extract_video_id(filepath.name),
        'title': extract_title(filepath.name),
        'subtitles': content,
        'source_file': filepath.name
    }
```

**특징:**
- `.txt` 및 `.srt` 형식 지원
- 파일명에서 video_id, title 자동 추출
- SRT 타임스탬프 자동 제거

**지원 파일명 형식:**
- `video_id.txt` (예: `7wPZYk8B6rw.txt`)
- `video_id - title.txt` (예: `7wPZYk8B6rw - Claude Skills.txt`)
- `video_id.srt`

### 2. 콘텐츠 분석 (Claude API)

```python
from analyzer.content_analyzer import ContentAnalyzer

analyzer = ContentAnalyzer(api_key=os.getenv('ANTHROPIC_API_KEY'))
analyzed = analyzer.analyze_content(
    subtitle_text=result['subtitles'],
    video_title=result['title']
)

# analyzed = {
#     'skill_name': 'kebab-case-name',
#     'description': '키워드1, 키워드2, ...',
#     'key_concepts': [...],
#     'code_examples': [...],
#     'best_practices': [...],
#     'common_pitfalls': [...]
# }
```

**특징:**
- Claude Sonnet 4.5 사용
- 토큰 제한 (15,000자)
- 기존 스킬 품질 참조

### 3. 스킬 파일 생성 (Jinja2)

```python
from generator.skill_generator import SkillGenerator

generator = SkillGenerator()
filepath = generator.generate_skill_file(
    analyzed_data=analyzed,
    output_dir=os.path.expanduser('~/.claude/skills')
)
```

**특징:**
- 기존 스킬 형식 준수 (YAML + Markdown)
- 코드 예제 문법 하이라이팅
- 태그 자동 생성

## 배치 처리

### 로컬 자막 일괄 처리

```bash
# subtitles/ 폴더에 여러 개 자막 파일 저장 후
python process_local_subtitles.py
```

**처리 과정:**
1. `subtitles/` 폴더에서 `.txt`, `.srt` 파일 자동 검색
2. 각 파일을 순차적으로 읽기
3. Claude API로 분석 (파일당 3분)
4. 스킬 파일 생성 → `~/.claude/skills/`
5. 완료 요약 출력

### 예상 소요 시간

```
- 파일 읽기: 즉시
- Claude 분석: 39분 (13개 × 3분)
- 스킬 생성: 즉시
- 총 약 40분
```

**특징:**
- 순차 처리 (API rate limit 준수)
- 실패 시 로그 기록 (process_local.log)
- 중간 결과 저장 (analyzed_from_local.json)

## 출력 예시

**입력:**
```
https://www.youtube.com/watch?v=7wPZYk8B6rw
```

**출력:**
```markdown
---
name: claude-code-skills-guide
description: Claude스킬, 스킬생성, 스킬활용, ...
---

# Claude Code 스킬 활용 가이드

## 개요

Claude Code 스킬은...

## 핵심 개념

### 스킬 구조

스킬 파일은...

```yaml
---
name: my-skill
description: 키워드, 키워드
---
```

...
```

## 지원 콘텐츠 타입

| 타입 | 방법 | 상태 | 도구 |
|------|------|------|------|
| 블로그/정보성 글 | 자동 | ✅ 가능 | WebFetch |
| YouTube 영상 | 수동 → 로컬 처리 | ⚠️ 수동 | downsub.com + process_local_subtitles.py |
| PDF 문서 | 수동 | 🔜 계획 중 | - |

## 예상 비용

### Claude API 비용
- 자막 길이: 평균 10,000 토큰
- 응답 길이: 평균 5,000 토큰
- 13개 영상: 195,000 토큰
- **예상 비용: ~$1.50**

## 리스크 및 대응

### 리스크 1: YouTube IP 차단 ⚠️
**문제:** youtube-transcript-api가 클라우드 IP에서 차단됨

**대응:**
- downsub.com에서 자막 수동 다운로드
- YouTube "트랜스크립트 표시"에서 복사
- `process_local_subtitles.py`로 로컬 처리

### 리스크 2: 자막 없음
**대응:**
- 영어/한국어 자막이 있는 영상만 선택
- 없는 경우 건너뛰기

### 리스크 3: API 오류
**대응:**
- 토큰 제한 (15,000자)
- 에러 핸들링 및 재시도
- 실패 시 로그 기록

### 리스크 4: 품질 저하
**대응:**
- 프롬프트 최적화
- 기존 고품질 스킬 참조
- 사후 수동 검토

## 참고 자료

### 자막 다운로드
- [downsub.com](https://downsub.com/) - YouTube 자막 다운로드 (무료, 광고 있음)
- YouTube "트랜스크립트 표시" 기능

### 개발 도구
- [Claude API](https://docs.anthropic.com/)
- [Jinja2](https://jinja.palletsprojects.com/)
- [WebFetch 도구](https://docs.anthropic.com/en/docs/build-with-claude/tool-use)

### 프로젝트 파일
- `C:\Users\woosol\youtube-to-skill\process_local_subtitles.py`
- `C:\Users\woosol\youtube-to-skill\analyzer\content_analyzer.py`
- `C:\Users\woosol\youtube-to-skill\generator\skill_generator.py`

## 예시 워크플로우

### 블로그 글 → 스킬

```
입력: https://yozm.wishket.com/magazine/detail/2341/
↓
WebFetch로 콘텐츠 추출
↓
Claude API 분석
↓
출력: modern-frontend-frameworks.md
```

### YouTube 영상 → 스킬

```
입력: https://www.youtube.com/watch?v=7wPZYk8B6rw
↓
downsub.com에서 자막 다운로드 → 7wPZYk8B6rw.txt
↓
subtitles/ 폴더에 저장
↓
python process_local_subtitles.py 실행
↓
출력: claude-code-skills-guide.md
```

## 태그

#URL스킬생성 #YouTube #로컬파일처리 #블로그분석 #WebFetch #downsub #자막추출 #Claude #자동화 #메타스킬 #지식베이스 #콘텐츠분석
