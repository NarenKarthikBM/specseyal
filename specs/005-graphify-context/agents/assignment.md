# Agent Assignment — 005-graphify-context

> Format: `artifact-layout.md` §8 (D49, resolving I-12) + `data-model.md` §5. Written by
> `/speckit-agent-assign` — `assemble.py` (zero-AI, deterministic; `agent-library-schema.md` §3) plus a
> Sonnet `skill-builder` session per ∅-match gap (D2/D40.2) — then signed by `/speckit-workforce-approve`
> (S13). The signed `## Workforce Gate` decision is what unlocks `/speckit-implement-parallel`; the
> roster below it is a proposal until then.
>
> **Inputs:** `categorization.md` (36 tasks) ⇐ `tasks.md @ 4f6f740` (S14 freshness
> binding — a stale SHA hard-warns and routes back to re-categorize rather than assembling against it).
> **Library snapshot (S18):** content-hash `fb82fb90b412c8024d47c51baf747878437c811051e6359adb1567f0e3537330` — the base+skill set on disk when
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

## Workforce Gate — [PENDING — timestamp, set by `/speckit-workforce-approve`]

| Field | Value |
|---|---|
| reviewer | [PENDING — set by `/speckit-workforce-approve`] |
| decision | [PENDING — one of `approved` \| `approved-with-notes` \| `rejected`] |
| reviewed | [PENDING — set by `/speckit-workforce-approve`] |

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
| T001, T002, T016 | `agt_devtools_cli` | Sonnet | `skl_shell_scripting@1.0.0` (library), `skl_golden_fixture_discipline@1.0.0` (built) | none |
| T003, T008, T009 | `agt_devtools_cli` | Sonnet | `skl_shell_scripting@1.0.0` (library) | none |
| T004 | `agt_ai_agents` | Sonnet | `skl_dispatched_prompt_authoring@1.0.0` (library), `skl_docs_contract_authoring@1.0.0` (library), `skl_golden_fixture_discipline@1.0.0` (built) | none |
| T005, T006 | `agt_qa_automation` | Sonnet | `skl_shell_scripting@1.0.0` (library), `skl_yaml_hooks@1.0.0` (library), `skl_golden_fixture_discipline@1.0.0` (built) | none |
| T007 | `agt_qa_automation` | Sonnet | `skl_shell_scripting@1.0.0` (library), `skl_golden_fixture_discipline@1.0.0` (built) | none |
| T010, T021, T022, T027 | `agt_ai_agents` | Sonnet | `skl_dispatched_prompt_authoring@1.0.0` (library) | none |
| T011, T012, T013, T014, T018, T019, T024, T025 | `agt_qa_automation` | Sonnet | `skl_golden_fixture_discipline@1.0.0` (built) | none |
| T015 | `agt_devtools_cli` | Sonnet | `skl_golden_fixture_discipline@1.0.0` (built), `skl_shell_scripting@1.0.0` (library) | none |
| T017 | `agt_devtools_cli` | Sonnet | `skl_yaml_hooks@1.0.0` (library) | none |
| T020 | `agt_ai_agents` | Sonnet | `skl_dispatched_prompt_authoring@1.0.0` (library), `skl_golden_fixture_discipline@1.0.0` (built) | none |
| T023 | `agt_ai_agents` | Sonnet | `skl_docs_contract_authoring@1.0.0` (library) | none |
| T026 | `agt_ai_agents` | Sonnet | `skl_yaml_hooks@1.0.0` (library) | none |
| T028 | `agt_ai_agents` | Sonnet | `skl_orchestration@1.0.0` (library) | none |
| T029, T030, T031, T032, T033, T034 | `agt_qa_automation` | Sonnet | `skl_golden_fixture_discipline@1.0.0` (built), `skl_quickstart_integration_gate@1.0.0` (built) | none |
| T035 | `agt_devtools_cli` | Sonnet | `skl_installer_hygiene@1.0.0` (library), `skl_shell_scripting@1.0.0` (library) | none |
| T036 | `agt_qa_automation` | Sonnet | `skl_refactor_discipline@1.0.0` (library), `skl_quickstart_integration_gate@1.0.0` (built) | none |

**Empty lane(s) (FR-016):** none.

**Dropped skills (cap=3, FR-011/SC-004):** none.

**Gap clusters (FR-006/SC-007, D66):** none — every task matched at least one skill (or carries no tags). Gap-free; nothing for the skill-builder to author.

**Grant tripwire (D67):** clear — no elevated grants in this roster. `gates.workforce.mode: auto` may auto-approve (profile-schema.md P4).

**Notes:** [PENDING — the reviewer's notes, or `none.` if there are none]

**Overrides:** [PENDING — any roster value the reviewer overrode at the gate, naming the D-row if one was opened, or `none.` if there are none]
