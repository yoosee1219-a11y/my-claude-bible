# Modern Backend Frameworks - 최신 백엔드 프레임워크 전문가

## 개요
tRPC, Hono, Bun, Fastify 등 최신 백엔드 프레임워크와 패턴을 활용한 고성능 API 서버 개발 전문 스킬입니다.

## 핵심 역량

### 1. tRPC - 타입 안전한 API
- **End-to-end Type Safety** - 완전한 타입 안전성
- **No Code Generation** - 코드 생성 불필요
- **React Query Integration** - React Query 통합
- **Zod Validation** - Zod 스키마 검증
- **Batch Requests** - 배치 요청 지원

### 2. Hono - 엣지 최적화 프레임워크
- **Ultrafast** - 초고속 라우터
- **Multi-runtime** - 여러 런타임 지원
- **Middleware** - 풍부한 미들웨어
- **TypeScript First** - TypeScript 우선
- **Zero Dependencies** - 의존성 없음

### 3. Bun - 올인원 JavaScript 런타임
- **Fast Runtime** - 빠른 실행 속도
- **Native Bundler** - 내장 번들러
- **Test Runner** - 내장 테스트 러너
- **Package Manager** - 내장 패키지 매니저
- **SQLite Support** - SQLite 기본 지원

### 4. Fastify - 고성능 Node.js 프레임워크
- **Low Overhead** - 낮은 오버헤드
- **Schema-based** - 스키마 기반 검증
- **Plugin System** - 플러그인 시스템
- **TypeScript Support** - TypeScript 지원
- **Logging** - 내장 로깅

---

## 1. tRPC - 타입 안전한 API

### 1.1 tRPC 서버 설정 (Next.js 15 App Router)

```typescript
// server/trpc.ts
import { initTRPC } from '@trpc/server'
import { z } from 'zod'

// Context 정의
export const createContext = async () => {
  return {
    userId: null,  // 인증 로직 추가
  }
}

type Context = Awaited<ReturnType<typeof createContext>>

// tRPC 인스턴스 생성
const t = initTRPC.context<Context>().create()

export const router = t.router
export const publicProcedure = t.procedure

// Router 정의
export const appRouter = router({
  getUser: publicProcedure
    .input(z.object({ id: z.number() }))
    .query(async ({ input }) => {
      const user = await db.user.findUnique({
        where: { id: input.id },
      })
      return user
    }),

  createUser: publicProcedure
    .input(
      z.object({
        name: z.string().min(1),
        email: z.string().email(),
      })
    )
    .mutation(async ({ input }) => {
      const user = await db.user.create({
        data: input,
      })
      return user
    }),

  listUsers: publicProcedure
    .input(
      z.object({
        limit: z.number().min(1).max(100).default(10),
        cursor: z.number().optional(),
      })
    )
    .query(async ({ input }) => {
      const users = await db.user.findMany({
        take: input.limit + 1,
        cursor: input.cursor ? { id: input.cursor } : undefined,
      })

      let nextCursor: number | undefined = undefined
      if (users.length > input.limit) {
        const nextItem = users.pop()
        nextCursor = nextItem!.id
      }

      return {
        users,
        nextCursor,
      }
    }),
})

export type AppRouter = typeof appRouter
```

### 1.2 tRPC API Route (Next.js 15)

```typescript
// app/api/trpc/[trpc]/route.ts
import { fetchRequestHandler } from '@trpc/server/adapters/fetch'
import { appRouter, createContext } from '@/server/trpc'

const handler = (req: Request) =>
  fetchRequestHandler({
    endpoint: '/api/trpc',
    req,
    router: appRouter,
    createContext,
  })

export { handler as GET, handler as POST }
```

### 1.3 tRPC 클라이언트 설정

```typescript
// lib/trpc/client.ts
import { createTRPCReact } from '@trpc/react-query'
import type { AppRouter } from '@/server/trpc'

export const trpc = createTRPCReact<AppRouter>()

// lib/trpc/provider.tsx
'use client'

import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { httpBatchLink } from '@trpc/client'
import { useState } from 'react'
import { trpc } from './client'

export function TRPCProvider({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(() => new QueryClient())
  const [trpcClient] = useState(() =>
    trpc.createClient({
      links: [
        httpBatchLink({
          url: '/api/trpc',
        }),
      ],
    })
  )

  return (
    <trpc.Provider client={trpcClient} queryClient={queryClient}>
      <QueryClientProvider client={queryClient}>
        {children}
      </QueryClientProvider>
    </trpc.Provider>
  )
}
```

### 1.4 tRPC 사용 (클라이언트)

```typescript
'use client'

import { trpc } from '@/lib/trpc/client'

export function UserList() {
  // ✅ 완전한 타입 안전성
  const { data, isLoading, error } = trpc.listUsers.useQuery({
    limit: 10,
  })

  const createUser = trpc.createUser.useMutation({
    onSuccess: () => {
      // 쿼리 무효화
      trpc.useContext().listUsers.invalidate()
    },
  })

  if (isLoading) return <div>Loading...</div>
  if (error) return <div>Error: {error.message}</div>

  return (
    <div>
      <button
        onClick={() =>
          createUser.mutate({
            name: 'John Doe',
            email: 'john@example.com',
          })
        }
      >
        Add User
      </button>

      <ul>
        {data?.users.map((user) => (
          <li key={user.id}>
            {user.name} - {user.email}
          </li>
        ))}
      </ul>
    </div>
  )
}
```

### 1.5 tRPC Middleware (인증)

```typescript
// server/trpc.ts
import { TRPCError } from '@trpc/server'

const isAuthed = t.middleware(({ ctx, next }) => {
  if (!ctx.userId) {
    throw new TRPCError({ code: 'UNAUTHORIZED' })
  }
  return next({
    ctx: {
      userId: ctx.userId,
    },
  })
})

// Protected procedure
export const protectedProcedure = t.procedure.use(isAuthed)

// Router에서 사용
export const appRouter = router({
  // Public
  getUser: publicProcedure
    .input(z.object({ id: z.number() }))
    .query(async ({ input }) => {
      // ...
    }),

  // Protected
  deleteUser: protectedProcedure
    .input(z.object({ id: z.number() }))
    .mutation(async ({ input, ctx }) => {
      // ctx.userId는 확정됨
      await db.user.delete({ where: { id: input.id } })
      return { success: true }
    }),
})
```

---

## 2. Hono - 엣지 최적화 프레임워크

### 2.1 Hono 기본 설정

```typescript
// app/api/[[...route]]/route.ts
import { Hono } from 'hono'
import { handle } from 'hono/vercel'
import { z } from 'zod'
import { zValidator } from '@hono/zod-validator'

export const runtime = 'edge'

const app = new Hono().basePath('/api')

// Middleware
app.use('*', async (c, next) => {
  console.log(`${c.req.method} ${c.req.url}`)
  await next()
})

// Routes
app.get('/hello', (c) => {
  return c.json({ message: 'Hello from Hono!' })
})

// Validation with Zod
const userSchema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
})

app.post('/users', zValidator('json', userSchema), async (c) => {
  const data = c.req.valid('json')
  // data는 타입 안전

  const user = await db.user.create({ data })
  return c.json(user, 201)
})

// Path parameters
app.get('/users/:id', async (c) => {
  const id = c.req.param('id')
  const user = await db.user.findUnique({ where: { id: Number(id) } })

  if (!user) {
    return c.json({ error: 'User not found' }, 404)
  }

  return c.json(user)
})

export const GET = handle(app)
export const POST = handle(app)
export const PUT = handle(app)
export const DELETE = handle(app)
```

### 2.2 Hono with TypeScript

```typescript
import { Hono } from 'hono'

type Bindings = {
  DATABASE_URL: string
  API_KEY: string
}

type Variables = {
  userId: number
}

const app = new Hono<{ Bindings: Bindings; Variables: Variables }>()

// Middleware로 변수 설정
app.use('*', async (c, next) => {
  c.set('userId', 123)
  await next()
})

app.get('/profile', (c) => {
  const userId = c.get('userId')  // 타입 안전
  const dbUrl = c.env.DATABASE_URL  // 타입 안전
  return c.json({ userId })
})
```

### 2.3 Hono Middleware

```typescript
import { Hono } from 'hono'
import { cors } from 'hono/cors'
import { logger } from 'hono/logger'
import { prettyJSON } from 'hono/pretty-json'
import { jwt } from 'hono/jwt'

const app = new Hono()

// CORS
app.use('*', cors({
  origin: ['https://example.com'],
  credentials: true,
}))

// Logger
app.use('*', logger())

// Pretty JSON
app.use('*', prettyJSON())

// JWT Authentication
app.use('/api/*', jwt({
  secret: process.env.JWT_SECRET!,
}))

app.get('/api/protected', (c) => {
  const payload = c.get('jwtPayload')
  return c.json({ user: payload })
})
```

### 2.4 Hono with RPC

```typescript
// server/api.ts
import { Hono } from 'hono'
import { zValidator } from '@hono/zod-validator'
import { z } from 'zod'

const app = new Hono()
  .get('/users', async (c) => {
    const users = await db.user.findMany()
    return c.json(users)
  })
  .post(
    '/users',
    zValidator('json', z.object({
      name: z.string(),
      email: z.string().email(),
    })),
    async (c) => {
      const data = c.req.valid('json')
      const user = await db.user.create({ data })
      return c.json(user)
    }
  )

export type AppType = typeof app
export default app

// client/api.ts
import { hc } from 'hono/client'
import type { AppType } from '../server/api'

const client = hc<AppType>('/api')

// ✅ 완전한 타입 안전성
const res = await client.users.$post({
  json: {
    name: 'John',
    email: 'john@example.com',
  },
})

const user = await res.json()  // 타입 추론됨
```

---

## 3. Bun - 올인원 JavaScript 런타임

### 3.1 Bun HTTP 서버

```typescript
// server.ts
const server = Bun.serve({
  port: 3000,
  async fetch(req) {
    const url = new URL(req.url)

    // JSON 응답
    if (url.pathname === '/api/hello') {
      return Response.json({ message: 'Hello from Bun!' })
    }

    // Static file serving
    if (url.pathname.startsWith('/public/')) {
      const file = Bun.file(`.${url.pathname}`)
      return new Response(file)
    }

    // 404
    return new Response('Not Found', { status: 404 })
  },
})

console.log(`Server running at http://localhost:${server.port}`)
```

### 3.2 Bun SQLite

```typescript
import { Database } from 'bun:sqlite'

// 데이터베이스 생성
const db = new Database('mydb.sqlite')

// 테이블 생성
db.run(`
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL
  )
`)

// 데이터 삽입
const insert = db.prepare('INSERT INTO users (name, email) VALUES (?, ?)')
insert.run('John Doe', 'john@example.com')

// 데이터 조회
const query = db.query('SELECT * FROM users WHERE id = ?')
const user = query.get(1)  // { id: 1, name: 'John Doe', email: '...' }

// 모든 데이터 조회
const allUsers = db.query('SELECT * FROM users').all()

// Transaction
db.transaction(() => {
  insert.run('Jane Doe', 'jane@example.com')
  insert.run('Bob Smith', 'bob@example.com')
})()

// Close
db.close()
```

### 3.3 Bun with Hono

```typescript
import { Hono } from 'hono'

const app = new Hono()

app.get('/', (c) => c.text('Hello Bun + Hono!'))

app.get('/api/users', async (c) => {
  const users = await db.query('SELECT * FROM users').all()
  return c.json(users)
})

export default {
  port: 3000,
  fetch: app.fetch,
}
```

### 3.4 Bun Testing

```typescript
// math.test.ts
import { expect, test, describe } from 'bun:test'

describe('Math', () => {
  test('addition', () => {
    expect(1 + 1).toBe(2)
  })

  test('multiplication', () => {
    expect(2 * 3).toBe(6)
  })
})

// API testing
import { describe, test, expect } from 'bun:test'

describe('API', () => {
  test('GET /api/users', async () => {
    const res = await fetch('http://localhost:3000/api/users')
    expect(res.status).toBe(200)

    const data = await res.json()
    expect(Array.isArray(data)).toBe(true)
  })
})
```

---

## 4. Fastify - 고성능 Node.js 프레임워크

### 4.1 Fastify 기본 설정

```typescript
import Fastify from 'fastify'
import { TypeBoxTypeProvider } from '@fastify/type-provider-typebox'
import { Type } from '@sinclair/typebox'

const fastify = Fastify({
  logger: true,
}).withTypeProvider<TypeBoxTypeProvider>()

// Schema 정의
const UserSchema = Type.Object({
  id: Type.Number(),
  name: Type.String(),
  email: Type.String({ format: 'email' }),
})

// Routes
fastify.get('/users/:id', {
  schema: {
    params: Type.Object({
      id: Type.Number(),
    }),
    response: {
      200: UserSchema,
      404: Type.Object({
        error: Type.String(),
      }),
    },
  },
  handler: async (request, reply) => {
    const { id } = request.params
    const user = await db.user.findUnique({ where: { id } })

    if (!user) {
      return reply.code(404).send({ error: 'User not found' })
    }

    return user
  },
})

fastify.post('/users', {
  schema: {
    body: Type.Object({
      name: Type.String({ minLength: 1 }),
      email: Type.String({ format: 'email' }),
    }),
    response: {
      201: UserSchema,
    },
  },
  handler: async (request, reply) => {
    const user = await db.user.create({ data: request.body })
    return reply.code(201).send(user)
  },
})

// Start server
fastify.listen({ port: 3000 }, (err) => {
  if (err) {
    fastify.log.error(err)
    process.exit(1)
  }
})
```

### 4.2 Fastify Plugins

```typescript
import fp from 'fastify-plugin'

// Database plugin
export const dbPlugin = fp(async (fastify) => {
  const prisma = new PrismaClient()

  fastify.decorate('db', prisma)

  fastify.addHook('onClose', async (instance) => {
    await instance.db.$disconnect()
  })
})

// Usage
fastify.register(dbPlugin)

fastify.get('/users', async (request, reply) => {
  const users = await fastify.db.user.findMany()
  return users
})
```

### 4.3 Fastify Hooks

```typescript
// Global hooks
fastify.addHook('onRequest', async (request, reply) => {
  console.log(`${request.method} ${request.url}`)
})

fastify.addHook('preHandler', async (request, reply) => {
  const token = request.headers.authorization
  if (!token) {
    reply.code(401).send({ error: 'Unauthorized' })
  }
})

// Route-specific hooks
fastify.get('/protected', {
  preHandler: async (request, reply) => {
    // 이 라우트에만 적용
    const user = await verifyToken(request.headers.authorization)
    request.user = user
  },
  handler: async (request, reply) => {
    return { user: request.user }
  },
})
```

### 4.4 Fastify with TypeScript

```typescript
import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify'

interface User {
  id: number
  name: string
  email: string
}

interface CreateUserBody {
  name: string
  email: string
}

// Type-safe handler
fastify.post<{ Body: CreateUserBody; Reply: User }>(
  '/users',
  async (request, reply) => {
    const { name, email } = request.body  // 타입 추론
    const user = await db.user.create({ data: { name, email } })
    return reply.code(201).send(user)  // 타입 검증
  }
)

// Type-safe params
interface GetUserParams {
  id: string
}

fastify.get<{ Params: GetUserParams; Reply: User | { error: string } }>(
  '/users/:id',
  async (request, reply) => {
    const { id } = request.params  // 타입 추론
    const user = await db.user.findUnique({ where: { id: Number(id) } })

    if (!user) {
      return reply.code(404).send({ error: 'Not found' })
    }

    return user
  }
)
```

---

## 5. 성능 비교

### 5.1 벤치마크 결과 (2026년 기준)

```
Requests/sec (평균)
1. Bun (native)     ~140,000
2. Hono (Bun)       ~130,000
3. Fastify (Node)   ~75,000
4. Hono (Node)      ~70,000
5. Express (Node)   ~35,000
6. Next.js API      ~25,000
```

### 5.2 프레임워크 선택 가이드

**tRPC를 선택하는 경우:**
- ✅ Fullstack TypeScript 프로젝트
- ✅ Next.js와 통합
- ✅ 완전한 타입 안전성 필요
- ✅ React Query 활용
- ✅ Monorepo 구조

**Hono를 선택하는 경우:**
- ✅ 엣지 런타임 배포 (Vercel, Cloudflare)
- ✅ 초경량 API
- ✅ 멀티 런타임 지원 필요
- ✅ 빠른 시작과 간단한 API

**Bun을 선택하는 경우:**
- ✅ 최고 성능 필요
- ✅ 올인원 툴체인
- ✅ SQLite 사용
- ✅ 빠른 빌드/테스트

**Fastify를 선택하는 경우:**
- ✅ Node.js 생태계 활용
- ✅ 풍부한 플러그인 생태계
- ✅ 스키마 기반 검증
- ✅ 엔터프라이즈 환경

---

## 6. 실전 패턴

### 6.1 에러 처리 (tRPC)

```typescript
import { TRPCError } from '@trpc/server'

export const appRouter = router({
  getUser: publicProcedure
    .input(z.object({ id: z.number() }))
    .query(async ({ input }) => {
      const user = await db.user.findUnique({ where: { id: input.id } })

      if (!user) {
        throw new TRPCError({
          code: 'NOT_FOUND',
          message: `User with id ${input.id} not found`,
        })
      }

      return user
    }),
})

// Client
const { data, error } = trpc.getUser.useQuery({ id: 1 })

if (error) {
  if (error.data?.code === 'NOT_FOUND') {
    // 404 처리
  }
}
```

### 6.2 Rate Limiting (Hono)

```typescript
import { Hono } from 'hono'
import { rateLimiter } from 'hono-rate-limiter'

const app = new Hono()

app.use(
  '*',
  rateLimiter({
    windowMs: 15 * 60 * 1000,  // 15분
    max: 100,  // 최대 100 요청
    message: 'Too many requests',
  })
)
```

### 6.3 CORS (Fastify)

```typescript
import cors from '@fastify/cors'

fastify.register(cors, {
  origin: ['https://example.com'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
})
```

### 6.4 WebSocket (Bun)

```typescript
const server = Bun.serve({
  port: 3000,
  fetch(req, server) {
    const url = new URL(req.url)

    if (url.pathname === '/ws') {
      const success = server.upgrade(req)
      if (success) return undefined
    }

    return new Response('Not a websocket request', { status: 400 })
  },
  websocket: {
    open(ws) {
      console.log('Client connected')
      ws.subscribe('chat-room')
    },
    message(ws, message) {
      ws.publish('chat-room', message)
    },
    close(ws) {
      console.log('Client disconnected')
    },
  },
})
```

---

## 7. 배포

### 7.1 Vercel (Next.js + tRPC/Hono)
```bash
# vercel.json
{
  "framework": "nextjs",
  "regions": ["icn1"]
}
```

### 7.2 Cloudflare Workers (Hono)
```typescript
// wrangler.toml
name = "my-api"
main = "src/index.ts"
compatibility_date = "2024-01-01"

[[kv_namespaces]]
binding = "KV"
id = "your-kv-id"
```

### 7.3 Docker (Fastify/Bun)
```dockerfile
FROM oven/bun:1

WORKDIR /app

COPY package.json bun.lockb ./
RUN bun install

COPY . .

EXPOSE 3000

CMD ["bun", "run", "server.ts"]
```

---

## 체크리스트

### tRPC
- [ ] End-to-end 타입 안전성 확보
- [ ] Zod로 입력 검증
- [ ] React Query 통합
- [ ] 에러 처리 표준화
- [ ] Middleware로 인증/인가

### Hono
- [ ] 엣지 런타임 최적화
- [ ] Zod Validator 활용
- [ ] RPC 타입 추론
- [ ] Middleware 체인
- [ ] CORS, Rate Limiting

### Bun
- [ ] 네이티브 HTTP 서버 활용
- [ ] SQLite 통합
- [ ] 테스트 작성 (bun:test)
- [ ] 빠른 빌드 시간 확보

### Fastify
- [ ] Schema 기반 검증
- [ ] Plugin 시스템 활용
- [ ] Hooks로 로직 분리
- [ ] 로깅 설정
- [ ] TypeScript 타입 정의

---

## 참고 자료
- [tRPC 공식 문서](https://trpc.io/)
- [Hono 문서](https://hono.dev/)
- [Bun 문서](https://bun.sh/docs)
- [Fastify 문서](https://fastify.dev/)
