# Modern Frontend Frameworks - 최신 프론트엔드 프레임워크 전문가

## 개요
React 19, Next.js 15, Svelte 5, Solid.js 등 최신 프론트엔드 프레임워크와 패턴을 활용한 고성능 웹 애플리케이션 개발 전문 스킬입니다.

## 핵심 역량

### 1. React 19 최신 기능
- **React Compiler** - 자동 메모이제이션
- **Server Components** - RSC 패턴
- **Actions** - 서버 액션과 폼 처리
- **use() Hook** - 비동기 데이터 처리
- **Suspense 개선** - 더 나은 로딩 상태

### 2. Next.js 15 App Router
- **Server Actions** - 타입 세이프 서버 함수
- **Parallel Routes** - 병렬 라우팅
- **Intercepting Routes** - 모달 라우팅
- **Server & Client Components** - 하이브리드 렌더링
- **Metadata API** - SEO 최적화

### 3. Svelte 5 (Runes API)
- **$state** - 반응형 상태
- **$derived** - 파생 상태
- **$effect** - 사이드 이펙트
- **Snippets** - 재사용 가능한 템플릿
- **Stores 개선** - 더 나은 상태 관리

### 4. Solid.js
- **Fine-grained Reactivity** - 세밀한 반응성
- **No Virtual DOM** - 직접 DOM 업데이트
- **Signals** - 반응형 프리미티브
- **JSX 템플릿** - React와 유사한 문법
- **SolidStart** - 풀스택 프레임워크

---

## 1. React 19 - 최신 기능 활용

### 1.1 React Compiler (자동 메모이제이션)

```javascript
// ❌ React 18 - 수동 메모이제이션 필요
import { useMemo, useCallback } from 'react'

function TodoList({ todos, filter }) {
  const filteredTodos = useMemo(
    () => todos.filter(todo => todo.status === filter),
    [todos, filter]
  )

  const handleToggle = useCallback((id) => {
    // toggle logic
  }, [])

  return (
    <ul>
      {filteredTodos.map(todo => (
        <TodoItem key={todo.id} todo={todo} onToggle={handleToggle} />
      ))}
    </ul>
  )
}

// ✅ React 19 - Compiler가 자동 최적화
function TodoList({ todos, filter }) {
  const filteredTodos = todos.filter(todo => todo.status === filter)

  const handleToggle = (id) => {
    // toggle logic
  }

  return (
    <ul>
      {filteredTodos.map(todo => (
        <TodoItem key={todo.id} todo={todo} onToggle={handleToggle} />
      ))}
    </ul>
  )
}
```

### 1.2 use() Hook - 비동기 데이터 처리

```typescript
// app/posts/[id]/page.tsx
import { use } from 'react'

async function getPost(id: string) {
  const res = await fetch(`https://api.example.com/posts/${id}`)
  return res.json()
}

export default function PostPage({ params }: { params: { id: string } }) {
  // ✅ use() Hook으로 비동기 데이터 처리
  const post = use(getPost(params.id))

  return (
    <article>
      <h1>{post.title}</h1>
      <p>{post.content}</p>
    </article>
  )
}
```

### 1.3 Server Actions - 폼 처리

```typescript
// app/actions.ts
'use server'

import { revalidatePath } from 'next/cache'

export async function createTodo(formData: FormData) {
  const title = formData.get('title') as string

  await db.todo.create({
    data: { title, completed: false }
  })

  revalidatePath('/todos')
}

// app/todos/page.tsx
import { createTodo } from './actions'

export default function TodosPage() {
  return (
    <form action={createTodo}>
      <input type="text" name="title" required />
      <button type="submit">Add Todo</button>
    </form>
  )
}
```

### 1.4 Suspense 개선 - 더 나은 로딩 상태

```typescript
// app/dashboard/page.tsx
import { Suspense } from 'react'

async function UserStats() {
  const stats = await fetchUserStats()
  return <div>Total: {stats.total}</div>
}

async function RecentActivity() {
  const activity = await fetchActivity()
  return <ul>{activity.map(a => <li key={a.id}>{a.title}</li>)}</ul>
}

export default function DashboardPage() {
  return (
    <div>
      {/* 각 컴포넌트가 독립적으로 로딩 */}
      <Suspense fallback={<StatsLoading />}>
        <UserStats />
      </Suspense>

      <Suspense fallback={<ActivityLoading />}>
        <RecentActivity />
      </Suspense>
    </div>
  )
}
```

---

## 2. Next.js 15 - App Router 고급 패턴

### 2.1 Parallel Routes - 병렬 라우팅

```
app/
├── @analytics/
│   └── page.tsx
├── @team/
│   └── page.tsx
└── layout.tsx
```

```typescript
// app/layout.tsx
export default function DashboardLayout({
  children,
  analytics,
  team,
}: {
  children: React.ReactNode
  analytics: React.ReactNode
  team: React.ReactNode
}) {
  return (
    <div>
      {children}
      <div className="grid grid-cols-2 gap-4">
        {analytics}
        {team}
      </div>
    </div>
  )
}
```

### 2.2 Intercepting Routes - 모달 라우팅

```
app/
├── photos/
│   ├── [id]/
│   │   └── page.tsx
│   └── page.tsx
└── @modal/
    └── (..)photos/
        └── [id]/
            └── page.tsx
```

```typescript
// app/@modal/(..)photos/[id]/page.tsx
import { Modal } from '@/components/modal'

export default function PhotoModal({ params }: { params: { id: string } }) {
  return (
    <Modal>
      <img src={`/photos/${params.id}.jpg`} alt="Photo" />
    </Modal>
  )
}

// app/photos/[id]/page.tsx
export default function PhotoPage({ params }: { params: { id: string } }) {
  // 직접 URL 접근 시 전체 페이지로 렌더링
  return (
    <div className="container">
      <img src={`/photos/${params.id}.jpg`} alt="Photo" />
    </div>
  )
}
```

### 2.3 Server & Client Components 최적화

```typescript
// components/server/user-profile.tsx (Server Component)
import { db } from '@/lib/db'
import { InteractiveButton } from './interactive-button'

export async function UserProfile({ userId }: { userId: string }) {
  // 서버에서만 실행 - DB 직접 접근
  const user = await db.user.findUnique({ where: { id: userId } })

  return (
    <div>
      <h2>{user.name}</h2>
      <p>{user.bio}</p>
      {/* Client Component는 필요한 부분만 */}
      <InteractiveButton userId={userId} />
    </div>
  )
}

// components/client/interactive-button.tsx (Client Component)
'use client'

import { useState } from 'react'

export function InteractiveButton({ userId }: { userId: string }) {
  const [liked, setLiked] = useState(false)

  return (
    <button onClick={() => setLiked(!liked)}>
      {liked ? '❤️' : '🤍'}
    </button>
  )
}
```

### 2.4 Dynamic Metadata Generation

```typescript
// app/blog/[slug]/page.tsx
import { Metadata } from 'next'

export async function generateMetadata({
  params
}: {
  params: { slug: string }
}): Promise<Metadata> {
  const post = await getPost(params.slug)

  return {
    title: post.title,
    description: post.excerpt,
    openGraph: {
      title: post.title,
      description: post.excerpt,
      type: 'article',
      publishedTime: post.publishedAt,
      authors: [post.author.name],
      images: [
        {
          url: post.coverImage,
          width: 1200,
          height: 630,
          alt: post.title,
        },
      ],
    },
    twitter: {
      card: 'summary_large_image',
      title: post.title,
      description: post.excerpt,
      images: [post.coverImage],
    },
  }
}
```

---

## 3. Svelte 5 - Runes API

### 3.1 $state - 반응형 상태

```svelte
<script>
  // ✅ Svelte 5 - $state rune
  let count = $state(0)
  let doubled = $derived(count * 2)

  function increment() {
    count++
  }
</script>

<button on:click={increment}>
  Count: {count} (Doubled: {doubled})
</button>
```

### 3.2 $effect - 사이드 이펙트

```svelte
<script>
  import { onMount } from 'svelte'

  let width = $state(0)

  // ✅ $effect - 반응형 사이드 이펙트
  $effect(() => {
    function handleResize() {
      width = window.innerWidth
    }

    window.addEventListener('resize', handleResize)
    handleResize()

    return () => {
      window.removeEventListener('resize', handleResize)
    }
  })
</script>

<p>Window width: {width}px</p>
```

### 3.3 Snippets - 재사용 가능한 템플릿

```svelte
<script>
  let items = $state([
    { id: 1, name: 'Item 1', price: 100 },
    { id: 2, name: 'Item 2', price: 200 },
  ])
</script>

{#snippet itemCard(item)}
  <div class="card">
    <h3>{item.name}</h3>
    <p>${item.price}</p>
  </div>
{/snippet}

<div class="grid">
  {#each items as item}
    {@render itemCard(item)}
  {/each}
</div>
```

### 3.4 Stores 개선

```typescript
// stores/counter.svelte.ts
import { writable } from 'svelte/store'

class Counter {
  count = $state(0)
  doubled = $derived(this.count * 2)

  increment() {
    this.count++
  }

  decrement() {
    this.count--
  }
}

export const counter = new Counter()
```

```svelte
<!-- routes/+page.svelte -->
<script>
  import { counter } from '$lib/stores/counter.svelte'
</script>

<button on:click={() => counter.increment()}>
  Count: {counter.count}
</button>
<p>Doubled: {counter.doubled}</p>
```

---

## 4. Solid.js - 세밀한 반응성

### 4.1 Signals - 반응형 프리미티브

```typescript
import { createSignal, createEffect } from 'solid-js'

function Counter() {
  const [count, setCount] = createSignal(0)
  const doubled = () => count() * 2

  createEffect(() => {
    console.log('Count changed:', count())
  })

  return (
    <div>
      <button onClick={() => setCount(count() + 1)}>
        Count: {count()}
      </button>
      <p>Doubled: {doubled()}</p>
    </div>
  )
}
```

### 4.2 createResource - 비동기 데이터

```typescript
import { createResource, Show, For } from 'solid-js'

async function fetchTodos() {
  const res = await fetch('https://api.example.com/todos')
  return res.json()
}

function TodoList() {
  const [todos] = createResource(fetchTodos)

  return (
    <Show
      when={!todos.loading}
      fallback={<p>Loading...</p>}
    >
      <ul>
        <For each={todos()}>
          {(todo) => <li>{todo.title}</li>}
        </For>
      </ul>
    </Show>
  )
}
```

### 4.3 Store - 중첩 객체 반응성

```typescript
import { createStore } from 'solid-js/store'

function TodoApp() {
  const [state, setState] = createStore({
    todos: [
      { id: 1, title: 'Learn Solid', completed: false },
      { id: 2, title: 'Build app', completed: false },
    ],
    filter: 'all',
  })

  const addTodo = (title: string) => {
    setState('todos', (todos) => [
      ...todos,
      { id: Date.now(), title, completed: false },
    ])
  }

  const toggleTodo = (id: number) => {
    setState(
      'todos',
      (todo) => todo.id === id,
      'completed',
      (completed) => !completed
    )
  }

  return (
    <div>
      <For each={state.todos}>
        {(todo) => (
          <div>
            <input
              type="checkbox"
              checked={todo.completed}
              onChange={() => toggleTodo(todo.id)}
            />
            <span>{todo.title}</span>
          </div>
        )}
      </For>
    </div>
  )
}
```

### 4.4 SolidStart - 풀스택 프레임워크

```typescript
// routes/api/posts.ts
import { json } from '@solidjs/router'
import { prisma } from '~/lib/prisma'

export async function GET() {
  const posts = await prisma.post.findMany()
  return json(posts)
}

export async function POST({ request }: { request: Request }) {
  const data = await request.json()
  const post = await prisma.post.create({ data })
  return json(post)
}

// routes/posts.tsx
import { createAsync } from '@solidjs/router'

async function getPosts() {
  const res = await fetch('/api/posts')
  return res.json()
}

export default function PostsPage() {
  const posts = createAsync(() => getPosts())

  return (
    <ul>
      <For each={posts()}>
        {(post) => <li>{post.title}</li>}
      </For>
    </ul>
  )
}
```

---

## 5. 프레임워크 선택 가이드

### 5.1 React 19 / Next.js 15를 선택하는 경우
- ✅ 대규모 팀 프로젝트
- ✅ 방대한 생태계와 라이브러리 필요
- ✅ SEO 최적화된 서버 사이드 렌더링
- ✅ Vercel 배포 및 엣지 컴퓨팅
- ✅ 기존 React 코드베이스 마이그레이션

### 5.2 Svelte 5를 선택하는 경우
- ✅ 번들 크기가 중요한 경우 (작은 번들)
- ✅ 초보자 친화적인 문법
- ✅ 빠른 프로토타이핑
- ✅ 간결한 코드 작성
- ✅ SvelteKit으로 풀스택 개발

### 5.3 Solid.js를 선택하는 경우
- ✅ 최고 수준의 성능 필요
- ✅ 세밀한 반응성 제어
- ✅ 작은 번들 크기 + 빠른 런타임
- ✅ React와 유사한 문법 선호
- ✅ 복잡한 상태 관리

---

## 6. 성능 최적화 패턴

### 6.1 React 19 - Transition API

```typescript
import { useTransition } from 'react'

function SearchPage() {
  const [isPending, startTransition] = useTransition()
  const [query, setQuery] = useState('')
  const [results, setResults] = useState([])

  function handleSearch(e: React.ChangeEvent<HTMLInputElement>) {
    const value = e.target.value
    setQuery(value)

    // ✅ 낮은 우선순위 업데이트로 표시
    startTransition(() => {
      const filtered = data.filter(item =>
        item.name.toLowerCase().includes(value.toLowerCase())
      )
      setResults(filtered)
    })
  }

  return (
    <div>
      <input value={query} onChange={handleSearch} />
      {isPending && <Spinner />}
      <ResultsList results={results} />
    </div>
  )
}
```

### 6.2 Next.js 15 - Streaming SSR

```typescript
// app/page.tsx
import { Suspense } from 'react'

async function SlowComponent() {
  await new Promise(resolve => setTimeout(resolve, 3000))
  return <div>Slow data loaded!</div>
}

export default function HomePage() {
  return (
    <div>
      <h1>Fast content here</h1>

      {/* ✅ 느린 컴포넌트를 스트리밍 */}
      <Suspense fallback={<div>Loading...</div>}>
        <SlowComponent />
      </Suspense>
    </div>
  )
}
```

### 6.3 Svelte 5 - Lazy Loading

```svelte
<script>
  import { onMount } from 'svelte'

  let HeavyComponent

  onMount(async () => {
    const module = await import('./HeavyComponent.svelte')
    HeavyComponent = module.default
  })
</script>

{#if HeavyComponent}
  <svelte:component this={HeavyComponent} />
{:else}
  <p>Loading...</p>
{/if}
```

---

## 7. TypeScript 통합

### 7.1 Next.js 15 타입 안전성

```typescript
// app/api/users/[id]/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'

const userSchema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
})

export async function PUT(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const body = await request.json()
    const validatedData = userSchema.parse(body)

    const user = await db.user.update({
      where: { id: params.id },
      data: validatedData,
    })

    return NextResponse.json(user)
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        { errors: error.errors },
        { status: 400 }
      )
    }
    throw error
  }
}
```

### 7.2 Svelte 5 타입 안전성

```svelte
<script lang="ts">
  interface User {
    id: number
    name: string
    email: string
  }

  let users = $state<User[]>([])

  async function fetchUsers() {
    const res = await fetch('/api/users')
    users = await res.json()
  }
</script>

{#each users as user}
  <div>{user.name} - {user.email}</div>
{/each}
```

### 7.3 Solid.js 타입 안전성

```typescript
import { Component, createSignal } from 'solid-js'

interface TodoProps {
  initialTodos: Todo[]
}

interface Todo {
  id: number
  title: string
  completed: boolean
}

const TodoList: Component<TodoProps> = (props) => {
  const [todos, setTodos] = createSignal<Todo[]>(props.initialTodos)

  return (
    <ul>
      <For each={todos()}>
        {(todo) => <li>{todo.title}</li>}
      </For>
    </ul>
  )
}
```

---

## 8. 테스팅 전략

### 8.1 React 19 - Testing Library

```typescript
import { render, screen, waitFor } from '@testing-library/react'
import { userEvent } from '@testing-library/user-event'
import { TodoList } from './TodoList'

describe('TodoList', () => {
  it('should add new todo', async () => {
    const user = userEvent.setup()
    render(<TodoList />)

    const input = screen.getByRole('textbox')
    const button = screen.getByRole('button', { name: /add/i })

    await user.type(input, 'New todo')
    await user.click(button)

    await waitFor(() => {
      expect(screen.getByText('New todo')).toBeInTheDocument()
    })
  })
})
```

### 8.2 Svelte 5 - Testing Library

```typescript
import { render, fireEvent } from '@testing-library/svelte'
import Counter from './Counter.svelte'

describe('Counter', () => {
  it('should increment count', async () => {
    const { getByRole, getByText } = render(Counter)

    const button = getByRole('button')
    await fireEvent.click(button)

    expect(getByText('Count: 1')).toBeInTheDocument()
  })
})
```

---

## 9. 배포 및 호스팅

### 9.1 Vercel (Next.js 최적화)
```bash
# vercel.json
{
  "framework": "nextjs",
  "buildCommand": "npm run build",
  "devCommand": "npm run dev",
  "installCommand": "npm install",
  "regions": ["icn1"],
  "env": {
    "DATABASE_URL": "@database-url"
  }
}
```

### 9.2 Cloudflare Pages (Svelte/Solid)
```bash
# wrangler.toml
name = "my-app"
pages_build_output_dir = "dist"

[build]
command = "npm run build"

[[rules]]
pattern = "/*"
element_selectors = []
```

---

## 10. 마이그레이션 전략

### 10.1 React 18 → React 19
```typescript
// Before: React 18
import { useMemo, useCallback } from 'react'

function Component({ data }) {
  const processed = useMemo(() => processData(data), [data])
  const handler = useCallback(() => handleClick(), [])

  return <div>{processed}</div>
}

// After: React 19 (Compiler 활성화)
function Component({ data }) {
  const processed = processData(data)  // 자동 메모이제이션
  const handler = () => handleClick()   // 자동 최적화

  return <div>{processed}</div>
}
```

### 10.2 Svelte 4 → Svelte 5
```svelte
<!-- Before: Svelte 4 -->
<script>
  let count = 0
  $: doubled = count * 2

  function increment() {
    count++
  }
</script>

<!-- After: Svelte 5 -->
<script>
  let count = $state(0)
  let doubled = $derived(count * 2)

  function increment() {
    count++
  }
</script>
```

---

## 체크리스트

### React 19 / Next.js 15
- [ ] React Compiler 활성화 및 최적화 확인
- [ ] Server Actions를 사용한 폼 처리
- [ ] Server & Client Components 최적 분리
- [ ] Parallel/Intercepting Routes 활용
- [ ] Metadata API로 SEO 최적화
- [ ] Suspense를 활용한 스트리밍 SSR

### Svelte 5
- [ ] $state, $derived, $effect 활용
- [ ] Snippets로 템플릿 재사용
- [ ] SvelteKit으로 풀스택 개발
- [ ] 번들 크기 최적화 확인

### Solid.js
- [ ] Signals로 세밀한 반응성 구현
- [ ] createResource로 비동기 데이터 처리
- [ ] Store로 복잡한 상태 관리
- [ ] SolidStart로 풀스택 개발

### 공통
- [ ] TypeScript 타입 안전성 확보
- [ ] 테스팅 커버리지 80% 이상
- [ ] 성능 모니터링 (Core Web Vitals)
- [ ] 배포 파이프라인 자동화

---

## 참고 자료
- [React 19 공식 문서](https://react.dev/blog/2024/12/05/react-19)
- [Next.js 15 문서](https://nextjs.org/docs)
- [Svelte 5 문서](https://svelte.dev/docs/svelte/overview)
- [Solid.js 문서](https://www.solidjs.com/)
- [Vercel 배포 가이드](https://vercel.com/docs)
