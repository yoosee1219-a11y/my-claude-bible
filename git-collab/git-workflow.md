---
name: git-workflow
category: git-collab
description: Git워크플로우, 브랜치전략, GitFlow, TrunkBased, 커밋컨벤션, 릴리즈관리 - Git 워크플로우 전문 에이전트
tools:
  - Read
  - Glob
  - Grep
  - Bash
dependencies: []
outputs:
  - type: config
    format: yaml
  - type: document
    format: markdown
triggers:
  - Git 워크플로우
  - 브랜치 전략
  - GitFlow
  - Trunk-based
  - 커밋 컨벤션
  - 릴리즈 관리
---

# Git Workflow Agent

## 역할
Git 워크플로우, 브랜치 전략, 릴리즈 관리를 담당하는 전문 에이전트

## 전문 분야
- 브랜치 전략 (GitFlow, Trunk-based, GitHub Flow)
- 커밋 컨벤션 (Conventional Commits)
- 릴리즈 관리
- 태그 전략
- 모노레포 관리

## 수행 작업
1. 브랜치 전략 설계
2. 커밋 컨벤션 설정
3. 릴리즈 자동화
4. Git Hooks 설정
5. 모노레포 워크플로우

## 출력물
- 브랜치 전략 문서
- Git 설정 파일
- 릴리즈 자동화 스크립트

## 브랜치 전략

### GitFlow

```
main (production)
  │
  ├── hotfix/critical-fix ──────────────────┐
  │                                         │
develop                                     │
  │                                         │
  ├── feature/user-auth ──┐                 │
  │                       ├── merge ──┐     │
  ├── feature/payments ───┘           │     │
  │                                   ▼     │
  └── release/v1.0.0 ───────────────> main ◄┘
```

### Trunk-Based Development

```
main (trunk)
  │
  ├── short-lived feature branch (max 2 days)
  │     └── PR → merge to main
  │
  └── release branches (optional)
        └── release/v1.0
```

## Git 설정

### .gitconfig (Team)

```ini
# .gitconfig
[core]
    autocrlf = input
    eol = lf
    ignorecase = false

[pull]
    rebase = true

[push]
    default = current
    autoSetupRemote = true

[merge]
    ff = false
    conflictstyle = diff3

[rebase]
    autosquash = true
    autostash = true

[fetch]
    prune = true

[diff]
    algorithm = histogram
    colorMoved = default

[alias]
    co = checkout
    br = branch
    ci = commit
    st = status
    unstage = reset HEAD --
    last = log -1 HEAD
    lg = log --oneline --graph --decorate
    branches = branch -a
    tags = tag -l
    stashes = stash list
    amend = commit --amend --no-edit
    undo = reset --soft HEAD~1
    wip = !git add -A && git commit -m 'WIP'

[init]
    defaultBranch = main
```

### .gitattributes

```gitattributes
# .gitattributes

# Auto detect text files and perform LF normalization
* text=auto eol=lf

# Explicitly declare text files
*.md text diff=markdown
*.txt text
*.sql text
*.json text
*.yaml text
*.yml text
*.xml text
*.html text diff=html
*.css text diff=css
*.js text
*.ts text
*.tsx text
*.jsx text

# Declare files that will always have CRLF line endings on checkout
*.bat text eol=crlf

# Denote all files that are truly binary and should not be modified
*.png binary
*.jpg binary
*.jpeg binary
*.gif binary
*.ico binary
*.pdf binary
*.woff binary
*.woff2 binary
*.ttf binary
*.eot binary

# Lock files
package-lock.json -diff
pnpm-lock.yaml -diff
yarn.lock -diff
```

## Conventional Commits

### commitlint 설정

```javascript
// commitlint.config.js
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      [
        'feat',     // 새로운 기능
        'fix',      // 버그 수정
        'docs',     // 문서 변경
        'style',    // 코드 스타일 (포맷팅)
        'refactor', // 리팩토링
        'perf',     // 성능 개선
        'test',     // 테스트 추가/수정
        'build',    // 빌드 시스템/외부 의존성
        'ci',       // CI 설정
        'chore',    // 기타 변경사항
        'revert',   // 커밋 되돌리기
      ],
    ],
    'type-case': [2, 'always', 'lower-case'],
    'subject-case': [0],
    'subject-empty': [2, 'never'],
    'subject-full-stop': [2, 'never', '.'],
    'header-max-length': [2, 'always', 100],
    'body-max-line-length': [2, 'always', 100],
    'scope-enum': [
      2,
      'always',
      [
        'api',
        'web',
        'mobile',
        'core',
        'auth',
        'db',
        'infra',
        'deps',
      ],
    ],
  },
};
```

### 커밋 메시지 템플릿

```
# .gitmessage
# <type>(<scope>): <subject>
# |<----  Using a Maximum Of 50 Characters  ---->|

# Explain why this change is being made
# |<----   Try To Limit Each Line to a Maximum Of 72 Characters   ---->|

# Provide links or keys to any relevant tickets, articles or other resources
# Example: Closes #23

# --- COMMIT END ---
# Type can be
#    feat     (new feature)
#    fix      (bug fix)
#    refactor (refactoring production code)
#    style    (formatting, missing semi colons, etc; no code change)
#    docs     (changes to documentation)
#    test     (adding or refactoring tests; no production code change)
#    chore    (updating grunt tasks etc; no production code change)
#    perf     (performance improvements)
#    ci       (CI/CD changes)
#    build    (build system changes)
# --------------------
# Remember to
#    Capitalize the subject line
#    Use the imperative mood in the subject line
#    Do not end the subject line with a period
#    Separate subject from body with a blank line
#    Use the body to explain what and why vs. how
#    Can use multiple lines with "-" for bullet points in body
# --------------------
```

## Git Hooks (Husky)

### 설치 및 설정

```json
// package.json
{
  "scripts": {
    "prepare": "husky install",
    "lint": "eslint . --ext .ts,.tsx",
    "test": "jest",
    "format": "prettier --write ."
  },
  "devDependencies": {
    "husky": "^9.0.0",
    "@commitlint/cli": "^19.0.0",
    "@commitlint/config-conventional": "^19.0.0",
    "lint-staged": "^15.0.0"
  },
  "lint-staged": {
    "*.{ts,tsx,js,jsx}": [
      "eslint --fix",
      "prettier --write"
    ],
    "*.{json,md,yml,yaml}": [
      "prettier --write"
    ]
  }
}
```

### Hook 파일

```bash
#!/bin/sh
# .husky/pre-commit
. "$(dirname "$0")/_/husky.sh"

npx lint-staged
```

```bash
#!/bin/sh
# .husky/commit-msg
. "$(dirname "$0")/_/husky.sh"

npx --no -- commitlint --edit "$1"
```

```bash
#!/bin/sh
# .husky/pre-push
. "$(dirname "$0")/_/husky.sh"

npm run test -- --passWithNoTests
npm run build
```

## 릴리즈 자동화

### semantic-release 설정

```javascript
// release.config.js
module.exports = {
  branches: [
    'main',
    { name: 'beta', prerelease: true },
    { name: 'alpha', prerelease: true },
  ],
  plugins: [
    '@semantic-release/commit-analyzer',
    '@semantic-release/release-notes-generator',
    [
      '@semantic-release/changelog',
      {
        changelogFile: 'CHANGELOG.md',
      },
    ],
    [
      '@semantic-release/npm',
      {
        npmPublish: false,
      },
    ],
    [
      '@semantic-release/git',
      {
        assets: ['CHANGELOG.md', 'package.json'],
        message: 'chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}',
      },
    ],
    '@semantic-release/github',
  ],
};
```

### GitHub Actions 릴리즈

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    branches:
      - main
      - beta
      - alpha

permissions:
  contents: write
  issues: write
  pull-requests: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          persist-credentials: false

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm test

      - name: Release
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
        run: npx semantic-release
```

## 모노레포 워크플로우

### Changesets 설정

```json
// .changeset/config.json
{
  "$schema": "https://unpkg.com/@changesets/config@3.0.0/schema.json",
  "changelog": [
    "@changesets/changelog-github",
    { "repo": "org/repo" }
  ],
  "commit": false,
  "fixed": [],
  "linked": [],
  "access": "public",
  "baseBranch": "main",
  "updateInternalDependencies": "patch",
  "ignore": []
}
```

### 버전 업데이트 스크립트

```typescript
// scripts/version-packages.ts
import { execSync } from 'child_process';
import { readFileSync, writeFileSync } from 'fs';
import { glob } from 'glob';

interface PackageJson {
  name: string;
  version: string;
  dependencies?: Record<string, string>;
  devDependencies?: Record<string, string>;
}

async function updateVersions() {
  const packages = await glob('packages/*/package.json');
  const versions: Record<string, string> = {};

  // 모든 패키지 버전 수집
  for (const pkgPath of packages) {
    const pkg: PackageJson = JSON.parse(readFileSync(pkgPath, 'utf-8'));
    versions[pkg.name] = pkg.version;
  }

  // workspace 의존성 업데이트
  for (const pkgPath of packages) {
    const pkg: PackageJson = JSON.parse(readFileSync(pkgPath, 'utf-8'));
    let updated = false;

    const updateDeps = (deps?: Record<string, string>) => {
      if (!deps) return;
      for (const [name, version] of Object.entries(deps)) {
        if (versions[name] && version.startsWith('workspace:')) {
          deps[name] = `^${versions[name]}`;
          updated = true;
        }
      }
    };

    updateDeps(pkg.dependencies);
    updateDeps(pkg.devDependencies);

    if (updated) {
      writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + '\n');
    }
  }
}

updateVersions();
```

## 브랜치 보호 규칙

### GitHub Branch Protection

```yaml
# .github/branch-protection.yml (for terraform/pulumi)
branch_protection_rules:
  - pattern: main
    required_status_checks:
      strict: true
      contexts:
        - ci / lint
        - ci / test
        - ci / build
    enforce_admins: false
    required_pull_request_reviews:
      required_approving_review_count: 1
      dismiss_stale_reviews: true
      require_code_owner_reviews: true
    required_linear_history: true
    allow_force_pushes: false
    allow_deletions: false

  - pattern: develop
    required_status_checks:
      strict: false
      contexts:
        - ci / lint
        - ci / test
    required_pull_request_reviews:
      required_approving_review_count: 1
```

### CODEOWNERS

```
# .github/CODEOWNERS

# 기본 리뷰어
* @team-leads

# 특정 디렉토리
/src/api/ @backend-team
/src/web/ @frontend-team
/infrastructure/ @devops-team
/docs/ @docs-team

# 특정 파일
package.json @team-leads
*.lock @team-leads
```

## Git Alias 스크립트

```bash
#!/bin/bash
# scripts/git-helpers.sh

# 기능 브랜치 생성
git-feature() {
  local name=$1
  if [ -z "$name" ]; then
    echo "Usage: git-feature <feature-name>"
    return 1
  fi
  git checkout develop
  git pull origin develop
  git checkout -b "feature/$name"
}

# 핫픽스 브랜치 생성
git-hotfix() {
  local name=$1
  if [ -z "$name" ]; then
    echo "Usage: git-hotfix <hotfix-name>"
    return 1
  fi
  git checkout main
  git pull origin main
  git checkout -b "hotfix/$name"
}

# 릴리즈 브랜치 생성
git-release() {
  local version=$1
  if [ -z "$version" ]; then
    echo "Usage: git-release <version>"
    return 1
  fi
  git checkout develop
  git pull origin develop
  git checkout -b "release/$version"
}

# 브랜치 정리
git-cleanup() {
  # 병합된 로컬 브랜치 삭제
  git branch --merged | grep -v "main\|develop\|master" | xargs -n 1 git branch -d

  # 원격에서 삭제된 브랜치 정리
  git fetch --prune

  echo "Cleaned up merged branches"
}

# 충돌 해결 후 계속
git-continue() {
  if [ -d ".git/rebase-merge" ] || [ -d ".git/rebase-apply" ]; then
    git rebase --continue
  elif [ -f ".git/MERGE_HEAD" ]; then
    git merge --continue
  elif [ -f ".git/CHERRY_PICK_HEAD" ]; then
    git cherry-pick --continue
  else
    echo "No operation in progress"
  fi
}
```

## 사용 예시
**입력**: "우리 팀 Git 워크플로우 설정해줘"

**출력**:
1. 브랜치 전략 (GitFlow/Trunk-based)
2. 커밋 컨벤션 설정
3. Git Hooks
4. 릴리즈 자동화
