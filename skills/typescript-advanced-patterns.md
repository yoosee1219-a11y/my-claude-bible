# TypeScript Advanced Patterns - 고급 타입 패턴 전문가

## 개요
TypeScript의 고급 타입 시스템, Zod 스키마 검증, Effect 함수형 프로그래밍을 활용한 타입 세이프 애플리케이션 개발 전문 스킬입니다.

## 핵심 역량

### 1. TypeScript 5.x 고급 기능
- **Template Literal Types** - 문자열 타입 조작
- **Conditional Types** - 조건부 타입
- **Mapped Types** - 매핑 타입
- **Discriminated Unions** - 구별된 유니온
- **Type Guards** - 타입 가드
- **Const Assertions** - 상수 단언

### 2. Zod 스키마 검증
- **Schema Definition** - 스키마 정의
- **Type Inference** - 타입 추론
- **Validation** - 검증 로직
- **Transform** - 데이터 변환
- **Error Handling** - 에러 처리

### 3. Effect 함수형 프로그래밍
- **Effect Type** - 효과 타입
- **Error Channels** - 에러 채널
- **Dependency Injection** - 의존성 주입
- **Resource Management** - 리소스 관리
- **Concurrency** - 동시성 제어

---

## 1. TypeScript 고급 타입 패턴

### 1.1 Template Literal Types

```typescript
// 타입 안전한 이벤트 시스템
type EventName = 'click' | 'hover' | 'focus'
type EventHandler<T extends EventName> = `on${Capitalize<T>}`

// "onClick" | "onHover" | "onFocus"
type AllHandlers = EventHandler<EventName>

// 실제 활용
interface ButtonProps {
  onClick?: () => void
  onHover?: () => void
  onFocus?: () => void
}

// HTTP Method + Path 조합
type HTTPMethod = 'GET' | 'POST' | 'PUT' | 'DELETE'
type APIPath = '/users' | '/posts' | '/comments'
type APIEndpoint = `${HTTPMethod} ${APIPath}`

// "GET /users" | "POST /users" | "PUT /users" | ...
const endpoint: APIEndpoint = 'GET /users'
```

### 1.2 Conditional Types - 조건부 타입

```typescript
// 배열인지 확인하는 타입
type IsArray<T> = T extends any[] ? true : false

type A = IsArray<string[]> // true
type B = IsArray<string>   // false

// 함수 반환 타입 추출
type ReturnTypeOf<T> = T extends (...args: any[]) => infer R ? R : never

function getUser() {
  return { id: 1, name: 'John' }
}

type User = ReturnTypeOf<typeof getUser> // { id: number; name: string }

// Promise 언래핑
type Awaited<T> = T extends Promise<infer U> ? U : T

type A = Awaited<Promise<string>> // string
type B = Awaited<string>          // string

// 실전 예제: API 응답 타입
type APIResponse<T> = {
  data: T
  error: null
} | {
  data: null
  error: string
}

function handleResponse<T>(response: APIResponse<T>): T {
  if (response.error) {
    throw new Error(response.error)
  }
  return response.data
}
```

### 1.3 Mapped Types - 매핑 타입

```typescript
// 모든 속성을 선택적으로
type Partial<T> = {
  [P in keyof T]?: T[P]
}

// 모든 속성을 읽기 전용으로
type Readonly<T> = {
  readonly [P in keyof T]: T[P]
}

// 특정 키만 선택
type Pick<T, K extends keyof T> = {
  [P in K]: T[P]
}

// 특정 키 제외
type Omit<T, K extends keyof T> = Pick<T, Exclude<keyof T, K>>

// 실전 예제
interface User {
  id: number
  name: string
  email: string
  password: string
  createdAt: Date
}

type UserInput = Omit<User, 'id' | 'createdAt'> // password 포함
type UserPublic = Omit<User, 'password'>        // password 제외
type UserUpdate = Partial<UserInput>            // 모든 필드 선택적

// Getters 타입 생성
type Getters<T> = {
  [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K]
}

type UserGetters = Getters<User>
// {
//   getId: () => number
//   getName: () => string
//   getEmail: () => string
//   ...
// }
```

### 1.4 Discriminated Unions - 구별된 유니온

```typescript
// 상태 관리를 위한 타입 세이프 패턴
type LoadingState = {
  status: 'loading'
}

type SuccessState<T> = {
  status: 'success'
  data: T
}

type ErrorState = {
  status: 'error'
  error: string
}

type AsyncState<T> = LoadingState | SuccessState<T> | ErrorState

// 타입 가드를 사용한 안전한 처리
function handleState<T>(state: AsyncState<T>) {
  switch (state.status) {
    case 'loading':
      return <Spinner />
    case 'success':
      return <Data data={state.data} />  // state.data 접근 가능
    case 'error':
      return <Error message={state.error} />  // state.error 접근 가능
  }
}

// 실전 예제: Redux Action
type Action =
  | { type: 'INCREMENT'; payload: number }
  | { type: 'DECREMENT'; payload: number }
  | { type: 'RESET' }

function reducer(state: number, action: Action): number {
  switch (action.type) {
    case 'INCREMENT':
      return state + action.payload  // payload 자동 완성
    case 'DECREMENT':
      return state - action.payload
    case 'RESET':
      return 0
  }
}
```

### 1.5 Type Guards - 타입 가드

```typescript
// User-defined type guards
interface Dog {
  kind: 'dog'
  bark: () => void
}

interface Cat {
  kind: 'cat'
  meow: () => void
}

type Animal = Dog | Cat

// Type predicate
function isDog(animal: Animal): animal is Dog {
  return animal.kind === 'dog'
}

function makeSound(animal: Animal) {
  if (isDog(animal)) {
    animal.bark()  // Dog로 타입 좁혀짐
  } else {
    animal.meow()  // Cat로 타입 좁혀짐
  }
}

// 실전 예제: API 응답 검증
interface SuccessResponse {
  success: true
  data: unknown
}

interface ErrorResponse {
  success: false
  error: string
}

type Response = SuccessResponse | ErrorResponse

function isSuccessResponse(res: Response): res is SuccessResponse {
  return res.success === true
}

async function fetchData() {
  const response: Response = await fetch('/api/data').then(r => r.json())

  if (isSuccessResponse(response)) {
    console.log(response.data)  // data 접근 가능
  } else {
    console.error(response.error)  // error 접근 가능
  }
}
```

### 1.6 Const Assertions - 상수 단언

```typescript
// 일반 객체 (mutable)
const config = {
  apiUrl: 'https://api.example.com',
  timeout: 5000,
  methods: ['GET', 'POST']
}
// Type: { apiUrl: string, timeout: number, methods: string[] }

// const assertion (immutable)
const config = {
  apiUrl: 'https://api.example.com',
  timeout: 5000,
  methods: ['GET', 'POST']
} as const
// Type: {
//   readonly apiUrl: "https://api.example.com"
//   readonly timeout: 5000
//   readonly methods: readonly ["GET", "POST"]
// }

// 실전 예제: Routes 정의
const routes = {
  home: '/',
  about: '/about',
  user: '/user/:id',
  posts: '/posts',
} as const

type Route = typeof routes[keyof typeof routes]
// "/" | "/about" | "/user/:id" | "/posts"

// Enum 대체
const Status = {
  Pending: 'pending',
  InProgress: 'in_progress',
  Done: 'done',
} as const

type Status = typeof Status[keyof typeof Status]
// "pending" | "in_progress" | "done"
```

---

## 2. Zod - 스키마 검증

### 2.1 기본 스키마 정의

```typescript
import { z } from 'zod'

// 기본 타입
const userSchema = z.object({
  id: z.number(),
  name: z.string(),
  email: z.string().email(),
  age: z.number().min(18).max(120),
  role: z.enum(['admin', 'user', 'guest']),
  profile: z.object({
    bio: z.string().optional(),
    avatar: z.string().url().optional(),
  }),
  tags: z.array(z.string()),
  createdAt: z.date(),
})

// 타입 자동 추론
type User = z.infer<typeof userSchema>
// {
//   id: number
//   name: string
//   email: string
//   age: number
//   role: "admin" | "user" | "guest"
//   profile: {
//     bio?: string
//     avatar?: string
//   }
//   tags: string[]
//   createdAt: Date
// }
```

### 2.2 고급 검증 패턴

```typescript
import { z } from 'zod'

// Custom validation
const passwordSchema = z.string()
  .min(8, 'Password must be at least 8 characters')
  .regex(/[A-Z]/, 'Password must contain uppercase')
  .regex(/[a-z]/, 'Password must contain lowercase')
  .regex(/[0-9]/, 'Password must contain number')
  .regex(/[^A-Za-z0-9]/, 'Password must contain special character')

// Refinement
const signupSchema = z.object({
  email: z.string().email(),
  password: passwordSchema,
  confirmPassword: z.string(),
}).refine((data) => data.password === data.confirmPassword, {
  message: "Passwords don't match",
  path: ['confirmPassword'],
})

// Transform
const dateSchema = z.string().transform((str) => new Date(str))

const userInputSchema = z.object({
  name: z.string().transform((val) => val.trim().toLowerCase()),
  age: z.string().transform((val) => parseInt(val, 10)),
  birthDate: dateSchema,
})

// Discriminated unions
const eventSchema = z.discriminatedUnion('type', [
  z.object({ type: z.literal('click'), x: z.number(), y: z.number() }),
  z.object({ type: z.literal('keypress'), key: z.string() }),
  z.object({ type: z.literal('focus'), element: z.string() }),
])

type Event = z.infer<typeof eventSchema>
```

### 2.3 API 요청 검증 (Next.js)

```typescript
// app/api/users/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'

const createUserSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  email: z.string().email('Invalid email'),
  age: z.number().int().min(18, 'Must be 18 or older'),
})

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()

    // ✅ 검증 및 타입 안전성 확보
    const validatedData = createUserSchema.parse(body)

    const user = await db.user.create({
      data: validatedData,  // 타입 안전
    })

    return NextResponse.json(user)
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        { errors: error.errors },
        { status: 400 }
      )
    }
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
```

### 2.4 Form 검증 (React Hook Form)

```typescript
'use client'

import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'

const signupSchema = z.object({
  username: z.string().min(3, 'Username must be at least 3 characters'),
  email: z.string().email('Invalid email address'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  confirmPassword: z.string(),
}).refine((data) => data.password === data.confirmPassword, {
  message: "Passwords don't match",
  path: ['confirmPassword'],
})

type SignupForm = z.infer<typeof signupSchema>

export function SignupForm() {
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<SignupForm>({
    resolver: zodResolver(signupSchema),
  })

  const onSubmit = async (data: SignupForm) => {
    // data는 이미 검증됨
    console.log(data)
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('username')} />
      {errors.username && <span>{errors.username.message}</span>}

      <input {...register('email')} />
      {errors.email && <span>{errors.email.message}</span>}

      <input type="password" {...register('password')} />
      {errors.password && <span>{errors.password.message}</span>}

      <input type="password" {...register('confirmPassword')} />
      {errors.confirmPassword && <span>{errors.confirmPassword.message}</span>}

      <button type="submit">Sign Up</button>
    </form>
  )
}
```

---

## 3. Effect - 함수형 프로그래밍

### 3.1 Effect 기본 개념

```typescript
import { Effect, Console } from 'effect'

// 단순 Effect
const program = Effect.sync(() => {
  console.log('Hello, Effect!')
  return 42
})

// 비동기 Effect
const fetchUser = (id: number) =>
  Effect.tryPromise({
    try: () => fetch(`/api/users/${id}`).then(res => res.json()),
    catch: (error) => new Error(`Failed to fetch user: ${error}`),
  })

// Effect 조합
const getUserName = (id: number) =>
  fetchUser(id).pipe(
    Effect.map(user => user.name),
    Effect.tap(name => Console.log(`User name: ${name}`)),
  )

// 실행
Effect.runPromise(getUserName(1))
  .then(name => console.log(name))
  .catch(error => console.error(error))
```

### 3.2 Error Channels - 타입 안전한 에러 처리

```typescript
import { Effect, Data } from 'effect'

// 에러 타입 정의
class UserNotFoundError extends Data.TaggedError('UserNotFoundError')<{
  userId: number
}> {}

class NetworkError extends Data.TaggedError('NetworkError')<{
  message: string
}> {}

// Effect<성공타입, 에러타입, 요구사항>
const getUser = (id: number): Effect.Effect<User, UserNotFoundError | NetworkError, never> =>
  Effect.tryPromise({
    try: async () => {
      const res = await fetch(`/api/users/${id}`)
      if (!res.ok) {
        throw new UserNotFoundError({ userId: id })
      }
      return res.json()
    },
    catch: (error) => new NetworkError({ message: String(error) }),
  })

// 에러별 처리
const program = getUser(1).pipe(
  Effect.catchTags({
    UserNotFoundError: (error) =>
      Effect.succeed({ id: error.userId, name: 'Guest' }),
    NetworkError: (error) =>
      Effect.fail(new Error(`Network error: ${error.message}`)),
  })
)
```

### 3.3 Dependency Injection - 의존성 주입

```typescript
import { Effect, Context, Layer } from 'effect'

// 서비스 정의
class Database extends Context.Tag('Database')<
  Database,
  {
    query: (sql: string) => Effect.Effect<unknown, Error>
  }
>() {}

class Logger extends Context.Tag('Logger')<
  Logger,
  {
    log: (message: string) => Effect.Effect<void>
  }
>() {}

// 서비스를 사용하는 비즈니스 로직
const getUsers = Effect.gen(function* (_) {
  const db = yield* _(Database)
  const logger = yield* _(Logger)

  yield* _(logger.log('Fetching users...'))
  const users = yield* _(db.query('SELECT * FROM users'))
  yield* _(logger.log(`Found ${users.length} users`))

  return users
})

// Layer 정의 (구현체)
const DatabaseLive = Layer.succeed(Database, {
  query: (sql: string) =>
    Effect.tryPromise({
      try: () => pg.query(sql),
      catch: (error) => new Error(String(error)),
    }),
})

const LoggerLive = Layer.succeed(Logger, {
  log: (message: string) =>
    Effect.sync(() => console.log(message)),
})

// Layer 조합
const AppLive = Layer.merge(DatabaseLive, LoggerLive)

// 실행
const program = getUsers.pipe(Effect.provide(AppLive))

Effect.runPromise(program)
```

### 3.4 Resource Management - 리소스 관리

```typescript
import { Effect, Scope } from 'effect'

// 리소스 획득 및 해제
const makeConnection = Effect.gen(function* (_) {
  const conn = yield* _(
    Effect.acquireRelease(
      Effect.sync(() => {
        console.log('Opening connection')
        return { query: (sql: string) => Promise.resolve([]) }
      }),
      (conn) =>
        Effect.sync(() => {
          console.log('Closing connection')
          // conn.close()
        })
    )
  )

  return conn
})

// 사용
const program = Effect.gen(function* (_) {
  const conn = yield* _(makeConnection)
  const results = yield* _(
    Effect.tryPromise(() => conn.query('SELECT * FROM users'))
  )
  return results
})
// connection은 자동으로 닫힘

// Scope를 사용한 수동 관리
const manualScope = Effect.gen(function* (_) {
  const scope = yield* _(Scope.make())
  const conn = yield* _(makeConnection, Scope.extend(scope))

  // 수동으로 리소스 해제
  yield* _(Scope.close(scope, Effect.unit))
})
```

### 3.5 Concurrency - 동시성 제어

```typescript
import { Effect, Duration } from 'effect'

// 병렬 실행
const fetchUsers = Effect.tryPromise(() => fetch('/api/users'))
const fetchPosts = Effect.tryPromise(() => fetch('/api/posts'))

const parallel = Effect.all([fetchUsers, fetchPosts], {
  concurrency: 'unbounded',
})

// 순차 실행
const sequential = Effect.all([fetchUsers, fetchPosts], {
  concurrency: 1,
})

// 제한된 동시성
const limited = Effect.all(
  [
    fetchUser(1),
    fetchUser(2),
    fetchUser(3),
    fetchUser(4),
    fetchUser(5),
  ],
  { concurrency: 2 }  // 최대 2개씩 동시 실행
)

// Timeout
const withTimeout = fetchUsers.pipe(
  Effect.timeout(Duration.seconds(5)),
  Effect.catchTag('TimeoutException', () =>
    Effect.succeed({ users: [] })
  )
)

// Retry
const withRetry = fetchUsers.pipe(
  Effect.retry({
    times: 3,
    schedule: Schedule.exponential(Duration.millis(100)),
  })
)
```

---

## 4. 실전 패턴

### 4.1 타입 안전한 API 클라이언트

```typescript
import { z } from 'zod'

const userSchema = z.object({
  id: z.number(),
  name: z.string(),
  email: z.string().email(),
})

type User = z.infer<typeof userSchema>

class APIClient {
  private baseURL: string

  constructor(baseURL: string) {
    this.baseURL = baseURL
  }

  async get<T>(path: string, schema: z.ZodType<T>): Promise<T> {
    const res = await fetch(`${this.baseURL}${path}`)
    const data = await res.json()
    return schema.parse(data)  // 런타임 검증 + 타입 안전성
  }

  async post<T, U>(
    path: string,
    body: T,
    inputSchema: z.ZodType<T>,
    outputSchema: z.ZodType<U>
  ): Promise<U> {
    const validatedBody = inputSchema.parse(body)
    const res = await fetch(`${this.baseURL}${path}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(validatedBody),
    })
    const data = await res.json()
    return outputSchema.parse(data)
  }
}

// 사용
const api = new APIClient('https://api.example.com')

const user = await api.get('/users/1', userSchema)
// user는 User 타입이며, 런타임에서도 검증됨
```

### 4.2 Builder Pattern with TypeScript

```typescript
// 타입 안전한 쿼리 빌더
type Query<T> = {
  table: string
  where?: Partial<T>
  select?: (keyof T)[]
  limit?: number
}

class QueryBuilder<T> {
  private query: Query<T> = { table: '' }

  table(name: string): this {
    this.query.table = name
    return this
  }

  where(condition: Partial<T>): this {
    this.query.where = condition
    return this
  }

  select<K extends keyof T>(...fields: K[]): this {
    this.query.select = fields as (keyof T)[]
    return this
  }

  limit(count: number): this {
    this.query.limit = count
    return this
  }

  build(): Query<T> {
    return this.query
  }
}

// 사용
interface User {
  id: number
  name: string
  email: string
  age: number
}

const query = new QueryBuilder<User>()
  .table('users')
  .where({ age: 25 })
  .select('id', 'name', 'email')  // 자동완성 지원
  .limit(10)
  .build()
```

### 4.3 Event Emitter with TypeScript

```typescript
type EventMap = {
  'user:created': { id: number; name: string }
  'user:updated': { id: number; changes: Partial<User> }
  'user:deleted': { id: number }
}

class TypedEventEmitter<T extends Record<string, any>> {
  private listeners: {
    [K in keyof T]?: Array<(data: T[K]) => void>
  } = {}

  on<K extends keyof T>(event: K, handler: (data: T[K]) => void): this {
    if (!this.listeners[event]) {
      this.listeners[event] = []
    }
    this.listeners[event]!.push(handler)
    return this
  }

  emit<K extends keyof T>(event: K, data: T[K]): this {
    const handlers = this.listeners[event]
    if (handlers) {
      handlers.forEach(handler => handler(data))
    }
    return this
  }

  off<K extends keyof T>(event: K, handler: (data: T[K]) => void): this {
    const handlers = this.listeners[event]
    if (handlers) {
      this.listeners[event] = handlers.filter(h => h !== handler) as any
    }
    return this
  }
}

// 사용
const emitter = new TypedEventEmitter<EventMap>()

emitter.on('user:created', (data) => {
  console.log(`User ${data.name} created with ID ${data.id}`)
  // data는 { id: number; name: string } 타입
})

emitter.emit('user:created', { id: 1, name: 'John' })
// 타입 안전성 확보
```

---

## 5. 성능 최적화

### 5.1 타입 최적화

```typescript
// ❌ 느린 타입 (재귀적 조건부 타입)
type SlowDeepPartial<T> = {
  [P in keyof T]?: T[P] extends object ? SlowDeepPartial<T[P]> : T[P]
}

// ✅ 빠른 타입 (깊이 제한)
type FastDeepPartial<T, Depth extends number = 5> = Depth extends 0
  ? T
  : {
      [P in keyof T]?: T[P] extends object
        ? FastDeepPartial<T[P], Prev[Depth]>
        : T[P]
    }

type Prev = [never, 0, 1, 2, 3, 4, 5, ...0[]]

// ❌ 복잡한 유니온
type BadUnion = string | number | boolean | null | undefined | ...100개

// ✅ 단순화된 타입
type GoodType = string | number | { custom: boolean }
```

### 5.2 Zod 성능 최적화

```typescript
import { z } from 'zod'

// ❌ 매번 새로운 스키마 생성
function validate(data: unknown) {
  const schema = z.object({
    name: z.string(),
    age: z.number(),
  })
  return schema.parse(data)
}

// ✅ 스키마 재사용
const userSchema = z.object({
  name: z.string(),
  age: z.number(),
})

function validate(data: unknown) {
  return userSchema.parse(data)
}

// ✅ Lazy parsing (큰 객체에 유용)
const lazySchema = z.lazy(() => z.object({
  // ...
}))
```

---

## 6. 테스팅

### 6.1 타입 테스트

```typescript
// 타입 체크 헬퍼
type Expect<T extends true> = T
type Equal<X, Y> = (<T>() => T extends X ? 1 : 2) extends <T>() => T extends Y
  ? 1
  : 2
  ? true
  : false

// 타입 테스트
type Test1 = Expect<Equal<ReturnType<typeof getUser>, Promise<User>>>
type Test2 = Expect<Equal<Parameters<typeof createUser>[0], UserInput>>

// ts-expect-error 사용
// @ts-expect-error - 이 코드는 타입 에러가 발생해야 함
const invalid: User = { id: 'string' }
```

### 6.2 Zod 스키마 테스트

```typescript
import { describe, it, expect } from 'vitest'
import { z } from 'zod'

const userSchema = z.object({
  name: z.string().min(1),
  age: z.number().min(18),
})

describe('userSchema', () => {
  it('should accept valid data', () => {
    const result = userSchema.safeParse({
      name: 'John',
      age: 25,
    })
    expect(result.success).toBe(true)
  })

  it('should reject invalid age', () => {
    const result = userSchema.safeParse({
      name: 'John',
      age: 15,
    })
    expect(result.success).toBe(false)
    if (!result.success) {
      expect(result.error.errors[0].path).toEqual(['age'])
    }
  })
})
```

---

## 체크리스트

### TypeScript
- [ ] Template Literal Types로 타입 안전한 문자열 조작
- [ ] Conditional Types로 유연한 타입 정의
- [ ] Mapped Types로 DRY 원칙 준수
- [ ] Discriminated Unions로 안전한 상태 관리
- [ ] Type Guards로 런타임 타입 검증
- [ ] Const Assertions로 불변 데이터 정의

### Zod
- [ ] 모든 외부 입력 검증 (API, Form, ENV)
- [ ] 타입 추론으로 중복 제거
- [ ] Transform으로 데이터 정규화
- [ ] Refinement로 복잡한 검증 로직
- [ ] 명확한 에러 메시지 제공

### Effect
- [ ] Effect 타입으로 부수효과 명시
- [ ] Error Channels로 타입 안전한 에러 처리
- [ ] Dependency Injection으로 테스트 가능성 향상
- [ ] Resource Management로 안전한 리소스 해제
- [ ] Concurrency 패턴 활용

### 성능
- [ ] 타입 복잡도 모니터링
- [ ] Zod 스키마 재사용
- [ ] 빌드 시간 측정 및 최적화

---

## 참고 자료
- [TypeScript 공식 문서](https://www.typescriptlang.org/docs/)
- [Zod 문서](https://zod.dev/)
- [Effect 문서](https://effect.website/)
- [TypeScript Deep Dive](https://basarat.gitbook.io/typescript/)
