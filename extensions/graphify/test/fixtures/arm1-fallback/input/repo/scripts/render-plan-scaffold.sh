#!/bin/sh
# render-plan-scaffold.sh — prints the plan-scaffolding template verbatim so
# a caller can prime a fresh plan.md from it.
#
# This is a genuine cross-file relationship — a script READING a Markdown
# scaffolding template — that sits OUTSIDE augment.sh's three modeled edge
# kinds (registers_hook / installs / invokes). plan.md Arm 1 (D76) excludes
# the "template-read" kind deliberately, booking it as an evidence-backed
# follow-up (I-24) rather than modeling it here. augment.sh MUST still
# DETECT this reference — it is a literal, unconditional, uncommented path,
# not the ambiguous shape the arm1-messy fixture exercises — and surface it
# as the labeled-assertion fallback (relation "asserted", confidence
# "ASSERTED", FR-004/SC-002): never dropped silently, and never minted as a
# confident "invokes" edge (invokes is reserved for script-to-script calls;
# this reference's target is a .md document, not a .sh script).
set -eu

cat "$(dirname "$0")/../templates/plan-template.md"
