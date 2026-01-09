# Microservices Architecture

> 모놀리스에서 마이크로서비스로: API Gateway, Service Mesh로 확장 가능한 아키텍처 구축 (2026)

## 목차

1. [마이크로서비스가 왜 필요한가?](#마이크로서비스가-왜-필요한가)
2. [API Gateway 패턴](#api-gateway-패턴)
3. [Service Mesh](#service-mesh)
4. [실전 사례](#실전-사례)

---

## 마이크로서비스가 왜 필요한가?

### 모놀리스의 문제점

**배포 지옥** 🔥
- 한 줄 수정 → 전체 앱 재배포
- 배포 시간: 30분+
- 장애 영향 범위: 전체 시스템

**스케일링 비효율**
- CPU 집약적인 결제 모듈 때문에 전체 앱 스케일업
- 비용 낭비: 300%

### 마이크로서비스의 이점

**독립 배포** 🚀
- 서비스별 독립 배포
- 배포 시간: 5분
- 장애 격리: 영향 범위 최소화

**선택적 스케일링** 💰
- 결제 서비스만 3배 확장
- 나머지는 1배 유지
- 비용 절감: 60%

---

## API Gateway 패턴

### API Gateway란?

외부 클라이언트의 **단일 진입점**(Single Entry Point)
- 라우팅, 인증, Rate Limiting
- 응답 집계
- 프로토콜 변환

### Next.js API Routes를 Gateway로 사용

```typescript
// app/api/gateway/[...path]/route.ts
import { NextRequest, NextResponse } from 'next/server';

const SERVICES = {
  users: process.env.USER_SERVICE_URL,
  orders: process.env.ORDER_SERVICE_URL,
  payments: process.env.PAYMENT_SERVICE_URL,
};

export async function GET(req: NextRequest, { params }: { params: { path: string[] } }) {
  const [service, ...rest] = params.path;

  // 1. 인증 체크
  const token = req.headers.get('Authorization');
  if (!token) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  // 2. Rate Limiting (예시)
  // const rateLimitOk = await checkRateLimit(req.ip);
  // if (!rateLimitOk) return NextResponse.json({ error: 'Too many requests' }, { status: 429 });

  // 3. 라우팅
  const serviceUrl = SERVICES[service as keyof typeof SERVICES];
  if (!serviceUrl) {
    return NextResponse.json({ error: 'Service not found' }, { status: 404 });
  }

  // 4. 프록시
  const response = await fetch(`${serviceUrl}/${rest.join('/')}`, {
    headers: { Authorization: token },
  });

  return NextResponse.json(await response.json());
}
```

### Kong API Gateway (프로덕션)

```yaml
# docker-compose.yml
version: '3.8'
services:
  kong:
    image: kong:latest
    environment:
      KONG_DATABASE: postgres
      KONG_PG_HOST: kong-database
    ports:
      - "8000:8000"  # Proxy
      - "8001:8001"  # Admin API

  kong-database:
    image: postgres:15
    environment:
      POSTGRES_USER: kong
      POSTGRES_DB: kong
```

**서비스 등록:**
```bash
# 1. 서비스 추가
curl -i -X POST http://localhost:8001/services \
  --data name=user-service \
  --data url=http://user-service:3000

# 2. 라우트 추가
curl -i -X POST http://localhost:8001/services/user-service/routes \
  --data 'paths[]=/users'

# 3. Rate Limiting 플러그인
curl -i -X POST http://localhost:8001/services/user-service/plugins \
  --data name=rate-limiting \
  --data config.minute=100
```

---

## Service Mesh

### Service Mesh vs API Gateway

| 항목 | API Gateway | Service Mesh |
|------|-------------|--------------|
| 트래픽 | North-South (외부→내부) | East-West (서비스간) |
| 위치 | 경계 (Edge) | 내부 (Sidecar) |
| 기능 | 인증, Rate Limit, 변환 | 로드밸런싱, 재시도, Circuit Breaker |
| 예시 | Kong, Traefik | Istio, Linkerd |

### Istio 기본 설정

```yaml
# service-mesh/virtual-service.yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: user-service
spec:
  hosts:
  - user-service
  http:
  - match:
    - headers:
        version:
          exact: v2
    route:
    - destination:
        host: user-service
        subset: v2
      weight: 20  # Canary 배포: 20% 트래픽
  - route:
    - destination:
        host: user-service
        subset: v1
      weight: 80
---
# Destination Rule (Circuit Breaker)
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: user-service
spec:
  host: user-service
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 50
        maxRequestsPerConnection: 2
    outlierDetection:
      consecutiveErrors: 5
      interval: 30s
      baseEjectionTime: 30s
```

**적용:**
```bash
kubectl apply -f service-mesh/virtual-service.yaml
```

---

## 실전 사례

### 사례: E-커머스 모놀리스 → 마이크로서비스

**Before (모놀리스)**
```
- 단일 Rails 앱: 500K LOC
- 배포: 월 1회 (위험 부담)
- 스케일링: 전체 앱 10대
- 비용: $15,000/월
```

**After (마이크로서비스 + Istio)**
```
- 12개 서비스 (Node.js, Go, Python)
- 배포: 일 10회+ (서비스별 독립)
- 스케일링: 결제 5대, 나머지 2대
- 비용: $6,000/월 (60% 절감)

장점:
- 배포 시간: 2시간 → 5분
- 신기능 출시: 월 1개 → 주 3개
- 장애 영향: 100% → 8%(한 서비스만)
```

**ROI:** 연간 $108,000 절감, 매출 40% 증가

---

## 체크리스트

- [ ] 모놀리스 경계 식별 (Bounded Context)
- [ ] API Gateway 선택 (Kong, Traefik, AWS API Gateway)
- [ ] 서비스 간 통신 프로토콜 (REST, gRPC)
- [ ] Service Mesh 도입 검토 (20+ 서비스)
- [ ] Circuit Breaker 패턴 구현
- [ ] 분산 추적 (Jaeger, Zipkin)
- [ ] 중앙 로깅 (ELK Stack)

---

## 참고 자료

- [Service Mesh vs API Gateway](https://www.solo.io/topics/istio/service-mesh-vs-api-gateway)
- [API Gateway 2026 Guide](https://www.digitalapi.ai/blogs/api-gateway-framework-the-complete-2026-guide-for-modern-microservices)
- [Istio Documentation](https://istio.io/latest/docs/)

---

**마이크로서비스 아키텍처로 확장성과 안정성을 동시에! 🚀**
