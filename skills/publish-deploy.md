---
name: publish
description: 웹배포, 퍼블리싱, SEO최적화, 성능최적화, Vercel배포, GitHub배포, 사이트맵생성, 메타태그, 번들최적화, 이미지압축, Lighthouse분석, 모니터링설정, 프로덕션빌드를 자동화하는 스킬
---

# Publish: Complete Deployment Skill

퍼블리싱 및 배포 자동화 워크플로우

## 기능:

1. **SEO 최적화**
   - 메타 태그 자동 생성
   - Open Graph 설정
   - Twitter Cards 설정
   - Sitemap 생성
   - robots.txt 설정
   - 구조화된 데이터 (Schema.org)

2. **성능 최적화**
   - 이미지 최적화 (WebP, AVIF)
   - 코드 스플리팅
   - 번들 사이즈 최적화
   - 레이지 로딩
   - CDN 설정
   - 캐싱 전략

3. **빌드 & 배포**
   - Production 빌드
   - 환경변수 검증
   - 에러 체크
   - GitHub 푸시
   - Vercel 배포
   - 배포 검증

4. **모니터링 설정**
   - Analytics 설정 (GA4)
   - 에러 트래킹 (Sentry)
   - 성능 모니터링
   - 로그 수집
   - 알림 설정

## 실행 단계:

```bash
# 1. SEO 최적화
- sitemap.xml 생성
- robots.txt 생성
- 메타 태그 검증

# 2. 성능 최적화
- 이미지 압축
- 번들 분석
- Lighthouse 스코어 체크

# 3. 빌드
- npm run build
- 에러 체크
- 빌드 사이즈 확인

# 4. 배포
- Git commit & push
- Vercel 자동 배포
- 배포 URL 확인

# 5. 검증
- 헬스 체크
- 페이지 로딩 테스트
- API 응답 테스트
```

## 체크리스트:

**SEO:**
- [ ] Title, Description 설정
- [ ] Open Graph 이미지
- [ ] Sitemap 생성
- [ ] robots.txt 설정
- [ ] 구조화된 데이터

**성능:**
- [ ] Lighthouse 스코어 90+
- [ ] First Contentful Paint < 1.8s
- [ ] Time to Interactive < 3.8s
- [ ] 번들 사이즈 최적화

**배포:**
- [ ] Production 빌드 성공
- [ ] Vercel 배포 완료
- [ ] DNS 설정 (필요시)
- [ ] SSL 인증서 확인

**모니터링:**
- [ ] Analytics 작동
- [ ] 에러 트래킹 활성화
- [ ] 성능 대시보드 설정

## 출력:

- DEPLOYMENT_REPORT.md
- SEO_CHECKLIST.md
- PERFORMANCE_SCORE.md
- 배포 URL 및 상태
