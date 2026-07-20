#!/bin/sh
# run.sh — the ONE workforce-extension test harness (git-ext model, D57 S3).
#
# Single entry point, clear per-section PASS/FAIL, non-zero exit if ANY section fails:
#   1. install -> reinstall-survival     (S07: seeds + a generated skill survive a reinstall)
#   2. deterministic-assembly golden      (test_assemble.sh — SC-003/004/005/006 + S01/S15)
#   3. validator units                    (test_frontmatter.py, test_categorize.sh, test_skill_builder.sh)
#   4. per-SC loop-closure                (trace-roster-diff.sh — SC-008)
#
# Sub-suites own their frozen fixtures and run standalone (zero-AI, no model). Section 1 uses a
# SCRATCH repo copy under $TMPDIR — the real .specify/ and .claude/ are never touched.

set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo=$(CDPATH= cd -- "$here/../../.." && pwd)      # extensions/workforce/test -> repo root
gitext="$repo/extensions/git/install.sh"
wfext="$repo/extensions/workforce/install.sh"

pass=0; fail=0
ok()  { printf '  \033[32mok  \033[0m %s\n' "$1"; pass=$((pass+1)); }
bad() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; fail=$((fail+1)); }
section() { printf '\n\033[1m%s\033[0m\n' "$1"; }

run_suite() {   # <label> <command...>
    label="$1"; shift
    if "$@" >/dev/null 2>&1; then ok "$label"; else bad "$label (see: $*)"; fi
}

# ---------------------------------------------------------------------------
section "1. install -> reinstall-survival (S07 — the flywheel/seed library is user data)"
TMP=$(mktemp -d "${TMPDIR:-/tmp}/wf-run.XXXXXX")
trap 'rm -rf "$TMP" 2>/dev/null || true' EXIT
W="$TMP/repo"
mkdir -p "$W"
( cd "$W" && git init -q && git config user.email t@t && git config user.name t \
    && mkdir -p .specify specs \
    && printf '{"feature_directory":"specs/999-fixture"}\n' > .specify/feature.json \
    && printf 'installed: []\nhooks: {}\n' > .specify/extensions.yml \
    && mkdir -p specs/999-fixture && printf '# f\n' > specs/999-fixture/spec.md \
    && git add -A && git commit -qm init )

# install git (order: git before workforce) then workforce, into the scratch repo
if sh "$gitext" "$W" >/dev/null 2>&1 && sh "$wfext" "$W" >/dev/null 2>&1; then
    ok "git + workforce install into a fresh repo"
else
    bad "install failed"
fi

n_agents=$(find "$W/.claude/agents" -name 'agt_*.md' 2>/dev/null | wc -l | tr -d ' ')
n_skills=$(find "$W/.claude/skills" -maxdepth 2 -name 'SKILL.md' 2>/dev/null | wc -l | tr -d ' ')
[ "$n_agents" = "7" ] && ok "7 seed bases seeded (.claude/agents/agt_*.md)" || bad "expected 7 seed bases, found $n_agents"
[ "$n_skills" -ge "5" ] && ok "5+ seed skills seeded (.claude/skills/*/SKILL.md), found $n_skills" || bad "expected >=5 seed skills, found $n_skills"
grep -q "after_categorize" "$W/.specify/extensions.yml" && ok "after_categorize hook registered" || bad "after_categorize hook missing"

# plant flywheel data: a hand-edited seed + a generated skill (both user data, must survive)
echo "# HAND EDIT" >> "$W/.claude/agents/agt_generic.md"
mkdir -p "$W/.claude/skills/planted-generated"
printf -- '---\nspecseyal:\n  kind: skill\n  id: skl_planted\n  origin: generated\n---\nplanted\n' > "$W/.claude/skills/planted-generated/SKILL.md"
plant_sum=$(shasum "$W/.claude/agents/agt_generic.md" | cut -d' ' -f1)

# reinstall workforce (self) + graphify (foreign) — the reinstall-survival hazard (S07/I-14)
sh "$wfext" "$W" >/dev/null 2>&1 || true
sh "$repo/extensions/graphify/install.sh" "$W" >/dev/null 2>&1 || true
sh "$wfext" "$W" >/dev/null 2>&1 || true

[ -f "$W/.claude/skills/planted-generated/SKILL.md" ] && ok "generated skill SURVIVED self+foreign reinstall (S07)" || bad "generated skill CLOBBERED by reinstall (S07 violated)"
[ "$(shasum "$W/.claude/agents/agt_generic.md" | cut -d' ' -f1)" = "$plant_sum" ] && ok "hand-edited seed base SURVIVED reinstall byte-for-byte (S07)" || bad "hand-edited seed base was overwritten by reinstall (S07 violated)"
grep -q "after_agent-assign" "$W/.specify/extensions.yml" && ok "hooks still registered after reinstall" || bad "hooks lost after reinstall"

# ---------------------------------------------------------------------------
section "2. deterministic-assembly golden (SC-003/004/005/006, S01/S15)"
run_suite "test_assemble.sh" sh "$here/test_assemble.sh"

# ---------------------------------------------------------------------------
section "3. validator units (frontmatter parser + categorization + skill validators)"
run_suite "test_frontmatter.py (S21 shared parser)" python3 "$here/test_frontmatter.py"
run_suite "test_categorize.sh (SC-001/002, S22 no-write)" sh "$here/test_categorize.sh"
run_suite "test_skill_builder.sh (FR-007/S9, SC-007/S04, grant-disjoint)" sh "$here/test_skill_builder.sh"
run_suite "test_profile.sh (SC-008/009/010, FR-018 enum-equiv, R1-S09/S10/S18)" sh "$here/test_profile.sh"

# ---------------------------------------------------------------------------
section "4. loop-closure (SC-008 — traces carry only approved assemblies)"
run_suite "trace-roster-diff.sh --self-test" sh "$here/trace-roster-diff.sh" --self-test

# ===========================================================================
# 5. FR-015 branch-scope allowlist guard — begin (T002, 008-pre-public-maintenance)
# ===========================================================================
section "5. FR-015 branch-scope allowlist guard (no stray path outside this feature's declared allowlist)"
# Mechanically enforces FR-015, this feature's load-bearing scope invariant:
# no path in this branch's diff against base_branch may fall outside the
# feature's declared allowlist. A stray edit to any gate-schema or
# gate-semantics file must break this suite, naming the offending path.
# Folded into THIS file rather than a new one: a new file would itself fall
# outside the allowlist it defines and would self-fail.

# fr015_path_allowed <path> — true iff <path> is inside the FR-015 allowlist.
# The allowlist is a UNION of two categories, and the distinction matters:
fr015_path_allowed() {
  case "$1" in
    # -- declared FR-015 implementation edit sites (13) --
    bootstrap.sh) return 0 ;;
    extensions/workforce/extension/scripts/check-conformance.py) return 0 ;;
    specs/008-pre-public-maintenance/fixtures/*) return 0 ;;
    extensions/git/install.sh) return 0 ;;
    extensions/git/test/run.sh) return 0 ;;
    extensions/graphify/extension/scripts/augment_merge.py) return 0 ;;
    extensions/graphify/test/run.sh) return 0 ;;
    extensions/council/skills/speckit-council/SKILL.md) return 0 ;;
    extensions/council/skills/speckit-council-triage/SKILL.md) return 0 ;;
    extensions/graphify/skills/speckit-implement-parallel/SKILL.md) return 0 ;;
    extensions/workforce/test/run.sh) return 0 ;;
    README.md) return 0 ;;
    docs/90-DECISIONS-AND-IDEAS.md) return 0 ;;
  esac
  case "$1" in
    # -- pipeline OUTPUT, not source edits (see note below) --
    # FR-015 asserts SOURCE non-interference: that no gate-schema or
    # gate-semantics file changed. The SDD pipeline itself writes tasks.md,
    # traces.jsonl, implement.log.md, gates.yml, council/, and
    # completion-report.md into the feature's own directory on every phase,
    # and /speckit-agent-assign persists generated skills into
    # .claude/skills/. Those are pipeline OUTPUT, not source edits, and they
    # appear in the branch diff unavoidably. A guard that flagged them would
    # fail on its own run and prove nothing — exempting them (and ONLY
    # them) is what lets the guard keep its teeth everywhere FR-015
    # actually points.
    specs/008-pre-public-maintenance/*) return 0 ;;   # the feature's own SDD artifacts
    .claude/skills/*) return 0 ;;                      # workforce-persisted generated skills
  esac
  return 1
}

gitcfg="$repo/.specify/extensions/git/git-config.yml"
base_branch=$(awk '/^base_branch:/ { print $2; exit }' "$gitcfg" 2>/dev/null || true)

if [ -z "${base_branch:-}" ]; then
  bad "FR-015 allowlist guard: could not resolve base_branch from $gitcfg"
elif merge_base=$(cd "$repo" && git merge-base "$base_branch" HEAD 2>/dev/null); then
  branch_diff=$(cd "$repo" && git diff --name-only "$merge_base"..HEAD)
  n_checked=0; stray_count=0
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    n_checked=$((n_checked+1))
    if ! fr015_path_allowed "$p"; then
      bad "stray path outside FR-015 allowlist: $p"
      stray_count=$((stray_count+1))
    fi
  done <<FR015_DIFF
$branch_diff
FR015_DIFF
  [ "$stray_count" -eq 0 ] && ok "FR-015 branch-scope allowlist guard ($n_checked branch-diff path(s), all inside the declared allowlist)"
else
  bad "FR-015 allowlist guard: could not compute merge-base($base_branch, HEAD)"
fi
# ===========================================================================
# 5. FR-015 branch-scope allowlist guard — end (T011 appends AFTER this line)
# ===========================================================================

# ===========================================================================
# 6-10. check-conformance.py wiring (T011, 008-pre-public-maintenance)
# ===========================================================================
# The both-branch fixture invocation (FR-009), the standing golden PASS
# assertion (C4/FR-006/SC-004), the static no-import guard (R1-S22), the
# double-run determinism check (R1-S21/SC-005), and --self-test (C9) for
# extensions/workforce/extension/scripts/check-conformance.py.

checker="$repo/extensions/workforce/extension/scripts/check-conformance.py"
fixtures="$repo/specs/008-pre-public-maintenance/fixtures"

# assert_conformant <fixture-name> -- checker must exit 0 against
# fixtures/<fixture-name>/.
assert_conformant() {
    fixture="$1"
    if python3 "$checker" "$fixtures/$fixture" >/dev/null 2>&1; then
        ok "fixtures/$fixture -> exit 0 (CONFORMANT)"
    else
        bad "fixtures/$fixture -> expected exit 0 (CONFORMANT)"
    fi
}

# assert_violation <fixture-name> <expected-message>... -- checker must exit
# non-zero against fixtures/<fixture-name>/, AND every <expected-message>
# given (there may be more than one -- violation-bad-trace-line/ carries two
# independently-named cases) must appear verbatim on stderr. Matched against
# the exact "Expected checker message" each fixture's own VIOLATION.md pins,
# not merely the exit code -- an exit-code-only assertion would pass even if
# the checker named the wrong rule.
assert_violation() {
    fixture="$1"; shift
    rc=0
    stderr_out=$(python3 "$checker" "$fixtures/$fixture" 2>&1 1>/dev/null) || rc=$?
    if [ "$rc" -eq 0 ]; then
        bad "fixtures/$fixture -> expected non-zero exit, got 0"
        return
    fi
    missing=0
    for expected in "$@"; do
        case "$stderr_out" in
            *"$expected"*) : ;;
            *) missing=$((missing+1)); bad "fixtures/$fixture: expected message not found on stderr: $expected" ;;
        esac
    done
    [ "$missing" -eq 0 ] && ok "fixtures/$fixture -> exit $rc, names its cause ($# expected message(s) matched verbatim)"
}

# ---------------------------------------------------------------------------
section "6. check-conformance.py both-branch fixture assertions (FR-009 -- conformant/ PASSES, each violation-*/ FAILS naming its cause)"

assert_conformant "conformant"

assert_violation "violation-wrong-path" \
  "council/defense-deck/technical.md · artifact-layout.md §1: required artifact not found at its layout path (found instead at council/technical.md, missing the defense-deck/ subdirectory)"

assert_violation "violation-missing-section" \
  "council/decision-record.md · decision-record.md §5: required section '## Carried Constraints' is missing (cardinality 1, last, required — may be empty but never absent)"

assert_violation "violation-bad-frontmatter" \
  "completion-report.md · completion-report.md §6 rule 1: frontmatter 'status' = 'done' is not one of {success, partial, failed}"

assert_violation "violation-coverage-gap" \
  "testing.md · testing-doc.md §6 rule 3: 'FR-002' appears in spec.md but has no '## Coverage map' row (bijection broken)"

assert_violation "violation-bad-trace-line" \
  "traces.jsonl:1 · trace-schema.md §7 rule 4: role 'orchestrator' record carries non-null agent_id (agent_id != null must imply role == \"implementer\")" \
  "traces.jsonl:12 (I-31 pinning case) · hardening-invariants.md H4.1: artifact 'specs/008-pre-public-maintenance/fixtures/violation-bad-trace-line/renders/technical.pptx' is a gitignored path — a task whose sole output is gitignored/untracked must record artifact: null"

assert_violation "violation-assembly-cap-exceeded" \
  "agents/assignment.md · agent-library-schema.md §3 (D40 Guardrails): assembled agent for T001 carries 4 injected skills, exceeding the assembly cap of 3"

# ---------------------------------------------------------------------------
section "7. check-conformance.py static no-import guard (R1-S22 -- shells out to the sibling validators, never imports them)"
# FR-008/C2 requires check-conformance.py to DELEGATE to validate-profile.py /
# validate-categorization.py / validate-skill.py by subprocess shell-out only,
# never by a source-level `import` -- see this file's own module docstring
# ("Delegation, not duplication"). A static grep over the SOURCE, not a
# runtime check: turns a silent future regression (someone "helpfully"
# importing a sibling validator's function instead of shelling out to it)
# into a caught build failure, per FR-008's composition-not-duplication
# property.
if grep -nE '^[[:space:]]*(import|from)[[:space:]]+.*validate[_-]?(profile|categorization|skill)' "$checker" >/dev/null 2>&1; then
    bad "check-conformance.py source-level imports a sibling validator (must shell out only -- R1-S22/FR-008)"
else
    ok "check-conformance.py has no source-level import of validate-{profile,categorization,skill}.py (R1-S22 -- subprocess shell-out only)"
fi

# ---------------------------------------------------------------------------
section "8. check-conformance.py double-run byte-diff determinism (R1-S21/SC-005/C6 -- same input -> byte-identical output)"
# Replaces a manual re-run-and-eyeball step with a code-verified assertion.
# violation-assembly-cap-exceeded/ is used rather than conformant/ because it
# actually exercises real finding-rendering output (conformant/ prints one
# short OK line and would barely exercise render_lines()'s sort-before-print
# discipline at all).
det_fixture="$fixtures/violation-assembly-cap-exceeded"
det_rc1=0
python3 "$checker" "$det_fixture" >"$TMP/detrun1.out" 2>"$TMP/detrun1.err" || det_rc1=$?
det_rc2=0
python3 "$checker" "$det_fixture" >"$TMP/detrun2.out" 2>"$TMP/detrun2.err" || det_rc2=$?
if [ "$det_rc1" -eq "$det_rc2" ] && cmp -s "$TMP/detrun1.out" "$TMP/detrun2.out" && cmp -s "$TMP/detrun1.err" "$TMP/detrun2.err"; then
    ok "check-conformance.py double-run is byte-identical (stdout, stderr, exit code) on the same input"
else
    bad "check-conformance.py double-run diverged between runs (non-determinism -- R1-S21/SC-005 violated)"
fi

# ---------------------------------------------------------------------------
section "9. standing golden PASS assertion (C4/FR-006/SC-004)"
#
# conformance-checker-command.md's C4 and this feature's FR-006/SC-004 both
# name specs/000-sample/ as the standing CI golden the checker must pass
# ("PASSES specs/000-sample -- artifact-layout §7's 'any conformance checker
# built later must pass it' made real"). specs/000-sample/ is M0-era and
# predates D72, D77, and the M4 shapes of completion-report.md and
# testing-doc.md (docs/90-DECISIONS-AND-IDEAS.md) -- run against
# check-conformance.py as it stands today, it is NONCONFORMANT on 12 separate
# counts (categorization.md table shape, completion-report.md frontmatter +
# two core sections, testing.md frontmatter + two required sections + an
# appendix-heading breach, and four traces.jsonl role-field breaches). This
# was discovered during T011 implementation, not assumed, and was
# adjudicated by a human rather than resolved unilaterally here.
#
# The approved resolution: pin THIS standing PASS assertion against
# specs/008-pre-public-maintenance/fixtures/conformant/ instead of
# specs/000-sample/. fixtures/conformant/ was authored against the CURRENT
# docs/contracts/*.md shapes (see fixtures/README.md) and is independently
# verified passing (section 6, above). specs/000-sample/'s staleness is
# recorded here as a tracked follow-up (bring the M0 fixture up to the M4
# contract shapes, or grant it a documented carve-out) -- it is NOT silently
# patched to make this line green, and this harness deliberately does NOT
# assert that specs/000-sample fails either: doing so would pin its current
# brokenness as expected behaviour, which is not the intent. specs/000-sample/
# itself is untouched by this feature (outside the FR-015 scope allowlist,
# section 5 above) and is not read by this harness at all.
#
run_suite "standing golden PASS: fixtures/conformant/ (substituting for stale specs/000-sample -- see comment above)" \
    python3 "$checker" "$fixtures/conformant"

# ---------------------------------------------------------------------------
section "10. check-conformance.py --self-test (C9 -- catches docs/contracts/*.md drifting out from under its only enforcer)"
run_suite "check-conformance.py --self-test (89 contract-coupling assertions vs docs/contracts/*.md, exit 0)" \
    python3 "$checker" --self-test

# ---------------------------------------------------------------------------
printf '\n\033[1mworkforce test/run.sh: %d passed, %d failed\033[0m\n' "$pass" "$fail"
[ "$fail" -eq 0 ] || exit 1
