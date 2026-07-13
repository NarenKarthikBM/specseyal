#!/bin/sh
#
# cmd.sh — arm1-messy golden driver (T007, 005-graphify-context)
#
# Runs augment.sh in its --emit (test-surface) mode against this fixture's own
# input/repo/ slice and prints the canonical, sorted NODE/EDGE projection to stdout for
# test/run.sh to byte-diff against expected.txt. Resolves its own directory first so it
# never depends on the caller's working directory (the run.sh fixture convention).
#
# Until augment.sh (T008, a later wave) exists, this intentionally fails — the golden is
# authored red-for-the-right-reason: "augment.sh not found", never a malformed fixture.
#
set -eu

fixture_dir="$(cd "$(dirname "$0")" && pwd)"

exec "$REPO/extensions/graphify/extension/scripts/augment.sh" --emit "$fixture_dir/input/repo"
