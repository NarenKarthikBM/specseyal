#!/bin/sh
# on-council-approve.sh -- the after_council_approve hook action.
#
# Wired declaratively in extension.yml:
#   after_council_approve:
#     command: speckit.git.record-gate   # hook-internal action -> this file
#     gate: council
# This is a hook-internal ACTION, not a reusable primitive: nothing else
# ever calls it, so it is deliberately absent from extension.yml's
# `provides.commands` list. `gate: council` in the manifest is declarative
# metadata for a future generic dispatcher (M6 — no HookExecutor exists in
# v1, enforcement is prose-level, R1-S08/D53); this script does not read
# it as an argument -- it is hardcoded to the council gate because this
# hook only ever fires for the council gate (see extension.yml's other
# hooks for the workforce-gate equivalent, still M3 future work).
#
# Fires once a council approval exists for the current feature's plan.md
# (specs/002-speckit-ext-git/contracts/commands.md, "Gate-command
# integration points" -> "Council approve -> after_council_approve hook").
# Its entire job is to record the GateSHABinding
# (specs/002-speckit-ext-git/data-model.md #GateSHABinding) for the
# council gate by composing the sibling gates.sh primitive:
#
#   gates.sh write council
#
# gates.sh (git-ext-owned, sole owner of gates.yml -- R1-S09/S20) resolves
# the spec ID, resolves plan.md's current SHA via sha.sh, and (re)writes
# the "council:" block of specs/<spec-id>/gates.yml wholesale. THAT is the
# authoritative binding. This script adds no logic of its own beyond
# triggering that write at the right event: it never re-implements any
# part of gates.sh's job, and never parses decision-record.md to "check"
# the approval first -- the after_council_approve event firing at all
# already means an approval exists; trusting that event is what keeps
# this script mechanical instead of growing a second opinion about
# council's own artifact.
#
# ---------------------------------------------------------------------
# Reinstall-surviving (R1-S04).
# ---------------------------------------------------------------------
# This file lives inside the GIT extension's own scripts/ directory, not
# inside the council extension, and is wired to the after_council_approve
# event purely via extension.yml's hook declaration. It is NOT a patch to
# .claude/skills/speckit-council-approve/SKILL.md (or any other file the
# council extension owns): council's install.sh does `rm -rf` + `cp -R`
# of its own installed tree on every (re)install, which would silently
# wipe any edit parked inside speckit-council-approve's source -- and
# editing another extension's owned file is an ownership violation on its
# own terms regardless of whether it survives. Because this action lives
# entirely under extensions/git/ and is reached declaratively rather than
# by patching council's skill body, reinstalling either extension leaves
# the binding behavior intact as long as git's own extension.yml (and
# this script) are reinstalled too -- which is exactly what git's own
# install.sh does.
#
# ---------------------------------------------------------------------
# PRINCIPLE I -- writes ONLY gates.yml, never council/decision-record.md.
# ---------------------------------------------------------------------
# decision-record.md is council-owned end to end
# (docs/contracts/artifact-layout.md #6 Ownership: "Council extension |
# everything under council/"), and its "## Human Gate" section
# specifically is attributed to the human/auto-approval step itself
# (artifact-layout.md #2 phase table: "council-gate | human | ... |
# decision-record.md gate section"), not to this extension. The
# GateSHABinding's real home is the git-ext-owned
# specs/<spec-id>/gates.yml (data-model.md #GateSHABinding -- "owner
# ruling, R1-S09/S20 -- supersedes the earlier 'inside the gate section'
# design, which co-wrote another command's artifact"): that ruling exists
# precisely so a council artifact never gets a second writer. FR-008's
# requirement that "the gate section carries a one-line reference to
# gates.yml" is satisfied BY CONVENTION -- gates.yml always lives at the
# well-known path specs/<spec-id>/gates.yml, so any reader of ## Human
# Gate already knows where to look without this script (or any git-ext
# script) ever touching decision-record.md's bytes. This script must
# NEVER be "improved" to append or edit that reference itself -- doing so
# would recreate the exact second-writer problem R1-S09/S20 dissolved.
#
# ---------------------------------------------------------------------
# Signer-agnostic (FR-010).
# ---------------------------------------------------------------------
# FR-010: a GateSHABinding must be recorded regardless of who signs -- a
# human running /speckit-council-approve, or an auto-mode gate write
# under gates.council.mode: auto (D9/D33, legal only within a full_auto
# profile). This script has no notion of "human" vs. "auto" at all: it
# keys off the approval EVENT (a fresh council approval now exists for
# plan.md), not off any human-specific step, and performs the identical
# gates.sh write either way -- there is no signer-specific branch to find
# here because none exists. Making both paths actually reach this action
# is a manifest-wiring concern, not this script's: extension.yml's
# after_council_approve entry already documents that intent ("must also
# fire on an auto-written gate"), and it is the invoker's/manifest's job
# to also trigger this same action from the auto-write path (i.e. when
# speckit-council-triage writes the gate section directly under
# full_auto, with no separate human `approve` event). This comment exists
# so whoever wires that auto path knows this script is already ready for
# it as-is -- nothing here needs to change to support it.
#
# ---------------------------------------------------------------------
# Idempotent.
# ---------------------------------------------------------------------
# Re-running this script (a re-approval, or the hook firing more than
# once) re-records the same binding without corruption: `gates.sh write`
# already replaces the "council:" block of gates.yml wholesale rather
# than appending, so repeated runs converge on one binding per artifact,
# never a duplicate.
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
#   on-council-approve.sh          (no arguments -- everything comes from
#                                    feature.json, exactly like branch.sh)

set -eu

die() {
    printf 'on-council-approve.sh: error: %s\n' "$1" >&2
    exit 1
}

usage() {
    printf 'usage: on-council-approve.sh\n' >&2
}

case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
esac

[ "$#" -eq 0 ] || die "takes no arguments (spec ID comes from .specify/feature.json; this action is hardcoded to the council gate)"

# ---------------------------------------------------------------------------
# Locate the sibling gates.sh regardless of the caller's CWD or how this
# script itself was invoked (relative, ./-relative, or absolute) -- same
# resolution style as commit.sh's own script_dir lookup for branch.sh.
# ---------------------------------------------------------------------------

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd) || die "cannot resolve on-council-approve.sh's own directory from \$0 ($0)"
gates_script="$script_dir/gates.sh"
[ -f "$gates_script" ] || die "sibling gates.sh not found at $gates_script -- on-council-approve.sh composes gates.sh for the actual gates.yml write"

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
# The action itself: delegate to `gates.sh write council` (defaults to
# plan.md -- contracts/commands.md: "council gate binds plan.md @
# <sha>"). gates.sh does everything else: resolves the SHA via sha.sh,
# validates plan.md exists, and (re)writes gates.yml's "council:" block.
# No decision-record.md path is ever touched here (PRINCIPLE I, above).
# ---------------------------------------------------------------------------

printf 'on-council-approve.sh: recording council gate binding for %s\n' "$spec_id" >&2

sh "$gates_script" write council
