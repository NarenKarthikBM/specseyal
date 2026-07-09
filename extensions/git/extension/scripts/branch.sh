#!/bin/sh
# branch.sh — ensure-branch-from-spec-id (FR-001, FR-002, FR-012).
#
# Called with no arguments from the `after_specify` hook, ahead of
# `commit.sh spec "…"` (contracts/commands.md, after_specify row): ensures
# the feature branch exists, named exactly the spec ID, and switches onto
# it. Idempotent — safe to re-run. Mechanical git only: no model call, no
# traces.jsonl write (FR-007).
#
# Spec ID resolution (D45 — .specify/feature.json is the sole spec-ID
# resolver): basename of feature.json's "feature_directory". This script
# never recomputes NNN+slug itself, so it can't drift from what
# /speckit-specify actually created (README.md).
#
# Usage:
#   branch.sh          (no arguments — everything comes from feature.json)
#
# Behavior:
#   1. Validate the spec ID against branch.pattern (FR-002; both the
#      default NNN-slug form and the timestamp form added at triage for
#      feature_numbering: timestamp, R1-S25 — transcribed verbatim from
#      ../git-config.yml's branch.pattern.default / .timestamp).
#   2. Idempotent ensure (FR-012): branch already exists -> switch, no
#      error, no duplicate. Branch absent -> `git checkout -b`, carrying
#      the current (uncommitted) working tree onto it — this is how
#      spec.md lands on the feature branch rather than on base_branch.
#   3. Concurrency guard + collision guard (R1-S13 / Risk R3): the ensure
#      in step 2 runs inside a lock (flock(1) if present, else a portable
#      mkdir-as-mutex — see run_locked() below) so concurrent
#      /speckit-specify runs serialize; and a branch sharing this spec
#      ID's NNN prefix but a DIFFERENT slug is a loud-fail, not a silent
#      create, since it signals an upstream numbering race that would
#      otherwise strand two features' commits under one prefix.

set -eu

die() {
    printf 'branch.sh: error: %s\n' "$1" >&2
    exit 1
}

[ "$#" -eq 0 ] || die "usage: branch.sh takes no arguments (spec ID comes from .specify/feature.json)"

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

# basename only — never recompute NNN+slug ourselves (D45/FR-013: the
# resolver is feature.json, not the branch name).
spec_id=$(basename "$feature_directory")

# ---------------------------------------------------------------------------
# FR-002: branch name == spec ID, validated against branch.pattern. Both
# forms transcribed verbatim from ../git-config.yml (branch.pattern.default
# / .timestamp, R1-S25) rather than parsed at runtime — this is a
# structural identity format, not an operational knob like base_branch.
# LC_ALL=C keeps [a-z0-9] deterministic regardless of the caller's locale.
# ---------------------------------------------------------------------------

pattern_default='^[0-9]{3}-[a-z0-9]+(-[a-z0-9]+)*$'
pattern_timestamp='^[0-9]{8}-[0-9]{6}-[a-z0-9]+(-[a-z0-9]+)*$'

if printf '%s\n' "$spec_id" | LC_ALL=C grep -Eq "$pattern_timestamp"; then
    spec_prefix=$(printf '%s' "$spec_id" | cut -c1-15)   # YYYYMMDD-HHMMSS
elif printf '%s\n' "$spec_id" | LC_ALL=C grep -Eq "$pattern_default"; then
    spec_prefix=$(printf '%s' "$spec_id" | cut -c1-3)    # NNN
else
    die "spec ID '$spec_id' (from $feature_json) matches neither branch.pattern.default nor .timestamp — refusing to touch git"
fi

# ---------------------------------------------------------------------------
# The ensure itself. Must run inside the lock acquired by run_locked() below.
# ---------------------------------------------------------------------------

ensure_branch() {
    if git show-ref --verify --quiet "refs/heads/$spec_id"; then
        # FR-012 idempotent path: this spec ID already has its branch.
        # Switch, don't duplicate, and don't treat "already exists" as an
        # error.
        current_branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) || current_branch=""
        if [ "$current_branch" = "$spec_id" ]; then
            printf 'branch.sh: already on "%s"\n' "$spec_id"
        else
            printf 'branch.sh: switching to existing feature branch "%s"\n' "$spec_id"
            git checkout "$spec_id" || die "could not switch to existing branch '$spec_id' (uncommitted changes conflicting with it?)"
        fi
        return 0
    fi

    # R1-S13/Risk R3: a branch sharing our NNN (or YYYYMMDD-HHMMSS) prefix
    # under a DIFFERENT slug means an earlier/concurrent /speckit-specify
    # run already claimed this prefix for another feature (e.g. a
    # create-new-feature.sh numbering race). A same-slug match can't reach
    # here (that's the idempotent branch above), so any hit below is a
    # genuine collision: create-if-absent would otherwise silently strand
    # two features' commits under one prefix. Loud-fail instead of guessing.
    collision=$(git for-each-ref --format='%(refname:short)' "refs/heads/${spec_prefix}-*" 2>/dev/null) || collision=""
    if [ -n "$collision" ]; then
        printf 'branch.sh: error: refusing to create "%s" — branch(es) already claim prefix "%s" under a different slug:\n' "$spec_id" "$spec_prefix" >&2
        printf '%s\n' "$collision" | sed 's/^/    /' >&2
        printf 'branch.sh: error: resolve the numbering collision by hand before re-running /speckit-specify.\n' >&2
        exit 1
    fi

    # FR-001: branch born here, named exactly the spec ID. `checkout -b`
    # carries the current (uncommitted) working tree onto it — this is how
    # spec.md lands on the feature branch, not base_branch.
    printf 'branch.sh: creating feature branch "%s"\n' "$spec_id"
    git checkout -b "$spec_id" || die "could not create branch '$spec_id'"
}

# ---------------------------------------------------------------------------
# Concurrency guard (R1-S13 / Risk R3): serialize concurrent
# /speckit-specify runs around ensure_branch. Prefer flock(1)
# (Linux/util-linux); degrade to an atomic mkdir-as-mutex when it isn't on
# PATH — e.g. stock macOS ships the flock(2) syscall but no flock(1) CLI,
# so `command -v flock` reliably tells us which guard is available.
# ---------------------------------------------------------------------------

lock_wait_seconds=15
flock_file=".git/speckit-git-branch.flock"
mkdir_lock=".git/speckit-git-branch.lock"

cleanup_mkdir_lock() {
    rmdir "$mkdir_lock" 2>/dev/null || true
}

run_locked() {
    if command -v flock >/dev/null 2>&1; then
        exec 9>"$flock_file"
        if ! flock -w "$lock_wait_seconds" 9; then
            die "timed out waiting for the branch lock ($flock_file) — another /speckit-specify may be running"
        fi
        ensure_branch   # fd 9 (and its flock) is released when this process exits
        return
    fi

    # Portable guard (no flock(1) on PATH): mkdir is atomic on every POSIX
    # filesystem, so a successful mkdir IS the lock. A stale lock left by a
    # crashed prior run (>2min old) is reaped so this can't wedge the
    # pipeline shut forever.
    waited=0
    while ! mkdir "$mkdir_lock" 2>/dev/null; do
        if [ -n "$(find "$mkdir_lock" -maxdepth 0 -mmin +2 2>/dev/null)" ]; then
            rmdir "$mkdir_lock" 2>/dev/null || true
            continue
        fi
        waited=$((waited + 1))
        [ "$waited" -lt "$lock_wait_seconds" ] || die "timed out waiting for $mkdir_lock — another /speckit-specify may be running (remove the dir by hand if it's stale)"
        sleep 1
    done
    trap cleanup_mkdir_lock EXIT INT TERM
    ensure_branch
}

run_locked
