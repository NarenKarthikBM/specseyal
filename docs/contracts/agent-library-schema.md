# Contract — Agent Library

> **Status:** 2.0 (M0, amended 2026-07-09). Normative.
> **Implements:** D2 (hybrid creator), D16 (taxonomy keys), D17 (per-repo now, central library later), D18 (model policy), D24/I-1 (flywheel), D34, **D40** (composability), **D41** (tool grants), **D43** (stats rekeyed on skill `id@version`), **D44** (curated-static bases; core-vs-elevated terms).
> **Amended by:** `docs/reviews/2026-07-09-taxonomy-v0-review.md` §3 (A-1) and §4 (A-2); flag adjudications D43–D44. **v1 (D65):** taxonomy cross-references re-pathed `taxonomy-v0.md` → `taxonomy.md`; §4 gains the `runtime_consumed` routing guard (below), the D48 guard re-homed on the modifier that superseded the `prompt` tag (`taxonomy.md` §2.4).
> **Consumed by:** the categorizer and skill builder (M3), Claude Code's own subagent and skill loaders, the central skill registry (I-10, later).

**The library's unit of storage is the skill, not the agent (D40).** An agent is not a file; it is an *assembly* performed at dispatch time:

```
agent = base model (Sonnet, per D18)
      + base specialist config   selected by (type, specialization)   ← fixed core
      + injected skill modules   selected by tags                     ← free tags
      + tool grants              aggregated from those skills         ← D41
```

Two things are stored, and only one of them evolves:

| Stored | Path | Selected by | Evolves? |
|---|---|---|---|
| **Base specialist** | `.claude/agents/<name>.md` | `(type, specialization)` — exactly one lane | No. A thin config; hand-curated; 8 × 11 possible lanes, most empty. |
| **Skill module** | `.claude/skills/<name>/SKILL.md` | `tags`, ranked | **Yes.** Authored by the skill builder, persisted by the flywheel (D24), synced to the registry (I-10). Format: `skill-module.md`. |

Both remain **native Claude Code files that happen to carry SpecSeyal metadata** — not SpecSeyal files that happen to be loadable (D34). That ordering is the whole design: the same file must dispatch today and sync to a central registry tomorrow, with no conversion step.

> **Two-kind storage — confirmed (Flag 3, adjudicated D44).** The memo states the unit of storage is the skill (§3) *and* that matching yields a base selected by `(type, specialization)` (§5.2). Both are honored by storing two entry kinds with **different evolutionary status**:
> - **Base specialists are curated-static.** They are created and changed by a human, and only under a D-row — never by the flywheel, never by the skill builder. A base is a thin, stable lane definition; it does not learn.
> - **Skills alone evolve.** The flywheel (D24) authors, versions, promotes, and persists *skills*. This is the single self-evolving component of year one, and it lives entirely on one side of this split.
>
> Base specialists do **not** disappear into assembly-from-bare-Sonnet. The `(type, specialization)` lane needs a stored home, and that home is the base.

---

## 1. The two entry formats

### 1.1 Base specialist — `.claude/agents/<name>.md`

Claude Code owns `name`, `description`, `tools`, `model`. Everything of ours nests under `specseyal:`.

```markdown
---
name: backend-service
description: Implements service-layer business logic. Base specialist for the
  (service|endpoint) × backend-service lane.
tools: Read, Write, Edit, Bash, Glob, Grep     # the immutable core — see §4.1
model: sonnet

specseyal:
  schema_version: "2.0"
  kind: base                                   # base | (skills use skill-module.md)
  id: agt_backend_service                      # stable, immutable, globally unique
  version: 1.0.0

  taxonomy:
    type: [service, endpoint]                  # list — the task types this lane accepts
    specialization: backend-service            # exactly one — its lane

  provenance:
    created: 2026-07-09
    created_by: human

  central:
    synced: false
    remote_id: null
    body_sha256: null                          # hash of the prompt body below
---

<system prompt body — lane-level discipline only; no framework or protocol knowledge>
```

A base specialist carries **no `tags`**. Tags select skills, never bases. A base that encodes `fastapi` knowledge is a skill wearing a base's clothes, and it will be wrong the first time the lane meets Django.

### 1.2 Skill module — `.claude/skills/<name>/SKILL.md`

Full format in **`skill-module.md`**. Its metadata surface, for reference here:

```yaml
specseyal:
  kind: skill
  id: skl_refactor_discipline
  version: 1.0.0
  origin: seed | generated | promoted
  taxonomy:
    tags: [refactor, blast-radius]     # what it matches on
  grants: []                           # declared tool grants (D41) — union'd at assembly
  stats: { assignments: 0, success_rate: null, last_used: null }
```

## 2. Identity, versioning, and why `id` is not `name`

| Field | Mutable? | Purpose |
|---|---|---|
| `id` | **never** | The join key. Registry, traces, and assignment records all reference `id`. |
| `name` | yes | Claude Code's dispatch handle and the filename. Humans rename things. |
| `version` | monotonic | Attributes stats to a prompt. |

`id` format: `agt_` (bases) or `skl_` (skills) + `snake_case`, stable for the life of the entry. Renaming changes the filename and `name`; `id` and accumulated `stats` survive. Had the library joined on `name`, one rename would orphan a skill's entire performance history — and the flywheel (D24) *is* that history.

**Version bump rule.** Bump when any of `{prompt body, tools/grants, model}` changes:
- prompt body → **minor** (behavior change)
- `tools`, `grants`, or `model` → **minor**
- typo/comment-only edit → **patch**
- `taxonomy.type` / `taxonomy.specialization` (bases) or `taxonomy.tags` (skills) → **major** — it now matches different tasks, and old stats no longer transfer

`body_sha256` is recomputed on every write. It is how the registry (I-10) detects that a repo edited a shared entry locally without bumping `version` — the one desync that silently corrupts cross-repo stats.

**Body, defined exactly:** everything after the frontmatter's closing `---` line and its newline, taken verbatim as UTF-8 bytes — no trimming, no normalization. Reference implementation:

```sh
sed '1,/^---$/d; 1,/^---$/d' agent.md | shasum -a 256
```

## 3. Matching and assembly (D16, D40)

Given a categorized task `t` with `t.type`, `t.specialization`, `t.tags`, `t.preserves_behavior`:

```
# ---- 1. Base: the fixed core selects exactly one lane ----
base = the b ∈ bases with  t.type ∈ b.taxonomy.type
                         ∧ t.specialization == b.taxonomy.specialization
       (lanes are unique; ∅ → generic base, and the lane is reported at the workforce gate)

# ---- 2. Skills: free tags rank the candidates ----
candidates = { s ∈ skills : s.taxonomy.tags ∩ t.tags ≠ ∅ }

if t.preserves_behavior:
    force-inject skl_refactor_discipline          # taxonomy.md §2.3 — counts against the cap

rank candidates by, in order:
    1. |t.tags ∩ s.taxonomy.tags| / |t.tags ∪ s.taxonomy.tags|   (Jaccard, descending)
    2. s.stats.success_rate                                       (descending, nulls last)
    3. s.version                                                  (descending)
    4. s.id                                                       (ascending — total order, no ties)

injected = first 3 of (forced ++ ranked)          # ASSEMBLY CAP = 3 (D40)
dropped  = the remainder — MUST be logged, never silently discarded

# ---- 3. Grants: the union, nothing more (D41) ----
grants = ⋃ { s.grants : s ∈ injected }

# ---- 4. Gap ----
if candidates = ∅ and t.tags ≠ ∅ → skill builder authors a new SKILL.md (D2, D40.2)
```

Step 4 of the ranking exists so assignment is **deterministic**: the same `categorization.md` against the same library yields the same roster, every run. That is what makes the workforce gate reviewable and the implement phase resumable.

**Guardrails (D40.4), all normative:**

- **Assembly cap: base + 3 injected skills, maximum.** The assignment step trims by tag-rank; it never exceeds. What it trims, it logs.
- **Additive only.** Skills extend the base. A skill MUST NOT override or contradict base-agent behavior. `skill-module.md` encodes this as a hard constraint on the module format, not as advice.

The fixed core selects the base; free tags select, rank, and brief the skills. That is the division of labour D16 asked for, with D40's third job (`taxonomy.md` §6) added.

## 4. Model policy is validated, not suggested (D18)

`model ∈ {opus, sonnet, haiku, inherit}`. Only **base specialists** declare a model — skills never do, because a skill is not a dispatch target.

| Role | Model | Rule |
|---|---|---|
| Implementation work (every base specialist accepting an implementation type) | `sonnet` | **Enforced.** A base whose `taxonomy.type` contains any of the 7 implementation types (`taxonomy.md` §3) and whose `model ≠ sonnet` is invalid. |
| Judgment roles — council chairman, analyze/triage | `opus` | Not library entries; see `trace-schema.md` `role`. |
| Mechanical roles — deck prep, categorizer, skill builder, council members | `sonnet` | as above |
| `haiku` | — | Unused in v1 (D18). A validator **warns**; it does not fail. |

`preserves_behavior: true` does not change the model. It injects a skill (`taxonomy.md` §2.3), and skills have no model to change.

**`runtime_consumed: true` pins the Sonnet floor at routing time (v1, D65 — `taxonomy.md` §2.4).** The rule above validates a *base* (a base accepting an implementation type must be `sonnet`). The `runtime_consumed` modifier adds the complementary *task-routing* guard: a task delivering a file consumed by an agent at runtime — mechanically `type: docs`, but implementation work — MUST NOT assemble onto a non-Sonnet `docs`-exempt base. The assembler (`assemble.py`) hard-errors on a `runtime_consumed: true` task whose selected base's `model ≠ sonnet`. This is the former D48 `prompt`-tag guard, re-homed on the modifier that superseded the tag (`taxonomy.md` §2.4, verdict 10); the `docs`-model exemption now applies only to `runtime_consumed: false` documentation.

A specialist wanting Opus is not a config edit. It is an argument that D18's two-plane policy is wrong for this role, made in docs/90, decided, then applied. The validator's job is to make sure that argument actually happens.

### 4.1 Tool grants (D41) — two defined terms (Flag 4, adjudicated D44)

Tool access splits into two named tiers. These are **defined terms**, used with these exact meanings everywhere in the contracts:

> **Core toolset** — the fixed set `{Read, Write, Edit, Bash, Glob, Grep}`. Every base specialist carries it, unmodified. Bases do not differ in tools; they differ in prompt. The core is never listed in a grant set or a trace — it is assumed, so only elevation is auditable.
>
> **Elevated grant** — any tool access *beyond* the core. **Web search is the first of them.** An elevated grant is never an agent-level default: it is *declared by a skill* (`skill-module.md` §4), and it reaches a dispatch only by that skill being injected.

- The assembled agent's **elevated-grant set** is the **union** of its injected skills' declarations (§3 step 3). A skill may not declare a core tool as a grant (validation rule 9) — that would make the audit trail lie about where access came from.
- **The workforce-gate roster MUST display each assembled agent's elevated-grant set.** Approving the roster is approving network access. This binds M3 (the roster artifact) and M5 (the gate view), and the approved set is recorded on every dispatch's trace as `elevated_grants` (D43).

**A-2's "not an agent-level default" — clarified (D44):** it governs *elevated* access only. It never meant a base cannot `Read` a file; a base without the core toolset could do nothing at all. It means elevation — the network, and whatever follows it — is skill-declared and gate-visible, which is the audit property A-2 exists to secure.

## 5. `stats` is a cache, `traces.jsonl` is the truth

`stats` lives on **skills** (bases do not evolve, so they do not accumulate). It is derived by aggregating `traces.jsonl` across features over the records in which **this exact skill version** was injected — read straight off each record's `skills` array (`trace-schema.md` §1, added by D43):

- `assignments` — `count(r : {id: a.id, version: a.version} ∈ r.skills)`
- `success_rate` — `count(those with outcome == success) / assignments`, `null` when `assignments == 0`
- `last_used` — `max(r.started_at)` over those records

The aggregation keys on `id@version`, matching `trace-schema.md` §5's `skill_success`, and for the reason given there: crediting the base (`agent_id`) would smear each skill's record across every other skill it was co-injected with, and ignoring `version` would let a regressed prompt coast on an older one's numbers (D17/D24). A skill is credited only in *combination* with its assembly-mates — honest, and sufficient for a promotion bar (see the isolation note in `trace-schema.md` §5).

`stats` is cached into the entry so that ranking (§3, step 2) needs one glob of `.claude/skills/`, not a scan of every feature's traces. A stale `stats` block degrades ranking quality; it can never corrupt correctness, because ranking step 4 still totally orders the candidates. Never hand-edit `stats`; recompute it.

**The flywheel (D24, I-1)** is this loop, running on skills: a `generated` skill accumulates `stats` → clears a promotion bar → `origin: promoted`. Promotion is the only self-evolving behavior in year one. The promotion bar is M3's decision, not M0's.

> **Attribution resolved (D43).** An earlier draft of this section flagged the flywheel as BLOCKED: under D40 the dispatched agent is an assembly, and the pre-D43 trace record carried no field naming which skills were injected, so `stats` could not be computed. D43 added `skills: [{id, version}]` (and `elevated_grants`) to the trace record, and the aggregation above now reads it directly. The flywheel turns.

## 6. Validation

An entry conforms iff:

1. Frontmatter parses as YAML; `name`, `description` present; `specseyal` present; `model` present iff `kind: base`.
2. `id` matches `^agt_[a-z0-9]+(_[a-z0-9]+)*$` (bases) or `^skl_[a-z0-9]+(_[a-z0-9]+)*$` (skills), and is unique across the library.
3. `version` is valid semver.
4. Skills: `origin ∈ {seed, generated, promoted}`; `origin ∈ {generated, promoted}` ⟹ `source_feature` non-null; `origin == promoted` ⟹ `promoted_at` non-null. Bases have no `origin`.
5. **Bases:** `taxonomy.type` is a non-empty subset of `taxonomy.md`'s **8** types; `taxonomy.specialization` is exactly one of its **11** specializations; the `(type, specialization)` lane is unique across bases. **Skills:** `taxonomy.tags` is non-empty; bases carry no `tags`.
6. §4's model rule holds (bases only). §4.1's core toolset is present and unmodified.
7. `body_sha256` equals the SHA-256 of the prompt body.
8. The prompt body is non-empty.
9. Skills: `grants` is a (possibly empty) list; no skill grants a tool the base's core already provides.

Rule 5 is why `taxonomy.md` had to be blessed before M3: it is a closed enum, and closed enums are load-bearing for rules 5 and §3. It now is (2026-07-09).

## 7. Non-goals (v1)

- **No index file.** Matching globs `.claude/agents/*.md` and `.claude/skills/*/SKILL.md` and parses frontmatter. An index is a cache with a staleness problem. Revisit when the registry (I-10) makes the glob a network call.
- **No skill-to-skill composition.** Skills compose onto a base, never onto each other. The assembly cap of 3 is the only depth there is.
- **No second permission system.** Grants (§4.1) name Claude Code's own tools. We do not invent our own.
- **No central registry.** D17 is explicit: per-repo now. The `central:` block exists so the migration is a field-population, not a schema change.
