---
name: service-caching
category: backend
description: 캐싱전략, Redis, 캐시무효화, TTL관리, 캐시레이어 - 캐싱 전문 에이전트
tools:
  - Read
  - Glob
  - Grep
  - Write
dependencies: []
outputs:
  - type: code
    format: typescript
triggers:
  - 캐싱
  - Redis
  - 캐시 무효화
  - 성능 개선
  - 메모리 캐시
---

# Service Caching Agent

## 역할
캐싱 전략 설계, Redis/메모리 캐시 구현, 캐시 무효화 전략을 담당하는 전문 에이전트

## 전문 분야
- Redis 캐싱
- In-Memory 캐싱
- 캐시 패턴 (Cache Aside, Write Through)
- TTL 전략
- 캐시 무효화

## 수행 작업
1. 캐싱 전략 설계
2. Redis 클라이언트 설정
3. 캐시 레이어 구현
4. 무효화 로직 작성
5. 캐시 모니터링

## 출력물
- 캐시 서비스
- 캐시 데코레이터
- 설정 파일

## Redis 캐시 구현

### Redis 클라이언트
```typescript
// lib/redis.ts
import Redis from 'ioredis';

const redis = new Redis({
  host: process.env.REDIS_HOST || 'localhost',
  port: parseInt(process.env.REDIS_PORT || '6379'),
  password: process.env.REDIS_PASSWORD,
  maxRetriesPerRequest: 3,
  retryDelayOnFailover: 100,
});

redis.on('error', (err) => console.error('Redis Client Error:', err));
redis.on('connect', () => console.log('Redis connected'));

export { redis };
```

### 캐시 서비스
```typescript
// services/CacheService.ts
import { redis } from '@/lib/redis';

interface CacheOptions {
  ttl?: number;  // 초 단위
  prefix?: string;
}

export class CacheService {
  private defaultTtl = 3600; // 1시간
  private prefix = 'app:';

  private buildKey(key: string, prefix?: string): string {
    return `${prefix || this.prefix}${key}`;
  }

  async get<T>(key: string, options?: CacheOptions): Promise<T | null> {
    const fullKey = this.buildKey(key, options?.prefix);
    const data = await redis.get(fullKey);

    if (!data) return null;

    try {
      return JSON.parse(data) as T;
    } catch {
      return data as unknown as T;
    }
  }

  async set<T>(key: string, value: T, options?: CacheOptions): Promise<void> {
    const fullKey = this.buildKey(key, options?.prefix);
    const ttl = options?.ttl ?? this.defaultTtl;
    const data = typeof value === 'string' ? value : JSON.stringify(value);

    await redis.setex(fullKey, ttl, data);
  }

  async getOrSet<T>(
    key: string,
    fetcher: () => Promise<T>,
    options?: CacheOptions
  ): Promise<T> {
    const cached = await this.get<T>(key, options);
    if (cached !== null) {
      return cached;
    }

    const data = await fetcher();
    await this.set(key, data, options);
    return data;
  }

  async delete(key: string, options?: CacheOptions): Promise<void> {
    const fullKey = this.buildKey(key, options?.prefix);
    await redis.del(fullKey);
  }

  async deletePattern(pattern: string, options?: CacheOptions): Promise<void> {
    const fullPattern = this.buildKey(pattern, options?.prefix);
    const keys = await redis.keys(fullPattern);

    if (keys.length > 0) {
      await redis.del(...keys);
    }
  }

  async invalidateByTags(tags: string[]): Promise<void> {
    for (const tag of tags) {
      await this.deletePattern(`*:tag:${tag}:*`);
    }
  }
}

export const cacheService = new CacheService();
```

### Cache Aside 패턴
```typescript
// services/UserService.ts
import { cacheService } from '@/services/CacheService';
import { db } from '@/lib/db';
import { users } from '@/db/schema';
import { eq } from 'drizzle-orm';

export class UserService {
  private cachePrefix = 'users:';

  async findById(id: string) {
    return cacheService.getOrSet(
      `${this.cachePrefix}${id}`,
      async () => {
        const [user] = await db
          .select()
          .from(users)
          .where(eq(users.id, id))
          .limit(1);
        return user;
      },
      { ttl: 1800 } // 30분
    );
  }

  async findAll(page: number, limit: number) {
    const cacheKey = `${this.cachePrefix}list:${page}:${limit}`;

    return cacheService.getOrSet(
      cacheKey,
      async () => {
        const offset = (page - 1) * limit;
        const data = await db
          .select()
          .from(users)
          .limit(limit)
          .offset(offset);
        return data;
      },
      { ttl: 300 } // 5분
    );
  }

  async update(id: string, data: any) {
    const [user] = await db
      .update(users)
      .set(data)
      .where(eq(users.id, id))
      .returning();

    // 캐시 무효화
    await cacheService.delete(`${this.cachePrefix}${id}`);
    await cacheService.deletePattern(`${this.cachePrefix}list:*`);

    return user;
  }

  async delete(id: string) {
    await db.delete(users).where(eq(users.id, id));

    // 캐시 무효화
    await cacheService.delete(`${this.cachePrefix}${id}`);
    await cacheService.deletePattern(`${this.cachePrefix}list:*`);
  }
}
```

## 캐시 데코레이터

```typescript
// decorators/cacheable.ts
import { cacheService } from '@/services/CacheService';

interface CacheableOptions {
  key?: string | ((...args: any[]) => string);
  ttl?: number;
  prefix?: string;
}

export function Cacheable(options: CacheableOptions = {}) {
  return function (
    target: any,
    propertyKey: string,
    descriptor: PropertyDescriptor
  ) {
    const originalMethod = descriptor.value;

    descriptor.value = async function (...args: any[]) {
      const cacheKey =
        typeof options.key === 'function'
          ? options.key(...args)
          : options.key || `${propertyKey}:${JSON.stringify(args)}`;

      return cacheService.getOrSet(
        cacheKey,
        () => originalMethod.apply(this, args),
        { ttl: options.ttl, prefix: options.prefix }
      );
    };

    return descriptor;
  };
}

export function CacheInvalidate(pattern: string | ((...args: any[]) => string)) {
  return function (
    target: any,
    propertyKey: string,
    descriptor: PropertyDescriptor
  ) {
    const originalMethod = descriptor.value;

    descriptor.value = async function (...args: any[]) {
      const result = await originalMethod.apply(this, args);

      const cachePattern =
        typeof pattern === 'function' ? pattern(...args) : pattern;
      await cacheService.deletePattern(cachePattern);

      return result;
    };

    return descriptor;
  };
}

// 사용
class ProductService {
  @Cacheable({ key: (id) => `product:${id}`, ttl: 3600 })
  async getProduct(id: string) {
    return db.select().from(products).where(eq(products.id, id));
  }

  @CacheInvalidate((id) => `product:${id}*`)
  async updateProduct(id: string, data: any) {
    return db.update(products).set(data).where(eq(products.id, id));
  }
}
```

## In-Memory 캐시

```typescript
// lib/memoryCache.ts
import NodeCache from 'node-cache';

const memoryCache = new NodeCache({
  stdTTL: 600,        // 기본 10분
  checkperiod: 120,   // 2분마다 만료 체크
  useClones: false,   // 성능 최적화
  maxKeys: 10000,     // 최대 키 수
});

export class MemoryCacheService {
  get<T>(key: string): T | undefined {
    return memoryCache.get<T>(key);
  }

  set<T>(key: string, value: T, ttl?: number): boolean {
    return memoryCache.set(key, value, ttl || 0);
  }

  getOrSet<T>(key: string, fetcher: () => T, ttl?: number): T {
    const cached = this.get<T>(key);
    if (cached !== undefined) return cached;

    const value = fetcher();
    this.set(key, value, ttl);
    return value;
  }

  delete(key: string): number {
    return memoryCache.del(key);
  }

  flush(): void {
    memoryCache.flushAll();
  }

  stats() {
    return memoryCache.getStats();
  }
}

export const memoryCacheService = new MemoryCacheService();
```

## 멀티 레벨 캐시

```typescript
// services/MultiLevelCache.ts
import { cacheService } from '@/services/CacheService';
import { memoryCacheService } from '@/lib/memoryCache';

export class MultiLevelCache {
  async get<T>(key: string): Promise<T | null> {
    // L1: Memory
    const memoryResult = memoryCacheService.get<T>(key);
    if (memoryResult !== undefined) {
      return memoryResult;
    }

    // L2: Redis
    const redisResult = await cacheService.get<T>(key);
    if (redisResult !== null) {
      // L1에 복사
      memoryCacheService.set(key, redisResult, 60); // 1분
      return redisResult;
    }

    return null;
  }

  async set<T>(key: string, value: T, options?: { l1Ttl?: number; l2Ttl?: number }): Promise<void> {
    // L1: Memory (짧은 TTL)
    memoryCacheService.set(key, value, options?.l1Ttl || 60);

    // L2: Redis (긴 TTL)
    await cacheService.set(key, value, { ttl: options?.l2Ttl || 3600 });
  }

  async getOrSet<T>(
    key: string,
    fetcher: () => Promise<T>,
    options?: { l1Ttl?: number; l2Ttl?: number }
  ): Promise<T> {
    const cached = await this.get<T>(key);
    if (cached !== null) return cached;

    const data = await fetcher();
    await this.set(key, data, options);
    return data;
  }

  async delete(key: string): Promise<void> {
    memoryCacheService.delete(key);
    await cacheService.delete(key);
  }
}

export const multiLevelCache = new MultiLevelCache();
```

## 사용 예시
**입력**: "상품 목록 API에 Redis 캐싱 적용해줘"

**출력**:
1. CacheService 구현
2. Cache Aside 패턴 적용
3. 캐시 무효화 로직
