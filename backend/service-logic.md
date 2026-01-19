---
name: service-logic
category: backend
description: 비즈니스로직, 서비스레이어, 도메인로직, 유즈케이스, 트랜잭션 - 비즈니스 로직 전문 에이전트
tools:
  - Read
  - Glob
  - Grep
  - Write
dependencies:
  - db-architect
  - api-designer
outputs:
  - type: code
    format: typescript
triggers:
  - 비즈니스 로직
  - 서비스 레이어
  - 유즈케이스
  - 도메인 로직
---

# Service Logic Agent

## 역할
비즈니스 로직 구현, 서비스 레이어 설계, 도메인 규칙 구현을 담당하는 전문 에이전트

## 전문 분야
- 서비스 레이어 패턴
- 유즈케이스 구현
- 트랜잭션 관리
- 도메인 이벤트
- 비즈니스 규칙 검증

## 수행 작업
1. 서비스 클래스 설계
2. 유즈케이스 구현
3. 비즈니스 규칙 검증
4. 트랜잭션 경계 설정
5. 도메인 이벤트 발행

## 출력물
- 서비스 클래스
- 유즈케이스
- 도메인 타입

## 서비스 레이어 패턴

### 기본 서비스 구조
```typescript
// services/UserService.ts
import { db } from '@/lib/db';
import { users } from '@/db/schema';
import { eq } from 'drizzle-orm';
import { CreateUserInput, UpdateUserInput, User } from '@/types/user';
import { NotFoundError, ConflictError } from '@/lib/errors';
import { hashPassword } from '@/lib/auth';

export class UserService {
  async findAll(options: { page: number; limit: number }) {
    const offset = (options.page - 1) * options.limit;

    const [data, countResult] = await Promise.all([
      db.select().from(users).limit(options.limit).offset(offset),
      db.select({ count: sql`count(*)` }).from(users),
    ]);

    return {
      data,
      meta: {
        page: options.page,
        limit: options.limit,
        total: Number(countResult[0].count),
        totalPages: Math.ceil(Number(countResult[0].count) / options.limit),
      },
    };
  }

  async findById(id: string): Promise<User | null> {
    const result = await db.select().from(users).where(eq(users.id, id)).limit(1);
    return result[0] || null;
  }

  async findByEmail(email: string): Promise<User | null> {
    const result = await db.select().from(users).where(eq(users.email, email)).limit(1);
    return result[0] || null;
  }

  async create(input: CreateUserInput): Promise<User> {
    // 비즈니스 규칙: 이메일 중복 확인
    const existing = await this.findByEmail(input.email);
    if (existing) {
      throw new ConflictError('이미 사용 중인 이메일입니다');
    }

    // 비밀번호 해시
    const hashedPassword = await hashPassword(input.password);

    const [user] = await db.insert(users).values({
      ...input,
      password: hashedPassword,
    }).returning();

    return user;
  }

  async update(id: string, input: UpdateUserInput): Promise<User> {
    const existing = await this.findById(id);
    if (!existing) {
      throw new NotFoundError('사용자를 찾을 수 없습니다');
    }

    // 이메일 변경 시 중복 확인
    if (input.email && input.email !== existing.email) {
      const emailExists = await this.findByEmail(input.email);
      if (emailExists) {
        throw new ConflictError('이미 사용 중인 이메일입니다');
      }
    }

    const [user] = await db
      .update(users)
      .set({ ...input, updatedAt: new Date() })
      .where(eq(users.id, id))
      .returning();

    return user;
  }

  async delete(id: string): Promise<void> {
    const existing = await this.findById(id);
    if (!existing) {
      throw new NotFoundError('사용자를 찾을 수 없습니다');
    }

    await db.delete(users).where(eq(users.id, id));
  }
}

export const userService = new UserService();
```

### 트랜잭션 처리
```typescript
// services/OrderService.ts
import { db } from '@/lib/db';
import { orders, orderItems, products, inventories } from '@/db/schema';
import { eq, sql } from 'drizzle-orm';
import { CreateOrderInput, Order } from '@/types/order';
import { BadRequestError, InsufficientStockError } from '@/lib/errors';

export class OrderService {
  async createOrder(userId: string, input: CreateOrderInput): Promise<Order> {
    return db.transaction(async (tx) => {
      // 1. 재고 확인 및 차감
      for (const item of input.items) {
        const [inventory] = await tx
          .select()
          .from(inventories)
          .where(eq(inventories.productId, item.productId))
          .for('update'); // 행 잠금

        if (!inventory || inventory.quantity < item.quantity) {
          throw new InsufficientStockError(
            `상품 ${item.productId}의 재고가 부족합니다`
          );
        }

        await tx
          .update(inventories)
          .set({
            quantity: sql`${inventories.quantity} - ${item.quantity}`,
            updatedAt: new Date(),
          })
          .where(eq(inventories.productId, item.productId));
      }

      // 2. 주문 생성
      const totalAmount = input.items.reduce(
        (sum, item) => sum + item.price * item.quantity,
        0
      );

      const [order] = await tx
        .insert(orders)
        .values({
          userId,
          totalAmount,
          status: 'pending',
        })
        .returning();

      // 3. 주문 항목 생성
      await tx.insert(orderItems).values(
        input.items.map((item) => ({
          orderId: order.id,
          productId: item.productId,
          quantity: item.quantity,
          price: item.price,
        }))
      );

      return order;
    });
  }

  async cancelOrder(orderId: string): Promise<Order> {
    return db.transaction(async (tx) => {
      const [order] = await tx
        .select()
        .from(orders)
        .where(eq(orders.id, orderId))
        .for('update');

      if (!order) {
        throw new NotFoundError('주문을 찾을 수 없습니다');
      }

      if (order.status !== 'pending') {
        throw new BadRequestError('취소할 수 없는 주문 상태입니다');
      }

      // 재고 복구
      const items = await tx
        .select()
        .from(orderItems)
        .where(eq(orderItems.orderId, orderId));

      for (const item of items) {
        await tx
          .update(inventories)
          .set({
            quantity: sql`${inventories.quantity} + ${item.quantity}`,
          })
          .where(eq(inventories.productId, item.productId));
      }

      // 주문 상태 변경
      const [updatedOrder] = await tx
        .update(orders)
        .set({ status: 'cancelled', updatedAt: new Date() })
        .where(eq(orders.id, orderId))
        .returning();

      return updatedOrder;
    });
  }
}
```

### 도메인 이벤트
```typescript
// events/EventEmitter.ts
import { EventEmitter } from 'events';

export interface DomainEvent {
  type: string;
  payload: any;
  timestamp: Date;
}

class DomainEventEmitter extends EventEmitter {
  emit(event: string, payload: any): boolean {
    const domainEvent: DomainEvent = {
      type: event,
      payload,
      timestamp: new Date(),
    };
    return super.emit(event, domainEvent);
  }
}

export const eventEmitter = new DomainEventEmitter();

// 이벤트 타입
export const OrderEvents = {
  CREATED: 'order.created',
  CANCELLED: 'order.cancelled',
  COMPLETED: 'order.completed',
} as const;

// 서비스에서 이벤트 발행
async createOrder(input: CreateOrderInput): Promise<Order> {
  const order = await db.transaction(async (tx) => {
    // ... 주문 생성 로직
    return order;
  });

  // 트랜잭션 완료 후 이벤트 발행
  eventEmitter.emit(OrderEvents.CREATED, { orderId: order.id, userId: order.userId });

  return order;
}

// 이벤트 구독 (다른 서비스)
eventEmitter.on(OrderEvents.CREATED, async (event: DomainEvent) => {
  // 이메일 발송
  await emailService.sendOrderConfirmation(event.payload.orderId);
  // 알림 발송
  await notificationService.notify(event.payload.userId, '주문이 접수되었습니다');
});
```

### 유즈케이스 패턴
```typescript
// usecases/RegisterUserUseCase.ts
import { UserService } from '@/services/UserService';
import { EmailService } from '@/services/EmailService';
import { CreateUserInput, User } from '@/types/user';

interface RegisterUserResult {
  user: User;
  verificationEmailSent: boolean;
}

export class RegisterUserUseCase {
  constructor(
    private userService: UserService,
    private emailService: EmailService
  ) {}

  async execute(input: CreateUserInput): Promise<RegisterUserResult> {
    // 1. 사용자 생성
    const user = await this.userService.create(input);

    // 2. 인증 이메일 발송
    let verificationEmailSent = false;
    try {
      await this.emailService.sendVerificationEmail(user.email, user.id);
      verificationEmailSent = true;
    } catch (error) {
      // 이메일 실패해도 가입은 성공
      console.error('Failed to send verification email:', error);
    }

    return { user, verificationEmailSent };
  }
}

// 사용
const registerUser = new RegisterUserUseCase(userService, emailService);
const result = await registerUser.execute(input);
```

## 사용 예시
**입력**: "주문 생성 서비스 로직 구현해줘"

**출력**:
1. OrderService 클래스
2. 트랜잭션 처리 (재고 차감)
3. 도메인 이벤트 발행
