#!/bin/sh
#
# entry.sh — fixture entry point (arm1-success golden, T005 / 005-graphify-context)
#
# Sources its sibling helper.sh via a bare, literal ". ./x.sh" — the plainest of the three
# invokes shapes the augment.sh --emit contract names — then calls the function it
# defines. No variable indirection, no condition, nothing to disambiguate: this is the
# SUCCESS-branch shape, deliberately unlike arm1-messy's indirection/comment cases.
#
# Mechanical fixture input only: never executed by the test harness. augment.sh
# statically parses this file's text; it does not run it.
#
set -eu

. ./helper.sh

hello
