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
bold "6. I-17 checkbox-delta survival regression (FR-015)"
# Regresses the checkbox-delta admissible-staleness branch verify-gate.sh
# grew for gate=workforce, artifact=tasks.md ONLY (I-17 — see that script's
# own header "EXCEPTION" paragraph) by invoking the INSTALLED copy the way
# a real before_implement hook would, never the source tree directly — so
# this doubles as the FR-015/R1-S15 survival property: after a git-ext
# reinstall (the fix lives in extensions/git/extension/scripts/
# verify-gate.sh, redeployed wholesale by install.sh's rm -rf + cp -R) and
# after an unrelated foreign extension's reinstall, the same forward-flip
# PASS and reverse-flip BLOCK must still hold. agents/assignment.md and
# the council/plan.md binding are deliberately OUT of this branch's scope
# and keep the pre-I-17 strict SHA+dirty-tree check — case 6g is the
# regression proving that boundary holds (the tolerance must not leak).

W6="$TMP/cbdelta"; W6_SPEC="092-checkbox-delta"
mk_repo "$W6" "$W6_SPEC"
mkdir -p "$W6/.claude/skills"   # defensive, mirrors §3 before any install

W6_SPEC_DIR="$W6/specs/$W6_SPEC"
W6_TASKS="$W6_SPEC_DIR/tasks.md";              W6_TASKS_REL="specs/$W6_SPEC/tasks.md"
W6_ASSIGN_DIR="$W6_SPEC_DIR/agents"
W6_ASSIGN="$W6_ASSIGN_DIR/assignment.md";      W6_ASSIGN_REL="specs/$W6_SPEC/agents/assignment.md"
W6_PLAN="$W6_SPEC_DIR/plan.md";                W6_PLAN_REL="specs/$W6_SPEC/plan.md"
W6_GATES="$W6_SPEC_DIR/gates.yml"
VG="$W6/.specify/extensions/git/scripts/verify-gate.sh"

# ---- fixture-content generators — each does a full rewrite of $W6_TASKS
# rather than an in-place sed edit: under set -eu a full rewrite makes
# every case's diff-against-HEAD obvious straight off its printf block,
# with nothing left over from a previous case to account for. ------------
w6_write_base() {
  printf '%s\n' \
    '# Tasks' \
    '' \
    '- [ ] T001 implement widget loader' \
    '- [ ] T002 wire up the thing' \
    '  - [ ] T002a sub-item for T002' \
    'This is prose, not a task line.' \
    > "$W6_TASKS"
}
w6_write_t001_checked() {                     # case 6a AND the 6f "approved" commit
  printf '%s\n' \
    '# Tasks' \
    '' \
    '- [X] T001 implement widget loader' \
    '- [ ] T002 wire up the thing' \
    '  - [ ] T002a sub-item for T002' \
    'This is prose, not a task line.' \
    > "$W6_TASKS"
}
w6_write_t002_and_t002a_checked() {            # case 6b — 2 flips, one indented, one lowercase
  printf '%s\n' \
    '# Tasks' \
    '' \
    '- [ ] T001 implement widget loader' \
    '- [X] T002 wire up the thing' \
    '  - [x] T002a sub-item for T002' \
    'This is prose, not a task line.' \
    > "$W6_TASKS"
}
w6_write_edited_text() {                       # case 6c — flip + reworded task
  printf '%s\n' \
    '# Tasks' \
    '' \
    '- [x] T001 implement the WIDGET loader (renamed)' \
    '- [ ] T002 wire up the thing' \
    '  - [ ] T002a sub-item for T002' \
    'This is prose, not a task line.' \
    > "$W6_TASKS"
}
w6_write_unpaired_insert() {                   # case 6d — flip + brand-new task line
  printf '%s\n' \
    '# Tasks' \
    '' \
    '- [X] T001 implement widget loader' \
    '- [ ] T002 wire up the thing' \
    '  - [ ] T002a sub-item for T002' \
    'This is prose, not a task line.' \
    '- [ ] T099 unexpectedly inserted task' \
    > "$W6_TASKS"
}
w6_write_unpaired_delete() {                   # case 6e — whole task line removed
  printf '%s\n' \
    '# Tasks' \
    '' \
    '- [ ] T001 implement widget loader' \
    '- [ ] T002 wire up the thing' \
    'This is prose, not a task line.' \
    > "$W6_TASKS"
}
w6_write_survival_fwd() {                      # post-6f baseline (T001 already [X]) + T002 flip
  printf '%s\n' \
    '# Tasks' \
    '' \
    '- [X] T001 implement widget loader' \
    '- [x] T002 wire up the thing' \
    '  - [ ] T002a sub-item for T002' \
    'This is prose, not a task line.' \
    > "$W6_TASKS"
}

w6_write_gates() {   # $1=tasks_sha $2=assign_sha $3=plan_sha
  {
    printf '# gates.yml -- test fixture GateSHABinding record (mirrors\n'
    printf '# specs/004-testing-completion/gates.yml shape).\n'
    printf 'version: 1\n'
    printf 'council:\n'
    printf '  plan.md: %s\n' "$3"
    printf 'workforce:\n'
    printf '  tasks.md: %s\n' "$1"
    printf '  agents/assignment.md: %s\n' "$2"
  } > "$W6_GATES"
}

# w6_run — invoke the INSTALLED verify-gate (never the source tree) for
# gate=workforce from inside the fixture repo; sets w6_rc (exit code) and
# w6_out (combined stdout+stderr, which is where the checkbox-delta audit
# line and every block reason land). The "A && B || C" shape keeps the
# assignment itself out of set -eu's errexit net (verify-gate legitimately
# exits 1 on most of the cases below) without toggling set +e/-e globally.
w6_run() {
  w6_out=$( ( cd "$W6" && sh "$VG" workforce ) 2>&1 ) && w6_rc=0 || w6_rc=$?
}
w6_reset_tasks()  { ( cd "$W6" && git checkout -- "$W6_TASKS_REL" ) >/dev/null 2>&1; }
w6_reset_assign() { ( cd "$W6" && git checkout -- "$W6_ASSIGN_REL" ) >/dev/null 2>&1; }

w6_assert_pass() {   # $1 = label, $2 = optional additional required substring
  if [ "$w6_rc" -eq 0 ]; then
    case "$w6_out" in
      *'PASS via checkbox-delta'*)
        if [ -n "${2:-}" ]; then
          case "$w6_out" in
            *"$2"*) ok "$1 (audit: PASS via checkbox-delta, $2)" ;;
            *)      bad "$1 — audit line present but missing '$2' — got: $w6_out" ;;
          esac
        else
          ok "$1 (audit: PASS via checkbox-delta)"
        fi
        ;;
      *) bad "$1 — exit 0 but no 'PASS via checkbox-delta' audit line (R1-S09) — got: $w6_out" ;;
    esac
  else
    bad "$1 — expected exit 0 (PASS), got exit $w6_rc — $w6_out"
  fi
}
w6_assert_block() {  # $1 = label, $2 = optional required substring in the block reason
  if [ "$w6_rc" -ne 0 ]; then
    if [ -n "${2:-}" ]; then
      case "$w6_out" in
        *"$2"*) ok "$1 (blocked, citing $2)" ;;
        *)      bad "$1 — blocked but message did not cite '$2' — got: $w6_out" ;;
      esac
    else
      ok "$1 (blocked as expected, exit $w6_rc)"
    fi
  else
    bad "$1 — expected a BLOCK (non-zero exit), got exit 0 — $w6_out"
  fi
}

# ---- fixture: base commit — three unchecked GFM task lines (one an
# indented sub-item) + one prose line, plus agents/assignment.md and
# plan.md so the workforce AND council bindings both resolve to real
# committed SHAs. -----------------------------------------------------
w6_write_base
mkdir -p "$W6_ASSIGN_DIR"
printf '# assignment\n\nroster placeholder.\n' > "$W6_ASSIGN"
printf '# plan\n' > "$W6_PLAN"
( cd "$W6" && git add -A && git commit -qm 'w6 artifacts' )

W6_TASKS_SHA1=$( cd "$W6" && git log -1 --format=%H -- "$W6_TASKS_REL" )
W6_ASSIGN_SHA1=$( cd "$W6" && git log -1 --format=%H -- "$W6_ASSIGN_REL" )
W6_PLAN_SHA1=$( cd "$W6" && git log -1 --format=%H -- "$W6_PLAN_REL" )

# ---- install git-ext, then bind the workforce gate straight to the SHAs
# above — exactly what the real sha.sh prints for these paths (verified
# independently in §1/§4). ------------------------------------------------
sh "$GIT_EXT/install.sh" "$W6" >/dev/null 2>&1
w6_write_gates "$W6_TASKS_SHA1" "$W6_ASSIGN_SHA1" "$W6_PLAN_SHA1"

# (a) forward flip — single box, uppercase X: PASS via checkbox-delta.
w6_write_t001_checked
w6_run
w6_assert_pass "6a forward flip (tasks.md T001 [ ]->[X])" "1 forward GFM checkbox advance(s)"
w6_reset_tasks

# (b) multiple forward flips, including the indented sub-item, mixed case.
w6_write_t002_and_t002a_checked
w6_run
w6_assert_pass "6b multiple forward flips (T002 [X] + indented T002a [x])" "2 forward GFM checkbox advance(s)"
w6_reset_tasks

# (c) a flip riding along with an edited task line — must BLOCK, not PASS.
w6_write_edited_text
w6_run
w6_assert_block "6c edited task text alongside a flip"
w6_reset_tasks

# (d) unpaired insertion — a flip plus a brand-new task line — BLOCK (R1-S04).
w6_write_unpaired_insert
w6_run
w6_assert_block "6d unpaired insertion (flip + new T099 line)" "R1-S04"
w6_reset_tasks

# (e) unpaired deletion — a whole task line removed, nothing else — BLOCK (R1-S04).
w6_write_unpaired_delete
w6_run
w6_assert_block "6e unpaired deletion (T002a line removed)" "R1-S04"
w6_reset_tasks

# (f) REVERSE flip — the load-bearing case (R1-S14/S18 direction
# asymmetry). First establish an APPROVED state where the box is
# CHECKED: commit it (scoped to tasks.md only, so this stays a clean,
# minimal history) and rebind gates.yml's workforce/tasks.md entry to
# that new SHA.
w6_write_t001_checked
( cd "$W6" && git add "$W6_TASKS_REL" && git commit -qm 'w6 T001 approved-checked' )
W6_TASKS_SHA2=$( cd "$W6" && git log -1 --format=%H -- "$W6_TASKS_REL" )
w6_write_gates "$W6_TASKS_SHA2" "$W6_ASSIGN_SHA1" "$W6_PLAN_SHA1"
# Flip that same box back to unchecked. w6_write_base is, not by
# coincidence, exactly "T001 unchecked, everything else identical to the
# SHA2 commit" — SHA2 only ever touched T001 — so reusing it here
# produces a minimal single-line REVERSE diff against the new baseline.
w6_write_base
w6_run
w6_assert_block "6f REVERSE flip (T001 [X]->[ ] vs. an approved-checked SHA)" "R1-S14/S18"
w6_reset_tasks

# (g) scope guard — the checkbox tolerance is scoped EXCLUSIVELY to
# gate=workforce, artifact=tasks.md (I-17). It must not leak to
# agents/assignment.md, which keeps the pre-I-17 strict SHA +
# working-tree-dirty check. tasks.md is clean here (just reset to
# HEAD/SHA2, matching gates.yml's current tasks.md binding); only
# assignment.md is dirtied.
printf '# assignment\n\nroster placeholder.\nhand-edited, uncommitted.\n' > "$W6_ASSIGN"
w6_run
w6_assert_block "6g scope guard (dirty agents/assignment.md, tasks.md clean)" "R1-S05"
w6_reset_assign

# ---- THE survival property (FR-015 / R1-S15): the fix lives in the
# extension's SOURCE tree, redeployed wholesale (rm -rf + cp -R) by
# install.sh on every install. Reinstalling git-ext, then reinstalling an
# unrelated foreign extension, must not regress either the forward-flip
# PASS or the reverse-flip BLOCK. Baseline entering this round: HEAD =
# SHA2 (T001 checked), gates.yml tasks.md @ SHA2 — set by case (f) above.
sh "$GIT_EXT/install.sh" "$W6" >/dev/null 2>&1

w6_write_survival_fwd
w6_run
w6_assert_pass "6a forward flip SURVIVED git-ext reinstall" "1 forward GFM checkbox advance(s)"
w6_reset_tasks

w6_write_base
w6_run
w6_assert_block "6f reverse flip SURVIVED git-ext reinstall" "R1-S14/S18"
w6_reset_tasks

sh "$REPO/extensions/graphify/install.sh" "$W6" >/dev/null 2>&1 || true

w6_write_survival_fwd
w6_run
w6_assert_pass "6a forward flip SURVIVED foreign (graphify) reinstall" "1 forward GFM checkbox advance(s)"
w6_reset_tasks

w6_write_base
w6_run
w6_assert_block "6f reverse flip SURVIVED foreign (graphify) reinstall" "R1-S14/S18"
w6_reset_tasks

# ---------------------------------------------------------------------------
bold "7. testing/complete commit-seam survival regression (SC-006/008)"
# Regresses the after_complete / after_testing hook pair layered onto git-ext's
# manifest: commit.sh's phase enum now also accepts "complete" and "testing"
# (ordinary PhaseCommit grammar, <phase>(<spec-id>): <summary>), and
# extension.yml declares both hooks routed to speckit.git.commit with
# phase: complete / phase: testing respectively. There is still no
# HookExecutor in v1 (D53) — hooks are prose-level, run by the invoking
# phase-skill — so this regression does NOT auto-fire either hook. Instead it
# proves the seam two ways: (a) DECLARATION — both hooks are registered in
# .specify/extensions.yml and routed to the right command + phase after
# install; (b) FUNCTION — invoking the INSTALLED commit.sh directly with
# phase complete/testing (exactly what the after_complete / after_testing
# hooks do once their phase-skill fires them) produces the correctly-tagged
# commit; a rejected phase would die non-zero and leave no commit, so this
# doubles as proof the enum change landed. Then, per R1-S08/SC-008, BOTH
# sides must SURVIVE a git-ext reinstall and a foreign extension's reinstall
# — the same S04-class hazard sections 3/4/6 regress for other git-ext
# seams, extended here to the complete/testing pair.

S7="$TMP/seam"; S7_SPEC="093-seam"
mk_repo "$S7" "$S7_SPEC"
S7_SPEC_DIR="$S7/specs/$S7_SPEC"
printf '# report\n' > "$S7_SPEC_DIR/completion-report.md"

sh "$GIT_EXT/install.sh" "$S7" >/dev/null 2>&1

s7_ext_yml="$S7/.specify/extensions.yml"
s7_commit_sh="$S7/.specify/extensions/git/scripts/commit.sh"

# hook_routed <hooks-key> <phase-value> — like §4's gate_routed, but for the
# phase: field the commit-seam hooks carry instead of gate:. Reuses §4's
# hook_block to extract the hook's registry block, then asserts it both
# dispatches through speckit.git.commit AND carries the expected phase.
hook_routed() {
  block="$(hook_block "$s7_ext_yml" "$1")"
  printf '%s\n' "$block" | grep -q 'command: speckit.git.commit' \
    && printf '%s\n' "$block" | grep -q "phase: $2"
}

# ---- (a) declaration side: both hooks registered + routed after install ---
hook_routed after_complete complete && ok "after_complete routed to speckit.git.commit, phase: complete" || bad "after_complete not routed to speckit.git.commit / phase: complete"
hook_routed after_testing  testing  && ok "after_testing routed to speckit.git.commit, phase: testing"   || bad "after_testing not routed to speckit.git.commit / phase: testing"

# ---- (b) function side: the installed commit.sh primitive produces the
# tagged commit for each phase — the seam's other half, simulating exactly
# what the after_complete / after_testing hooks do when their phase-skill
# fires them. -----------------------------------------------------------
if ( cd "$S7" && sh "$s7_commit_sh" complete "finalized report" >/dev/null 2>&1 ); then
  if git -C "$S7" log --format=%s | grep -qx "complete($S7_SPEC): finalized report"; then
    ok "commit.sh complete → complete($S7_SPEC): finalized report"
  else
    bad "commit.sh complete exited 0 but no matching commit subject found"
  fi
else
  bad "commit.sh complete exited non-zero (phase enum rejected 'complete'?)"
fi

printf '# testing\n' > "$S7_SPEC_DIR/testing.md"
if ( cd "$S7" && sh "$s7_commit_sh" testing "coverage mapped" >/dev/null 2>&1 ); then
  if git -C "$S7" log --format=%s | grep -qx "testing($S7_SPEC): coverage mapped"; then
    ok "commit.sh testing → testing($S7_SPEC): coverage mapped"
  else
    bad "commit.sh testing exited 0 but no matching commit subject found"
  fi
else
  bad "commit.sh testing exited non-zero (phase enum rejected 'testing'?)"
fi

# ---- THE survival property (R1-S08/SC-008): reinstall git-ext, then
# re-assert BOTH the declaration side and the function side. ----------------
sh "$GIT_EXT/install.sh" "$S7" >/dev/null 2>&1

hook_routed after_complete complete && ok "after_complete routing SURVIVED git-ext reinstall" || bad "after_complete routing lost after git-ext reinstall"
hook_routed after_testing  testing  && ok "after_testing routing SURVIVED git-ext reinstall"  || bad "after_testing routing lost after git-ext reinstall"

printf '# report v2\n' > "$S7_SPEC_DIR/completion-report.md"
if ( cd "$S7" && sh "$s7_commit_sh" complete "post-reinstall" >/dev/null 2>&1 ); then
  if git -C "$S7" log --format=%s | grep -qx "complete($S7_SPEC): post-reinstall"; then
    ok "commit.sh complete SURVIVED git-ext reinstall → complete($S7_SPEC): post-reinstall"
  else
    bad "commit.sh complete SURVIVED reinstall but no matching commit subject found"
  fi
else
  bad "commit.sh complete broken after git-ext reinstall"
fi

# ---- a foreign extension's reinstall must not deregister git-ext's seam ---
sh "$REPO/extensions/graphify/install.sh" "$S7" >/dev/null 2>&1 || true

hook_routed after_complete complete && ok "after_complete routing SURVIVED foreign (graphify) reinstall" || bad "after_complete routing lost after foreign (graphify) reinstall"
hook_routed after_testing  testing  && ok "after_testing routing SURVIVED foreign (graphify) reinstall"  || bad "after_testing routing lost after foreign (graphify) reinstall"

# ---------------------------------------------------------------------------
bold "8. worktree regression (I-28): .git is a FILE, not a directory"
# Every section above builds a plain clone via mk_repo, where `.git` is a real
# directory — which is exactly why this bug survived to 006. In a LINKED
# WORKTREE `.git` is a FILE (`gitdir: …/.git/worktrees/<name>`), so a lock path
# hardcoded as `.git/<lock>` can never be mkdir'd: ENOTDIR on every retry, then
# a bogus "another /speckit-specify may be running" timeout pointing at a lock
# dir that cannot exist. commit.sh self-heals through branch.sh (R1-S12), so
# EVERY phase-commit hook fails in a worktree.
COMMIT_SH="$GIT_EXT/extension/scripts/commit.sh"
R8="$TMP/u8"; mk_repo "$R8" "080-main-feature"
WT="$TMP/u8-wt"
( cd "$R8" && git worktree add -q -b 081-worktree-feature "$WT" >/dev/null 2>&1 )

# make the worktree a spec-kit target in its own right
mkdir -p "$WT/.specify" "$WT/specs/081-worktree-feature"
printf '{"feature_directory": "specs/081-worktree-feature"}\n' > "$WT/.specify/feature.json"
printf '# spec\n' > "$WT/specs/081-worktree-feature/spec.md"

[ -f "$WT/.git" ] \
  && ok "fixture: the worktree's .git is a FILE (the I-28 precondition holds)" \
  || bad "fixture: worktree .git is not a file — this section is NOT exercising I-28"

# THE regression: the lock must be acquirable where `.git` is not a directory.
if ( cd "$WT" && sh "$BRANCH_SH" >/dev/null 2>&1 ); then
  ok "branch.sh acquires its lock and exits 0 inside a worktree (I-28)"
else
  bad "branch.sh FAILED inside a worktree — the I-28 ENOTDIR lock bug is back"
fi

# and the end-to-end property that actually broke: a phase commit in a worktree.
if ( cd "$WT" && sh "$COMMIT_SH" plan "worktree lock regression" >/dev/null 2>&1 ); then
  if ( cd "$WT" && git log -1 --format=%s | grep -q '^plan(081-worktree-feature): ' ); then
    ok "commit.sh phase-commits inside a worktree (the hook path that failed)"
  else
    bad "commit.sh exited 0 in a worktree but the phase commit is missing/misgrammared"
  fi
else
  bad "commit.sh FAILED inside a worktree — the after_* phase-commit hooks are broken there"
fi

# Design lint: the lock must live in the COMMON git dir, not the worktree's
# private gitdir. The branch namespace is SHARED across worktrees, so two
# worktrees racing ensure_branch must contend on the SAME lock; --git-dir would
# hand each one a private lock and silently defeat the guard. Asserted
# statically (the lock is trap-removed on exit, so it can't be observed after).
if grep -q 'git rev-parse --git-common-dir' "$BRANCH_SH"; then
  ok "branch.sh resolves the lock via --git-common-dir (shared branch namespace)"
else
  bad "branch.sh does not use --git-common-dir — a per-worktree lock defeats the R1-S13 guard"
fi
if grep -qE '^(flock_file|mkdir_lock)="\.git/' "$BRANCH_SH"; then
  bad "branch.sh still hardcodes a .git/ lock path — the I-28 bug"
else
  ok "branch.sh hardcodes no .git/ lock path (I-28 drift lint)"
fi

( cd "$R8" && git worktree remove --force "$WT" >/dev/null 2>&1 ) || true

# ---------------------------------------------------------------------------
bold "Result: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
