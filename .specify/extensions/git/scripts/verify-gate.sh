#!/bin/sh
# verify-gate.sh — speckit.git.verify-gate <gate>
#
# The gate-freshness hard-block primitive (specs/002-speckit-ext-git/
# contracts/commands.md #speckit.git.verify-gate; data-model.md
# #GateSHABinding "Freshness rule (FR-009)"). Fired by the before_tasks
# (gate=council) and before_implement (gate=workforce) hooks: a non-zero
# exit here is a HARD BLOCK on the gated phase (contracts/commands.md,
# Hooks table: "non-zero => hard-block"). Zero AI, mechanical git only: no
# commit, no model call, no traces.jsonl write (FR-007).
#
# Usage:
#   verify-gate.sh <council|workforce>
#
# What "fresh" means (data-model.md #GateSHABinding, FR-009) — a
# GateSHABinding is fresh iff BOTH hold, for EVERY artifact the gate binds:
#
#   1. The recorded <sha> (from gates.yml, read via the sibling
#      `gates.sh read <gate>`) equals the artifact's CURRENT committed SHA
#      (the sibling `sha.sh <artifact>` — "the SHA of the HEAD commit that
#      last touched <artifact-path>"). A mismatch is stale.
#
#   2. Working-tree-aware (R1-S05) — CRITICAL: even when (1) matches, the
#      artifact is stale if it has ANY uncommitted change right now —
#      unstaged (`git diff --quiet -- <artifact>`) OR staged
#      (`git diff --cached --quiet -- <artifact>`). The gate approved
#      committed CONTENT; a dirty hand-edit after approval means the
#      content actually on disk no longer matches what was approved, even
#      though the committed SHA both sides would naively compare hasn't
#      moved. Comparing committed SHAs alone is exactly the hole FR-009
#      exists to close — this check is not optional or best-effort, and it
#      always runs in addition to (never instead of) check 1.
#
# Fail-closed, never fail-open — this script never guesses its way to
# exit 0. Treated as stale (block), specifically citing R1-S10 where the
# source docs do:
#
#   - specs/<spec-id>/gates.yml is missing entirely (R1-S10).
#   - the requested gate's binding is absent or empty (R1-S10).
#   - gates.sh otherwise exits non-zero for ANY reason — unparseable line,
#     gates.yml format-version drift, etc. (R1-S10). This script never
#     tries to make sense of *why* gates.sh failed; any non-zero from it
#     means "nothing trustworthy to verify," full stop.
#   - a binding line, once read, still fails this script's own defensive
#     re-validation (missing artifact name / SHA not hex) (R1-S10).
#   - the sibling sha.sh can't resolve a current SHA for a bound artifact
#     at all (e.g. no commit history left for that path) — fail-closed,
#     though this particular case isn't itself an R1-S10 gates.yml/binding
#     issue, just the same "when in doubt, block" principle applied to a
#     different failure mode.
#
# Read-only: composes gates.sh (to read bindings — this script never reads
# or writes gates.yml directly, matching gates.yml's sole-owner ruling,
# R1-S09/S20) and sha.sh (to resolve a current SHA — this script never
# computes a SHA itself), plus plain read-only `git diff --quiet` calls for
# the working-tree check. No git state is ever changed by this script.
#
# Spec ID resolution (D45 — .specify/feature.json is the sole spec-ID
# resolver, same as every other script in this extension): basename of
# feature.json's "feature_directory". Needed here independently of
# gates.sh (which resolves its own copy internally) to turn the SHORT
# artifact names gates.sh prints (e.g. "plan.md") back into the
# repo-relative paths (specs/<spec-id>/plan.md) that sha.sh and `git diff`
# expect.
#
# Exit: 0 iff every recorded artifact for <gate> is fresh. Non-zero
# otherwise, with a human-readable line on stderr per stale/unverifiable
# artifact naming it and why (SHA mismatch vs. dirty tree vs. missing/
# malformed binding vs. unreadable gates.yml). Silent on stdout and stderr
# when fresh (exit 0) — the exit code IS the contract on the happy path.

set -eu

die() {
    printf 'verify-gate.sh: error: %s\n' "$1" >&2
    exit 1
}

usage() {
    printf 'usage: verify-gate.sh <council|workforce>\n' >&2
}

case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
esac

if [ "$#" -ne 1 ]; then
    usage
    exit 1
fi

gate="$1"

case "$gate" in
    council|workforce) : ;;
    *) die "unknown gate '$gate' (expected 'council' or 'workforce')" ;;
esac

# ---------------------------------------------------------------------------
# Locate the sibling primitives this script composes (never reimplements —
# see header). Resolved from this script's own directory so invocation
# works regardless of the caller's CWD or how verify-gate.sh itself was
# invoked (relative, ./-relative, or absolute) — same technique gates.sh
# uses to resolve its own sha.sh.
# ---------------------------------------------------------------------------

script_dir=$(dirname "$0")
script_dir=$(cd "$script_dir" 2>/dev/null && pwd) || die "cannot resolve script directory from '$0'"

gates_script="$script_dir/gates.sh"
[ -f "$gates_script" ] || die "sibling script not found: $gates_script (verify-gate.sh composes gates.sh to read recorded bindings — fail-closed, cannot verify anything without it)"

sha_script="$script_dir/sha.sh"
[ -f "$sha_script" ] || die "sibling script not found: $sha_script (verify-gate.sh composes sha.sh for every current-SHA lookup — fail-closed, cannot verify anything without it)"

# ---------------------------------------------------------------------------
# Repo root + feature.json (D45: feature.json is the sole spec-ID resolver).
# ---------------------------------------------------------------------------

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || die "not inside a git repository"
cd "$repo_root"

feature_json=".specify/feature.json"
[ -f "$feature_json" ] || die "$feature_json not found — run /speckit-specify first"

feature_directory=$(grep '"feature_directory"' "$feature_json" 2>/dev/null \
    | head -n 1 \
    | sed -E 's/.*"feature_directory"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')

[ -n "$feature_directory" ] || die "could not read \"feature_directory\" from $feature_json"

spec_id=$(basename "$feature_directory")

# ---------------------------------------------------------------------------
# Read the recorded bindings for this gate via the sibling gates.sh — the
# sole owner of gates.yml (data-model.md #GateSHABinding). ANY non-zero
# exit from gates.sh (missing gates.yml, gate never recorded, unparseable
# line, format-version drift — see gates.sh's own header) is fail-closed
# here: this script does not try to distinguish those cases from each
# other, it just blocks (R1-S10). gates.sh's own stderr is captured and
# relayed (indented) so the human sees exactly why.
# ---------------------------------------------------------------------------

if bindings=$("$gates_script" read "$gate" 2>&1); then
    :
else
    printf 'verify-gate.sh: error: gate "%s" blocked — could not read recorded bindings via gates.sh (fail-closed, R1-S10):\n' "$gate" >&2
    printf '%s\n' "$bindings" | sed 's/^/    /' >&2
    exit 1
fi

# Defensive (R1-S10): never trust "gates.sh exited 0" alone as proof there
# is something real to verify — an empty/blank success is fail-closed too
# ("the gate's binding is absent/empty"). Belt-and-suspenders: gates.sh's
# own cmd_read already refuses to return an empty block, but this script
# does not rely solely on a sibling's internal invariant.
non_blank=$(printf '%s' "$bindings" | tr -d '[:space:]')
if [ -z "$non_blank" ]; then
    printf 'verify-gate.sh: error: gate "%s" blocked — gates.sh reported success but returned no bindings to verify (fail-closed, R1-S10)\n' "$gate" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Split gates.sh's "<artifact> @ <sha>" lines into positional params rather
# than piping into `while read` — a pipeline's final stage commonly runs in
# a subshell (dash always; bash unless lastpipe is on), which would
# silently drop the stale_found/report state this loop needs to survive
# it. Same newline-split idiom commit.sh uses for its own multi-path list.
# ---------------------------------------------------------------------------

old_ifs=$IFS
IFS='
'
set -f
set -- $bindings
set +f
IFS=$old_ifs

stale_found=0
checked_count=0
report=""

# mark_stale <reason> — record a stale/unverifiable finding and remember
# that the gate must block. <reason> should name the artifact; no leading
# indentation (indentation is applied once, uniformly, at final print
# time).
mark_stale() {
    stale_found=1
    if [ -n "$report" ]; then
        report="$report
$1"
    else
        report="$1"
    fi
}

for line in "$@"; do
    [ -n "$line" ] || continue
    checked_count=$((checked_count + 1))

    case "$line" in
        *' @ '*) : ;;
        *)
            mark_stale "malformed binding line (no ' @ ' separator): '$line' — fail-closed, R1-S10"
            continue
            ;;
    esac

    artifact=$(printf '%s' "$line" | cut -d'@' -f1 | sed -E 's/[[:space:]]+$//')
    recorded_sha=$(printf '%s' "$line" | cut -d'@' -f2- | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')

    if [ -z "$artifact" ] || ! printf '%s' "$recorded_sha" | LC_ALL=C grep -Eq '^[0-9a-f]+$'; then
        mark_stale "malformed binding value in line '$line' — fail-closed, R1-S10"
        continue
    fi

    artifact_path="specs/$spec_id/$artifact"

    # 1. Current committed SHA vs. recorded SHA (sha.sh is the sole SHA
    #    authority — see header; this script never computes one itself).
    #    sha.sh failing at all (e.g. no commit history left for the path)
    #    is fail-closed too, though not itself an R1-S10 gates.yml issue.
    if current_sha=$("$sha_script" "$artifact_path" 2>&1); then
        :
    else
        mark_stale "$artifact: could not resolve a current SHA via sha.sh — treating as stale (fail-closed) — $current_sha"
        continue
    fi

    if [ "$current_sha" != "$recorded_sha" ]; then
        mark_stale "$artifact: SHA mismatch — recorded $recorded_sha, current $current_sha (FR-009)"
        continue
    fi

    # 2. Working-tree-aware check (R1-S05) — CRITICAL, see header: even
    #    though the committed SHA matches, a dirty hand-edit (unstaged OR
    #    staged) means the CURRENT content differs from what was approved.
    dirty=0
    git diff --quiet -- "$artifact_path" || dirty=1
    git diff --cached --quiet -- "$artifact_path" || dirty=1

    if [ "$dirty" -eq 1 ]; then
        mark_stale "$artifact: working tree is dirty (uncommitted changes present) even though the committed SHA ($recorded_sha) matches — a dirty approved artifact is stale (R1-S05)"
        continue
    fi

    # Fresh: no report entry, no output — silence is the contract here.
done

# Defensive redundant safety net (should be unreachable given the
# non_blank check above; kept anyway per this extension's "fail closed,
# never assume" ethos): a "successful" read that somehow yielded zero
# actually-parseable lines is still nothing to trust.
if [ "$checked_count" -eq 0 ]; then
    mark_stale "gate '$gate' had no parseable bindings after all — fail-closed, R1-S10"
fi

if [ "$stale_found" -eq 1 ]; then
    printf 'verify-gate.sh: error: gate "%s" is stale — phase blocked (FR-009). Stale/unverifiable binding(s):\n' "$gate" >&2
    printf '%s\n' "$report" | sed 's/^/    /' >&2
    exit 1
fi

exit 0
