# Backup & Disaster Recovery

> RTO/RPO, 자동화된 백업, Point-in-Time Recovery로 데이터 손실 제로 달성 (2026)

## 목차

1. [백업이 왜 중요한가?](#백업이-왜-중요한가)
2. [RTO vs RPO](#rto-vs-rpo)
3. [백업 전략](#백업-전략)
4. [데이터베이스별 백업](#데이터베이스별-백업)
5. [AWS S3 백업](#aws-s3-백업)
6. [재해 복구 테스트](#재해-복구-테스트)
7. [실전 사례](#실전-사례)

---

## 백업이 왜 중요한가?

### 재해 사고의 비용

**GitLab DB 삭제 사고 (2017)**
- 사고: 엔지니어가 프로덕션 DB 삭제
- 손실: 300GB 데이터, 6시간 분량
- 원인: 백업 실패 (5개 백업 중 작동한 것 0개)
- 복구: 18시간 소요
- **교훈:** 백업 테스트를 하지 않았음

**FEMA 통계:**
- 심각한 재해 후 25% 기업은 재개업 못 함
- IT 다운타임 평균 비용: $5,600/분

---

### 백업 없는 시스템의 위험

**Before 백업**
```
- DB 서버 하드웨어 고장 → 전체 데이터 손실
- 랜섬웨어 공격 → 복호화 불가
- 실수로 데이터 삭제 → 복구 불가
- 비용: $수억 + 고객 신뢰 상실
```

**After 백업**
```
✅ 자동 일일 백업 → AWS S3 (암호화)
✅ Point-in-Time Recovery → 5분 전 상태로 복원
✅ 지리적 분산 (Multi-Region) → 지역 재해 대비
✅ 정기 복원 테스트 → 신뢰성 보장
```

**ROI:** 평균 데이터 손실 비용 $9.4M 회피

---

## RTO vs RPO

### 핵심 개념

**RPO (Recovery Point Objective): 데이터 손실 허용치**
- "최대 몇 분치 데이터를 잃어도 되는가?"
- 백업 주기 결정

**RTO (Recovery Time Objective): 다운타임 허용치**
- "최대 몇 분 동안 서비스가 중단되어도 되는가?"
- 복구 속도 결정

---

### 예시

**시나리오: E커머스 DB 서버 장애 (오후 3시)**

**RPO = 1시간**
```
- 마지막 백업: 오후 2시
- 복원 후 상태: 오후 2시
- 손실 데이터: 오후 2시~3시 주문 (1시간치)
```

**RTO = 30분**
```
- 장애 발생: 오후 3시
- 복구 완료: 오후 3시 30분
- 다운타임: 30분
```

---

### 목표 설정

**애플리케이션별 RTO/RPO 예시:**

| 서비스 | RPO | RTO | 백업 전략 |
|--------|-----|-----|----------|
| 결제 시스템 | 5분 | 15분 | 실시간 복제 + 5분 백업 |
| 사용자 DB | 1시간 | 30분 | 1시간 자동 백업 |
| 블로그 콘텐츠 | 24시간 | 2시간 | 일일 백업 |
| 로그 데이터 | 7일 | 24시간 | 주간 백업 |

**공식:**
- **RPO ↓ (낮음) = 백업 빈도 ↑ = 비용 ↑**
- **RTO ↓ (낮음) = 복구 속도 ↑ = 복잡도 ↑**

---

## 백업 전략

### 3-2-1 규칙

**업계 표준 백업 규칙:**
```
3: 백업 복사본 3개
2: 서로 다른 매체 2종류 (예: 로컬 SSD + 클라우드)
1: 오프사이트 1개 (지리적으로 떨어진 위치)
```

**구현 예시:**
```
복사본 1: 프로덕션 DB (Primary)
복사본 2: 로컬 백업 (매일, 7일 보관)
복사본 3: AWS S3 (매일, 30일 보관)
복사본 4: AWS S3 Glacier (월간, 1년 보관) - 옵션
```

---

### 백업 타입

**1. Full Backup (전체 백업)**
```
- 모든 데이터 백업
- 장점: 복원 빠름 (1개 파일만)
- 단점: 시간 오래 걸림, 스토리지 많이 사용
- 주기: 주간 또는 월간
```

**2. Incremental Backup (증분 백업)**
```
- 마지막 백업 이후 변경된 데이터만
- 장점: 빠르고 스토리지 절약
- 단점: 복원 시 모든 증분 필요
- 주기: 매일
```

**3. Differential Backup (차등 백업)**
```
- 마지막 Full Backup 이후 변경분
- 장점: 복원 시 Full + 마지막 Differential만 필요
- 주기: 매일
```

**조합 전략:**
```
일요일: Full Backup
월~토: Incremental Backup

복원 시: Full (일요일) + Incremental (월~목요일) = 4개 파일
```

---

## 데이터베이스별 백업

### PostgreSQL

**1. pg_dump (논리적 백업)**
```bash
# 단일 DB 백업
pg_dump -U postgres -d mydb -F c -f /backups/mydb_$(date +\%Y\%m\%d).dump

# 모든 DB 백업
pg_dumpall -U postgres -f /backups/all_dbs_$(date +\%Y\%m\%d).sql

# 압축 백업
pg_dump -U postgres -d mydb -F c -Z 9 -f /backups/mydb.dump.gz
```

**복원:**
```bash
# 단일 DB 복원
pg_restore -U postgres -d mydb -c /backups/mydb_20260109.dump

# SQL 파일 복원
psql -U postgres -d mydb -f /backups/all_dbs_20260109.sql
```

---

**2. pgBackRest (엔터프라이즈)**

**설치:**
```bash
sudo apt install pgbackrest
```

**설정 (/etc/pgbackrest/pgbackrest.conf):**
```ini
[global]
repo1-path=/var/lib/pgbackrest
repo1-retention-full=2
repo1-retention-diff=7

[mydb]
pg1-path=/var/lib/postgresql/14/main
pg1-port=5432
```

**백업:**
```bash
# Full Backup
pgbackrest --stanza=mydb --type=full backup

# Incremental Backup
pgbackrest --stanza=mydb --type=incr backup

# Differential Backup
pgbackrest --stanza=mydb --type=diff backup
```

**Point-in-Time Recovery:**
```bash
# 특정 시점으로 복원
pgbackrest --stanza=mydb --type=time \
  --target="2026-01-09 14:30:00" restore
```

---

**3. WAL-G (클라우드 친화적)**

**설치:**
```bash
go install github.com/wal-g/wal-g@latest
```

**AWS S3 백업:**
```bash
export AWS_ACCESS_KEY_ID=your-key
export AWS_SECRET_ACCESS_KEY=your-secret
export WALG_S3_PREFIX=s3://my-backups/postgres

# Full Backup
wal-g backup-push /var/lib/postgresql/14/main

# 백업 목록
wal-g backup-list

# 복원
wal-g backup-fetch /var/lib/postgresql/14/main LATEST
```

**자동화 (cron):**
```bash
# /etc/cron.d/postgres-backup
0 2 * * * postgres wal-g backup-push /var/lib/postgresql/14/main
```

---

### MongoDB

**1. mongodump (기본)**
```bash
# 전체 DB 백업
mongodump --uri="mongodb://localhost:27017" --out=/backups/$(date +\%Y\%m\%d)

# 단일 DB
mongodump --db=mydb --out=/backups/mydb_$(date +\%Y\%m\%d)

# GZIP 압축
mongodump --gzip --archive=/backups/mongodb_$(date +\%Y\%m\%d).gz
```

**복원:**
```bash
# 전체 복원
mongorestore --uri="mongodb://localhost:27017" /backups/20260109

# GZIP 복원
mongorestore --gzip --archive=/backups/mongodb_20260109.gz
```

---

**2. Percona Backup for MongoDB (엔터프라이즈)**

**설치:**
```bash
wget https://downloads.percona.com/downloads/percona-backup-mongodb/pbm.deb
sudo dpkg -i pbm.deb
```

**S3 설정:**
```yaml
# /etc/pbm.yaml
storage:
  type: s3
  s3:
    region: us-east-1
    bucket: my-mongodb-backups
    credentials:
      access-key-id: ${AWS_ACCESS_KEY_ID}
      secret-access-key: ${AWS_SECRET_ACCESS_KEY}
```

**백업:**
```bash
# Full Backup
pbm backup --type=full

# Incremental Backup
pbm backup --type=incremental

# Point-in-Time Recovery 활성화
pbm config --set pitr.enabled=true
```

**복원:**
```bash
# 최신 백업으로 복원
pbm restore --time="2026-01-09T14:30:00Z"
```

---

### Redis

**1. RDB (스냅샷)**
```bash
# redis.conf
save 900 1      # 900초마다 최소 1개 변경 시
save 300 10     # 300초마다 최소 10개 변경 시
save 60 10000   # 60초마다 최소 10,000개 변경 시

dbfilename dump.rdb
dir /var/lib/redis
```

**수동 백업:**
```bash
# 즉시 스냅샷
redis-cli SAVE

# 백그라운드 스냅샷
redis-cli BGSAVE

# RDB 파일 복사
cp /var/lib/redis/dump.rdb /backups/redis_$(date +\%Y\%m\%d).rdb
```

---

**2. AOF (Append-Only File)**
```bash
# redis.conf
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec  # 1초마다 디스크 동기화
```

**복원:**
```bash
# 1. Redis 중지
sudo systemctl stop redis

# 2. RDB 또는 AOF 파일 복원
cp /backups/redis_20260109.rdb /var/lib/redis/dump.rdb

# 3. Redis 시작
sudo systemctl start redis
```

---

### Prisma (애플리케이션 레벨)

**백업 스크립트 (Node.js):**
```javascript
// scripts/backup-db.js
import { PrismaClient } from '@prisma/client';
import { exec } from 'child_process';
import { promisify } from 'util';
import fs from 'fs';

const execAsync = promisify(exec);
const prisma = new PrismaClient();

async function backupDatabase() {
  const timestamp = new Date().toISOString().split('T')[0];
  const backupFile = `backups/db_${timestamp}.sql`;

  try {
    // PostgreSQL
    await execAsync(`pg_dump ${process.env.DATABASE_URL} > ${backupFile}`);

    console.log(`✅ Backup created: ${backupFile}`);

    // AWS S3 업로드 (선택)
    await execAsync(`aws s3 cp ${backupFile} s3://my-backups/${backupFile}`);

    console.log('✅ Uploaded to S3');

    // 로컬 파일 삭제 (7일 이상)
    const files = fs.readdirSync('backups');
    const sevenDaysAgo = Date.now() - 7 * 24 * 60 * 60 * 1000;

    files.forEach(file => {
      const filePath = `backups/${file}`;
      const stats = fs.statSync(filePath);

      if (stats.mtimeMs < sevenDaysAgo) {
        fs.unlinkSync(filePath);
        console.log(`🗑️ Deleted old backup: ${file}`);
      }
    });
  } catch (error) {
    console.error('❌ Backup failed:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

backupDatabase();
```

**실행:**
```bash
node scripts/backup-db.js
```

**자동화 (GitHub Actions):**
```yaml
# .github/workflows/backup.yml
name: Daily Database Backup

on:
  schedule:
    - cron: '0 2 * * *'  # 매일 오전 2시 (UTC)
  workflow_dispatch:     # 수동 실행

jobs:
  backup:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install dependencies
        run: npm ci

      - name: Run backup
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        run: node scripts/backup-db.js

      - name: Notify Slack
        if: failure()
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "❌ Database backup failed"
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

---

## AWS S3 백업

### S3 Continuous Backup (Point-in-Time Recovery)

**AWS Backup으로 설정:**

**1. AWS Console:**
```
AWS Backup → Backup plans → Create backup plan
→ Resource assignments → Select S3 buckets
→ Enable continuous backups
```

**2. Terraform:**
```hcl
# terraform/backup.tf
resource "aws_backup_plan" "s3_continuous" {
  name = "s3-continuous-backup"

  rule {
    rule_name         = "continuous_backup_rule"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 2 * * ? *)"  # 매일 오전 2시

    lifecycle {
      delete_after = 35  # 35일 보관
    }

    enable_continuous_backup = true
  }
}

resource "aws_backup_selection" "s3_buckets" {
  name         = "s3-bucket-selection"
  plan_id      = aws_backup_plan.s3_continuous.id
  iam_role_arn = aws_iam_role.backup.arn

  resources = [
    "arn:aws:s3:::my-app-data/*",
    "arn:aws:s3:::my-app-uploads/*",
  ]
}

resource "aws_backup_vault" "main" {
  name = "my-backup-vault"
}
```

**복원:**
```bash
# AWS CLI
aws backup start-restore-job \
  --recovery-point-arn arn:aws:backup:us-east-1:123456789012:recovery-point:abc123 \
  --metadata Bucket=my-app-data-restored
```

---

### S3 Versioning (간단한 방법)

**활성화:**
```bash
aws s3api put-bucket-versioning \
  --bucket my-app-data \
  --versioning-configuration Status=Enabled
```

**이전 버전 복원:**
```bash
# 모든 버전 확인
aws s3api list-object-versions --bucket my-app-data --prefix uploads/

# 특정 버전 복원
aws s3api copy-object \
  --bucket my-app-data \
  --copy-source my-app-data/uploads/photo.jpg?versionId=abc123 \
  --key uploads/photo.jpg
```

---

### Cross-Region Replication (재해 복구)

**Terraform:**
```hcl
resource "aws_s3_bucket" "primary" {
  bucket = "my-app-data-us-east-1"
}

resource "aws_s3_bucket" "replica" {
  bucket   = "my-app-data-eu-west-1"
  provider = aws.eu
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  bucket = aws_s3_bucket.primary.id
  role   = aws_iam_role.replication.arn

  rule {
    id     = "replicate-all"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.replica.arn
      storage_class = "STANDARD"
    }
  }
}
```

**결과:**
- US-EAST-1 재해 시 → EU-WEST-1에서 즉시 복구

---

## 재해 복구 테스트

### 복구 훈련 (Quarterly)

**분기별 DR Drill 체크리스트:**

```
[ ] 1. 테스트 환경 준비
    - 프로덕션과 별도 환경
    - 복원용 서버 준비

[ ] 2. 백업 파일 선택
    - 최신 백업 사용
    - 무결성 확인 (체크섬)

[ ] 3. 복원 실행
    - 복원 시작 시간 기록
    - 복원 과정 로깅

[ ] 4. 데이터 검증
    - 레코드 수 확인
    - 주요 데이터 샘플링
    - 애플리케이션 연동 테스트

[ ] 5. RTO 측정
    - 복원 소요 시간 계산
    - 목표 RTO와 비교

[ ] 6. 문서화
    - 복원 절차 업데이트
    - 발견된 문제점 기록
    - 개선 사항 작성
```

---

### 자동화된 복원 테스트

**스크립트 (Bash):**
```bash
#!/bin/bash
# scripts/test-restore.sh

set -e

echo "🔄 Starting restore test..."

# 1. 최신 백업 다운로드
LATEST_BACKUP=$(aws s3 ls s3://my-backups/ | sort | tail -n 1 | awk '{print $4}')
aws s3 cp s3://my-backups/$LATEST_BACKUP /tmp/test-restore.dump

# 2. 테스트 DB 생성
psql -U postgres -c "DROP DATABASE IF EXISTS test_restore;"
psql -U postgres -c "CREATE DATABASE test_restore;"

# 3. 복원
START_TIME=$(date +%s)
pg_restore -U postgres -d test_restore /tmp/test-restore.dump
END_TIME=$(date +%s)

# 4. 검증
RECORD_COUNT=$(psql -U postgres -d test_restore -t -c "SELECT COUNT(*) FROM users;")

if [ "$RECORD_COUNT" -lt 1000 ]; then
  echo "❌ Restore test failed: only $RECORD_COUNT records"
  exit 1
fi

# 5. RTO 계산
RESTORE_TIME=$((END_TIME - START_TIME))
echo "✅ Restore test passed"
echo "📊 Records: $RECORD_COUNT"
echo "⏱️ Restore time: ${RESTORE_TIME}s (RTO target: 1800s)"

# 6. 정리
psql -U postgres -c "DROP DATABASE test_restore;"
rm /tmp/test-restore.dump

# 7. 알림
if [ $RESTORE_TIME -gt 1800 ]; then
  curl -X POST $SLACK_WEBHOOK -d '{"text":"⚠️ Restore time exceeded RTO target"}'
fi
```

**자동화 (cron):**
```bash
# 매주 일요일 오전 3시
0 3 * * 0 /scripts/test-restore.sh >> /var/log/restore-test.log 2>&1
```

---

## 실전 사례

### 사례: SaaS 스타트업 재해 복구 시스템

**Before**
```
- 백업: 수동 (개발자가 기억할 때만)
- 주기: 불규칙 (주 1~2회)
- 저장: 로컬 서버 (단일 장애점)
- 복원 테스트: 없음
- RPO: 7일 (최악의 경우)
- RTO: 알 수 없음
```

**사고:**
```
- DB 서버 디스크 고장
- 마지막 백업: 5일 전
- 손실: 5일치 고객 데이터 (1,200건)
- 복구 시도: 실패 (백업 파일 손상)
- 결과: 고객 50% 이탈, $500K 매출 손실
```

---

**After 구축:**

**1. 백업 전략:**
```yaml
PostgreSQL:
  - pgBackRest (자동)
  - Full: 매주 일요일
  - Incremental: 매일
  - 보관: 30일
  - 저장: AWS S3 + Glacier

Redis:
  - RDB 스냅샷: 6시간마다
  - AOF: 활성화
  - 보관: 14일

S3 (사용자 업로드):
  - Versioning: 활성화
  - Cross-Region Replication: US-EAST-1 → EU-WEST-1
  - Lifecycle: 90일 후 Glacier
```

**2. Infrastructure as Code (Terraform):**
```hcl
# terraform/backup.tf
module "database_backup" {
  source = "./modules/backup"

  database_id = aws_db_instance.main.id
  retention   = 30
  backup_window = "03:00-04:00"
  s3_bucket   = "my-app-backups"
}
```

**3. 모니터링 & 알림:**
```javascript
// scripts/monitor-backups.js
import { S3Client, ListObjectsV2Command } from '@aws-sdk/client-s3';

const s3 = new S3Client({ region: 'us-east-1' });

async function checkBackups() {
  const response = await s3.send(new ListObjectsV2Command({
    Bucket: 'my-app-backups',
    Prefix: 'postgres/',
  }));

  const latestBackup = response.Contents[0];
  const backupAge = Date.now() - latestBackup.LastModified.getTime();
  const maxAge = 25 * 60 * 60 * 1000;  // 25시간

  if (backupAge > maxAge) {
    // Slack 알림
    await fetch(process.env.SLACK_WEBHOOK, {
      method: 'POST',
      body: JSON.stringify({
        text: '🚨 Backup is older than 25 hours!'
      }),
    });
  }
}

checkBackups();
```

**4. 복구 훈련 (월간):**
```bash
# 매월 첫째 일요일
0 3 1-7 * 0 /scripts/test-restore.sh
```

---

**결과:**
- RPO: 7일 → 1시간 (99.4% 개선)
- RTO: 알 수 없음 → 30분 (검증됨)
- 백업 신뢰도: 0% → 100% (월간 테스트)
- 스토리지 비용: $0 → $120/월
- 다운타임 (연간): 8시간 → 0시간

**ROI:** 평균 데이터 손실 비용 $9.4M 회피, 고객 신뢰도 회복

---

## 체크리스트

### 백업 설정
- [ ] RTO/RPO 목표 정의
- [ ] 3-2-1 백업 규칙 적용
- [ ] 자동화된 백업 스케줄 (cron/GitHub Actions)
- [ ] 암호화 활성화 (AES-256)
- [ ] 보관 주기 설정 (30-90일)

### 데이터베이스
- [ ] PostgreSQL: pgBackRest 또는 WAL-G
- [ ] MongoDB: Percona Backup 또는 mongodump
- [ ] Redis: RDB + AOF
- [ ] Point-in-Time Recovery 활성화

### 클라우드 스토리지
- [ ] AWS S3 Versioning
- [ ] Cross-Region Replication
- [ ] Lifecycle Policy (Glacier 전환)
- [ ] AWS Backup 설정

### 테스트 & 모니터링
- [ ] 월간 복원 테스트
- [ ] RTO 측정 및 기록
- [ ] 백업 실패 알림 (Slack/Email)
- [ ] 백업 나이 모니터링 (25시간 이상 시 알림)

### 문서화
- [ ] 복원 절차 문서화
- [ ] 백업 인벤토리 (위치, 주기)
- [ ] 연락처 (온콜 엔지니어)
- [ ] 에스컬레이션 프로세스

---

## 참고 자료

- [RTO vs RPO (Veeam)](https://www.veeam.com/blog/recovery-time-recovery-point-objectives.html)
- [Top PostgreSQL Backup Solutions 2026](https://www.bytebase.com/blog/top-open-source-postgres-backup-solution/)
- [MongoDB Backup Tools 2026](https://dev.to/piteradyson/top-mongodb-backup-tools-in-2026-26io)
- [AWS Backup Documentation](https://docs.aws.amazon.com/aws-backup/)
- [pgBackRest Documentation](https://pgbackrest.org/)
- [Percona Backup for MongoDB](https://www.percona.com/mongodb/software/percona-backup-for-mongodb)

---

**백업 테스트 없는 백업은 백업이 아닙니다! 💾**
