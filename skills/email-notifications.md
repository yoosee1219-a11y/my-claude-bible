# Email & Notifications

> Resend, React Email, Firebase로 이메일, 푸시 알림, SMS 완벽 구현 가이드 (2026)

## 목차

1. [알림이 왜 중요한가?](#알림이-왜-중요한가)
2. [Email (Resend + React Email)](#email-resend--react-email)
3. [Push Notifications (Firebase)](#push-notifications-firebase)
4. [SMS (Twilio)](#sms-twilio)
5. [알림 큐 (BullMQ)](#알림-큐-bullmq)
6. [실전 사례](#실전-사례)

---

## 알림이 왜 중요한가?

### 사용자 참여도 향상

**통계 (2026):**
- 이메일 오픈율: 21.5%
- 푸시 알림 오픈율: 7.8%
- SMS 오픈율: 98%
- 이메일 클릭률: 2.6%

**활용 사례:**
- 회원가입 환영 이메일
- 비밀번호 재설정
- 주문 확인/배송 알림
- 새 댓글/메시지 알림
- 프로모션 및 뉴스레터

---

## Email (Resend + React Email)

### 왜 Resend인가?

**Resend vs SendGrid:**
| 항목 | Resend | SendGrid |
|------|--------|----------|
| 가격 | $20/월 (50k 이메일) | $19.95/월 (50k 이메일) |
| DX | 우수 (React Email 내장) | 보통 (HTML 템플릿) |
| 전송 속도 | 빠름 | 빠름 |
| 무료 플랜 | 100/일 | 100/일 |
| 도메인 설정 | 쉬움 | 복잡 |

---

### 설치

```bash
npm install resend react-email @react-email/components
```

---

### React Email 템플릿

**emails/WelcomeEmail.tsx:**
```tsx
import {
  Body,
  Button,
  Container,
  Head,
  Heading,
  Html,
  Img,
  Link,
  Preview,
  Section,
  Text,
} from '@react-email/components';

interface WelcomeEmailProps {
  username: string;
  loginUrl: string;
}

export const WelcomeEmail = ({ username, loginUrl }: WelcomeEmailProps) => (
  <Html>
    <Head />
    <Preview>Welcome to MyApp - Get started today</Preview>
    <Body style={main}>
      <Container style={container}>
        <Img
          src="https://myapp.com/logo.png"
          width="48"
          height="48"
          alt="MyApp"
          style={logo}
        />

        <Heading style={heading}>Welcome to MyApp, {username}!</Heading>

        <Text style={paragraph}>
          Thanks for signing up! We're excited to have you on board.
        </Text>

        <Section style={buttonContainer}>
          <Button style={button} href={loginUrl}>
            Get Started
          </Button>
        </Section>

        <Text style={paragraph}>
          If you have any questions, feel free to{' '}
          <Link style={link} href="https://myapp.com/support">
            contact our support team
          </Link>
          .
        </Text>

        <Text style={footer}>
          © 2026 MyApp. All rights reserved.
          <br />
          123 Street, City, Country
        </Text>
      </Container>
    </Body>
  </Html>
);

// Styles
const main = {
  backgroundColor: '#f6f9fc',
  fontFamily:
    '-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,"Helvetica Neue",Ubuntu,sans-serif',
};

const container = {
  backgroundColor: '#ffffff',
  margin: '0 auto',
  padding: '20px 0 48px',
  marginBottom: '64px',
};

const logo = {
  margin: '0 auto',
};

const heading = {
  fontSize: '32px',
  lineHeight: '1.3',
  fontWeight: '700',
  color: '#484848',
  padding: '17px 0 0',
};

const paragraph = {
  fontSize: '18px',
  lineHeight: '1.4',
  color: '#484848',
};

const buttonContainer = {
  padding: '27px 0 27px',
};

const button = {
  backgroundColor: '#5469d4',
  borderRadius: '5px',
  color: '#fff',
  fontSize: '16px',
  fontWeight: 'bold',
  textDecoration: 'none',
  textAlign: 'center' as const,
  display: 'block',
  width: '100%',
  padding: '10px',
};

const link = {
  color: '#5469d4',
  textDecoration: 'underline',
};

const footer = {
  color: '#9ca299',
  fontSize: '14px',
  marginBottom: '10px',
};
```

---

### Resend API 사용 (Next.js)

**app/api/send-welcome-email/route.ts:**
```typescript
import { Resend } from 'resend';
import { WelcomeEmail } from '@/emails/WelcomeEmail';

const resend = new Resend(process.env.RESEND_API_KEY);

export async function POST(req: Request) {
  const { email, username } = await req.json();

  try {
    const { data, error } = await resend.emails.send({
      from: 'MyApp <onboarding@myapp.com>',
      to: email,
      subject: 'Welcome to MyApp!',
      react: WelcomeEmail({
        username,
        loginUrl: 'https://myapp.com/login',
      }),
    });

    if (error) {
      return Response.json({ error }, { status: 400 });
    }

    return Response.json({ success: true, id: data?.id });
  } catch (error) {
    return Response.json({ error: 'Failed to send email' }, { status: 500 });
  }
}
```

---

### 이메일 미리보기 (개발)

```bash
# 개발 서버 실행
npx react-email dev

# 브라우저에서 http://localhost:3000 접속
# 모든 이메일 템플릿 미리보기 가능
```

---

### Nodemailer (Self-hosted)

**설치:**
```bash
npm install nodemailer @react-email/render
```

**app/api/send-email/route.ts:**
```typescript
import nodemailer from 'nodemailer';
import { render } from '@react-email/render';
import { WelcomeEmail } from '@/emails/WelcomeEmail';

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: Number(process.env.SMTP_PORT),
  secure: true,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASSWORD,
  },
});

export async function POST(req: Request) {
  const { email, username } = await req.json();

  const emailHtml = render(
    WelcomeEmail({
      username,
      loginUrl: 'https://myapp.com/login',
    })
  );

  try {
    await transporter.sendMail({
      from: '"MyApp" <noreply@myapp.com>',
      to: email,
      subject: 'Welcome to MyApp!',
      html: emailHtml,
    });

    return Response.json({ success: true });
  } catch (error) {
    return Response.json({ error: 'Failed to send email' }, { status: 500 });
  }
}
```

---

## Push Notifications (Firebase)

### 설치

```bash
npm install firebase
```

---

### Firebase 설정

**lib/firebase.ts:**
```typescript
import { initializeApp } from 'firebase/app';
import { getMessaging, getToken, onMessage } from 'firebase/messaging';

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
};

const app = initializeApp(firebaseConfig);

// Messaging (클라이언트만)
export const messaging = typeof window !== 'undefined' ? getMessaging(app) : null;
```

---

### Service Worker

**public/firebase-messaging-sw.js:**
```javascript
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'YOUR_API_KEY',
  authDomain: 'YOUR_AUTH_DOMAIN',
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_STORAGE_BUCKET',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  appId: 'YOUR_APP_ID',
});

const messaging = firebase.messaging();

// 백그라운드 메시지 수신
messaging.onBackgroundMessage((payload) => {
  console.log('Background message:', payload);

  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icon.png',
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
```

---

### 푸시 알림 구독 (React)

**hooks/usePushNotifications.ts:**
```typescript
import { useEffect, useState } from 'react';
import { messaging } from '@/lib/firebase';
import { getToken, onMessage } from 'firebase/messaging';

export const usePushNotifications = () => {
  const [permission, setPermission] = useState<NotificationPermission>('default');
  const [token, setToken] = useState<string | null>(null);

  useEffect(() => {
    if (!messaging) return;

    // 권한 확인
    if (Notification.permission !== 'default') {
      setPermission(Notification.permission);
    }
  }, []);

  const requestPermission = async () => {
    if (!messaging) return;

    try {
      // 권한 요청
      const permission = await Notification.requestPermission();
      setPermission(permission);

      if (permission === 'granted') {
        // FCM 토큰 받기
        const currentToken = await getToken(messaging, {
          vapidKey: process.env.NEXT_PUBLIC_FIREBASE_VAPID_KEY,
        });

        if (currentToken) {
          setToken(currentToken);

          // 서버에 토큰 저장
          await fetch('/api/save-fcm-token', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ token: currentToken }),
          });

          console.log('FCM token:', currentToken);
        }
      }
    } catch (error) {
      console.error('Failed to get FCM token:', error);
    }
  };

  useEffect(() => {
    if (!messaging || permission !== 'granted') return;

    // 포그라운드 메시지 수신
    const unsubscribe = onMessage(messaging, (payload) => {
      console.log('Foreground message:', payload);

      // 브라우저 알림 표시
      new Notification(payload.notification?.title || 'Notification', {
        body: payload.notification?.body,
        icon: '/icon.png',
      });
    });

    return () => unsubscribe();
  }, [messaging, permission]);

  return {
    permission,
    token,
    requestPermission,
  };
};
```

---

**components/PushNotificationButton.tsx:**
```tsx
'use client';

import { usePushNotifications } from '@/hooks/usePushNotifications';

export function PushNotificationButton() {
  const { permission, requestPermission } = usePushNotifications();

  if (permission === 'granted') {
    return (
      <div className="flex items-center gap-2 text-green-600">
        <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
          <path d="M10 2a6 6 0 00-6 6v3.586l-.707.707A1 1 0 004 14h12a1 1 0 00.707-1.707L16 11.586V8a6 6 0 00-6-6zM10 18a3 3 0 01-3-3h6a3 3 0 01-3 3z" />
        </svg>
        <span>Notifications enabled</span>
      </div>
    );
  }

  if (permission === 'denied') {
    return (
      <div className="text-red-600">
        Notifications blocked. Please enable in browser settings.
      </div>
    );
  }

  return (
    <button
      onClick={requestPermission}
      className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600"
    >
      Enable Notifications
    </button>
  );
}
```

---

### 푸시 알림 전송 (서버)

**app/api/send-push/route.ts:**
```typescript
import admin from 'firebase-admin';

// Firebase Admin SDK 초기화
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    }),
  });
}

export async function POST(req: Request) {
  const { token, title, body, link } = await req.json();

  try {
    const message = {
      notification: {
        title,
        body,
      },
      data: {
        link,
      },
      token,
    };

    const response = await admin.messaging().send(message);

    return Response.json({ success: true, messageId: response });
  } catch (error) {
    console.error('FCM send error:', error);
    return Response.json({ error: 'Failed to send notification' }, { status: 500 });
  }
}
```

---

## SMS (Twilio)

### 설치

```bash
npm install twilio
```

---

### Twilio API

**app/api/send-sms/route.ts:**
```typescript
import twilio from 'twilio';

const client = twilio(
  process.env.TWILIO_ACCOUNT_SID,
  process.env.TWILIO_AUTH_TOKEN
);

export async function POST(req: Request) {
  const { to, message } = await req.json();

  try {
    const result = await client.messages.create({
      body: message,
      from: process.env.TWILIO_PHONE_NUMBER,
      to,
    });

    return Response.json({ success: true, sid: result.sid });
  } catch (error) {
    return Response.json({ error: 'Failed to send SMS' }, { status: 500 });
  }
}
```

---

### SMS OTP 인증

```typescript
// 1. OTP 생성 및 전송
export async function POST(req: Request) {
  const { phoneNumber } = await req.json();

  // 6자리 OTP 생성
  const otp = Math.floor(100000 + Math.random() * 900000).toString();

  // Redis에 5분간 저장
  await redis.setex(`otp:${phoneNumber}`, 300, otp);

  // SMS 전송
  await client.messages.create({
    body: `Your verification code is: ${otp}`,
    from: process.env.TWILIO_PHONE_NUMBER,
    to: phoneNumber,
  });

  return Response.json({ success: true });
}

// 2. OTP 검증
export async function PUT(req: Request) {
  const { phoneNumber, otp } = await req.json();

  const storedOtp = await redis.get(`otp:${phoneNumber}`);

  if (storedOtp === otp) {
    // 인증 성공
    await redis.del(`otp:${phoneNumber}`);
    return Response.json({ success: true, verified: true });
  }

  return Response.json({ success: false, verified: false }, { status: 400 });
}
```

---

## 알림 큐 (BullMQ)

### 왜 큐가 필요한가?

**문제:**
```
회원가입 API
  → 이메일 전송 (2초)
  → SMS 전송 (1초)
  → 총 응답 시간: 3초 (느림!)
```

**해결:**
```
회원가입 API
  → 큐에 작업 추가 (10ms)
  → 즉시 응답 (빠름!)

백그라운드 워커
  → 이메일 전송 (2초)
  → SMS 전송 (1초)
```

---

### 설치

```bash
npm install bullmq ioredis
```

---

### 큐 설정

**lib/queue.ts:**
```typescript
import { Queue, Worker } from 'bullmq';
import IORedis from 'ioredis';

const connection = new IORedis({
  host: process.env.REDIS_HOST || 'localhost',
  port: Number(process.env.REDIS_PORT) || 6379,
  maxRetriesPerRequest: null,
});

// 이메일 큐
export const emailQueue = new Queue('emails', { connection });

// SMS 큐
export const smsQueue = new Queue('sms', { connection });

// 푸시 알림 큐
export const pushQueue = new Queue('push-notifications', { connection });
```

---

### 워커 (workers/email-worker.ts)

```typescript
import { Worker } from 'bullmq';
import { Resend } from 'resend';
import { WelcomeEmail } from '@/emails/WelcomeEmail';
import IORedis from 'ioredis';

const connection = new IORedis({
  host: process.env.REDIS_HOST,
  port: Number(process.env.REDIS_PORT),
  maxRetriesPerRequest: null,
});

const resend = new Resend(process.env.RESEND_API_KEY);

const emailWorker = new Worker(
  'emails',
  async (job) => {
    const { type, data } = job.data;

    console.log(`Processing email job: ${type}`, data);

    switch (type) {
      case 'welcome':
        await resend.emails.send({
          from: 'MyApp <onboarding@myapp.com>',
          to: data.email,
          subject: 'Welcome to MyApp!',
          react: WelcomeEmail({
            username: data.username,
            loginUrl: 'https://myapp.com/login',
          }),
        });
        break;

      case 'password-reset':
        // 비밀번호 재설정 이메일
        break;

      case 'order-confirmation':
        // 주문 확인 이메일
        break;
    }

    return { success: true };
  },
  {
    connection,
    concurrency: 5, // 동시 5개 작업
  }
);

emailWorker.on('completed', (job) => {
  console.log(`Email job ${job.id} completed`);
});

emailWorker.on('failed', (job, err) => {
  console.error(`Email job ${job?.id} failed:`, err);
});
```

---

### 큐에 작업 추가

**app/api/signup/route.ts:**
```typescript
import { emailQueue, smsQueue, pushQueue } from '@/lib/queue';

export async function POST(req: Request) {
  const { email, username, phoneNumber } = await req.json();

  // 1. DB에 사용자 생성
  const user = await prisma.user.create({
    data: { email, username, phoneNumber },
  });

  // 2. 알림 작업을 큐에 추가 (비동기)
  await Promise.all([
    // 환영 이메일
    emailQueue.add('welcome-email', {
      type: 'welcome',
      data: { email, username },
    }),

    // 환영 SMS
    smsQueue.add('welcome-sms', {
      phoneNumber,
      message: `Welcome to MyApp, ${username}!`,
    }),
  ]);

  // 3. 즉시 응답 (10ms)
  return Response.json({ success: true, user });
}
```

---

## 실전 사례

### 사례: E커머스 알림 시스템

**Before**
```
- 주문 확인: API 응답 5초 (이메일 전송 대기)
- SMS 알림: 없음
- 푸시 알림: 없음
- 배송 추적: 이메일만
```

---

**알림 전략:**

**1. 주문 확인 (이메일 + SMS)**
```typescript
// 주문 생성 API
await emailQueue.add('order-confirmation', {
  email: user.email,
  orderId: order.id,
  items: order.items,
  total: order.total,
});

await smsQueue.add('order-sms', {
  phoneNumber: user.phoneNumber,
  message: `Order #${order.id} confirmed! Total: $${order.total}`,
});
```

---

**2. 배송 추적 (푸시 알림)**
```typescript
// 배송 상태 업데이트 시
await pushQueue.add('shipping-update', {
  userId: order.userId,
  title: 'Your order is on the way!',
  body: `Order #${order.id} has been shipped`,
  link: `/orders/${order.id}`,
});
```

---

**3. 재입고 알림 (이메일 + 푸시)**
```typescript
// 재입고 시
const subscribers = await prisma.restock Notification.findMany({
  where: { productId: product.id },
});

await Promise.all(
  subscribers.map(async (subscriber) => {
    await emailQueue.add('restock-notification', {
      email: subscriber.email,
      productName: product.name,
      productUrl: `https://myapp.com/products/${product.id}`,
    });

    if (subscriber.pushToken) {
      await pushQueue.add('restock-push', {
        token: subscriber.pushToken,
        title: 'Back in stock!',
        body: `${product.name} is available again`,
        link: `/products/${product.id}`,
      });
    }
  })
);
```

---

**After**
```
✅ 주문 확인: API 응답 50ms (95% 빠름)
✅ SMS 알림: 주문, 배송 상태 업데이트
✅ 푸시 알림: 실시간 배송 추적
✅ 이메일: 주문, 배송, 리뷰 요청
✅ 큐 처리량: 1,000 작업/분
```

**결과:**
- 사용자 참여도: +45%
- 재구매율: +30%
- 고객 만족도: 4.2 → 4.7 (5점 만점)
- 서버 응답 시간: 5초 → 50ms

**ROI:** 매출 +25% (알림을 통한 재참여)

---

## 체크리스트

### 이메일
- [ ] Resend 또는 SendGrid 설정
- [ ] React Email 템플릿 작성
- [ ] 도메인 인증 (SPF, DKIM)
- [ ] 환영 이메일
- [ ] 비밀번호 재설정
- [ ] 트랜잭션 이메일

### 푸시 알림
- [ ] Firebase 프로젝트 생성
- [ ] Service Worker 설정
- [ ] FCM 토큰 관리
- [ ] 포그라운드 알림
- [ ] 백그라운드 알림
- [ ] 알림 권한 요청 UX

### SMS
- [ ] Twilio 계정 설정
- [ ] 전화번호 인증
- [ ] OTP 인증 구현
- [ ] Rate Limiting

### 큐
- [ ] BullMQ 설정
- [ ] 워커 프로세스 분리
- [ ] 재시도 로직
- [ ] Dead Letter Queue
- [ ] 모니터링 (Bull Board)

### 보안
- [ ] API 키 환경 변수
- [ ] Rate Limiting
- [ ] 스팸 방지
- [ ] Unsubscribe 링크

---

## 참고 자료

- [Resend Documentation](https://resend.com/docs)
- [React Email Documentation](https://react.email/docs)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Twilio SMS API](https://www.twilio.com/docs/sms)
- [BullMQ Documentation](https://docs.bullmq.io/)

---

**적절한 알림 전략으로 사용자 참여도를 2배로 향상하세요! 📬**
