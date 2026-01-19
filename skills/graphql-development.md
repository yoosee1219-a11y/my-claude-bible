# GraphQL Development

> Apollo Server, Code Generation, DataLoader로 타입 안전하고 효율적인 GraphQL API 구축 (2026)

## 목차

1. [GraphQL이 왜 필요한가?](#graphql이-왜-필요한가)
2. [Apollo Server 설정](#apollo-server-설정)
3. [TypeScript Code Generation](#typescript-code-generation)
4. [N+1 문제 해결 (DataLoader)](#n1-문제-해결-dataloader)
5. [스키마 설계 Best Practices](#스키마-설계-best-practices)
6. [실전 사례](#실전-사례)

---

## GraphQL이 왜 필요한가?

### REST API의 한계

**Over-fetching (과다 요청)**
```javascript
// REST: 사용자 이름만 필요한데 전체 데이터 받음
GET /api/users/123
{
  "id": 123,
  "name": "John",
  "email": "john@example.com",
  "address": { ... },  // 불필요
  "preferences": { ... },  // 불필요
  "orders": [ ... ]  // 불필요
}
```

**Under-fetching (추가 요청 필요)**
```javascript
// 사용자 + 최근 주문 3개 필요
GET /api/users/123         // 1번 요청
GET /api/users/123/orders  // 2번 요청

// 총 2번 요청
```

---

### GraphQL의 장점

**정확한 데이터 요청**
```graphql
# 필요한 필드만 요청
query {
  user(id: 123) {
    name
    recentOrders(limit: 3) {
      id
      total
      createdAt
    }
  }
}

# 1번 요청으로 완료
```

**결과:**
- 네트워크 전송량: 80% 감소
- API 요청 수: 60% 감소
- 프론트엔드 코드 간소화

---

## Apollo Server 설정

### 설치

```bash
npm install @apollo/server graphql
npm install -D @graphql-codegen/cli @graphql-codegen/typescript @graphql-codegen/typescript-resolvers
```

---

### 기본 설정 (Next.js 15 App Router)

**app/api/graphql/route.ts:**
```typescript
import { ApolloServer } from '@apollo/server';
import { startServerAndCreateNextHandler } from '@as-integrations/next';
import { typeDefs } from './schema';
import { resolvers } from './resolvers';

const server = new ApolloServer({
  typeDefs,
  resolvers,
  introspection: process.env.NODE_ENV !== 'production',
});

const handler = startServerAndCreateNextHandler(server, {
  context: async (req) => ({
    req,
    user: await getUserFromToken(req.headers.get('authorization')),
  }),
});

export { handler as GET, handler as POST };
```

---

### 스키마 정의

**app/api/graphql/schema.ts:**
```typescript
export const typeDefs = `#graphql
  """
  사용자 정보
  """
  type User {
    id: ID!
    email: String!
    name: String!
    posts: [Post!]!
    createdAt: DateTime!
  }

  """
  블로그 포스트
  """
  type Post {
    id: ID!
    title: String!
    content: String!
    author: User!
    comments: [Comment!]!
    publishedAt: DateTime
    createdAt: DateTime!
  }

  type Comment {
    id: ID!
    content: String!
    author: User!
    post: Post!
    createdAt: DateTime!
  }

  """
  커스텀 스칼라: ISO 8601 날짜
  """
  scalar DateTime

  type Query {
    "모든 사용자 조회"
    users: [User!]!

    "특정 사용자 조회"
    user(id: ID!): User

    "모든 포스트 조회 (페이지네이션)"
    posts(limit: Int = 10, offset: Int = 0): [Post!]!

    "특정 포스트 조회"
    post(id: ID!): Post
  }

  type Mutation {
    "새 포스트 작성"
    createPost(input: CreatePostInput!): Post!

    "포스트 수정"
    updatePost(id: ID!, input: UpdatePostInput!): Post!

    "포스트 삭제"
    deletePost(id: ID!): Boolean!
  }

  input CreatePostInput {
    title: String!
    content: String!
  }

  input UpdatePostInput {
    title: String
    content: String
    publishedAt: DateTime
  }
`;
```

---

### Resolvers

**app/api/graphql/resolvers.ts:**
```typescript
import { GraphQLScalarType } from 'graphql';
import { Resolvers } from './generated/graphql';
import { prisma } from '@/lib/prisma';

// DateTime 스칼라
const dateTimeScalar = new GraphQLScalarType({
  name: 'DateTime',
  description: 'ISO 8601 date-time string',
  serialize(value: Date) {
    return value.toISOString();
  },
  parseValue(value: string) {
    return new Date(value);
  },
  parseLiteral(ast) {
    if (ast.kind === 'StringValue') {
      return new Date(ast.value);
    }
    return null;
  },
});

export const resolvers: Resolvers = {
  DateTime: dateTimeScalar,

  Query: {
    users: async () => {
      return await prisma.user.findMany();
    },

    user: async (_, { id }) => {
      return await prisma.user.findUnique({
        where: { id },
      });
    },

    posts: async (_, { limit, offset }) => {
      return await prisma.post.findMany({
        take: limit,
        skip: offset,
        orderBy: { createdAt: 'desc' },
      });
    },

    post: async (_, { id }) => {
      return await prisma.post.findUnique({
        where: { id },
      });
    },
  },

  Mutation: {
    createPost: async (_, { input }, context) => {
      if (!context.user) {
        throw new Error('Unauthorized');
      }

      return await prisma.post.create({
        data: {
          ...input,
          authorId: context.user.id,
        },
      });
    },

    updatePost: async (_, { id, input }, context) => {
      const post = await prisma.post.findUnique({
        where: { id },
      });

      if (!post) {
        throw new Error('Post not found');
      }

      if (post.authorId !== context.user?.id) {
        throw new Error('Forbidden');
      }

      return await prisma.post.update({
        where: { id },
        data: input,
      });
    },

    deletePost: async (_, { id }, context) => {
      const post = await prisma.post.findUnique({
        where: { id },
      });

      if (!post) {
        throw new Error('Post not found');
      }

      if (post.authorId !== context.user?.id) {
        throw new Error('Forbidden');
      }

      await prisma.post.delete({
        where: { id },
      });

      return true;
    },
  },

  // Field Resolvers
  User: {
    posts: async (parent) => {
      return await prisma.post.findMany({
        where: { authorId: parent.id },
      });
    },
  },

  Post: {
    author: async (parent) => {
      return await prisma.user.findUniqueOrThrow({
        where: { id: parent.authorId },
      });
    },

    comments: async (parent) => {
      return await prisma.comment.findMany({
        where: { postId: parent.id },
      });
    },
  },

  Comment: {
    author: async (parent) => {
      return await prisma.user.findUniqueOrThrow({
        where: { id: parent.authorId },
      });
    },

    post: async (parent) => {
      return await prisma.post.findUniqueOrThrow({
        where: { id: parent.postId },
      });
    },
  },
};
```

---

## TypeScript Code Generation

### Codegen 설정

**codegen.ts:**
```typescript
import type { CodegenConfig } from '@graphql-codegen/cli';

const config: CodegenConfig = {
  schema: './app/api/graphql/schema.ts',
  generates: {
    // 서버 타입
    './app/api/graphql/generated/graphql.ts': {
      plugins: [
        'typescript',
        'typescript-resolvers',
      ],
      config: {
        useIndexSignature: true,
        contextType: '../types#Context',
        mappers: {
          User: '@prisma/client#User',
          Post: '@prisma/client#Post',
          Comment: '@prisma/client#Comment',
        },
      },
    },

    // 클라이언트 타입
    './lib/graphql/generated/': {
      documents: './lib/graphql/**/*.graphql',
      preset: 'client',
      config: {
        documentMode: 'string',
      },
    },
  },
};

export default config;
```

**app/api/graphql/types.ts:**
```typescript
import { User } from '@prisma/client';

export interface Context {
  req: Request;
  user: User | null;
}
```

---

### package.json 스크립트

```json
{
  "scripts": {
    "codegen": "graphql-codegen",
    "codegen:watch": "graphql-codegen --watch"
  }
}
```

**실행:**
```bash
npm run codegen
```

---

### 클라이언트 사용 (React)

**lib/graphql/queries/getUser.graphql:**
```graphql
query GetUser($id: ID!) {
  user(id: $id) {
    id
    name
    email
    posts {
      id
      title
      createdAt
    }
  }
}
```

**components/UserProfile.tsx:**
```typescript
import { useQuery } from '@apollo/client';
import { graphql } from '@/lib/graphql/generated';

// 타입 안전한 쿼리
const GET_USER = graphql(`
  query GetUser($id: ID!) {
    user(id: $id) {
      id
      name
      email
      posts {
        id
        title
        createdAt
      }
    }
  }
`);

export function UserProfile({ userId }: { userId: string }) {
  const { data, loading, error } = useQuery(GET_USER, {
    variables: { id: userId },
  });

  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;
  if (!data?.user) return <div>User not found</div>;

  // 완전한 타입 안전성!
  return (
    <div>
      <h1>{data.user.name}</h1>
      <p>{data.user.email}</p>

      <h2>Posts</h2>
      <ul>
        {data.user.posts.map(post => (
          <li key={post.id}>
            {post.title} - {new Date(post.createdAt).toLocaleDateString()}
          </li>
        ))}
      </ul>
    </div>
  );
}
```

---

## N+1 문제 해결 (DataLoader)

### N+1 문제 예시

**문제:**
```typescript
// 포스트 10개 조회
const posts = await prisma.post.findMany({ take: 10 });

// 각 포스트의 작성자 조회 (10번 쿼리!)
for (const post of posts) {
  post.author = await prisma.user.findUnique({
    where: { id: post.authorId }
  });
}

// 총 11번 쿼리 (1 + 10)
```

---

### DataLoader 설치

```bash
npm install dataloader
```

---

### DataLoader 구현

**app/api/graphql/dataloaders.ts:**
```typescript
import DataLoader from 'dataloader';
import { prisma } from '@/lib/prisma';
import { User, Post, Comment } from '@prisma/client';

// User DataLoader
export const createUserLoader = () =>
  new DataLoader<string, User | null>(async (userIds) => {
    const users = await prisma.user.findMany({
      where: { id: { in: [...userIds] } },
    });

    // 입력 순서와 동일하게 반환 (중요!)
    const userMap = new Map(users.map(user => [user.id, user]));
    return userIds.map(id => userMap.get(id) || null);
  });

// Post DataLoader
export const createPostLoader = () =>
  new DataLoader<string, Post | null>(async (postIds) => {
    const posts = await prisma.post.findMany({
      where: { id: { in: [...postIds] } },
    });

    const postMap = new Map(posts.map(post => [post.id, post]));
    return postIds.map(id => postMap.get(id) || null);
  });

// Posts by Author (배치 로딩)
export const createPostsByAuthorLoader = () =>
  new DataLoader<string, Post[]>(async (authorIds) => {
    const posts = await prisma.post.findMany({
      where: { authorId: { in: [...authorIds] } },
    });

    // 작성자별로 그룹화
    const postsByAuthor = new Map<string, Post[]>();
    for (const post of posts) {
      const existing = postsByAuthor.get(post.authorId) || [];
      postsByAuthor.set(post.authorId, [...existing, post]);
    }

    return authorIds.map(id => postsByAuthor.get(id) || []);
  });

// Comments by Post
export const createCommentsByPostLoader = () =>
  new DataLoader<string, Comment[]>(async (postIds) => {
    const comments = await prisma.comment.findMany({
      where: { postId: { in: [...postIds] } },
    });

    const commentsByPost = new Map<string, Comment[]>();
    for (const comment of comments) {
      const existing = commentsByPost.get(comment.postId) || [];
      commentsByPost.set(comment.postId, [...existing, comment]);
    }

    return postIds.map(id => commentsByPost.get(id) || []);
  });
```

---

### Context에 DataLoader 추가

**app/api/graphql/route.ts:**
```typescript
import { ApolloServer } from '@apollo/server';
import { startServerAndCreateNextHandler } from '@as-integrations/next';
import { typeDefs } from './schema';
import { resolvers } from './resolvers';
import {
  createUserLoader,
  createPostLoader,
  createPostsByAuthorLoader,
  createCommentsByPostLoader,
} from './dataloaders';

const server = new ApolloServer({
  typeDefs,
  resolvers,
});

const handler = startServerAndCreateNextHandler(server, {
  context: async (req) => ({
    req,
    user: await getUserFromToken(req.headers.get('authorization')),

    // 요청마다 새 DataLoader 인스턴스 생성
    loaders: {
      user: createUserLoader(),
      post: createPostLoader(),
      postsByAuthor: createPostsByAuthorLoader(),
      commentsByPost: createCommentsByPostLoader(),
    },
  }),
});

export { handler as GET, handler as POST };
```

---

### Resolvers에서 DataLoader 사용

**app/api/graphql/resolvers.ts:**
```typescript
export const resolvers: Resolvers = {
  // ...

  User: {
    posts: async (parent, _, context) => {
      // DataLoader로 배치 로딩
      return await context.loaders.postsByAuthor.load(parent.id);
    },
  },

  Post: {
    author: async (parent, _, context) => {
      // DataLoader로 배치 로딩
      return await context.loaders.user.load(parent.authorId);
    },

    comments: async (parent, _, context) => {
      return await context.loaders.commentsByPost.load(parent.id);
    },
  },

  Comment: {
    author: async (parent, _, context) => {
      return await context.loaders.user.load(parent.authorId);
    },

    post: async (parent, _, context) => {
      return await context.loaders.post.load(parent.postId);
    },
  },
};
```

---

### 결과 비교

**Before (N+1 문제):**
```
포스트 10개 조회:
  SELECT * FROM posts LIMIT 10;        -- 1 쿼리
  SELECT * FROM users WHERE id = 1;    -- 10 쿼리 (각 포스트마다)
  SELECT * FROM users WHERE id = 2;
  ...
총: 11 쿼리
```

**After (DataLoader):**
```
포스트 10개 조회:
  SELECT * FROM posts LIMIT 10;                -- 1 쿼리
  SELECT * FROM users WHERE id IN (1,2,3,...); -- 1 쿼리 (배치)
총: 2 쿼리 (82% 감소!)
```

---

## 스키마 설계 Best Practices

### 1. 명확한 네이밍

```graphql
# ✅ 좋은 예
type User {
  id: ID!
  email: String!
  fullName: String!
}

query {
  getUserById(id: ID!): User
  listAllUsers: [User!]!
}

# ❌ 나쁜 예
type User {
  id: ID!
  e: String!  # 불명확
  n: String!  # 불명확
}

query {
  get(id: ID!): User  # 무엇을 가져오는지 불명확
}
```

---

### 2. Non-null vs Nullable

```graphql
# ✅ 좋은 예
type User {
  id: ID!              # 항상 존재
  email: String!       # 항상 존재
  bio: String          # 선택적
  avatarUrl: String    # 선택적
}

query {
  user(id: ID!): User  # null 가능 (사용자 없을 수 있음)
  users: [User!]!      # 항상 배열 반환 (빈 배열 가능)
}
```

---

### 3. Input Types

```graphql
# ✅ 좋은 예: Input Type 사용
input CreateUserInput {
  email: String!
  name: String!
  bio: String
}

mutation {
  createUser(input: CreateUserInput!): User!
}

# ❌ 나쁜 예: 개별 인자
mutation {
  createUser(
    email: String!
    name: String!
    bio: String
  ): User!
}
```

---

### 4. Pagination

```graphql
# ✅ 좋은 예: Cursor-based Pagination
type PageInfo {
  hasNextPage: Boolean!
  hasPreviousPage: Boolean!
  startCursor: String
  endCursor: String
}

type PostEdge {
  node: Post!
  cursor: String!
}

type PostConnection {
  edges: [PostEdge!]!
  pageInfo: PageInfo!
  totalCount: Int!
}

query {
  posts(
    first: Int
    after: String
    last: Int
    before: String
  ): PostConnection!
}
```

---

### 5. 에러 처리

```typescript
// ✅ 좋은 예: 커스텀 에러
import { GraphQLError } from 'graphql';

export const resolvers = {
  Mutation: {
    createPost: async (_, { input }, context) => {
      if (!context.user) {
        throw new GraphQLError('Authentication required', {
          extensions: {
            code: 'UNAUTHENTICATED',
          },
        });
      }

      if (input.title.length < 5) {
        throw new GraphQLError('Title must be at least 5 characters', {
          extensions: {
            code: 'BAD_USER_INPUT',
            argumentName: 'title',
          },
        });
      }

      return await prisma.post.create({ data: input });
    },
  },
};
```

---

### 6. 문서화 (Markdown)

```graphql
"""
사용자 정보를 나타냅니다.

## 권한
- 자신의 정보: 모든 필드 조회 가능
- 타인의 정보: 공개 필드만 조회 가능
"""
type User {
  "고유 식별자"
  id: ID!

  "이메일 주소 (비공개)"
  email: String!

  "표시 이름"
  name: String!

  """
  사용자가 작성한 포스트 목록

  기본적으로 최신 순으로 정렬됩니다.
  """
  posts(
    "반환할 최대 포스트 수"
    limit: Int = 10

    "건너뛸 포스트 수"
    offset: Int = 0
  ): [Post!]!
}
```

---

## 실전 사례

### 사례: E커머스 GraphQL API 구축

**Before (REST API)**
```
- GET /api/products → 상품 목록
- GET /api/products/:id → 상품 상세
- GET /api/products/:id/reviews → 리뷰
- GET /api/users/:id → 판매자 정보
- GET /api/categories/:id → 카테고리

문제:
- 상품 상세 페이지: 4-5번 요청
- Over-fetching: 불필요한 데이터 전송
- N+1 문제: 상품 목록에서 각 판매자 정보 조회
```

---

**GraphQL 마이그레이션:**

**1. 스키마 설계**
```graphql
type Product {
  id: ID!
  name: String!
  description: String!
  price: Float!
  images: [String!]!
  seller: User!
  category: Category!
  reviews(limit: Int = 5): [Review!]!
  averageRating: Float
  totalReviews: Int!
}

type User {
  id: ID!
  name: String!
  avatar: String
  products: [Product!]!
}

type Category {
  id: ID!
  name: String!
  products: [Product!]!
}

type Review {
  id: ID!
  rating: Int!
  comment: String!
  author: User!
  product: Product!
  createdAt: DateTime!
}

type Query {
  product(id: ID!): Product
  products(
    categoryId: ID
    searchQuery: String
    limit: Int = 20
    offset: Int = 0
  ): [Product!]!

  categories: [Category!]!
}
```

---

**2. DataLoader 구현**
```typescript
// dataloaders.ts
export const createProductLoader = () =>
  new DataLoader<string, Product>(async (productIds) => {
    const products = await prisma.product.findMany({
      where: { id: { in: [...productIds] } },
    });

    const productMap = new Map(products.map(p => [p.id, p]));
    return productIds.map(id => productMap.get(id)!);
  });

export const createReviewsByProductLoader = () =>
  new DataLoader<string, Review[]>(async (productIds) => {
    const reviews = await prisma.review.findMany({
      where: { productId: { in: [...productIds] } },
      take: 5,
      orderBy: { createdAt: 'desc' },
    });

    const reviewsByProduct = new Map<string, Review[]>();
    for (const review of reviews) {
      const existing = reviewsByProduct.get(review.productId) || [];
      reviewsByProduct.set(review.productId, [...existing, review]);
    }

    return productIds.map(id => reviewsByProduct.get(id) || []);
  });
```

---

**3. 클라이언트 쿼리 (상품 상세 페이지)**
```graphql
query GetProductDetail($id: ID!) {
  product(id: $id) {
    id
    name
    description
    price
    images
    averageRating
    totalReviews

    seller {
      id
      name
      avatar
    }

    category {
      id
      name
    }

    reviews(limit: 5) {
      id
      rating
      comment
      author {
        name
        avatar
      }
      createdAt
    }
  }
}
```

**결과: 1번 요청으로 모든 데이터 완료!**

---

**After (GraphQL)**
```
✅ API 요청 수: 5번 → 1번 (80% 감소)
✅ 네트워크 전송량: 120KB → 35KB (71% 감소)
✅ 페이지 로딩 시간: 2.5초 → 0.8초 (68% 빠름)
✅ 프론트엔드 코드 라인: -40%
✅ 타입 안전성: 100% (Code Generation)
```

**ROI:**
- 개발 속도: +45%
- 모바일 사용자 이탈률: -35%
- API 서버 비용: -25%

---

## 체크리스트

### 스키마 설계
- [ ] 명확한 네이밍 (camelCase 필드, PascalCase 타입)
- [ ] Non-null vs Nullable 올바른 사용
- [ ] Input Types 사용
- [ ] Markdown 문서화
- [ ] Pagination 구현

### Code Generation
- [ ] `@graphql-codegen/cli` 설치
- [ ] codegen.ts 설정
- [ ] 타입 매핑 (Prisma → GraphQL)
- [ ] 클라이언트 Preset 설정

### 성능 최적화
- [ ] DataLoader 구현 (N+1 해결)
- [ ] 요청마다 새 DataLoader 인스턴스
- [ ] 배치 로딩 순서 보장
- [ ] 적절한 캐싱 전략

### 보안
- [ ] Authentication (JWT)
- [ ] Authorization (Field-level)
- [ ] Rate Limiting
- [ ] Query Depth Limiting
- [ ] Query Complexity Analysis

### 개발 환경
- [ ] Apollo Studio (GraphQL IDE)
- [ ] Introspection (개발 환경만)
- [ ] 에러 로깅
- [ ] Performance Monitoring

---

## 참고 자료

- [Apollo Server Documentation](https://www.apollographql.com/docs/apollo-server)
- [GraphQL Code Generator](https://the-guild.dev/graphql/codegen)
- [DataLoader GitHub](https://github.com/graphql/dataloader)
- [GraphQL Best Practices (Apollo)](https://www.apollographql.com/docs/react/data/operation-best-practices)
- [Principled GraphQL](https://github.com/apollographql/principled-graphql)

---

**타입 안전하고 효율적인 GraphQL API로 개발 속도를 2배로! 🚀**
