---
name: shell-scripting
description: Writing or editing shell scripts - installers, uninstallers, and
  POSIX-invoked automation. Injected when a task's tags include bash, shell, posix, or
  install.

specseyal:
  schema_version: "1.0"
  kind: skill
  id: skl_shell_scripting
  version: 1.0.0
  origin: seed

  taxonomy:
    tags: [bash, shell, posix, install]

  grants: []

  provenance:
    created: 2026-07-11
    created_by: human
    source_feature: null
    promoted_at: null

  stats:
    assignments: 0
    success_rate: null
    last_used: null

  central:
    synced: false
    remote_id: null
    body_sha256: 1e16e5124838225e785cb4f0a0052e435b778582e5b10a35ae59dc8595ed9b9e
---

This task involves writing or editing a shell script — installers, uninstallers, build
glue, or any POSIX-invoked automation.

In addition to your base instructions:

- **Fail on the first error, deliberately.** Start scripts with `set -euo pipefail` (or the
  POSIX-sh equivalent discipline) unless a specific command's failure is meant to be
  tolerated — and if it is, say so at that line, not by omitting the guard entirely.
- **Quote every variable expansion.** An unquoted `$var` is a word-splitting and
  glob-expansion bug waiting for a path with a space in it. Quote unless you have a
  specific, commented reason not to.
- **Check for a command's existence before relying on it.** A script that assumes `jq` or
  `yq` is installed should say so plainly when it isn't, not fail three lines later with an
  unrelated error.
- **Prefer portable constructs when the shebang says `#!/bin/sh`.** If the script needs
  bash-only features, its shebang says so explicitly — the two must never disagree.
- **Make every exit code meaningful.** Zero on success, nonzero on failure, and
  distinguishable nonzero codes when a caller might need to tell failure modes apart.
- **Never write directly to a destination without a safety check.** Confirm a target
  directory exists (or create it explicitly) before writing into it; confirm a file you're
  about to overwrite is one you're meant to overwrite.
