#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════
# sync-upstream.sh — Sync Operator GUI fork with upstream gastown-gui
#
# Generalized version of the Nebuchadnezzar core sync script.
# Configurable for any fork/branch combo via env vars.
#
# Usage:
#   ./scripts/sync-upstream.sh              # Full sync + rebase
#   ./scripts/sync-upstream.sh --dry-run    # Check only, no changes
#   ./scripts/sync-upstream.sh --status     # Show sync status
#
# Env overrides (defaults shown):
#   UPSTREAM_BRANCH=master       # branch tracked from upstream
#   FORK_BRANCH=master           # local mirror of upstream
#   FEATURE_BRANCH=feature/matrix-theme
#   UPSTREAM_REMOTE=upstream
#   UPSTREAM_URL=https://github.com/web3dev1337/gastown-gui.git
#   SYNC_LOG_DIR=docs/v2_matrix_rebuild_gui/sync_log
#
# Two-fork workflow reminder:
#   Always sync the gastown core (Nebuchadnezzar) FIRST, then this GUI.
#   Operator shells the `gt` CLI from core; CLI shape changes upstream
#   propagate through core sync first, so GUI conflicts surface in context.
# ══════════════════════════════════════════════════════════

set -uo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
DIM='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m'

UPSTREAM_BRANCH="${UPSTREAM_BRANCH:-master}"
FORK_BRANCH="${FORK_BRANCH:-master}"
FEATURE_BRANCH="${FEATURE_BRANCH:-feature/matrix-theme}"
UPSTREAM_REMOTE="${UPSTREAM_REMOTE:-upstream}"
UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/web3dev1337/gastown-gui.git}"
SYNC_LOG_DIR="${SYNC_LOG_DIR:-docs/v2_matrix_rebuild_gui/sync_log}"

DRY_RUN=false
STATUS_ONLY=false
for arg in "$@"; do
    case $arg in
        --dry-run) DRY_RUN=true ;;
        --status) STATUS_ONLY=true ;;
        --help|-h)
            echo "Usage: $0 [--dry-run] [--status]"
            echo "  --dry-run   Check for conflicts without making changes"
            echo "  --status    Show current sync status"
            exit 0
            ;;
    esac
done

log()  { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
err()  { echo -e "${RED}✗${NC} $1"; }
info() { echo -e "${CYAN}→${NC} $1"; }
dim()  { echo -e "${DIM}  $1${NC}"; }

echo -e "\n${BOLD}═══ Operator (gastown-gui) Upstream Sync ═══${NC}\n"

if ! git rev-parse --git-dir &>/dev/null; then
    err "Not a git repository. Run from /gt/neb/gui/rig/"
    exit 1
fi

if ! git remote get-url "$UPSTREAM_REMOTE" &>/dev/null; then
    info "Adding upstream remote: $UPSTREAM_URL"
    git remote add "$UPSTREAM_REMOTE" "$UPSTREAM_URL"
fi

info "Fetching upstream..."
git fetch "$UPSTREAM_REMOTE" --quiet
log "Upstream fetched"

CURRENT_BRANCH=$(git branch --show-current)
FORK_HASH=$(git rev-parse "$FORK_BRANCH" 2>/dev/null || echo "none")
UPSTREAM_HASH=$(git rev-parse "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH" 2>/dev/null || echo "none")
FEATURE_HASH=$(git rev-parse "$FEATURE_BRANCH" 2>/dev/null || echo "none")

BEHIND_COUNT=$(git rev-list --count "$FORK_BRANCH..$UPSTREAM_REMOTE/$UPSTREAM_BRANCH" 2>/dev/null || echo "?")
AHEAD_COUNT=$(git rev-list --count "$FORK_BRANCH..$FEATURE_BRANCH" 2>/dev/null || echo "?")

echo ""
echo -e "  ${BOLD}Current branch:${NC}  $CURRENT_BRANCH"
echo -e "  ${BOLD}$FORK_BRANCH:${NC}            ${FORK_HASH:0:12}"
echo -e "  ${BOLD}$UPSTREAM_REMOTE/$UPSTREAM_BRANCH:${NC}   ${UPSTREAM_HASH:0:12}"
echo -e "  ${BOLD}$FEATURE_BRANCH:${NC} ${FEATURE_HASH:0:12}"
echo ""
echo -e "  $FORK_BRANCH is ${BOLD}${BEHIND_COUNT}${NC} commits behind upstream"
echo -e "  $FEATURE_BRANCH is ${BOLD}${AHEAD_COUNT}${NC} commits ahead of $FORK_BRANCH"
echo ""

if [ "$STATUS_ONLY" = true ]; then
    if [ "$BEHIND_COUNT" = "0" ]; then
        log "Already in sync with upstream"
    else
        warn "$BEHIND_COUNT new upstream commits available"
        echo ""
        echo -e "  ${DIM}Recent upstream changes:${NC}"
        git log --oneline "$FORK_BRANCH..$UPSTREAM_REMOTE/$UPSTREAM_BRANCH" | head -10 | while read -r line; do
            dim "  $line"
        done
    fi
    exit 0
fi

if [ "$BEHIND_COUNT" = "0" ]; then
    log "$FORK_BRANCH is already in sync with upstream"
    echo ""

    if [ "$DRY_RUN" = true ]; then
        info "Dry run: testing rebase of $FEATURE_BRANCH onto $FORK_BRANCH..."
        if git rebase --onto "$FORK_BRANCH" "$FORK_BRANCH" "$FEATURE_BRANCH" --quiet 2>/dev/null; then
            git rebase --abort 2>/dev/null || true
            log "Rebase would succeed cleanly (no conflicts)"
        else
            git rebase --abort 2>/dev/null || true
            warn "Rebase would produce conflicts"
        fi
        exit 0
    fi

    log "Nothing to sync. Run with --status for details."
    exit 0
fi

echo -e "${BOLD}New upstream commits:${NC}"
git log --oneline "$FORK_BRANCH..$UPSTREAM_REMOTE/$UPSTREAM_BRANCH" | head -20 | while read -r line; do
    dim "$line"
done
TOTAL_NEW=$(git rev-list --count "$FORK_BRANCH..$UPSTREAM_REMOTE/$UPSTREAM_BRANCH")
if [ "$TOTAL_NEW" -gt 20 ]; then
    dim "... and $((TOTAL_NEW - 20)) more"
fi
echo ""

info "Checking for potential conflicts..."
OUR_FILES=$(git diff --name-only "$FORK_BRANCH" "$FEATURE_BRANCH" 2>/dev/null | sort)
THEIR_FILES=$(git diff --name-only "$FORK_BRANCH" "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH" 2>/dev/null | sort)
CONFLICTS=$(comm -12 <(echo "$OUR_FILES") <(echo "$THEIR_FILES"))

if [ -n "$CONFLICTS" ]; then
    warn "Files modified by BOTH us and upstream:"
    echo "$CONFLICTS" | while read -r f; do
        echo -e "  ${YELLOW}!!${NC} $f"
    done
    echo ""
else
    log "No overlapping file changes detected"
fi

if [ "$DRY_RUN" = true ]; then
    info "Dry run complete. Use without --dry-run to apply changes."
    exit 0
fi

OLD_FORK_HASH=$(git rev-parse "$FORK_BRANCH" 2>/dev/null)
SYNC_START_TIME=$(date +%s)

STASHED=false
if ! git diff --quiet || ! git diff --cached --quiet; then
    warn "Stashing uncommitted changes..."
    git stash push -m "sync-upstream: auto-stash $(date +%Y%m%d-%H%M%S)"
    STASHED=true
fi

ORIGINAL_BRANCH="$CURRENT_BRANCH"

info "Updating $FORK_BRANCH branch..."
git checkout "$FORK_BRANCH" --quiet
if git merge "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH" --ff-only --quiet; then
    log "$FORK_BRANCH fast-forwarded to upstream"
else
    err "$FORK_BRANCH cannot fast-forward — manual intervention required"
    git checkout "$ORIGINAL_BRANCH" --quiet
    if [ "$STASHED" = true ]; then git stash pop --quiet; fi
    exit 1
fi

info "Pushing $FORK_BRANCH to origin..."
if git push origin "$FORK_BRANCH" --quiet 2>/dev/null; then
    log "$FORK_BRANCH pushed to origin"
else
    warn "Push to origin failed (non-fatal — may need token scope)"
fi

info "Rebasing $FEATURE_BRANCH onto updated $FORK_BRANCH..."
git checkout "$FEATURE_BRANCH" --quiet

if git rebase "$FORK_BRANCH" --quiet 2>/dev/null; then
    log "Rebase completed successfully — no conflicts!"

    info "Force-pushing rebased $FEATURE_BRANCH..."
    if git push origin "$FEATURE_BRANCH" --force-with-lease --quiet 2>/dev/null; then
        log "Rebased branch pushed to origin"
    else
        if git push origin "$FEATURE_BRANCH" --force --quiet 2>/dev/null; then
            log "Rebased branch force-pushed to origin"
        else
            warn "Force-push failed (may need token scope)"
        fi
    fi

    info "Recording sync log..."
    SYNC_DATE=$(date -u +%Y-%m-%d)
    SYNC_TIME=$(date -u +%H:%M:%S)
    NEW_FORK_HASH=$(git rev-parse "$FORK_BRANCH")
    NEW_FEATURE_HASH=$(git rev-parse "$FEATURE_BRANCH")
    FEATURE_AHEAD=$(git rev-list --count "$FORK_BRANCH..$FEATURE_BRANCH")

    mkdir -p "$SYNC_LOG_DIR"

    FEAT_COUNT=$(git log --oneline "$OLD_FORK_HASH".."$NEW_FORK_HASH" --grep="^feat" 2>/dev/null | wc -l)
    FIX_COUNT=$(git log --oneline "$OLD_FORK_HASH".."$NEW_FORK_HASH" --grep="^fix" 2>/dev/null | wc -l)
    MERGE_COUNT=$(git log --oneline "$OLD_FORK_HASH".."$NEW_FORK_HASH" --grep="^Merge" 2>/dev/null | wc -l)

    FILES_CHANGED=$(git diff --stat "$OLD_FORK_HASH".."$NEW_FORK_HASH" 2>/dev/null | tail -1)
    OUR_MODIFIED=$(git diff --name-only "$FORK_BRANCH" "$FEATURE_BRANCH" 2>/dev/null | sort)
    UPSTREAM_MODIFIED=$(git diff --name-only "$OLD_FORK_HASH" "$NEW_FORK_HASH" 2>/dev/null | sort)
    OVERLAP=$(comm -12 <(echo "$OUR_MODIFIED") <(echo "$UPSTREAM_MODIFIED") 2>/dev/null)
    NOTABLE=$(git log --oneline "$OLD_FORK_HASH".."$NEW_FORK_HASH" --no-merges 2>/dev/null | head -15)

    LOG_FILE="$SYNC_LOG_DIR/sync-${SYNC_DATE}.md"
    cat > "$LOG_FILE" << LOGEOF
# Operator Upstream Sync: ${SYNC_DATE}

**Time:** ${SYNC_TIME} UTC
**Commits absorbed:** ${BEHIND_COUNT}
**Conflicts:** 0 (clean rebase)

## Sync Details

| Field | Value |
|-------|-------|
| Previous $FORK_BRANCH | \`${OLD_FORK_HASH:0:12}\` |
| New $FORK_BRANCH | \`${NEW_FORK_HASH:0:12}\` |
| Feature branch | \`${NEW_FEATURE_HASH:0:12}\` (${FEATURE_AHEAD} commits ahead) |
| Upstream stats | ${FILES_CHANGED} |

## Commit Breakdown

- **Features:** ~${FEAT_COUNT}
- **Fixes:** ~${FIX_COUNT}
- **Merges:** ~${MERGE_COUNT}

## Notable Upstream Changes

\`\`\`
${NOTABLE}
\`\`\`

## Risk Assessment

LOGEOF

    if [ -n "$OVERLAP" ]; then
        echo "**Files modified by both us and upstream:**" >> "$LOG_FILE"
        echo "" >> "$LOG_FILE"
        echo "$OVERLAP" | while read -r f; do
            echo "- \`$f\` (resolved cleanly)" >> "$LOG_FILE"
        done
    else
        echo "No overlapping file modifications." >> "$LOG_FILE"
    fi

    cat >> "$LOG_FILE" << LOGEOF

## Action Items

- [ ] Verify GUI boots: \`cd /gt/neb/gui/rig && npm install && npm start\`
- [ ] Run vitest suites
- [ ] Confirm CLI commands still resolve against Nebuchadnezzar gt
- [ ] Review notable upstream changes for features to adopt
LOGEOF

    log "Sync log written to $LOG_FILE"

    HISTORY_FILE="$SYNC_LOG_DIR/SYNC_HISTORY.md"
    if [ ! -f "$HISTORY_FILE" ]; then
        echo "# Operator Upstream Sync History" > "$HISTORY_FILE"
        echo "" >> "$HISTORY_FILE"
        echo "Cumulative log of upstream syncs for the Operator GUI fork." >> "$HISTORY_FILE"
        echo "" >> "$HISTORY_FILE"
        echo "| Date | Commits | Conflicts | Duration | Notes |" >> "$HISTORY_FILE"
        echo "|------|---------|-----------|----------|-------|" >> "$HISTORY_FILE"
    fi
    DURATION=$(( $(date +%s) - SYNC_START_TIME ))
    echo "| ${SYNC_DATE} | ${BEHIND_COUNT} | 0 | ${DURATION}s | Clean rebase, no overlapping files |" >> "$HISTORY_FILE"
    log "Updated sync history"
else
    err "Rebase produced conflicts!"
    echo ""
    echo -e "${RED}Conflicting files:${NC}"
    git diff --name-only --diff-filter=U 2>/dev/null | while read -r f; do
        echo -e "  ${RED}✗${NC} $f"
    done
    echo ""
    echo -e "To resolve:"
    echo -e "  1. Open each file and resolve ${YELLOW}<<<<<<< / >>>>>>>>${NC} markers"
    echo -e "  2. Consult ${CYAN}docs/v2_matrix_rebuild_gui/CHANGELOG.md${NC} for our changes"
    echo -e "  3. Run: ${BOLD}git add <resolved-files> && git rebase --continue${NC}"
    echo -e "  4. Or abort: ${BOLD}git rebase --abort${NC}"
    echo ""

    git rebase --abort
    warn "Rebase aborted — your branch is unchanged"
fi

git checkout "$ORIGINAL_BRANCH" --quiet 2>/dev/null || true

if [ "$STASHED" = true ]; then
    git stash pop --quiet
    log "Restored stashed changes"
fi

echo ""
echo -e "${BOLD}═══ Sync Complete ═══${NC}\n"
