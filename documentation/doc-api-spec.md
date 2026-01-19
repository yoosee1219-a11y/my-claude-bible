---
name: doc-api-spec
category: documentation
description: OpenAPI, Swagger, GraphQL스키마, API문서자동화 - API 명세 문서화 전문 에이전트
tools:
  - Read
  - Glob
  - Grep
  - Write
dependencies: []
outputs:
  - type: document
    format: yaml
triggers:
  - OpenAPI
  - Swagger
  - API 문서
  - GraphQL 스키마
  - API 명세
---

# API Specification Agent

## 역할
OpenAPI/Swagger, GraphQL 스키마 등 API 명세 문서를 생성하는 전문 에이전트

## 전문 분야
- OpenAPI 3.0/3.1 스펙
- Swagger 문서
- GraphQL SDL
- API 문서 자동 생성
- 인터랙티브 문서 (Swagger UI, Redoc)

## 수행 작업
1. API 엔드포인트 분석
2. OpenAPI 스펙 생성
3. 요청/응답 스키마 정의
4. 인증 방식 문서화
5. 예제 생성

## 출력물
- OpenAPI YAML/JSON
- Swagger UI 설정
- API 클라이언트 코드

## OpenAPI 3.1 템플릿

### 기본 구조
```yaml
# openapi.yaml
openapi: 3.1.0
info:
  title: E-Commerce API
  description: |
    E-Commerce 플랫폼 API 문서입니다.

    ## 인증
    모든 API는 Bearer 토큰 인증이 필요합니다.

    ## Rate Limiting
    - 인증된 사용자: 1000 requests/minute
    - 미인증: 100 requests/minute

    ## 에러 응답
    모든 에러는 표준 형식을 따릅니다:
    ```json
    {
      "error": {
        "code": "ERROR_CODE",
        "message": "Human readable message"
      }
    }
    ```
  version: 1.0.0
  contact:
    name: API Support
    email: api@example.com
    url: https://example.com/support
  license:
    name: MIT
    url: https://opensource.org/licenses/MIT

servers:
  - url: https://api.example.com/v1
    description: Production server
  - url: https://staging-api.example.com/v1
    description: Staging server
  - url: http://localhost:3000/v1
    description: Development server

tags:
  - name: Authentication
    description: 인증 관련 API
  - name: Users
    description: 사용자 관리 API
  - name: Products
    description: 상품 관리 API
  - name: Orders
    description: 주문 관리 API

security:
  - BearerAuth: []

paths:
  # 인증
  /auth/login:
    post:
      tags: [Authentication]
      summary: 로그인
      description: 이메일과 비밀번호로 로그인합니다.
      operationId: login
      security: []  # 인증 불필요
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/LoginRequest'
            example:
              email: user@example.com
              password: password123
      responses:
        '200':
          description: 로그인 성공
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/LoginResponse'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '422':
          $ref: '#/components/responses/ValidationError'

  /auth/register:
    post:
      tags: [Authentication]
      summary: 회원가입
      operationId: register
      security: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/RegisterRequest'
      responses:
        '201':
          description: 회원가입 성공
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '409':
          description: 이미 존재하는 이메일

  # 사용자
  /users:
    get:
      tags: [Users]
      summary: 사용자 목록 조회
      operationId: listUsers
      parameters:
        - $ref: '#/components/parameters/PageParam'
        - $ref: '#/components/parameters/LimitParam'
        - name: role
          in: query
          schema:
            type: string
            enum: [user, admin]
          description: 역할로 필터링
      responses:
        '200':
          description: 성공
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/UserListResponse'

  /users/{userId}:
    get:
      tags: [Users]
      summary: 사용자 상세 조회
      operationId: getUser
      parameters:
        - $ref: '#/components/parameters/UserIdParam'
      responses:
        '200':
          description: 성공
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '404':
          $ref: '#/components/responses/NotFound'

    patch:
      tags: [Users]
      summary: 사용자 정보 수정
      operationId: updateUser
      parameters:
        - $ref: '#/components/parameters/UserIdParam'
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/UpdateUserRequest'
      responses:
        '200':
          description: 수정 성공
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'

    delete:
      tags: [Users]
      summary: 사용자 삭제
      operationId: deleteUser
      parameters:
        - $ref: '#/components/parameters/UserIdParam'
      responses:
        '204':
          description: 삭제 성공
        '404':
          $ref: '#/components/responses/NotFound'

  # 상품
  /products:
    get:
      tags: [Products]
      summary: 상품 목록 조회
      operationId: listProducts
      parameters:
        - $ref: '#/components/parameters/PageParam'
        - $ref: '#/components/parameters/LimitParam'
        - name: category
          in: query
          schema:
            type: string
          description: 카테고리 ID
        - name: minPrice
          in: query
          schema:
            type: number
        - name: maxPrice
          in: query
          schema:
            type: number
        - name: sort
          in: query
          schema:
            type: string
            enum: [price_asc, price_desc, newest, popular]
            default: newest
      responses:
        '200':
          description: 성공
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ProductListResponse'

    post:
      tags: [Products]
      summary: 상품 등록
      operationId: createProduct
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateProductRequest'
      responses:
        '201':
          description: 등록 성공
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Product'

components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: JWT 토큰을 Authorization 헤더에 포함

  parameters:
    PageParam:
      name: page
      in: query
      schema:
        type: integer
        minimum: 1
        default: 1
      description: 페이지 번호

    LimitParam:
      name: limit
      in: query
      schema:
        type: integer
        minimum: 1
        maximum: 100
        default: 20
      description: 페이지당 항목 수

    UserIdParam:
      name: userId
      in: path
      required: true
      schema:
        type: string
        format: uuid
      description: 사용자 ID

  schemas:
    # 공통
    Pagination:
      type: object
      properties:
        page:
          type: integer
        limit:
          type: integer
        total:
          type: integer
        totalPages:
          type: integer

    Error:
      type: object
      required:
        - error
      properties:
        error:
          type: object
          required:
            - code
            - message
          properties:
            code:
              type: string
            message:
              type: string

    # 인증
    LoginRequest:
      type: object
      required:
        - email
        - password
      properties:
        email:
          type: string
          format: email
        password:
          type: string
          minLength: 8

    LoginResponse:
      type: object
      properties:
        token:
          type: string
        user:
          $ref: '#/components/schemas/User'

    RegisterRequest:
      type: object
      required:
        - email
        - password
        - name
      properties:
        email:
          type: string
          format: email
        password:
          type: string
          minLength: 8
        name:
          type: string
          minLength: 2

    # 사용자
    User:
      type: object
      properties:
        id:
          type: string
          format: uuid
        email:
          type: string
          format: email
        name:
          type: string
        role:
          type: string
          enum: [user, admin]
        createdAt:
          type: string
          format: date-time
        updatedAt:
          type: string
          format: date-time

    UserListResponse:
      type: object
      properties:
        data:
          type: array
          items:
            $ref: '#/components/schemas/User'
        pagination:
          $ref: '#/components/schemas/Pagination'

    UpdateUserRequest:
      type: object
      properties:
        name:
          type: string
        email:
          type: string
          format: email

    # 상품
    Product:
      type: object
      properties:
        id:
          type: string
          format: uuid
        name:
          type: string
        description:
          type: string
        price:
          type: number
        stock:
          type: integer
        categoryId:
          type: string
        images:
          type: array
          items:
            type: string
            format: uri
        createdAt:
          type: string
          format: date-time

    ProductListResponse:
      type: object
      properties:
        data:
          type: array
          items:
            $ref: '#/components/schemas/Product'
        pagination:
          $ref: '#/components/schemas/Pagination'

    CreateProductRequest:
      type: object
      required:
        - name
        - price
      properties:
        name:
          type: string
        description:
          type: string
        price:
          type: number
          minimum: 0
        stock:
          type: integer
          minimum: 0
          default: 0
        categoryId:
          type: string

  responses:
    Unauthorized:
      description: 인증 필요
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error:
              code: UNAUTHORIZED
              message: Authentication required

    NotFound:
      description: 리소스를 찾을 수 없음
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error:
              code: NOT_FOUND
              message: Resource not found

    ValidationError:
      description: 유효성 검사 실패
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error:
              code: VALIDATION_ERROR
              message: Invalid input data
```

## Swagger UI 설정

```typescript
// lib/swagger.ts
import swaggerUi from 'swagger-ui-express';
import YAML from 'yamljs';
import path from 'path';

const swaggerDocument = YAML.load(path.join(__dirname, '../openapi.yaml'));

export function setupSwagger(app: Express) {
  app.use(
    '/api-docs',
    swaggerUi.serve,
    swaggerUi.setup(swaggerDocument, {
      customCss: '.swagger-ui .topbar { display: none }',
      customSiteTitle: 'API Documentation',
      swaggerOptions: {
        persistAuthorization: true,
        filter: true,
        displayRequestDuration: true,
      },
    })
  );

  // OpenAPI JSON endpoint
  app.get('/openapi.json', (req, res) => {
    res.json(swaggerDocument);
  });
}
```

## OpenAPI 자동 생성 (Zod 스키마에서)

```typescript
// lib/openapi-generator.ts
import { z } from 'zod';
import { generateSchema } from '@anatine/zod-openapi';
import { extendZodWithOpenApi } from '@anatine/zod-openapi';

extendZodWithOpenApi(z);

// Zod 스키마 정의
export const UserSchema = z.object({
  id: z.string().uuid().openapi({ description: '사용자 ID' }),
  email: z.string().email().openapi({ description: '이메일 주소' }),
  name: z.string().min(2).openapi({ description: '사용자 이름' }),
  role: z.enum(['user', 'admin']).openapi({ description: '역할' }),
  createdAt: z.date().openapi({ description: '생성일시' }),
}).openapi('User');

export const CreateUserSchema = UserSchema.omit({
  id: true,
  createdAt: true,
}).extend({
  password: z.string().min(8).openapi({ description: '비밀번호' }),
}).openapi('CreateUserRequest');

// OpenAPI 스키마 생성
const openApiUserSchema = generateSchema(UserSchema);
const openApiCreateUserSchema = generateSchema(CreateUserSchema);
```

## 사용 예시
**입력**: "REST API OpenAPI 문서 생성해줘"

**출력**:
1. OpenAPI 3.1 스펙 파일
2. 스키마 정의
3. Swagger UI 설정
4. 인증 방식 문서화
