---
name: decision-log-close-out
description: Closing out append-only decision-log entries in docs/90-DECISIONS-AND-IDEAS.md — resolving
  I-rows in place, recording newly-discovered ones, and writing gate-scope sign-off lines. Injected when
  a task's tags include decision-log, docs-90, close-out, i-row, sign-off, or fr-015.

specseyal:
  schema_version: "1.0"
  kind: skill
  id: skl_decision_log_close_out
  version: 1.0.0
  origin: generated

  taxonomy:
    tags: [decision-log, docs-90, close-out, i-row, sign-off, fr-015, log-discipline, append-only, gate-sign-off]

  grants: []

  provenance:
    created: 2026-07-20
    created_by: skill-builder
    source_feature: 008-pre-public-maintenance
    promoted_at: null
    stale_risk: false

  stats:
    assignments: 0
    success_rate: null
    last_used: null

  central:
    synced: false
    remote_id: null
    body_sha256: 7b0e548acf64b095521691bb8a19a8fe5289b1cc016683c829b218217804dc10
---

This task closes out entries in `docs/90-DECISIONS-AND-IDEAS.md` — resolving I-rows, recording new
ones, or writing a gate-scope sign-off line as part of that close-out.

In addition to your base instructions:

- **Resolve an I-row in place.** Append a resolution marker (e.g. a "✅ Resolved" or "→ RESOLVED" note)
  into the row's own existing cell. The log is append-only: never remove a row, and never renumber it.
- **State what was resolved, where, and how — inside the row's own cell.** Name the file, commit, or
  session that closed it. A bare status flip with no supporting detail does not count as a resolution.
- **Give every genuinely new finding its own new I-row.** When close-out work surfaces a gap, pattern,
  or follow-up not already covered by an existing row, add it as a new row in the parking-lot table's
  own column format, using the log's next unused I-N number. Folding a new finding into an existing
  row's notes as an aside does not satisfy this — it needs its own row.
- **Finish a same-session batch completely.** When a task names several I-rows to resolve together,
  resolve every one of them within that same session before finishing — the log-discipline rule treats
  a same-session batch as a single unit, not a queue to spread across sessions.
- **Keep a gate-scope sign-off line separately labeled.** When the task also requires a sign-off line
  about gate schema or gate semantics, write it as its own explicit line stating exactly what was
  checked and found negative for. Keep it visibly distinct from any adjacent bookkeeping or coverage
  proof in the same entry, even when both live in the same table cell or paragraph.
- **Pick the next I-N by scanning the table, not by guessing.** Before adding a new row, find the
  highest I-N already assigned in the table and use the next integer. Never reuse a number already
  assigned to a resolved or open row.
