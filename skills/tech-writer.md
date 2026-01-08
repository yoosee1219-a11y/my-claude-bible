---
name: technical-writer
description: 기술문서, API문서, 코드문서화, 사용자가이드, 설치가이드, 튜토리얼, 아키텍처문서, README작성, JSDoc, TSDoc, OpenAPI, Swagger, 문서자동생성을 지원하는 스킬
---

# Technical Writer: Documentation Generator

기술 문서 자동 생성

## 기능:

1. **API 문서 자동 생성**
   - OpenAPI/Swagger 스펙
   - 엔드포인트 설명
   - 요청/응답 예시
   - 에러 코드 설명
   - 인증 가이드

2. **코드 문서화**
   - JSDoc/TSDoc 자동 생성
   - 컴포넌트 Props 문서
   - 함수 시그니처 설명
   - 사용 예제 코드
   - Best Practices

3. **사용자 가이드**
   - 설치 가이드
   - 빠른 시작 튜토리얼
   - 사용 사례 (Use Cases)
   - 트러블슈팅
   - FAQ

4. **아키텍처 문서**
   - 시스템 아키텍처 다이어그램
   - 데이터 플로우
   - 디렉토리 구조 설명
   - 기술 스택 정의
   - 배포 가이드

## 생성되는 문서:

```
docs/
├── api/
│   ├── README.md           # API 개요
│   ├── authentication.md   # 인증
│   ├── endpoints.md        # 엔드포인트
│   └── errors.md          # 에러 코드
├── guides/
│   ├── installation.md     # 설치
│   ├── quickstart.md      # 빠른 시작
│   ├── tutorials/         # 튜토리얼
│   └── troubleshooting.md # 문제 해결
├── architecture/
│   ├── overview.md        # 아키텍처 개요
│   ├── database.md        # DB 설계
│   └── deployment.md      # 배포
└── contributing/
    ├── code-style.md      # 코딩 스타일
    ├── pull-requests.md   # PR 가이드
    └── testing.md         # 테스트 가이드
```

## API 문서 예시:

```markdown
# POST /api/users

새로운 사용자를 생성합니다.

## 요청

\`\`\`json
{
  "email": "user@example.com",
  "password": "********",
  "name": "홍길동"
}
\`\`\`

## 응답

\`\`\`json
{
  "id": "user_123",
  "email": "user@example.com",
  "created_at": "2024-01-01T00:00:00Z"
}
\`\`\`

## 에러

- 400: 잘못된 요청
- 409: 이메일 중복
- 500: 서버 에러
```

## 문서 품질:

- 명확성: 쉽게 이해 가능
- 완전성: 모든 기능 설명
- 정확성: 최신 상태 유지
- 예제: 실행 가능한 코드
- 검색: 인덱스 및 태그

## 출력:

- 완전한 문서 사이트
- Markdown 파일
- PDF 내보내기 (옵션)
- 다국어 지원 (옵션)
