#!/bin/sh
#
# install.sh — fixture installer (arm1-messy golden, T007 / 005-graphify-context)
#
# Contains ONLY the S10 "conditional cp" construct under test — no unconditional
# install step; a clean, unconditional `installs` edge is arm1-success's job, not
# this fixture's. Both cp operands below are literal strings (no variable
# indirection) — the ONLY thing standing between this copy and a confident
# `installs` fact is that it sits inside a runtime check this pass cannot evaluate
# by reading the repo alone, not anything the source or destination path itself
# leaves ambiguous.
#
# Mechanical fixture input only: never executed by the test harness. augment.sh
# statically parses this file's text; it does not run it.
#
set -eu

# --- S10 construct 2: a conditional cp -------------------------------------
# Migrates a legacy config forward only when the TARGET repo's tree still carries
# the old marker file at install time — a fact about that repo, not this one.
# Expected handling: labeled assertion (relation=asserted, confidence=ASSERTED) — a
# real, nameable relationship, just not one presentable as unconditional fact;
# never silently dropped either (FR-004). See ../../README.md.
if [ -f "legacy-gadget.marker" ]; then
  cp "legacy-gadget.yml" ".specify/extensions/gadget/config.yml"
fi
