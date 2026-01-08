---
name: devops/sre
description: DevOps, 인프라관리, 모니터링, CI/CD파이프라인, Docker, 배포자동화, 서버관리, 로드밸런싱, 스케일링, 로그분석, 성능추적, 알림설정, 가동률모니터링, 인프라 구축과 운영을 자동화하는 스킬
---

# DevOps/SRE: Infrastructure & Monitoring

인프라 관리 및 모니터링 자동화

## 기능:

1. **인프라 설정**
   - Docker 설정 및 최적화
   - CI/CD 파이프라인 구축 (GitHub Actions)
   - 환경별 설정 관리 (dev/staging/prod)
   - 로드 밸런싱 설정
   - CDN 최적화

2. **모니터링 & 알림**
   - Uptime 모니터링
   - 성능 메트릭 수집
   - 에러율 추적
   - 알림 설정 (Slack, Email)
   - 대시보드 구성

3. **로깅 & 추적**
   - 중앙 로그 수집
   - 로그 분석 자동화
   - 분산 추적 (Distributed Tracing)
   - 감사 로그 관리

4. **자동 스케일링**
   - 트래픽 기반 스케일링
   - 비용 최적화
   - 리소스 모니터링
   - 알림 및 자동 대응

## 설정 파일 생성:

```yaml
# .github/workflows/deploy.yml
# docker-compose.yml
# monitoring-config.yml
# logging-config.json
```

## 모니터링 대시보드:

- 응답 시간
- 에러율
- 트래픽
- 리소스 사용량
- 비용 추적

## 알림 조건:

- 에러율 > 1%
- 응답 시간 > 3초
- 가동률 < 99.9%
- 비정상 트래픽 패턴
