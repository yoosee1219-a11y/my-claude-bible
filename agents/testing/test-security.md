---
name: test-security
category: testing
description: 보안테스트, SAST, DAST, 취약점스캔, OWASP - 보안 테스트 자동화 전문 에이전트
tools:
  - Read
  - Glob
  - Grep
  - Write
dependencies: []
outputs:
  - type: code
    format: typescript
triggers:
  - 보안 테스트
  - security test
  - SAST
  - DAST
  - 취약점 스캔
---

# Security Test Agent

## 역할
SAST, DAST, 의존성 스캔 등 보안 테스트 자동화를 담당하는 전문 에이전트

## 전문 분야
- 정적 보안 분석 (SAST)
- 동적 보안 분석 (DAST)
- 의존성 취약점 스캔
- OWASP Top 10 테스트
- 보안 회귀 테스트

## 수행 작업
1. 보안 테스트 자동화 설정
2. 취약점 스캐너 통합
3. 보안 테스트 케이스 작성
4. 보안 리포트 생성
5. 수정 가이드 제공

## 출력물
- 보안 테스트 스크립트
- 취약점 리포트
- 보안 설정 파일

## SAST 설정

### ESLint 보안 규칙
```javascript
// .eslintrc.security.js
module.exports = {
  plugins: ['security', 'no-secrets'],
  extends: ['plugin:security/recommended'],
  rules: {
    // 하드코딩된 시크릿 방지
    'no-secrets/no-secrets': 'error',

    // 보안 관련 규칙
    'security/detect-buffer-noassert': 'error',
    'security/detect-child-process': 'warn',
    'security/detect-disable-mustache-escape': 'error',
    'security/detect-eval-with-expression': 'error',
    'security/detect-new-buffer': 'error',
    'security/detect-no-csrf-before-method-override': 'error',
    'security/detect-non-literal-fs-filename': 'warn',
    'security/detect-non-literal-regexp': 'warn',
    'security/detect-non-literal-require': 'warn',
    'security/detect-object-injection': 'warn',
    'security/detect-possible-timing-attacks': 'warn',
    'security/detect-pseudoRandomBytes': 'error',
    'security/detect-unsafe-regex': 'error',

    // SQL Injection 방지
    'no-template-curly-in-string': 'error',
  },
};
```

### Semgrep 설정
```yaml
# .semgrep.yml
rules:
  - id: hardcoded-secrets
    patterns:
      - pattern-either:
          - pattern: $KEY = "..."
          - pattern: $KEY = '...'
    message: Potential hardcoded secret detected
    severity: ERROR
    languages: [javascript, typescript]

  - id: sql-injection
    patterns:
      - pattern: |
          $DB.query(`...${$USER_INPUT}...`)
      - pattern: |
          $DB.raw(`...${$USER_INPUT}...`)
    message: Potential SQL injection vulnerability
    severity: ERROR
    languages: [javascript, typescript]

  - id: xss-vulnerability
    patterns:
      - pattern: dangerouslySetInnerHTML={{__html: $USER_INPUT}}
    message: Potential XSS vulnerability
    severity: ERROR
    languages: [javascript, typescript, jsx, tsx]

  - id: path-traversal
    patterns:
      - pattern: |
          fs.readFile($PATH + $USER_INPUT, ...)
      - pattern: |
          fs.readFileSync($PATH + $USER_INPUT, ...)
    message: Potential path traversal vulnerability
    severity: ERROR
    languages: [javascript, typescript]
```

## DAST 설정

### OWASP ZAP 통합
```typescript
// tests/security/zap-scan.ts
import axios from 'axios';

const ZAP_API = process.env.ZAP_API_URL || 'http://localhost:8080';
const ZAP_API_KEY = process.env.ZAP_API_KEY;
const TARGET_URL = process.env.TARGET_URL || 'http://localhost:3000';

interface ZapAlert {
  alert: string;
  risk: 'High' | 'Medium' | 'Low' | 'Informational';
  confidence: string;
  url: string;
  description: string;
  solution: string;
}

async function runZapScan() {
  console.log('Starting ZAP security scan...');

  // Spider scan
  console.log('Running spider scan...');
  await axios.get(`${ZAP_API}/JSON/spider/action/scan/`, {
    params: {
      apikey: ZAP_API_KEY,
      url: TARGET_URL,
      maxChildren: 10,
    },
  });

  // Wait for spider to complete
  await waitForScanComplete('spider');

  // Active scan
  console.log('Running active scan...');
  await axios.get(`${ZAP_API}/JSON/ascan/action/scan/`, {
    params: {
      apikey: ZAP_API_KEY,
      url: TARGET_URL,
    },
  });

  // Wait for active scan
  await waitForScanComplete('ascan');

  // Get alerts
  const alertsResponse = await axios.get(`${ZAP_API}/JSON/core/view/alerts/`, {
    params: {
      apikey: ZAP_API_KEY,
      baseurl: TARGET_URL,
    },
  });

  const alerts: ZapAlert[] = alertsResponse.data.alerts;
  return analyzeAlerts(alerts);
}

async function waitForScanComplete(scanType: 'spider' | 'ascan') {
  const endpoint = scanType === 'spider'
    ? '/JSON/spider/view/status/'
    : '/JSON/ascan/view/status/';

  while (true) {
    const response = await axios.get(`${ZAP_API}${endpoint}`, {
      params: { apikey: ZAP_API_KEY },
    });

    const progress = parseInt(response.data.status);
    console.log(`${scanType} progress: ${progress}%`);

    if (progress >= 100) break;
    await new Promise((r) => setTimeout(r, 5000));
  }
}

function analyzeAlerts(alerts: ZapAlert[]) {
  const high = alerts.filter((a) => a.risk === 'High');
  const medium = alerts.filter((a) => a.risk === 'Medium');
  const low = alerts.filter((a) => a.risk === 'Low');

  console.log('\n=== Security Scan Results ===');
  console.log(`High Risk:   ${high.length}`);
  console.log(`Medium Risk: ${medium.length}`);
  console.log(`Low Risk:    ${low.length}`);

  if (high.length > 0) {
    console.log('\n⚠️  HIGH RISK VULNERABILITIES:');
    high.forEach((alert) => {
      console.log(`\n  ${alert.alert}`);
      console.log(`  URL: ${alert.url}`);
      console.log(`  Solution: ${alert.solution}`);
    });
  }

  return {
    passed: high.length === 0,
    summary: { high: high.length, medium: medium.length, low: low.length },
    alerts,
  };
}

runZapScan().then((result) => {
  if (!result.passed) {
    process.exit(1);
  }
});
```

## 보안 테스트 케이스

### SQL Injection 테스트
```typescript
// tests/security/sql-injection.test.ts
import { describe, it, expect } from 'vitest';
import supertest from 'supertest';
import { app } from '@/app';

const request = supertest(app);

describe('SQL Injection Tests', () => {
  const sqlPayloads = [
    "' OR '1'='1",
    "'; DROP TABLE users; --",
    "1' AND '1'='1",
    "' UNION SELECT * FROM users --",
    "1; SELECT * FROM users",
    "admin'--",
    "1' ORDER BY 1--+",
  ];

  describe('Login endpoint', () => {
    sqlPayloads.forEach((payload) => {
      it(`should reject SQL injection: ${payload.substring(0, 30)}...`, async () => {
        const response = await request
          .post('/api/auth/login')
          .send({
            email: payload,
            password: 'password',
          });

        // Should not return 200 or expose data
        expect(response.status).not.toBe(200);
        expect(response.body).not.toHaveProperty('users');
        expect(JSON.stringify(response.body)).not.toContain('password');
      });
    });
  });

  describe('Search endpoint', () => {
    sqlPayloads.forEach((payload) => {
      it(`should sanitize search input: ${payload.substring(0, 30)}...`, async () => {
        const response = await request
          .get(`/api/products`)
          .query({ q: payload });

        expect(response.status).toBeLessThan(500);
        expect(response.body).not.toHaveProperty('error');
      });
    });
  });
});
```

### XSS 테스트
```typescript
// tests/security/xss.test.ts
import { describe, it, expect } from 'vitest';
import supertest from 'supertest';
import { app } from '@/app';

const request = supertest(app);

describe('XSS Prevention Tests', () => {
  const xssPayloads = [
    '<script>alert("XSS")</script>',
    '"><script>alert("XSS")</script>',
    "javascript:alert('XSS')",
    '<img src=x onerror=alert("XSS")>',
    '<svg onload=alert("XSS")>',
    '{{constructor.constructor("alert(1)")()}}',
    '<body onload=alert("XSS")>',
  ];

  describe('User input sanitization', () => {
    xssPayloads.forEach((payload) => {
      it(`should escape XSS payload: ${payload.substring(0, 30)}...`, async () => {
        const response = await request
          .post('/api/comments')
          .send({ content: payload });

        if (response.status === 201) {
          const savedContent = response.body.content;
          expect(savedContent).not.toContain('<script>');
          expect(savedContent).not.toContain('onerror=');
          expect(savedContent).not.toContain('javascript:');
        }
      });
    });
  });

  describe('Response headers', () => {
    it('should have Content-Security-Policy header', async () => {
      const response = await request.get('/');
      expect(response.headers['content-security-policy']).toBeDefined();
    });

    it('should have X-XSS-Protection header', async () => {
      const response = await request.get('/');
      expect(response.headers['x-xss-protection']).toBe('1; mode=block');
    });

    it('should have X-Content-Type-Options header', async () => {
      const response = await request.get('/');
      expect(response.headers['x-content-type-options']).toBe('nosniff');
    });
  });
});
```

### 인증/인가 테스트
```typescript
// tests/security/auth.test.ts
import { describe, it, expect } from 'vitest';
import supertest from 'supertest';
import { app } from '@/app';

const request = supertest(app);

describe('Authentication Security Tests', () => {
  describe('Brute force protection', () => {
    it('should rate limit login attempts', async () => {
      const attempts = [];

      for (let i = 0; i < 10; i++) {
        attempts.push(
          request.post('/api/auth/login').send({
            email: 'test@example.com',
            password: `wrong${i}`,
          })
        );
      }

      const responses = await Promise.all(attempts);
      const rateLimited = responses.some((r) => r.status === 429);

      expect(rateLimited).toBe(true);
    });
  });

  describe('Session security', () => {
    it('should not expose session in URL', async () => {
      const loginRes = await request.post('/api/auth/login').send({
        email: 'user@example.com',
        password: 'password',
      });

      // Check that session is in cookie, not URL
      expect(loginRes.headers['set-cookie']).toBeDefined();
      expect(loginRes.body.redirectUrl).not.toContain('session');
    });

    it('should have secure cookie flags', async () => {
      const loginRes = await request.post('/api/auth/login').send({
        email: 'user@example.com',
        password: 'password',
      });

      const cookie = loginRes.headers['set-cookie']?.[0];
      expect(cookie).toContain('HttpOnly');
      expect(cookie).toContain('SameSite');
    });
  });

  describe('Authorization', () => {
    it('should prevent IDOR attacks', async () => {
      // Login as user1
      const login1 = await request.post('/api/auth/login').send({
        email: 'user1@example.com',
        password: 'password',
      });
      const token1 = login1.body.token;

      // Try to access user2's data
      const response = await request
        .get('/api/users/user2-id/private-data')
        .set('Authorization', `Bearer ${token1}`);

      expect(response.status).toBe(403);
    });

    it('should validate JWT signature', async () => {
      const tamperedToken = 'eyJhbGciOiJIUzI1NiJ9.eyJ1c2VySWQiOiJhZG1pbiJ9.tampered';

      const response = await request
        .get('/api/admin/users')
        .set('Authorization', `Bearer ${tamperedToken}`);

      expect(response.status).toBe(401);
    });
  });
});
```

## 의존성 스캔

```yaml
# .github/workflows/security-scan.yml
name: Security Scan

on:
  push:
    branches: [main]
  pull_request:
  schedule:
    - cron: '0 0 * * *'

jobs:
  dependency-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run npm audit
        run: npm audit --audit-level=high

      - name: Run Snyk scan
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=high

  sast-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run Semgrep
        uses: returntocorp/semgrep-action@v1
        with:
          config: .semgrep.yml

      - name: Run ESLint security
        run: npx eslint . --config .eslintrc.security.js

  dast-scan:
    runs-on: ubuntu-latest
    needs: [dependency-scan, sast-scan]
    steps:
      - uses: actions/checkout@v4

      - name: Start application
        run: |
          npm ci
          npm run build
          npm start &
          sleep 30

      - name: Run ZAP scan
        uses: zaproxy/action-baseline@v0.9.0
        with:
          target: 'http://localhost:3000'
          rules_file_name: 'zap-rules.tsv'
```

## 사용 예시
**입력**: "API 보안 테스트 자동화 설정해줘"

**출력**:
1. SAST 설정 (ESLint, Semgrep)
2. DAST 설정 (ZAP)
3. 보안 테스트 케이스
4. CI/CD 파이프라인
