---
name: code-review
description: 코드리뷰, 품질검사, 보안검사, 성능분석, ESLint, TypeScript검사, 취약점스캔, 복잡도분석, 베스트프랙티스, 자동리뷰를 제공하는 스킬
---

# Code Review: Automatic Code Review Skill

자동 코드 리뷰 및 품질 검사

## 기능:

1. **코드 품질 분석**
   - ESLint 규칙 검사
   - TypeScript 타입 체크
   - 코드 스타일 검사 (Prettier)
   - 복잡도 분석
   - 중복 코드 탐지

2. **보안 검사**
   - 하드코딩된 시크릿 탐지
   - SQL Injection 취약점
   - XSS 취약점
   - CSRF 취약점
   - 의존성 보안 스캔

3. **성능 검사**
   - 비효율적 렌더링 탐지
   - 메모리 누수 가능성
   - 불필요한 리렌더링
   - 번들 사이즈 영향
   - API 호출 최적화

4. **베스트 프랙티스**
   - React 베스트 프랙티스
   - Next.js 최적화
   - TypeScript 활용도
   - 접근성 체크
   - SEO 최적화

## 실행:

```bash
# 1. Linting
npx eslint . --ext .ts,.tsx

# 2. Type checking
npx tsc --noEmit

# 3. Security scan
npm audit
npx snyk test

# 4. Code quality
npx sonarqube-scanner

# 5. Review report
```

## 리뷰 항목:

**필수:**
- [ ] TypeScript 타입 안전성
- [ ] ESLint 규칙 준수
- [ ] 보안 취약점 없음
- [ ] 테스트 커버리지 80%+

**권장:**
- [ ] 성능 최적화
- [ ] 접근성 개선
- [ ] 문서화 완료
- [ ] 코드 복잡도 감소

## 출력:

- CODE_REVIEW.md (종합 리포트)
- ISSUES.md (발견된 이슈)
- SUGGESTIONS.md (개선 제안)
- SCORE.md (코드 품질 점수)
