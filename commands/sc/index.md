---
name: index
description: "프로젝트문서화, 지식베이스생성, API문서화, 구조분석, 자동인덱싱, 크로스레퍼런스, README생성, 문서자동화, 아키텍트페르소나, 스크라이브페르소나, 품질검증, 프레임워크패턴으로 프로젝트 문서와 지식 베이스를 지능형으로 자동 생성하는 명령어"
category: special
complexity: standard
mcp-servers: [sequential, context7]
personas: [architect, scribe, quality]
---

# /sc:index - Project Documentation

## Triggers
- Project documentation creation and maintenance requirements
- Knowledge base generation and organization needs
- API documentation and structure analysis requirements
- Cross-referencing and navigation enhancement requests

## Usage
```
/sc:index [target] [--type docs|api|structure|readme] [--format md|json|yaml]
```

## Behavioral Flow
1. **Analyze**: Examine project structure and identify key documentation components
2. **Organize**: Apply intelligent organization patterns and cross-referencing strategies
3. **Generate**: Create comprehensive documentation with framework-specific patterns
4. **Validate**: Ensure documentation completeness and quality standards
5. **Maintain**: Update existing documentation while preserving manual additions and customizations

Key behaviors:
- Multi-persona coordination (architect, scribe, quality) based on documentation scope and complexity
- Sequential MCP integration for systematic analysis and comprehensive documentation workflows
- Context7 MCP integration for framework-specific patterns and documentation standards
- Intelligent organization with cross-referencing capabilities and automated maintenance

## MCP Integration
- **Sequential MCP**: Complex multi-step project analysis and systematic documentation generation
- **Context7 MCP**: Framework-specific documentation patterns and established standards
- **Persona Coordination**: Architect (structure), Scribe (content), Quality (validation)

## Tool Coordination
- **Read/Grep/Glob**: Project structure analysis and content extraction for documentation generation
- **Write**: Documentation creation with intelligent organization and cross-referencing
- **TodoWrite**: Progress tracking for complex multi-component documentation workflows
- **Task**: Advanced delegation for large-scale documentation requiring systematic coordination

## Key Patterns
- **Structure Analysis**: Project examination → component identification → logical organization → cross-referencing
- **Documentation Types**: API docs → Structure docs → README → Knowledge base approaches
- **Quality Validation**: Completeness assessment → accuracy verification → standard compliance → maintenance planning
- **Framework Integration**: Context7 patterns → official standards → best practices → consistency validation

## Examples

### Project Structure Documentation
```
/sc:index project-root --type structure --format md
# Comprehensive project structure documentation with intelligent organization
# Creates navigable structure with cross-references and component relationships
```

### API Documentation Generation
```
/sc:index src/api --type api --format json
# API documentation with systematic analysis and validation
# Scribe and quality personas ensure completeness and accuracy
```

### Knowledge Base Creation
```
/sc:index . --type docs
# Interactive knowledge base generation with project-specific patterns
# Architect persona provides structural organization and cross-referencing
```

## Boundaries

**Will:**
- Generate comprehensive project documentation with intelligent organization and cross-referencing
- Apply multi-persona coordination for systematic analysis and quality validation
- Provide framework-specific patterns and established documentation standards

**Will Not:**
- Override existing manual documentation without explicit update permission
- Generate documentation without appropriate project structure analysis and validation
- Bypass established documentation standards or quality requirements