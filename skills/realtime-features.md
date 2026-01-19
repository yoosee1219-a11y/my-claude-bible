# Real-Time Features

> WebSocket, SSE, Pusher로 실시간 채팅, 알림, 협업 기능 구축 완벽 가이드 (2026)

## 목차

1. [실시간 기능이 왜 필요한가?](#실시간-기능이-왜-필요한가)
2. [WebSocket vs SSE vs Polling](#websocket-vs-sse-vs-polling)
3. [Socket.io (WebSocket)](#socketio-websocket)
4. [Server-Sent Events (SSE)](#server-sent-events-sse)
5. [Pusher / Ably (Managed Service)](#pusher--ably-managed-service)
6. [실전 사례](#실전-사례)

---

## 실시간 기능이 왜 필요한가?

### Polling의 한계

**Before (Short Polling)**
```javascript
// 1초마다 새 메시지 확인
setInterval(() => {
  fetch('/api/messages?since=' + lastMessageId)
    .then(res => res.json())
    .then(messages => {
      if (messages.length > 0) {
        displayMessages(messages);
      }
    });
}, 1000);

문제:
- 불필요한 요청 (메시지 없어도 1초마다 요청)
- 지연: 최대 1초
- 서버 부하: 초당 1,000 사용자 = 1,000 요청/초
```

**After (WebSocket)**
```javascript
const socket = io('https://myapp.com');

socket.on('new-message', (message) => {
  displayMessage(message);  // 즉시 수신!
});

결과:
✅ 실시간: 지연 0초
✅ 효율적: 메시지 있을 때만 전송
✅ 서버 부하: 99% 감소
```

---

## WebSocket vs SSE vs Polling

### 비교표

| 항목 | Polling | SSE | WebSocket |
|------|---------|-----|-----------|
| 통신 방향 | 단방향 (Client → Server) | 단방향 (Server → Client) | 양방향 |
| 프로토콜 | HTTP | HTTP | WS/WSS |
| 연결 | 매번 새 연결 | 단일 지속 연결 | 단일 지속 연결 |
| 브라우저 지원 | 100% | 99% (IE 제외) | 99% |
| 서버 부하 | 높음 | 낮음 | 낮음 |
| 복잡도 | 낮음 | 낮음 | 중간 |
| 자동 재연결 | ❌ | ✅ | ❌ (라이브러리 필요) |
| Vercel 지원 | ✅ | ✅ | ❌ |

**선택 기준:**
- **Polling:** 레거시 브라우저 지원 필요
- **SSE:** 서버 → 클라이언트 단방향 (알림, 대시보드, AI 스트리밍)
- **WebSocket:** 양방향 실시간 (채팅, 게임, 협업)

---

## Socket.io (WebSocket)

### 설치 (Next.js)

```bash
npm install socket.io socket.io-client
```

---

### 서버 설정 (Custom Server)

**주의:** Vercel은 WebSocket 미지원! Fly.io, Railway, AWS 등 사용

**server.js:**
```javascript
import { createServer } from 'http';
import { parse } from 'url';
import next from 'next';
import { Server } from 'socket.io';

const dev = process.env.NODE_ENV !== 'production';
const app = next({ dev });
const handle = app.getRequestHandler();

app.prepare().then(() => {
  const server = createServer((req, res) => {
    const parsedUrl = parse(req.url, true);
    handle(req, res, parsedUrl);
  });

  const io = new Server(server, {
    cors: {
      origin: process.env.CLIENT_URL || 'http://localhost:3000',
      methods: ['GET', 'POST'],
    },
  });

  // Socket.io 이벤트
  io.on('connection', (socket) => {
    console.log('User connected:', socket.id);

    // 채팅 메시지
    socket.on('send-message', async (data) => {
      const { roomId, message, userId } = data;

      // DB 저장
      const savedMessage = await prisma.message.create({
        data: {
          content: message,
          roomId,
          userId,
        },
        include: {
          user: {
            select: { id: true, name: true, avatar: true },
          },
        },
      });

      // 룸의 모든 사용자에게 브로드캐스트
      io.to(roomId).emit('new-message', savedMessage);
    });

    // 룸 참가
    socket.on('join-room', (roomId) => {
      socket.join(roomId);
      console.log(`User ${socket.id} joined room ${roomId}`);

      // 룸의 다른 사용자들에게 알림
      socket.to(roomId).emit('user-joined', {
        userId: socket.data.userId,
        socketId: socket.id,
      });
    });

    // 룸 나가기
    socket.on('leave-room', (roomId) => {
      socket.leave(roomId);
      socket.to(roomId).emit('user-left', {
        userId: socket.data.userId,
        socketId: socket.id,
      });
    });

    // 타이핑 중
    socket.on('typing', ({ roomId, userId }) => {
      socket.to(roomId).emit('user-typing', { userId });
    });

    socket.on('stop-typing', ({ roomId, userId }) => {
      socket.to(roomId).emit('user-stop-typing', { userId });
    });

    // 연결 해제
    socket.on('disconnect', () => {
      console.log('User disconnected:', socket.id);
    });
  });

  const PORT = process.env.PORT || 3000;
  server.listen(PORT, () => {
    console.log(`> Ready on http://localhost:${PORT}`);
  });
});
```

**package.json:**
```json
{
  "scripts": {
    "dev": "node server.js",
    "build": "next build",
    "start": "NODE_ENV=production node server.js"
  }
}
```

---

### 클라이언트 (React)

**lib/socket.ts:**
```typescript
import { io, Socket } from 'socket.io-client';

let socket: Socket | null = null;

export const getSocket = () => {
  if (!socket) {
    socket = io(process.env.NEXT_PUBLIC_SOCKET_URL || 'http://localhost:3000', {
      autoConnect: false,
    });
  }
  return socket;
};
```

---

**hooks/useSocket.ts:**
```typescript
import { useEffect, useState } from 'use';
import { getSocket } from '@/lib/socket';
import { Socket } from 'socket.io-client';

export const useSocket = () => {
  const [socket, setSocket] = useState<Socket | null>(null);
  const [connected, setConnected] = useState(false);

  useEffect(() => {
    const socketInstance = getSocket();
    setSocket(socketInstance);

    socketInstance.connect();

    socketInstance.on('connect', () => {
      console.log('Connected to socket server');
      setConnected(true);
    });

    socketInstance.on('disconnect', () => {
      console.log('Disconnected from socket server');
      setConnected(false);
    });

    return () => {
      socketInstance.off('connect');
      socketInstance.off('disconnect');
    };
  }, []);

  return { socket, connected };
};
```

---

**components/ChatRoom.tsx:**
```typescript
'use client';

import { useEffect, useState } from 'react';
import { useSocket } from '@/hooks/useSocket';

interface Message {
  id: string;
  content: string;
  userId: string;
  user: {
    id: string;
    name: string;
    avatar: string;
  };
  createdAt: string;
}

export function ChatRoom({ roomId }: { roomId: string }) {
  const { socket, connected } = useSocket();
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputValue, setInputValue] = useState('');
  const [typingUsers, setTypingUsers] = useState<string[]>([]);

  useEffect(() => {
    if (!socket || !connected) return;

    // 룸 참가
    socket.emit('join-room', roomId);

    // 새 메시지 수신
    socket.on('new-message', (message: Message) => {
      setMessages(prev => [...prev, message]);
    });

    // 사용자 타이핑 중
    socket.on('user-typing', ({ userId }) => {
      setTypingUsers(prev => [...new Set([...prev, userId])]);
    });

    socket.on('user-stop-typing', ({ userId }) => {
      setTypingUsers(prev => prev.filter(id => id !== userId));
    });

    return () => {
      socket.emit('leave-room', roomId);
      socket.off('new-message');
      socket.off('user-typing');
      socket.off('user-stop-typing');
    };
  }, [socket, connected, roomId]);

  const sendMessage = () => {
    if (!socket || !inputValue.trim()) return;

    socket.emit('send-message', {
      roomId,
      message: inputValue,
      userId: 'current-user-id',
    });

    setInputValue('');
  };

  const handleTyping = () => {
    if (!socket) return;
    socket.emit('typing', { roomId, userId: 'current-user-id' });

    // 3초 후 타이핑 중지
    setTimeout(() => {
      socket.emit('stop-typing', { roomId, userId: 'current-user-id' });
    }, 3000);
  };

  if (!connected) {
    return <div>Connecting...</div>;
  }

  return (
    <div className="flex flex-col h-screen">
      <div className="flex-1 overflow-y-auto p-4">
        {messages.map(message => (
          <div key={message.id} className="mb-4">
            <div className="flex items-start gap-3">
              <img
                src={message.user.avatar}
                alt={message.user.name}
                className="w-10 h-10 rounded-full"
              />
              <div>
                <div className="font-semibold">{message.user.name}</div>
                <div className="text-gray-700">{message.content}</div>
                <div className="text-xs text-gray-500">
                  {new Date(message.createdAt).toLocaleTimeString()}
                </div>
              </div>
            </div>
          </div>
        ))}

        {typingUsers.length > 0 && (
          <div className="text-sm text-gray-500 italic">
            {typingUsers.length === 1
              ? '1 person is typing...'
              : `${typingUsers.length} people are typing...`}
          </div>
        )}
      </div>

      <div className="border-t p-4">
        <div className="flex gap-2">
          <input
            type="text"
            value={inputValue}
            onChange={(e) => {
              setInputValue(e.target.value);
              handleTyping();
            }}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                sendMessage();
              }
            }}
            placeholder="Type a message..."
            className="flex-1 px-4 py-2 border rounded-lg"
          />
          <button
            onClick={sendMessage}
            className="px-6 py-2 bg-blue-500 text-white rounded-lg"
          >
            Send
          </button>
        </div>
      </div>
    </div>
  );
}
```

---

## Server-Sent Events (SSE)

### 서버 (Next.js API Route)

**Vercel 지원 ✅**

**app/api/notifications/route.ts:**
```typescript
export const runtime = 'edge';

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const userId = searchParams.get('userId');

  // SSE 헤더
  const encoder = new TextEncoder();
  const stream = new ReadableStream({
    async start(controller) {
      // 5초마다 하트비트
      const heartbeat = setInterval(() => {
        controller.enqueue(encoder.encode(': heartbeat\n\n'));
      }, 5000);

      // 실제 알림 전송 (예시)
      const sendNotification = (notification: any) => {
        const data = `data: ${JSON.stringify(notification)}\n\n`;
        controller.enqueue(encoder.encode(data));
      };

      // DB에서 새 알림 폴링 (실제로는 Redis Pub/Sub 등 사용)
      const checkNotifications = async () => {
        const notifications = await prisma.notification.findMany({
          where: {
            userId,
            read: false,
            createdAt: {
              gte: new Date(Date.now() - 10000), // 최근 10초
            },
          },
        });

        notifications.forEach(sendNotification);
      };

      const interval = setInterval(checkNotifications, 10000);

      // 연결 종료 시 정리
      req.signal.addEventListener('abort', () => {
        clearInterval(heartbeat);
        clearInterval(interval);
        controller.close();
      });
    },
  });

  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      Connection: 'keep-alive',
    },
  });
}
```

---

### 클라이언트 (React)

**hooks/useNotifications.ts:**
```typescript
import { useEffect, useState } from 'react';

interface Notification {
  id: string;
  title: string;
  message: string;
  createdAt: string;
}

export const useNotifications = (userId: string) => {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [connected, setConnected] = useState(false);

  useEffect(() => {
    const eventSource = new EventSource(
      `/api/notifications?userId=${userId}`
    );

    eventSource.onopen = () => {
      console.log('SSE connected');
      setConnected(true);
    };

    eventSource.onmessage = (event) => {
      try {
        const notification = JSON.parse(event.data);
        setNotifications(prev => [notification, ...prev]);

        // 브라우저 알림
        if (Notification.permission === 'granted') {
          new Notification(notification.title, {
            body: notification.message,
          });
        }
      } catch (error) {
        console.error('Failed to parse notification:', error);
      }
    };

    eventSource.onerror = () => {
      console.error('SSE error');
      setConnected(false);
      eventSource.close();

      // 5초 후 재연결 (자동 재연결은 브라우저가 처리)
    };

    return () => {
      eventSource.close();
    };
  }, [userId]);

  return { notifications, connected };
};
```

---

**components/NotificationBell.tsx:**
```typescript
'use client';

import { useNotifications } from '@/hooks/useNotifications';
import { useEffect } from 'react';

export function NotificationBell({ userId }: { userId: string }) {
  const { notifications, connected } = useNotifications(userId);

  useEffect(() => {
    // 브라우저 알림 권한 요청
    if (Notification.permission === 'default') {
      Notification.requestPermission();
    }
  }, []);

  return (
    <div className="relative">
      <button className="relative p-2">
        <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
        </svg>

        {notifications.length > 0 && (
          <span className="absolute top-0 right-0 inline-flex items-center justify-center px-2 py-1 text-xs font-bold leading-none text-white bg-red-500 rounded-full">
            {notifications.length}
          </span>
        )}

        {!connected && (
          <span className="absolute bottom-0 right-0 w-2 h-2 bg-gray-400 rounded-full" />
        )}
      </button>

      {notifications.length > 0 && (
        <div className="absolute right-0 mt-2 w-80 bg-white rounded-lg shadow-lg border">
          <div className="p-4">
            <h3 className="font-semibold mb-2">Notifications</h3>
            <div className="space-y-3">
              {notifications.map(notification => (
                <div key={notification.id} className="p-3 bg-gray-50 rounded">
                  <div className="font-medium">{notification.title}</div>
                  <div className="text-sm text-gray-600">{notification.message}</div>
                  <div className="text-xs text-gray-400 mt-1">
                    {new Date(notification.createdAt).toLocaleTimeString()}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
```

---

## Pusher / Ably (Managed Service)

### Pusher 설정

**설치:**
```bash
npm install pusher pusher-js
```

---

**서버 (Next.js API Route):**
```typescript
// app/api/pusher/auth/route.ts
import Pusher from 'pusher';

const pusher = new Pusher({
  appId: process.env.PUSHER_APP_ID!,
  key: process.env.NEXT_PUBLIC_PUSHER_KEY!,
  secret: process.env.PUSHER_SECRET!,
  cluster: process.env.NEXT_PUBLIC_PUSHER_CLUSTER!,
  useTLS: true,
});

export async function POST(req: Request) {
  const { socket_id, channel_name } = await req.json();

  // Private/Presence 채널 인증
  const auth = pusher.authorizeChannel(socket_id, channel_name);

  return Response.json(auth);
}

// app/api/messages/route.ts
export async function POST(req: Request) {
  const { roomId, message, userId } = await req.json();

  // DB 저장
  const savedMessage = await prisma.message.create({
    data: { content: message, roomId, userId },
    include: { user: true },
  });

  // Pusher로 브로드캐스트
  await pusher.trigger(`room-${roomId}`, 'new-message', savedMessage);

  return Response.json(savedMessage);
}
```

---

**클라이언트:**
```typescript
'use client';

import { useEffect, useState } from 'react';
import Pusher from 'pusher-js';

export function PusherChat({ roomId }: { roomId: string }) {
  const [messages, setMessages] = useState([]);

  useEffect(() => {
    const pusher = new Pusher(process.env.NEXT_PUBLIC_PUSHER_KEY!, {
      cluster: process.env.NEXT_PUBLIC_PUSHER_CLUSTER!,
      authEndpoint: '/api/pusher/auth',
    });

    const channel = pusher.subscribe(`room-${roomId}`);

    channel.bind('new-message', (message: any) => {
      setMessages(prev => [...prev, message]);
    });

    return () => {
      channel.unbind_all();
      channel.unsubscribe();
    };
  }, [roomId]);

  // ... 렌더링
}
```

---

### 비용 비교

| 서비스 | 무료 플랜 | 유료 시작 | 적합한 규모 |
|--------|-----------|-----------|-------------|
| Pusher | 100 동시 연결 | $29/월 (500 연결) | 중소 규모 |
| Ably | 200 동시 연결 | $29/월 (1,000 연결) | 중대 규모 |
| Self-hosted Socket.io | 무제한 | 서버 비용 ($10-50/월) | 모든 규모 |

**선택 기준:**
- **Pusher:** 빠른 구현, 간단한 사용, Vercel 호환
- **Ably:** 고신뢰성 (99.999% uptime), 메시지 히스토리
- **Self-hosted:** 완전한 제어, 비용 절감 (대규모)

---

## 실전 사례

### 사례: 협업 도구 실시간 기능 구축

**Before**
```
- Polling: 2초마다 새 데이터 확인
- API 요청: 100 사용자 × 0.5회/초 = 50 req/sec
- 지연: 평균 1초
- 서버 비용: $200/월
```

---

**After (Socket.io + SSE 하이브리드)**

**1. Socket.io (양방향 실시간)**
- 채팅
- 협업 편집 (문서, 화이트보드)
- 사용자 Presence (온라인/오프라인)

**2. SSE (단방향 푸시)**
- 알림
- 대시보드 업데이트
- AI 응답 스트리밍

**구현:**
```typescript
// Socket.io - 협업 편집
socket.on('document-update', (delta) => {
  // Operational Transform
  const newDoc = applyDelta(currentDoc, delta);
  setDocument(newDoc);
});

// SSE - 알림
const eventSource = new EventSource('/api/notifications');
eventSource.onmessage = (event) => {
  const notification = JSON.parse(event.data);
  showToast(notification);
};
```

---

**결과:**
```
✅ API 요청: 50 req/sec → 0 req/sec (Polling 제거)
✅ 지연: 1초 → 50ms (95% 개선)
✅ 서버 비용: $200/월 → $80/월 (60% 절감)
✅ 사용자 만족도: +40%
✅ 동시 접속: 100명 → 1,000명 (10배)
```

**ROI:** 연간 $1,440 비용 절감 + 사용자 경험 대폭 개선

---

## 체크리스트

### 기술 선택
- [ ] 통신 방향 (단방향/양방향)
- [ ] 배포 환경 (Vercel: SSE만 가능)
- [ ] 규모 (동시 연결 수)
- [ ] 예산 (Self-hosted vs Managed)

### Socket.io
- [ ] Custom Server 설정 (server.js)
- [ ] CORS 설정
- [ ] Room 기반 메시징
- [ ] 인증 미들웨어
- [ ] 자동 재연결

### SSE
- [ ] EventSource API
- [ ] Heartbeat (연결 유지)
- [ ] 에러 처리 & 재연결
- [ ] 브라우저 알림 권한
- [ ] Edge Runtime 사용 (Vercel)

### Pusher/Ably
- [ ] API 키 발급
- [ ] Private Channel 인증
- [ ] Presence Channel (온라인 상태)
- [ ] 메시지 히스토리
- [ ] Webhook 설정

### 보안
- [ ] 인증/인가
- [ ] Rate Limiting
- [ ] Input Validation
- [ ] XSS 방어

### 모니터링
- [ ] 연결 수 추적
- [ ] 메시지 전송 성공률
- [ ] 지연 시간 측정
- [ ] 에러 로깅

---

## 참고 자료

- [Socket.IO Documentation](https://socket.io/docs/v4/)
- [Using Server-Sent Events (MDN)](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events)
- [Pusher vs Ably Comparison](https://www.index.dev/skill-vs-skill/pusher-vs-ably-vs-pubnub)
- [WebSockets with Next.js (Fly.io)](https://fly.io/javascript-journal/websockets-with-nextjs/)
- [Why SSE for Real-Time Updates](https://talent500.com/blog/server-sent-events-real-time-updates/)

---

**실시간 기능으로 사용자 경험을 혁신하세요! ⚡**
