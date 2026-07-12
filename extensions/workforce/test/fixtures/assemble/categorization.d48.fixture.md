# Categorization — assemble.py runtime_consumed-guard fixture (T021 / SC-006/S03)

> **Frozen test fixture.** A single `runtime_consumed: true` task whose `(type,
> specialization)` resolves to the frozen library's SYNTHETIC non-Sonnet base
> (`agt_fx_nonsonnet`, `model: haiku`) -- so `extensions/workforce/test/test_assemble.sh`
> can assert the runtime_consumed guard's `else: hard-error` branch (agent-library-schema.md
> §4, taxonomy.md §2.4/§3; the re-homed D48 guard, D65 verdict 10) actually executes, not
> merely that it exists in the source. A conforming run over this fixture MUST exit non-zero
> (2) and write nothing. Hand-authored, not categorizer output.
>
> **v1 note (D65).** The guard now keys on the `runtime_consumed` modifier, NOT the `prompt`
> free tag. This task keeps its `prompt` tag (a legitimate detection hint) but it is the
> `runtime_consumed: true` cell that fires the guard — the tag-convention check is retired.
> The complementary fixture `categorization.prompt-retired.fixture.md` proves the tag alone
> (with `runtime_consumed: false`) no longer trips it.
>
> **Source binding (S14):** derived from `tasks.md @ deadbeef` (1 task) -- a fixture value.

## Categorization table

| task_id | type | specialization | preserves_behavior | runtime_consumed | tags |
|---|---|---|---|---|---|
| T001 | `docs` | `security` | false | true | prompt, guard-check |
