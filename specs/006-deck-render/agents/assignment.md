# Agent Assignment — 006-deck-render

> Format: `artifact-layout.md` §8 (D49, resolving I-12) + `data-model.md` §5. Written by
> `/speckit-agent-assign` — `assemble.py` (zero-AI, deterministic; `agent-library-schema.md` §3) plus a
> Sonnet `skill-builder` session per ∅-match gap (D2/D40.2) — then signed by `/speckit-workforce-approve`
> (S13). The signed `## Workforce Gate` decision is what unlocks `/speckit-implement-parallel`; the
> roster below it is a proposal until then.
>
> **Inputs:** `categorization.md` (37 tasks) ⇐ `tasks.md @ 7134c87` (S14 freshness
> binding — a stale SHA hard-warns and routes back to re-categorize rather than assembling against it).
> **Library snapshot (S18):** content-hash `053f8e331d7e76ac893c15570502e98bb1eddbccbb8368c3c45a1d13c64b1bef` — the base+skill set on disk when
> this run started, stamped so SC-005 ("gap-free ⇒ byte-identical roster") is checkable in one line.
>
> **Write boundary within this one file (principle 1):** `assemble.py` writes everything from here down
> through the `### Roster approved` table — base/skill selection, the `library`/`built` marks (FR-022),
> the elevated-grant union (FR-013, total-ordered per S01), the empty-lane / dropped-skill notes
> (FR-016 / FR-011), and (v1) the gap-cluster notes (FR-006/SC-007, D66) and the grant-tripwire notice
> (D67). It never writes the gate timestamp or the `reviewer` / `decision` / `reviewed` / `Notes:` /
> `Overrides:` fields below — those five are **`/speckit-workforce-approve`'s alone** (S13), and hold the
> literal `[PENDING — …]` marker until a human signs (or, under `gates.workforce.mode: auto` — **valid
> standalone**, `profile-schema.md` P4 / D67 verdict 12, no longer only within `full_auto` — the assigner
> resolves them itself in the same write, **unless the grant tripwire below is ENGAGED**, which forces a
> human signature regardless of profile — FR-020/W4; the pending state shown here is the `human`-mode
> default).

## Workforce Gate — 2026-07-15T09:03:12Z

| Field | Value |
|---|---|
| reviewer | Naren Karthik B M |
| decision | `approved` |
| reviewed | `tasks.md`, `assignment.md` (roster) |

### Roster approved

> One row per assembled agent — a base plus its ≤3 injected skills (W1); every task appears in exactly
> one row's `Task(s)` cell. Each `Skills` entry is marked **`library`** (present in the library at this
> run's start) or **`built`** (authored by the skill builder during *this* run) — FR-022; a **gap-free**
> roster (SC-005) carries zero `built` marks. **`Elevated grants` is mandatory on every row and is never
> omitted** — write `none` when the union is empty (W2/FR-018); the core toolset (`Read, Write, Edit,
> Bash, Glob, Grep`) is assumed and never listed (D44). A task matching no `(type, specialization)` lane
> assembles onto `agt_generic` and its row carries an **empty-lane** annotation (FR-016) — never a silent
> fallback. Whenever the 3-skill cap trims a candidate, the drop is recorded below the table, never
> silently discarded (FR-011/SC-004).

| Task(s) | Assembled agent (base) | Model | Skills (`id@ver`) | Elevated grants |
|---|---|---|---|---|
| T001 | `agt_devtools_cli` | Sonnet | `skl_extension_tree_scaffold@1.0.0` (built) | none |
| T002 | `agt_devtools_cli` | Sonnet | `skl_yaml_hooks@1.0.0` (library), `skl_extension_tree_scaffold@1.0.0` (built) | none |
| T003 | `agt_devtools_cli` | Sonnet | `skl_shell_scripting@1.0.0` (library), `skl_installer_hygiene@1.0.0` (library) | none |
| T004 | `agt_devtools_cli` | Sonnet | `skl_installer_hygiene@1.0.0` (library), `skl_shell_scripting@1.0.0` (library) | none |
| T005, T006, T013 | `agt_devtools_cli` | Sonnet | `skl_cli_command_wrapper@1.0.0` (built) | none |
| T007 | `agt_devtools_cli` | Sonnet | `skl_refactor_discipline@1.0.0` (library), `skl_yaml_hooks@1.0.0` (library) | none |
| T008 | `agt_devtools_cli` | Sonnet | `skl_docs_contract_authoring@1.0.0` (library), `skl_yaml_hooks@1.0.0` (library) | none |
| T009, T011 | `agt_devtools_cli` | Sonnet | `skl_docs_contract_authoring@1.0.0` (library) | none |
| T010 | `agt_devtools_cli` | Sonnet | `skl_yaml_hooks@1.0.0` (library), `skl_golden_fixture_discipline@1.0.0` (library) | none |
| T012 | `agt_devtools_cli` | Sonnet | `skl_refactor_discipline@1.0.0` (library), `skl_installer_hygiene@1.0.0` (library) | none |
| T014 | `agt_devtools_cli` | Sonnet | `skl_yaml_hooks@1.0.0` (library), `skl_quickstart_integration_gate@1.0.0` (library) | none |
| T015 | `agt_devtools_cli` | Sonnet | `skl_golden_fixture_discipline@1.0.0` (library) | none |
| T016 | `agt_qa_automation` | Sonnet | `skl_golden_fixture_discipline@1.0.0` (library) | none |
| T017 | `agt_qa_automation` | Sonnet | `skl_shell_scripting@1.0.0` (library) | none |
| T018 | `agt_qa_automation` | Sonnet | `skl_golden_fixture_discipline@1.0.0` (library), `skl_cli_command_wrapper@1.0.0` (built), `skl_quickstart_integration_gate@1.0.0` (library) | none |
| T019, T020, T023, T025, T026, T028, T029, T030, T032, T033, T035 | `agt_qa_automation` | Sonnet | `skl_refactor_discipline@1.0.0` (library), `skl_shell_scripting@1.0.0` (library) | none |
| T021, T031 | `agt_qa_automation` | Sonnet | `skl_refactor_discipline@1.0.0` (library), `skl_shell_scripting@1.0.0` (library), `skl_golden_fixture_discipline@1.0.0` (library) | none |
| T022 | `agt_qa_automation` | Sonnet | `skl_yaml_hooks@1.0.0` (library), `skl_golden_fixture_discipline@1.0.0` (library) | none |
| T024 | `agt_qa_automation` | Sonnet | `skl_refactor_discipline@1.0.0` (library), `skl_shell_scripting@1.0.0` (library), `skl_quickstart_integration_gate@1.0.0` (library) | none |
| T027 | `agt_qa_automation` | Sonnet | `skl_golden_fixture_discipline@1.0.0` (library), `skl_quickstart_integration_gate@1.0.0` (library) | none |
| T034 | `agt_qa_automation` | Sonnet | `skl_refactor_discipline@1.0.0` (library), `skl_installer_hygiene@1.0.0` (library), `skl_shell_scripting@1.0.0` (library) | none |
| T036 | `agt_qa_automation` | Sonnet | `skl_quickstart_integration_gate@1.0.0` (library) | none |
| T037 | `agt_qa_automation` | Sonnet | `skl_refactor_discipline@1.0.0` (library), `skl_quickstart_integration_gate@1.0.0` (library) | none |

**Empty lane(s) (FR-016):** none.

**Dropped skills (cap=3, FR-011/SC-004):** none.

**Gap clusters (FR-006/SC-007, D66):** none — every task matched at least one skill (or carries no tags). Gap-free; nothing for the skill-builder to author.

**Grant tripwire (D67):** clear — no elevated grants in this roster. `gates.workforce.mode: auto` may auto-approve (profile-schema.md P4).

**Notes:** none.

**Overrides:** none.
