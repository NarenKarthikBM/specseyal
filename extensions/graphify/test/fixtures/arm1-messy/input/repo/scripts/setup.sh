#!/bin/sh
#
# setup.sh — fixture setup script (arm1-messy golden, T007 / 005-graphify-context)
#
# Puts two S10 messy constructs and one clean control in the SAME file, adjacent to
# each other, so the pass has to discriminate line-by-line — not just react to
# "this repo has .sh files that mention other .sh files."
#
# Mechanical fixture input only: never executed by the test harness. augment.sh
# statically parses this file's text; it does not run it.
#
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- S10 construct 1: a commented-out source, INACTIVE ----------------------
# Retired when helper.sh (below) replaced it; left as a paper trail, not a live
# import. Expected handling: NO edge at all — nothing here to label, confidently
# or otherwise, because this line never runs.
# . ./old.sh

# --- S10 construct 3: indirection through an unresolvable variable ----------
# PLUGIN_DIR is supplied by whatever calls this script at install time; there is no
# literal path here for the pass to resolve. Expected handling: labeled assertion
# (relation=asserted, confidence=ASSERTED), naming the dequoted expression itself —
# not a confident EXTRACTED `invokes` edge, and not silently dropped either.
PLUGIN_DIR="${GADGET_PLUGIN_DIR:-}"
"$PLUGIN_DIR/script.sh"

# --- clean control: unconditional, literal, resolvable ----------------------
# SCRIPT_DIR is the standard self-locating idiom (always this script's own
# directory, regardless of caller) — a literal, resolvable target, unlike
# PLUGIN_DIR above. Expected handling: a confident EXTRACTED `invokes` edge to
# scripts/helper.sh — proving the two messy constructs above don't make the pass
# go quiet on the rest of this same file.
. "$SCRIPT_DIR/helper.sh"
