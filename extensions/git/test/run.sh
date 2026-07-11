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
#   4. workforce gate reinstall-survival — the same S04 property, extended (T020, 003-workforce)
#                                to after_workforce_approve: after a git-ext REINSTALL, do BOTH
#                                gates still route through record-gate in extensions.yml, is
#                                on-gate-approve.sh still present, and does `gates.sh write
#                                <gate>` still succeed for council AND workforce (R1-S04/S07/S17)?
#   5. before_specify drift lint (R1-S29/D50) — grep guard against the rejected before_specify
#                                branch-creation design
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
hook_action="$T/.specify/extensions/git/scripts/on-gate-approve.sh"

# pre-reinstall: seam call sites present
[ -f "$hook_action" ] && ok "T014 after_council_approve action installed" || bad "on-gate-approve.sh missing after install"
if grep -q 'after_council_approve' "$T/.specify/extensions.yml" 2>/dev/null; then ok "T014 after_council_approve hook registered"; else bad "after_council_approve hook not registered"; fi
if [ -f "$ipar" ] && grep -q "$marker" "$ipar"; then ok "T010 per-wave edit present after install"; else bad "T010 per-wave edit missing after install (graphify source not carrying it?)"; fi

# THE regression: reinstall graphify + council, then re-check the seam survived
sh "$REPO/extensions/graphify/install.sh" "$T" >/dev/null 2>&1 || true
sh "$REPO/extensions/council/install.sh" "$T" >/dev/null 2>&1 || true
if [ -f "$ipar" ] && grep -q "$marker" "$ipar"; then ok "T010 per-wave edit SURVIVED graphify reinstall (in graphify source)"; else bad "T010 per-wave edit WIPED by graphify reinstall — the S04 hazard"; fi
[ -f "$hook_action" ] && ok "T014 hook action SURVIVED council reinstall (git-ext-owned)" || bad "on-gate-approve.sh wiped by reinstall"
if grep -q 'after_council_approve' "$T/.specify/extensions.yml" 2>/dev/null; then ok "T014 hook registration SURVIVED reinstall"; else bad "after_council_approve deregistered by reinstall"; fi

# ---------------------------------------------------------------------------
bold "4. workforce gate reinstall-survival (R1-S04/S07/S17, 003-workforce)"
# T018/T019 generalized on-council-approve.sh -> on-gate-approve.sh <gate> and added
# after_workforce_approve alongside after_council_approve to extension.yml (S02/R8). T020
# fixed install.sh's manual PyYAML-unavailable fallback, which had been missing the
# after_workforce_approve entry (I-16/S02 — a reinstall on a fallback-only host would have
# silently dropped the workforce gate-write). This extends section 3's R1-S04 property to
# BOTH gates: after a git-ext REINSTALL, does extensions.yml still route each gate through
# record-gate, is on-gate-approve.sh still on disk, and does the actual write (`gates.sh
# write <gate>`) still work for council AND workforce?
W="$TMP/wgate"; W_SPEC="091-workforce-gate"
mk_repo "$W" "$W_SPEC"
W_SPEC_DIR="$W/specs/$W_SPEC"
printf '# plan\n' > "$W_SPEC_DIR/plan.md"
printf '# tasks\n' > "$W_SPEC_DIR/tasks.md"
# gates.sh's default workforce artifact list is `tasks.md agents/assignment.md` (the path was
# corrected in the S02 cluster — see I-18; the roster+gate live at specs/<id>/agents/assignment.md,
# the artifact-layout §8 home, which is what on-gate-approve.sh's bare `gates.sh write workforce`
# resolves). The fixture mirrors that real layout so the write actually binds.
mkdir -p "$W_SPEC_DIR/agents"
printf '# assignment\n' > "$W_SPEC_DIR/agents/assignment.md"
( cd "$W" && git add -A && git commit -qm artifacts )

sh "$GIT_EXT/install.sh" "$W" >/dev/null 2>&1

w_ext_yml="$W/.specify/extensions.yml"
w_gate_action="$W/.specify/extensions/git/scripts/on-gate-approve.sh"
w_gates_sh="$W/.specify/extensions/git/scripts/gates.sh"

# hook_block <file> <hooks-key> — the indented list entries under a top-level-under-`hooks:`
# key (e.g. after_workforce_approve), up to (not including) the next such key or EOF. Same
# block-extraction idiom as gates.sh's own gate_block() awk helper, adapted to extensions.yml's
# one-deeper (2-space) hook-key nesting under `hooks:`.
hook_block() {
  awk -v key="  $2:" '
    $0 == key { in_block = 1; next }
    in_block && /^  [A-Za-z]/ { in_block = 0 }
    in_block { print }
  ' "$1"
}
# gate_routed <hooks-key> <gate-value> — true if that hook's block both dispatches through
# record-gate AND carries the expected `gate:` value (not just record-gate present somewhere).
gate_routed() {
  block="$(hook_block "$w_ext_yml" "$1")"
  printf '%s\n' "$block" | grep -q 'command: speckit.git.record-gate' \
    && printf '%s\n' "$block" | grep -q "gate: $2"
}

# pre-reinstall baseline
gate_routed after_council_approve council && ok "after_council_approve routed through record-gate" || bad "after_council_approve not routed through record-gate"
gate_routed after_workforce_approve workforce && ok "after_workforce_approve routed through record-gate" || bad "after_workforce_approve not routed through record-gate"
[ -f "$w_gate_action" ] && ok "on-gate-approve.sh present after install" || bad "on-gate-approve.sh missing after install"
( cd "$W" && sh "$w_gates_sh" write council >/dev/null 2>&1 )   && ok "gates.sh write council succeeds"   || bad "gates.sh write council failed"
( cd "$W" && sh "$w_gates_sh" write workforce >/dev/null 2>&1 ) && ok "gates.sh write workforce succeeds" || bad "gates.sh write workforce failed"

# THE regression: a second git-ext install — the exact I-16/S02 hazard, since a REINSTALL of
# git-ext itself is what re-runs its own manual-fallback hook list — must not drop either wiring
sh "$GIT_EXT/install.sh" "$W" >/dev/null 2>&1

gate_routed after_council_approve council && ok "after_council_approve SURVIVED reinstall (record-gate)" || bad "after_council_approve lost its record-gate routing after reinstall"
gate_routed after_workforce_approve workforce && ok "after_workforce_approve SURVIVED reinstall (record-gate)" || bad "after_workforce_approve lost its record-gate routing after reinstall — the I-16/S02 hazard"
[ -f "$w_gate_action" ] && ok "on-gate-approve.sh SURVIVED reinstall" || bad "on-gate-approve.sh missing after reinstall"
( cd "$W" && sh "$w_gates_sh" write council >/dev/null 2>&1 )   && ok "gates.sh write council still succeeds after reinstall"   || bad "gates.sh write council broken after reinstall"
( cd "$W" && sh "$w_gates_sh" write workforce >/dev/null 2>&1 ) && ok "gates.sh write workforce still succeeds after reinstall" || bad "gates.sh write workforce broken after reinstall — R1-S04/S07/S17 now covering workforce"

# static check on the fix itself: install.sh's PyYAML-unavailable manual fallback block (the
# text a human pastes by hand on a host with neither a PyYAML interpreter nor `uv`) must also
# declare after_workforce_approve — the auto-merge exercised above can't reach that code path
# on this host (uv is present), so this greps the source directly for the fixed entry.
if awk '/^print_manual_block/,/^MANUAL$/' "$GIT_EXT/install.sh" | grep -q 'after_workforce_approve.*record-gate.*gate: workforce'; then
  ok "install.sh manual fallback declares after_workforce_approve (record-gate, gate: workforce)"
else
  bad "install.sh manual fallback still missing after_workforce_approve"
fi

# ---------------------------------------------------------------------------
bold "5. before_specify drift lint (R1-S29 / D50)"
# Mechanical, CI-runnable guard (rule-5 ethos: a grep, not a judgment) against reintroducing
# the REJECTED design — branch creation via a before_specify git-ext hook. The ratified design
# is branch-birth folded into after_specify (D-R1). Homed here as the concrete v1 vehicle until
# the D50 conformance checker ships (D50: "building the checker stays open"); relocate then.
SPECIFY_SKILL="$REPO/.claude/skills/speckit-specify/SKILL.md"
GCTX="$REPO/specs/002-speckit-ext-git/graphify-context.md"
# (a) drift signatures MUST be absent
if grep -Eq 'Branch creation is handled by the `?before_specify`? hook' "$SPECIFY_SKILL" 2>/dev/null; then
  bad "drift: speckit-specify NOTE attributes branch creation to before_specify (rejected design)"
else ok "no before_specify branch-creation claim in speckit-specify NOTE"; fi
if grep -Eq 'registers `?before_specify`? \+ commit' "$GCTX" 2>/dev/null; then
  bad "drift: graphify-context claims 002 registers a before_specify hook (rejected design)"
else ok "no before_specify-hook registration claim in graphify-context"; fi
# (b) ratified markers MUST be present (branch birth = after_specify) — affirms the corrected
#     design is stated, not merely that the drift phrasing was deleted. (Robust to markdown bold.)
if grep -q 'after_specify' "$SPECIFY_SKILL" 2>/dev/null; then ok "ratified after_specify branch-birth marker present in speckit-specify"; else bad "ratified after_specify marker missing from speckit-specify NOTE"; fi
if grep -q 'after_specify' "$GCTX" 2>/dev/null; then ok "ratified after_specify marker present in graphify-context"; else bad "ratified marker missing from graphify-context"; fi

# ---------------------------------------------------------------------------
bold "Result: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
