#!/bin/bash
# my-claude-bible 동기화 스크립트 (Mac/Linux)

set -e

echo "🔄 my-claude-bible 동기화 시작..."
echo ""

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 디렉토리 경로
CLAUDE_SKILLS="$HOME/.claude/skills"
REPO_DIR="$HOME/my-claude-vible"
REPO_SKILLS="$REPO_DIR/skills"

# 저장소 디렉토리로 이동
if [ ! -d "$REPO_DIR" ]; then
  echo -e "${YELLOW}⚠️  my-claude-vible 디렉토리를 찾을 수 없습니다: $REPO_DIR${NC}"
  echo "먼저 저장소를 클론하세요:"
  echo "  git clone https://github.com/yoosee1219-a11y/my-claude-bible.git ~/my-claude-vible"
  exit 1
fi

cd "$REPO_DIR"

# 원격 최신 상태 확인
echo -e "${BLUE}📡 원격 저장소 확인 중...${NC}"
git fetch origin

# 스킬 파일 동기화
echo ""
echo -e "${BLUE}📦 스킬 파일 동기화 중...${NC}"

SYNCED_COUNT=0
NEW_COUNT=0
UPDATED_COUNT=0

for skill in "$CLAUDE_SKILLS"/*.md; do
  if [ -f "$skill" ]; then
    SKILL_NAME=$(basename "$skill")

    if [ ! -f "$REPO_SKILLS/$SKILL_NAME" ]; then
      # 새 파일
      cp "$skill" "$REPO_SKILLS/"
      echo -e "  ${GREEN}+ $SKILL_NAME (새 스킬)${NC}"
      NEW_COUNT=$((NEW_COUNT + 1))
      SYNCED_COUNT=$((SYNCED_COUNT + 1))
    elif ! cmp -s "$skill" "$REPO_SKILLS/$SKILL_NAME"; then
      # 수정된 파일
      cp "$skill" "$REPO_SKILLS/"
      echo -e "  ${CYAN}✎ $SKILL_NAME (수정됨)${NC}"
      UPDATED_COUNT=$((UPDATED_COUNT + 1))
      SYNCED_COUNT=$((SYNCED_COUNT + 1))
    fi
  fi
done

# 변경사항 확인
if [ $SYNCED_COUNT -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✅ 모든 스킬이 최신 상태입니다!${NC}"
  exit 0
fi

# Git 상태 확인
echo ""
echo -e "${BLUE}📊 변경 사항:${NC}"
git status --short

# Git에 추가
echo ""
echo -e "${BLUE}📝 Git에 추가 중...${NC}"
git add skills/

# 커밋 메시지 생성
COMMIT_MSG="Sync skills: "
if [ $NEW_COUNT -gt 0 ]; then
  COMMIT_MSG="${COMMIT_MSG}${NEW_COUNT}개 추가"
fi
if [ $UPDATED_COUNT -gt 0 ]; then
  if [ $NEW_COUNT -gt 0 ]; then
    COMMIT_MSG="${COMMIT_MSG}, "
  fi
  COMMIT_MSG="${COMMIT_MSG}${UPDATED_COUNT}개 수정"
fi
COMMIT_MSG="${COMMIT_MSG} ($(date '+%Y-%m-%d %H:%M'))"

# 커밋
git commit -m "$COMMIT_MSG" 2>/dev/null || {
  echo -e "${YELLOW}ℹ️  커밋할 변경사항이 없습니다${NC}"
  exit 0
}

# 푸시
echo ""
echo -e "${BLUE}🚀 GitHub에 푸시 중...${NC}"
git push origin main

# 완료
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✨ 동기화 완료!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}📊 동기화 요약:${NC}"
if [ $NEW_COUNT -gt 0 ]; then
  echo "  • 새로 추가: $NEW_COUNT개"
fi
if [ $UPDATED_COUNT -gt 0 ]; then
  echo "  • 수정됨: $UPDATED_COUNT개"
fi
echo "  • 총 동기화: $SYNCED_COUNT개"
echo ""
echo -e "${CYAN}🔗 GitHub: https://github.com/yoosee1219-a11y/my-claude-bible${NC}"
echo ""
