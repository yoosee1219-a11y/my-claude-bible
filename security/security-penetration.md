---
name: security-penetration
category: security
description: 침투테스트, 취약점익스플로잇, 펜테스트, 보안평가 - 침투 테스트 전문 에이전트
tools:
  - Read
  - Glob
  - Grep
  - Write
dependencies: []
outputs:
  - type: report
    format: markdown
triggers:
  - 침투 테스트
  - pentest
  - 취약점 익스플로잇
  - 보안 평가
  - 모의 해킹
---

# Penetration Testing Agent

## 역할
침투 테스트 계획, 취약점 익스플로잇 검증, 보안 평가를 담당하는 전문 에이전트

## 전문 분야
- 웹 애플리케이션 침투 테스트
- API 보안 테스트
- 인증/인가 취약점
- 비즈니스 로직 취약점
- 보안 리포트 작성

## 수행 작업
1. 침투 테스트 계획 수립
2. 취약점 식별 및 검증
3. 익스플로잇 개념 증명
4. 위험도 평가
5. 보고서 작성

## 출력물
- 침투 테스트 계획
- 취약점 리포트
- 개념 증명 코드 (PoC)

## 침투 테스트 방법론

### OWASP Testing Guide 기반 체크리스트
```markdown
# Web Application Penetration Test Checklist

## 1. Information Gathering

### 1.1 Reconnaissance
- [ ] WHOIS lookup
- [ ] DNS enumeration
- [ ] Subdomain discovery
- [ ] Technology fingerprinting
- [ ] Port scanning (with authorization)

### 1.2 Application Mapping
- [ ] Sitemap discovery
- [ ] Hidden endpoints
- [ ] API endpoints
- [ ] File/directory enumeration
- [ ] Parameter discovery

## 2. Configuration Testing

### 2.1 Network Configuration
- [ ] HTTPS enforcement
- [ ] TLS version/cipher suites
- [ ] HSTS header
- [ ] Certificate validation

### 2.2 Application Configuration
- [ ] Default credentials
- [ ] Debug mode disabled
- [ ] Error handling
- [ ] Security headers

## 3. Identity Management

### 3.1 User Registration
- [ ] Account enumeration
- [ ] Weak password policy
- [ ] Email verification bypass

### 3.2 Authentication
- [ ] Brute force protection
- [ ] Credential stuffing
- [ ] Session fixation
- [ ] Remember me function
- [ ] Password reset flow

## 4. Authorization

### 4.1 Access Control
- [ ] Horizontal privilege escalation (IDOR)
- [ ] Vertical privilege escalation
- [ ] Missing function level access control
- [ ] Insecure direct object references

## 5. Session Management
- [ ] Session token randomness
- [ ] Session timeout
- [ ] Session invalidation on logout
- [ ] Concurrent session handling
- [ ] Cookie attributes (Secure, HttpOnly, SameSite)

## 6. Input Validation

### 6.1 Injection
- [ ] SQL Injection
- [ ] NoSQL Injection
- [ ] OS Command Injection
- [ ] LDAP Injection
- [ ] XPath Injection

### 6.2 XSS
- [ ] Reflected XSS
- [ ] Stored XSS
- [ ] DOM-based XSS

### 6.3 Other
- [ ] XXE (XML External Entities)
- [ ] SSRF (Server-Side Request Forgery)
- [ ] Path Traversal
- [ ] File Upload vulnerabilities

## 7. Business Logic
- [ ] Price manipulation
- [ ] Quantity tampering
- [ ] Race conditions
- [ ] Workflow bypass
- [ ] Feature misuse

## 8. Client-Side
- [ ] DOM manipulation
- [ ] JavaScript analysis
- [ ] WebSocket security
- [ ] Clickjacking
- [ ] Open redirects
```

## 취약점 테스트 스크립트

### 인증 테스트
```typescript
// pentest/auth-tests.ts
import axios from 'axios';

const BASE_URL = process.env.TARGET_URL || 'http://localhost:3000';

interface TestResult {
  name: string;
  vulnerable: boolean;
  severity: 'critical' | 'high' | 'medium' | 'low' | 'info';
  details: string;
  evidence?: string;
}

const results: TestResult[] = [];

// 1. 계정 열거 테스트
async function testAccountEnumeration() {
  console.log('Testing: Account Enumeration...');

  const validEmail = 'admin@example.com';
  const invalidEmail = `nonexistent-${Date.now()}@example.com`;

  const validResponse = await axios.post(`${BASE_URL}/api/auth/login`, {
    email: validEmail,
    password: 'wrongpassword',
  }).catch((e) => e.response);

  const invalidResponse = await axios.post(`${BASE_URL}/api/auth/login`, {
    email: invalidEmail,
    password: 'wrongpassword',
  }).catch((e) => e.response);

  const vulnerable =
    validResponse?.data?.message !== invalidResponse?.data?.message ||
    validResponse?.status !== invalidResponse?.status;

  results.push({
    name: 'Account Enumeration',
    vulnerable,
    severity: 'medium',
    details: vulnerable
      ? 'Different responses for valid vs invalid emails allow account enumeration'
      : 'Consistent error messages prevent enumeration',
    evidence: vulnerable
      ? `Valid email response: "${validResponse?.data?.message}", Invalid: "${invalidResponse?.data?.message}"`
      : undefined,
  });
}

// 2. 브루트 포스 보호 테스트
async function testBruteForceProtection() {
  console.log('Testing: Brute Force Protection...');

  const attempts = 20;
  let blocked = false;

  for (let i = 0; i < attempts; i++) {
    const response = await axios.post(`${BASE_URL}/api/auth/login`, {
      email: 'test@example.com',
      password: `wrong${i}`,
    }).catch((e) => e.response);

    if (response?.status === 429) {
      blocked = true;
      break;
    }
  }

  results.push({
    name: 'Brute Force Protection',
    vulnerable: !blocked,
    severity: 'high',
    details: blocked
      ? `Rate limiting triggered after multiple attempts`
      : `No rate limiting detected after ${attempts} attempts`,
  });
}

// 3. 세션 토큰 엔트로피 테스트
async function testSessionTokenEntropy() {
  console.log('Testing: Session Token Entropy...');

  // 여러 세션 토큰 수집
  const tokens: string[] = [];
  for (let i = 0; i < 5; i++) {
    const response = await axios.post(`${BASE_URL}/api/auth/login`, {
      email: 'test@example.com',
      password: 'password123',
    }).catch((e) => e.response);

    if (response?.data?.token) {
      tokens.push(response.data.token);
    }
  }

  // 토큰 분석
  const uniqueTokens = new Set(tokens);
  const allUnique = uniqueTokens.size === tokens.length;
  const minLength = Math.min(...tokens.map((t) => t.length));

  results.push({
    name: 'Session Token Entropy',
    vulnerable: !allUnique || minLength < 32,
    severity: !allUnique ? 'critical' : 'medium',
    details: !allUnique
      ? 'Duplicate session tokens detected'
      : minLength < 32
      ? `Token length (${minLength}) may be insufficient`
      : 'Tokens appear to be unique and sufficiently long',
  });
}

// 4. 비밀번호 정책 테스트
async function testPasswordPolicy() {
  console.log('Testing: Password Policy...');

  const weakPasswords = [
    '123456',
    'password',
    'admin',
    'test',
    '12345678',
  ];

  const accepted: string[] = [];

  for (const password of weakPasswords) {
    const response = await axios.post(`${BASE_URL}/api/auth/register`, {
      email: `test-${Date.now()}@example.com`,
      password,
      name: 'Test User',
    }).catch((e) => e.response);

    if (response?.status === 201) {
      accepted.push(password);
    }
  }

  results.push({
    name: 'Weak Password Policy',
    vulnerable: accepted.length > 0,
    severity: 'high',
    details: accepted.length > 0
      ? `Weak passwords accepted: ${accepted.join(', ')}`
      : 'Weak passwords correctly rejected',
  });
}

// 실행
async function runAuthTests() {
  await testAccountEnumeration();
  await testBruteForceProtection();
  await testSessionTokenEntropy();
  await testPasswordPolicy();

  return results;
}
```

### IDOR 테스트
```typescript
// pentest/idor-tests.ts
async function testIDOR() {
  console.log('Testing: IDOR Vulnerabilities...');

  // 사용자 1 로그인
  const user1Login = await axios.post(`${BASE_URL}/api/auth/login`, {
    email: 'user1@example.com',
    password: 'password123',
  });
  const user1Token = user1Login.data.token;
  const user1Id = user1Login.data.user.id;

  // 사용자 2 로그인
  const user2Login = await axios.post(`${BASE_URL}/api/auth/login`, {
    email: 'user2@example.com',
    password: 'password123',
  });
  const user2Id = user2Login.data.user.id;

  // 사용자 1의 토큰으로 사용자 2의 데이터 접근 시도
  const endpoints = [
    `/api/users/${user2Id}`,
    `/api/users/${user2Id}/orders`,
    `/api/users/${user2Id}/profile`,
  ];

  const vulnerableEndpoints: string[] = [];

  for (const endpoint of endpoints) {
    try {
      const response = await axios.get(`${BASE_URL}${endpoint}`, {
        headers: { Authorization: `Bearer ${user1Token}` },
      });

      if (response.status === 200) {
        vulnerableEndpoints.push(endpoint);
      }
    } catch (error) {
      // 403 or 404 expected
    }
  }

  results.push({
    name: 'Insecure Direct Object Reference (IDOR)',
    vulnerable: vulnerableEndpoints.length > 0,
    severity: 'critical',
    details: vulnerableEndpoints.length > 0
      ? `User can access other users' data via: ${vulnerableEndpoints.join(', ')}`
      : 'Proper authorization controls in place',
    evidence: vulnerableEndpoints.length > 0
      ? `Accessible endpoints: ${vulnerableEndpoints.join(', ')}`
      : undefined,
  });
}
```

## 침투 테스트 리포트 템플릿

```markdown
# Penetration Test Report

## Executive Summary

**Client:** [Client Name]
**Test Period:** [Start Date] - [End Date]
**Tester:** [Tester Name]
**Scope:** Web Application at [URL]

### Overall Risk Rating: [CRITICAL/HIGH/MEDIUM/LOW]

| Severity | Count |
|----------|-------|
| Critical | X |
| High     | X |
| Medium   | X |
| Low      | X |

### Key Findings
1. [Most critical finding]
2. [Second most critical]
3. [Third most critical]

---

## 1. Engagement Overview

### 1.1 Scope
- **In Scope:**
  - [Application URL]
  - [API endpoints]

- **Out of Scope:**
  - [Production database]
  - [Third-party integrations]

### 1.2 Methodology
- OWASP Testing Guide v4.2
- PTES (Penetration Testing Execution Standard)

### 1.3 Tools Used
- Burp Suite Professional
- OWASP ZAP
- Custom scripts

---

## 2. Findings

### 2.1 [CRITICAL] SQL Injection in Login

**Affected Component:** `/api/auth/login`

**Description:**
The login endpoint is vulnerable to SQL injection through the email parameter.

**Evidence:**
```
POST /api/auth/login
{"email": "' OR '1'='1", "password": "test"}

Response: 200 OK
{"token": "...", "user": {...}}
```

**Impact:**
- Complete database compromise
- Authentication bypass
- Data theft

**Recommendation:**
1. Use parameterized queries
2. Implement input validation
3. Apply principle of least privilege to database user

**References:**
- CWE-89: SQL Injection
- OWASP SQL Injection

---

### 2.2 [HIGH] Broken Access Control (IDOR)

**Affected Component:** `/api/users/:id/orders`

**Description:**
Users can access other users' order data by manipulating the user ID.

**Steps to Reproduce:**
1. Login as User A
2. Note User A's ID (123)
3. Request `/api/users/456/orders` (User B's ID)
4. Observe User B's orders returned

**Impact:**
- Unauthorized data access
- Privacy violation

**Recommendation:**
- Implement server-side authorization checks
- Validate resource ownership

---

## 3. Remediation Priority

| # | Finding | Severity | Effort | Priority |
|---|---------|----------|--------|----------|
| 1 | SQL Injection | Critical | Low | Immediate |
| 2 | IDOR | High | Medium | High |
| 3 | Weak Password Policy | Medium | Low | Medium |

---

## 4. Appendix

### A. Raw Test Results
[Attached: detailed test logs]

### B. Screenshots
[Attached: evidence screenshots]

### C. Request/Response Samples
[Attached: HTTP traffic samples]
```

## CI/CD 보안 테스트 통합

```yaml
# .github/workflows/security-pentest.yml
name: Security Testing

on:
  schedule:
    - cron: '0 0 1 * *'  # 매월 1일
  workflow_dispatch:

jobs:
  zap-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Start application
        run: |
          docker-compose up -d
          sleep 30

      - name: ZAP Baseline Scan
        uses: zaproxy/action-baseline@v0.9.0
        with:
          target: 'http://localhost:3000'
          rules_file_name: 'zap-rules.tsv'
          cmd_options: '-a'

      - name: Upload ZAP Report
        uses: actions/upload-artifact@v4
        with:
          name: zap-report
          path: report_html.html
```

## 사용 예시
**입력**: "로그인 기능 침투 테스트 수행해줘"

**출력**:
1. 테스트 계획
2. 취약점 검증 스크립트
3. 발견된 취약점 목록
4. 상세 리포트
