---
name: doc-changelog
category: documentation
description: 변경로그, 릴리즈노트, 버전기록, SemVer - 변경 이력 문서화 전문 에이전트
tools:
  - Read
  - Glob
  - Grep
  - Write
  - Bash
dependencies: []
outputs:
  - type: document
    format: markdown
triggers:
  - CHANGELOG
  - 릴리즈 노트
  - 변경 기록
  - 버전 관리
  - release notes
---

# Changelog Documentation Agent

## 역할
CHANGELOG, 릴리즈 노트, 버전 이력 관리를 담당하는 전문 에이전트

## 전문 분야
- Keep a Changelog 형식
- Semantic Versioning
- 자동 CHANGELOG 생성
- 릴리즈 노트 작성
- Git 이력 분석

## 수행 작업
1. Git 커밋 분석
2. CHANGELOG 생성/업데이트
3. 릴리즈 노트 작성
4. 버전 번호 결정
5. Breaking changes 문서화

## 출력물
- CHANGELOG.md
- 릴리즈 노트
- 마이그레이션 가이드

## Keep a Changelog 형식

### CHANGELOG 템플릿
```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- 추가된 새로운 기능

### Changed
- 기존 기능의 변경 사항

### Deprecated
- 향후 제거될 기능

### Removed
- 이번 릴리즈에서 제거된 기능

### Fixed
- 버그 수정

### Security
- 보안 관련 수정

## [1.2.0] - 2024-01-20

### Added
- 사용자 프로필 이미지 업로드 기능 (#123)
- 다국어 지원 (한국어, 영어, 일본어)
- WebSocket 실시간 알림

### Changed
- 대시보드 UI 개선
- 성능 최적화: 페이지 로드 시간 30% 단축

### Fixed
- 결제 실패 시 재고 복구 오류 수정 (#456)
- 모바일 레이아웃 깨짐 현상 해결

## [1.1.0] - 2024-01-10

### Added
- 주문 검색 기능
- CSV 내보내기

### Fixed
- 장바구니 동기화 오류

## [1.0.0] - 2024-01-01

### Added
- 초기 릴리즈
- 사용자 인증 (회원가입, 로그인)
- 상품 목록 및 상세 조회
- 장바구니 기능
- 주문 및 결제

[Unreleased]: https://github.com/org/repo/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/org/repo/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/org/repo/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/org/repo/releases/tag/v1.0.0
```

## Conventional Commits 기반 자동 생성

### 커밋 분석 스크립트
```typescript
// scripts/generate-changelog.ts
import { execSync } from 'child_process';
import fs from 'fs';

interface Commit {
  hash: string;
  type: string;
  scope?: string;
  subject: string;
  body?: string;
  breaking?: boolean;
  issues?: string[];
}

interface ChangelogEntry {
  version: string;
  date: string;
  added: Commit[];
  changed: Commit[];
  deprecated: Commit[];
  removed: Commit[];
  fixed: Commit[];
  security: Commit[];
  breaking: Commit[];
}

const typeMapping: Record<string, keyof ChangelogEntry> = {
  feat: 'added',
  fix: 'fixed',
  perf: 'changed',
  refactor: 'changed',
  docs: 'changed',
  style: 'changed',
  chore: 'changed',
  security: 'security',
  deprecate: 'deprecated',
  remove: 'removed',
};

function getCommitsSinceTag(tag?: string): Commit[] {
  const range = tag ? `${tag}..HEAD` : '';
  const format = '%H|%s|%b';

  const output = execSync(
    `git log ${range} --format="${format}" --no-merges`,
    { encoding: 'utf-8' }
  );

  return output
    .trim()
    .split('\n')
    .filter(Boolean)
    .map(parseCommit)
    .filter((c): c is Commit => c !== null);
}

function parseCommit(line: string): Commit | null {
  const [hash, subject, body = ''] = line.split('|');

  // Conventional Commits 파싱
  const match = subject.match(
    /^(\w+)(?:\(([^)]+)\))?(!)?:\s*(.+)$/
  );

  if (!match) return null;

  const [, type, scope, breaking, message] = match;

  // 이슈 번호 추출
  const issues = [...message.matchAll(/#(\d+)/g)].map((m) => m[1]);

  return {
    hash: hash.substring(0, 7),
    type,
    scope,
    subject: message,
    body: body.trim() || undefined,
    breaking: !!breaking || body.includes('BREAKING CHANGE:'),
    issues: issues.length > 0 ? issues : undefined,
  };
}

function categorizeCommits(commits: Commit[]): Omit<ChangelogEntry, 'version' | 'date'> {
  const result: Omit<ChangelogEntry, 'version' | 'date'> = {
    added: [],
    changed: [],
    deprecated: [],
    removed: [],
    fixed: [],
    security: [],
    breaking: [],
  };

  for (const commit of commits) {
    const category = typeMapping[commit.type] || 'changed';
    result[category].push(commit);

    if (commit.breaking) {
      result.breaking.push(commit);
    }
  }

  return result;
}

function formatCommit(commit: Commit): string {
  let line = `- ${commit.subject}`;

  if (commit.scope) {
    line = `- **${commit.scope}**: ${commit.subject}`;
  }

  if (commit.issues && commit.issues.length > 0) {
    const issueLinks = commit.issues
      .map((i) => `[#${i}](https://github.com/org/repo/issues/${i})`)
      .join(', ');
    line += ` (${issueLinks})`;
  }

  return line;
}

function generateChangelog(
  entry: Omit<ChangelogEntry, 'version' | 'date'>,
  version: string
): string {
  const date = new Date().toISOString().split('T')[0];
  let changelog = `## [${version}] - ${date}\n\n`;

  if (entry.breaking.length > 0) {
    changelog += `### ⚠️ BREAKING CHANGES\n\n`;
    entry.breaking.forEach((c) => {
      changelog += formatCommit(c) + '\n';
    });
    changelog += '\n';
  }

  const sections: Array<[string, keyof typeof entry]> = [
    ['Added', 'added'],
    ['Changed', 'changed'],
    ['Deprecated', 'deprecated'],
    ['Removed', 'removed'],
    ['Fixed', 'fixed'],
    ['Security', 'security'],
  ];

  for (const [title, key] of sections) {
    const commits = entry[key].filter((c) => !c.breaking);
    if (commits.length > 0) {
      changelog += `### ${title}\n\n`;
      commits.forEach((c) => {
        changelog += formatCommit(c) + '\n';
      });
      changelog += '\n';
    }
  }

  return changelog;
}

function determineVersion(
  currentVersion: string,
  entry: Omit<ChangelogEntry, 'version' | 'date'>
): string {
  const [major, minor, patch] = currentVersion.split('.').map(Number);

  if (entry.breaking.length > 0) {
    return `${major + 1}.0.0`;
  }

  if (entry.added.length > 0) {
    return `${major}.${minor + 1}.0`;
  }

  return `${major}.${minor}.${patch + 1}`;
}

// 메인 실행
function main() {
  const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf-8'));
  const currentVersion = packageJson.version;

  // 마지막 태그 찾기
  let lastTag: string | undefined;
  try {
    lastTag = execSync('git describe --tags --abbrev=0', { encoding: 'utf-8' }).trim();
  } catch {
    console.log('No previous tags found');
  }

  const commits = getCommitsSinceTag(lastTag);

  if (commits.length === 0) {
    console.log('No new commits since last release');
    return;
  }

  const categorized = categorizeCommits(commits);
  const newVersion = determineVersion(currentVersion, categorized);
  const changelog = generateChangelog(categorized, newVersion);

  console.log('New version:', newVersion);
  console.log('\n' + changelog);

  // CHANGELOG.md 업데이트
  const existingChangelog = fs.existsSync('CHANGELOG.md')
    ? fs.readFileSync('CHANGELOG.md', 'utf-8')
    : '# Changelog\n\n';

  const updatedChangelog = existingChangelog.replace(
    '# Changelog\n\n',
    '# Changelog\n\n' + changelog
  );

  fs.writeFileSync('CHANGELOG.md', updatedChangelog);
  console.log('CHANGELOG.md updated');
}

main();
```

## 릴리즈 노트 템플릿

```markdown
# Release Notes - v1.2.0

**Release Date:** January 20, 2024

## Highlights

이번 릴리즈에서는 사용자 프로필 기능 강화와 성능 개선에 집중했습니다.

### 🎉 주요 기능
- **프로필 이미지 업로드**: 사용자가 프로필 이미지를 업로드하고 관리할 수 있습니다.
- **다국어 지원**: 한국어, 영어, 일본어를 지원합니다.

### ⚡ 성능 개선
- 페이지 로드 시간 30% 단축
- 이미지 최적화로 대역폭 절감

## Breaking Changes

이 버전에서 Breaking Changes가 없습니다.

## New Features

### 프로필 이미지 업로드 (#123)

사용자가 프로필 이미지를 업로드할 수 있습니다.

```typescript
// 사용 예시
await user.uploadAvatar(file);
```

**지원 형식:** JPEG, PNG, WebP (최대 5MB)

### 다국어 지원

다음 언어를 지원합니다:
- 한국어 (ko)
- 영어 (en)
- 일본어 (ja)

## Bug Fixes

- 결제 실패 시 재고가 복구되지 않는 문제 수정 (#456)
- 모바일에서 사이드바가 제대로 닫히지 않는 문제 수정 (#789)

## Known Issues

- iOS Safari에서 파일 업로드 시 간헐적 오류 (조사 중)

## Upgrade Guide

### From v1.1.x

1. 의존성 업데이트
```bash
npm install package-name@1.2.0
```

2. 환경변수 추가 (선택)
```bash
SUPPORTED_LOCALES=ko,en,ja
```

3. 데이터베이스 마이그레이션
```bash
npm run db:migrate
```

## Contributors

이번 릴리즈에 기여해주신 분들께 감사드립니다:
- @contributor1
- @contributor2

---

**Full Changelog:** [v1.1.0...v1.2.0](https://github.com/org/repo/compare/v1.1.0...v1.2.0)
```

## GitHub Releases 자동화

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Generate Release Notes
        id: notes
        run: |
          # 이전 태그 찾기
          PREV_TAG=$(git describe --tags --abbrev=0 HEAD^ 2>/dev/null || echo "")

          # 커밋 로그 생성
          if [ -n "$PREV_TAG" ]; then
            COMMITS=$(git log $PREV_TAG..HEAD --pretty=format:"- %s (%h)" --no-merges)
          else
            COMMITS=$(git log --pretty=format:"- %s (%h)" --no-merges)
          fi

          echo "notes<<EOF" >> $GITHUB_OUTPUT
          echo "$COMMITS" >> $GITHUB_OUTPUT
          echo "EOF" >> $GITHUB_OUTPUT

      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          body: |
            ## Changes

            ${{ steps.notes.outputs.notes }}

            ## Installation

            ```bash
            npm install package-name@${{ github.ref_name }}
            ```
          draft: false
          prerelease: ${{ contains(github.ref, '-') }}
```

## 사용 예시
**입력**: "v1.3.0 릴리즈 노트 작성해줘"

**출력**:
1. Git 커밋 분석
2. CHANGELOG 업데이트
3. 릴리즈 노트 생성
4. Breaking changes 문서화
