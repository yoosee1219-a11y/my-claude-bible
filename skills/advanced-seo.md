# Advanced SEO

> Next.js Metadata API, Core Web Vitals, Structured Data로 검색 순위 1페이지 달성 (2026)

## 목차

1. [SEO가 왜 중요한가?](#seo가-왜-중요한가)
2. [Next.js Metadata API](#nextjs-metadata-api)
3. [Core Web Vitals 최적화](#core-web-vitals-최적화)
4. [Structured Data (JSON-LD)](#structured-data-json-ld)
5. [Technical SEO](#technical-seo)
6. [실전 사례](#실전-사례)

---

## SEO가 왜 중요한가?

### 통계 (2026)

- 유기적 검색: 전체 트래픽의 53.3%
- 1위 클릭률: 39.8%
- 2위 클릭률: 18.7%
- 10위 클릭률: 2.2%
- 2페이지 도달률: <1%

**→ 1페이지 진입 = 필수**

---

### SEO의 ROI

**Before**
```
- 유료 광고 의존: $5,000/월
- CPC: $2.50
- 월 방문자: 2,000명
```

**After (SEO 최적화)**
```
✅ 유기적 검색: 80% 트래픽
✅ 광고 비용: $5,000 → $2,000 (60% 절감)
✅ 월 방문자: 2,000 → 10,000명 (5배)
✅ 전환율: 2% → 4% (품질 높은 트래픽)
```

---

## Next.js Metadata API

### 기본 메타데이터

**app/layout.tsx:**
```typescript
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: {
    template: '%s | MyApp',
    default: 'MyApp - Best SaaS Solution',
  },
  description: 'Transform your business with MyApp - the leading SaaS platform for modern teams',
  keywords: ['saas', 'productivity', 'collaboration', 'team management'],
  authors: [{ name: 'MyApp Team' }],
  creator: 'MyApp Inc',
  publisher: 'MyApp Inc',

  // Open Graph
  openGraph: {
    type: 'website',
    locale: 'en_US',
    url: 'https://myapp.com',
    siteName: 'MyApp',
    title: 'MyApp - Best SaaS Solution',
    description: 'Transform your business with MyApp',
    images: [
      {
        url: 'https://myapp.com/og-image.png',
        width: 1200,
        height: 630,
        alt: 'MyApp',
      },
    ],
  },

  // Twitter
  twitter: {
    card: 'summary_large_image',
    site: '@myapp',
    creator: '@myapp',
    title: 'MyApp - Best SaaS Solution',
    description: 'Transform your business with MyApp',
    images: ['https://myapp.com/twitter-image.png'],
  },

  // Robots
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-video-preview': -1,
      'max-image-preview': 'large',
      'max-snippet': -1,
    },
  },

  // Icons
  icons: {
    icon: '/favicon.ico',
    shortcut: '/shortcut-icon.png',
    apple: '/apple-icon.png',
  },

  // Manifest
  manifest: '/manifest.json',
};
```

---

### 동적 메타데이터

**app/blog/[slug]/page.tsx:**
```typescript
import { Metadata } from 'next';
import { notFound } from 'next/navigation';

interface Props {
  params: { slug: string };
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const post = await prisma.post.findUnique({
    where: { slug: params.slug },
  });

  if (!post) {
    return {};
  }

  return {
    title: post.title,
    description: post.excerpt,
    authors: [{ name: post.author.name }],

    openGraph: {
      title: post.title,
      description: post.excerpt,
      type: 'article',
      publishedTime: post.publishedAt?.toISOString(),
      authors: [post.author.name],
      images: [
        {
          url: post.coverImage,
          width: 1200,
          height: 630,
          alt: post.title,
        },
      ],
    },

    twitter: {
      card: 'summary_large_image',
      title: post.title,
      description: post.excerpt,
      images: [post.coverImage],
    },
  };
}

export default async function BlogPost({ params }: Props) {
  const post = await prisma.post.findUnique({
    where: { slug: params.slug },
  });

  if (!post) {
    notFound();
  }

  return <article>{/* ... */}</article>;
}
```

---

### Canonical URL

```typescript
export const metadata: Metadata = {
  // 중복 콘텐츠 방지
  alternates: {
    canonical: 'https://myapp.com/blog/seo-guide',
  },
};
```

---

### Sitemap & Robots.txt

**app/sitemap.ts:**
```typescript
import { MetadataRoute } from 'next';

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const baseUrl = 'https://myapp.com';

  // 정적 페이지
  const staticPages = ['', '/about', '/pricing', '/contact'].map(route => ({
    url: `${baseUrl}${route}`,
    lastModified: new Date(),
    changeFrequency: 'monthly' as const,
    priority: route === '' ? 1 : 0.8,
  }));

  // 동적 페이지 (블로그 포스트)
  const posts = await prisma.post.findMany({
    select: { slug: true, updatedAt: true },
  });

  const postPages = posts.map(post => ({
    url: `${baseUrl}/blog/${post.slug}`,
    lastModified: post.updatedAt,
    changeFrequency: 'weekly' as const,
    priority: 0.6,
  }));

  return [...staticPages, ...postPages];
}
```

**app/robots.ts:**
```typescript
import { MetadataRoute } from 'next';

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      {
        userAgent: '*',
        allow: '/',
        disallow: ['/admin/', '/api/', '/_next/'],
      },
    ],
    sitemap: 'https://myapp.com/sitemap.xml',
  };
}
```

---

## Core Web Vitals 최적화

### 3가지 핵심 메트릭

1. **LCP (Largest Contentful Paint)** - 로딩 성능
   - 목표: 2.5초 이내
   - 주요 콘텐츠가 얼마나 빨리 표시되는가

2. **INP (Interaction to Next Paint)** - 반응성
   - 목표: 200ms 이내
   - 사용자 상호작용에 얼마나 빨리 반응하는가

3. **CLS (Cumulative Layout Shift)** - 시각적 안정성
   - 목표: 0.1 미만
   - 레이아웃이 얼마나 안정적인가

---

### LCP 최적화

**문제:**
```typescript
// ❌ 나쁜 예: 큰 이미지 최적화 안 됨
<img src="/hero.jpg" alt="Hero" />
```

**해결:**
```typescript
// ✅ 좋은 예: Next.js Image 최적화
import Image from 'next/image';

<Image
  src="/hero.jpg"
  alt="Hero"
  width={1200}
  height={600}
  priority  // LCP 이미지는 priority 설정!
  placeholder="blur"
  blurDataURL="data:image/jpeg;base64,..."
/>
```

**추가 최적화:**
```typescript
// next.config.js
module.exports = {
  images: {
    formats: ['image/avif', 'image/webp'],
    deviceSizes: [640, 750, 828, 1080, 1200, 1920],
    imageSizes: [16, 32, 48, 64, 96, 128, 256, 384],
  },
};
```

---

### INP 최적화

**문제:**
```typescript
// ❌ 나쁜 예: 큰 JavaScript 번들
import { HeavyChart } from 'heavy-chart-library';

export default function Dashboard() {
  return <HeavyChart data={data} />;
}
```

**해결:**
```typescript
// ✅ 좋은 예: Dynamic Import + Suspense
import dynamic from 'next/dynamic';

const HeavyChart = dynamic(() => import('heavy-chart-library'), {
  loading: () => <div>Loading chart...</div>,
  ssr: false,
});

export default function Dashboard() {
  return <HeavyChart data={data} />;
}
```

**3rd-party 스크립트 최적화:**
```typescript
// ✅ Next.js Script 컴포넌트
import Script from 'next/script';

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}

        {/* Google Analytics - defer 로딩 */}
        <Script
          src="https://www.googletagmanager.com/gtag/js?id=GA_ID"
          strategy="afterInteractive"
        />
      </body>
    </html>
  );
}
```

---

### CLS 최적화

**문제:**
```typescript
// ❌ 나쁜 예: 이미지 크기 미지정
<img src="/product.jpg" alt="Product" />
```

**해결:**
```typescript
// ✅ 좋은 예: 크기 명시
<Image
  src="/product.jpg"
  alt="Product"
  width={300}
  height={400}
  // aspect-ratio 자동 유지
/>
```

**광고/배너 공간 예약:**
```css
/* ✅ 좋은 예: 광고 슬롯 예약 */
.ad-slot {
  min-height: 250px;
  background: #f0f0f0;
}
```

**폰트 로딩 최적화:**
```typescript
// next.config.js
import { Inter } from 'next/font/google';

const inter = Inter({
  subsets: ['latin'],
  display: 'swap',  // FOUT 방지
  preload: true,
});

export default function RootLayout({ children }) {
  return (
    <html className={inter.className}>
      <body>{children}</body>
    </html>
  );
}
```

---

## Structured Data (JSON-LD)

### Organization Schema

**app/layout.tsx:**
```typescript
export default function RootLayout({ children }) {
  const organizationSchema = {
    '@context': 'https://schema.org',
    '@type': 'Organization',
    name: 'MyApp Inc',
    url: 'https://myapp.com',
    logo: 'https://myapp.com/logo.png',
    sameAs: [
      'https://twitter.com/myapp',
      'https://linkedin.com/company/myapp',
      'https://facebook.com/myapp',
    ],
    contactPoint: {
      '@type': 'ContactPoint',
      telephone: '+1-555-123-4567',
      contactType: 'Customer Service',
    },
  };

  return (
    <html>
      <head>
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{
            __html: JSON.stringify(organizationSchema),
          }}
        />
      </head>
      <body>{children}</body>
    </html>
  );
}
```

---

### Article Schema (블로그)

**app/blog/[slug]/page.tsx:**
```typescript
export default function BlogPost({ post }) {
  const articleSchema = {
    '@context': 'https://schema.org',
    '@type': 'BlogPosting',
    headline: post.title,
    description: post.excerpt,
    image: post.coverImage,
    datePublished: post.publishedAt.toISOString(),
    dateModified: post.updatedAt.toISOString(),
    author: {
      '@type': 'Person',
      name: post.author.name,
      url: `https://myapp.com/authors/${post.author.slug}`,
    },
    publisher: {
      '@type': 'Organization',
      name: 'MyApp',
      logo: {
        '@type': 'ImageObject',
        url: 'https://myapp.com/logo.png',
      },
    },
    mainEntityOfPage: {
      '@type': 'WebPage',
      '@id': `https://myapp.com/blog/${post.slug}`,
    },
  };

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify(articleSchema),
        }}
      />
      <article>{/* ... */}</article>
    </>
  );
}
```

---

### Product Schema (E커머스)

```typescript
export default function ProductPage({ product }) {
  const productSchema = {
    '@context': 'https://schema.org',
    '@type': 'Product',
    name: product.name,
    image: product.images,
    description: product.description,
    brand: {
      '@type': 'Brand',
      name: product.brand,
    },
    offers: {
      '@type': 'Offer',
      url: `https://myapp.com/products/${product.slug}`,
      priceCurrency: 'USD',
      price: product.price,
      availability: product.inStock
        ? 'https://schema.org/InStock'
        : 'https://schema.org/OutOfStock',
      seller: {
        '@type': 'Organization',
        name: 'MyApp',
      },
    },
    aggregateRating: {
      '@type': 'AggregateRating',
      ratingValue: product.averageRating,
      reviewCount: product.reviewCount,
    },
  };

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify(productSchema),
        }}
      />
      <div>{/* ... */}</div>
    </>
  );
}
```

---

### FAQ Schema

```typescript
export default function FAQPage({ faqs }) {
  const faqSchema = {
    '@context': 'https://schema.org',
    '@type': 'FAQPage',
    mainEntity: faqs.map(faq => ({
      '@type': 'Question',
      name: faq.question,
      acceptedAnswer: {
        '@type': 'Answer',
        text: faq.answer,
      },
    })),
  };

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify(faqSchema),
        }}
      />
      <div>{/* ... */}</div>
    </>
  );
}
```

**결과:** FAQ 리치 스니펫 → CTR +35%

---

## Technical SEO

### 1. HTTPS

```bash
# Vercel은 자동 HTTPS
# 커스텀 도메인: Let's Encrypt 무료 SSL
```

---

### 2. Mobile-First

```typescript
// ✅ 반응형 디자인
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3">
  {products.map(product => (
    <ProductCard key={product.id} product={product} />
  ))}
</div>
```

---

### 3. URL 구조

```
✅ 좋은 예:
https://myapp.com/blog/seo-guide-2026
https://myapp.com/products/wireless-headphones

❌ 나쁜 예:
https://myapp.com/p?id=12345
https://myapp.com/blog/2026/01/09/post
```

---

### 4. Internal Linking

```typescript
import Link from 'next/link';

// ✅ 관련 콘텐츠 링크
<Link href="/blog/related-post" className="text-blue-600 hover:underline">
  Read more about SEO →
</Link>
```

---

### 5. Image Optimization

```typescript
// ✅ Alt 텍스트 (필수!)
<Image
  src="/product.jpg"
  alt="Wireless Bluetooth Headphones - Black"
  width={300}
  height={400}
/>

// ✅ 파일명
// 좋은 예: wireless-headphones-black.jpg
// 나쁜 예: IMG_1234.jpg
```

---

## 실전 사례

### 사례: SaaS 블로그 SEO 최적화

**Before**
```
- 월 방문자: 500명
- 주요 키워드 순위: 50위+
- Core Web Vitals: 모두 빨간색
- Structured Data: 없음
```

---

**최적화 작업:**

**1. Core Web Vitals 개선**
```typescript
// LCP: 4.2초 → 1.8초
- Next.js Image 최적화 (priority)
- 폰트 프리로드
- 불필요한 JavaScript 제거

// INP: 350ms → 120ms
- Dynamic Import 적용
- 3rd-party 스크립트 defer

// CLS: 0.25 → 0.05
- 이미지 크기 명시
- 폰트 display: swap
- 광고 공간 예약
```

---

**2. Metadata 최적화**
```typescript
// app/blog/[slug]/page.tsx
export async function generateMetadata({ params }): Promise<Metadata> {
  const post = await getPost(params.slug);

  return {
    title: `${post.title} | MyApp Blog`,
    description: post.excerpt,
    keywords: post.tags,

    openGraph: {
      title: post.title,
      description: post.excerpt,
      type: 'article',
      images: [{ url: post.coverImage, width: 1200, height: 630 }],
    },

    alternates: {
      canonical: `https://myapp.com/blog/${post.slug}`,
    },
  };
}
```

---

**3. Structured Data 추가**
```typescript
// Article Schema 모든 포스트에 적용
const articleSchema = {
  '@context': 'https://schema.org',
  '@type': 'BlogPosting',
  headline: post.title,
  datePublished: post.publishedAt,
  author: { '@type': 'Person', name: post.author.name },
  // ...
};

// Breadcrumb Schema
const breadcrumbSchema = {
  '@context': 'https://schema.org',
  '@type': 'BreadcrumbList',
  itemListElement: [
    { '@type': 'ListItem', position: 1, name: 'Home', item: 'https://myapp.com' },
    { '@type': 'ListItem', position: 2, name: 'Blog', item: 'https://myapp.com/blog' },
    { '@type': 'ListItem', position: 3, name: post.title },
  ],
};
```

---

**4. Internal Linking 전략**
```typescript
// 관련 포스트 추천
<section className="mt-12">
  <h2 className="text-2xl font-bold mb-4">Related Articles</h2>
  <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
    {relatedPosts.map(post => (
      <Link key={post.id} href={`/blog/${post.slug}`}>
        <article className="border rounded-lg p-4 hover:shadow-lg transition">
          <h3 className="font-semibold">{post.title}</h3>
          <p className="text-sm text-gray-600 mt-2">{post.excerpt}</p>
        </article>
      </Link>
    ))}
  </div>
</section>
```

---

**After (6개월)**
```
✅ 월 방문자: 500 → 15,000명 (30배)
✅ 주요 키워드 순위: 50위+ → 5-15위
✅ Core Web Vitals: 모두 녹색
✅ Structured Data: 100% 적용
✅ Rich Snippets: 80% 포스트
✅ CTR: 1.5% → 4.2% (180% 증가)
```

**결과:**
- 유기적 트래픽: +2,900%
- 리드 생성: +45%
- 광고 비용: $3,000 → $1,000 (67% 절감)
- 매출: +60%

**ROI:** 연간 $24,000 광고비 절감 + 매출 대폭 증가

---

## 체크리스트

### Metadata
- [ ] title, description 모든 페이지
- [ ] Open Graph 이미지 (1200×630px)
- [ ] Twitter Card
- [ ] Canonical URL
- [ ] Sitemap.xml
- [ ] Robots.txt

### Core Web Vitals
- [ ] LCP < 2.5초 (Next.js Image priority)
- [ ] INP < 200ms (Dynamic Import)
- [ ] CLS < 0.1 (이미지 크기 명시)
- [ ] 폰트 최적화 (display: swap)
- [ ] 3rd-party 스크립트 defer

### Structured Data
- [ ] Organization Schema
- [ ] Article/BlogPosting Schema
- [ ] Product Schema (E커머스)
- [ ] FAQ Schema
- [ ] Breadcrumb Schema
- [ ] Google Rich Results Test 통과

### Technical SEO
- [ ] HTTPS
- [ ] Mobile-Friendly
- [ ] SEO-friendly URL
- [ ] Internal Linking
- [ ] Image Alt Text
- [ ] 404 페이지

### 모니터링
- [ ] Google Search Console
- [ ] Google Analytics 4
- [ ] PageSpeed Insights
- [ ] Lighthouse CI
- [ ] Keyword Ranking 추적

---

## 참고 자료

- [Next.js SEO Documentation](https://nextjs.org/learn/seo)
- [Core Web Vitals Guide 2026](https://developers.google.com/search/docs/appearance/core-web-vitals)
- [Schema.org Documentation](https://schema.org/)
- [Google Rich Results Test](https://search.google.com/test/rich-results)
- [PageSpeed Insights](https://pagespeed.web.dev/)

---

**적절한 SEO 최적화로 검색 순위 1페이지에 진입하세요! 📈**
