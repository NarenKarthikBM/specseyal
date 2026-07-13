#!/bin/sh
# freshness.sh — staleness guard for graphify context products (005 arm 2, T015)
#
# Decides whether a graphify context product (graphify-context.md, or a sibling arm-3
# diet — any file carrying the shared-provenance header) is stale relative to the graph
# it was generated from, and whether that graph is itself stale relative to the current
# worktree: the two-check freshness decision defined in
# extensions/graphify/skills/speckit-graphify-context/SKILL.md, "Shared-provenance
# header" / "Freshness decision" (T004), and specs/005-graphify-context/contracts/
# commands.md's Arm 2. Mechanical only: no model call, no network, no
# ANTHROPIC_API_KEY, no traces.jsonl write (constitution IV/V). Writes NO state file
# (D32/constitution III) — freshness is entirely derived and recomputed fresh on every
# call; nothing is cached or reused across invocations.
#
# Usage:
#   freshness.sh <product-path>
#
#   <product-path>  path to a product file carrying the
#                   "<!-- graphify-provenance:v1 ... -->" header, exactly as the caller
#                   wrote it (relative or absolute). Echoed back verbatim in the
#                   stale-verdict line below — never resolved, never re-rooted.
#
# Two independent checks (SKILL.md "Freshness decision") — either failing => stale:
#
#   1. Product-vs-graph. Extract graph-path + generation-id from <product-path>'s
#      header. Resolve graph-path to a real file relative to the SCOPE ROOT —
#      `git rev-parse --show-toplevel` run from <product-path>'s OWN directory, never
#      this script's cwd or install location, so a caller invoking this with a
#      non-cwd-relative path still resolves correctly. (graph-path is documented,
#      SKILL.md "Field reference", as always written relative to that same root for
#      BOTH repo scope, "graphify-out/graph.json", and merged scope,
#      "../graphify-out/graph.json" — one resolution covers both; graph-scope itself is
#      never read here.) Recompute generation-id by CALLING the sibling provenance.sh
#      ("provenance.sh generation-id <resolved-graph-path>") — the ONE canonicalization
#      implementation (T004); it is never reimplemented in this script. A mismatch is
#      stale.
#
#   2. Graph-vs-worktree. Extract source-fingerprint.
#        - "git-commit:<sha>" (the only form this script verifies — the common case, and
#          the only one a single-repo git-commit fingerprint can meaningfully describe):
#          `git diff --quiet <sha>` from the same scope root; any diff, or any error
#          (unreachable sha, rewritten history), is stale.
#        - "sha256:<hex>" is the merged/stack-scope fallback (T004) — no fixture or
#          repo-scope graph in this repo needs it, so, per T004's own fail-closed rule,
#          an inability to verify it is stale, not a reason to add a second,
#          differently-scoped verification path here.
#
# Fail-closed, never fail-open: ANY error while recomputing either check — the product
# unreadable, the header or a field missing, the named graph.json absent, provenance.sh
# itself failing, an unreachable commit — is stale. Unprovable freshness is stale; this
# script never guesses its way to a quiet exit 0.
#
# Hard-warn, not hard-block (contracts/commands.md, Arm 2): this script has no side
# effects either way — callers are the ones who warn and route to regeneration on a
# non-zero exit; this script itself only ever reports.
#
# Out: exit 0 on fresh — stdout AND stderr both silent. Exit non-zero on stale, with
# EXACTLY "stale: regenerate <product-path>" on stdout (the CLI argument as given, byte
# for byte — never a resolved or absolute path) and nothing else on stdout; an optional
# one-line diagnostic naming which check failed goes to stderr only, never stdout. A
# malformed invocation (wrong argument count) or a missing sibling provenance.sh is a
# separate, non-zero die() failure instead — a broken toolchain, not a staleness
# verdict — and prints no "stale:" line.

set -eu

die() {
    printf 'freshness.sh: error: %s\n' "$1" >&2
    exit 1
}

usage() {
    printf 'usage: freshness.sh <product-path>\n' >&2
}

case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
esac

[ "$#" -eq 1 ] || { usage; exit 1; }
product="$1"
[ -n "$product" ] || { usage; exit 1; }

# ---------------------------------------------------------------------------------------
# stale() — the ONE place the pinned stdout contract is emitted, so the literal can never
# drift between call sites. $1 (optional) is a stderr-only diagnostic naming which check
# failed and why; it is never part of the stdout contract callers byte-match against.
# ---------------------------------------------------------------------------------------
stale() {
    [ -z "${1:-}" ] || printf 'freshness.sh: stale: %s\n' "$1" >&2
    printf 'stale: regenerate %s\n' "$product"
    exit 1
}

# ---------------------------------------------------------------------------------------
# Locate the sibling provenance.sh (rule 6: this script's own directory, independent of
# how freshness.sh itself was invoked). No generic "cd to a repo root" here (contrast the
# scripts/README.md skeleton) — this script's root of operation is the PRODUCT's own
# location, not the caller's cwd or this script's install directory; see check 1 below.
# ---------------------------------------------------------------------------------------
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd) || die "cannot resolve own directory from \$0 ($0)"
provenance_script="$script_dir/provenance.sh"
[ -f "$provenance_script" ] || die "sibling script not found: $provenance_script (freshness.sh composes provenance.sh for generation-id -- the T004 single shared implementation -- and cannot verify anything without it)"

# ---------------------------------------------------------------------------------------
# Check 1 -- product-vs-graph.
# ---------------------------------------------------------------------------------------

header=$(sed -n '/<!-- graphify-provenance:v1/,/-->/p' "$product" 2>/dev/null) || stale "cannot read $product"
[ -n "$header" ] || stale "no graphify-provenance:v1 header found in $product"

graph_path=$(printf '%s\n' "$header" | grep '^graph-path:' | sed 's/^graph-path: //') || stale "header has no graph-path field"
[ -n "$graph_path" ] || stale "header has no graph-path field"

recorded_gen_id=$(printf '%s\n' "$header" | grep '^generation-id:' | sed 's/^generation-id: //') || stale "header has no generation-id field"
[ -n "$recorded_gen_id" ] || stale "header has no generation-id field"

source_fp=$(printf '%s\n' "$header" | grep '^source-fingerprint:' | sed 's/^source-fingerprint: //') || stale "header has no source-fingerprint field"
[ -n "$source_fp" ] || stale "header has no source-fingerprint field"

# Scope root: git rev-parse --show-toplevel run from the PRODUCT's own directory (never
# this script's cwd or install location). graph-path is documented (SKILL.md "Field
# reference") as always relative to that same root for both repo and merged scope, so
# one resolution covers both uniformly -- graph-scope itself is never read.
product_dir=$(CDPATH= cd -- "$(dirname -- "$product")" 2>/dev/null && pwd) || stale "cannot resolve directory of $product"
scope_root=$(cd "$product_dir" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null) || stale "cannot resolve scope root from $product_dir (not inside a git repository?)"
resolved_graph="$scope_root/$graph_path"

recomputed_gen_id=$("$provenance_script" generation-id "$resolved_graph" 2>/dev/null) || stale "cannot recompute generation-id from $resolved_graph"
[ -n "$recomputed_gen_id" ] || stale "provenance.sh returned an empty generation-id for $resolved_graph"

[ "$recomputed_gen_id" = "$recorded_gen_id" ] \
    || stale "generation-id mismatch (header: $recorded_gen_id, recomputed: $recomputed_gen_id) -- graph rebuilt since this product was generated"

# ---------------------------------------------------------------------------------------
# Check 2 -- graph-vs-worktree.
# ---------------------------------------------------------------------------------------

case "$source_fp" in
    git-commit:*)
        commit_sha=${source_fp#git-commit:}
        [ -n "$commit_sha" ] || stale "empty commit sha in source-fingerprint"
        (cd "$scope_root" && git diff --quiet "$commit_sha" >/dev/null 2>&1) \
            || stale "worktree under $scope_root differs from source-fingerprint commit $commit_sha (or that commit is no longer reachable)"
        ;;
    sha256:*)
        # The merged/stack-scope fallback (T004) -- no fixture or repo-scope graph in
        # this repo needs it, so it is deliberately not implemented here; an inability
        # to verify is stale, per T004's own fail-closed rule, not a reason to guess.
        stale "source-fingerprint is sha256: (merged-scope fallback) -- verification not implemented; fail-closed"
        ;;
    *)
        stale "unrecognized source-fingerprint format: $source_fp"
        ;;
esac

# Both checks passed.
exit 0
