---
name: security
description: 보안감사, 취약점스캔, OWASP, SQL인젝션, XSS검사, 의존성보안, 침투테스트, 보안분석, 코드보안, 시크릿탐지를 종합적으로 수행하는 스킬
---

# Security: Comprehensive Security Audit

보안 감사 및 취약점 스캔

## 기능:

1. **취약점 스캔**
   - OWASP Top 10 검사
   - SQL Injection 탐지
   - XSS (Cross-Site Scripting) 검사
   - CSRF 취약점 확인
   - 인증/인가 로직 검증

2. **의존성 보안 검사**
   - npm audit 자동 실행
   - 취약한 패키지 식별
   - 보안 패치 권장
   - 라이센스 준수 확인
   - 공급망 공격 방어

3. **코드 보안 분석**
   - 하드코딩된 시크릿 탐지
   - API 키 노출 검사
   - 민감 정보 로깅 확인
   - 안전하지 않은 함수 사용
   - 보안 코딩 규칙 준수

4. **침투 테스트**
   - 인증 우회 시도
   - 권한 상승 테스트
   - 데이터 유출 가능성
   - DoS 공격 내성
   - 보안 헤더 검증

## 보안 체크리스트:

**인증 & 인가:**
- [ ] JWT 토큰 안전하게 저장
- [ ] 비밀번호 해싱 (bcrypt)
- [ ] 세션 만료 설정
- [ ] 2FA 지원 (옵션)
- [ ] Rate Limiting 적용

**데이터 보호:**
- [ ] HTTPS 강제
- [ ] 암호화 저장 (중요 데이터)
- [ ] 입력 검증 및 Sanitization
- [ ] SQL 파라미터화
- [ ] CORS 올바른 설정

**인프라 보안:**
- [ ] 환경변수 보호
- [ ] 보안 헤더 설정
- [ ] 로그에 민감 정보 제외
- [ ] 정기적인 백업
- [ ] 접근 로그 모니터링

## 스캔 결과:

```
보안 등급: A+ / A / B / C / D / F

치명적 (Critical): 0
높음 (High): 0
중간 (Medium): 2
낮음 (Low): 5
```

## 출력:

- SECURITY_REPORT.md
- VULNERABILITIES.json
- PATCH_RECOMMENDATIONS.md
- COMPLIANCE_CHECK.md
