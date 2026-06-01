#!/usr/bin/env bash
# Drive one platform through the EPIC-00 + EPIC-01 benchmark, task by task,
# in dependency order. The agent for each task marks status: done and commits;
# the loop re-runs the dispatcher to pick the next ready task.
#
# Usage:
#   workflow/run_benchmark.sh <platform>
#   platform ∈ {claude, codex, gemini}
#   (cursor is GUI-driven — use the prompts in KICKOFF.md instead.)
#
# Run from inside that platform's workspace ($HOME/khatir-bench/<platform>).
set -euo pipefail

PLATFORM="${1:?usage: run_benchmark.sh <claude|codex|gemini>}"
EPICS="EPIC-00,EPIC-01"
LIMIT="${BENCH_MAX_TASKS:-40}"   # safety cap

role_for_layer() {
  case "$1" in
    backend) echo backend ;;
    mobile)  echo mobile ;;
    admin)   echo admin ;;
    *)       echo infra ;;   # infra/packages/docs/cross-cutting
  esac
}

launch() {  # $1=role $2=task-key
  local role="$1" key="$2"
  local prompt="Act as the ${role} agent per workflow/roles/${role}.md and obey your platform entrypoint. \
Build exactly ${key}. Follow workflow/CORE.md: load only that task + its depends_on + any named design screen. \
Run its tests, set status: done in the task frontmatter, append a line to BOARD.md, and commit 'T-XXX: <summary>'. Then stop."
  case "$PLATFORM" in
    claude) claude -p "$prompt" ;;
    codex)  codex exec "$prompt" ;;
    gemini) gemini -p "$prompt" ;;
    *) echo "unknown platform: $PLATFORM" >&2; exit 2 ;;
  esac
}

count=0
while :; do
  # next ready task (key<TAB>layer), first line only
  line="$(python3 workflow/dispatcher.py --epics "$EPICS" | grep -E '^EPIC-' | head -1 || true)"
  [ -z "$line" ] && { echo "no ready tasks left — benchmark sequence complete"; break; }
  key="${line%%$'\t'*}"
  layer="${line##*$'\t'}"
  role="$(role_for_layer "$layer")"
  count=$((count+1))
  echo "=== [$count] $key  (layer=$layer role=$role) ==="
  launch "$role" "$key"
  # Guard: if the agent did NOT flip status to done, stop to avoid an infinite loop.
  still="$(python3 workflow/dispatcher.py --epics "$EPICS" | grep -E '^EPIC-' | head -1 || true)"
  if [ "${still%%$'\t'*}" = "$key" ]; then
    echo "WARNING: $key still ready after the agent ran (status not set to done). Stopping." >&2
    break
  fi
  [ "$count" -ge "$LIMIT" ] && { echo "hit BENCH_MAX_TASKS=$LIMIT cap"; break; }
done

echo "--- metrics ---"
python3 workflow/bench_metrics.py . --epics "$EPICS"
