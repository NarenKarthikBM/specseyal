# Agent Assignment — assemble

> Format: `artifact-layout.md` §8 (D49, resolving I-12) + `data-model.md` §5. Written by
> `/speckit-agent-assign` — `assemble.py` (zero-AI, deterministic; `agent-library-schema.md` §3) plus a
> Sonnet `skill-builder` session per ∅-match gap (D2/D40.2) — then signed by `/speckit-workforce-approve`
> (S13). The signed `## Workforce Gate` decision is what unlocks `/speckit-implement-parallel`; the
> roster below it is a proposal until then.
>
> **Inputs:** `categorization.md` (2 tasks) ⇐ `tasks.md @ deadbeef` (S14 freshness
> binding — a stale SHA hard-warns and routes back to re-categorize rather than assembling against it).
> **Library snapshot (S18):** content-hash `c13ce45b1b7b41b32a94d1be0a80875532a70837f682ffd27096ffe7813a9bc2` — the base+skill set on disk when
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
| T001 | `agt_fx_sonnet` | Sonnet | `skl_fx_alpha@1.0.0` (library), `skl_fx_beta@1.0.0` (library) | `aa_beta_only`, `web_search`, `zz_alpha_only` |
| T002 | `agt_fx_sonnet` | Sonnet | `skl_fx_delta@1.0.0` (library), `skl_fx_epsilon@1.0.0` (library), `skl_fx_gamma@1.0.0` (library) | none |

**Empty lane(s) (FR-016):** none.

**Dropped skills (cap=3, FR-011/SC-004):**

- T002 — 4 candidate(s) ranked by tag-Jaccard (agent-library-schema.md S3 step 4); cap is 3; dropped `skl_fx_zeta@1.0.0`.

**Gap clusters (FR-006/SC-007, D66):** none — every task matched at least one skill (or carries no tags). Gap-free; nothing for the skill-builder to author.

**Grant tripwire (D67): ENGAGED** — this roster carries elevated grant(s) `aa_beta_only`, `web_search`, `zz_alpha_only`. The workforce gate REQUIRES a human signature regardless of `profile.yaml`: `gates.workforce.mode: auto` does not auto-approve here (approving the roster is approving that network/tool access — profile-schema.md P4 + D67 verdict 12).

**Notes:** [PENDING — the reviewer's notes, or `none.` if there are none]

**Overrides:** [PENDING — any roster value the reviewer overrode at the gate, naming the D-row if one was opened, or `none.` if there are none]
