#!/bin/sh
#
# helper.sh — fixture helper sourced by setup.sh (arm1-messy golden, T007 /
# 005-graphify-context)
#
# Exists only so setup.sh's clean control construct names a real file. Has no
# outgoing edges of its own.
#
# Mechanical fixture input only: never executed by the test harness. augment.sh
# statically parses this file's text; it does not run it.
#

echo "helper ran"
