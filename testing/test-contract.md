---
name: test-contract
category: testing
description: 계약테스트, Consumer-Driven, Pact, API계약검증 - API 계약 테스트 전문 에이전트
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
  - 계약 테스트
  - contract test
  - Pact
  - consumer-driven
  - API 계약
---

# Contract Test Agent

## 역할
Consumer-Driven Contract Testing, API 계약 검증을 담당하는 전문 에이전트

## 전문 분야
- Pact 계약 테스트
- Consumer-Driven Contracts
- Provider 검증
- 계약 브로커 설정
- 스키마 검증

## 수행 작업
1. Consumer 계약 작성
2. Provider 검증 테스트
3. 계약 브로커 설정
4. 계약 버전 관리
5. 호환성 검증

## 출력물
- Pact 테스트 파일
- Provider 검증 스크립트
- 계약 설정

## Pact 설정

### 기본 설정
```typescript
// pact/pact-config.ts
import { PactV3, MatchersV3 } from '@pact-foundation/pact';
import path from 'path';

export const pactConfig = {
  consumer: 'frontend-app',
  dir: path.resolve(process.cwd(), 'pacts'),
  logLevel: 'warn',
  spec: 3,
};

export const { like, eachLike, string, integer, boolean, datetime, uuid } = MatchersV3;

export function createPact(provider: string) {
  return new PactV3({
    ...pactConfig,
    provider,
  });
}
```

### Consumer 테스트
```typescript
// pact/consumer/users-api.pact.ts
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { PactV3 } from '@pact-foundation/pact';
import { createPact, like, eachLike, uuid, string } from '../pact-config';
import { UserApiClient } from '@/clients/UserApiClient';

describe('Users API Contract', () => {
  const provider = createPact('users-service');
  let client: UserApiClient;

  beforeAll(async () => {
    await provider.setup();
    client = new UserApiClient(provider.mockService.baseUrl);
  });

  afterAll(async () => {
    await provider.finalize();
  });

  describe('GET /api/users/:id', () => {
    it('should return user details', async () => {
      const expectedUser = {
        id: uuid(),
        email: string('user@example.com'),
        name: string('John Doe'),
        role: string('user'),
        createdAt: string('2024-01-01T00:00:00Z'),
      };

      await provider.addInteraction({
        states: [{ description: 'user with ID 123 exists' }],
        uponReceiving: 'a request for user 123',
        withRequest: {
          method: 'GET',
          path: '/api/users/123',
          headers: {
            Authorization: 'Bearer valid-token',
          },
        },
        willRespondWith: {
          status: 200,
          headers: {
            'Content-Type': 'application/json',
          },
          body: like(expectedUser),
        },
      });

      const user = await client.getUser('123', 'valid-token');

      expect(user).toHaveProperty('id');
      expect(user).toHaveProperty('email');
      expect(user).toHaveProperty('name');
    });

    it('should return 404 for non-existent user', async () => {
      await provider.addInteraction({
        states: [{ description: 'user with ID 999 does not exist' }],
        uponReceiving: 'a request for non-existent user',
        withRequest: {
          method: 'GET',
          path: '/api/users/999',
          headers: {
            Authorization: 'Bearer valid-token',
          },
        },
        willRespondWith: {
          status: 404,
          headers: {
            'Content-Type': 'application/json',
          },
          body: {
            error: string('User not found'),
          },
        },
      });

      await expect(client.getUser('999', 'valid-token'))
        .rejects.toThrow('User not found');
    });
  });

  describe('GET /api/users', () => {
    it('should return paginated users list', async () => {
      await provider.addInteraction({
        states: [{ description: 'users exist in database' }],
        uponReceiving: 'a request for users list',
        withRequest: {
          method: 'GET',
          path: '/api/users',
          query: {
            page: '1',
            limit: '10',
          },
          headers: {
            Authorization: 'Bearer admin-token',
          },
        },
        willRespondWith: {
          status: 200,
          headers: {
            'Content-Type': 'application/json',
          },
          body: {
            data: eachLike({
              id: uuid(),
              email: string(),
              name: string(),
            }),
            pagination: like({
              page: 1,
              limit: 10,
              total: 100,
              totalPages: 10,
            }),
          },
        },
      });

      const result = await client.getUsers({ page: 1, limit: 10 }, 'admin-token');

      expect(result.data).toBeInstanceOf(Array);
      expect(result.pagination).toHaveProperty('total');
    });
  });

  describe('POST /api/users', () => {
    it('should create new user', async () => {
      const newUser = {
        email: 'new@example.com',
        name: 'New User',
        password: 'SecurePass123!',
      };

      await provider.addInteraction({
        states: [{ description: 'email new@example.com is not taken' }],
        uponReceiving: 'a request to create user',
        withRequest: {
          method: 'POST',
          path: '/api/users',
          headers: {
            'Content-Type': 'application/json',
          },
          body: newUser,
        },
        willRespondWith: {
          status: 201,
          headers: {
            'Content-Type': 'application/json',
          },
          body: like({
            id: uuid(),
            email: 'new@example.com',
            name: 'New User',
            createdAt: string(),
          }),
        },
      });

      const user = await client.createUser(newUser);

      expect(user.email).toBe('new@example.com');
      expect(user).not.toHaveProperty('password');
    });
  });
});
```

## Provider 검증

```typescript
// pact/provider/users-service.verify.ts
import { Verifier } from '@pact-foundation/pact';
import { describe, it, beforeAll, afterAll } from 'vitest';
import { app } from '@/app';
import { db } from '@/lib/db';
import { users } from '@/db/schema';

describe('Users Service Provider Verification', () => {
  let server: any;
  const port = 3001;

  beforeAll(async () => {
    server = app.listen(port);
  });

  afterAll(async () => {
    server.close();
  });

  it('should validate against consumer contracts', async () => {
    const verifier = new Verifier({
      provider: 'users-service',
      providerBaseUrl: `http://localhost:${port}`,

      // Pact Broker 설정
      pactBrokerUrl: process.env.PACT_BROKER_URL,
      pactBrokerToken: process.env.PACT_BROKER_TOKEN,

      // 또는 로컬 파일
      // pactUrls: ['./pacts/frontend-app-users-service.json'],

      publishVerificationResult: process.env.CI === 'true',
      providerVersion: process.env.GIT_COMMIT || '1.0.0',

      // State handlers
      stateHandlers: {
        'user with ID 123 exists': async () => {
          await db.insert(users).values({
            id: '123',
            email: 'user@example.com',
            name: 'John Doe',
            passwordHash: 'hashed',
            role: 'user',
          }).onConflictDoNothing();
        },

        'user with ID 999 does not exist': async () => {
          await db.delete(users).where(eq(users.id, '999'));
        },

        'users exist in database': async () => {
          await db.insert(users).values([
            { id: '1', email: 'user1@example.com', name: 'User 1', passwordHash: 'hash' },
            { id: '2', email: 'user2@example.com', name: 'User 2', passwordHash: 'hash' },
          ]).onConflictDoNothing();
        },

        'email new@example.com is not taken': async () => {
          await db.delete(users).where(eq(users.email, 'new@example.com'));
        },
      },

      // Request filter (인증 처리)
      requestFilter: (req, res, next) => {
        if (req.headers.authorization === 'Bearer valid-token') {
          req.user = { userId: '123', role: 'user' };
        } else if (req.headers.authorization === 'Bearer admin-token') {
          req.user = { userId: 'admin', role: 'admin' };
        }
        next();
      },
    });

    await verifier.verifyProvider();
  });
});
```

## Pact Broker 설정

### Docker Compose
```yaml
# docker-compose.pact.yml
version: '3.8'

services:
  pact-broker:
    image: pactfoundation/pact-broker:latest
    ports:
      - "9292:9292"
    environment:
      PACT_BROKER_DATABASE_URL: postgres://postgres:postgres@postgres/pact_broker
      PACT_BROKER_BASIC_AUTH_USERNAME: admin
      PACT_BROKER_BASIC_AUTH_PASSWORD: admin
    depends_on:
      - postgres

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: pact_broker
    volumes:
      - pact-db:/var/lib/postgresql/data

volumes:
  pact-db:
```

### 계약 발행 스크립트
```typescript
// scripts/publish-pacts.ts
import { Publisher } from '@pact-foundation/pact';
import path from 'path';

async function publishPacts() {
  const publisher = new Publisher({
    pactBroker: process.env.PACT_BROKER_URL!,
    pactBrokerToken: process.env.PACT_BROKER_TOKEN,
    pactFilesOrDirs: [path.resolve(process.cwd(), 'pacts')],
    consumerVersion: process.env.GIT_COMMIT || '1.0.0',
    tags: [process.env.GIT_BRANCH || 'main'],
  });

  await publisher.publishPacts();
  console.log('Pacts published successfully');
}

publishPacts();
```

## Can-I-Deploy

```typescript
// scripts/can-i-deploy.ts
import { CanDeploy } from '@pact-foundation/pact';

async function canIDeploy() {
  const canDeploy = new CanDeploy({
    pactBroker: process.env.PACT_BROKER_URL!,
    pactBrokerToken: process.env.PACT_BROKER_TOKEN,
    pacticipant: process.env.SERVICE_NAME!,
    version: process.env.GIT_COMMIT!,
    to: process.env.DEPLOY_ENV || 'production',
  });

  try {
    const result = await canDeploy.canDeploy();
    console.log('Can deploy:', result.ok);

    if (!result.ok) {
      console.error('Deployment blocked:');
      result.messages.forEach((msg) => console.error(`  - ${msg}`));
      process.exit(1);
    }
  } catch (error) {
    console.error('Can-I-Deploy check failed:', error);
    process.exit(1);
  }
}

canIDeploy();
```

## CI/CD 통합

```yaml
# .github/workflows/contract-tests.yml
name: Contract Tests

on:
  push:
    branches: [main, develop]
  pull_request:

jobs:
  consumer-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run consumer contract tests
        run: npm run test:contract:consumer

      - name: Publish pacts
        if: github.ref == 'refs/heads/main'
        run: npm run pact:publish
        env:
          PACT_BROKER_URL: ${{ secrets.PACT_BROKER_URL }}
          PACT_BROKER_TOKEN: ${{ secrets.PACT_BROKER_TOKEN }}
          GIT_COMMIT: ${{ github.sha }}
          GIT_BRANCH: ${{ github.ref_name }}

  provider-verification:
    runs-on: ubuntu-latest
    needs: consumer-tests
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Start test database
        run: docker-compose -f docker-compose.test.yml up -d

      - name: Verify provider
        run: npm run test:contract:provider
        env:
          PACT_BROKER_URL: ${{ secrets.PACT_BROKER_URL }}
          PACT_BROKER_TOKEN: ${{ secrets.PACT_BROKER_TOKEN }}
          GIT_COMMIT: ${{ github.sha }}
          CI: true

  can-i-deploy:
    runs-on: ubuntu-latest
    needs: provider-verification
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Can I Deploy?
        run: |
          npm run pact:can-i-deploy
        env:
          PACT_BROKER_URL: ${{ secrets.PACT_BROKER_URL }}
          PACT_BROKER_TOKEN: ${{ secrets.PACT_BROKER_TOKEN }}
          SERVICE_NAME: users-service
          GIT_COMMIT: ${{ github.sha }}
          DEPLOY_ENV: production
```

## 사용 예시
**입력**: "마이크로서비스 간 API 계약 테스트 설정해줘"

**출력**:
1. Consumer 계약 테스트
2. Provider 검증 설정
3. Pact Broker 설정
4. CI/CD 파이프라인
