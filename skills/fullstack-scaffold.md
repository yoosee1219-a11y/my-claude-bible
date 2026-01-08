---
name: fullstack
description: 풀스택개발, 자동생성, React, Next.js, TypeScript, API개발, 데이터베이스설계, Supabase, 테스트코드, 프론트엔드, 백엔드, 스캐폴딩, 프로젝트구조, 마이그레이션, RLS정책, Jest, Playwright를 완전 자동으로 생성하는 스킬
---

# Fullstack: Complete Scaffold Skill

풀스택 기능을 처음부터 끝까지 자동 생성합니다.

## 기능:

1. **Frontend 자동 생성**
   - React 컴포넌트 생성
   - TypeScript 타입 정의
   - 스타일링 (Tailwind CSS)
   - 상태 관리 (Zustand/Context)
   - API 클라이언트

2. **Backend 자동 생성**
   - API 라우트 생성 (Next.js)
   - DB 스키마 설계
   - 비즈니스 로직 구현
   - 에러 핸들링
   - 인증/인가

3. **Database 자동 설정**
   - Supabase 테이블 생성
   - 관계 설정
   - RLS 정책 설정
   - 인덱스 최적화
   - 마이그레이션 스크립트

4. **Testing 자동 생성**
   - 단위 테스트 (Jest)
   - 통합 테스트
   - E2E 테스트 (Playwright)
   - Mock 데이터 생성

## 사용 예:

```
"유저 프로필 편집 기능을 만들어줘"

→ 자동으로 생성:
  ✅ ProfileEditForm.tsx (Frontend)
  ✅ /api/profile/route.ts (Backend)
  ✅ profiles 테이블 (Database)
  ✅ ProfileEdit.test.tsx (Testing)
```

## 생성 파일 구조:

```
feature-name/
├── components/
│   ├── FeatureComponent.tsx
│   └── FeatureComponent.test.tsx
├── api/
│   └── feature/
│       └── route.ts
├── types/
│   └── feature.ts
├── hooks/
│   └── useFeature.ts
└── supabase/
    └── migrations/
        └── create_feature_table.sql
```

## 체크리스트:

- [ ] Frontend 컴포넌트
- [ ] API 엔드포인트
- [ ] Database 스키마
- [ ] TypeScript 타입
- [ ] 테스트 코드
- [ ] 문서화
