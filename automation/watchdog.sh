#!/bin/bash
# Claude Code Watchdog - Mac/Linux
# Usage: ./watchdog.sh [safe|yolo] [interval] [build_cmd]

set -e
MODE="${1:-safe}"
INTERVAL="${2:-60}"
BUILD_CMD="${3:-npm run build}"
LOG_DIR="./watchdog-logs"
LOG_FILE="$LOG_DIR/watchdog-$(date +%Y%m%d).log"
mkdir -p "$LOG_DIR"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"; }

echo "========================================================"
echo "         Claude Code Watchdog v1.0"
echo "========================================================"
[ "$MODE" = "yolo" ] && echo "  Mode: YOLO (Full Auto)" || echo "  Mode: SAFE (Review Required)"
echo "  Interval: ${INTERVAL}s | Build: $BUILD_CMD"
echo "========================================================"

run_build() {
  log "Build running..."
  BUILD_OUTPUT=$(eval "$BUILD_CMD" 2>&1) || true
  if [ $? -eq 0 ]; then log "Build OK"; return 0
  else log "Build FAILED"; echo "$BUILD_OUTPUT" > "$LOG_DIR/last-error.log"; return 1; fi
}

auto_fix() {
  log "Claude auto-fix requesting..."
  if [ "$MODE" = "safe" ]; then
    git stash push -m "watchdog-snapshot-$(date +%H%M%S)" 2>/dev/null || true
    claude "Fix this build error with minimal changes:

$(cat "$LOG_DIR/last-error.log")

Summarize what you changed." --auto-approve 2>&1 | tee -a "$LOG_FILE"

    echo ""; echo "--- Changes ---"
    git diff --stat; echo ""; git diff --color; echo ""
    echo "[A] Approve  [R] Reject  [S] Skip"
    read -r -p "Choice: " choice
    case "$choice" in
      [Aa]) git add -A; git commit -m "fix: watchdog auto-fix ($(date '+%m/%d %H:%M'))"; log "Approved" ;;
      [Rr]) git checkout -- .; git stash pop 2>/dev/null || true; log "Rejected" ;;
      *) log "Skipped" ;;
    esac
  else
    claude "Fix this build error with minimal changes:

$(cat "$LOG_DIR/last-error.log")

After fixing, run git add -A and git commit -m 'fix: watchdog auto-fix ($(date '+%m/%d %H:%M'))'" --auto-approve 2>&1 | tee -a "$LOG_FILE"
    log "YOLO auto-committed"
  fi
}

CYCLE=0; FIXES=0; ERRORS=0
log "Watchdog started (PID: $$)"

while true; do
  CYCLE=$((CYCLE + 1))
  log "-- Cycle #$CYCLE --"
  if run_build; then :
  else
    ERRORS=$((ERRORS + 1)); auto_fix
    if run_build; then FIXES=$((FIXES + 1)); log "Auto-fix success! ($FIXES/$ERRORS resolved)"
    else log "Still failing after auto-fix"
      [ "$MODE" = "safe" ] && { echo "Press Enter to continue"; read -r; }
    fi
  fi
  [ $((CYCLE % 10)) -eq 0 ] && log "Stats: cycles=$CYCLE errors=$ERRORS fixes=$FIXES"
  sleep "$INTERVAL"
done
