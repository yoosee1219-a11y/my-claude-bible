#!/usr/bin/env bash
#
# sync-to-bible.sh
# ~/.claude/ → my-claude-bible 전체 동기화
#
# 사용법:
#   bash scripts/sync-to-bible.sh           # 동기화만
#   bash scripts/sync-to-bible.sh --push    # 동기화 + 커밋 + 푸시

set -euo pipefail

# 경로 설정
LOCAL_CLAUDE="${HOME}/.claude"
BIBLE_DIR="${HOME}/my-claude-bible"

# Windows 경로 변환 (Git Bash / MSYS)
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
  LOCAL_CLAUDE_WIN=$(cygpath -w "$LOCAL_CLAUDE")
  BIBLE_DIR_WIN=$(cygpath -w "$BIBLE_DIR")
  USE_ROBOCOPY=1
else
  USE_ROBOCOPY=0
fi

echo "════════════════════════════════════════"
echo "  Claude Bible 동기화"
echo "════════════════════════════════════════"
echo "  소스: $LOCAL_CLAUDE"
echo "  대상: $BIBLE_DIR"
echo ""

if [ ! -d "$BIBLE_DIR" ]; then
  echo "❌ bible 디렉토리 없음: $BIBLE_DIR"
  exit 1
fi

sync_dir() {
  local name="$1"
  local extra_xd="${2:-}"  # 추가로 제외할 디렉토리 이름 (공백 구분)
  local src="${LOCAL_CLAUDE}/${name}"
  local dst="${BIBLE_DIR}/${name}"

  if [ ! -d "$src" ]; then
    echo "⚠️  $name 스킵 (소스 없음)"
    return
  fi

  echo "📦 동기화: $name${extra_xd:+ (제외: $extra_xd)}"

  if [ "$USE_ROBOCOPY" -eq 1 ]; then
    local src_win="${LOCAL_CLAUDE_WIN}\\${name}"
    local dst_win="${BIBLE_DIR_WIN}\\${name}"
    # shellcheck disable=SC2086
    MSYS_NO_PATHCONV=1 robocopy "$src_win" "$dst_win" \
      /MIR /NFL /NDL /NP \
      /XD "gstack" "node_modules" "dist" "__pycache__" ".gstack" ".gstack-worktrees" $extra_xd \
      /XF "*.log" "*.tmp" > /dev/null 2>&1 || true
    # robocopy 종료코드 0~7은 성공
  else
    # rsync fallback (Linux/Mac)
    local rsync_extra=""
    for d in $extra_xd; do rsync_extra="$rsync_extra --exclude=${d}/"; done
    # shellcheck disable=SC2086
    rsync -av --delete \
      --exclude='gstack/' \
      --exclude='node_modules/' \
      --exclude='dist/' \
      --exclude='__pycache__/' \
      --exclude='.gstack/' \
      --exclude='.gstack-worktrees/' \
      --exclude='*.log' \
      --exclude='*.tmp' \
      $rsync_extra \
      "${src}/" "${dst}/" > /dev/null
  fi
}

# 각 디렉토리 동기화
# agents: 중첩된 skills/ 폴더는 top-level skills/ 중복이므로 제외
sync_dir "agents" "skills"
sync_dir "skills"
sync_dir "commands"
sync_dir "hooks"

# 파일 복사
echo "📄 파일 복사"
[ -f "${LOCAL_CLAUDE}/CLAUDE.md" ] && cp "${LOCAL_CLAUDE}/CLAUDE.md" "${BIBLE_DIR}/CLAUDE.md"
[ -f "${LOCAL_CLAUDE}/settings.json" ] && cp "${LOCAL_CLAUDE}/settings.json" "${BIBLE_DIR}/configs/settings.json"

# dist 정리 (gitignore 외에 실수 방지)
rm -rf "${BIBLE_DIR}/skills/browse/dist" 2>/dev/null || true

# Bible 전용 파일 복원 (로컬엔 없지만 bible에 보존해야 하는 문서/템플릿)
cd "$BIBLE_DIR"
BIBLE_ONLY_FILES=(
  "hooks/.env.example"
  "hooks/README.md"
  "skills/unified-orchestrator.md"
)
for file in "${BIBLE_ONLY_FILES[@]}"; do
  if [ ! -f "$file" ] && git cat-file -e HEAD:"$file" 2>/dev/null; then
    git checkout HEAD -- "$file" 2>/dev/null && echo "  🔄 복원: $file"
  fi
done

echo ""
echo "✅ 동기화 완료"
echo ""

# 상태 확인
cd "$BIBLE_DIR"
CHANGES=$(git status --porcelain | wc -l)
echo "📊 변경사항: ${CHANGES}개 파일"

if [ "$CHANGES" -eq 0 ]; then
  echo "변경 없음. 종료."
  exit 0
fi

# --push 옵션 처리
if [[ "${1:-}" == "--push" ]]; then
  DATE=$(date +"%Y-%m-%d %H:%M")
  echo ""
  echo "📤 커밋 + 푸시 진행..."
  git add -A
  git commit -m "sync: auto-sync from local .claude (${DATE})"
  git push origin main
  echo "✅ 푸시 완료"
else
  echo ""
  echo "💡 커밋하려면: cd ${BIBLE_DIR} && git add -A && git commit -m 'sync: <메시지>' && git push"
  echo "   또는: bash scripts/sync-to-bible.sh --push"
fi
