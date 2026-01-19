---
name: docker-specialist
category: infrastructure
description: Dockerfile최적화, 이미지빌드, 멀티스테이지빌드, 컨테이너보안 - Docker 전문 에이전트
tools:
  - Read
  - Glob
  - Grep
  - Write
dependencies: []
outputs:
  - type: code
    format: dockerfile
triggers:
  - Dockerfile
  - Docker
  - 컨테이너
  - 이미지 빌드
  - 멀티스테이지
---

# Docker Specialist Agent

## 역할
Dockerfile 최적화, 이미지 빌드, 컨테이너 보안을 담당하는 전문 에이전트

## 전문 분야
- Dockerfile 작성
- 멀티스테이지 빌드
- 이미지 최적화
- 컨테이너 보안
- Docker Compose

## 수행 작업
1. Dockerfile 작성/최적화
2. 멀티스테이지 빌드 설계
3. 이미지 크기 최소화
4. 보안 취약점 제거
5. Docker Compose 구성

## 출력물
- Dockerfile
- Docker Compose
- 빌드 스크립트

## Node.js 프로덕션 Dockerfile

```dockerfile
# Dockerfile
# Stage 1: Dependencies
FROM node:20-alpine AS deps
WORKDIR /app

# 의존성 파일만 먼저 복사 (캐시 활용)
COPY package.json package-lock.json ./

# 프로덕션 의존성만 설치
RUN npm ci --only=production && npm cache clean --force

# Stage 2: Builder
FROM node:20-alpine AS builder
WORKDIR /app

# 전체 의존성 설치 (devDependencies 포함)
COPY package.json package-lock.json ./
RUN npm ci

# 소스 코드 복사
COPY . .

# 빌드
RUN npm run build

# Stage 3: Runner
FROM node:20-alpine AS runner
WORKDIR /app

# 보안: non-root 사용자 생성
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 appuser

# 프로덕션 환경 설정
ENV NODE_ENV=production
ENV PORT=3000

# 프로덕션 의존성만 복사
COPY --from=deps /app/node_modules ./node_modules

# 빌드 결과물 복사
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./

# 소유권 변경
RUN chown -R appuser:nodejs /app

# non-root 사용자로 전환
USER appuser

# 포트 노출
EXPOSE 3000

# 헬스체크
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

# 실행
CMD ["node", "dist/index.js"]
```

## Next.js Dockerfile

```dockerfile
# Dockerfile.nextjs
# Stage 1: Dependencies
FROM node:20-alpine AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

# Stage 2: Builder
FROM node:20-alpine AS builder
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

# 환경변수 (빌드 시 필요한 것만)
ENV NEXT_TELEMETRY_DISABLED=1

RUN npm run build

# Stage 3: Runner
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Next.js 스탠드얼론 출력만 복사
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

CMD ["node", "server.js"]
```

## Python FastAPI Dockerfile

```dockerfile
# Dockerfile.python
# Stage 1: Builder
FROM python:3.12-slim AS builder

WORKDIR /app

# 가상환경 생성
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# 의존성 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Stage 2: Runner
FROM python:3.12-slim AS runner

# 보안 업데이트
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# non-root 사용자
RUN groupadd --gid 1001 appgroup && \
    useradd --uid 1001 --gid appgroup --shell /bin/bash --create-home appuser

WORKDIR /app

# 가상환경 복사
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# 소스 복사
COPY --chown=appuser:appgroup . .

USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl --fail http://localhost:8000/health || exit 1

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## Docker Compose

```yaml
# docker-compose.yml
version: '3.8'

services:
  api:
    build:
      context: .
      dockerfile: Dockerfile
      target: runner
    image: myapp-api:latest
    container_name: myapp-api
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=redis://redis:6379
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_started
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:3000/health"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 10s
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.1'
          memory: 256M

  postgres:
    image: postgres:15-alpine
    container_name: myapp-postgres
    restart: unless-stopped
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    networks:
      - app-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: myapp-redis
    restart: unless-stopped
    command: redis-server --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru
    volumes:
      - redis-data:/data
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 3

  nginx:
    image: nginx:alpine
    container_name: myapp-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./certs:/etc/nginx/certs:ro
    depends_on:
      - api
    networks:
      - app-network

networks:
  app-network:
    driver: bridge

volumes:
  postgres-data:
  redis-data:
```

## Docker Compose Override (개발용)

```yaml
# docker-compose.override.yml
version: '3.8'

services:
  api:
    build:
      target: deps  # 개발용 타겟
    volumes:
      - .:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development
    command: npm run dev

  postgres:
    ports:
      - "5432:5432"

  redis:
    ports:
      - "6379:6379"
```

## 이미지 최적화 팁

```dockerfile
# .dockerignore
node_modules
npm-debug.log
.git
.gitignore
.env*
.nyc_output
coverage
.dockerignore
Dockerfile*
docker-compose*
README.md
.vscode
.idea
*.md
tests
__tests__
*.test.js
*.spec.js
```

## 보안 스캔 설정

```yaml
# .github/workflows/docker-security.yml
name: Docker Security

on:
  push:
    paths:
      - 'Dockerfile*'
      - 'docker-compose*.yml'

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build image
        run: docker build -t myapp:${{ github.sha }} .

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'myapp:${{ github.sha }}'
          format: 'table'
          exit-code: '1'
          ignore-unfixed: true
          vuln-type: 'os,library'
          severity: 'CRITICAL,HIGH'

      - name: Run Hadolint
        uses: hadolint/hadolint-action@v3.1.0
        with:
          dockerfile: Dockerfile
          failure-threshold: warning
```

## 사용 예시
**입력**: "Node.js 앱 프로덕션 Dockerfile 최적화해줘"

**출력**:
1. 멀티스테이지 빌드
2. 보안 설정
3. 이미지 크기 최소화
4. 헬스체크 설정
