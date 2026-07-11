---
name: installer-hygiene
description: Installer/uninstaller lifecycle work that must be idempotent and
  reinstall-safe. Injected when a task's tags include install, uninstall, idempotent, or
  reinstall.

specseyal:
  schema_version: "1.0"
  kind: skill
  id: skl_installer_hygiene
  version: 1.0.0
  origin: seed

  taxonomy:
    tags: [install, uninstall, idempotent, reinstall]

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
    body_sha256: 97fb2698eb771e208fc04a776a6e0837beb6928cba7c9b6f1eb145ce048d5e0a
---

This task involves an installer or uninstaller — code whose job is to add or remove
something from a user's environment, possibly more than once.

In addition to your base instructions:

- **Deregister before you register.** An installer that might run twice must remove its
  own prior registration first, so re-running it converges to one clean state, never a
  pile of accumulated duplicates.
- **Never delete what you don't own.** An uninstall step removes exactly what its matching
  install step created — nothing adjacent, nothing user-authored, nothing another
  extension or process might also depend on.
- **Treat reinstall as the primary test, not an edge case.** Install, then install again,
  then uninstall, then install once more — each step should leave the system in the same
  well-defined state a fresh install would.
- **Keep generated or user data outside the install payload.** Anything produced after
  install (logs, generated files, flywheel-persisted data) lives outside whatever path a
  reinstall's cleanup step touches, so a reinstall never silently destroys it.
- **Make partial failure recoverable.** If an install is interrupted partway, a re-run
  should be able to finish or cleanly retry rather than leaving the system in a state
  neither installed nor clean.
- **Report what changed.** An install or uninstall step that touches the filesystem or a
  shared config says what it added, removed, or left alone — silent success is
  indistinguishable from silent no-op to whoever is debugging later.
