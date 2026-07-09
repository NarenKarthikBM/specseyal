#!/usr/bin/env sh
#
# speckit-ext-git — CI test harness (R1-S17)
# Scripted, model-free tests for a deterministic zero-AI extension:
#   1. branch.sh unit tests   — create-if-absent, idempotent switch, NNN-collision loud-fail
#   2. concurrency test        — concurrent branch.sh serialize without corruption (R1-S13)
#   3. reinstall-survival      — the S04 class a manual quickstart never catches: after a
#                                graphify/council REINSTALL, do the R1-seam call sites survive?
#                                (T010 per-wave commit in graphify-shipped speckit-implement-parallel;
#                                 T014 after_council_approve hook owned by the git extension.)
#
# Runs entirely in throwaway dirs under a temp root; never touches this repo.
# Usage:  sh extensions/git/test/run.sh
#
set -eu

REPO="$(cd "$(dirname "$0")/../../.." && pwd)"          # repo root (…/specseyal)
GIT_EXT="$REPO/extensions/git"
BRANCH_SH="$GIT_EXT/extension/scripts/branch.sh"
TMP="${TMPDIR:-/tmp}/speckit-git-test.$$"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); printf '  \033[32mPASS\033[0m %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  \033[31mFAIL\033[0m %s\n' "$1"; }
bold() { printf '\n\033[1m%s\033[0m\n' "$1"; }

# fabricate a minimal spec-kit repo with a feature.json pointing at <spec-id>
mk_repo() {  # $1 = dir, $2 = spec-id
  mkdir -p "$1/.specify" "$1/specs/$2"
  ( cd "$1" && git init -q && git config user.email t@t && git config user.name t )
  printf '{"feature_directory": "specs/%s"}\n' "$2" > "$1/.specify/feature.json"
  printf '# spec\n' > "$1/specs/$2/spec.md"
  ( cd "$1" && git add -A && git commit -qm init )
}

# ---------------------------------------------------------------------------
bold "1. branch.sh units"
R1="$TMP/u1"; mk_repo "$R1" "042-alpha-feature"
( cd "$R1" && sh "$BRANCH_SH" >/dev/null 2>&1 )
if ( cd "$R1" && [ "$(git rev-parse --abbrev-ref HEAD)" = "042-alpha-feature" ] ); then ok "creates branch = spec id when absent"; else bad "branch not created / wrong name"; fi
# idempotent: re-run switches, no error, no duplicate
if ( cd "$R1" && sh "$BRANCH_SH" >/dev/null 2>&1 && [ "$(git rev-parse --abbrev-ref HEAD)" = "042-alpha-feature" ] ); then ok "idempotent re-run (switch, no error)"; else bad "re-run errored or diverged"; fi
# NNN-collision loud-fail: a branch with same NNN, different slug already exists
R2="$TMP/u2"; mk_repo "$R2" "042-beta-feature"
( cd "$R2" && git branch 042-different-slug >/dev/null 2>&1 )
if ( cd "$R2" && sh "$BRANCH_SH" >/dev/null 2>&1 ); then bad "did NOT loud-fail on NNN-collision (R1-S13)"; else ok "loud-fails on NNN-collision, different slug (R1-S13)"; fi

# ---------------------------------------------------------------------------
bold "2. concurrency (R1-S13 lock)"
R3="$TMP/c1"; mk_repo "$R3" "077-concurrent"
( cd "$R3" && sh "$BRANCH_SH" >/dev/null 2>&1 ) &  p1=$!
( cd "$R3" && sh "$BRANCH_SH" >/dev/null 2>&1 ) &  p2=$!
wait "$p1" 2>/dev/null || true; wait "$p2" 2>/dev/null || true
n=$( cd "$R3" && git branch --list '077-concurrent' | wc -l | tr -d ' ' )
if [ "$n" = "1" ]; then ok "concurrent branch.sh → branch created exactly once (no corruption)"; else bad "concurrent race produced $n branches"; fi
# no lock left wedged
if [ -z "$(find "$R3" -name '*.lock' -o -name '*branch*lock*' 2>/dev/null)" ]; then ok "no stale lock left behind"; else bad "stale lock remained"; fi

# ---------------------------------------------------------------------------
bold "3. reinstall-survival regression (R1-S04)"
T="$TMP/target"; mkdir -p "$T/.specify"
# a spec-kit target with the stock skills graphify overwrites (implement-parallel)
mkdir -p "$T/.claude/skills"
sh "$GIT_EXT/install.sh" "$T" >/dev/null 2>&1
sh "$REPO/extensions/graphify/install.sh" "$T" >/dev/null 2>&1 || true
sh "$REPO/extensions/council/install.sh" "$T" >/dev/null 2>&1 || true

marker='verify-gate workforce'          # T010 per-wave edit marker
ipar="$T/.claude/skills/speckit-implement-parallel/SKILL.md"
hook_action="$T/.specify/extensions/git/scripts/on-council-approve.sh"

# pre-reinstall: seam call sites present
[ -f "$hook_action" ] && ok "T014 after_council_approve action installed" || bad "on-council-approve.sh missing after install"
if grep -q 'after_council_approve' "$T/.specify/extensions.yml" 2>/dev/null; then ok "T014 after_council_approve hook registered"; else bad "after_council_approve hook not registered"; fi
if [ -f "$ipar" ] && grep -q "$marker" "$ipar"; then ok "T010 per-wave edit present after install"; else bad "T010 per-wave edit missing after install (graphify source not carrying it?)"; fi

# THE regression: reinstall graphify + council, then re-check the seam survived
sh "$REPO/extensions/graphify/install.sh" "$T" >/dev/null 2>&1 || true
sh "$REPO/extensions/council/install.sh" "$T" >/dev/null 2>&1 || true
if [ -f "$ipar" ] && grep -q "$marker" "$ipar"; then ok "T010 per-wave edit SURVIVED graphify reinstall (in graphify source)"; else bad "T010 per-wave edit WIPED by graphify reinstall — the S04 hazard"; fi
[ -f "$hook_action" ] && ok "T014 hook action SURVIVED council reinstall (git-ext-owned)" || bad "on-council-approve.sh wiped by reinstall"
if grep -q 'after_council_approve' "$T/.specify/extensions.yml" 2>/dev/null; then ok "T014 hook registration SURVIVED reinstall"; else bad "after_council_approve deregistered by reinstall"; fi

# ---------------------------------------------------------------------------
bold "Result: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
