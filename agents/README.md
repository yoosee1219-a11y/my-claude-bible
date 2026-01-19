# Agents

자율 실행 에이전트 모음입니다. 스킬이 지식/패턴을 제공한다면, 에이전트는 자동으로 프로젝트를 스캐폴딩하고 설정합니다.

## 구조

```
agents/
├── config.json           # 에이전트 등록 및 오케스트레이션 설정
├── frontend/
│   └── hotwire-native.md # Hotwire Native 프로젝트 에이전트
└── README.md
```

## 에이전트 목록

### Frontend

| 에이전트 | 설명 | 트리거 |
|----------|------|--------|
| `hotwire-native` | Rails + iOS/Android 프로젝트 자동 생성 | "Hotwire Native", "Rails 앱", "모바일 앱" |

## 사용 방법

### 1. 직접 호출
```
"Hotwire Native로 todo 앱 만들어줘"
→ hotwire-native 에이전트 자동 활성화
```

### 2. 오케스트레이터 통합
```
"실시간 채팅이 있는 Hotwire Native 앱 만들어줘"
→ hotwire-native + realtime-services 에이전트 조합 실행
```

## config.json 구조

```json
{
  "categories": {
    "frontend": {
      "agents": ["ui-component", "ui-state", "hotwire-native", ...]
    }
  },
  "orchestration": {
    "defaultWaves": {
      "design": [...],
      "implement": [...],
      "quality": [...],
      "deploy": [...]
    }
  }
}
```

## 설치 방법

```bash
# 에이전트 파일 복사
cp -r agents/* ~/.claude/agents/
```

## 관련 스킬

에이전트는 해당 스킬의 지식을 참조합니다:
- `hotwire-native` 에이전트 → `skills/hotwire-native-framework/` 스킬
