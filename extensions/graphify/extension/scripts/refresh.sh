#!/bin/sh
# refresh.sh — arm-2 incremental graph refresh + stale-survivor guard (005, T016).
#
# Wraps the upstream incremental merge, carries the stale-survivor guard proven by hand at
# step-0 (step-0 caught 0; M3 caught 86), and — per the S06 cross-arm invariant — RE-INVOKES
# arm-1's augment.sh on the changed scope so an incremental refresh never silently regresses
# arm-1's .sh/.yml coverage. Contracts: specs/005-graphify-context/contracts/commands.md
# (`refresh.sh`), plan.md "Arm 2". Mechanical only: no model call, no ANTHROPIC_API_KEY, no
# traces.jsonl write. graphifyy is never modified (D75) — its API is called, augmented around.
#
# Usage:
#   refresh.sh <scratch-dir>   (run with cwd also <scratch-dir>)
#
# Reads <scratch-dir>/graphify-out/graph.json (mutated in place), changed-files.txt, and —
# when present — fresh-extraction.json (the authoritative fresh node/edge set; a hermetic
# test seam standing in for a live AST re-extraction, so this script never depends on
# upstream parse fidelity). Prints `stale_survivors: <N>` on stdout, then augment.sh's own
# `augmented: …` summary (S06). Exit 0 on success; non-zero + diagnostic on stderr on failure.
#
# Stale/recovery branch table (S02): common cheap incremental (below); survivors>0 →
# prune + report (refresh_merge.py); a full-corpus regen fires ONLY on an extractor
# VERSION change (the pin check below, R4) or explicit operator demand — never as the
# default stale response.

set -eu

die() {
    printf 'refresh.sh: error: %s\n' "$1" >&2
    exit 1
}

usage() { printf 'usage: refresh.sh <scratch-dir>\n' >&2; }

case "${1:-}" in
    -h|--help) usage; exit 0 ;;
esac

[ "$#" -ge 1 ] || { usage; exit 1; }
scratch="$1"
[ -d "$scratch" ] || die "scratch dir not found: $scratch"

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd) || die "cannot resolve own directory from \$0 ($0)"
graph="$scratch/graphify-out/graph.json"
[ -f "$graph" ] || die "graph not found at $graph"

engine="$script_dir/refresh_merge.py"
augment="$script_dir/augment.sh"
[ -f "$engine" ] || die "sibling refresh_merge.py not found at $engine"

if [ -f "$scratch/fresh-extraction.json" ]; then
    # Test-seam / cheap-incremental path: the fresh extraction is provided (ground truth).
    python3 "$engine" "$scratch" || die "refresh_merge.py failed"
else
    # Live path: a real incremental merge would call the upstream build_merge /
    # detect_incremental here. Assert the version pin FIRST (R4/S16) — a mismatch routes to
    # the full-regen branch, never a silent wrong-contract call.
    pin="$script_dir/graphify-version.pin"
    if [ -f "$pin" ]; then
        pinned=$(grep '^pinned_graphify_version=' "$pin" | head -n1 | cut -d'"' -f2)
        current=$(graphify --version 2>/dev/null || printf '')
        if [ "$pinned" != "$current" ]; then
            die "graphify version pin mismatch (pinned='$pinned', current='$current') — route to full-regen (R4); refusing a wrong-contract incremental call"
        fi
    fi
    die "live incremental path (no fresh-extraction.json) requires the upstream build_merge/detect_incremental; provide a fresh-extraction.json for the hermetic path"
fi

# S06: re-invoke arm-1's augment pass on the changed scope so its .sh/.yml edges are carried
# into the refreshed graph (a pure AST refresh would drop them). augment.sh's `augmented: …`
# summary lands on stdout after the guard's `stale_survivors:` line; consumers grep, not diff.
#
# Arm-1 is the detach-first arm (plan.md Detach order): it has a working fallback and is
# cleanly severable. If augment.sh is ABSENT (arm 1 detached), refresh.sh must still work —
# it skips the S06 re-invoke and .sh/.yml coverage degrades to today's honest
# labeled-assertion / file-disjointness behavior, never dies. This is exactly what the
# severability fixture (T034) asserts: arms 2+3+4 stay green with arm 1 absent.
if [ -f "$augment" ]; then
    "$augment" "$graph" "$scratch" || die "augment.sh re-invocation failed"
else
    printf 'refresh.sh: note: augment.sh absent (arm 1 detached) — skipping the S06 augment re-invoke; .sh/.yml coverage degrades to the labeled-assertion fallback\n' >&2
fi
