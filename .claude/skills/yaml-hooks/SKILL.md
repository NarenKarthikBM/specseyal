---
name: yaml-hooks
description: Writing or editing YAML configuration, manifests, or hook-registration
  wiring. Injected when a task's tags include yaml, config, manifest, or hooks.

specseyal:
  schema_version: "1.0"
  kind: skill
  id: skl_yaml_hooks
  version: 1.0.0
  origin: seed

  taxonomy:
    tags: [yaml, config, manifest, hooks]

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
    body_sha256: a7724d89d812f64db1057142d763452095b72bfa602679eabb9f50dca531a6bb
---

This task involves writing or editing YAML — configuration files, manifests, or the
hook-registration wiring that other tools read.

In addition to your base instructions:

- **Preserve key order and existing structure when editing a shared manifest.** A
  hand-authored ordering often carries meaning (precedence, grouping); reorder only when
  the task specifically calls for it.
- **Never hand-merge a manifest that another process also writes.** If a file is
  read-modify-written by more than one actor, treat concurrent access as a real risk —
  merge under a lock or an atomic write-then-rename, not a bare read-edit-write.
- **Validate the YAML parses before you consider the task done.** A syntactically broken
  manifest fails silently for whoever reads it next, often far from where the mistake was
  made.
- **Comment the non-obvious.** A hook's fire-point, a key's valid enum, or a manifest's
  consumer is worth one line of comment if it isn't obvious from the key name alone.
- **Keep additions additive to existing hook chains.** A new hook registration should not
  silently replace or reorder an existing one's fire-point unless the task is specifically
  about that reordering.
- **Match the schema the consumer expects exactly.** An extra or missing key in a config a
  script parses strictly is a startup failure, not a warning — check the consuming code's
  expectations, not just YAML-validity.
