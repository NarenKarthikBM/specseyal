#!/bin/sh
#
# install.sh — arm2-compose fixture input (T014, 005-graphify-context).
#
# Its AST (the old_stage function below) is re-extracted into fresh-extraction.json
# unchanged, so the incremental refresh leaves 0 stale survivors. Its `cp` line, by
# contrast, is an ARM-1 AUGMENT edge (installs: install.sh -> the copy destination) that
# the AST layer does not model at all — a pure AST refresh would silently drop it. The
# S06 cross-arm invariant asserts refresh.sh re-invokes augment.sh on the changed scope
# so this edge is present in the refreshed graph. Mechanical fixture input only: never
# executed by the harness; augment.sh statically parses this text.
set -eu

old_stage() {
    printf 'staging\n'
}

cp -R "payload" ".specify/extensions/demo"
