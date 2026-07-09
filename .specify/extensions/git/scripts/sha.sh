#!/bin/sh
# speckit.git.sha <artifact-path>
#
# Read-only primitive (specs/002-speckit-ext-git/contracts/commands.md):
# prints the SHA of the HEAD commit that last touched <artifact-path> —
# `git log -1 --format=%H -- "<artifact-path>"`. This is the value a gate
# command records as a GateSHABinding (data-model.md #GateSHABinding), later
# compared by verify-gate to decide freshness. No commit, no traces.jsonl
# write, no model call, no other side effect.

set -eu

usage() {
    echo "usage: sha.sh <artifact-path>" >&2
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

artifact_path="$1"

sha=$(git log -1 --format=%H -- "$artifact_path")

if [ -z "$sha" ]; then
    # No commit has ever touched this path: there is no SHA to bind. Fail
    # closed rather than print nothing, since a gate binding built on an
    # empty value would look "fresh" by accident.
    echo "sha.sh: no commit history for '$artifact_path' (artifact not yet committed — no SHA to bind)" >&2
    exit 1
fi

printf '%s\n' "$sha"
