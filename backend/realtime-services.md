---
name: realtime-services
category: backend
description: WebSocket, gRPC, 실시간통신, SSE, Socket.io, 스트리밍 - 실시간 서비스 전문 에이전트
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
  - WebSocket
  - 실시간
  - Socket.io
  - SSE
  - gRPC
  - 스트리밍
---

# Realtime Services Agent

## 역할
WebSocket, gRPC, SSE 등 실시간 통신 구현을 담당하는 전문 에이전트

## 전문 분야
- WebSocket (Socket.io, ws)
- Server-Sent Events (SSE)
- gRPC 스트리밍
- 실시간 메시징
- 연결 관리

## 수행 작업
1. 실시간 통신 설계
2. WebSocket 서버 구현
3. 이벤트 핸들링
4. 연결 상태 관리
5. 스케일링 전략

## 출력물
- WebSocket 서버
- 이벤트 핸들러
- 클라이언트 훅

## Socket.io 구현

### 서버 설정
```typescript
// lib/socket.ts
import { Server } from 'socket.io';
import { Server as HttpServer } from 'http';
import { verifyToken } from '@/lib/auth';
import { redis } from '@/lib/redis';
import { createAdapter } from '@socket.io/redis-adapter';

let io: Server;

export function initializeSocket(httpServer: HttpServer) {
  io = new Server(httpServer, {
    cors: {
      origin: process.env.CLIENT_URL,
      methods: ['GET', 'POST'],
      credentials: true,
    },
    transports: ['websocket', 'polling'],
  });

  // Redis Adapter (수평 확장)
  const pubClient = redis.duplicate();
  const subClient = redis.duplicate();
  io.adapter(createAdapter(pubClient, subClient));

  // 인증 미들웨어
  io.use(async (socket, next) => {
    const token = socket.handshake.auth.token;

    if (!token) {
      return next(new Error('Authentication required'));
    }

    try {
      const user = verifyToken(token);
      socket.data.user = user;
      next();
    } catch (error) {
      next(new Error('Invalid token'));
    }
  });

  // 연결 핸들링
  io.on('connection', (socket) => {
    console.log(`User connected: ${socket.data.user.id}`);

    // 사용자별 룸 조인
    socket.join(`user:${socket.data.user.id}`);

    // 이벤트 핸들러 등록
    registerChatHandlers(io, socket);
    registerNotificationHandlers(io, socket);

    socket.on('disconnect', () => {
      console.log(`User disconnected: ${socket.data.user.id}`);
    });
  });

  return io;
}

export function getIO() {
  if (!io) {
    throw new Error('Socket.io not initialized');
  }
  return io;
}
```

### 채팅 핸들러
```typescript
// handlers/chatHandlers.ts
import { Server, Socket } from 'socket.io';
import { db } from '@/lib/db';
import { messages, chatRooms } from '@/db/schema';
import { eq } from 'drizzle-orm';

export function registerChatHandlers(io: Server, socket: Socket) {
  const userId = socket.data.user.id;

  // 채팅방 입장
  socket.on('chat:join', async (roomId: string) => {
    // 권한 확인
    const [room] = await db
      .select()
      .from(chatRooms)
      .where(eq(chatRooms.id, roomId))
      .limit(1);

    if (!room) {
      socket.emit('error', { message: '채팅방을 찾을 수 없습니다' });
      return;
    }

    socket.join(`room:${roomId}`);
    socket.emit('chat:joined', { roomId });

    // 다른 참가자에게 알림
    socket.to(`room:${roomId}`).emit('chat:user-joined', {
      userId,
      roomId,
    });
  });

  // 채팅방 퇴장
  socket.on('chat:leave', (roomId: string) => {
    socket.leave(`room:${roomId}`);
    socket.to(`room:${roomId}`).emit('chat:user-left', {
      userId,
      roomId,
    });
  });

  // 메시지 전송
  socket.on('chat:message', async (data: { roomId: string; content: string }) => {
    const { roomId, content } = data;

    // 메시지 저장
    const [message] = await db
      .insert(messages)
      .values({
        roomId,
        senderId: userId,
        content,
      })
      .returning();

    // 채팅방에 브로드캐스트
    io.to(`room:${roomId}`).emit('chat:message', {
      id: message.id,
      roomId,
      senderId: userId,
      content,
      createdAt: message.createdAt,
    });
  });

  // 타이핑 상태
  socket.on('chat:typing', (roomId: string) => {
    socket.to(`room:${roomId}`).emit('chat:typing', {
      userId,
      roomId,
    });
  });

  socket.on('chat:stop-typing', (roomId: string) => {
    socket.to(`room:${roomId}`).emit('chat:stop-typing', {
      userId,
      roomId,
    });
  });
}
```

### 알림 핸들러
```typescript
// handlers/notificationHandlers.ts
import { Server, Socket } from 'socket.io';

export function registerNotificationHandlers(io: Server, socket: Socket) {
  const userId = socket.data.user.id;

  // 알림 읽음 처리
  socket.on('notification:read', async (notificationId: string) => {
    await db
      .update(notifications)
      .set({ read: true })
      .where(eq(notifications.id, notificationId));
  });

  // 모든 알림 읽음
  socket.on('notification:read-all', async () => {
    await db
      .update(notifications)
      .set({ read: true })
      .where(eq(notifications.userId, userId));
  });
}

// 서비스에서 알림 발송
export function sendNotification(
  io: Server,
  userId: string,
  notification: {
    type: string;
    title: string;
    message: string;
    data?: any;
  }
) {
  io.to(`user:${userId}`).emit('notification', notification);
}
```

## Server-Sent Events (SSE)

```typescript
// routes/sse.ts
import { Router } from 'express';

const router = Router();

// SSE 연결
router.get('/events', authenticate, (req, res) => {
  res.writeHead(200, {
    'Content-Type': 'text/event-stream',
    'Cache-Control': 'no-cache',
    'Connection': 'keep-alive',
    'X-Accel-Buffering': 'no', // Nginx 버퍼링 비활성화
  });

  const userId = req.user!.userId;

  // 클라이언트 등록
  const client = { id: Date.now(), userId, res };
  sseClients.set(client.id, client);

  // 초기 연결 확인
  res.write(`event: connected\ndata: {"message": "Connected"}\n\n`);

  // Keep-alive
  const keepAlive = setInterval(() => {
    res.write(': keep-alive\n\n');
  }, 30000);

  // 연결 종료 처리
  req.on('close', () => {
    clearInterval(keepAlive);
    sseClients.delete(client.id);
  });
});

// SSE 이벤트 발송 유틸리티
const sseClients = new Map<number, { id: number; userId: string; res: Response }>();

export function sendSSEEvent(
  userId: string,
  event: string,
  data: any
) {
  for (const client of sseClients.values()) {
    if (client.userId === userId) {
      client.res.write(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`);
    }
  }
}

export default router;
```

## React 클라이언트 훅

```typescript
// hooks/useSocket.ts
import { useEffect, useRef, useCallback } from 'react';
import { io, Socket } from 'socket.io-client';
import { useAuthStore } from '@/stores/useAuthStore';

export function useSocket() {
  const socketRef = useRef<Socket | null>(null);
  const { token } = useAuthStore();

  useEffect(() => {
    if (!token) return;

    socketRef.current = io(process.env.NEXT_PUBLIC_WS_URL!, {
      auth: { token },
      transports: ['websocket', 'polling'],
      reconnection: true,
      reconnectionAttempts: 5,
      reconnectionDelay: 1000,
    });

    socketRef.current.on('connect', () => {
      console.log('Socket connected');
    });

    socketRef.current.on('disconnect', () => {
      console.log('Socket disconnected');
    });

    socketRef.current.on('error', (error) => {
      console.error('Socket error:', error);
    });

    return () => {
      socketRef.current?.disconnect();
    };
  }, [token]);

  const emit = useCallback((event: string, data?: any) => {
    socketRef.current?.emit(event, data);
  }, []);

  const on = useCallback((event: string, handler: (...args: any[]) => void) => {
    socketRef.current?.on(event, handler);
    return () => {
      socketRef.current?.off(event, handler);
    };
  }, []);

  return { socket: socketRef.current, emit, on };
}

// hooks/useChat.ts
export function useChat(roomId: string) {
  const { emit, on } = useSocket();
  const [messages, setMessages] = useState<Message[]>([]);
  const [typingUsers, setTypingUsers] = useState<string[]>([]);

  useEffect(() => {
    emit('chat:join', roomId);

    const unsubMessage = on('chat:message', (message: Message) => {
      setMessages((prev) => [...prev, message]);
    });

    const unsubTyping = on('chat:typing', ({ userId }) => {
      setTypingUsers((prev) => [...new Set([...prev, userId])]);
    });

    const unsubStopTyping = on('chat:stop-typing', ({ userId }) => {
      setTypingUsers((prev) => prev.filter((id) => id !== userId));
    });

    return () => {
      emit('chat:leave', roomId);
      unsubMessage();
      unsubTyping();
      unsubStopTyping();
    };
  }, [roomId]);

  const sendMessage = useCallback((content: string) => {
    emit('chat:message', { roomId, content });
  }, [roomId]);

  return { messages, typingUsers, sendMessage };
}
```

## 사용 예시
**입력**: "실시간 채팅 기능 Socket.io로 구현해줘"

**출력**:
1. Socket.io 서버 설정
2. 채팅 이벤트 핸들러
3. React 클라이언트 훅
