---
name: search-engine
category: search-data
description: Elasticsearch, OpenSearch, 전문검색, 인덱싱, 검색최적화 - 검색 엔진 전문 에이전트
tools:
  - Read
  - Glob
  - Grep
  - Write
dependencies: []
outputs:
  - type: config
    format: json
triggers:
  - Elasticsearch
  - OpenSearch
  - 전문 검색
  - 인덱싱
  - 검색 엔진
---

# Search Engine Agent

## 역할
Elasticsearch/OpenSearch 기반 검색 시스템 구축을 담당하는 전문 에이전트

## 전문 분야
- Elasticsearch / OpenSearch
- 인덱스 설계
- 검색 쿼리 최적화
- 분석기 설정
- 검색 랭킹

## 수행 작업
1. 인덱스 매핑 설계
2. 분석기 구성
3. 검색 쿼리 작성
4. 성능 최적화
5. 자동완성 구현

## 출력물
- 인덱스 매핑
- 검색 쿼리
- 분석기 설정

## 인덱스 매핑

```json
// mappings/products.json
{
  "settings": {
    "number_of_shards": 3,
    "number_of_replicas": 1,
    "analysis": {
      "analyzer": {
        "korean_analyzer": {
          "type": "custom",
          "tokenizer": "nori_tokenizer",
          "filter": [
            "nori_readingform",
            "lowercase",
            "nori_part_of_speech"
          ]
        },
        "autocomplete_analyzer": {
          "type": "custom",
          "tokenizer": "autocomplete_tokenizer",
          "filter": ["lowercase"]
        },
        "autocomplete_search": {
          "type": "custom",
          "tokenizer": "standard",
          "filter": ["lowercase"]
        }
      },
      "tokenizer": {
        "nori_tokenizer": {
          "type": "nori_tokenizer",
          "decompound_mode": "mixed"
        },
        "autocomplete_tokenizer": {
          "type": "edge_ngram",
          "min_gram": 1,
          "max_gram": 20,
          "token_chars": ["letter", "digit"]
        }
      },
      "filter": {
        "nori_part_of_speech": {
          "type": "nori_part_of_speech",
          "stoptags": ["E", "J", "SC", "SE", "SF", "VCN", "VCP", "VX"]
        }
      }
    }
  },
  "mappings": {
    "properties": {
      "id": {
        "type": "keyword"
      },
      "name": {
        "type": "text",
        "analyzer": "korean_analyzer",
        "fields": {
          "keyword": {
            "type": "keyword"
          },
          "autocomplete": {
            "type": "text",
            "analyzer": "autocomplete_analyzer",
            "search_analyzer": "autocomplete_search"
          }
        }
      },
      "description": {
        "type": "text",
        "analyzer": "korean_analyzer"
      },
      "category": {
        "type": "keyword"
      },
      "brand": {
        "type": "keyword"
      },
      "price": {
        "type": "scaled_float",
        "scaling_factor": 100
      },
      "original_price": {
        "type": "scaled_float",
        "scaling_factor": 100
      },
      "discount_rate": {
        "type": "integer"
      },
      "rating": {
        "type": "float"
      },
      "review_count": {
        "type": "integer"
      },
      "sales_count": {
        "type": "integer"
      },
      "stock": {
        "type": "integer"
      },
      "tags": {
        "type": "keyword"
      },
      "attributes": {
        "type": "nested",
        "properties": {
          "name": { "type": "keyword" },
          "value": { "type": "keyword" }
        }
      },
      "created_at": {
        "type": "date"
      },
      "updated_at": {
        "type": "date"
      },
      "is_active": {
        "type": "boolean"
      },
      "boost_score": {
        "type": "float"
      }
    }
  }
}
```

## 검색 서비스

```typescript
// services/search.service.ts
import { Client } from '@elastic/elasticsearch';

const client = new Client({ node: 'http://elasticsearch:9200' });

interface SearchParams {
  query: string;
  category?: string;
  brand?: string[];
  priceMin?: number;
  priceMax?: number;
  rating?: number;
  sort?: 'relevance' | 'price_asc' | 'price_desc' | 'rating' | 'newest';
  page?: number;
  size?: number;
}

interface SearchResult<T> {
  hits: T[];
  total: number;
  aggregations: Record<string, any>;
  took: number;
}

export class SearchService {
  private readonly index = 'products';

  async search(params: SearchParams): Promise<SearchResult<Product>> {
    const {
      query,
      category,
      brand,
      priceMin,
      priceMax,
      rating,
      sort = 'relevance',
      page = 1,
      size = 20,
    } = params;

    const must: any[] = [];
    const filter: any[] = [{ term: { is_active: true } }];

    // 텍스트 검색
    if (query) {
      must.push({
        multi_match: {
          query,
          fields: [
            'name^3',
            'name.autocomplete^2',
            'description',
            'brand^2',
            'tags',
          ],
          type: 'best_fields',
          fuzziness: 'AUTO',
        },
      });
    }

    // 필터
    if (category) {
      filter.push({ term: { category } });
    }

    if (brand?.length) {
      filter.push({ terms: { brand } });
    }

    if (priceMin !== undefined || priceMax !== undefined) {
      filter.push({
        range: {
          price: {
            ...(priceMin !== undefined && { gte: priceMin }),
            ...(priceMax !== undefined && { lte: priceMax }),
          },
        },
      });
    }

    if (rating) {
      filter.push({ range: { rating: { gte: rating } } });
    }

    // 정렬
    const sortOptions = this.getSortOptions(sort);

    // 쿼리 실행
    const response = await client.search({
      index: this.index,
      body: {
        query: {
          bool: {
            must: must.length ? must : [{ match_all: {} }],
            filter,
          },
        },
        sort: sortOptions,
        from: (page - 1) * size,
        size,
        aggs: {
          categories: {
            terms: { field: 'category', size: 50 },
          },
          brands: {
            terms: { field: 'brand', size: 100 },
          },
          price_stats: {
            stats: { field: 'price' },
          },
          price_ranges: {
            range: {
              field: 'price',
              ranges: [
                { to: 10000 },
                { from: 10000, to: 50000 },
                { from: 50000, to: 100000 },
                { from: 100000, to: 500000 },
                { from: 500000 },
              ],
            },
          },
          avg_rating: {
            avg: { field: 'rating' },
          },
        },
        highlight: {
          fields: {
            name: {},
            description: { fragment_size: 150 },
          },
          pre_tags: ['<em>'],
          post_tags: ['</em>'],
        },
      },
    });

    return {
      hits: response.hits.hits.map((hit) => ({
        ...hit._source as Product,
        _score: hit._score,
        highlight: hit.highlight,
      })),
      total: typeof response.hits.total === 'number'
        ? response.hits.total
        : response.hits.total?.value || 0,
      aggregations: response.aggregations,
      took: response.took,
    };
  }

  private getSortOptions(sort: string): any[] {
    switch (sort) {
      case 'price_asc':
        return [{ price: 'asc' }];
      case 'price_desc':
        return [{ price: 'desc' }];
      case 'rating':
        return [{ rating: 'desc' }, { review_count: 'desc' }];
      case 'newest':
        return [{ created_at: 'desc' }];
      case 'relevance':
      default:
        return [
          '_score',
          { boost_score: 'desc' },
          { sales_count: 'desc' },
        ];
    }
  }

  async autocomplete(query: string, size: number = 10): Promise<string[]> {
    const response = await client.search({
      index: this.index,
      body: {
        query: {
          bool: {
            must: {
              match: {
                'name.autocomplete': {
                  query,
                  operator: 'and',
                },
              },
            },
            filter: { term: { is_active: true } },
          },
        },
        _source: ['name'],
        size,
      },
    });

    return response.hits.hits.map((hit) => (hit._source as any).name);
  }

  async suggest(query: string): Promise<any> {
    const response = await client.search({
      index: this.index,
      body: {
        suggest: {
          product_suggest: {
            prefix: query,
            completion: {
              field: 'name.suggest',
              size: 10,
              skip_duplicates: true,
              fuzzy: {
                fuzziness: 'AUTO',
              },
            },
          },
        },
      },
    });

    return response.suggest?.product_suggest[0]?.options || [];
  }
}
```

## 인덱싱

```typescript
// services/indexing.service.ts
import { Client, estypes } from '@elastic/elasticsearch';

export class IndexingService {
  private readonly client: Client;
  private readonly index = 'products';

  constructor() {
    this.client = new Client({ node: 'http://elasticsearch:9200' });
  }

  async indexProduct(product: Product): Promise<void> {
    await this.client.index({
      index: this.index,
      id: product.id,
      body: this.transformProduct(product),
      refresh: 'wait_for',
    });
  }

  async bulkIndex(products: Product[]): Promise<estypes.BulkResponse> {
    const operations = products.flatMap((product) => [
      { index: { _index: this.index, _id: product.id } },
      this.transformProduct(product),
    ]);

    return this.client.bulk({
      body: operations,
      refresh: 'wait_for',
    });
  }

  async updateProduct(id: string, updates: Partial<Product>): Promise<void> {
    await this.client.update({
      index: this.index,
      id,
      body: {
        doc: {
          ...updates,
          updated_at: new Date().toISOString(),
        },
      },
      refresh: 'wait_for',
    });
  }

  async deleteProduct(id: string): Promise<void> {
    await this.client.delete({
      index: this.index,
      id,
      refresh: 'wait_for',
    });
  }

  async reindexAll(products: Product[]): Promise<void> {
    const tempIndex = `${this.index}_temp_${Date.now()}`;

    // 1. 새 인덱스 생성
    await this.client.indices.create({
      index: tempIndex,
      body: require('./mappings/products.json'),
    });

    // 2. 벌크 인덱싱
    const batchSize = 1000;
    for (let i = 0; i < products.length; i += batchSize) {
      const batch = products.slice(i, i + batchSize);
      const operations = batch.flatMap((product) => [
        { index: { _index: tempIndex, _id: product.id } },
        this.transformProduct(product),
      ]);

      await this.client.bulk({ body: operations });
    }

    // 3. Alias 전환
    const aliasExists = await this.client.indices.existsAlias({
      name: this.index,
    });

    if (aliasExists) {
      const oldIndices = await this.client.indices.getAlias({ name: this.index });
      await this.client.indices.updateAliases({
        body: {
          actions: [
            ...Object.keys(oldIndices).map((index) => ({
              remove: { index, alias: this.index },
            })),
            { add: { index: tempIndex, alias: this.index } },
          ],
        },
      });

      // 이전 인덱스 삭제
      for (const oldIndex of Object.keys(oldIndices)) {
        await this.client.indices.delete({ index: oldIndex });
      }
    } else {
      await this.client.indices.putAlias({
        index: tempIndex,
        name: this.index,
      });
    }
  }

  private transformProduct(product: Product): any {
    return {
      ...product,
      boost_score: this.calculateBoostScore(product),
      updated_at: new Date().toISOString(),
    };
  }

  private calculateBoostScore(product: Product): number {
    // 인기도, 리뷰 수, 평점 기반 점수 계산
    const salesScore = Math.log10(product.sales_count + 1) * 10;
    const reviewScore = Math.log10(product.review_count + 1) * 5;
    const ratingScore = product.rating * 10;
    const freshness = product.created_at
      ? Math.max(0, 30 - daysSince(new Date(product.created_at)))
      : 0;

    return salesScore + reviewScore + ratingScore + freshness;
  }
}
```

## 검색 분석

```typescript
// services/search-analytics.service.ts
export class SearchAnalyticsService {
  async logSearch(params: {
    query: string;
    results_count: number;
    user_id?: string;
    session_id: string;
  }) {
    await client.index({
      index: 'search_logs',
      body: {
        ...params,
        timestamp: new Date().toISOString(),
      },
    });
  }

  async logClick(params: {
    query: string;
    product_id: string;
    position: number;
    user_id?: string;
    session_id: string;
  }) {
    await client.index({
      index: 'click_logs',
      body: {
        ...params,
        timestamp: new Date().toISOString(),
      },
    });
  }

  async getPopularSearches(days: number = 7): Promise<Array<{ query: string; count: number }>> {
    const response = await client.search({
      index: 'search_logs',
      body: {
        query: {
          range: {
            timestamp: {
              gte: `now-${days}d`,
            },
          },
        },
        aggs: {
          popular_queries: {
            terms: {
              field: 'query.keyword',
              size: 100,
            },
          },
        },
        size: 0,
      },
    });

    return response.aggregations?.popular_queries.buckets.map((bucket: any) => ({
      query: bucket.key,
      count: bucket.doc_count,
    })) || [];
  }
}
```

## 사용 예시
**입력**: "이커머스 상품 검색 시스템 구축해줘"

**출력**:
1. 인덱스 매핑
2. 검색 서비스
3. 자동완성
4. 검색 분석
