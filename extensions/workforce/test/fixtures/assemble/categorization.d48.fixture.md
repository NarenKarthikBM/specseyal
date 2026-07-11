# Categorization — assemble.py D48-guard fixture (T021 / SC-006/S03)

> **Frozen test fixture.** A single `prompt`-tagged task whose `(type, specialization)`
> resolves to the frozen library's SYNTHETIC non-Sonnet base (`agt_fx_nonsonnet`,
> `model: haiku`) -- so `extensions/workforce/test/test_assemble.sh` can assert the D48
> guard's `else: hard-error` branch (agent-library-schema.md §4, taxonomy-v0.md §3, D48)
> actually executes, not merely that it exists in the source. A conforming run over this
> fixture MUST exit non-zero (2) and write nothing. Hand-authored, not categorizer output.
>
> **Source binding (S14):** derived from `tasks.md @ deadbeef` (1 task) -- a fixture value.

## Categorization table

| task_id | type | specialization | preserves_behavior | tags |
|---|---|---|---|---|
| T001 | `docs` | `security` | false | prompt, guard-check |
