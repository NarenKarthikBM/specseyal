#!/bin/sh
#
# helper.sh — fixture helper sourced by entry.sh (arm1-success golden, T005 / 005-graphify-context)
#
# Defines the one function entry.sh calls after sourcing this file.
#
# Mechanical fixture input only: never executed by the test harness. augment.sh
# statically parses this file's text; it does not run it.
#

hello() {
    printf 'hello from helper\n'
}
