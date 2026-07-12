# Categorization — assemble.py tag-retirement fixture (v1, D65 verdict 10)

> **Frozen test fixture.** The negative control for the runtime_consumed guard: a single
> task carrying the legacy **`prompt` free tag** but **`runtime_consumed: false`**, whose
> `(type, specialization)` = `(docs, security)` resolves to the SYNTHETIC non-Sonnet base
> (`agt_fx_nonsonnet`, `model: haiku`) — the exact `(base, task)` pairing that used to trip
> the D48 `prompt`-tag guard. Under v1 the tag-convention check is **retired** (D65 verdict
> 10): the guard keys on the `runtime_consumed` modifier, not the tag, so this run MUST
> **exit 0 and write the roster** (T001 → `agt_fx_nonsonnet`, Haiku). Its twin
> `categorization.d48.fixture.md` — same base, but `runtime_consumed: true` — still exits 2.
> Together they prove the guard moved off the tag and onto the modifier. Hand-authored, not
> categorizer output.
>
> (T001's tags match no fixture skill, so it is also an incidental gap — `GAP_TASKS: T001`;
> that is not what this fixture tests, only a harmless side effect of using novel tags.)
>
> **Source binding (S14):** derived from `tasks.md @ deadbeef` (1 task) — a fixture value.

## Categorization table

| task_id | type | specialization | preserves_behavior | runtime_consumed | tags |
|---|---|---|---|---|---|
| T001 | `docs` | `security` | false | false | prompt, guard-check |
