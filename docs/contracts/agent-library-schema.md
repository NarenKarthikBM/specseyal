# Contract — Agent Library Entry

> **Status:** 1.0 (M0). Normative.
> **Implements:** D2 (hybrid creator), D16 (taxonomy keys), D17 (per-repo now, central library later), D18 (model policy), D24/I-1 (flywheel), D34.
> **Location:** `.claude/agents/<name>.md` — one file per specialist.
> **Consumed by:** the agent creator (M3), Claude Code's own subagent loader, the central-library MCP (I-10, later).

An entry is **a Claude Code agent file that happens to carry SpecSeyal metadata** — not a SpecSeyal file that happens to be loadable. That ordering is the whole design (D34): the same file must dispatch as a subagent today and sync to a central library tomorrow, with no conversion step.

---

## 1. Format

Claude Code owns the top-level frontmatter keys `name`, `description`, `tools`, `model`. Everything of ours nests under a single `specseyal:` key, so the two vocabularies can never collide.

```markdown
---
name: backend-service-python
description: Implements service-layer business logic in Python. Use for tasks typed
  service or endpoint in a FastAPI/SQLAlchemy codebase.
tools: Read, Write, Edit, Bash, Glob, Grep
model: sonnet

specseyal:
  schema_version: "1.0"
  id: agt_backend_service_python          # stable, immutable, globally unique
  version: 1.2.0                          # semver
  origin: library                         # library | generated | promoted

  taxonomy:                               # D16 fixed core + free tags
    type: [service, endpoint]             # list — the task types this agent accepts
    specialization: backend-service       # exactly one — its lane
    tags: [python, fastapi, sqlalchemy, pytest]

  provenance:
    created: 2026-07-08
    created_by: human                     # human | agent-creator
    source_feature: null                  # specs/NNN-… for origin=generated|promoted
    promoted_at: null                     # ISO date; set when generated → promoted

  stats:                                  # DERIVED from traces.jsonl. Cache, not truth.
    assignments: 0
    success_rate: null
    last_used: null

  central:                                # D17 — central-sync-ready from day one
    synced: false
    remote_id: null
    body_sha256: null                     # hash of the prompt body below
---

<system prompt body — everything below the frontmatter>
```

## 2. Identity, versioning, and why `id` is not `name`

| Field | Mutable? | Purpose |
|---|---|---|
| `id` | **never** | The join key. Central library, traces, and assignment records all reference `id`. |
| `name` | yes | Claude Code's dispatch handle and the filename. Humans rename things. |
| `version` | monotonic | Attributes stats to a prompt. |

`id` format: `agt_` + `snake_case`, stable for the life of the specialist. Renaming `backend-service-python` → `python-backend` changes the filename and `name`; `id` and accumulated `stats` survive. Had the library joined on `name`, one rename would orphan a specialist's entire performance history — and the flywheel (D24) is exactly that history.

**Version bump rule.** Bump when any of `{prompt body, tools, model}` changes:
- prompt body → **minor** (behavior change)
- `tools` or `model` → **minor**
- typo/comment-only edit → **patch**
- taxonomy `type` or `specialization` change → **major** (it now matches different tasks; old stats no longer transfer)

`body_sha256` is recomputed on every write. It is how the central library (I-10) detects that a repo edited a shared specialist locally without bumping `version` — the one desync that silently corrupts cross-repo stats.

**Body, defined exactly:** everything after the frontmatter's closing `---` line and its newline, taken verbatim as UTF-8 bytes — no trimming, no normalization. Reference implementation:

```sh
sed '1,/^---$/d; 1,/^---$/d' agent.md | shasum -a 256
```

## 3. Taxonomy keys and the matching algorithm (D16)

Keys are drawn from `taxonomy-v0.md`. `type` is a **list** (a specialist accepts several kinds of work); `specialization` is **exactly one** (a specialist has one lane). This asymmetry is the matching algorithm's whole basis.

Given a categorized task `t` with `t.type`, `t.specialization`, `t.tags`:

```
candidates = { a ∈ library :
                 t.type ∈ a.taxonomy.type
               ∧ t.specialization == a.taxonomy.specialization }

if candidates = ∅         → gap generator (D2): create a bespoke agent
if |candidates| = 1       → assign it
else rank by, in order:
    1. |t.tags ∩ a.taxonomy.tags| / |t.tags ∪ a.taxonomy.tags|   (Jaccard, descending)
    2. a.stats.success_rate                                       (descending, nulls last)
    3. a.version                                                  (descending)
    4. a.id                                                       (ascending — total order, no ties)
```

Step 4 exists so assignment is **deterministic**: the same `categorization.md` against the same library yields the same roster, every run. That is what makes the workforce gate reviewable and the implement phase resumable.

The fixed core does the matching; free `tags` do the ranking and feed the gap generator's prompt when matching fails. That is the division of labour D16 asked for.

## 4. Model policy is validated, not suggested (D18)

`model ∈ {opus, sonnet, haiku, inherit}`.

| Role | Model | Rule |
|---|---|---|
| Implementation agents (every library specialist) | `sonnet` | **Enforced.** An entry whose `taxonomy.type` contains any implementation type (`taxonomy-v0.md` §3) and whose `model ≠ sonnet` is invalid. |
| Judgment roles — council chairman, analyze/triage | `opus` | Not library entries; see `trace-schema.md` `role`. |
| Mechanical roles — deck prep, categorizer, council members | `sonnet` | as above |
| `haiku` | — | Unused in v1 (D18). A validator **warns**; it does not fail. |

A specialist wanting Opus is not a config edit. It is an argument that D18's two-plane policy is wrong for this role, made in docs/90, decided, then applied. The validator's job is to make sure that argument actually happens.

## 5. `stats` is a cache, `traces.jsonl` is the truth

`stats` is **derived** by aggregating `traces.jsonl` across features over records where `agent_id == a.id`:

- `assignments` — count of records
- `success_rate` — `count(outcome == success) / assignments`, `null` when `assignments == 0`
- `last_used` — `max(started_at)`

It is written into the entry as a cache so that matching (§3, rank step 2) needs one glob of `.claude/agents/`, not a scan of every feature's traces. A stale `stats` block degrades ranking quality; it can never corrupt correctness, because step 4 still totally orders the candidates. Never hand-edit `stats`; recompute it.

**The flywheel (D24, I-1)** is exactly this loop: a `generated` agent accumulates `stats` → clears a promotion bar → `origin: promoted`, `promoted_at` set, `source_feature` retained. Promotion is the only self-evolving behavior in year one, and it is gated on data this schema requires from day one. The promotion bar itself is M3's decision, not M0's.

## 6. Validation

An entry conforms iff:

1. Frontmatter parses as YAML; `name`, `description`, `model` present; `specseyal` present.
2. `id` matches `^agt_[a-z0-9]+(_[a-z0-9]+)*$` and is unique across `.claude/agents/`.
3. `version` is valid semver.
4. `origin ∈ {library, generated, promoted}`; `origin ∈ {generated, promoted}` ⟹ `source_feature` non-null; `origin == promoted` ⟹ `promoted_at` non-null.
5. `taxonomy.type` is a non-empty subset of `taxonomy-v0.md` types; `taxonomy.specialization` is exactly one of its specializations.
6. §4's model rule holds.
7. `body_sha256` equals the SHA-256 of the prompt body.
8. The prompt body is non-empty.

Rule 5 is why `taxonomy-v0.md` must be blessed before M3: it is a closed enum, and closed enums are load-bearing for rules 5 and §3.

## 7. Non-goals (v1)

- **No index file.** Matching globs `.claude/agents/*.md` and parses frontmatter. An index is a cache with a staleness problem, and the library is a handful of files. Revisit when the central library (I-10) makes the glob a network call.
- **No inheritance or composition** between entries. A specialist is one file.
- **No per-entry tool allowlists beyond Claude Code's `tools`.** We do not invent a second permission system.
- **No central library.** D17 is explicit: per-repo now. The `central:` block exists so the migration is a field-population, not a schema change.
