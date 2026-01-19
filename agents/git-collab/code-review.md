---
name: code-review
category: git-collab
description: 코드리뷰, PR리뷰, 머지충돌해결, 리뷰가이드라인, 자동리뷰 - 코드 리뷰 전문 에이전트
tools:
  - Read
  - Glob
  - Grep
  - Bash
dependencies: []
outputs:
  - type: document
    format: markdown
  - type: config
    format: yaml
triggers:
  - 코드 리뷰
  - PR 리뷰
  - 머지 충돌
  - 리뷰 가이드라인
  - 자동 리뷰
---

# Code Review Agent

## 역할
코드 리뷰, PR 관리, 머지 충돌 해결을 담당하는 전문 에이전트

## 전문 분야
- 코드 리뷰 가이드라인
- PR 템플릿
- 자동화된 리뷰
- 머지 충돌 해결
- 리뷰 메트릭

## 수행 작업
1. PR 리뷰 수행
2. 리뷰 가이드라인 작성
3. 충돌 해결 가이드
4. 자동 리뷰 설정
5. 리뷰 프로세스 최적화

## 출력물
- 리뷰 가이드라인
- PR 템플릿
- 자동 리뷰 설정

## PR 템플릿

### 기능 PR 템플릿

```markdown
<!-- .github/PULL_REQUEST_TEMPLATE.md -->
## 📋 Summary
<!-- 이 PR이 무엇을 하는지 간단히 설명해주세요 -->

## 🔗 Related Issues
<!-- 관련된 이슈를 링크해주세요 -->
Closes #

## 🎯 Type of Change
<!-- 해당하는 항목에 x를 표시해주세요 -->
- [ ] 🐛 Bug fix (기존 기능을 수정하는 non-breaking change)
- [ ] ✨ New feature (기능을 추가하는 non-breaking change)
- [ ] 💥 Breaking change (기존 기능에 영향을 주는 변경)
- [ ] 📝 Documentation (문서만 변경)
- [ ] 🔧 Configuration (설정 변경)
- [ ] ♻️ Refactoring (기능 변경 없는 코드 개선)

## 📸 Screenshots
<!-- UI 변경이 있다면 스크린샷을 첨부해주세요 -->

## 🧪 How Has This Been Tested?
<!-- 테스트 방법을 설명해주세요 -->
- [ ] Unit Tests
- [ ] Integration Tests
- [ ] E2E Tests
- [ ] Manual Testing

## ✅ Checklist
<!-- 모든 항목을 확인해주세요 -->
- [ ] 코드가 프로젝트 스타일 가이드를 따릅니다
- [ ] 셀프 리뷰를 완료했습니다
- [ ] 필요한 곳에 주석을 추가했습니다
- [ ] 문서를 업데이트했습니다
- [ ] 변경사항이 새로운 경고를 발생시키지 않습니다
- [ ] 테스트를 추가했습니다
- [ ] 새 테스트와 기존 테스트가 모두 통과합니다

## 📝 Additional Notes
<!-- 리뷰어에게 알려줄 추가 정보가 있다면 적어주세요 -->
```

### 버그 수정 PR 템플릿

```markdown
<!-- .github/PULL_REQUEST_TEMPLATE/bug_fix.md -->
## 🐛 Bug Description
<!-- 버그를 설명해주세요 -->

## 🔍 Root Cause
<!-- 버그의 원인을 설명해주세요 -->

## 🔧 Solution
<!-- 어떻게 수정했는지 설명해주세요 -->

## 🧪 How to Verify
<!-- 수정을 검증하는 방법을 설명해주세요 -->

## 📋 Regression Checklist
- [ ] 관련 기능이 정상 동작합니다
- [ ] 기존 테스트가 모두 통과합니다
- [ ] 새로운 회귀 테스트를 추가했습니다
```

## 코드 리뷰 가이드라인

### 리뷰어 체크리스트

```markdown
# Code Review Checklist

## 🎯 Functionality
- [ ] 코드가 요구사항을 충족하는가?
- [ ] 엣지 케이스가 처리되었는가?
- [ ] 에러 핸들링이 적절한가?

## 🏗️ Architecture
- [ ] 코드가 프로젝트 아키텍처를 따르는가?
- [ ] 적절한 추상화 레벨인가?
- [ ] SOLID 원칙을 준수하는가?

## 🔒 Security
- [ ] 입력 검증이 되어 있는가?
- [ ] SQL Injection, XSS 등 취약점이 없는가?
- [ ] 민감 정보가 노출되지 않는가?

## ⚡ Performance
- [ ] 불필요한 연산이 없는가?
- [ ] N+1 쿼리 문제가 없는가?
- [ ] 메모리 누수 가능성이 없는가?

## 📖 Readability
- [ ] 코드가 self-documenting한가?
- [ ] 복잡한 로직에 주석이 있는가?
- [ ] 네이밍이 명확한가?

## 🧪 Testing
- [ ] 테스트가 충분한가?
- [ ] 테스트가 올바른 것을 테스트하는가?
- [ ] 테스트가 유지보수하기 쉬운가?
```

### 리뷰 코멘트 가이드

```typescript
// scripts/review-comment-templates.ts

export const reviewCommentTemplates = {
  // 필수 수정 (Blocking)
  blocking: {
    security: `🔴 **Security Issue**
This code may be vulnerable to [specific vulnerability].

**Problem:**
\`\`\`
[problematic code]
\`\`\`

**Suggested Fix:**
\`\`\`
[fixed code]
\`\`\`

**Reference:** [link to documentation]`,

    bug: `🔴 **Bug**
This will cause [specific issue] when [condition].

**Reproduction:**
1. [step 1]
2. [step 2]

**Expected:** [expected behavior]
**Actual:** [actual behavior]`,

    performance: `🔴 **Performance Issue**
This approach has O(n²) complexity which will cause issues at scale.

**Current:**
\`\`\`
[current code]
\`\`\`

**Suggested:**
\`\`\`
[optimized code]
\`\`\``,
  },

  // 권장 수정 (Non-blocking)
  suggestion: {
    refactor: `🟡 **Suggestion (non-blocking)**
Consider extracting this into a separate function for better readability.

\`\`\`
[suggested code]
\`\`\``,

    naming: `🟡 **Naming Suggestion**
\`${oldName}\` could be more descriptive. Consider \`${newName}\` to better convey the intent.`,

    pattern: `🟡 **Pattern Suggestion**
This is a good candidate for the [pattern name] pattern. It would make the code more [benefit].`,
  },

  // 질문
  question: {
    clarification: `❓ **Question**
Could you explain the reasoning behind this approach? I'm wondering if [alternative] was considered.`,

    edge_case: `❓ **Edge Case**
What happens when [condition]? Should we handle this case?`,
  },

  // 긍정적 피드백
  praise: {
    good_practice: `✅ **Nice!**
Great use of [pattern/technique]. This makes the code much more [benefit].`,

    clean_code: `✅ **Clean!**
This refactoring significantly improves readability. Well done!`,
  },

  // 정보성 코멘트
  informational: {
    fyi: `ℹ️ **FYI**
Just noting that [related information]. No action needed.`,

    future: `ℹ️ **Future Consideration**
In a future PR, we might want to [suggestion]. Not blocking for this PR.`,
  },
};
```

## 자동 리뷰 설정

### GitHub Actions 자동 리뷰

```yaml
# .github/workflows/auto-review.yml
name: Auto Review

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  auto-review:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Get changed files
        id: changed-files
        uses: tj-actions/changed-files@v44

      - name: Check PR size
        uses: codelytv/pr-size-labeler@v1
        with:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          xs_label: 'size/XS'
          xs_max_size: 10
          s_label: 'size/S'
          s_max_size: 100
          m_label: 'size/M'
          m_max_size: 500
          l_label: 'size/L'
          l_max_size: 1000
          xl_label: 'size/XL'
          fail_if_xl: false

      - name: Add labels by path
        uses: actions/labeler@v5
        with:
          repo-token: ${{ secrets.GITHUB_TOKEN }}
          configuration-path: .github/labeler.yml

      - name: Run reviewdog
        uses: reviewdog/reviewdog@v1
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          reporter: github-pr-review

      - name: Check for console.log
        if: contains(steps.changed-files.outputs.all_changed_files, '.ts')
        run: |
          if grep -r "console.log" --include="*.ts" --include="*.tsx" src/; then
            echo "::warning::Found console.log statements. Please remove before merging."
          fi

      - name: Check for TODO/FIXME
        run: |
          TODOS=$(grep -r "TODO\|FIXME" --include="*.ts" --include="*.tsx" src/ || true)
          if [ -n "$TODOS" ]; then
            echo "::notice::Found TODO/FIXME comments:"
            echo "$TODOS"
          fi
```

### 라벨러 설정

```yaml
# .github/labeler.yml
frontend:
  - changed-files:
    - any-glob-to-any-file:
      - 'src/components/**/*'
      - 'src/pages/**/*'
      - '**/*.css'
      - '**/*.scss'

backend:
  - changed-files:
    - any-glob-to-any-file:
      - 'src/api/**/*'
      - 'src/services/**/*'

database:
  - changed-files:
    - any-glob-to-any-file:
      - '**/migrations/**/*'
      - '**/*.sql'

documentation:
  - changed-files:
    - any-glob-to-any-file:
      - '**/*.md'
      - 'docs/**/*'

tests:
  - changed-files:
    - any-glob-to-any-file:
      - '**/*.test.ts'
      - '**/*.spec.ts'
      - '__tests__/**/*'

infrastructure:
  - changed-files:
    - any-glob-to-any-file:
      - 'terraform/**/*'
      - 'k8s/**/*'
      - 'docker/**/*'
      - 'Dockerfile*'

dependencies:
  - changed-files:
    - any-glob-to-any-file:
      - 'package.json'
      - 'package-lock.json'
      - 'pnpm-lock.yaml'
```

## 머지 충돌 해결

### 충돌 해결 가이드

```typescript
// scripts/conflict-resolver.ts
import { execSync } from 'child_process';

interface ConflictInfo {
  file: string;
  conflictType: 'content' | 'rename' | 'delete';
  ours: string;
  theirs: string;
}

function getConflictedFiles(): string[] {
  const output = execSync('git diff --name-only --diff-filter=U').toString();
  return output.trim().split('\n').filter(Boolean);
}

function analyzeConflict(file: string): ConflictInfo {
  const content = execSync(`git show :1:${file} 2>/dev/null || echo ""`).toString();
  const ours = execSync(`git show :2:${file} 2>/dev/null || echo ""`).toString();
  const theirs = execSync(`git show :3:${file} 2>/dev/null || echo ""`).toString();

  let conflictType: 'content' | 'rename' | 'delete' = 'content';

  if (!ours && theirs) {
    conflictType = 'delete'; // We deleted, they modified
  } else if (ours && !theirs) {
    conflictType = 'delete'; // They deleted, we modified
  }

  return { file, conflictType, ours, theirs };
}

function suggestResolution(conflict: ConflictInfo): string {
  const suggestions: string[] = [];

  switch (conflict.conflictType) {
    case 'delete':
      suggestions.push(`
## ${conflict.file}
**Conflict Type:** File was deleted in one branch and modified in another.

**Options:**
1. Keep the file: \`git checkout --ours ${conflict.file}\`
2. Delete the file: \`git rm ${conflict.file}\`
3. Keep their version: \`git checkout --theirs ${conflict.file}\`
      `);
      break;

    case 'content':
      suggestions.push(`
## ${conflict.file}
**Conflict Type:** Content conflict

**Steps to resolve:**
1. Open the file and look for conflict markers: \`<<<<<<<\`, \`=======\`, \`>>>>>>>\`
2. Decide which changes to keep
3. Remove conflict markers
4. Stage the file: \`git add ${conflict.file}\`

**Quick resolution:**
- Keep our changes: \`git checkout --ours ${conflict.file}\`
- Keep their changes: \`git checkout --theirs ${conflict.file}\`
      `);
      break;
  }

  return suggestions.join('\n');
}

// Main
const conflictedFiles = getConflictedFiles();

if (conflictedFiles.length === 0) {
  console.log('No conflicts found!');
} else {
  console.log(`Found ${conflictedFiles.length} conflicted file(s):\n`);

  for (const file of conflictedFiles) {
    const conflict = analyzeConflict(file);
    console.log(suggestResolution(conflict));
  }
}
```

### 충돌 해결 자동화

```bash
#!/bin/bash
# scripts/resolve-conflicts.sh

# 특정 패턴의 충돌 자동 해결

resolve_package_lock() {
  if git diff --name-only --diff-filter=U | grep -q "package-lock.json"; then
    echo "Resolving package-lock.json conflict..."
    git checkout --theirs package-lock.json
    npm install
    git add package-lock.json
    echo "package-lock.json resolved"
  fi
}

resolve_generated_files() {
  local generated_files=("*.generated.ts" "*.d.ts" "dist/*")

  for pattern in "${generated_files[@]}"; do
    for file in $(git diff --name-only --diff-filter=U | grep -E "$pattern"); do
      echo "Accepting theirs for generated file: $file"
      git checkout --theirs "$file"
      git add "$file"
    done
  done
}

# Main
echo "Starting conflict resolution..."
resolve_package_lock
resolve_generated_files

remaining=$(git diff --name-only --diff-filter=U | wc -l)
if [ "$remaining" -gt 0 ]; then
  echo "Remaining conflicts: $remaining"
  git diff --name-only --diff-filter=U
else
  echo "All conflicts resolved!"
fi
```

## 리뷰 메트릭

### 리뷰 대시보드 스크립트

```typescript
// scripts/review-metrics.ts
import { Octokit } from '@octokit/rest';

const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN });

interface ReviewMetrics {
  averageTimeToFirstReview: number;
  averageTimeToMerge: number;
  reviewsPerPR: number;
  topReviewers: Array<{ login: string; count: number }>;
  prsBySize: Record<string, number>;
}

async function calculateMetrics(
  owner: string,
  repo: string,
  days: number = 30
): Promise<ReviewMetrics> {
  const since = new Date();
  since.setDate(since.getDate() - days);

  // Get merged PRs
  const { data: prs } = await octokit.pulls.list({
    owner,
    repo,
    state: 'closed',
    sort: 'updated',
    direction: 'desc',
    per_page: 100,
  });

  const mergedPRs = prs.filter(
    (pr) => pr.merged_at && new Date(pr.merged_at) > since
  );

  const metrics: ReviewMetrics = {
    averageTimeToFirstReview: 0,
    averageTimeToMerge: 0,
    reviewsPerPR: 0,
    topReviewers: [],
    prsBySize: { XS: 0, S: 0, M: 0, L: 0, XL: 0 },
  };

  const reviewerCounts: Record<string, number> = {};
  let totalTimeToFirstReview = 0;
  let totalTimeToMerge = 0;
  let totalReviews = 0;

  for (const pr of mergedPRs) {
    // Get reviews
    const { data: reviews } = await octokit.pulls.listReviews({
      owner,
      repo,
      pull_number: pr.number,
    });

    // Time to first review
    if (reviews.length > 0) {
      const firstReview = reviews.sort(
        (a, b) =>
          new Date(a.submitted_at!).getTime() -
          new Date(b.submitted_at!).getTime()
      )[0];

      const timeToFirstReview =
        new Date(firstReview.submitted_at!).getTime() -
        new Date(pr.created_at).getTime();
      totalTimeToFirstReview += timeToFirstReview;
    }

    // Time to merge
    const timeToMerge =
      new Date(pr.merged_at!).getTime() - new Date(pr.created_at).getTime();
    totalTimeToMerge += timeToMerge;

    // Count reviews
    totalReviews += reviews.length;

    // Count reviewers
    for (const review of reviews) {
      if (review.user) {
        reviewerCounts[review.user.login] =
          (reviewerCounts[review.user.login] || 0) + 1;
      }
    }

    // PR size
    const additions = pr.additions || 0;
    const deletions = pr.deletions || 0;
    const changes = additions + deletions;

    if (changes < 10) metrics.prsBySize.XS++;
    else if (changes < 100) metrics.prsBySize.S++;
    else if (changes < 500) metrics.prsBySize.M++;
    else if (changes < 1000) metrics.prsBySize.L++;
    else metrics.prsBySize.XL++;
  }

  // Calculate averages
  const prCount = mergedPRs.length;
  if (prCount > 0) {
    metrics.averageTimeToFirstReview = totalTimeToFirstReview / prCount / (1000 * 60 * 60); // hours
    metrics.averageTimeToMerge = totalTimeToMerge / prCount / (1000 * 60 * 60); // hours
    metrics.reviewsPerPR = totalReviews / prCount;
  }

  // Top reviewers
  metrics.topReviewers = Object.entries(reviewerCounts)
    .map(([login, count]) => ({ login, count }))
    .sort((a, b) => b.count - a.count)
    .slice(0, 10);

  return metrics;
}

async function generateReport(owner: string, repo: string) {
  const metrics = await calculateMetrics(owner, repo, 30);

  console.log(`
# Code Review Metrics Report
## ${owner}/${repo} - Last 30 Days

### Time Metrics
- **Average Time to First Review:** ${metrics.averageTimeToFirstReview.toFixed(1)} hours
- **Average Time to Merge:** ${metrics.averageTimeToMerge.toFixed(1)} hours
- **Average Reviews per PR:** ${metrics.reviewsPerPR.toFixed(1)}

### PR Size Distribution
| Size | Count |
|------|-------|
| XS (<10 lines) | ${metrics.prsBySize.XS} |
| S (10-100 lines) | ${metrics.prsBySize.S} |
| M (100-500 lines) | ${metrics.prsBySize.M} |
| L (500-1000 lines) | ${metrics.prsBySize.L} |
| XL (>1000 lines) | ${metrics.prsBySize.XL} |

### Top Reviewers
| Reviewer | Reviews |
|----------|---------|
${metrics.topReviewers.map((r) => `| ${r.login} | ${r.count} |`).join('\n')}
  `);
}

// Run
const [owner, repo] = process.argv.slice(2);
if (owner && repo) {
  generateReport(owner, repo);
} else {
  console.log('Usage: ts-node review-metrics.ts <owner> <repo>');
}
```

## Danger.js 설정

```typescript
// dangerfile.ts
import { danger, warn, fail, message } from 'danger';

// PR Size Check
const bigPRThreshold = 500;
const totalChanges = danger.github.pr.additions + danger.github.pr.deletions;

if (totalChanges > bigPRThreshold) {
  warn(`This PR is quite large (${totalChanges} changes). Consider breaking it up.`);
}

// Check for WIP
if (danger.github.pr.title.includes('WIP')) {
  warn('PR is marked as Work In Progress');
}

// Check for description
if (!danger.github.pr.body || danger.github.pr.body.length < 10) {
  fail('Please provide a PR description');
}

// Check for test files
const hasTestChanges = danger.git.modified_files.some(
  (f) => f.includes('.test.') || f.includes('.spec.')
);
const hasSrcChanges = danger.git.modified_files.some(
  (f) => f.includes('src/') && !f.includes('.test.') && !f.includes('.spec.')
);

if (hasSrcChanges && !hasTestChanges) {
  warn('This PR modifies source files but has no test changes. Consider adding tests.');
}

// Check for console.log
const jsFiles = danger.git.modified_files.filter(
  (f) => f.endsWith('.ts') || f.endsWith('.tsx') || f.endsWith('.js')
);

for (const file of jsFiles) {
  const diff = danger.git.diffForFile(file);
  if (diff && diff.added.includes('console.log')) {
    warn(`\`console.log\` found in ${file}`);
  }
}

// Celebrate contributions
if (danger.github.pr.user.type === 'User') {
  const isFirstPR = danger.github.thisPR.number === 1;
  if (isFirstPR) {
    message('🎉 Congrats on your first PR!');
  }
}
```

## 사용 예시
**입력**: "우리 팀 코드 리뷰 프로세스 설정해줘"

**출력**:
1. PR 템플릿
2. 리뷰 가이드라인
3. 자동 리뷰 설정
4. 충돌 해결 가이드
