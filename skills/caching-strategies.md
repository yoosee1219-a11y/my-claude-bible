# Caching Strategies

> Redis, CDN, Browser Cache로 응답 속도 10배 향상 완벽 가이드 (2026)

## 목차

1. [캐싱이 왜 중요한가?](#캐싱이-왜-중요한가)
2. [캐싱 패턴](#캐싱-패턴)
3. [Redis 캐싱](#redis-캐싱)
4. [CDN 캐싱](#cdn-캐싱)
5. [Browser 캐싱](#browser-캐싱)
6. [Cache Invalidation](#cache-invalidation)
7. [실전 사례](#실전-사례)

---

## 캐싱이 왜 중요한가?

### 캐싱 없는 시스템의 문제

**Before**
```
API 요청 → DB 쿼리 (500ms) → 응답

문제:
- 응답 시간: 500ms
- DB 부하: 100 req/sec = 100 쿼리/sec
- 비용: DB 인스턴스 업그레이드 필요
```

**After (Redis 캐시)**
```
API 요청 → Redis (5ms) → 응답

결과:
✅ 응답 시간: 500ms → 5ms (100배 빠름)
✅ DB 부하: 100 쿼리/sec → 10 쿼리/sec (90% 감소)
✅ 비용: DB 다운그레이드 가능
```

---

### 캐싱 레이어

```
┌─────────────┐
│  Browser    │  30초-1년 캐싱 (정적 자산)
└─────────────┘
      ↓
┌─────────────┐
│     CDN     │  1분-1일 캐싱 (HTML, API)
└─────────────┘
      ↓
┌─────────────┐
│   Redis     │  1분-1시간 캐싱 (DB 쿼리)
└─────────────┘
      ↓
┌─────────────┐
│  Database   │  원본 데이터
└─────────────┘
```

---

## 캐싱 패턴

### 1. Cache-Aside (Lazy Loading)

**가장 인기 있는 패턴**

```typescript
// Next.js API Route
import { redis } from '@/lib/redis';

export async function GET(req: Request) {
  const userId = new URL(req.url).searchParams.get('id');
  const cacheKey = `user:${userId}`;

  // 1. 캐시 확인
  const cached = await redis.get(cacheKey);
  if (cached) {
    return Response.json(JSON.parse(cached));
  }

  // 2. 캐시 미스: DB 조회
  const user = await prisma.user.findUnique({
    where: { id: userId },
  });

  // 3. 캐시에 저장 (1시간)
  await redis.setex(cacheKey, 3600, JSON.stringify(user));

  return Response.json(user);
}
```

**장점:**
- 간단한 구현
- 실제 요청된 데이터만 캐싱 (효율적)
- Redis 장애 시 DB로 폴백

**단점:**
- 첫 요청은 느림 (캐시 미스)
- 캐시 워밍업 필요

---

### 2. Write-Through

**DB 업데이트 시 캐시도 동시 업데이트**

```typescript
export async function PUT(req: Request) {
  const { id, name, email } = await req.json();

  // 1. DB 업데이트
  const user = await prisma.user.update({
    where: { id },
    data: { name, email },
  });

  // 2. 캐시 즉시 업데이트
  await redis.setex(
    `user:${id}`,
    3600,
    JSON.stringify(user)
  );

  return Response.json(user);
}
```

**장점:**
- 캐시 항상 최신
- 읽기 성능 보장

**단점:**
- 쓰기 성능 저하 (2번 쓰기)

---

### 3. Write-Behind (Write-Back)

**캐시만 업데이트, DB는 비동기**

```typescript
export async function PUT(req: Request) {
  const { id, name, email } = await req.json();

  // 1. 캐시만 즉시 업데이트
  const user = { id, name, email, updatedAt: new Date() };
  await redis.setex(`user:${id}`, 3600, JSON.stringify(user));

  // 2. DB는 백그라운드 큐로
  await queue.add('update-user', { id, name, email });

  return Response.json(user);
}
```

**장점:**
- 쓰기 성능 극대화

**단점:**
- 데이터 손실 위험 (Redis 장애 시)

---

### 4. Read-Through

**애플리케이션은 캐시와만 통신**

```typescript
// lib/cache.ts
export class CacheService {
  async get(key: string) {
    // 캐시 확인
    const cached = await redis.get(key);
    if (cached) return JSON.parse(cached);

    // 미스: DB 조회 (내부 처리)
    const data = await this.loadFromDB(key);

    // 캐시 저장
    await redis.setex(key, 3600, JSON.stringify(data));

    return data;
  }

  private async loadFromDB(key: string) {
    // DB 로직 (캐시가 내부적으로 처리)
    // ...
  }
}
```

---

## Redis 캐싱

### 설치 (Upstash Redis)

```bash
npm install @upstash/redis
```

**Vercel 호환 ✅**

---

### 기본 사용

**lib/redis.ts:**
```typescript
import { Redis } from '@upstash/redis';

export const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL!,
  token: process.env.UPSTASH_REDIS_REST_TOKEN!,
});
```

---

### 캐싱 예시

**1. 문자열 캐싱**
```typescript
// 저장 (1시간)
await redis.setex('user:123', 3600, JSON.stringify(user));

// 조회
const cached = await redis.get('user:123');
if (cached) {
  const user = JSON.parse(cached);
}

// 삭제
await redis.del('user:123');
```

---

**2. 해시 캐싱 (객체)**
```typescript
// 저장
await redis.hset('user:123', {
  name: 'John',
  email: 'john@example.com',
  age: 30,
});

// 조회
const user = await redis.hgetall('user:123');

// 특정 필드만
const name = await redis.hget('user:123', 'name');

// 삭제
await redis.hdel('user:123', 'age');
```

---

**3. 리스트 캐싱**
```typescript
// 최근 검색어 (최대 5개)
await redis.lpush('search:user:123', 'Next.js');
await redis.ltrim('search:user:123', 0, 4);

// 조회
const recentSearches = await redis.lrange('search:user:123', 0, 4);
```

---

**4. 세트 캐싱**
```typescript
// 온라인 사용자
await redis.sadd('online-users', 'user:123');

// 확인
const isOnline = await redis.sismember('online-users', 'user:123');

// 전체 조회
const onlineUsers = await redis.smembers('online-users');

// 제거
await redis.srem('online-users', 'user:123');
```

---

### Cache Stampede 방지

**문제:** 캐시 만료 시 동시 다수 요청이 DB 공격

```typescript
// lib/cache-with-lock.ts
export async function getCachedWithLock<T>(
  key: string,
  loader: () => Promise<T>,
  ttl: number = 3600
): Promise<T> {
  // 1. 캐시 확인
  const cached = await redis.get(key);
  if (cached) {
    return JSON.parse(cached as string);
  }

  // 2. 락 획득 시도 (10초)
  const lockKey = `lock:${key}`;
  const lockAcquired = await redis.set(lockKey, '1', {
    ex: 10,
    nx: true,
  });

  if (lockAcquired) {
    try {
      // 3. 데이터 로드
      const data = await loader();

      // 4. 캐시 저장
      await redis.setex(key, ttl, JSON.stringify(data));

      return data;
    } finally {
      // 5. 락 해제
      await redis.del(lockKey);
    }
  } else {
    // 6. 락 대기 (다른 스레드가 로딩 중)
    await new Promise(resolve => setTimeout(resolve, 100));

    // 7. 재시도
    return getCachedWithLock(key, loader, ttl);
  }
}

// 사용
const user = await getCachedWithLock(
  'user:123',
  () => prisma.user.findUnique({ where: { id: '123' } }),
  3600
);
```

---

### Eviction 정책

**Redis 메모리가 가득 찼을 때:**

```bash
# redis.conf
maxmemory 256mb
maxmemory-policy allkeys-lru
```

**정책:**
- `allkeys-lru`: 가장 오래 사용 안 된 키 제거 (추천)
- `allkeys-lfu`: 가장 적게 사용된 키 제거
- `volatile-ttl`: 만료 시간 가장 짧은 키 제거
- `noeviction`: 메모리 가득 시 에러

---

## CDN 캐싱

### Vercel CDN

**자동 캐싱:**
```typescript
// app/api/posts/route.ts
export const runtime = 'edge';

export async function GET() {
  const posts = await prisma.post.findMany({ take: 10 });

  return Response.json(posts, {
    headers: {
      // CDN에서 60초 캐싱
      'Cache-Control': 's-maxage=60, stale-while-revalidate=300',
    },
  });
}
```

**헤더 설명:**
- `s-maxage=60`: CDN에서 60초 캐싱 (fresh)
- `stale-while-revalidate=300`: 만료 후 300초 동안 stale 제공하며 백그라운드 갱신

---

### Cloudflare CDN

**Next.js + Cloudflare:**
```typescript
// middleware.ts
import { NextResponse } from 'next/server';

export function middleware(req: Request) {
  const res = NextResponse.next();

  // 정적 자산: 1년 캐싱
  if (req.url.includes('/images/') || req.url.includes('/fonts/')) {
    res.headers.set('Cache-Control', 'public, max-age=31536000, immutable');
  }

  // API: 1분 캐싱
  if (req.url.includes('/api/')) {
    res.headers.set('Cache-Control', 's-maxage=60, stale-while-revalidate=300');
  }

  return res;
}
```

---

### Tiered Caching (Cloudflare Enterprise)

```
사용자 요청
  ↓
[Edge Cache (로컬)] → MISS
  ↓
[Regional Cache (Super)] → MISS
  ↓
[Origin Server]

Hit Rate: 95%+ (일반 CDN 80% vs)
```

---

## Browser 캐싱

### Cache-Control 헤더

```typescript
// Next.js Static Assets
export default function page() {
  return (
    <div>
      <img src="/images/logo.png" alt="Logo" />
      {/* public/images/logo.png
          자동으로 다음 헤더 추가:
          Cache-Control: public, max-age=31536000, immutable
      */}
    </div>
  );
}
```

---

### 동적 콘텐츠 캐싱

```typescript
// app/blog/[slug]/page.tsx
export const revalidate = 3600; // 1시간 ISR

export default async function BlogPost({ params }: { params: { slug: string } }) {
  const post = await prisma.post.findUnique({
    where: { slug: params.slug },
  });

  return <article>{post.content}</article>;
}

// 생성되는 헤더:
// Cache-Control: s-maxage=3600, stale-while-revalidate
```

---

### Service Worker 캐싱

```javascript
// public/sw.js
self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request).then((response) => {
      // 캐시 먼저 확인
      if (response) {
        return response;
      }

      // 네트워크 요청
      return fetch(event.request).then((response) => {
        // 성공 시 캐시에 저장
        if (response.status === 200) {
          const responseClone = response.clone();
          caches.open('v1').then((cache) => {
            cache.put(event.request, responseClone);
          });
        }
        return response;
      });
    })
  );
});
```

---

## Cache Invalidation

### "세상에서 가장 어려운 두 가지"
> 1. Cache invalidation
> 2. Naming things

---

### 1. TTL (Time-To-Live)

**간단하지만 정확도 낮음**

```typescript
// 1시간 후 자동 만료
await redis.setex('user:123', 3600, JSON.stringify(user));
```

**선택 기준:**
- 블로그 포스트: 5-60분
- 제품 정보: 10-30분
- 재고 수량: 1-10초
- 사용자 프로필: 30분-1시간

---

### 2. Stale-While-Revalidate

**최고의 UX: 즉시 응답 + 백그라운드 갱신**

```typescript
export async function GET() {
  const posts = await prisma.post.findMany();

  return Response.json(posts, {
    headers: {
      'Cache-Control': 's-maxage=60, stale-while-revalidate=300',
    },
  });
}

// 동작:
// 0-60초: Fresh 캐시 제공
// 61-360초: Stale 캐시 제공하며 백그라운드 갱신
// 361초+: 캐시 무시, 원본 요청
```

**결과:**
- P95 지연: 200-500ms (CDN)
- 사용자는 항상 즉시 응답 받음

---

### 3. Tag-Based Invalidation (Next.js 15)

```typescript
// app/api/posts/route.ts
import { unstable_cache } from 'next/cache';

export async function GET() {
  const posts = await unstable_cache(
    async () => prisma.post.findMany(),
    ['posts'],
    {
      tags: ['posts'],
      revalidate: 3600,
    }
  )();

  return Response.json(posts);
}

// app/api/posts/create/route.ts
import { revalidateTag } from 'next/cache';

export async function POST(req: Request) {
  const post = await prisma.post.create({
    data: await req.json(),
  });

  // 'posts' 태그 캐시 무효화
  revalidateTag('posts');

  return Response.json(post);
}
```

---

### 4. Event-Driven Invalidation

**Redis Pub/Sub:**

```typescript
// lib/cache-events.ts
import { redis } from './redis';

export async function invalidateCache(pattern: string) {
  // Pub/Sub으로 모든 인스턴스에 알림
  await redis.publish('cache-invalidation', pattern);

  // 로컬 캐시 무효화
  const keys = await redis.keys(pattern);
  if (keys.length > 0) {
    await redis.del(...keys);
  }
}

// 구독 (server.js)
const subscriber = redis.duplicate();
await subscriber.subscribe('cache-invalidation', (message) => {
  console.log('Invalidating cache:', message);
  // 로컬 메모리 캐시 무효화 등
});

// 사용
await invalidateCache('user:*');
```

---

## 실전 사례

### 사례: E커머스 API 캐싱 전략

**Before**
```
- 응답 시간: 800ms (DB 쿼리)
- DB 부하: 500 req/sec
- 서버 비용: $300/월
```

---

**캐싱 전략:**

**1. 제품 목록 (Redis + CDN)**
```typescript
// app/api/products/route.ts
export async function GET() {
  const cacheKey = 'products:list';

  // Redis 캐시 확인
  const cached = await redis.get(cacheKey);
  if (cached) {
    return Response.json(JSON.parse(cached as string), {
      headers: {
        'X-Cache': 'HIT',
        'Cache-Control': 's-maxage=300, stale-while-revalidate=600',
      },
    });
  }

  // DB 조회
  const products = await prisma.product.findMany({
    take: 50,
    orderBy: { createdAt: 'desc' },
  });

  // Redis에 5분 캐싱
  await redis.setex(cacheKey, 300, JSON.stringify(products));

  return Response.json(products, {
    headers: {
      'X-Cache': 'MISS',
      'Cache-Control': 's-maxage=300, stale-while-revalidate=600',
    },
  });
}
```

---

**2. 제품 상세 (Redis Only)**
```typescript
// app/api/products/[id]/route.ts
export async function GET(req: Request, { params }: { params: { id: string } }) {
  const cacheKey = `product:${params.id}`;

  const cached = await redis.get(cacheKey);
  if (cached) {
    return Response.json(JSON.parse(cached as string));
  }

  const product = await prisma.product.findUnique({
    where: { id: params.id },
    include: {
      reviews: { take: 10, orderBy: { createdAt: 'desc' } },
      category: true,
    },
  });

  // 1시간 캐싱
  await redis.setex(cacheKey, 3600, JSON.stringify(product));

  return Response.json(product);
}
```

---

**3. 재고 수량 (짧은 TTL + SWR)**
```typescript
// app/api/inventory/[id]/route.ts
export async function GET(req: Request, { params }: { params: { id: string } }) {
  const cacheKey = `inventory:${params.id}`;

  const cached = await redis.get(cacheKey);
  if (cached) {
    return Response.json(JSON.parse(cached as string), {
      headers: {
        // 10초 fresh, 30초 stale
        'Cache-Control': 's-maxage=10, stale-while-revalidate=30',
      },
    });
  }

  const inventory = await prisma.inventory.findUnique({
    where: { productId: params.id },
  });

  // 10초 캐싱
  await redis.setex(cacheKey, 10, JSON.stringify(inventory));

  return Response.json(inventory);
}
```

---

**4. 캐시 무효화 (주문 시)**
```typescript
// app/api/orders/route.ts
export async function POST(req: Request) {
  const { productId, quantity } = await req.json();

  // 주문 생성
  const order = await prisma.order.create({
    data: { productId, quantity },
  });

  // 재고 업데이트
  await prisma.inventory.update({
    where: { productId },
    data: { quantity: { decrement: quantity } },
  });

  // 캐시 무효화
  await redis.del(`inventory:${productId}`);
  await redis.del(`product:${productId}`);
  await redis.del('products:list');

  return Response.json(order);
}
```

---

**After**
```
✅ 응답 시간: 800ms → 15ms (98% 빠름)
✅ DB 부하: 500 req/sec → 25 req/sec (95% 감소)
✅ 캐시 히트율: 95%
✅ 서버 비용: $300/월 → $120/월 (60% 절감)
```

**ROI:** 연간 $2,160 비용 절감 + 사용자 경험 대폭 개선

---

## 체크리스트

### Redis 캐싱
- [ ] Upstash Redis 설정
- [ ] 캐싱 패턴 선택 (Cache-Aside 추천)
- [ ] TTL 설정 (데이터 특성에 맞게)
- [ ] Cache Stampede 방지
- [ ] Eviction 정책 (LRU 추천)

### CDN 캐싱
- [ ] Cache-Control 헤더 설정
- [ ] s-maxage vs max-age 구분
- [ ] Stale-While-Revalidate 활용
- [ ] 정적 자산: immutable 설정
- [ ] Cloudflare 또는 Vercel CDN

### Browser 캐싱
- [ ] 정적 자산: 1년 캐싱
- [ ] 동적 콘텐츠: 적절한 TTL
- [ ] ETag 활용
- [ ] Service Worker (PWA)

### Cache Invalidation
- [ ] TTL 설정
- [ ] Tag-based 무효화 (Next.js)
- [ ] Event-driven 무효화 (Pub/Sub)
- [ ] 명시적 무효화 (업데이트 시)

### 모니터링
- [ ] 캐시 히트율 추적 (목표: 80%+)
- [ ] 응답 시간 측정
- [ ] X-Cache 헤더 로깅
- [ ] Redis 메모리 사용률

---

## 참고 자료

- [Redis Caching Patterns (AWS)](https://docs.aws.amazon.com/whitepapers/latest/database-caching-strategies-using-redis/caching-patterns.html)
- [Vercel CDN Cache](https://vercel.com/docs/cdn-cache)
- [Cache-Control Header (MDN)](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control)
- [Stale-While-Revalidate Guide](https://www.debugbear.com/docs/stale-while-revalidate)
- [Redis Solutions: Caching](https://redis.io/solutions/caching/)

---

**적절한 캐싱 전략으로 응답 속도를 10배 향상하세요! ⚡**
