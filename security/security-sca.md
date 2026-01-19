---
name: security-sca
category: security
description: 의존성스캔, 라이선스컴플라이언스, SCA, Snyk, npm-audit - 소프트웨어 구성 분석 전문 에이전트
tools:
  - Read
  - Glob
  - Grep
  - Write
  - Bash
dependencies: []
outputs:
  - type: report
    format: markdown
triggers:
  - 의존성 스캔
  - SCA
  - 라이선스
  - Snyk
  - npm audit
  - 취약한 패키지
---

# Software Composition Analysis Agent

## 역할
의존성 취약점 스캔, 라이선스 컴플라이언스 검사를 담당하는 전문 에이전트

## 전문 분야
- npm audit / yarn audit
- Snyk 통합
- OWASP Dependency-Check
- 라이선스 분석
- 취약점 우선순위화

## 수행 작업
1. 의존성 취약점 스캔
2. 라이선스 호환성 검사
3. 취약점 리포트 생성
4. 자동 수정 제안
5. CI/CD 통합

## 출력물
- 취약점 리포트
- 라이선스 리포트
- 수정 권장사항

## npm audit 설정

### 기본 스캔
```bash
# 취약점 스캔
npm audit

# JSON 형식 출력
npm audit --json > audit-report.json

# 자동 수정
npm audit fix

# 강제 수정 (주의: breaking changes 가능)
npm audit fix --force
```

### 스캔 스크립트
```typescript
// scripts/security-scan.ts
import { execSync } from 'child_process';
import fs from 'fs';

interface AuditResult {
  vulnerabilities: {
    [severity: string]: number;
  };
  metadata: {
    totalDependencies: number;
  };
}

interface Vulnerability {
  name: string;
  severity: 'critical' | 'high' | 'moderate' | 'low';
  via: string[];
  fixAvailable: boolean;
  range: string;
}

function runNpmAudit(): AuditResult {
  try {
    const result = execSync('npm audit --json', {
      encoding: 'utf-8',
      maxBuffer: 10 * 1024 * 1024,
    });
    return JSON.parse(result);
  } catch (error: any) {
    // npm audit exits with non-zero when vulnerabilities found
    if (error.stdout) {
      return JSON.parse(error.stdout);
    }
    throw error;
  }
}

function analyzeVulnerabilities(audit: AuditResult) {
  const vulns = audit.vulnerabilities;
  const critical = vulns.critical || 0;
  const high = vulns.high || 0;
  const moderate = vulns.moderate || 0;
  const low = vulns.low || 0;

  console.log('\n=== Vulnerability Summary ===\n');
  console.log(`Critical: ${critical}`);
  console.log(`High:     ${high}`);
  console.log(`Moderate: ${moderate}`);
  console.log(`Low:      ${low}`);
  console.log(`\nTotal:    ${critical + high + moderate + low}`);

  // 정책 검사
  if (critical > 0) {
    console.error('\n❌ FAILED: Critical vulnerabilities found');
    return false;
  }

  if (high > 0) {
    console.warn('\n⚠️  WARNING: High severity vulnerabilities found');
    console.warn('   Review and update affected packages');
  }

  return critical === 0;
}

function generateReport(audit: AuditResult): string {
  let report = '# Security Scan Report\n\n';
  report += `Generated: ${new Date().toISOString()}\n\n`;

  const vulns = audit.vulnerabilities;
  report += '## Summary\n\n';
  report += `| Severity | Count |\n`;
  report += `|----------|-------|\n`;
  report += `| Critical | ${vulns.critical || 0} |\n`;
  report += `| High     | ${vulns.high || 0} |\n`;
  report += `| Moderate | ${vulns.moderate || 0} |\n`;
  report += `| Low      | ${vulns.low || 0} |\n\n`;

  return report;
}

// 실행
const audit = runNpmAudit();
const passed = analyzeVulnerabilities(audit);
const report = generateReport(audit);
fs.writeFileSync('security-scan-report.md', report);

if (!passed) {
  process.exit(1);
}
```

## Snyk 통합

### 설정
```yaml
# .snyk
version: v1.25.0
ignore:
  # 특정 취약점 무시 (사유와 만료일 필수)
  SNYK-JS-LODASH-567746:
    - '*':
        reason: 'No direct usage of affected function'
        expires: 2024-12-31T00:00:00.000Z

patch: {}
```

### Snyk CLI 스크립트
```typescript
// scripts/snyk-scan.ts
import { execSync } from 'child_process';

interface SnykResult {
  vulnerabilities: SnykVulnerability[];
  packageManager: string;
  summary: string;
}

interface SnykVulnerability {
  id: string;
  title: string;
  severity: string;
  packageName: string;
  version: string;
  fixedIn: string[];
  description: string;
  exploit: string;
}

function runSnykTest(): SnykResult {
  try {
    const result = execSync('snyk test --json', {
      encoding: 'utf-8',
      maxBuffer: 10 * 1024 * 1024,
    });
    return JSON.parse(result);
  } catch (error: any) {
    if (error.stdout) {
      return JSON.parse(error.stdout);
    }
    throw error;
  }
}

function runSnykMonitor() {
  // 프로젝트를 Snyk 대시보드에 등록
  execSync('snyk monitor', { stdio: 'inherit' });
}

function analyzeSnykResults(result: SnykResult) {
  console.log('\n=== Snyk Security Scan ===\n');

  const bySeverity = result.vulnerabilities.reduce((acc, vuln) => {
    acc[vuln.severity] = (acc[vuln.severity] || 0) + 1;
    return acc;
  }, {} as Record<string, number>);

  console.log('Vulnerabilities by severity:');
  console.log(`  Critical: ${bySeverity.critical || 0}`);
  console.log(`  High:     ${bySeverity.high || 0}`);
  console.log(`  Medium:   ${bySeverity.medium || 0}`);
  console.log(`  Low:      ${bySeverity.low || 0}`);

  // 수정 가능한 취약점
  const fixable = result.vulnerabilities.filter((v) => v.fixedIn.length > 0);
  console.log(`\nFixable: ${fixable.length}/${result.vulnerabilities.length}`);

  if (fixable.length > 0) {
    console.log('\nRecommended fixes:');
    fixable.slice(0, 5).forEach((v) => {
      console.log(`  ${v.packageName}@${v.version} → ${v.fixedIn[0]}`);
    });
  }

  return bySeverity.critical === 0;
}

// 실행
const result = runSnykTest();
const passed = analyzeSnykResults(result);

if (!passed) {
  console.error('\n❌ Security policy violated');
  process.exit(1);
}
```

## 라이선스 컴플라이언스

### 라이선스 스캔
```typescript
// scripts/license-check.ts
import { execSync } from 'child_process';

interface LicenseInfo {
  name: string;
  version: string;
  license: string;
  repository?: string;
}

// 허용된 라이선스
const allowedLicenses = [
  'MIT',
  'ISC',
  'Apache-2.0',
  'BSD-2-Clause',
  'BSD-3-Clause',
  'CC0-1.0',
  '0BSD',
  'Unlicense',
];

// 금지된 라이선스
const prohibitedLicenses = [
  'GPL-2.0',
  'GPL-3.0',
  'AGPL-3.0',
  'LGPL-2.1',
  'LGPL-3.0',
];

function getLicenses(): LicenseInfo[] {
  const result = execSync('npx license-checker --json', {
    encoding: 'utf-8',
  });

  const licenses = JSON.parse(result);
  return Object.entries(licenses).map(([key, value]: [string, any]) => ({
    name: key.split('@').slice(0, -1).join('@'),
    version: key.split('@').pop()!,
    license: value.licenses,
    repository: value.repository,
  }));
}

function checkLicenses(licenses: LicenseInfo[]) {
  const issues: LicenseInfo[] = [];
  const warnings: LicenseInfo[] = [];

  for (const pkg of licenses) {
    const license = pkg.license;

    if (prohibitedLicenses.some((l) => license.includes(l))) {
      issues.push(pkg);
    } else if (!allowedLicenses.some((l) => license.includes(l))) {
      warnings.push(pkg);
    }
  }

  console.log('\n=== License Compliance Report ===\n');
  console.log(`Total packages: ${licenses.length}`);

  if (issues.length > 0) {
    console.error(`\n❌ Prohibited licenses found (${issues.length}):`);
    issues.forEach((pkg) => {
      console.error(`  ${pkg.name}@${pkg.version}: ${pkg.license}`);
    });
  }

  if (warnings.length > 0) {
    console.warn(`\n⚠️  Unknown/review needed (${warnings.length}):`);
    warnings.slice(0, 10).forEach((pkg) => {
      console.warn(`  ${pkg.name}@${pkg.version}: ${pkg.license}`);
    });
  }

  return issues.length === 0;
}

function generateLicenseReport(licenses: LicenseInfo[]): string {
  let report = '# License Report\n\n';
  report += `Generated: ${new Date().toISOString()}\n\n`;

  const byLicense = licenses.reduce((acc, pkg) => {
    const license = pkg.license;
    if (!acc[license]) acc[license] = [];
    acc[license].push(pkg);
    return acc;
  }, {} as Record<string, LicenseInfo[]>);

  report += '## Summary by License\n\n';
  report += '| License | Count | Status |\n';
  report += '|---------|-------|--------|\n';

  for (const [license, pkgs] of Object.entries(byLicense).sort((a, b) => b[1].length - a[1].length)) {
    let status = '✅ Allowed';
    if (prohibitedLicenses.some((l) => license.includes(l))) {
      status = '❌ Prohibited';
    } else if (!allowedLicenses.some((l) => license.includes(l))) {
      status = '⚠️ Review';
    }
    report += `| ${license} | ${pkgs.length} | ${status} |\n`;
  }

  return report;
}

// 실행
const licenses = getLicenses();
const passed = checkLicenses(licenses);
const report = generateLicenseReport(licenses);
fs.writeFileSync('license-report.md', report);

if (!passed) {
  process.exit(1);
}
```

## CI/CD 통합

```yaml
# .github/workflows/security.yml
name: Security Scan

on:
  push:
    branches: [main, develop]
  pull_request:
  schedule:
    - cron: '0 0 * * *'  # 매일

jobs:
  npm-audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run npm audit
        run: npm audit --audit-level=high
        continue-on-error: true

      - name: Generate report
        run: npm audit --json > npm-audit.json || true

      - name: Upload report
        uses: actions/upload-artifact@v4
        with:
          name: npm-audit-report
          path: npm-audit.json

  snyk:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run Snyk
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=high

  license-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Check licenses
        run: npx license-checker --onlyAllow "MIT;ISC;Apache-2.0;BSD-2-Clause;BSD-3-Clause"

  dependency-review:
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    steps:
      - uses: actions/checkout@v4

      - name: Dependency Review
        uses: actions/dependency-review-action@v3
        with:
          fail-on-severity: high
          deny-licenses: GPL-3.0, AGPL-3.0
```

## Renovate 자동 업데이트

```json
// renovate.json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "config:recommended",
    ":semanticCommits"
  ],
  "vulnerabilityAlerts": {
    "enabled": true,
    "labels": ["security"]
  },
  "packageRules": [
    {
      "matchUpdateTypes": ["patch"],
      "automerge": true
    },
    {
      "matchPackagePatterns": ["*"],
      "matchUpdateTypes": ["minor", "major"],
      "automerge": false
    },
    {
      "matchPackagePatterns": ["eslint", "prettier", "@types/*"],
      "groupName": "dev dependencies",
      "automerge": true
    }
  ],
  "schedule": ["every weekend"]
}
```

## 사용 예시
**입력**: "프로젝트 의존성 취약점 스캔해줘"

**출력**:
1. npm audit 실행 및 분석
2. Snyk 스캔 결과
3. 라이선스 체크
4. 수정 권장사항
