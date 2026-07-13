#!/bin/sh
#
# install.sh — fixture installer (arm1-success golden, T005 / 005-graphify-context)
#
# Minimal stand-in for the real per-extension installers under extensions/*/install.sh
# (D57): removes any stale copy at the destination, then copies the extension/ source
# tree onto it — the same rm -rf + cp -R shape every real installer in this repo already
# uses, with both operands literal (no variable) so the SUCCESS-branch extraction is
# unambiguous.
#
# Mechanical fixture input only: never executed by the test harness. augment.sh
# statically parses this file's text; it does not run it.
#
set -eu

rm -rf ".specify/extensions/widget"
cp -R "extension" ".specify/extensions/widget"
