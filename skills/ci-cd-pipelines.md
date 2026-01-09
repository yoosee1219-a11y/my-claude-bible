# CI/CD Pipelines

> GitHub Actions, GitLab CI로 자동화된 배포 파이프라인 구축 완벽 가이드 (2026)

## 목차

1. [CI/CD가 왜 중요한가?](#cicd가-왜-중요한가)
2. [GitHub Actions vs GitLab CI](#github-actions-vs-gitlab-ci)
3. [GitHub Actions 파이프라인](#github-actions-파이프라인)
4. [GitLab CI 파이프라인](#gitlab-ci-파이프라인)
5. [배포 전략](#배포-전략)
6. [최적화 기법](#최적화-기법)
7. [실전 사례](#실전-사례)

---

## CI/CD가 왜 중요한가?

### 수동 배포의 문제점

**Before CI/CD**
```
1. 로컬에서 빌드
2. FTP로 파일 업로드
3. SSH 접속해서 수동 설정
4. 서버 재시작
5. 테스트 (프로덕션에서!)
6. 문제 발생 시 수동 롤백

문제:
- 배포 시간: 1-2시간
- 휴먼 에러 빈번
- 롤백 어려움
- 다운타임 발생
```

**After CI/CD**
```
1. git push
2. 자동 빌드 & 테스트
3. 자동 배포
4. 자동 헬스체크
5. 실패 시 자동 롤백

결과:
✅ 배포 시간: 5분
✅ 에러 99% 감소
✅ 제로 다운타임
✅ 하루 10회+ 배포
```

---

### 통계 (2026)

| 메트릭 | High Performers | Low Performers |
|--------|-----------------|----------------|
| CI/CD 도입률 | 75% | 42% |
| 배포 속도 | 50% 빠름 | 기준 |
| 개발자 생산성 | +20% | 기준 |
| 장애율 | -70% | 기준 |

**ROI:** 연간 $150K 인건비 절감 (수동 배포 시간)

---

## GitHub Actions vs GitLab CI

### 비교표

| 항목 | GitHub Actions | GitLab CI |
|------|----------------|-----------|
| 설정 파일 | `.github/workflows/*.yml` | `.gitlab-ci.yml` |
| Runner | GitHub-hosted / Self-hosted | GitLab-hosted / Self-hosted |
| 무료 Runner | 2,000분/월 (Public 무제한) | 400분/월 |
| Marketplace | 11,000+ Actions | Components |
| 병렬 실행 | Matrix Builds | Parallel Jobs |
| 캐싱 | `actions/cache` | `cache:` 키워드 |
| Secrets | Repository/Organization | Project/Group |
| 러닝 커브 | 쉬움 | 중간 |

**선택 기준:**
- **GitHub Actions:** GitHub 호스팅, Marketplace 활용, 간단한 설정
- **GitLab CI:** GitLab 호스팅, 복잡한 파이프라인, 내장 기능 풍부

---

## GitHub Actions 파이프라인

### 기본 구조

```yaml
# .github/workflows/ci-cd.yml
name: CI/CD Pipeline

# 트리거
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  workflow_dispatch:  # 수동 실행

# 환경 변수
env:
  NODE_VERSION: '20'
  REGISTRY: ghcr.io

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run linter
        run: npm run lint

      - name: Run tests
        run: npm test -- --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          token: ${{ secrets.CODECOV_TOKEN }}

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build

      - name: Upload build artifacts
        uses: actions/upload-artifact@v4
        with:
          name: build
          path: dist/

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment: production
    steps:
      - uses: actions/checkout@v4

      - name: Download build artifacts
        uses: actions/download-artifact@v4
        with:
          name: build
          path: dist/

      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          vercel-args: '--prod'
```

---

### Matrix Builds (병렬 테스트)

```yaml
jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        node-version: [18, 20, 22]
        exclude:
          - os: macos-latest
            node-version: 18
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}

      - run: npm ci
      - run: npm test
```

**결과:** 3 OS × 3 Node 버전 = 9개 조합 병렬 실행

---

### Caching (의존성 캐싱)

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # npm 캐싱 (자동)
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      # 커스텀 캐싱
      - name: Cache node modules
        uses: actions/cache@v4
        with:
          path: |
            ~/.npm
            node_modules
          key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
          restore-keys: |
            ${{ runner.os }}-node-

      - run: npm ci
```

**결과:** 의존성 설치 시간 3분 → 30초

---

### Secrets 관리

**설정:**
```
GitHub → Repository → Settings → Secrets and variables → Actions
→ New repository secret
```

**사용:**
```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
          API_KEY: ${{ secrets.API_KEY }}
        run: |
          echo "Deploying with secure credentials"
          npm run deploy
```

**조직 레벨 Secrets:**
```
GitHub → Organization → Settings → Secrets
```

---

### Docker 이미지 빌드 & 푸시

```yaml
jobs:
  docker:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ghcr.io/${{ github.repository }}
          tags: |
            type=ref,event=branch
            type=semver,pattern={{version}}
            type=sha

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

---

## GitLab CI 파이프라인

### 기본 구조

```yaml
# .gitlab-ci.yml
stages:
  - test
  - build
  - deploy

variables:
  NODE_VERSION: "20"

# 템플릿 (재사용)
.node_template: &node_template
  image: node:$NODE_VERSION
  before_script:
    - npm ci
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - node_modules/

# 테스트
test:lint:
  <<: *node_template
  stage: test
  script:
    - npm run lint

test:unit:
  <<: *node_template
  stage: test
  script:
    - npm test -- --coverage
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml

# 빌드
build:
  <<: *node_template
  stage: build
  script:
    - npm run build
  artifacts:
    paths:
      - dist/
    expire_in: 1 week

# 배포
deploy:production:
  stage: deploy
  image: alpine:latest
  before_script:
    - apk add --no-cache curl
  script:
    - curl -X POST $VERCEL_DEPLOY_HOOK
  environment:
    name: production
    url: https://myapp.com
  only:
    - main
```

---

### Parallel Jobs

```yaml
test:unit:
  stage: test
  parallel: 3
  script:
    - npm run test:parallel -- --ci-node-index $CI_NODE_INDEX --ci-node-total $CI_NODE_TOTAL
```

**결과:** 테스트 스위트를 3개로 분할하여 병렬 실행

---

### Multi-Project Pipelines

```yaml
# 메인 프로젝트 .gitlab-ci.yml
trigger:frontend:
  stage: deploy
  trigger:
    project: mygroup/frontend
    branch: main

trigger:backend:
  stage: deploy
  trigger:
    project: mygroup/backend
    branch: main
```

---

### Dynamic Child Pipelines

```yaml
generate-config:
  stage: .pre
  script:
    - python generate_pipeline.py > generated-config.yml
  artifacts:
    paths:
      - generated-config.yml

child-pipeline:
  stage: test
  trigger:
    include:
      - artifact: generated-config.yml
        job: generate-config
    strategy: depend
```

---

## 배포 전략

### 1. Rolling Deployment (점진적 배포)

**설명:** 서버를 하나씩 업데이트

```yaml
# GitHub Actions
jobs:
  deploy:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        server: [server1, server2, server3]
      max-parallel: 1  # 한 번에 1개씩
    steps:
      - name: Deploy to ${{ matrix.server }}
        run: |
          ssh user@${{ matrix.server }} 'docker pull myapp:latest'
          ssh user@${{ matrix.server }} 'docker-compose up -d'
          sleep 30  # 헬스체크 대기
```

**장점:** 간단, 다운타임 최소화
**단점:** 롤백 복잡

---

### 2. Blue-Green Deployment

**설명:** 두 환경(Blue/Green)을 번갈아 사용

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Determine target environment
        id: target
        run: |
          CURRENT=$(aws elbv2 describe-target-groups --names myapp-prod | jq -r '.TargetGroups[0].TargetGroupArn')
          if [[ $CURRENT == *"blue"* ]]; then
            echo "target=green" >> $GITHUB_OUTPUT
          else
            echo "target=blue" >> $GITHUB_OUTPUT
          fi

      - name: Deploy to ${{ steps.target.outputs.target }}
        run: |
          aws ecs update-service --cluster myapp --service myapp-${{ steps.target.outputs.target }} --force-new-deployment

      - name: Wait for deployment
        run: aws ecs wait services-stable --cluster myapp --services myapp-${{ steps.target.outputs.target }}

      - name: Switch traffic
        run: |
          aws elbv2 modify-listener --listener-arn $LISTENER_ARN \
            --default-actions Type=forward,TargetGroupArn=${{ steps.target.outputs.target }}-tg

      - name: Monitor for 5 minutes
        run: sleep 300

      - name: Rollback if errors detected
        if: failure()
        run: |
          aws elbv2 modify-listener --listener-arn $LISTENER_ARN \
            --default-actions Type=forward,TargetGroupArn=$OLD_TARGET_GROUP
```

**장점:** 즉시 롤백, 제로 다운타임
**단점:** 인프라 2배 비용

---

### 3. Canary Deployment (카나리 배포)

**설명:** 일부 트래픽만 새 버전으로

```yaml
jobs:
  deploy-canary:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to canary
        run: kubectl set image deployment/myapp myapp=myapp:${{ github.sha }} -n canary

      - name: Route 10% traffic to canary
        run: |
          kubectl apply -f - <<EOF
          apiVersion: networking.istio.io/v1beta1
          kind: VirtualService
          metadata:
            name: myapp
          spec:
            hosts:
            - myapp.com
            http:
            - match:
              - headers:
                  cookie:
                    regex: ".*canary=true.*"
              route:
              - destination:
                  host: myapp
                  subset: canary
            - route:
              - destination:
                  host: myapp
                  subset: stable
                weight: 90
              - destination:
                  host: myapp
                  subset: canary
                weight: 10
          EOF

      - name: Monitor metrics for 30 minutes
        run: |
          for i in {1..30}; do
            ERROR_RATE=$(curl -s http://prometheus:9090/api/v1/query?query=rate\(http_errors_total\{version=\"canary\"\}\[5m]\) | jq '.data.result[0].value[1]')
            if (( $(echo "$ERROR_RATE > 0.05" | bc -l) )); then
              echo "Error rate too high: $ERROR_RATE"
              exit 1
            fi
            sleep 60
          done

      - name: Promote to production
        if: success()
        run: kubectl set image deployment/myapp myapp=myapp:${{ github.sha }} -n production

      - name: Rollback canary
        if: failure()
        run: kubectl rollout undo deployment/myapp -n canary
```

**장점:** 위험 최소화, 실제 트래픽 테스트
**단점:** 복잡한 모니터링 필요

---

## 최적화 기법

### 1. 조건부 실행

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    # main 브랜치만
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Deploy
        run: npm run deploy

  notify-slack:
    runs-on: ubuntu-latest
    # 실패 시에만
    if: failure()
    steps:
      - name: Notify Slack
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "❌ Build failed: ${{ github.event.head_commit.message }}"
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

---

### 2. Reusable Workflows (GitHub Actions)

```yaml
# .github/workflows/reusable-deploy.yml
name: Reusable Deploy Workflow

on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
    secrets:
      DEPLOY_TOKEN:
        required: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to ${{ inputs.environment }}
        run: echo "Deploying to ${{ inputs.environment }}"
        env:
          TOKEN: ${{ secrets.DEPLOY_TOKEN }}
```

**사용:**
```yaml
# .github/workflows/main.yml
jobs:
  deploy-staging:
    uses: ./.github/workflows/reusable-deploy.yml
    with:
      environment: staging
    secrets:
      DEPLOY_TOKEN: ${{ secrets.STAGING_TOKEN }}

  deploy-production:
    uses: ./.github/workflows/reusable-deploy.yml
    with:
      environment: production
    secrets:
      DEPLOY_TOKEN: ${{ secrets.PRODUCTION_TOKEN }}
```

---

### 3. Dependency Caching

```yaml
# npm (GitHub Actions)
- uses: actions/setup-node@v4
  with:
    cache: 'npm'

# GitLab CI
cache:
  key: ${CI_COMMIT_REF_SLUG}
  paths:
    - node_modules/
    - .npm/
```

---

### 4. 테스트 최적화

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # 전체 히스토리

      # 변경된 파일만 테스트
      - name: Get changed files
        id: changed-files
        uses: tj-actions/changed-files@v42

      - name: Run tests for changed files
        if: steps.changed-files.outputs.any_changed == 'true'
        run: |
          npm test -- --findRelatedTests ${{ steps.changed-files.outputs.all_changed_files }}
```

---

## 실전 사례

### 사례: SaaS 스타트업 CI/CD 구축

**Before**
```
- 수동 배포: 주 1회 (금요일 오후)
- 배포 시간: 2시간
- 롤백 시간: 30분 (수동)
- 테스트: 로컬에서만
- 장애율: 15% (배포 후 버그)
```

**CI/CD 구축 과정:**

**1. GitHub Actions 파이프라인 생성**
```yaml
# .github/workflows/ci-cd.yml
name: CI/CD

on:
  push:
    branches: [main]
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run lint
      - run: npm test -- --coverage
      - run: npm run test:e2e

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run build
      - uses: actions/upload-artifact@v4
        with:
          name: build
          path: dist/

  deploy-staging:
    needs: build
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: build
      - uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}

  deploy-production:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment: production
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: build
      - uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          vercel-args: '--prod'

      - name: Run smoke tests
        run: |
          curl -f https://myapp.com/api/health || exit 1

      - name: Notify Slack
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "✅ Deployed to production: ${{ github.event.head_commit.message }}"
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

**2. 보안 스캔 추가**
```yaml
jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # Dependency 스캔
      - name: Run Snyk
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}

      # Secret 스캔
      - name: GitGuardian scan
        uses: GitGuardian/ggshield-action@v1
        env:
          GITHUB_PUSH_BEFORE_SHA: ${{ github.event.before }}
          GITHUB_PUSH_BASE_SHA: ${{ github.event.base }}
          GITHUB_DEFAULT_BRANCH: ${{ github.event.repository.default_branch }}
          GITGUARDIAN_API_KEY: ${{ secrets.GITGUARDIAN_API_KEY }}
```

---

**After**
```
✅ 자동 배포: 하루 10회+
✅ 배포 시간: 5분
✅ 롤백 시간: 1분 (자동)
✅ 테스트: 모든 PR에서 자동 실행
✅ 장애율: 2% (87% 감소)
```

**결과:**
- 배포 빈도: 주 1회 → 일 10회 (1,000% 증가)
- 개발자 생산성: +35%
- 고객 불만: -60%
- Time-to-market: 2주 → 2일

**ROI:** 연간 $180K 인건비 절감 (수동 배포 시간 + 버그 수정 시간)

---

## 체크리스트

### 기본 설정
- [ ] CI/CD 플랫폼 선택 (GitHub Actions / GitLab CI)
- [ ] `.github/workflows/*.yml` 또는 `.gitlab-ci.yml` 생성
- [ ] 브랜치 전략 (main, develop, feature/*)
- [ ] Secrets 관리 (환경 변수)

### 테스트 단계
- [ ] Linting (ESLint, Prettier)
- [ ] Unit 테스트 (Jest, Vitest)
- [ ] Integration 테스트
- [ ] E2E 테스트 (Playwright, Cypress)
- [ ] Coverage 리포트 (80% 이상)

### 빌드 단계
- [ ] 의존성 캐싱
- [ ] 빌드 최적화
- [ ] Artifacts 저장

### 배포 단계
- [ ] 환경별 배포 (Staging, Production)
- [ ] 배포 전략 선택 (Rolling, Blue-Green, Canary)
- [ ] Smoke 테스트
- [ ] 자동 롤백

### 보안
- [ ] Dependency 스캔 (Snyk, Dependabot)
- [ ] Secret 스캔 (GitGuardian)
- [ ] SAST (Static Application Security Testing)
- [ ] Container 이미지 스캔

### 모니터링
- [ ] Slack/Discord 알림
- [ ] 배포 성공/실패 추적
- [ ] 성능 메트릭 수집
- [ ] 에러 리포팅 (Sentry)

---

## 참고 자료

- [GitHub Actions Documentation](https://docs.github.com/actions)
- [GitLab CI/CD Documentation](https://docs.gitlab.com/ci/)
- [GitHub Actions Best Practices (NetApp)](https://www.netapp.com/learn/cvo-blg-5-github-actions-cicd-best-practices/)
- [CI/CD Pipeline Guide 2026 (Middleware)](https://middleware.io/blog/what-is-a-ci-cd-pipeline/)
- [CI/CD Best Practices (Spacelift)](https://spacelift.io/blog/ci-cd-best-practices)

---

**git push 한 번으로 프로덕션 배포까지 자동화하세요! 🚀**
