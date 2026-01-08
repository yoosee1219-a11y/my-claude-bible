---
name: release-manager
description: 릴리스관리, 버전관리, 배포자동화, 릴리스노트, 체인지로그, Semantic Versioning, 롤백, Git태그, npm배포, GitHub Release, 배포계획, 버전업그레이드를 자동화하는 스킬
---

# Release Manager: Version & Release Management

버전 및 릴리스 관리

## 기능:

1. **릴리스 계획**
   - 버전 번호 관리 (Semantic Versioning)
   - 릴리스 일정 수립
   - 기능 로드맵
   - 의존성 점검
   - 롤백 계획

2. **릴리스 노트 자동 생성**
   - Git 커밋 기반 변경 사항 수집
   - 기능/버그수정/개선 분류
   - 사용자 친화적 설명
   - 스크린샷 포함 (옵션)
   - 다국어 지원

3. **릴리스 자동화**
   - 버전 태그 생성
   - 체인지로그 업데이트
   - npm 패키지 배포
   - GitHub Release 생성
   - 알림 발송 (Slack, Email)

4. **롤백 관리**
   - 빠른 롤백 프로세스
   - 버전 비교 리포트
   - 영향도 분석
   - 데이터 마이그레이션 롤백
   - 사후 분석

## Semantic Versioning:

```
버전 형식: MAJOR.MINOR.PATCH

예: 1.4.2

MAJOR (1): Breaking changes
MINOR (4): 새 기능 (하위 호환)
PATCH (2): 버그 수정
```

## 릴리스 노트 예시:

```markdown
# v1.5.0 (2024-11-19)

## 🎉 새로운 기능

- **블로그 다국어 지원**: 12개 언어 자동 번역 추가
- **성능 개선**: 페이지 로딩 속도 40% 향상
- **다크 모드**: 사용자 설정에 따른 테마 전환

## 🐛 버그 수정

- 모바일에서 검색 필터가 작동하지 않던 문제 해결
- 특정 브라우저에서 이미지가 표시되지 않던 문제 수정
- 로그인 세션 만료 알림 개선

## 🔧 개선사항

- API 응답 시간 25% 단축
- 에러 메시지 사용자 친화적으로 개선
- 접근성 개선 (WCAG 2.1 AA 준수)

## 📚 문서

- API 문서 업데이트
- 새 튜토리얼 3개 추가
- FAQ 업데이트

## 🚨 Breaking Changes

없음

## 📦 의존성

- Next.js: 14.0.0 → 14.1.0
- React: 18.2.0 → 18.3.0

## 🙏 감사

이번 릴리스에 기여해주신 모든 분들께 감사드립니다!
```

## 릴리스 체크리스트:

**배포 전:**
- [ ] 모든 테스트 통과
- [ ] 코드 리뷰 완료
- [ ] 보안 스캔 통과
- [ ] 성능 벤치마크 확인
- [ ] 문서 업데이트
- [ ] 릴리스 노트 작성

**배포 중:**
- [ ] 버전 태그 생성
- [ ] Production 빌드
- [ ] 배포 실행
- [ ] 헬스 체크
- [ ] 모니터링 확인

**배포 후:**
- [ ] 주요 기능 테스트
- [ ] 에러율 모니터링 (24시간)
- [ ] 성능 메트릭 확인
- [ ] 사용자 피드백 수집
- [ ] 사후 분석 (Postmortem)

## 롤백 프로세스:

```bash
# 즉시 롤백 (1분)
git revert <commit-hash>
git push origin main
# → Vercel 자동 재배포

# 또는 이전 버전으로
vercel rollback <deployment-url>
```

## 출력:

- RELEASE_NOTES.md
- CHANGELOG.md
- VERSION.txt
- ROLLBACK_PLAN.md
