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

# ---------------------------------------------------------------------------
section "4. loop-closure (SC-008 — traces carry only approved assemblies)"
run_suite "trace-roster-diff.sh --self-test" sh "$here/trace-roster-diff.sh" --self-test

# ---------------------------------------------------------------------------
printf '\n\033[1mworkforce test/run.sh: %d passed, %d failed\033[0m\n' "$pass" "$fail"
[ "$fail" -eq 0 ] || exit 1
