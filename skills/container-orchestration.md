# Container Orchestration (Docker Compose + Kubernetes)

> Docker Compose로 로컬 개발을 간편하게, Kubernetes로 프로덕션을 안정적으로 관리하는 완전 가이드 (2026년 최신)

## 목차

1. [컨테이너 오케스트레이션이 왜 필요한가?](#컨테이너-오케스트레이션이-왜-필요한가)
2. [Docker Compose vs Kubernetes](#docker-compose-vs-kubernetes)
3. [Docker Compose로 시작하기](#docker-compose로-시작하기)
4. [Kubernetes 기초](#kubernetes-기초)
5. [Helm Charts로 프로덕션 배포](#helm-charts로-프로덕션-배포)
6. [실전 사례](#실전-사례)

---

## 컨테이너 오케스트레이션이 왜 필요한가?

### 수동 컨테이너 관리의 문제점

**배포 지옥** 🔥
```
스타트업 현실:
- 마이크로서비스: API, Web, DB, Redis, Worker 5개
- 서버 3대: 개발, 스테이징, 프로덕션
- 배포 방식: SSH 접속 → docker run 수동 실행
- 배포 시간: 서버당 30분 × 3대 = 1.5시간
- 실수율: 30% (환경 변수 누락, 포트 충돌 등)
```

**스케일링 불가** 😞
```
트래픽 급증 시:
- 컨테이너 추가: 수동으로 docker run
- 로드 밸런싱: nginx 설정 수동 수정
- 결과: 대응 시간 1시간 → 서버 다운
```

**장애 복구 지연** 🐌
```
컨테이너 크래시:
- 자동 재시작: 없음
- 모니터링: 수동 확인
- 복구 시간: 평균 15분
- 연간 다운타임: 3.6시간 (99.96% 가용성)
```

### 오케스트레이션의 이점

**자동화** 🚀
```yaml
# docker-compose.yml (로컬)
services:
  api:
    image: my-api:latest
    replicas: 3        # 자동으로 3개 실행
    restart: always    # 크래시 시 자동 재시작
```
- 배포 시간: 1.5시간 → 5분 (95% 단축)
- 실수율: 30% → 0%

**자동 스케일링** ✅
```yaml
# Kubernetes (프로덕션)
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
spec:
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```
- 트래픽 급증 대응: 1시간 → 30초 (자동)

**자가 치유** 💚
```
컨테이너 크래시:
- Kubernetes가 자동 감지 (Health Check)
- 3초 내 새 컨테이너 시작
- 다운타임: 3.6시간/년 → 5분/년 (99.999% 가용성)
```

---

## Docker Compose vs Kubernetes

| 항목 | Docker Compose | Kubernetes |
|------|----------------|------------|
| 사용 환경 | 로컬 개발 | 프로덕션 |
| 규모 | 1-5 컨테이너 | 20+ 컨테이너 |
| 서버 | 단일 호스트 | 다중 노드 클러스터 |
| 설정 파일 | YAML (간단) | YAML (복잡) |
| 학습 곡선 | 낮음 | 높음 |
| 자동 스케일링 | 수동 | 자동 (HPA) |
| 자가 치유 | 제한적 | 강력 |
| 로드 밸런싱 | 수동 | 자동 (Service) |
| 배포 전략 | 단순 | Rolling, Blue-Green, Canary |
| 비용 | 무료 | 무료 (관리형은 유료) |

### 선택 가이드

**Docker Compose를 사용하세요:**
- ✅ 로컬 개발 환경
- ✅ 소규모 앱 (5개 이하 서비스)
- ✅ 빠른 프로토타이핑
- ✅ CI/CD 테스트 환경

**Kubernetes를 사용하세요:**
- ✅ 프로덕션 환경
- ✅ 대규모 앱 (20+ 서비스)
- ✅ 고가용성 필요
- ✅ 자동 스케일링 필요

**Best Practice:** 로컬은 Docker Compose, 프로덕션은 Kubernetes

---

## Docker Compose로 시작하기

### 설치 (1분)

```bash
# Docker Desktop (Mac/Windows) - Docker Compose 포함
# 다운로드: https://www.docker.com/products/docker-desktop

# Linux
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 확인
docker-compose --version
```

### 기본 예제 (Next.js + PostgreSQL + Redis)

```yaml
# docker-compose.yml
version: '3.8'

services:
  # Web App
  web:
    build: .
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgresql://user:password@db:5432/myapp
      - REDIS_URL=redis://redis:6379
    depends_on:
      - db
      - redis
    volumes:
      - .:/app
      - /app/node_modules
    command: npm run dev

  # PostgreSQL
  db:
    image: postgres:15
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
      POSTGRES_DB: myapp
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  # Redis
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  postgres_data:
```

```dockerfile
# Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "run", "dev"]
```

**실행:**
```bash
# 모든 서비스 시작
docker-compose up -d

# 로그 확인
docker-compose logs -f

# 특정 서비스만 재시작
docker-compose restart web

# 모든 서비스 중지 및 삭제
docker-compose down

# 볼륨까지 삭제
docker-compose down -v
```

### 환경별 설정 (Dev/Prod)

```yaml
# docker-compose.yml (기본)
services:
  web:
    image: my-app:latest
    environment:
      - NODE_ENV=development

# docker-compose.prod.yml (오버라이드)
services:
  web:
    environment:
      - NODE_ENV=production
    restart: always
```

**실행:**
```bash
# 개발
docker-compose up -d

# 프로덕션
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

---

## Kubernetes 기초

### 로컬 Kubernetes 설정 (Docker Desktop)

```
1. Docker Desktop 실행
2. Settings → Kubernetes
3. "Enable Kubernetes" 체크
4. Apply & Restart
```

**확인:**
```bash
kubectl version --client
kubectl cluster-info
```

### 핵심 개념

**Pod:** 가장 작은 배포 단위 (1개 이상의 컨테이너)
**Deployment:** Pod의 복제본 관리 (Replica, Rolling Update)
**Service:** Pod에 대한 네트워크 엔드포인트
**Namespace:** 리소스 격리 (dev, staging, prod)

### 기본 배포 (Deployment + Service)

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  labels:
    app: my-app
spec:
  replicas: 3  # 3개의 Pod 실행
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: web
        image: my-app:latest
        ports:
        - containerPort: 3000
        env:
        - name: DATABASE_URL
          value: "postgresql://user:password@db-service:5432/myapp"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:   # 헬스 체크
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: my-app-service
spec:
  selector:
    app: my-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
  type: LoadBalancer  # 외부 접근 가능
```

**배포:**
```bash
# 배포
kubectl apply -f deployment.yaml

# 상태 확인
kubectl get pods
kubectl get deployments
kubectl get services

# 로그 확인
kubectl logs -f deployment/my-app

# 스케일링
kubectl scale deployment my-app --replicas=5

# 삭제
kubectl delete -f deployment.yaml
```

### ConfigMap & Secret

```yaml
# configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  NODE_ENV: "production"
  API_URL: "https://api.example.com"
---
# secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  DATABASE_PASSWORD: cGFzc3dvcmQxMjM=  # base64 인코딩
```

```yaml
# deployment.yaml (수정)
spec:
  containers:
  - name: web
    envFrom:
    - configMapRef:
        name: app-config
    - secretRef:
        name: app-secrets
```

---

## Helm Charts로 프로덕션 배포

### Helm 설치

```bash
# macOS
brew install helm

# Windows
choco install kubernetes-helm

# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# 확인
helm version
```

### Helm Chart 생성

```bash
# 새 차트 생성
helm create my-app

# 구조
my-app/
├── Chart.yaml           # 차트 메타데이터
├── values.yaml          # 기본 설정값
├── templates/           # Kubernetes YAML 템플릿
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   └── _helpers.tpl
└── charts/              # 의존성 차트
```

### values.yaml (환경별 설정)

```yaml
# values.yaml (기본)
replicaCount: 2

image:
  repository: my-app
  tag: "latest"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "200m"

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

env:
  NODE_ENV: "production"
  API_URL: "https://api.example.com"

secrets:
  DATABASE_PASSWORD: "password123"
```

```yaml
# values-dev.yaml
replicaCount: 1
autoscaling:
  enabled: false
env:
  NODE_ENV: "development"

# values-prod.yaml
replicaCount: 5
autoscaling:
  minReplicas: 5
  maxReplicas: 20
env:
  NODE_ENV: "production"
```

### 배포

```bash
# 개발 환경
helm install my-app-dev ./my-app -f values-dev.yaml

# 프로덕션 환경
helm install my-app-prod ./my-app -f values-prod.yaml --namespace production

# 업그레이드
helm upgrade my-app-prod ./my-app -f values-prod.yaml

# 롤백
helm rollback my-app-prod 1

# 삭제
helm uninstall my-app-prod
```

### Helm Hooks (DB 마이그레이션 예제)

```yaml
# templates/db-migration.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Release.Name }}-db-migration
  annotations:
    "helm.sh/hook": pre-upgrade,pre-install
    "helm.sh/hook-weight": "0"
    "helm.sh/hook-delete-policy": before-hook-creation
spec:
  template:
    spec:
      containers:
      - name: migration
        image: {{ .Values.image.repository }}:{{ .Values.image.tag }}
        command: ["npm", "run", "migrate"]
      restartPolicy: Never
```

**결과:** 배포 전 자동으로 DB 마이그레이션 실행

---

## 실전 사례

### 사례 1: SaaS 스타트업 (5개 마이크로서비스)

**Before (수동 배포)**
```
인프라:
- 서비스: API, Web, Worker, DB, Redis
- 배포 방식: SSH + docker run 수동 실행
- 배포 시간: 서버당 30분 × 3대 = 1.5시간
- 실수율: 30% (환경 변수 누락 등)
- 다운타임: 월 2회 (평균 20분)

문제점:
- 트래픽 급증 대응 불가
- 장애 복구 수동 (평균 15분)
- 개발자 배포 스트레스 +++
```

**After (Docker Compose + Kubernetes)**
```yaml
# 로컬: docker-compose.yml
docker-compose up -d  # 5초 만에 전체 스택 실행

# 프로덕션: Helm Chart
helm upgrade my-app ./chart -f values-prod.yaml  # 2분

배포 시간: 1.5시간 → 2분 (98% 단축)
실수율: 30% → 0%
다운타임: 월 40분 → 월 0분
자동 스케일링: CPU 70% 도달 시 자동 확장

개발자 만족도: 5점 만점에 4.8점
```

**ROI:**
```
연간 절감:
- 배포 시간 절약: 52주 * 1.48시간 * $50/시간 = $3,848
- 장애 대응 인력: 24회 * 15분 * $100/시간 = $600
- 다운타임 손실 방지: 24회 * $2,000 = $48,000
- 총: $52,448

초기 투자: $5,000 (학습 + 설정)
1년 ROI: 949%
```

### 사례 2: E-커머스 (Black Friday 대응)

**Before (수동 스케일링)**
```
평소 트래픽: 100 req/sec
Black Friday: 3,000 req/sec (30배)

대응:
1. 서버 증설 준비 (1주일 전)
2. 새 서버에 수동 배포 (3시간)
3. 로드 밸런서 설정 수정 (1시간)
4. 총 준비 시간: 1주일 + 4시간

비용:
- 서버 증설: $5,000 (한 달 계약)
- 실제 사용: 3일
- 낭비: $4,500 (90%)
```

**After (Kubernetes HPA)**
```yaml
# HorizontalPodAutoscaler
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web
  minReplicas: 5
  maxReplicas: 50
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70

# 결과
- 평소: 5 Pods
- Black Friday: 자동 50 Pods로 확장 (30초 내)
- 종료 후: 자동으로 5 Pods로 축소

비용:
- 클라우드 Auto Scaling: 사용한 만큼만 (3일)
- 총 비용: $800
- 절감: $4,200 (84%)
```

**추가 이익:**
- 장애 없음 (이전 해는 2시간 다운)
- 예상 손실 방지: $200,000
- 고객 만족도 향상

### 사례 3: Fintech (고가용성 99.99%)

**Kubernetes Self-Healing**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-api
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: api
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5

# 장애 시나리오
1. Pod 크래시 감지 (10초 이내)
2. 자동으로 새 Pod 시작 (5초)
3. Health Check 통과 시 트래픽 전환
4. 총 복구 시간: 15초

연간 다운타임:
- Before (수동): 3.6시간 (99.96%)
- After (자동): 5분 (99.999%)

SLA 달성으로 고객 계약 유지: +$1,200,000/년
```

---

## 체크리스트

### Docker Compose 시작 전
- [ ] Docker Desktop 설치
- [ ] `docker-compose.yml` 작성
- [ ] 환경 변수 분리 (`.env` 파일)
- [ ] Volume으로 데이터 영속성 확보
- [ ] `depends_on`으로 서비스 의존성 정의

### Kubernetes 시작 전
- [ ] `kubectl` 설치 및 클러스터 연결
- [ ] Namespace 생성 (dev, staging, prod)
- [ ] ConfigMap & Secret 작성
- [ ] Resource Limits 설정
- [ ] Health Check (Liveness, Readiness) 구현

### Helm 배포 전
- [ ] Helm 설치
- [ ] Chart 구조 이해
- [ ] 환경별 `values.yaml` 작성
- [ ] Hooks로 마이그레이션 자동화
- [ ] `helm lint`로 유효성 검사

### 프로덕션 전
- [ ] HPA 설정 (자동 스케일링)
- [ ] Ingress 설정 (외부 접근)
- [ ] Monitoring (Prometheus + Grafana)
- [ ] Logging (ELK Stack)
- [ ] 백업 전략 수립

---

## 참고 자료

### Docker Compose
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Docker Compose vs Kubernetes (DataCamp)](https://www.datacamp.com/blog/docker-compose-vs-kubernetes)

### Kubernetes
- [Kubernetes Official Docs](https://kubernetes.io/)
- [Translate Docker Compose to Kubernetes](https://kubernetes.io/docs/tasks/configure-pod-container/translate-compose-kubernetes/)
- [쿠버네티스 개념 (코드스테이츠)](https://www.codestates.com/blog/content/쿠버네티스)
- [쿠버네티스 알아보기 (삼성SDS)](https://www.samsungsds.com/kr/insights/220222_kubernetes1.html)

### Helm
- [Helm Official Docs](https://helm.sh/)
- [Helm Charts Tutorial (Testkube)](https://testkube.io/blog/helm-charts-tutorial-complete-guide-to-kubernetes-testing-deployment)
- [Production-Ready Helm Charts (DEV.to)](https://dev.to/azeemah/create-your-own-helm-charts-reusable-scalable-and-production-ready-4ed7)

---

## 마무리

이 가이드를 따라 구현하면:

1. ✅ **배포 자동화**: 배포 시간 **95%+ 단축**
2. ✅ **고가용성**: 다운타임 **99%+ 감소** (99.999% 달성)
3. ✅ **비용 절감**: Auto Scaling으로 **40-80% 절감**
4. ✅ **개발자 생산성**: 로컬 환경 **5초** 내 구축
5. ✅ **장애 대응**: 자동 복구로 **평균 15초**

Container Orchestration, 지금 시작하세요! 🚀
