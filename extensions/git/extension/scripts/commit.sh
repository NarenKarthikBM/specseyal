#!/bin/sh
# commit.sh — speckit.git.commit <phase> <summary> [extra-path...]
#
# The phase-tagged commit primitive (specs/002-speckit-ext-git/contracts/
# commands.md #speckit.git.commit): stages the feature's changed paths and
# commits with the FR-006 message grammar. No-op (exit 0, no commit, no
# stdout) when there is nothing to commit in scope (FR-004). Mechanical git
# only: no model call, no traces.jsonl write (FR-007).
#
# Usage:
#   commit.sh <phase> <summary> [extra-path...]
#
#   <phase>       one of: spec plan council gate tasks categorize analyze
#                 agents impl complete testing (data-model.md #PhaseCommit).
#   <summary>     short human-readable description. If <phase> is "impl"
#                 and <summary> begins with "wave " (e.g. "wave 2/5: ..."),
#                 the WaveCommit grammar is used instead of PhaseCommit
#                 (data-model.md #WaveCommit).
#   [extra-path]  additional repo-relative paths to stage — the task's
#                 declared outputs beyond specs/<spec-id>/** (e.g. impl
#                 wave commits touching real source files). Repo-relative,
#                 same convention as sha.sh's <artifact-path>.
#
# Message grammar (FR-006, git-config.yml commit.grammar, transcribed):
#   phase form:  <phase>(<spec-id>): <summary>
#   wave form:   impl(<spec-id>) <summary>   (summary already reads
#                "wave K/N: ..."; note NO colon after the "(<spec-id>)").
#
# Self-heal (R1-S12): before staging/committing anything, this script
# invokes the sibling branch.sh with no arguments — the same ensure-branch
# primitive the after_specify hook runs — so that a failed, absent, or
# not-yet-run brancher can never let a commit land on base_branch. This is
# the single self-healing entry point for the commit primitive; if
# branch.sh cannot be found or does not exit 0, commit.sh refuses to
# proceed. After self-heal returns, the current branch is independently
# re-checked against the spec ID as a second safety net.
#
# Staging scope (R1-S11) — CRITICAL: only specs/<spec-id>/** plus any
# declared [extra-path...] args are ever staged. This script never runs
# `git add -A` / `git add .` — an unattended repo-wide add would sweep a
# stray secret (or any other unrelated dirty file) into permanent history.
# The final `git add`/`git commit` calls are also both scoped with an
# explicit `--` pathspec (not a bare `git commit`), so even something
# already staged outside this scope by an unrelated process is left
# untouched — neither swept into this commit nor unstaged.
#
# Spec ID resolution (D45 — .specify/feature.json is the sole spec-ID
# resolver): basename of feature.json's "feature_directory", read
# independently here exactly as branch.sh reads it — never passed as a
# CLI argument, so this script can't drift from what /speckit-specify
# actually created (README.md).
#
# Out: the new commit SHA (full, `git rev-parse HEAD`) on stdout, and
# nothing else on stdout — ever — so callers can safely do
# `sha=$(commit.sh ...)`. On no-op, stdout is empty. All informational
# messages (including anything branch.sh prints during self-heal) are
# redirected to stderr for exactly this reason.

set -eu

die() {
    printf 'commit.sh: error: %s\n' "$1" >&2
    exit 1
}

usage() {
    echo "usage: commit.sh <phase> <summary> [extra-path...]" >&2
}

case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
esac

# ---------------------------------------------------------------------------
# Args.
# ---------------------------------------------------------------------------

[ "$#" -ge 2 ] || { usage; exit 1; }

phase="$1"
summary="$2"
shift 2
# "$@" is now exactly the [extra-path...] args (possibly empty), left
# untouched until the pathspec build below.

case "$phase" in
    spec|plan|council|gate|tasks|categorize|analyze|agents|impl|complete|testing) ;;
    *) die "phase '$phase' is not one of: spec plan council gate tasks categorize analyze agents impl complete testing" ;;
esac

[ -n "$summary" ] || die "<summary> must not be empty"

# ---------------------------------------------------------------------------
# This script's own directory (to locate the sibling branch.sh regardless
# of the caller's CWD or how commit.sh itself was invoked — relative,
# ./-relative, or absolute).
# ---------------------------------------------------------------------------

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd) || die "cannot resolve commit.sh's own directory from \$0 ($0)"
branch_script="$script_dir/branch.sh"

# ---------------------------------------------------------------------------
# Repo root (match branch.sh's own style) + feature.json.
# ---------------------------------------------------------------------------

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || die "not inside a git repository"
cd "$repo_root"

# ---------------------------------------------------------------------------
# Self-heal (R1-S12): ensure the feature branch exists and is checked out
# BEFORE anything is staged or committed. branch.sh takes no arguments —
# it resolves the spec ID from feature.json itself, same as we do below.
# Its informational stdout is redirected to stderr so it can never leak
# into this script's own stdout contract (the commit SHA, and nothing
# else).
# ---------------------------------------------------------------------------

[ -f "$branch_script" ] || die "sibling branch.sh not found at $branch_script — refusing to commit without the self-heal ensure-branch step"
sh "$branch_script" 1>&2 || die "self-heal failed: branch.sh (sibling) did not exit 0 — refusing to risk a commit landing on base_branch"

# ---------------------------------------------------------------------------
# Spec ID (D45: feature.json is the sole resolver — read independently,
# never recomputed / never taken as an argument).
# ---------------------------------------------------------------------------

feature_json=".specify/feature.json"
[ -f "$feature_json" ] || die "$feature_json not found — run /speckit-specify first"

feature_directory=$(grep '"feature_directory"' "$feature_json" 2>/dev/null \
    | head -n 1 \
    | sed -E 's/.*"feature_directory"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')

[ -n "$feature_directory" ] || die "could not read \"feature_directory\" from $feature_json"

spec_id=$(basename "$feature_directory")

# Second safety net (R1-S12): even though branch.sh just ensured + switched
# onto this branch, independently confirm HEAD is actually on it before
# touching the index. A failed/absent brancher (or a self-heal that somehow
# didn't land us on the right ref) must never let a commit land on
# base_branch.
current_branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) || current_branch=""
[ "$current_branch" = "$spec_id" ] || die "refusing to commit: HEAD is on '${current_branch:-<detached>}', expected feature branch '$spec_id' (self-heal via branch.sh did not leave us on the expected branch)"

# ---------------------------------------------------------------------------
# Message grammar (FR-006): phase form vs. wave form. Only phase "impl"
# with a summary beginning "wave " gets the WaveCommit grammar; every
# other phase (including a plain "impl" summary that does NOT start with
# "wave ", e.g. the after_implement hook's own phase commit) gets the
# ordinary PhaseCommit grammar.
# ---------------------------------------------------------------------------

case "$phase" in
    impl)
        case "$summary" in
            "wave "*)
                message="impl($spec_id) $summary"
                ;;
            *)
                message="impl($spec_id): $summary"
                ;;
        esac
        ;;
    *)
        message="$phase($spec_id): $summary"
        ;;
esac

# ---------------------------------------------------------------------------
# Staging scope (R1-S11): specs/<spec-id> plus any [extra-path...] args
# that currently exist on disk. `git add`/`git commit` fatally reject a
# pathspec matching nothing, so a not-yet-materialized feature dir or an
# undeclared/not-yet-created extra path is skipped, not an error — that
# just means there's nothing there to stage.
#
# The filtered list is rebuilt into "$@" via a newline-delimited
# IFS split (the standard array-free POSIX-sh idiom) rather than a bare
# unquoted expansion, so individual paths may still contain spaces;
# `set -f` suspends globbing for the split so a literal glob character in
# a path can't unexpectedly expand against the filesystem. Only an
# embedded newline in a path (never produced by this extension's
# spec-id/artifact-path conventions) would defeat this.
# ---------------------------------------------------------------------------

feature_path="specs/$spec_id"

pathspec_list=""
if [ -e "$feature_path" ]; then
    pathspec_list="$feature_path"
fi
for extra_path in "$@"; do
    [ -e "$extra_path" ] || continue
    if [ -n "$pathspec_list" ]; then
        pathspec_list="$pathspec_list
$extra_path"
    else
        pathspec_list="$extra_path"
    fi
done

if [ -z "$pathspec_list" ]; then
    # Nothing in scope exists on disk at all: definitionally no-op
    # (FR-004). Exit 0, stdout stays empty.
    exit 0
fi

old_ifs=$IFS
IFS='
'
set -f
set -- $pathspec_list
set +f
IFS=$old_ifs

# ---------------------------------------------------------------------------
# Stage only the scoped paths (never -A / .), then no-op if that scope has
# nothing changed (FR-004) — checked with an explicit pathspec so any
# already-staged content OUTSIDE our scope (left by something else) is
# never mistaken for "dirty" here, and is never swept into this commit.
# ---------------------------------------------------------------------------

git add -- "$@"

if git diff --cached --quiet -- "$@"; then
    # Clean for everything in scope: no-op. Stdout stays empty.
    exit 0
fi

# ---------------------------------------------------------------------------
# Commit, scoped to the same pathspec (git commit -- <pathspec> commits
# only those paths — including newly `git add`-ed untracked files under
# them — leaving any other already-staged index content exactly as it
# was, neither committed nor unstaged). Quiet, so nothing but the SHA we
# print ourselves ever reaches stdout.
# ---------------------------------------------------------------------------

git commit -q -m "$message" -- "$@"

printf '%s\n' "$(git rev-parse HEAD)"
