# Database Optimization

> 쿼리 성능 10배 향상: 인덱싱, 쿼리 최적화, N+1 문제 해결 완전 가이드 (2026)

## 목차

1. [DB 성능 문제가 왜 발생하나?](#db-성능-문제가-왜-발생하나)
2. [인덱싱 전략](#인덱싱-전략)
3. [쿼리 최적화](#쿼리-최적화)
4. [N+1 문제 해결](#n1-문제-해결)
5. [실전 사례](#실전-사례)

---

## DB 성능 문제가 왜 발생하나?

### 인덱스 없는 쿼리

```sql
-- ❌ 나쁜 예: Full Table Scan
SELECT * FROM users WHERE email = 'user@example.com';
-- 실행 시간: 1,000,000 rows → 5초

-- ✅ 좋은 예: Index Scan
CREATE INDEX idx_users_email ON users(email);
-- 실행 시간: 10ms (500배 빠름)
```

### N+1 문제

```javascript
// ❌ 나쁜 예: N+1 쿼리
const users = await User.findAll();  // 1 쿼리
for (const user of users) {
  user.orders = await Order.findAll({ where: { userId: user.id } });  // N 쿼리
}
// 총: 1 + 100 = 101 쿼리 (5초)

// ✅ 좋은 예: JOIN
const users = await User.findAll({
  include: [{ model: Order }]
});
// 총: 1 쿼리 (50ms)
```

---

## 인덱싱 전략

### 1. Single Column Index

```sql
-- WHERE 절에 자주 사용되는 컬럼
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_posts_created_at ON posts(created_at);
```

### 2. Composite Index (복합 인덱스)

```sql
-- 여러 컬럼을 함께 검색할 때
CREATE INDEX idx_orders_user_created ON orders(user_id, created_at DESC);

-- ✅ 이 인덱스를 사용하는 쿼리
SELECT * FROM orders WHERE user_id = 123 ORDER BY created_at DESC;

-- ❌ 사용 안 됨 (컬럼 순서 중요!)
SELECT * FROM orders WHERE created_at > '2024-01-01';
```

**컬럼 순서 원칙:**
1. WHERE 절의 = 조건 컬럼 먼저
2. WHERE 절의 범위 조건 (>, <) 다음
3. ORDER BY 컬럼 마지막

### 3. Covering Index

```sql
-- 쿼리에 필요한 모든 컬럼을 인덱스에 포함
CREATE INDEX idx_users_email_name ON users(email, name, created_at);

-- ✅ 테이블 접근 없이 인덱스만으로 응답 가능
SELECT name, created_at FROM users WHERE email = 'user@example.com';
```

### 4. Partial Index (조건부 인덱스)

```sql
-- PostgreSQL
CREATE INDEX idx_active_users ON users(email) WHERE active = true;

-- 활성 사용자만 인덱싱 → 인덱스 크기 50% 감소
```

---

## 쿼리 최적화

### 1. SELECT * 피하기

```sql
-- ❌ 나쁜 예
SELECT * FROM users;
-- 불필요한 50개 컬럼 전송 → 네트워크 낭비

-- ✅ 좋은 예
SELECT id, email, name FROM users;
-- 필요한 3개 컬럼만
```

### 2. LIMIT 사용

```sql
-- ❌ 나쁜 예
SELECT * FROM posts ORDER BY created_at DESC;
-- 100만 개 정렬 → 5초

-- ✅ 좋은 예
SELECT * FROM posts ORDER BY created_at DESC LIMIT 10;
-- 10개만 → 10ms
```

### 3. EXISTS vs COUNT

```sql
-- ❌ 느린 예
SELECT COUNT(*) FROM orders WHERE user_id = 123;
-- 모든 주문 카운트

-- ✅ 빠른 예 (존재 여부만 확인 시)
SELECT EXISTS(SELECT 1 FROM orders WHERE user_id = 123);
-- 첫 번째 발견 시 즉시 종료
```

### 4. EXPLAIN ANALYZE 사용

```sql
EXPLAIN ANALYZE
SELECT * FROM users WHERE email = 'user@example.com';

-- 결과:
-- Index Scan using idx_users_email on users  (cost=0.42..8.44 rows=1)
--   Index Cond: (email = 'user@example.com')
-- Planning Time: 0.123 ms
-- Execution Time: 0.045 ms
```

**체크 포인트:**
- Seq Scan (Full Table Scan) → Index 추가 필요
- cost 높음 → 쿼리 개선 필요
- rows 예측 vs 실제 차이 크면 → 통계 업데이트 (`ANALYZE`)

---

## N+1 문제 해결

### Prisma (Next.js)

```typescript
// ❌ N+1 문제
const users = await prisma.user.findMany();
for (const user of users) {
  user.posts = await prisma.post.findMany({ where: { authorId: user.id } });
}

// ✅ include로 해결
const users = await prisma.user.findMany({
  include: {
    posts: true,
  },
});

// ✅ select로 필요한 컬럼만
const users = await prisma.user.findMany({
  select: {
    id: true,
    email: true,
    posts: {
      select: {
        id: true,
        title: true,
      },
    },
  },
});
```

### Sequelize (Node.js)

```javascript
// ✅ Eager Loading
const users = await User.findAll({
  include: [
    {
      model: Post,
      as: 'posts',
      include: [{ model: Comment, as: 'comments' }],
    },
  ],
});
```

### Django ORM

```python
# ✅ select_related (1:1, N:1)
users = User.objects.select_related('profile').all()

# ✅ prefetch_related (1:N, M:N)
users = User.objects.prefetch_related('posts__comments').all()
```

---

## 실전 사례

### 사례: SaaS 대시보드 성능 개선

**Before**
```sql
-- 쿼리 1: 느린 쿼리 (5초)
SELECT * FROM analytics
WHERE user_id = 123
AND created_at BETWEEN '2024-01-01' AND '2024-12-31'
ORDER BY created_at DESC;

-- 문제: 인덱스 없음, Full Table Scan
-- 500만 rows 스캔
```

**After**
```sql
-- 인덱스 추가
CREATE INDEX idx_analytics_user_created
ON analytics(user_id, created_at DESC);

-- 쿼리 개선
SELECT id, metric_name, value, created_at
FROM analytics
WHERE user_id = 123
AND created_at BETWEEN '2024-01-01' AND '2024-12-31'
ORDER BY created_at DESC
LIMIT 100;

-- 결과: 5초 → 15ms (333배 빠름)
```

**ROI:**
- 페이지 로딩: 8초 → 1초
- 전환율: 2.1% → 4.3% (105% 증가)
- 서버 비용: $2,000/월 → $800/월 (60% 절감)

---

## 체크리스트

**인덱싱**
- [ ] WHERE 절 컬럼에 인덱스
- [ ] JOIN 키에 인덱스
- [ ] ORDER BY 컬럼에 인덱스
- [ ] 복합 인덱스 컬럼 순서 최적화
- [ ] Covering Index 검토

**쿼리 최적화**
- [ ] SELECT * 제거
- [ ] LIMIT 사용
- [ ] N+1 문제 제거
- [ ] EXPLAIN ANALYZE 실행
- [ ] Connection Pool 설정

**모니터링**
- [ ] Slow Query Log 활성화
- [ ] 인덱스 사용률 확인
- [ ] DB CPU/메모리 모니터링

---

## 참고 자료

- [SQL Query Optimization (DataCamp)](https://www.datacamp.com/blog/sql-query-optimization)
- [Database Indexing Best Practices (DEV.to)](https://dev.to/muhammmad_nawaz_d8ba895e1/best-practices-for-database-indexing-to-improve-query-performance-1k7e)
- [8 Indexing Strategies](https://www.developernation.net/blog/8-indexing-strategies-to-optimize-database-performance/)

---

**DB 성능 최적화로 사용자 경험과 비용을 동시에 개선! ⚡**
