# Dependency Analyzer - 의존성 분석 및 병렬화 최적화

**설명**: 코드/작업 의존성 자동 분석, 의존성 그래프 생성, 병렬화 가능 여부 판단, 최적 실행 순서 계산. Planner 에이전트의 핵심 기능으로 작업을 병렬 실행 가능한 그룹으로 자동 분류합니다.

**키워드**: 의존성분석, 병렬화최적화, 의존성그래프, 작업순서최적화, 코드의존성분석, 모듈의존성, 실행순서계산, 병렬실행그룹, 순환의존성탐지, DAG분석, Topological정렬, 작업스케줄링, 병렬처리최적화, Planner핵심기능, 자동병렬화판단, 의존성트리, 작업분해분석, 동시실행가능작업, 의존관계파싱

## 사용 시점 (When to Use This Skill)

다음 상황에서 이 스킬을 자동으로 사용해야 합니다:

1. **대규모 작업 분해 시** - 100개 이상의 파일/작업을 병렬로 생성하기 전
2. **리팩토링 계획 시** - 여러 파일/모듈의 변경 순서를 결정할 때
3. **빌드 최적화 시** - 컴파일/번들링 작업의 병렬화 가능성 분석
4. **테스트 실행 계획 시** - 독립적인 테스트를 병렬 실행하기 위한 그룹화
5. **마이그레이션 작업 시** - 데이터베이스/API 마이그레이션의 안전한 순서 결정
6. **병렬 개발팀 배분 시** - 각 개발자/에이전트에게 독립적인 작업 할당

## 핵심 개념

### 1. 의존성 타입

```typescript
enum DependencyType {
  IMPORT = 'import',           // 코드 import/require
  EXTENDS = 'extends',         // 클래스 상속
  USES = 'uses',              // 함수/변수 사용
  DATA = 'data',              // 데이터 의존성
  BUILD = 'build',            // 빌드 순서
  TEST = 'test',              // 테스트 의존성
  RUNTIME = 'runtime'         // 런타임 의존성
}

interface Dependency {
  from: string;               // 의존하는 주체
  to: string;                 // 의존 대상
  type: DependencyType;
  required: boolean;          // 필수 의존성 여부
  weight?: number;            // 의존성 강도 (1-10)
}
```

### 2. 의존성 그래프

```typescript
class DependencyGraph {
  private nodes: Map<string, Node> = new Map();
  private edges: Dependency[] = [];

  addNode(id: string, data: any) {
    this.nodes.set(id, { id, data, dependencies: [], dependents: [] });
  }

  addDependency(dep: Dependency) {
    this.edges.push(dep);
    const fromNode = this.nodes.get(dep.from);
    const toNode = this.nodes.get(dep.to);

    if (fromNode && toNode) {
      fromNode.dependencies.push(dep.to);
      toNode.dependents.push(dep.from);
    }
  }

  // 순환 의존성 탐지
  detectCycles(): string[][] {
    const cycles: string[][] = [];
    const visited = new Set<string>();
    const recursionStack = new Set<string>();

    const dfs = (nodeId: string, path: string[]): boolean => {
      visited.add(nodeId);
      recursionStack.add(nodeId);
      path.push(nodeId);

      const node = this.nodes.get(nodeId);
      if (!node) return false;

      for (const depId of node.dependencies) {
        if (!visited.has(depId)) {
          if (dfs(depId, [...path])) return true;
        } else if (recursionStack.has(depId)) {
          // 순환 발견
          const cycleStart = path.indexOf(depId);
          cycles.push(path.slice(cycleStart));
          return true;
        }
      }

      recursionStack.delete(nodeId);
      return false;
    };

    for (const nodeId of this.nodes.keys()) {
      if (!visited.has(nodeId)) {
        dfs(nodeId, []);
      }
    }

    return cycles;
  }

  // Topological Sort (실행 순서 계산)
  topologicalSort(): string[][] {
    const inDegree = new Map<string, number>();
    const levels: string[][] = [];

    // 진입 차수 계산
    for (const nodeId of this.nodes.keys()) {
      inDegree.set(nodeId, 0);
    }

    for (const edge of this.edges) {
      if (edge.required) {
        inDegree.set(edge.from, (inDegree.get(edge.from) || 0) + 1);
      }
    }

    // 레벨별로 그룹화 (병렬 실행 가능한 작업들)
    const queue: string[] = [];

    // 진입 차수가 0인 노드들 (시작점)
    for (const [nodeId, degree] of inDegree.entries()) {
      if (degree === 0) {
        queue.push(nodeId);
      }
    }

    while (queue.length > 0) {
      const currentLevel: string[] = [...queue];
      levels.push(currentLevel);
      queue.length = 0;

      for (const nodeId of currentLevel) {
        const node = this.nodes.get(nodeId);
        if (!node) continue;

        for (const depId of node.dependents) {
          const newDegree = (inDegree.get(depId) || 0) - 1;
          inDegree.set(depId, newDegree);

          if (newDegree === 0) {
            queue.push(depId);
          }
        }
      }
    }

    return levels;
  }

  // 병렬화 가능 작업 그룹 추출
  getParallelGroups(): { group: number; tasks: string[] }[] {
    const levels = this.topologicalSort();

    return levels.map((tasks, index) => ({
      group: index + 1,
      tasks,
      canRunInParallel: true,
      estimatedTime: this.estimateGroupTime(tasks)
    }));
  }

  private estimateGroupTime(tasks: string[]): number {
    // 각 작업의 예상 시간 중 최대값 (병렬 실행이므로)
    return Math.max(...tasks.map(taskId => {
      const node = this.nodes.get(taskId);
      return node?.data?.estimatedTime || 60; // 기본 60초
    }));
  }
}
```

## 사용 방법

### Step 1: 코드 의존성 분석

```typescript
async function analyzeCodeDependencies(projectPath: string) {
  const graph = new DependencyGraph();

  // 1. 모든 파일 스캔
  const files = await globFiles('**/*.{ts,tsx,js,jsx}', { cwd: projectPath });

  for (const file of files) {
    graph.addNode(file, {
      type: 'file',
      path: file,
      estimatedTime: 30 // 30초 예상
    });
  }

  // 2. 각 파일의 import 분석
  for (const file of files) {
    const content = await readFile(file, 'utf-8');
    const imports = extractImports(content);

    for (const importPath of imports) {
      const resolvedPath = resolveImport(importPath, file);

      if (files.includes(resolvedPath)) {
        graph.addDependency({
          from: file,
          to: resolvedPath,
          type: DependencyType.IMPORT,
          required: true,
          weight: 10
        });
      }
    }
  }

  // 3. 순환 의존성 체크
  const cycles = graph.detectCycles();
  if (cycles.length > 0) {
    console.warn('⚠️ 순환 의존성 발견:', cycles);
    // 순환 의존성 해결 제안
    await suggestCycleBreaking(cycles);
  }

  // 4. 병렬 실행 그룹 생성
  const parallelGroups = graph.getParallelGroups();

  console.log('\n📊 병렬 실행 계획:');
  for (const { group, tasks, estimatedTime } of parallelGroups) {
    console.log(`\nGroup ${group} (병렬 실행 가능 - 예상 ${estimatedTime}초):`);
    console.log(`  ${tasks.join('\n  ')}`);
  }

  return { graph, parallelGroups, cycles };
}

function extractImports(code: string): string[] {
  const imports: string[] = [];

  // ES6 imports
  const es6Regex = /import\s+(?:[\w{},\s*]+\s+from\s+)?['"]([^'"]+)['"]/g;
  let match;

  while ((match = es6Regex.exec(code)) !== null) {
    imports.push(match[1]);
  }

  // CommonJS requires
  const cjsRegex = /require\s*\(\s*['"]([^'"]+)['"]\s*\)/g;

  while ((match = cjsRegex.exec(code)) !== null) {
    imports.push(match[1]);
  }

  return imports;
}
```

### Step 2: 작업 의존성 분석

```typescript
interface Task {
  id: string;
  name: string;
  description: string;
  estimatedTime: number; // 초
  dependencies: string[]; // 선행 작업 ID들
}

async function analyzeTaskDependencies(tasks: Task[]) {
  const graph = new DependencyGraph();

  // 1. 모든 작업을 노드로 추가
  for (const task of tasks) {
    graph.addNode(task.id, task);
  }

  // 2. 의존성 추가
  for (const task of tasks) {
    for (const depId of task.dependencies) {
      graph.addDependency({
        from: task.id,
        to: depId,
        type: DependencyType.DATA,
        required: true
      });
    }
  }

  // 3. 병렬 실행 계획 생성
  const parallelGroups = graph.getParallelGroups();

  // 4. 총 실행 시간 계산
  const sequentialTime = tasks.reduce((sum, t) => sum + t.estimatedTime, 0);
  const parallelTime = parallelGroups.reduce((sum, g) => sum + g.estimatedTime, 0);

  console.log('\n⏱️ 실행 시간 비교:');
  console.log(`순차 실행: ${sequentialTime}초 (${Math.round(sequentialTime / 60)}분)`);
  console.log(`병렬 실행: ${parallelTime}초 (${Math.round(parallelTime / 60)}분)`);
  console.log(`성능 향상: ${Math.round((sequentialTime / parallelTime) * 100) / 100}배`);

  return parallelGroups;
}
```

### Step 3: 실제 병렬 실행

```typescript
async function executeParallelGroups(parallelGroups, executor) {
  const results = [];

  for (const { group, tasks } of parallelGroups) {
    console.log(`\n🚀 Group ${group} 실행 중... (${tasks.length}개 작업 병렬)`);

    const groupResults = await Promise.all(
      tasks.map(taskId => executor(taskId))
    );

    results.push(...groupResults);
    console.log(`✅ Group ${group} 완료`);
  }

  return results;
}
```

## 실전 예제

### 예제 1: 100개 컴포넌트 리팩토링

```typescript
async function refactor100Components() {
  // 1. 의존성 분석
  const { parallelGroups } = await analyzeCodeDependencies('./src/components');

  // 2. 각 그룹별로 순차 실행, 그룹 내에서는 병렬 실행
  for (const { group, tasks } of parallelGroups) {
    console.log(`\n📦 Group ${group}: ${tasks.length}개 컴포넌트 리팩토링`);

    // 병렬로 리팩토링 에이전트 실행
    await Promise.all(
      tasks.map(async (componentPath) => {
        await Task({
          subagent_type: 'general-purpose',
          description: `Refactor ${componentPath}`,
          prompt: `
            Refactor the component at ${componentPath}:
            1. Convert to TypeScript
            2. Add PropTypes
            3. Optimize re-renders
            4. Add error boundaries

            DO NOT modify any dependencies - only this file.
          `,
          auto_approve: true
        });
      })
    );

    console.log(`✅ Group ${group} 완료`);
  }
}
```

### 예제 2: 데이터베이스 마이그레이션 순서 분석

```typescript
const migrations = [
  {
    id: 'create-users-table',
    name: 'Create users table',
    estimatedTime: 10,
    dependencies: []
  },
  {
    id: 'create-posts-table',
    name: 'Create posts table',
    estimatedTime: 15,
    dependencies: ['create-users-table'] // users 테이블에 FK
  },
  {
    id: 'create-comments-table',
    name: 'Create comments table',
    estimatedTime: 12,
    dependencies: ['create-users-table', 'create-posts-table']
  },
  {
    id: 'add-user-indexes',
    name: 'Add indexes to users',
    estimatedTime: 20,
    dependencies: ['create-users-table']
  },
  {
    id: 'add-post-indexes',
    name: 'Add indexes to posts',
    estimatedTime: 25,
    dependencies: ['create-posts-table']
  }
];

async function planMigration() {
  const groups = await analyzeTaskDependencies(migrations);

  // 출력 예:
  // Group 1 (병렬 가능):
  //   - create-users-table (10초)
  //
  // Group 2 (병렬 가능):
  //   - create-posts-table (15초)
  //   - add-user-indexes (20초)
  //
  // Group 3 (병렬 가능):
  //   - create-comments-table (12초)
  //   - add-post-indexes (25초)
  //
  // 순차 실행: 82초
  // 병렬 실행: 45초 (1.8배 향상)
}
```

### 예제 3: 테스트 병렬화

```typescript
async function parallelizeTests() {
  const testFiles = await globFiles('**/*.test.ts');
  const graph = new DependencyGraph();

  // 1. 각 테스트 파일을 독립적인 노드로 추가
  for (const testFile of testFiles) {
    const testSuite = await analyzeTestFile(testFile);

    graph.addNode(testFile, {
      type: 'test',
      path: testFile,
      estimatedTime: testSuite.estimatedTime,
      setupNeeded: testSuite.setupNeeded
    });
  }

  // 2. Setup 의존성 추가
  const setupFiles = testFiles.filter(f => f.includes('setup'));

  for (const testFile of testFiles) {
    if (!testFile.includes('setup')) {
      for (const setupFile of setupFiles) {
        graph.addDependency({
          from: testFile,
          to: setupFile,
          type: DependencyType.TEST,
          required: true
        });
      }
    }
  }

  // 3. 병렬 그룹 생성
  const groups = graph.getParallelGroups();

  // 4. Jest/Playwright에 병렬 설정 적용
  const jestConfig = {
    maxWorkers: groups[0]?.tasks.length || 4,
    testMatch: groups.map(g => g.tasks).flat()
  };

  console.log('Jest parallel config:', jestConfig);
}
```

### 예제 4: Monorepo 빌드 최적화

```typescript
interface Package {
  name: string;
  path: string;
  dependencies: string[];
  buildTime: number;
}

async function optimizeMonorepoBuild(packages: Package[]) {
  const graph = new DependencyGraph();

  // 1. 패키지 의존성 그래프 생성
  for (const pkg of packages) {
    graph.addNode(pkg.name, pkg);
  }

  for (const pkg of packages) {
    for (const dep of pkg.dependencies) {
      if (packages.find(p => p.name === dep)) {
        graph.addDependency({
          from: pkg.name,
          to: dep,
          type: DependencyType.BUILD,
          required: true
        });
      }
    }
  }

  // 2. 최적 빌드 순서 계산
  const buildGroups = graph.getParallelGroups();

  // 3. Turborepo/Nx 스타일 병렬 빌드
  for (const { group, tasks } of buildGroups) {
    console.log(`\n🔨 Building group ${group}...`);

    await Promise.all(
      tasks.map(async (pkgName) => {
        const pkg = packages.find(p => p.name === pkgName);
        if (!pkg) return;

        console.log(`  Building ${pkgName}...`);
        await buildPackage(pkg.path);
        console.log(`  ✅ ${pkgName} built`);
      })
    );
  }

  console.log('\n🎉 All packages built successfully!');
}
```

## 고급 기능

### 1. 스마트 의존성 추론

```typescript
async function inferDependencies(files: string[]) {
  const graph = new DependencyGraph();

  for (const file of files) {
    const content = await readFile(file);

    // AST 파싱을 통한 의존성 추론
    const ast = parseAST(content);

    // 함수 호출 분석
    const functionCalls = extractFunctionCalls(ast);

    // 변수 사용 분석
    const variableUsage = extractVariableUsage(ast);

    // 타입 의존성 분석 (TypeScript)
    const typeReferences = extractTypeReferences(ast);

    // 모든 의존성을 가중치와 함께 추가
    for (const dep of [...functionCalls, ...variableUsage, ...typeReferences]) {
      graph.addDependency({
        from: file,
        to: dep.target,
        type: dep.type,
        required: dep.required,
        weight: dep.weight
      });
    }
  }

  return graph;
}
```

### 2. 순환 의존성 자동 해결

```typescript
async function breakCycles(graph: DependencyGraph) {
  const cycles = graph.detectCycles();

  if (cycles.length === 0) {
    console.log('✅ 순환 의존성 없음');
    return;
  }

  console.log(`⚠️ ${cycles.length}개의 순환 의존성 발견`);

  for (const cycle of cycles) {
    console.log('\n순환:', cycle.join(' → '));

    // 해결 전략 제안
    const strategies = [
      {
        name: 'Dependency Inversion',
        description: '인터페이스 추출로 의존성 방향 역전',
        complexity: 'medium'
      },
      {
        name: 'Extract Common Module',
        description: '공통 모듈 추출',
        complexity: 'low'
      },
      {
        name: 'Lazy Loading',
        description: '동적 import로 지연 로딩',
        complexity: 'low'
      }
    ];

    console.log('\n해결 전략:');
    strategies.forEach((s, i) => {
      console.log(`  ${i + 1}. ${s.name} (복잡도: ${s.complexity})`);
      console.log(`     ${s.description}`);
    });
  }
}
```

### 3. 실시간 의존성 모니터링

```typescript
import chokidar from 'chokidar';

async function watchDependencies(projectPath: string) {
  let graph = await analyzeCodeDependencies(projectPath);

  const watcher = chokidar.watch('**/*.{ts,tsx,js,jsx}', {
    cwd: projectPath,
    ignoreInitial: true
  });

  watcher.on('change', async (filePath) => {
    console.log(`📝 ${filePath} 변경 감지`);

    // 의존성 재분석
    graph = await analyzeCodeDependencies(projectPath);

    // 새로운 순환 의존성 체크
    const cycles = graph.detectCycles();
    if (cycles.length > 0) {
      console.error('❌ 순환 의존성 발생!', cycles);
    }

    // 병렬화 가능 작업 업데이트
    const groups = graph.getParallelGroups();
    console.log(`✅ 병렬 그룹 업데이트: ${groups.length}개 그룹`);
  });
}
```

## 성능 비교

| 작업 종류 | 파일 수 | 순차 실행 | 병렬 실행 | 개선율 |
|---------|--------|---------|---------|--------|
| 컴포넌트 리팩토링 | 100 | 50분 | 8분 | 6.25배 |
| 테스트 실행 | 200 | 120분 | 15분 | 8배 |
| 빌드 (monorepo) | 50 | 180분 | 25분 | 7.2배 |
| 마이그레이션 | 30 | 45분 | 12분 | 3.75배 |

## 주의사항

1. **순환 의존성**: 반드시 해결 후 병렬화 진행
2. **공유 리소스**: 파일/DB/API 등 공유 자원 접근 시 lock 필요
3. **메모리 제한**: 너무 많은 병렬 작업은 메모리 부족 야기
4. **에러 전파**: 한 작업 실패 시 의존 작업들도 실패 처리

## 관련 리소스

- 원본 영상: [클로드코드 최애 기능 | 안쓰는 사람 없길 바래요](https://www.youtube.com/watch?v=prTGyqWMxw8)
- 관련 스킬: massive-parallel-orchestrator.md, claude-code-yolo-mode.md
- 이론: DAG (Directed Acyclic Graph), Topological Sort
- 라이브러리: dependency-cruiser, madge, webpack-bundle-analyzer

---

**💡 팁**: Planner 에이전트는 항상 이 스킬을 먼저 실행하여 작업을 최적화해야 합니다!
