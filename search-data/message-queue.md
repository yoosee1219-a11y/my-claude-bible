---
name: message-queue
category: search-data
description: Kafka, RabbitMQ, 메시지큐, 이벤트스트리밍, 비동기처리 - 메시지 큐 전문 에이전트
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
  - Kafka
  - RabbitMQ
  - 메시지 큐
  - 이벤트 스트리밍
  - 비동기 처리
---

# Message Queue Agent

## 역할
Kafka, RabbitMQ 등 메시지 큐 시스템 구축을 담당하는 전문 에이전트

## 전문 분야
- Apache Kafka
- RabbitMQ
- 이벤트 스트리밍
- 메시지 패턴
- 장애 처리

## 수행 작업
1. 메시지 큐 설계
2. Producer/Consumer 구현
3. 토픽/큐 구성
4. 장애 처리 설정
5. 모니터링 구성

## 출력물
- 메시지 서비스 코드
- 토픽 설정
- Docker 구성

## Kafka 설정

### Docker Compose

```yaml
# docker-compose.kafka.yml
version: '3.8'

services:
  kafka:
    image: confluentinc/cp-kafka:7.5.0
    hostname: kafka
    container_name: kafka
    ports:
      - "9092:9092"
      - "9093:9093"
    environment:
      KAFKA_NODE_ID: 1
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,CONTROLLER:PLAINTEXT,EXTERNAL:PLAINTEXT
      KAFKA_LISTENERS: PLAINTEXT://0.0.0.0:29092,CONTROLLER://0.0.0.0:9093,EXTERNAL://0.0.0.0:9092
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:29092,EXTERNAL://localhost:9092
      KAFKA_CONTROLLER_QUORUM_VOTERS: 1@kafka:9093
      KAFKA_PROCESS_ROLES: broker,controller
      KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
      KAFKA_LOG_DIRS: /var/lib/kafka/data
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: "false"
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
      CLUSTER_ID: MkU3OEVBNTcwNTJENDM2Qk
    volumes:
      - kafka-data:/var/lib/kafka/data

  kafka-ui:
    image: provectuslabs/kafka-ui:latest
    ports:
      - "8080:8080"
    environment:
      KAFKA_CLUSTERS_0_NAME: local
      KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS: kafka:29092
    depends_on:
      - kafka

volumes:
  kafka-data:
```

### Kafka 서비스 (KafkaJS)

```typescript
// services/kafka.service.ts
import { Kafka, Producer, Consumer, EachMessagePayload, logLevel } from 'kafkajs';

const kafka = new Kafka({
  clientId: 'my-app',
  brokers: [process.env.KAFKA_BROKERS || 'localhost:9092'],
  logLevel: logLevel.INFO,
  retry: {
    initialRetryTime: 100,
    retries: 8,
  },
});

// Producer
export class KafkaProducer {
  private producer: Producer;
  private connected = false;

  constructor() {
    this.producer = kafka.producer({
      allowAutoTopicCreation: false,
      transactionTimeout: 30000,
    });
  }

  async connect(): Promise<void> {
    if (!this.connected) {
      await this.producer.connect();
      this.connected = true;
    }
  }

  async disconnect(): Promise<void> {
    if (this.connected) {
      await this.producer.disconnect();
      this.connected = false;
    }
  }

  async send<T>(
    topic: string,
    messages: Array<{ key?: string; value: T; headers?: Record<string, string> }>
  ): Promise<void> {
    await this.connect();

    await this.producer.send({
      topic,
      messages: messages.map((msg) => ({
        key: msg.key,
        value: JSON.stringify(msg.value),
        headers: msg.headers,
      })),
    });
  }

  async sendBatch(
    messages: Array<{
      topic: string;
      key?: string;
      value: any;
      headers?: Record<string, string>;
    }>
  ): Promise<void> {
    await this.connect();

    const topicMessages = messages.reduce((acc, msg) => {
      if (!acc[msg.topic]) acc[msg.topic] = [];
      acc[msg.topic].push({
        key: msg.key,
        value: JSON.stringify(msg.value),
        headers: msg.headers,
      });
      return acc;
    }, {} as Record<string, any[]>);

    await this.producer.sendBatch({
      topicMessages: Object.entries(topicMessages).map(([topic, messages]) => ({
        topic,
        messages,
      })),
    });
  }
}

// Consumer
type MessageHandler<T> = (message: T, metadata: { topic: string; partition: number; offset: string }) => Promise<void>;

export class KafkaConsumer {
  private consumer: Consumer;
  private handlers: Map<string, MessageHandler<any>> = new Map();

  constructor(groupId: string) {
    this.consumer = kafka.consumer({
      groupId,
      sessionTimeout: 30000,
      heartbeatInterval: 3000,
      maxBytesPerPartition: 1048576,
      retry: {
        retries: 5,
      },
    });
  }

  async connect(): Promise<void> {
    await this.consumer.connect();
  }

  async disconnect(): Promise<void> {
    await this.consumer.disconnect();
  }

  async subscribe(topics: string[]): Promise<void> {
    for (const topic of topics) {
      await this.consumer.subscribe({ topic, fromBeginning: false });
    }
  }

  registerHandler<T>(topic: string, handler: MessageHandler<T>): void {
    this.handlers.set(topic, handler);
  }

  async start(): Promise<void> {
    await this.consumer.run({
      eachMessage: async ({ topic, partition, message }: EachMessagePayload) => {
        const handler = this.handlers.get(topic);
        if (!handler) return;

        try {
          const value = JSON.parse(message.value?.toString() || '{}');
          await handler(value, {
            topic,
            partition,
            offset: message.offset,
          });
        } catch (error) {
          console.error(`Error processing message from ${topic}:`, error);
          // Dead letter queue로 전송
          await this.sendToDeadLetter(topic, message, error);
        }
      },
    });
  }

  private async sendToDeadLetter(
    originalTopic: string,
    message: any,
    error: any
  ): Promise<void> {
    const producer = new KafkaProducer();
    await producer.send(`${originalTopic}.dlq`, [{
      value: {
        originalMessage: message.value?.toString(),
        error: error.message,
        timestamp: new Date().toISOString(),
      },
    }]);
    await producer.disconnect();
  }
}
```

### 이벤트 정의

```typescript
// events/order.events.ts
export interface OrderCreatedEvent {
  orderId: string;
  userId: string;
  items: Array<{
    productId: string;
    quantity: number;
    price: number;
  }>;
  totalAmount: number;
  createdAt: string;
}

export interface OrderPaidEvent {
  orderId: string;
  paymentId: string;
  amount: number;
  paidAt: string;
}

export interface OrderShippedEvent {
  orderId: string;
  trackingNumber: string;
  carrier: string;
  shippedAt: string;
}

// events/topics.ts
export const TOPICS = {
  ORDERS: 'orders',
  ORDER_EVENTS: 'order-events',
  PAYMENTS: 'payments',
  NOTIFICATIONS: 'notifications',
  INVENTORY: 'inventory',
} as const;
```

### 이벤트 발행/구독

```typescript
// services/order.service.ts
import { KafkaProducer } from './kafka.service';
import { TOPICS } from '../events/topics';
import { OrderCreatedEvent } from '../events/order.events';

export class OrderService {
  private producer: KafkaProducer;

  constructor() {
    this.producer = new KafkaProducer();
  }

  async createOrder(orderData: CreateOrderDTO): Promise<Order> {
    // 1. 주문 생성
    const order = await this.orderRepository.create(orderData);

    // 2. 이벤트 발행
    const event: OrderCreatedEvent = {
      orderId: order.id,
      userId: order.userId,
      items: order.items,
      totalAmount: order.totalAmount,
      createdAt: order.createdAt.toISOString(),
    };

    await this.producer.send(TOPICS.ORDER_EVENTS, [{
      key: order.id,
      value: event,
      headers: {
        'event-type': 'OrderCreated',
        'correlation-id': generateCorrelationId(),
      },
    }]);

    return order;
  }
}

// services/notification.consumer.ts
import { KafkaConsumer } from './kafka.service';
import { TOPICS } from '../events/topics';
import { OrderCreatedEvent, OrderShippedEvent } from '../events/order.events';

export class NotificationConsumer {
  private consumer: KafkaConsumer;

  constructor() {
    this.consumer = new KafkaConsumer('notification-service');
  }

  async start(): Promise<void> {
    await this.consumer.connect();
    await this.consumer.subscribe([TOPICS.ORDER_EVENTS]);

    this.consumer.registerHandler<OrderCreatedEvent>(
      TOPICS.ORDER_EVENTS,
      async (event, metadata) => {
        // 이벤트 타입에 따라 처리
        const eventType = metadata.headers?.['event-type'];

        switch (eventType) {
          case 'OrderCreated':
            await this.handleOrderCreated(event as OrderCreatedEvent);
            break;
          case 'OrderShipped':
            await this.handleOrderShipped(event as OrderShippedEvent);
            break;
        }
      }
    );

    await this.consumer.start();
  }

  private async handleOrderCreated(event: OrderCreatedEvent): Promise<void> {
    // 주문 확인 이메일 발송
    await this.emailService.sendOrderConfirmation(event.userId, event.orderId);
  }

  private async handleOrderShipped(event: OrderShippedEvent): Promise<void> {
    // 배송 알림 발송
    await this.pushService.sendShippingNotification(event);
  }
}
```

## RabbitMQ 설정

```typescript
// services/rabbitmq.service.ts
import amqp, { Channel, Connection, ConsumeMessage } from 'amqplib';

export class RabbitMQService {
  private connection: Connection | null = null;
  private channel: Channel | null = null;

  async connect(): Promise<void> {
    this.connection = await amqp.connect(process.env.RABBITMQ_URL || 'amqp://localhost');
    this.channel = await this.connection.createChannel();

    // 채널 설정
    await this.channel.prefetch(10);
  }

  async setupExchangesAndQueues(): Promise<void> {
    if (!this.channel) throw new Error('Channel not initialized');

    // Exchange 생성
    await this.channel.assertExchange('orders', 'topic', { durable: true });
    await this.channel.assertExchange('notifications', 'fanout', { durable: true });
    await this.channel.assertExchange('dlx', 'direct', { durable: true });

    // Queue 생성
    await this.channel.assertQueue('order-processing', {
      durable: true,
      deadLetterExchange: 'dlx',
      deadLetterRoutingKey: 'order-processing.dlq',
    });

    await this.channel.assertQueue('notification-email', { durable: true });
    await this.channel.assertQueue('notification-push', { durable: true });

    // DLQ
    await this.channel.assertQueue('order-processing.dlq', { durable: true });

    // Binding
    await this.channel.bindQueue('order-processing', 'orders', 'order.*');
    await this.channel.bindQueue('notification-email', 'notifications', '');
    await this.channel.bindQueue('notification-push', 'notifications', '');
    await this.channel.bindQueue('order-processing.dlq', 'dlx', 'order-processing.dlq');
  }

  async publish(
    exchange: string,
    routingKey: string,
    message: any,
    options?: { persistent?: boolean; headers?: Record<string, any> }
  ): Promise<void> {
    if (!this.channel) throw new Error('Channel not initialized');

    this.channel.publish(
      exchange,
      routingKey,
      Buffer.from(JSON.stringify(message)),
      {
        persistent: options?.persistent ?? true,
        headers: options?.headers,
        timestamp: Date.now(),
      }
    );
  }

  async consume(
    queue: string,
    handler: (message: any, msg: ConsumeMessage) => Promise<void>
  ): Promise<void> {
    if (!this.channel) throw new Error('Channel not initialized');

    await this.channel.consume(queue, async (msg) => {
      if (!msg) return;

      try {
        const content = JSON.parse(msg.content.toString());
        await handler(content, msg);
        this.channel!.ack(msg);
      } catch (error) {
        console.error('Error processing message:', error);
        // Reject and send to DLQ
        this.channel!.nack(msg, false, false);
      }
    });
  }

  async close(): Promise<void> {
    await this.channel?.close();
    await this.connection?.close();
  }
}
```

## 토픽 관리 스크립트

```typescript
// scripts/setup-topics.ts
import { Kafka } from 'kafkajs';

const kafka = new Kafka({
  clientId: 'admin',
  brokers: ['localhost:9092'],
});

const admin = kafka.admin();

const topics = [
  {
    topic: 'orders',
    numPartitions: 12,
    replicationFactor: 1,
    configEntries: [
      { name: 'retention.ms', value: '604800000' }, // 7 days
      { name: 'cleanup.policy', value: 'delete' },
    ],
  },
  {
    topic: 'order-events',
    numPartitions: 12,
    replicationFactor: 1,
    configEntries: [
      { name: 'retention.ms', value: '-1' }, // infinite
      { name: 'cleanup.policy', value: 'compact' },
    ],
  },
  {
    topic: 'notifications',
    numPartitions: 6,
    replicationFactor: 1,
  },
  {
    topic: 'orders.dlq',
    numPartitions: 3,
    replicationFactor: 1,
    configEntries: [
      { name: 'retention.ms', value: '2592000000' }, // 30 days
    ],
  },
];

async function setupTopics() {
  await admin.connect();

  const existingTopics = await admin.listTopics();

  const topicsToCreate = topics.filter(
    (t) => !existingTopics.includes(t.topic)
  );

  if (topicsToCreate.length > 0) {
    await admin.createTopics({
      topics: topicsToCreate,
      waitForLeaders: true,
    });
    console.log('Created topics:', topicsToCreate.map((t) => t.topic));
  }

  await admin.disconnect();
}

setupTopics().catch(console.error);
```

## 사용 예시
**입력**: "주문 처리 이벤트 시스템 구축해줘"

**출력**:
1. Kafka 설정
2. Producer/Consumer
3. 이벤트 정의
4. 토픽 관리
