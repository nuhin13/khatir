#!/usr/bin/env bash
# sync-agent-rules.sh — copy the ONE canonical AGENTS.md to every platform's expected
# rules filename, appending an optional per-platform shim. Run from repo root.
#
# Why: each CLI reads its rules from a different file name. We keep a single source of
# truth (docs/agentic/AGENTS.md) and fan it out, so the agnostic contract stays identical
# and only the thin tool-wiring shim differs per platform.
#
# Usage:
#   ./docs/agentic/sync-agent-rules.sh            # sync all known platforms
#   ./docs/agentic/sync-agent-rules.sh claude     # sync just one
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CANON="$ROOT/docs/agentic/AGENTS.md"
SHIMS="$ROOT/docs/agentic/shims"

[ -f "$CANON" ] || { echo "ERROR: canonical $CANON not found"; exit 1; }
mkdir -p "$SHIMS"

# platform -> destination rules file (relative to repo root)
# edit these paths if a CLI changes its convention.
declare -A DEST=(
  [claude]="CLAUDE.md"
  [codex]="AGENTS.md"                      # Codex/OpenAI reads AGENTS.md at root
  [gemini]="GEMINI.md"
  [opencode]="AGENTS.md"                   # OpenCode also reads AGENTS.md
  [cursor]=".cursor/rules/khatir.mdc"
  [antigravity]=".antigravity/rules.md"
)

sync_one() {
  local p="$1" dest="${DEST[$1]:-}"
  [ -n "$dest" ] || { echo "skip: unknown platform '$p'"; return; }
  local out="$ROOT/$dest"
  mkdir -p "$(dirname "$out")"
  {
    cat "$CANON"
    if [ -f "$SHIMS/$p.md" ]; then
      echo ""
      echo "<!-- ===== platform shim: $p ===== -->"
      cat "$SHIMS/$p.md"
    fi
  } > "$out"
  echo "synced: $p -> $dest"
}

if [ $# -gt 0 ]; then
  sync_one "$1"
else
  for p in "${!DEST[@]}"; do sync_one "$p"; done
fi

echo ""
echo "Done. Note: AGENTS.md at root serves Codex AND OpenCode (same file)."
echo "Commit the generated rules files so every clone/cloud-VM has them."
