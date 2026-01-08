---
name: database-admin
description: 데이터베이스관리, DB최적화, 쿼리튜닝, 스키마설계, 인덱스, 백업복구, 성능모니터링, ERD, 정규화, 느린쿼리, 실행계획, 데드락감지를 지원하는 스킬
---

# Database Admin: Database Management & Optimization

데이터베이스 관리 및 최적화

## 기능:

1. **데이터베이스 설계**
   - ERD (Entity-Relationship Diagram) 생성
   - 정규화 (1NF, 2NF, 3NF)
   - 인덱스 전략
   - 파티셔닝 설계
   - 샤딩 전략 (필요시)

2. **쿼리 최적화**
   - 느린 쿼리 탐지
   - 실행 계획 분석
   - 인덱스 추가/제거
   - 쿼리 리팩토링
   - N+1 문제 해결

3. **성능 모니터링**
   - 쿼리 실행 시간 추적
   - 데드락 감지
   - 연결 풀 관리
   - 캐시 히트율
   - 디스크 I/O 모니터링

4. **백업 & 복구**
   - 자동 백업 스케줄
   - 증분 백업
   - 복구 테스트
   - 재해 복구 계획
   - 데이터 마이그레이션

## 데이터베이스 스키마:

```sql
-- 자동 생성되는 최적화된 스키마 예시

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스 자동 생성
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at DESC);

-- 트리거 자동 생성
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

## 성능 최적화:

**쿼리 최적화 예시:**
```sql
-- Before (느림)
SELECT * FROM posts
WHERE user_id IN (
  SELECT id FROM users WHERE country = 'KR'
);

-- After (빠름)
SELECT p.* FROM posts p
INNER JOIN users u ON p.user_id = u.id
WHERE u.country = 'KR';

-- 실행 시간: 450ms → 12ms (37배 개선)
```

## 모니터링 메트릭:

```
데이터베이스 상태:

🔍 쿼리 성능
- 평균 응답 시간: 25ms
- 느린 쿼리 (>100ms): 3개
- 가장 느린 쿼리: 450ms

💾 리소스 사용
- CPU: 15%
- 메모리: 2.1GB / 4GB
- 디스크: 45GB / 100GB
- 연결: 12 / 100

📊 통계
- 총 쿼리/초: 125
- 읽기/쓰기 비율: 80/20
- 캐시 히트율: 94%
- 인덱스 활용률: 87%
```

## 백업 전략:

```
일일 백업:
- 전체 백업: 매일 03:00 (자동)
- 보관 기간: 7일
- 저장 위치: S3

증분 백업:
- 매 6시간마다
- 보관 기간: 48시간

복구 시간 목표 (RTO): 1시간
복구 시점 목표 (RPO): 6시간
```

## 출력:

- DATABASE_SCHEMA.sql
- OPTIMIZATION_REPORT.md
- SLOW_QUERIES.md
- BACKUP_STATUS.json
- MIGRATION_SCRIPTS/
