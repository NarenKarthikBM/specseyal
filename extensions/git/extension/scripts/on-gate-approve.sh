#!/bin/sh
# on-gate-approve.sh -- the after_council_approve / after_workforce_approve
# hook action. Gate-agnostic (S02/R8): takes ONE argument, the gate that
# fired it, and dispatches to that gate's binding write.
#
# Wired declaratively in extension.yml, once per gate, both hooks pointing
# at this same file with a different gate literal appended:
#   after_council_approve:
#     command: speckit.git.record-gate   # hook-internal action -> this file
#     gate: council
#   after_workforce_approve:
#     command: speckit.git.record-gate   # hook-internal action -> this file
#     gate: workforce
# This is a hook-internal ACTION, not a reusable primitive: nothing else
# ever calls it, so it is deliberately absent from extension.yml's
# `provides.commands` list. `gate: council` / `gate: workforce` in the
# manifest is declarative metadata for a future generic dispatcher (M6 --
# no HookExecutor exists in v1, enforcement is prose-level, R1-S08/D53);
# in v1 the invoking phase-skill reads its own manifest entry's `gate:`
# value and passes it as this script's $1 -- see "Usage" below. This
# script used to be two council-hardcoded scripts' worth of intent
# bundled into one (on-council-approve.sh, whose header said the
# workforce equivalent was "still M3 future work"); this IS that
# generalization (S02/R8, specs/003-workforce/research.md #R8) -- a
# rename+parameterize of git-ext's own source (D57 S2), not a new
# script and not a copy: on-council-approve.sh no longer exists.
#
# Fires once an approval exists for the current feature's gated
# artifact(s) -- plan.md (council) or tasks.md + assignment.md
# (workforce) (specs/002-speckit-ext-git/contracts/commands.md,
# "Gate-command integration points" -> "Council approve ->
# after_council_approve hook"; specs/003-workforce/contracts/commands.md,
# "/speckit-workforce-approve" -> "after_workforce_approve"). Its entire
# job is to record the GateSHABinding (specs/002-speckit-ext-git/
# data-model.md #GateSHABinding) for whichever gate fired it, by
# composing the sibling gates.sh primitive with that gate as its
# argument:
#
#   gates.sh write <gate>          # <gate> = $1, "council" or "workforce"
#
# gates.sh (git-ext-owned, sole owner of gates.yml -- R1-S09/S20) already
# knows both gates' default artifact sets (council -> plan.md; workforce
# -> tasks.md + assignment.md -- contracts/commands.md), resolves the
# spec ID, resolves each artifact's current SHA via sha.sh, and
# (re)writes that gate's block of specs/<spec-id>/gates.yml wholesale,
# preserving the OTHER gate's block verbatim. THAT is the authoritative
# binding. This script adds no logic of its own beyond validating $1 and
# triggering that write at the right event: it never re-implements any
# part of gates.sh's job, and never parses decision-record.md or
# assignment.md to "check" the approval first -- the after_council_approve
# / after_workforce_approve event firing at all already means an approval
# exists; trusting that event is what keeps this script mechanical
# instead of growing a second opinion about another extension's artifact.
#
# ---------------------------------------------------------------------
# Reinstall-surviving (R1-S04).
# ---------------------------------------------------------------------
# This file lives inside the GIT extension's own scripts/ directory, not
# inside the council or workforce extension, and is wired to the
# after_council_approve / after_workforce_approve events purely via
# extension.yml's hook declarations. It is NOT a patch to
# .claude/skills/speckit-council-approve/SKILL.md,
# .claude/skills/speckit-workforce-approve/SKILL.md (or any other file
# the council or workforce extension owns): each of those extensions'
# install.sh does `rm -rf` + `cp -R` of its own installed tree on every
# (re)install, which would silently wipe any edit parked inside their
# source -- and editing another extension's owned file is an ownership
# violation on its own terms regardless of whether it survives. Because
# this action lives entirely under extensions/git/ and is reached
# declaratively rather than by patching either gate extension's skill
# body, reinstalling any of the three extensions leaves the binding
# behavior intact for BOTH gates as long as git's own extension.yml (and
# this script) are reinstalled too -- which is exactly what git's own
# install.sh does.
#
# ---------------------------------------------------------------------
# PRINCIPLE I -- writes ONLY gates.yml, never decision-record.md or
# assignment.md.
# ---------------------------------------------------------------------
# decision-record.md is council-owned end to end (docs/contracts/
# artifact-layout.md #6 Ownership: "Council extension | everything under
# council/"), and its "## Human Gate" section specifically is attributed
# to the human/auto-approval step itself (artifact-layout.md #2 phase
# table: "council-gate | human | ... | decision-record.md gate
# section"). Likewise, agents/assignment.md is workforce-owned end to
# end, and its "## Workforce Gate" section is attributed to
# /speckit-workforce-approve (specs/003-workforce/contracts/
# commands.md). Neither artifact belongs to this extension. The
# GateSHABinding's real home is the git-ext-owned
# specs/<spec-id>/gates.yml (data-model.md #GateSHABinding -- "owner
# ruling, R1-S09/S20 -- supersedes the earlier 'inside the gate section'
# design, which co-wrote another command's artifact"): that ruling exists
# precisely so neither gate artifact ever gets a second writer. FR-008's
# requirement that "the gate section carries a one-line reference to
# gates.yml" is satisfied BY CONVENTION for both gates -- gates.yml
# always lives at the well-known path specs/<spec-id>/gates.yml, so any
# reader of ## Human Gate or ## Workforce Gate already knows where to
# look without this script (or any git-ext script) ever touching
# decision-record.md's or assignment.md's bytes. This script must NEVER
# be "improved" to append or edit either reference itself -- doing so
# would recreate the exact second-writer problem R1-S09/S20 dissolved.
#
# ---------------------------------------------------------------------
# Signer-agnostic (FR-010/W4).
# ---------------------------------------------------------------------
# FR-010: a GateSHABinding must be recorded regardless of who signs -- a
# human running /speckit-council-approve or /speckit-workforce-approve,
# or an auto-mode gate write under gates.council.mode: auto (D9/D33) or
# gates.workforce.mode: auto (FR-020/W4) -- both legal only within a
# full_auto profile. This script has no notion of "human" vs. "auto" at
# all, for either gate: it keys off the approval EVENT (a fresh approval
# now exists for the gate named in $1), not off any human-specific step,
# and performs the identical gates.sh write either way -- there is no
# signer-specific branch to find here because none exists. Making both
# paths actually reach this action is a manifest-wiring concern, not this
# script's: extension.yml's after_council_approve / after_workforce_approve
# entries already document that intent ("must also fire on an
# auto-written gate"), and it is the invoker's/manifest's job to also
# trigger this same action from each auto-write path (i.e. when
# speckit-council-triage or the workforce assigner writes the gate
# section directly under full_auto, with no separate human `approve`
# event). This comment exists so whoever wires either auto path knows
# this script is already ready for it as-is -- nothing here needs to
# change to support it.
#
# ---------------------------------------------------------------------
# Idempotent.
# ---------------------------------------------------------------------
# Re-running this script for a given gate (a re-approval, or the hook
# firing more than once) re-records the same binding without corruption:
# `gates.sh write <gate>` already replaces that gate's block of
# gates.yml wholesale rather than appending, and always preserves the
# other gate's block verbatim, so repeated runs -- of either gate,
# independently -- converge on one binding per artifact, never a
# duplicate and never a cross-gate clobber.
#
# Mechanical only: no model call, no traces.jsonl write (FR-007) -- ever.
#
# Spec ID resolution (D45 -- .specify/feature.json is the sole spec-ID
# resolver, same rule branch.sh/commit.sh/gates.sh all use): basename of
# feature.json's "feature_directory". Resolved independently here (never
# passed as an argument, never read back out of gates.sh) purely to fail
# fast with a clear message and to label this script's own log line --
# gates.sh resolves it again internally regardless, the same "never
# trust a caller's copy" idiom every sibling script in this extension
# already follows.
#
# Usage:
#   on-gate-approve.sh <council|workforce>
#       <gate> selects which binding to (re)write. The spec ID still
#       comes from feature.json (D45), exactly like branch.sh -- the
#       gate name is the only thing this script ever takes as an
#       argument.

set -eu

die() {
    printf 'on-gate-approve.sh: error: %s\n' "$1" >&2
    exit 1
}

usage() {
    printf 'usage: on-gate-approve.sh <council|workforce>\n' >&2
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
    *) die "unknown gate '$gate' (expected 'council' or 'workforce') -- fail-closed, this hook-internal action only ever fires for one of the two registered gates" ;;
esac

# ---------------------------------------------------------------------------
# Locate the sibling gates.sh regardless of the caller's CWD or how this
# script itself was invoked (relative, ./-relative, or absolute) -- same
# resolution style as commit.sh's own script_dir lookup for branch.sh.
# ---------------------------------------------------------------------------

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd) || die "cannot resolve on-gate-approve.sh's own directory from \$0 ($0)"
gates_script="$script_dir/gates.sh"
[ -f "$gates_script" ] || die "sibling gates.sh not found at $gates_script -- on-gate-approve.sh composes gates.sh for the actual gates.yml write"

# ---------------------------------------------------------------------------
# Repo root (match branch.sh/commit.sh/gates.sh's own style).
# ---------------------------------------------------------------------------

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || die "not inside a git repository"
cd "$repo_root"

# ---------------------------------------------------------------------------
# Spec ID (D45: feature.json is the sole resolver -- read independently
# here purely for a clear log line and a fast, specific failure; gates.sh
# re-resolves it internally regardless, so nothing found here is ever
# passed to it).
# ---------------------------------------------------------------------------

feature_json=".specify/feature.json"
[ -f "$feature_json" ] || die "$feature_json not found -- run /speckit-specify first"

feature_directory=$(grep '"feature_directory"' "$feature_json" 2>/dev/null \
    | head -n 1 \
    | sed -E 's/.*"feature_directory"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')

[ -n "$feature_directory" ] || die "could not read \"feature_directory\" from $feature_json"

spec_id=$(basename "$feature_directory")

# ---------------------------------------------------------------------------
# The action itself: delegate to `gates.sh write <gate>` (defaults per
# gate -- council: plan.md; workforce: tasks.md + assignment.md --
# contracts/commands.md). gates.sh does everything else: resolves the
# SHA via sha.sh, validates each artifact exists, and (re)writes that
# gate's block of gates.yml. No decision-record.md or assignment.md
# bytes are ever touched here (PRINCIPLE I, above).
# ---------------------------------------------------------------------------

printf 'on-gate-approve.sh: recording %s gate binding for %s\n' "$gate" "$spec_id" >&2

sh "$gates_script" write "$gate"
