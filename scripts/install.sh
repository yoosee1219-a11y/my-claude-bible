#!/bin/bash
# my-claude-vible 설치 스크립트 (Mac/Linux)

set -e

echo "🚀 my-claude-vible 설치 시작..."
echo ""

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Claude 디렉토리 확인
CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"
AGENTS_DIR="$CLAUDE_DIR/agents"

if [ ! -d "$CLAUDE_DIR" ]; then
  echo -e "${YELLOW}⚠️  ~/.claude 디렉토리가 없습니다. 생성합니다...${NC}"
  mkdir -p "$CLAUDE_DIR"
fi

if [ ! -d "$SKILLS_DIR" ]; then
  echo -e "${BLUE}📁 ~/.claude/skills 디렉토리 생성...${NC}"
  mkdir -p "$SKILLS_DIR"
fi

if [ ! -d "$AGENTS_DIR" ]; then
  echo -e "${BLUE}📁 ~/.claude/agents 디렉토리 생성...${NC}"
  mkdir -p "$AGENTS_DIR"
fi

# 백업 (기존 파일 보존)
BACKUP_DIR="$HOME/.claude-backup-$(date +%Y%m%d-%H%M%S)"
if [ "$(ls -A $SKILLS_DIR 2>/dev/null)" ]; then
  echo -e "${YELLOW}💾 기존 스킬 백업 중... ($BACKUP_DIR)${NC}"
  mkdir -p "$BACKUP_DIR/skills"
  cp -r "$SKILLS_DIR"/* "$BACKUP_DIR/skills/" 2>/dev/null || true
  echo -e "${GREEN}✅ 백업 완료!${NC}"
fi

# 스킬 복사
echo ""
echo -e "${BLUE}📦 스킬 설치 중...${NC}"
SKILL_COUNT=0
for skill in skills/*.md; do
  if [ -f "$skill" ]; then
    cp "$skill" "$SKILLS_DIR/"
    SKILL_COUNT=$((SKILL_COUNT + 1))
    echo "  ✓ $(basename $skill)"
  fi
done

# 에이전트 복사
if [ -d "agents" ] && [ "$(ls -A agents 2>/dev/null)" ]; then
  echo ""
  echo -e "${BLUE}🤖 에이전트 설치 중...${NC}"
  cp -r agents/* "$AGENTS_DIR/" 2>/dev/null || true
fi

# 설정 파일 복사 (선택)
if [ -d "configs" ]; then
  echo ""
  read -p "설정 파일도 덮어쓸까요? (y/N): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}⚙️  설정 파일 복사 중...${NC}"
    cp configs/*.json "$CLAUDE_DIR/" 2>/dev/null || true
  fi
fi

# 완료
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✨ 설치 완료!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}📊 설치 요약:${NC}"
echo "  • 스킬: $SKILL_COUNT개"
echo "  • 위치: $SKILLS_DIR"
if [ -d "$BACKUP_DIR" ]; then
  echo "  • 백업: $BACKUP_DIR"
fi
echo ""
echo -e "${YELLOW}🎯 사용법:${NC}"
echo "  /auto \"요청\"           - Intelligent Orchestrator 사용"
echo "  /skill-name            - 특정 스킬 실행"
echo ""
echo -e "${BLUE}📚 문서:${NC}"
echo "  README.md      - 전체 가이드"
echo "  CATALOG.md     - 스킬 카탈로그"
echo ""
echo "Happy Coding! 🚀"
