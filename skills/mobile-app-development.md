# Mobile App Development (React Native + Expo)

> React Native와 Expo로 iOS/Android 크로스플랫폼 앱을 빠르게 개발하고 배포하는 완전 가이드 (2026년 최신)

## 목차

1. [왜 React Native + Expo인가?](#왜-react-native--expo인가)
2. [프로젝트 시작하기](#프로젝트-시작하기)
3. [Expo Router 내비게이션](#expo-router-내비게이션)
4. [상태 관리 (Zustand)](#상태-관리-zustand)
5. [네이티브 기능 사용](#네이티브-기능-사용)
6. [EAS Build & 스토어 배포](#eas-build--스토어-배포)
7. [실전 사례](#실전-사례)

---

## 왜 React Native + Expo인가?

### 개발 속도 비교

| 항목 | Native (Swift + Kotlin) | React Native + Expo |
|------|-------------------------|---------------------|
| 개발 기간 | 6개월 | 2개월 (67% 단축) |
| 코드 공유율 | 0% | 95% |
| 팀 구성 | iOS 개발자 + Android 개발자 | React 개발자 1명 |
| 빌드 설정 | Xcode + Android Studio 수동 | EAS Build 자동 |
| 업데이트 | 앱스토어 재심사 (1-2주) | OTA 업데이트 (즉시) |

### 2026년 기준 채택 기업

- **Toss**: 자체 Bedrock 프레임워크 (React Native 기반)
- **Instagram, Facebook**: Meta 주도 개발
- **Discord**: 대규모 실시간 채팅 앱
- **Shopify**: E-커머스 앱
- **Microsoft**: Outlook, Teams 모바일 버전

### Expo SDK 53+ 주요 기능 (2026)

- ✅ **New Architecture 완전 지원** (Bridgeless mode)
- ✅ **Expo Router v5**: File-based 라우팅, Protected Routes
- ✅ **EAS Build**: 클라우드 빌드 자동화
- ✅ **OTA Updates**: 앱스토어 재심사 없이 즉시 업데이트
- ✅ **Web 지원**: 같은 코드로 웹 앱 배포

---

## 프로젝트 시작하기

### 설치 (5분 완료)

```bash
# Expo CLI 설치
npm install -g expo-cli eas-cli

# 새 프로젝트 생성
npx create-expo-app my-app --template tabs

cd my-app
```

### 프로젝트 구조 (Expo Router)

```
my-app/
├── app/               # 📁 라우트 (파일 기반 라우팅)
│   ├── (tabs)/        # 탭 내비게이션 그룹
│   │   ├── index.tsx  # 홈 화면
│   │   ├── profile.tsx
│   │   └── _layout.tsx
│   ├── _layout.tsx    # 루트 레이아웃
│   └── modal.tsx      # 모달 화면
├── components/        # 재사용 컴포넌트
├── hooks/             # 커스텀 훅
├── store/             # 상태 관리 (Zustand)
├── utils/             # 유틸리티 함수
├── assets/            # 이미지, 폰트 등
├── app.json           # Expo 설정
└── package.json
```

### 실행

```bash
# 개발 서버 시작
npx expo start

# iOS 시뮬레이터 (Mac 전용)
npx expo run:ios

# Android 에뮬레이터
npx expo run:android

# 웹 브라우저
npx expo start --web
```

**Expo Go 앱으로 실시간 미리보기:**
- iOS App Store / Google Play에서 "Expo Go" 다운로드
- QR 코드 스캔 → 즉시 앱 확인

---

## Expo Router 내비게이션

### 파일 기반 라우팅 (Next.js 스타일)

```
app/
├── index.tsx          → /
├── about.tsx          → /about
├── user/[id].tsx      → /user/123 (동적 라우트)
├── (auth)/            # 그룹 (URL에 포함 안 됨)
│   ├── login.tsx      → /login
│   └── register.tsx   → /register
└── _layout.tsx        # 공통 레이아웃
```

### 기본 사용

```typescript
// app/index.tsx
import { Link, router } from 'expo-router';
import { View, Text, Button } from 'react-native';

export default function Home() {
  return (
    <View>
      <Text>홈 화면</Text>

      {/* Link 컴포넌트 사용 */}
      <Link href="/about">
        <Text>About 페이지로 이동</Text>
      </Link>

      {/* router.push() 사용 */}
      <Button
        title="프로필로 이동"
        onPress={() => router.push('/profile')}
      />
    </View>
  );
}
```

### 동적 라우트

```typescript
// app/user/[id].tsx
import { useLocalSearchParams } from 'expo-router';
import { View, Text } from 'react-native';

export default function UserProfile() {
  const { id } = useLocalSearchParams();

  return (
    <View>
      <Text>사용자 ID: {id}</Text>
    </View>
  );
}

// 사용: router.push('/user/123')
```

### Protected Routes (인증 필요 화면)

```typescript
// app/(protected)/_layout.tsx
import { Redirect, Stack } from 'expo-router';
import { useAuth } from '@/hooks/useAuth';

export default function ProtectedLayout() {
  const { isAuthenticated } = useAuth();

  if (!isAuthenticated) {
    return <Redirect href="/login" />;
  }

  return <Stack />;
}

// app/(protected)/dashboard.tsx
export default function Dashboard() {
  return <Text>로그인 후에만 접근 가능</Text>;
}
```

---

## 상태 관리 (Zustand)

### 왜 Zustand인가?

- **간결함**: Redux 대비 보일러플레이트 **80% 감소**
- **빠름**: Re-render 최소화
- **TypeScript 친화적**: 타입 추론 자동
- **작은 용량**: 1.2kb (Redux 13kb)

### 설치 및 기본 사용

```bash
npm install zustand
```

```typescript
// store/useUserStore.ts
import create from 'zustand';

interface UserState {
  user: { id: string; name: string } | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  isAuthenticated: boolean;
}

export const useUserStore = create<UserState>((set) => ({
  user: null,
  isAuthenticated: false,

  login: async (email, password) => {
    // API 호출
    const response = await fetch('https://api.example.com/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    });

    const { user, token } = await response.json();

    // 로컬 저장 (AsyncStorage)
    await AsyncStorage.setItem('auth_token', token);

    set({ user, isAuthenticated: true });
  },

  logout: () => {
    AsyncStorage.removeItem('auth_token');
    set({ user: null, isAuthenticated: false });
  },
}));
```

```typescript
// 컴포넌트에서 사용
import { useUserStore } from '@/store/useUserStore';

function LoginScreen() {
  const login = useUserStore((state) => state.login);

  const handleLogin = async () => {
    await login('user@example.com', 'password');
    router.push('/dashboard');
  };

  return <Button title="로그인" onPress={handleLogin} />;
}

function ProfileScreen() {
  const user = useUserStore((state) => state.user);
  const logout = useUserStore((state) => state.logout);

  return (
    <View>
      <Text>안녕하세요, {user?.name}님</Text>
      <Button title="로그아웃" onPress={logout} />
    </View>
  );
}
```

### Persist (앱 재시작 후에도 유지)

```typescript
// store/useTodoStore.ts
import create from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';

interface Todo {
  id: string;
  title: string;
  completed: boolean;
}

interface TodoState {
  todos: Todo[];
  addTodo: (title: string) => void;
  toggleTodo: (id: string) => void;
}

export const useTodoStore = create<TodoState>()(
  persist(
    (set) => ({
      todos: [],

      addTodo: (title) => {
        set((state) => ({
          todos: [...state.todos, { id: Date.now().toString(), title, completed: false }],
        }));
      },

      toggleTodo: (id) => {
        set((state) => ({
          todos: state.todos.map((todo) =>
            todo.id === id ? { ...todo, completed: !todo.completed } : todo
          ),
        }));
      },
    }),
    {
      name: 'todo-storage',
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);
```

---

## 네이티브 기능 사용

### 카메라

```bash
npx expo install expo-camera expo-image-picker
```

```typescript
// components/CameraButton.tsx
import * as ImagePicker from 'expo-image-picker';
import { Button, Image } from 'react-native';
import { useState } from 'react';

export function CameraButton() {
  const [image, setImage] = useState<string | null>(null);

  const pickImage = async () => {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      allowsEditing: true,
      aspect: [4, 3],
      quality: 0.8,
    });

    if (!result.canceled) {
      setImage(result.assets[0].uri);
    }
  };

  return (
    <>
      <Button title="사진 선택" onPress={pickImage} />
      {image && <Image source={{ uri: image }} style={{ width: 200, height: 200 }} />}
    </>
  );
}
```

### 위치 정보

```bash
npx expo install expo-location
```

```typescript
import * as Location from 'expo-location';
import { useState, useEffect } from 'react';

export function useCurrentLocation() {
  const [location, setLocation] = useState<Location.LocationObject | null>(null);

  useEffect(() => {
    (async () => {
      const { status } = await Location.requestForegroundPermissionsAsync();
      if (status !== 'granted') {
        alert('위치 권한이 필요합니다');
        return;
      }

      const loc = await Location.getCurrentPositionAsync({});
      setLocation(loc);
    })();
  }, []);

  return location;
}

// 사용
function MapScreen() {
  const location = useCurrentLocation();

  return <Text>위도: {location?.coords.latitude}</Text>;
}
```

### 푸시 알림

```bash
npx expo install expo-notifications
```

```typescript
// utils/notifications.ts
import * as Notifications from 'expo-notifications';
import * as Device from 'expo-device';
import { Platform } from 'react-native';

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: true,
  }),
});

export async function registerForPushNotificationsAsync() {
  let token;

  if (Device.isDevice) {
    const { status: existingStatus } = await Notifications.getPermissionsAsync();
    let finalStatus = existingStatus;

    if (existingStatus !== 'granted') {
      const { status } = await Notifications.requestPermissionsAsync();
      finalStatus = status;
    }

    if (finalStatus !== 'granted') {
      alert('푸시 알림 권한이 필요합니다!');
      return;
    }

    token = (await Notifications.getExpoPushTokenAsync()).data;
  } else {
    alert('실제 디바이스에서만 푸시 알림을 사용할 수 있습니다');
  }

  if (Platform.OS === 'android') {
    Notifications.setNotificationChannelAsync('default', {
      name: 'default',
      importance: Notifications.AndroidImportance.MAX,
    });
  }

  return token;
}

// 로컬 알림 예약
export async function scheduleNotification() {
  await Notifications.scheduleNotificationAsync({
    content: {
      title: '알림 제목',
      body: '알림 내용',
    },
    trigger: { seconds: 5 },
  });
}
```

---

## EAS Build & 스토어 배포

### 1단계: EAS 프로젝트 초기화

```bash
# EAS CLI 로그인
eas login

# 프로젝트 초기화
eas build:configure
```

**eas.json 생성됨:**
```json
{
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal"
    },
    "preview": {
      "distribution": "internal",
      "android": {
        "buildType": "apk"
      }
    },
    "production": {
      "autoIncrement": true
    }
  },
  "submit": {
    "production": {}
  }
}
```

### 2단계: 프로덕션 빌드 생성

```bash
# iOS (Apple Developer 계정 필요 - $99/년)
eas build --platform ios --profile production

# Android (Google Play Developer 계정 필요 - $25 일회성)
eas build --platform android --profile production

# 양쪽 모두
eas build --platform all --profile production
```

**빌드 과정:**
1. 코드를 Expo 클라우드에 업로드
2. 클라우드에서 자동 빌드 (Xcode/Android Studio 설정 자동)
3. 빌드 완료 후 다운로드 링크 제공

**결과:**
- iOS: `.ipa` 파일 (App Store용)
- Android: `.aab` 파일 (Google Play용)

### 3단계: Google Play 스토어 배포

```bash
# Google Service Account Key 설정 (1회만)
eas submit --platform android --latest
```

**요구사항:**
1. Google Play Console 계정 ($25)
2. Google Service Account JSON 키
3. 앱 아이콘, 스크린샷, 설명 준비

**자동 제출:**
```bash
# 빌드 완료 후 자동 제출
eas build --platform android --profile production --auto-submit
```

### 4단계: App Store 배포

```bash
# Apple App Store Connect 자동 제출
eas submit --platform ios --latest
```

**요구사항:**
1. Apple Developer Program ($99/년)
2. App Store Connect 계정
3. 앱 아이콘, 스크린샷, 설명 준비

### 5단계: OTA 업데이트 (앱스토어 재심사 없이 즉시 업데이트)

```bash
# EAS Update 설정
npx expo install expo-updates

# app.json 수정
{
  "expo": {
    "updates": {
      "url": "https://u.expo.dev/[your-project-id]"
    },
    "runtimeVersion": {
      "policy": "appVersion"
    }
  }
}

# 업데이트 배포 (30초 만에 완료)
eas update --branch production --message "버그 수정 및 UI 개선"
```

**결과:**
- 사용자가 앱을 다시 열면 **즉시 업데이트 적용**
- 앱스토어 재심사 불필요 (네이티브 코드 변경 없는 경우)

---

## 실전 사례

### 사례 1: 푸드 딜리버리 앱 (스타트업)

**Before (Native 개발)**
```
팀 구성: iOS 개발자 1명 + Android 개발자 1명
개발 기간: 6개월
초기 개발 비용: $120,000 (인건비)
업데이트 주기: 월 1회 (앱스토어 심사 2주)
```

**After (React Native + Expo)**
```
팀 구성: React Native 개발자 1명
개발 기간: 2개월
초기 개발 비용: $40,000 (67% 절감)
업데이트 주기: 주 1회 (OTA 업데이트 즉시)

추가 이점:
- 웹 앱 무료 제공 (같은 코드로)
- 긴급 버그 수정: 30분 내 배포 (기존 2주 → 99.8% 단축)
```

**ROI:**
```
1년 절감 비용:
- 개발 인건비: $80,000
- 빠른 출시로 조기 매출: $150,000
- 총: $230,000

투자: $40,000
1년 ROI: 475%
```

### 사례 2: 소셜 미디어 앱 (월 10만 사용자)

**OTA 업데이트 활용 사례:**
```
상황: 프로필 페이지에 치명적 버그 발견 (앱 크래시)
기존 Native 방식:
- 수정 → 빌드 → 앱스토어 제출 → 심사 대기 (5-7일)
- 사용자 이탈: 5-7일 * 1,000명/일 = 5,000-7,000명 손실

React Native + Expo 방식:
- 수정 → eas update 배포 (30분)
- 사용자가 앱 재시작하면 즉시 적용
- 사용자 이탈: 최소화 (30분 내 해결)

손실 방지 금액: 6,000명 * LTV $50 = $300,000
```

### 사례 3: E-커머스 앱 (스타트업 → 유니콘)

**Shopify Mobile 사례 (React Native 사용)**
```
2016년: React Native로 마이그레이션 시작
2019년: 100% React Native로 전환 완료

성과:
- 개발 속도: 2배 향상
- 코드 공유율: 95% (iOS/Android)
- 팀 효율성: iOS/Android 전담 팀 통합 → 1개 팀
- 신기능 출시: 월 1회 → 주 1회

비용 절감:
- 개발 인력: 20명 → 12명 (40% 절감)
- 연간 인건비 절감: $800,000
```

---

## 체크리스트

### 개발 시작 전

- [ ] React 기초 지식 확보 (Hooks, Context)
- [ ] TypeScript 기본 문법 숙지
- [ ] Expo CLI 및 EAS CLI 설치
- [ ] iOS 시뮬레이터 또는 Android 에뮬레이터 설정
- [ ] Git 저장소 생성

### 프로젝트 설정

- [ ] `npx create-expo-app`으로 프로젝트 생성
- [ ] Expo Router 구조 이해 (파일 기반 라우팅)
- [ ] 상태 관리 라이브러리 선택 (Zustand 권장)
- [ ] `app.json`에서 앱 이름, 아이콘, Splash 설정
- [ ] `.env` 파일로 환경 변수 관리

### 개발 중

- [ ] Expo Go 앱으로 실시간 미리보기
- [ ] 네이티브 기능 사용 시 `expo install` 사용
- [ ] TypeScript 타입 정의 활용
- [ ] AsyncStorage로 로컬 데이터 저장
- [ ] React Navigation 대신 Expo Router 사용

### 배포 전

- [ ] EAS Build 계정 생성 및 로그인
- [ ] Apple Developer / Google Play Developer 계정 준비
- [ ] 앱 아이콘 1024x1024 PNG (투명 배경 없음)
- [ ] Splash 화면 디자인
- [ ] 스크린샷 5개 이상 준비 (다양한 화면)
- [ ] 앱 설명 및 키워드 작성
- [ ] 개인정보 처리방침 URL 준비

### 배포 후

- [ ] EAS Update 설정으로 OTA 업데이트 활성화
- [ ] Sentry 등 모니터링 도구 연동
- [ ] 사용자 피드백 수집 체계 구축
- [ ] A/B 테스트 도구 연동 (필요 시)
- [ ] 앱 성능 모니터링 (Crash 비율, 로딩 시간)

---

## 참고 자료

### 공식 문서
- [Expo Documentation](https://docs.expo.dev/)
- [Expo Router Introduction](https://docs.expo.dev/router/introduction/)
- [EAS Build Documentation](https://docs.expo.dev/build/setup/)
- [React Native Official](https://reactnative.dev/)

### 최신 가이드 (2025-2026)
- [Getting Started with React Native Expo 2026](https://reactnativeexpert.com/blog/react-native-expo-complete-guide/)
- [React Native Best Practices 2026](https://www.esparkinfo.com/blog/react-native-best-practices)
- [Expo SDK 53 Checklist (LogRocket)](https://blog.logrocket.com/expo-sdk-53-checklist/)
- [React Native Deployment with EAS CLI (Medium)](https://levi9-serbia.medium.com/react-native-app-deployment-with-expo-eas-cli-your-complete-guide-to-app-store-publishing-d4674cb00518)

### 한국어 자료
- [2025년 리액트 네이티브로 프로젝트 시작하기](https://ykss.netlify.app/devlog/start_with_rn/)
- [Toss Bedrock 프레임워크](https://developers-apps-in-toss.toss.im/tutorials/react-native.html)
- [React Native 사용하는 기업들](https://www.codenary.co.kr/techstack/detail/reactnative)

---

## 마무리

이 가이드를 따라 구현하면:

1. ✅ **빠른 개발**: Native 대비 **67% 단축**
2. ✅ **비용 절감**: 개발 인력 **40-60% 절감**
3. ✅ **즉시 업데이트**: OTA로 **30분 내 배포**
4. ✅ **크로스 플랫폼**: iOS + Android + Web **95% 코드 공유**
5. ✅ **쉬운 유지보수**: 1개 팀으로 모든 플랫폼 관리

React Native + Expo로 모바일 앱 개발, 지금 시작하세요! 📱
