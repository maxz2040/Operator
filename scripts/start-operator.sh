#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════
# start-operator.sh — Boot Operator against Nebuchadnezzar
#
# Sets the env vars Operator needs to find our build of gt/bd
# and the canonical /gt town layout, then launches the server.
#
# Usage:
#   ./scripts/start-operator.sh              # default port 7667
#   PORT=9090 ./scripts/start-operator.sh    # override port
#   ./scripts/start-operator.sh --open       # also open browser
# ══════════════════════════════════════════════════════════

set -euo pipefail

GT_ROOT_DEFAULT="/gt"
PORT_DEFAULT="7667"
HOST_DEFAULT="127.0.0.1"

export GT_ROOT="${GT_ROOT:-$GT_ROOT_DEFAULT}"
export OPERATOR_PORT="${OPERATOR_PORT:-${PORT:-$PORT_DEFAULT}}"
export OPERATOR_HOST="${OPERATOR_HOST:-${HOST:-$HOST_DEFAULT}}"

# GT_BIN / BD_BIN — leave unset so server.js falls back to PATH lookup.
# Override here if you have a non-PATH build.
# export GT_BIN=/gt/neb/mayor/rig/bin/gt
# export BD_BIN=/usr/local/bin/bd

GREEN='\033[0;32m'
DIM='\033[0;90m'
NC='\033[0m'

echo -e "${GREEN}Operator${NC} — Matrix Console for Nebuchadnezzar"
echo -e "${DIM}  GT_ROOT:        ${GT_ROOT}${NC}"
echo -e "${DIM}  OPERATOR_PORT:  ${OPERATOR_PORT}${NC}"
echo -e "${DIM}  OPERATOR_HOST:  ${OPERATOR_HOST}${NC}"
echo -e "${DIM}  gt:             $(command -v gt || echo MISSING)${NC}"
echo -e "${DIM}  bd:             $(command -v bd || echo MISSING)${NC}"
echo ""

if [ ! -d "$GT_ROOT" ]; then
    echo "✗ GT_ROOT does not exist: $GT_ROOT" >&2
    echo "  Set GT_ROOT to your Nebuchadnezzar town directory." >&2
    exit 1
fi

if ! command -v gt &>/dev/null && [ -z "${GT_BIN:-}" ]; then
    echo "✗ gt not in PATH and GT_BIN not set" >&2
    exit 1
fi

cd "$(dirname "$0")/.."

if [ ! -d node_modules ]; then
    echo "→ Installing dependencies..."
    npm install --quiet
fi

exec node bin/cli.js start "$@"
