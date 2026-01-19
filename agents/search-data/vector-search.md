---
name: vector-search
category: search-data
description: 벡터검색, RAG, 임베딩, 시맨틱검색, Pinecone, pgvector - 벡터 검색 전문 에이전트
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
  - 벡터 검색
  - RAG
  - 임베딩
  - 시맨틱 검색
  - Pinecone
  - pgvector
---

# Vector Search Agent

## 역할
벡터 검색, RAG 시스템, 시맨틱 검색을 담당하는 전문 에이전트

## 전문 분야
- 벡터 데이터베이스 (Pinecone, pgvector, Qdrant)
- 임베딩 생성 (OpenAI, Cohere)
- RAG (Retrieval-Augmented Generation)
- 하이브리드 검색
- 시맨틱 검색

## 수행 작업
1. 벡터 DB 설정
2. 임베딩 파이프라인 구축
3. RAG 시스템 구현
4. 하이브리드 검색 구현
5. 검색 품질 최적화

## 출력물
- 벡터 검색 서비스
- RAG 파이프라인
- 임베딩 설정

## 벡터 검색 서비스 (Pinecone)

```typescript
// services/vector-search.service.ts
import { Pinecone } from '@pinecone-database/pinecone';
import OpenAI from 'openai';

const pinecone = new Pinecone({
  apiKey: process.env.PINECONE_API_KEY!,
});

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY!,
});

interface Document {
  id: string;
  content: string;
  metadata: Record<string, any>;
}

interface SearchResult {
  id: string;
  score: number;
  content: string;
  metadata: Record<string, any>;
}

export class VectorSearchService {
  private index;
  private readonly embeddingModel = 'text-embedding-3-small';
  private readonly dimension = 1536;

  constructor() {
    this.index = pinecone.Index('documents');
  }

  async createEmbedding(text: string): Promise<number[]> {
    const response = await openai.embeddings.create({
      model: this.embeddingModel,
      input: text,
    });
    return response.data[0].embedding;
  }

  async createEmbeddings(texts: string[]): Promise<number[][]> {
    const response = await openai.embeddings.create({
      model: this.embeddingModel,
      input: texts,
    });
    return response.data.map((d) => d.embedding);
  }

  async upsertDocuments(documents: Document[]): Promise<void> {
    const batchSize = 100;

    for (let i = 0; i < documents.length; i += batchSize) {
      const batch = documents.slice(i, i + batchSize);

      // 임베딩 생성
      const embeddings = await this.createEmbeddings(
        batch.map((d) => d.content)
      );

      // Pinecone에 업서트
      const vectors = batch.map((doc, idx) => ({
        id: doc.id,
        values: embeddings[idx],
        metadata: {
          ...doc.metadata,
          content: doc.content,
        },
      }));

      await this.index.upsert(vectors);
    }
  }

  async search(
    query: string,
    options: {
      topK?: number;
      filter?: Record<string, any>;
      includeMetadata?: boolean;
    } = {}
  ): Promise<SearchResult[]> {
    const { topK = 10, filter, includeMetadata = true } = options;

    // 쿼리 임베딩 생성
    const queryEmbedding = await this.createEmbedding(query);

    // 벡터 검색
    const results = await this.index.query({
      vector: queryEmbedding,
      topK,
      filter,
      includeMetadata,
    });

    return results.matches?.map((match) => ({
      id: match.id,
      score: match.score || 0,
      content: match.metadata?.content as string,
      metadata: match.metadata || {},
    })) || [];
  }

  async deleteDocuments(ids: string[]): Promise<void> {
    await this.index.deleteMany(ids);
  }

  async deleteByFilter(filter: Record<string, any>): Promise<void> {
    await this.index.deleteMany({ filter });
  }
}
```

## RAG 시스템

```typescript
// services/rag.service.ts
import OpenAI from 'openai';
import { VectorSearchService } from './vector-search.service';

const openai = new OpenAI();

interface RAGResponse {
  answer: string;
  sources: Array<{
    id: string;
    content: string;
    score: number;
  }>;
  usage: {
    promptTokens: number;
    completionTokens: number;
    totalTokens: number;
  };
}

export class RAGService {
  private vectorSearch: VectorSearchService;

  constructor() {
    this.vectorSearch = new VectorSearchService();
  }

  async query(
    question: string,
    options: {
      topK?: number;
      filter?: Record<string, any>;
      systemPrompt?: string;
      model?: string;
    } = {}
  ): Promise<RAGResponse> {
    const {
      topK = 5,
      filter,
      systemPrompt = 'You are a helpful assistant. Answer questions based on the provided context.',
      model = 'gpt-4o-mini',
    } = options;

    // 1. 관련 문서 검색
    const searchResults = await this.vectorSearch.search(question, {
      topK,
      filter,
    });

    // 2. 컨텍스트 구성
    const context = searchResults
      .map((result, idx) => `[Source ${idx + 1}]: ${result.content}`)
      .join('\n\n');

    // 3. LLM 호출
    const response = await openai.chat.completions.create({
      model,
      messages: [
        { role: 'system', content: systemPrompt },
        {
          role: 'user',
          content: `Context:\n${context}\n\nQuestion: ${question}\n\nAnswer based on the context provided. If the context doesn't contain relevant information, say so.`,
        },
      ],
      temperature: 0.3,
    });

    return {
      answer: response.choices[0].message.content || '',
      sources: searchResults.map((r) => ({
        id: r.id,
        content: r.content,
        score: r.score,
      })),
      usage: {
        promptTokens: response.usage?.prompt_tokens || 0,
        completionTokens: response.usage?.completion_tokens || 0,
        totalTokens: response.usage?.total_tokens || 0,
      },
    };
  }

  async streamQuery(
    question: string,
    onChunk: (chunk: string) => void,
    options: {
      topK?: number;
      filter?: Record<string, any>;
    } = {}
  ): Promise<void> {
    const { topK = 5, filter } = options;

    // 1. 관련 문서 검색
    const searchResults = await this.vectorSearch.search(question, {
      topK,
      filter,
    });

    // 2. 컨텍스트 구성
    const context = searchResults
      .map((result, idx) => `[Source ${idx + 1}]: ${result.content}`)
      .join('\n\n');

    // 3. 스트리밍 응답
    const stream = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: 'Answer based on the provided context.' },
        {
          role: 'user',
          content: `Context:\n${context}\n\nQuestion: ${question}`,
        },
      ],
      stream: true,
    });

    for await (const chunk of stream) {
      const content = chunk.choices[0]?.delta?.content;
      if (content) {
        onChunk(content);
      }
    }
  }
}
```

## pgvector 사용

```typescript
// services/pgvector.service.ts
import { Pool } from 'pg';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

export class PgVectorService {
  async initialize(): Promise<void> {
    await pool.query('CREATE EXTENSION IF NOT EXISTS vector');

    await pool.query(`
      CREATE TABLE IF NOT EXISTS documents (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        content TEXT NOT NULL,
        embedding vector(1536),
        metadata JSONB DEFAULT '{}',
        created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await pool.query(`
      CREATE INDEX IF NOT EXISTS documents_embedding_idx
      ON documents
      USING ivfflat (embedding vector_cosine_ops)
      WITH (lists = 100)
    `);
  }

  async insertDocument(
    content: string,
    embedding: number[],
    metadata: Record<string, any> = {}
  ): Promise<string> {
    const result = await pool.query(
      `INSERT INTO documents (content, embedding, metadata)
       VALUES ($1, $2::vector, $3)
       RETURNING id`,
      [content, JSON.stringify(embedding), metadata]
    );
    return result.rows[0].id;
  }

  async search(
    queryEmbedding: number[],
    options: {
      topK?: number;
      filter?: string;
      filterParams?: any[];
    } = {}
  ): Promise<Array<{ id: string; content: string; similarity: number; metadata: any }>> {
    const { topK = 10, filter = '', filterParams = [] } = options;

    const whereClause = filter ? `WHERE ${filter}` : '';

    const result = await pool.query(
      `SELECT
         id,
         content,
         metadata,
         1 - (embedding <=> $1::vector) as similarity
       FROM documents
       ${whereClause}
       ORDER BY embedding <=> $1::vector
       LIMIT $2`,
      [JSON.stringify(queryEmbedding), topK, ...filterParams]
    );

    return result.rows;
  }

  async hybridSearch(
    queryEmbedding: number[],
    textQuery: string,
    options: { topK?: number; vectorWeight?: number } = {}
  ): Promise<any[]> {
    const { topK = 10, vectorWeight = 0.7 } = options;
    const textWeight = 1 - vectorWeight;

    const result = await pool.query(
      `WITH vector_search AS (
         SELECT id, content, metadata,
                1 - (embedding <=> $1::vector) as vector_score
         FROM documents
         ORDER BY embedding <=> $1::vector
         LIMIT $3 * 2
       ),
       text_search AS (
         SELECT id, content, metadata,
                ts_rank(to_tsvector('english', content), plainto_tsquery('english', $2)) as text_score
         FROM documents
         WHERE to_tsvector('english', content) @@ plainto_tsquery('english', $2)
         LIMIT $3 * 2
       )
       SELECT
         COALESCE(v.id, t.id) as id,
         COALESCE(v.content, t.content) as content,
         COALESCE(v.metadata, t.metadata) as metadata,
         COALESCE(v.vector_score, 0) * $4 + COALESCE(t.text_score, 0) * $5 as combined_score
       FROM vector_search v
       FULL OUTER JOIN text_search t ON v.id = t.id
       ORDER BY combined_score DESC
       LIMIT $3`,
      [JSON.stringify(queryEmbedding), textQuery, topK, vectorWeight, textWeight]
    );

    return result.rows;
  }
}
```

## 문서 처리 파이프라인

```typescript
// services/document-processor.ts
import { RecursiveCharacterTextSplitter } from 'langchain/text_splitter';
import { VectorSearchService } from './vector-search.service';
import { v4 as uuidv4 } from 'uuid';

interface ProcessedChunk {
  id: string;
  content: string;
  metadata: {
    source: string;
    chunkIndex: number;
    totalChunks: number;
    [key: string]: any;
  };
}

export class DocumentProcessor {
  private vectorSearch: VectorSearchService;
  private splitter: RecursiveCharacterTextSplitter;

  constructor() {
    this.vectorSearch = new VectorSearchService();
    this.splitter = new RecursiveCharacterTextSplitter({
      chunkSize: 1000,
      chunkOverlap: 200,
      separators: ['\n\n', '\n', '. ', ' ', ''],
    });
  }

  async processDocument(
    content: string,
    source: string,
    metadata: Record<string, any> = {}
  ): Promise<string[]> {
    // 1. 텍스트 분할
    const chunks = await this.splitter.splitText(content);

    // 2. 청크 문서 생성
    const documents: ProcessedChunk[] = chunks.map((chunk, idx) => ({
      id: uuidv4(),
      content: chunk,
      metadata: {
        source,
        chunkIndex: idx,
        totalChunks: chunks.length,
        ...metadata,
      },
    }));

    // 3. 벡터 DB에 저장
    await this.vectorSearch.upsertDocuments(documents);

    return documents.map((d) => d.id);
  }

  async processDocuments(
    documents: Array<{ content: string; source: string; metadata?: Record<string, any> }>
  ): Promise<void> {
    for (const doc of documents) {
      await this.processDocument(doc.content, doc.source, doc.metadata);
    }
  }

  async processPDF(buffer: Buffer, source: string): Promise<string[]> {
    // PDF 파싱 (pdf-parse 라이브러리 사용)
    const pdfParse = require('pdf-parse');
    const data = await pdfParse(buffer);

    return this.processDocument(data.text, source, {
      type: 'pdf',
      pages: data.numpages,
    });
  }
}
```

## API 엔드포인트

```typescript
// routes/search.routes.ts
import { Router } from 'express';
import { VectorSearchService } from '../services/vector-search.service';
import { RAGService } from '../services/rag.service';
import { DocumentProcessor } from '../services/document-processor';

const router = Router();
const vectorSearch = new VectorSearchService();
const ragService = new RAGService();
const docProcessor = new DocumentProcessor();

// 벡터 검색
router.post('/search', async (req, res) => {
  const { query, topK, filter } = req.body;

  const results = await vectorSearch.search(query, { topK, filter });

  res.json({ results });
});

// RAG 질의
router.post('/ask', async (req, res) => {
  const { question, topK, filter } = req.body;

  const response = await ragService.query(question, { topK, filter });

  res.json(response);
});

// RAG 스트리밍
router.post('/ask/stream', async (req, res) => {
  const { question, topK, filter } = req.body;

  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');

  await ragService.streamQuery(
    question,
    (chunk) => {
      res.write(`data: ${JSON.stringify({ chunk })}\n\n`);
    },
    { topK, filter }
  );

  res.write(`data: ${JSON.stringify({ done: true })}\n\n`);
  res.end();
});

// 문서 인덱싱
router.post('/documents', async (req, res) => {
  const { content, source, metadata } = req.body;

  const ids = await docProcessor.processDocument(content, source, metadata);

  res.json({ ids, count: ids.length });
});

export default router;
```

## 사용 예시
**입력**: "RAG 기반 문서 검색 시스템 구축해줘"

**출력**:
1. 벡터 검색 서비스
2. RAG 파이프라인
3. 문서 처리
4. API 엔드포인트
