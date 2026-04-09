---
name: ai-status
description: "Multi-AI 환경 상태를 한눈에 확인합니다. Claude, GPT-4o, Gemini의 가용 상태를 점검합니다."
category: multi-ai
complexity: basic
mcp-servers: [openai-bridge, gemini-bridge]
---

# /ai-status - Multi-AI 상태 확인

당신은 현재 Multi-AI 환경의 상태를 점검하는 도구입니다.

## 실행 절차

1. `openai-bridge`의 `check_status` 도구를 호출합니다 (병렬)
2. `gemini-bridge`의 `check_status` 도구를 호출합니다 (병렬)
3. Claude는 항상 사용 가능하므로 ✅로 표시합니다
4. 결과를 아래 형식으로 출력합니다

## 출력 형식

```
## 🤖 Multi-AI 상태

| AI | 상태 | 모델 | 용도 |
|------|------|------|------|
| Claude | ✅ 사용 가능 | opus-4-6 | 메인 추론/검증/최종 판단 |
| GPT-4o | {상태} | gpt-4o | 코드리뷰/Vision/대안 비교 |
| Gemini | {상태} | gemini-2.5-flash | Vision/코드리뷰/대안 비교 |

💡 **현재 모드**: {사용 가능한 AI 조합}
```

### 상태 값
- `✅ 사용 가능` — 정상
- `⚠️ 쿼타 초과` — Rate Limited (잠시 후 재시도)
- `🔑 인증 오류` — API 키 문제
- `❌ API 오류` — 기타 오류
- `🔌 연결 불가` — MCP 서버 연결 실패

### 현재 모드 표시
- 3개 모두 가능: `Claude + GPT-4o + Gemini (3-AI 풀 오케스트라)`
- 2개 가능: `Claude + {사용가능AI} (2-AI)`
- Claude만: `Claude 단독 모드 (외부 AI 사용 불가)`

### 추가 안내
- 쿼타 초과 시: `💡 무료 쿼타가 소진되었습니다. 잠시 후 다시 시도하거나 /ai-orchestra를 사용하면 자동 fallback됩니다.`
- 인증 오류 시: `💡 API 키를 확인하세요. 환경변수: OPENAI_API_KEY / GEMINI_API_KEY`

## 참고

check_status 호출이 실패해도(MCP 서버 미실행 등) 패닉하지 마세요.
해당 AI를 `🔌 연결 불가`로 표시하고 나머지 결과를 보여주세요.
