#!/bin/sh
# cleanup.sh — completion cleanup for speckit-ext-git (FR-011, D52, R1-S27).
#
# Wrapped later by the /speckit-git-cleanup human skill. Mechanical git
# only: no model call, no traces.jsonl write (FR-007).
#
# Usage:
#   cleanup.sh [feature-branch-name]
#
#   With no argument: the spec id / feature branch is derived from
#   .specify/feature.json's `feature_directory` (basename), falling back
#   to the currently checked-out branch if that file is absent or the
#   field can't be parsed. With an argument: that name IS the feature
#   branch and the spec id (FeatureBranch.name == spec id, data-model.md).
#
# Behavior (contracts/commands.md — /speckit-git-cleanup):
#   1. Integrate the feature branch into `base_branch` (git-config.yml):
#      fast-forward when possible; `git merge --no-ff` only when the base
#      has diverged (ff impossible). Never squash, never rebase-collapse
#      — every phase/wave commit stays individually reachable (D25).
#   2. Create the MANDATORY annotated tag `complete/<spec-id>` at the
#      integration commit — the completion anchor, independent of merge
#      topology (D52).
#   3. Delete the feature branch with `git branch -d` (never `-D`): git
#      itself refuses to delete an unmerged branch, so this is the
#      no-silent-loss guard rather than a bespoke check.
#   4. On a textual merge conflict: `git merge --abort` and surface a
#      clear, non-zero failure — never auto-resolve, never delete an
#      unmerged branch.
#   5. Idempotent: re-running after a completed cleanup (branch already
#      gone, tag already present) is a clean no-op, exit 0.
#
# Also refuses to operate (no side effects) if the working tree is dirty.

set -eu

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

die() {
    printf 'cleanup.sh: error: %s\n' "$1" >&2
    exit 1
}

# strip_quotes <value> — drop a single pair of surrounding double quotes.
strip_quotes() {
    printf '%s' "$1" | sed -E 's/^"(.*)"$/\1/'
}

# yaml_top <file> <key> — value of a top-level (unindented) "key: value" line.
# Light grep/sed parse; good enough for this extension's flat git-config.yml.
yaml_top() {
    grep -E "^$2:" "$1" 2>/dev/null | head -n 1 | sed -E "s/^$2:[[:space:]]*//; s/[[:space:]]*(#.*)?\$//"
}

# yaml_nested <file> <parent-key> <child-key> — value of a child key
# indented under an unindented "<parent-key>:" block (stops at the next
# unindented line).
yaml_nested() {
    awk -v parent="$2" -v child="$3" '
        $0 ~ "^"parent":" { in_block=1; next }
        in_block && /^[^[:space:]]/ { in_block=0 }
        in_block && $0 ~ "^[[:space:]]+"child":" {
            sub("^[[:space:]]+"child":[[:space:]]*", "");
            sub("[[:space:]]*(#.*)?$", "");
            print;
            exit
        }
    ' "$1" 2>/dev/null
}

branch_exists() {
    git show-ref --verify --quiet "refs/heads/$1"
}

tag_exists() {
    git show-ref --verify --quiet "refs/tags/$1"
}

# worktree_of_branch <branch> — path of the worktree that currently has
# <branch> checked out, or empty if none. In a linked-worktree layout the
# base_branch and the feature branch live in *different* worktrees, and git
# forbids checking a branch out in two places at once — so cleanup must ask
# where each branch lives rather than assume it can `git checkout` in place.
worktree_of_branch() {
    git worktree list --porcelain 2>/dev/null | awk -v want="refs/heads/$1" '
        /^worktree / { path = substr($0, 10) }
        /^branch /   { if (substr($0, 8) == want) { print path; exit } }
    '
}

# ---------------------------------------------------------------------------
# Args
# ---------------------------------------------------------------------------

[ "$#" -le 1 ] || die "usage: cleanup.sh [feature-branch-name]"

# ---------------------------------------------------------------------------
# Locate the repo root and this extension's own config (config lives next
# to this script regardless of where the extension bundle is installed).
# ---------------------------------------------------------------------------

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || die "not inside a git repository"
cd "$repo_root"

script_dir=$(dirname "$0")
script_dir=$(cd "$script_dir" 2>/dev/null && pwd) || die "cannot resolve script directory from '$0'"
config_file="$script_dir/../git-config.yml"
[ -f "$config_file" ] || die "config not found: $config_file"

base_branch=$(strip_quotes "$(yaml_top "$config_file" base_branch)")
[ -n "$base_branch" ] || base_branch=main

merge_policy=$(strip_quotes "$(yaml_nested "$config_file" merge policy)")
[ -n "$merge_policy" ] || merge_policy=ff-permitted

# v1 implements exactly one integration policy (data-model.md §Config); the
# mandatory tag anchor — not merge topology — is the completion anchor
# (D52), which is what frees this to fast-forward. Fail closed on drift.
case "$merge_policy" in
    ff-permitted) : ;;
    *) die "unsupported merge.policy '$merge_policy' in $config_file (this script implements ff-permitted only)" ;;
esac

anchor_pattern=$(strip_quotes "$(yaml_nested "$config_file" anchor pattern)")
[ -n "$anchor_pattern" ] || anchor_pattern='complete/<spec-id>'

# ---------------------------------------------------------------------------
# Resolve the feature branch + spec id.
# ---------------------------------------------------------------------------

feature_branch="${1:-}"

if [ -z "$feature_branch" ]; then
    feature_json=".specify/feature.json"
    if [ -f "$feature_json" ]; then
        feature_directory=$(grep '"feature_directory"' "$feature_json" 2>/dev/null \
            | head -n 1 \
            | sed -E 's/.*"feature_directory"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')
        if [ -n "$feature_directory" ]; then
            feature_branch=$(basename "$feature_directory")
        fi
    fi
fi

if [ -z "$feature_branch" ]; then
    feature_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || die "cannot determine the current branch"
fi

[ "$feature_branch" != "HEAD" ] || die "not on a branch (detached HEAD) and no feature-branch argument given"

spec_id="$feature_branch"

[ "$spec_id" != "$base_branch" ] || die "resolved feature branch equals base_branch ('$base_branch'); nothing to clean up"

tag_name=$(printf '%s' "$anchor_pattern" | sed "s/<spec-id>/$spec_id/")

# ---------------------------------------------------------------------------
# Idempotency check (read-only; safe regardless of working-tree state).
# ---------------------------------------------------------------------------

branch_is_present=false
branch_exists "$feature_branch" && branch_is_present=true

tag_is_present=false
tag_exists "$tag_name" && tag_is_present=true

if [ "$branch_is_present" = false ] && [ "$tag_is_present" = true ]; then
    printf 'cleanup.sh: already clean — branch "%s" is gone and tag "%s" exists; nothing to do.\n' \
        "$feature_branch" "$tag_name"
    exit 0
fi

if [ "$branch_is_present" = false ] && [ "$tag_is_present" = false ]; then
    die "feature branch '$feature_branch' does not exist and completion tag '$tag_name' is missing — nothing to integrate and no anchor to confirm; check the branch name or repair history manually"
fi

# ---------------------------------------------------------------------------
# From here on we do real work: guard the working tree first.
# ---------------------------------------------------------------------------

[ -z "$(git status --porcelain)" ] || die "working tree is dirty; commit or stash changes before cleanup"

branch_exists "$base_branch" || die "base_branch '$base_branch' does not exist locally"

# ---------------------------------------------------------------------------
# Locate base_branch. In a linked-worktree layout it is typically checked out
# in a *different* worktree (e.g. the primary clone), where git forbids us from
# checking it out here — a `git checkout <base>` would fail with "already used
# by worktree ...", blocking every cleanup run invoked from a feature worktree
# (I-30/D81). Integrate in whichever worktree owns base_branch rather than
# assuming this one can hold it.
# ---------------------------------------------------------------------------

base_wt=$(worktree_of_branch "$base_branch")

if [ -n "$base_wt" ] && [ "$base_wt" != "$repo_root" ]; then
    # base_branch lives elsewhere — operate there, and require it clean so a
    # fast-forward can't be blocked by, or leave behind, unrelated local state.
    [ -z "$(git -C "$base_wt" status --porcelain)" ] \
        || die "base_branch '$base_branch' is checked out in worktree '$base_wt' with a dirty working tree; commit or stash there before cleanup"
    integrate_here=false
else
    # base_branch is here (or checked out nowhere) — check it out in place, the
    # original single-worktree behavior.
    git checkout --quiet "$base_branch" || die "could not check out base_branch '$base_branch'"
    integrate_here=true
fi

# bgit — run git in base_branch's worktree (here, or the one that owns it).
bgit() {
    if [ "$integrate_here" = true ]; then
        git "$@"
    else
        git -C "$base_wt" "$@"
    fi
}

# ---------------------------------------------------------------------------
# Integrate: ff when possible, --no-ff only when base_branch has diverged
# from the feature branch tip (D52). Never squash, never rebase-collapse.
# ---------------------------------------------------------------------------

ff_possible=false
git merge-base --is-ancestor "$base_branch" "$feature_branch" && ff_possible=true

merge_failed=false
if [ "$ff_possible" = true ]; then
    bgit merge --ff-only "$feature_branch" || merge_failed=true
else
    bgit merge --no-ff -m "complete(${spec_id}): integrate ${feature_branch} into ${base_branch}" "$feature_branch" || merge_failed=true
fi

if [ "$merge_failed" = true ]; then
    bgit merge --abort >/dev/null 2>&1 || true
    die "integration of '$feature_branch' into '$base_branch' failed (likely a merge conflict) — merge aborted, no changes made, '$feature_branch' left intact; resolve manually and re-run cleanup.sh"
fi

integration_commit=$(git rev-parse "$base_branch")

# ---------------------------------------------------------------------------
# Mandatory completion anchor: annotated tag at the integration commit,
# unconditionally, regardless of merge topology (D52). Tags are global — this
# works the same whichever worktree performed the merge. Skip only if a prior,
# interrupted run already created it.
# ---------------------------------------------------------------------------

if [ "$tag_is_present" = true ]; then
    printf 'cleanup.sh: tag "%s" already present; skipping tag creation.\n' "$tag_name"
else
    git tag -a "$tag_name" "$integration_commit" -m "Completion anchor for ${spec_id} (integrated into ${base_branch})"
fi

# ---------------------------------------------------------------------------
# Retire the feature branch. `git branch -d` refuses to delete a branch that is
# checked out in ANY worktree — so if the feature branch is still checked out
# (typically the very worktree cleanup was invoked from), detach that HEAD
# first. After a fast-forward the detached commit is the one already in the
# working tree, so no files change; the worktree DIRECTORY is left in place for
# the human to remove when they choose (never `git worktree remove` — it can be
# the caller's own current directory). `-d` (never `-D`): git refuses if any
# commit would become unreachable — the no-silent-loss guard.
# ---------------------------------------------------------------------------

feature_wt=$(worktree_of_branch "$feature_branch")
detached_note=""
if [ -n "$feature_wt" ]; then
    git -C "$feature_wt" checkout --quiet --detach \
        || die "feature branch '$feature_branch' is checked out in worktree '$feature_wt' and its HEAD could not be detached to retire the branch"
    detached_note=" (worktree '$feature_wt' left on a detached HEAD)"
fi

git branch -d "$feature_branch" || die "'$feature_branch' still has commits not reachable from '$base_branch'; refusing to force-delete — resolve manually"

printf 'cleanup.sh: integrated "%s" into "%s"; tag "%s" set; branch deleted.%s\n' \
    "$feature_branch" "$base_branch" "$tag_name" "$detached_note"
