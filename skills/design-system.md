---
name: design
description: 디자인시스템, UI컴포넌트, 반응형디자인, Tailwind, 접근성, 다크모드, 버튼, 입력폼, 카드, 모달, 색상팔레트, 타이포그래피, 스페이싱, 브레이크포인트, 스타일가이드, CSS변수, 애니메이션, 아이콘, WCAG, 색상대비, 키보드네비게이션, 스크린리더, ARIA, 모바일우선, 태블릿최적화, 데스크톱레이아웃, 그리드시스템, Flexbox, 컴포넌트라이브러리, St
---

# Design: Component Design System Skill

디자인 시스템 및 UI 컴포넌트 자동 생성

## 기능:

1. **컴포넌트 디자인 시스템**
   - 버튼, 입력, 카드 등 기본 컴포넌트
   - 색상 팔레트 정의
   - 타이포그래피 시스템
   - 스페이싱 규칙
   - 반응형 브레이크포인트

2. **스타일 가이드 생성**
   - Tailwind 커스텀 설정
   - CSS 변수 정의
   - 다크 모드 지원
   - 애니메이션 라이브러리
   - 아이콘 시스템

3. **접근성 체크**
   - WCAG 2.1 준수 확인
   - 색상 대비 검사
   - 키보드 네비게이션
   - 스크린 리더 지원
   - ARIA 속성 자동 추가

4. **반응형 레이아웃**
   - 모바일 우선 디자인
   - 태블릿 최적화
   - 데스크톱 레이아웃
   - 그리드 시스템
   - Flexbox 유틸리티

## 생성되는 파일:

```
design-system/
├── components/
│   ├── Button.tsx
│   ├── Input.tsx
│   ├── Card.tsx
│   └── Modal.tsx
├── styles/
│   ├── colors.css
│   ├── typography.css
│   └── animations.css
├── tailwind.config.ts
└── DESIGN_GUIDE.md
```

## 컴포넌트 예시:

```tsx
// Button 컴포넌트 (자동 생성)
<Button
  variant="primary"
  size="lg"
  loading={false}
  disabled={false}
  onClick={() => {}}
>
  클릭하세요
</Button>

// 지원 variants:
// - primary, secondary, outline, ghost, danger
// - 자동으로 접근성, 반응형, 다크모드 지원
```

## 출력:

- 재사용 가능한 컴포넌트 라이브러리
- 스타일 가이드 문서
- Storybook 통합 (옵션)
- 디자인 토큰 (Figma 연동 가능)
