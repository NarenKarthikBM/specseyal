# Categorization — assemble.py gap-rerun fixture (T021 / S15)

> **Frozen test fixture.** Two tasks: T001's tag is already satisfied by the frozen
> "open" skill snapshot (`gap/skills-open/`); T002's tag (`novel-tag`) matches nothing
> until the "closed" snapshot (`gap/skills-closed/`, simulating the skill builder
> persisting a new `skl_fx_novel` module and the caller passing
> `--built-skill skl_fx_novel`) is used instead. `extensions/workforce/test/test_assemble.sh`
> runs `assemble.py` once per snapshot and asserts T001's roster row is byte-identical
> across both runs while only T002's row changes (S15 gap-rerun stability). Both snapshots
> share the same `library/agents/` (bases are curated-static, D44) and an identical copy
> of `fx-known/SKILL.md` (same id/version/tags/grants/body, so its `body_sha256` -- and
> therefore T001's row signature -- cannot drift between the two runs). Hand-authored, not
> categorizer output.
>
> **Source binding (S14):** derived from `tasks.md @ deadbeef` (2 tasks) -- a fixture value.

## Categorization table

| task_id | type | specialization | preserves_behavior | runtime_consumed | tags |
|---|---|---|---|---|---|
| T001 | `service` | `qa-automation` | false | false | known-tag |
| T002 | `test` | `qa-automation` | false | false | novel-tag |
