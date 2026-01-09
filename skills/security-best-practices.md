# Security Best Practices

> OWASP Top 10:2025, OAuth 2.0/JWT, CORS/XSS/CSRF 완벽 가이드 (2026)

## 목차

1. [보안이 왜 중요한가?](#보안이-왜-중요한가)
2. [OWASP Top 10:2025](#owasp-top-102025)
3. [인증 & 인가](#인증--인가)
4. [XSS/CSRF/CORS 방어](#xsscsrfcors-방어)
5. [API 보안](#api-보안)
6. [Secrets 관리](#secrets-관리)
7. [실전 사례](#실전-사례)

---

## 보안이 왜 중요한가?

### 보안 사고의 비용

**Equifax 데이터 유출 (2017)**
- 피해 규모: 1억 4,700만 명 개인정보 유출
- 직접 비용: $14억 (벌금, 보상)
- 간접 비용: 주가 31% 하락, CEO 사임

**원인:** 알려진 취약점 패치 안 함 (Apache Struts)

### 풀스택 회사의 보안 위험

**Before 보안**
```
- SQL Injection 취약점 → 고객 DB 유출 위험
- XSS 공격 → 관리자 계정 탈취
- 하드코딩된 API 키 → $12,000 AWS 청구서
```

**After 보안**
```
✅ 파라미터화된 쿼리 → SQL Injection 차단
✅ CSP 헤더 + Input Sanitization → XSS 방어
✅ Secrets Manager → API 키 암호화 저장
```

**ROI:** 데이터 유출 방지 = 평균 $4.45M 손실 회피

---

## OWASP Top 10:2025

### A01: Broken Access Control (접근 제어 실패)

**문제:**
```javascript
// ❌ 나쁜 예: 인증만 확인
app.get('/api/users/:id', authMiddleware, async (req, res) => {
  const user = await User.findById(req.params.id);
  res.json(user);
});
// 공격: 다른 사용자 ID로 정보 조회 가능
```

**해결:**
```javascript
// ✅ 좋은 예: 권한 확인
app.get('/api/users/:id', authMiddleware, async (req, res) => {
  const userId = req.params.id;

  // 본인 또는 관리자만 조회 가능
  if (req.user.id !== userId && !req.user.isAdmin) {
    return res.status(403).json({ error: 'Forbidden' });
  }

  const user = await User.findById(userId);
  res.json(user);
});
```

**체크리스트:**
- [ ] 모든 API에서 권한 확인
- [ ] URL 파라미터 조작 테스트
- [ ] IDOR (Insecure Direct Object Reference) 방지

---

### A02: Security Misconfiguration (보안 설정 오류)

**문제:**
```javascript
// ❌ 나쁜 예: 개발 모드로 프로덕션 배포
app.listen(3000, () => {
  console.log('Server running in development mode');
});
// 결과: 상세 에러 메시지 노출, 디버그 정보 유출
```

**해결:**
```javascript
// ✅ 좋은 예: 환경별 설정
const isProduction = process.env.NODE_ENV === 'production';

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
  },
}));

if (!isProduction) {
  app.use(errorHandler()); // 상세 에러만 개발 환경에서
}

app.listen(3000, () => {
  console.log(`Server running in ${process.env.NODE_ENV} mode`);
});
```

**Helmet으로 보안 헤더 설정:**
```bash
npm install helmet
```

---

### A03: Software Supply Chain Failures (소프트웨어 공급망 취약점)

**문제:**
```json
// package.json
{
  "dependencies": {
    "lodash": "^4.17.0"  // 2018년 버전 → 알려진 취약점 존재
  }
}
```

**해결:**
```bash
# 1. 취약점 스캔
npm audit

# 2. 자동 수정
npm audit fix

# 3. Snyk으로 지속 모니터링
npx snyk test
npx snyk monitor

# 4. Dependabot 활성화 (GitHub)
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
```

**체크리스트:**
- [ ] npm audit 정기 실행
- [ ] Dependabot 활성화
- [ ] package-lock.json 커밋
- [ ] 의존성 최소화

---

### A06: Insecure Design (안전하지 않은 설계)

**문제:**
```javascript
// ❌ 나쁜 예: 비밀번호 재설정 토큰 예측 가능
const resetToken = Date.now().toString();
```

**해결:**
```javascript
// ✅ 좋은 예: 암호학적으로 안전한 난수
import crypto from 'crypto';

const resetToken = crypto.randomBytes(32).toString('hex');
const hashedToken = crypto.createHash('sha256').update(resetToken).digest('hex');

// DB에는 해시만 저장
await User.updateOne(
  { email },
  {
    resetPasswordToken: hashedToken,
    resetPasswordExpire: Date.now() + 10 * 60 * 1000, // 10분
  }
);

// 이메일로 원본 토큰 전송 (1회만 표시)
```

---

### A07: Authentication Failures (인증 실패)

**문제:**
```javascript
// ❌ 나쁜 예: Rate Limiting 없음
app.post('/api/login', async (req, res) => {
  const { email, password } = req.body;
  const user = await User.findOne({ email });

  if (!user || !(await bcrypt.compare(password, user.password))) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }

  // 무한 로그인 시도 가능 → Brute Force 공격
});
```

**해결:**
```javascript
// ✅ 좋은 예: Rate Limiting + Account Lockout
import rateLimit from 'express-rate-limit';

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15분
  max: 5, // 최대 5회 시도
  message: 'Too many login attempts, please try again after 15 minutes',
});

app.post('/api/login', loginLimiter, async (req, res) => {
  const { email, password } = req.body;
  const user = await User.findOne({ email });

  if (!user) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }

  // 계정 잠금 확인
  if (user.lockUntil && user.lockUntil > Date.now()) {
    return res.status(423).json({
      error: 'Account locked due to too many failed attempts'
    });
  }

  const isMatch = await bcrypt.compare(password, user.password);

  if (!isMatch) {
    user.failedLoginAttempts += 1;

    if (user.failedLoginAttempts >= 5) {
      user.lockUntil = Date.now() + 30 * 60 * 1000; // 30분 잠금
    }

    await user.save();
    return res.status(401).json({ error: 'Invalid credentials' });
  }

  // 성공 시 카운터 리셋
  user.failedLoginAttempts = 0;
  user.lockUntil = undefined;
  await user.save();

  // 토큰 발급
  const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET);
  res.json({ token });
});
```

---

### A09: Security Logging & Alerting Failures

**문제:**
```javascript
// ❌ 나쁜 예: 보안 이벤트 로깅 없음
app.post('/api/admin/delete-user/:id', authMiddleware, async (req, res) => {
  await User.deleteOne({ _id: req.params.id });
  res.json({ success: true });
});
// 누가, 언제 삭제했는지 추적 불가
```

**해결:**
```javascript
// ✅ 좋은 예: Winston으로 보안 로깅
import winston from 'winston';

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'security.log' }),
    new winston.transports.Console(),
  ],
});

app.post('/api/admin/delete-user/:id', authMiddleware, async (req, res) => {
  const targetUserId = req.params.id;
  const targetUser = await User.findById(targetUserId);

  // 보안 이벤트 로깅
  logger.warn('User deletion attempt', {
    event: 'USER_DELETION',
    actor: req.user.id,
    actorEmail: req.user.email,
    target: targetUserId,
    targetEmail: targetUser?.email,
    ip: req.ip,
    timestamp: new Date().toISOString(),
  });

  await User.deleteOne({ _id: targetUserId });
  res.json({ success: true });
});
```

**로깅해야 할 보안 이벤트:**
- [ ] 로그인 성공/실패
- [ ] 비밀번호 변경/재설정
- [ ] 권한 변경
- [ ] 데이터 삭제/수정
- [ ] API Rate Limit 초과

---

## 인증 & 인가

### OAuth 2.0 + JWT (Next.js 15)

**설치:**
```bash
npm install next-auth@beta jsonwebtoken bcryptjs
```

**설정:**
```typescript
// app/api/auth/[...nextauth]/route.ts
import NextAuth from 'next-auth';
import CredentialsProvider from 'next-auth/providers/credentials';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

export const authOptions = {
  providers: [
    CredentialsProvider({
      name: 'Credentials',
      credentials: {
        email: { label: "Email", type: "email" },
        password: { label: "Password", type: "password" }
      },
      async authorize(credentials) {
        const user = await prisma.user.findUnique({
          where: { email: credentials.email }
        });

        if (!user) return null;

        const isValid = await bcrypt.compare(
          credentials.password,
          user.password
        );

        if (!isValid) return null;

        return { id: user.id, email: user.email, role: user.role };
      }
    })
  ],
  callbacks: {
    async jwt({ token, user }) {
      if (user) {
        token.role = user.role;
      }
      return token;
    },
    async session({ session, token }) {
      session.user.role = token.role;
      return session;
    }
  },
  session: {
    strategy: 'jwt',
    maxAge: 30 * 24 * 60 * 60, // 30일
  },
  jwt: {
    secret: process.env.NEXTAUTH_SECRET,
  },
};

const handler = NextAuth(authOptions);
export { handler as GET, handler as POST };
```

**권한 확인 미들웨어:**
```typescript
// middleware.ts
import { withAuth } from 'next-auth/middleware';

export default withAuth({
  callbacks: {
    authorized({ req, token }) {
      // /admin 경로는 admin 역할만
      if (req.nextUrl.pathname.startsWith('/admin')) {
        return token?.role === 'admin';
      }
      return !!token;
    },
  },
});

export const config = {
  matcher: ['/dashboard/:path*', '/admin/:path*']
};
```

---

### JWT 보안 Best Practices

**토큰 저장:**
```typescript
// ❌ 나쁜 예: localStorage (XSS 취약)
localStorage.setItem('token', jwt);

// ✅ 좋은 예: HttpOnly Cookie
res.setHeader('Set-Cookie', `token=${jwt}; HttpOnly; Secure; SameSite=Strict; Max-Age=86400`);
```

**토큰 검증:**
```typescript
// app/api/protected/route.ts
import { verify } from 'jsonwebtoken';

export async function GET(req: Request) {
  const token = req.headers.get('Authorization')?.split(' ')[1];

  if (!token) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 });
  }

  try {
    // 1. 서명 검증
    const payload = verify(token, process.env.JWT_SECRET!) as {
      userId: string;
      exp: number;
      iss: string;
      aud: string;
    };

    // 2. 만료 확인 (자동)
    // 3. Issuer 확인
    if (payload.iss !== 'your-app-name') {
      throw new Error('Invalid issuer');
    }

    // 4. Audience 확인
    if (payload.aud !== 'your-frontend-url') {
      throw new Error('Invalid audience');
    }

    // 요청 처리
    return Response.json({ userId: payload.userId });
  } catch (error) {
    return Response.json({ error: 'Invalid token' }, { status: 401 });
  }
}
```

**Short-lived Access Token + Refresh Token:**
```typescript
// Access Token: 15분
const accessToken = jwt.sign(
  { userId: user.id },
  process.env.JWT_SECRET!,
  { expiresIn: '15m' }
);

// Refresh Token: 7일 (DB에 저장)
const refreshToken = crypto.randomBytes(40).toString('hex');
await prisma.refreshToken.create({
  data: {
    token: refreshToken,
    userId: user.id,
    expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
  },
});
```

---

## XSS/CSRF/CORS 방어

### XSS (Cross-Site Scripting) 방지

**React 기본 보호:**
```jsx
// ✅ 안전: JSX는 자동 이스케이프
const userInput = '<img src=x onerror=alert(1)>';
return <div>{userInput}</div>;
// 렌더링: &lt;img src=x onerror=alert(1)&gt;
```

**위험한 패턴:**
```jsx
// ❌ 위험: dangerouslySetInnerHTML
<div dangerouslySetInnerHTML={{ __html: userInput }} />

// ✅ 안전: DOMPurify로 Sanitize
import DOMPurify from 'dompurify';

const cleanHTML = DOMPurify.sanitize(userInput);
<div dangerouslySetInnerHTML={{ __html: cleanHTML }} />
```

**URL Validation:**
```jsx
// ❌ 위험: javascript: 프로토콜
<a href={userInput}>Click</a>  // userInput = "javascript:alert(1)"

// ✅ 안전: URL 검증
const isSafeUrl = (url: string) => {
  try {
    const parsed = new URL(url);
    return ['http:', 'https:'].includes(parsed.protocol);
  } catch {
    return false;
  }
};

const SafeLink = ({ href, children }) => {
  if (!isSafeUrl(href)) {
    console.warn('Blocked unsafe URL:', href);
    return <span>{children}</span>;
  }
  return <a href={href}>{children}</a>;
};
```

---

### CSRF (Cross-Site Request Forgery) 방지

**Synchronizer Token Pattern (Node.js):**
```bash
npm install @dr.pogodin/csurf cookie-parser
```

```javascript
import csrf from '@dr.pogodin/csurf';
import cookieParser from 'cookie-parser';

app.use(cookieParser());

const csrfProtection = csrf({
  cookie: {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'strict',
  }
});

// GET: CSRF 토큰 발급
app.get('/api/csrf-token', csrfProtection, (req, res) => {
  res.json({ csrfToken: req.csrfToken() });
});

// POST: CSRF 토큰 검증
app.post('/api/transfer', csrfProtection, (req, res) => {
  // 토큰 불일치 시 자동 403 에러
  res.json({ success: true });
});
```

**React에서 CSRF 토큰 사용:**
```typescript
// hooks/useCsrfToken.ts
export const useCsrfToken = () => {
  const [csrfToken, setCsrfToken] = useState('');

  useEffect(() => {
    fetch('/api/csrf-token')
      .then(res => res.json())
      .then(data => setCsrfToken(data.csrfToken));
  }, []);

  return csrfToken;
};

// 사용
const csrfToken = useCsrfToken();

fetch('/api/transfer', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-Token': csrfToken,
  },
  body: JSON.stringify({ amount: 1000 }),
});
```

**SameSite Cookie (간단한 방법):**
```javascript
res.cookie('sessionId', sessionId, {
  httpOnly: true,
  secure: true,
  sameSite: 'strict',  // CSRF 방어
  maxAge: 24 * 60 * 60 * 1000,
});
```

---

### CORS (Cross-Origin Resource Sharing) 설정

**문제:**
```javascript
// ❌ 위험: 모든 도메인 허용
app.use(cors({ origin: '*' }));
```

**해결:**
```javascript
// ✅ 안전: 화이트리스트
const allowedOrigins = [
  'https://myapp.com',
  'https://www.myapp.com',
  process.env.NODE_ENV === 'development' && 'http://localhost:3000',
].filter(Boolean);

app.use(cors({
  origin: (origin, callback) => {
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,  // 쿠키 전송 허용
  maxAge: 86400,      // Preflight 캐싱 24시간
}));
```

**Next.js 15:**
```typescript
// middleware.ts
export function middleware(req: Request) {
  const origin = req.headers.get('origin');
  const allowedOrigins = ['https://myapp.com'];

  if (origin && !allowedOrigins.includes(origin)) {
    return new Response('CORS Error', { status: 403 });
  }

  const res = NextResponse.next();
  res.headers.set('Access-Control-Allow-Origin', origin || '*');
  res.headers.set('Access-Control-Allow-Credentials', 'true');

  return res;
}
```

---

## API 보안

### Rate Limiting

**Express:**
```javascript
import rateLimit from 'express-rate-limit';

// API 전역 제한
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15분
  max: 100, // IP당 100회
  message: 'Too many requests from this IP',
  standardHeaders: true,
  legacyHeaders: false,
});

app.use('/api/', apiLimiter);

// 엄격한 제한 (로그인, 회원가입)
const strictLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  skipSuccessfulRequests: true,  // 성공 시 카운트 안 함
});

app.post('/api/login', strictLimiter, loginHandler);
```

**Next.js (Upstash Redis):**
```typescript
// app/api/protected/route.ts
import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(10, '10 s'),
  analytics: true,
});

export async function GET(req: Request) {
  const ip = req.headers.get('x-forwarded-for') ?? 'unknown';
  const { success } = await ratelimit.limit(ip);

  if (!success) {
    return Response.json({ error: 'Rate limit exceeded' }, { status: 429 });
  }

  return Response.json({ data: 'Protected data' });
}
```

---

### Input Validation (Zod)

```typescript
import { z } from 'zod';

const userSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8).regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/),
  age: z.number().min(18).max(120),
  website: z.string().url().optional(),
});

export async function POST(req: Request) {
  const body = await req.json();

  try {
    const validated = userSchema.parse(body);
    // 검증된 데이터만 사용
    await createUser(validated);
    return Response.json({ success: true });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return Response.json({
        errors: error.errors
      }, { status: 400 });
    }
  }
}
```

---

### SQL Injection 방지

**Prisma (자동 방어):**
```typescript
// ✅ 안전: 파라미터화된 쿼리
const user = await prisma.user.findUnique({
  where: { email: userInput },
});
```

**Raw SQL 사용 시:**
```typescript
// ❌ 위험
const users = await prisma.$queryRawUnsafe(
  `SELECT * FROM users WHERE email = '${userInput}'`
);

// ✅ 안전: 파라미터 바인딩
const users = await prisma.$queryRaw`
  SELECT * FROM users WHERE email = ${userInput}
`;
```

---

## Secrets 관리

### 환경 변수 (개발)

```bash
# .env (절대 Git에 커밋하지 말 것)
DATABASE_URL="postgresql://user:pass@localhost:5432/db"
JWT_SECRET="your-secret-key-here"
STRIPE_SECRET_KEY="sk_test_..."
```

```javascript
// .gitignore
.env
.env.local
.env.production
```

---

### AWS Secrets Manager (프로덕션)

**설치:**
```bash
npm install @aws-sdk/client-secrets-manager
```

**사용:**
```typescript
// lib/secrets.ts
import {
  SecretsManagerClient,
  GetSecretValueCommand
} from '@aws-sdk/client-secrets-manager';

const client = new SecretsManagerClient({ region: 'us-east-1' });

export async function getSecret(secretName: string) {
  const command = new GetSecretValueCommand({ SecretId: secretName });
  const response = await client.send(command);
  return JSON.parse(response.SecretString!);
}

// 사용
const dbCreds = await getSecret('prod/database');
const prisma = new PrismaClient({
  datasources: {
    db: { url: dbCreds.DATABASE_URL },
  },
});
```

**장점:**
- 자동 로테이션
- 암호화 저장
- IAM 권한 제어
- 감사 로그

---

### Vercel Environment Variables

**설정:**
```bash
# Vercel CLI
vercel env add JWT_SECRET production
vercel env add DATABASE_URL production
```

**Next.js에서 사용:**
```typescript
// 서버 컴포넌트/API만 접근 가능
const secret = process.env.JWT_SECRET;

// 클라이언트에서 접근 (NEXT_PUBLIC_ 접두사)
const apiUrl = process.env.NEXT_PUBLIC_API_URL;
```

---

## 실전 사례

### 사례: SaaS 앱 보안 강화

**Before**
```typescript
// 취약점 1: SQL Injection
const query = `SELECT * FROM users WHERE email = '${email}'`;

// 취약점 2: XSS
<div dangerouslySetInnerHTML={{ __html: comment }} />

// 취약점 3: 하드코딩된 시크릿
const stripe = new Stripe('sk_live_abc123...');

// 취약점 4: Rate Limiting 없음
app.post('/api/signup', signupHandler);
```

**After**
```typescript
// 1. Prisma로 SQL Injection 방지
const user = await prisma.user.findUnique({ where: { email } });

// 2. DOMPurify로 XSS 방지
import DOMPurify from 'dompurify';
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(comment) }} />

// 3. AWS Secrets Manager
const { STRIPE_SECRET } = await getSecret('prod/stripe');
const stripe = new Stripe(STRIPE_SECRET);

// 4. Rate Limiting
const signupLimiter = rateLimit({ windowMs: 60000, max: 3 });
app.post('/api/signup', signupLimiter, signupHandler);
```

**결과:**
- 보안 스캔: 23개 취약점 → 0개
- 가동 시간: 99.5% → 99.95%
- 고객 신뢰도: 34% 증가
- 보안 사고: 0건 (6개월)

**ROI:** 평균 데이터 유출 비용 $4.45M 회피

---

## 체크리스트

### 인증 & 인가
- [ ] JWT에 짧은 만료 시간 (15분)
- [ ] Refresh Token 구현
- [ ] HttpOnly 쿠키 사용
- [ ] Rate Limiting (로그인: 5회/15분)
- [ ] 비밀번호 해싱 (bcrypt)
- [ ] 2FA (선택)

### XSS/CSRF/CORS
- [ ] CSP 헤더 설정
- [ ] DOMPurify로 HTML Sanitize
- [ ] CSRF 토큰 또는 SameSite=Strict
- [ ] CORS 화이트리스트
- [ ] URL 프로토콜 검증

### API 보안
- [ ] HTTPS 강제
- [ ] Rate Limiting
- [ ] Input Validation (Zod)
- [ ] 파라미터화된 쿼리
- [ ] API 키 인증

### Secrets
- [ ] .env 파일 .gitignore
- [ ] AWS Secrets Manager (프로덕션)
- [ ] 시크릿 로테이션
- [ ] 최소 권한 원칙

### 모니터링
- [ ] 보안 이벤트 로깅
- [ ] 실패한 로그인 알림
- [ ] npm audit 정기 실행
- [ ] Dependabot 활성화
- [ ] OWASP ZAP 스캔

---

## 참고 자료

- [OWASP Top 10:2025](https://owasp.org/Top10/2025/en/)
- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)
- [OAuth 2.0 Security Best Practices](https://datatracker.ietf.org/doc/draft-ietf-oauth-security-topics-update/)
- [JWT Best Practices (Curity)](https://curity.io/resources/learn/jwt-best-practices/)
- [React Security Best Practices 2025](https://corgea.com/Learn/react-security-best-practices-2025)
- [Node.js CSRF Protection Guide](https://www.stackhawk.com/blog/node-js-csrf-protection-guide-examples-and-how-to-enable-it/)

---

**보안은 한 번의 설정이 아니라 지속적인 프로세스입니다! 🔒**
