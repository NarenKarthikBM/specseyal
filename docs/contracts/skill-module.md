# Contract — Skill Module (`SKILL.md`)

> **Status:** 1.0 (2026-07-09). Normative.
> **Implements:** **D40** (composability — the library's unit of storage), **D41** (tool grants), D2 (gap generator → skill builder), D17 (registry-ready IDs), D24/I-1 (flywheel).
> **Created by:** `docs/reviews/2026-07-09-taxonomy-v0-review.md` §5.3.
> **Location:** `.claude/skills/<name>/SKILL.md` — Claude Code's native skill path.
> **Consumed by:** the assembly step (`agent-library-schema.md` §3), the workforce gate (D9), the skill registry (I-10).

A skill module is the **skill builder's output** and the library's unit of storage. It is a native Claude Code `SKILL.md` that carries SpecSeyal metadata — loadable as-is, no conversion step (D34).

Where the old design had the gap generator author a whole bespoke agent, it now authors *one of these* (D40.2). That is the difference between growing a library of 88 near-empty lanes and growing a library of composable parts.

---

## 1. Format

```markdown
---
name: refactor-discipline
description: Behavior-preserving edits to existing code. Injected automatically when a task's
  preserves_behavior is true. Bounds the blast radius; adds no public surface.

specseyal:
  schema_version: "1.0"
  kind: skill
  id: skl_refactor_discipline           # stable, immutable — the registry join key
  version: 1.0.0
  origin: seed                          # seed | generated | promoted

  taxonomy:
    tags: [refactor, blast-radius, behavior-preserving]

  grants: []                            # declared tool grants (D41). [] = core only.

  provenance:
    created: 2026-07-09
    created_by: human                   # human | skill-builder
    source_feature: null                # specs/NNN-… for origin=generated|promoted
    promoted_at: null

  stats:                                # DERIVED from traces. Cache, not truth.
    assignments: 0                      # derived per id@version from trace.skills (D43)
    success_rate: null
    last_used: null

  central:
    synced: false
    remote_id: null
    body_sha256: 
---

<module body — additive instructions only. See §3.>
```

`kind: skill` is required and distinguishes the entry from a base specialist (`agent-library-schema.md` §1.1). `id` is prefixed `skl_`; bases are prefixed `agt_`. Skills declare **no `model`** — a skill is not a dispatch target, so it has no model to declare (`agent-library-schema.md` §4).

## 2. Selection

A skill is a candidate iff its `taxonomy.tags` intersect the task's `tags`. Candidates are ranked by tag-Jaccard, then `stats.success_rate`, then `version`, then `id` — and the top **3** are injected onto the base specialist. The full algorithm, including the forced injection below, is `agent-library-schema.md` §3.

Skills are selected by **tags only**. A skill never carries `type` or `specialization`: those select the base. A skill that wants to restrict itself to one lane is a base specialist that has misunderstood itself.

## 3. The additive-only rule — a hard constraint, not advice

> **A skill module MUST extend the base specialist. It MUST NOT override, contradict, weaken, or countermand base-agent behavior.** (D40.4)

Assembly is a union, not an override chain: three skills injected in any order must produce the same agent. Any module that says "ignore the base's instruction to X" makes assembly order-dependent, and order-dependent assembly is not deterministic — which would break the workforce gate's whole claim to be reviewable.

The format encodes this rather than trusting it:

| # | Constraint | Rejected at validation |
|---|---|---|
| S1 | The body contains no negation of a base instruction — no "ignore", "instead of", "override", "disregard", "rather than the base" | yes |
| S2 | The body declares no model, no reasoning effort, no dispatch behavior | yes |
| S3 | The body's imperatives are **additional** obligations, never relaxations. A skill may forbid more; it may never permit more. | yes |
| S4 | Two skills injected together must not issue contradictory imperatives. Detectable only pairwise, at authoring time. | **no — flagged** |

S4 is honest about its own limits: nothing in this contract prevents `skl_move_fast` and `skl_be_careful` from being injected together. The assembly cap of 3 bounds the blast radius of that failure; the workforce gate is where a human sees the roster and catches it. This is a known hole, not an oversight.

**S3 is the one that matters.** A skill that may only *add* obligations can never make an agent less safe than its base. That is what makes injecting three of them, sight unseen, an acceptable thing to do.

## 4. Tool grants (D41)

- `grants` is a list of Claude Code tool names the module requires **beyond the base's immutable core** (`Read, Write, Edit, Bash, Glob, Grep` — `agent-library-schema.md` §4.1).
- `grants: []` means the skill needs nothing extra. Most skills are `[]`.
- The assembled agent's grant set is the **union** of its injected skills' declarations. Nothing else grants anything.
- **Web search is a grant, not a default.** A skill that looks up dependency versions declares `grants: [web_search]`. A skill that writes a migration declares nothing, and the agent it assembles into cannot reach the network.
- **Every grant is displayed on the workforce-gate roster.** Approving the roster is approving network access (D41). A grant that reaches an agent without appearing on the roster is a contract violation, not a UI bug.

Grants are **declared, not inherited**: a skill may not grant a tool the base already provides (validation rule 9, `agent-library-schema.md` §6). Redundant grants make the roster's grant column a lie about where access came from.

## 5. Seed module — `refactor-discipline`

**The first skill module, and the reason OQ1 could be overruled** (`taxonomy-v0.md` §2.3). It carries the discipline that `refactor`-as-a-type existed to supply, without costing a type.

Auto-injected — not tag-matched — whenever `preserves_behavior: true`. It counts against the assembly cap of 3, so a behavior-preserving task with many tags gets two tag-selected skills, not three.

```markdown
---
name: refactor-discipline
description: Behavior-preserving edits to existing code. Injected automatically when a task's
  preserves_behavior is true. Bounds the blast radius; adds no public surface.

specseyal:
  schema_version: "1.0"
  kind: skill
  id: skl_refactor_discipline
  version: 1.0.0
  origin: seed
  taxonomy:
    tags: [refactor, blast-radius, behavior-preserving]
  grants: []
  provenance: { created: 2026-07-09, created_by: human, source_feature: null, promoted_at: null }
  stats: { assignments: 0, success_rate: null, last_used: null }
  central: { synced: false, remote_id: null, body_sha256: null }
---

This task preserves behavior. Every file you touch already exists; you add no public surface.

In addition to your base instructions:

- **Add no new public surface.** No new exported symbol, route, table, CLI flag, or config key.
  If the task seems to need one, it is not a behavior-preserving task — stop and say so.
- **Stay inside the blast radius.** Your graphify blast radius names the files that depend on
  what you are changing. Every one of them must still compile and pass its tests. Do not widen
  the change to make your edit easier.
- **Preserve observable behavior exactly** — return values, error types, side effects, ordering,
  and timing characteristics that anything downstream could depend on.
- **Change no test to make your change pass.** A test that fails after a behavior-preserving
  edit has found a behavior you did not preserve. Fix the code, not the test.
- **Land it in one commit** whose message states what was preserved, not merely what moved.
```

Note what the body does **not** do: it never tells the agent to ignore its base, never relaxes an obligation, and adds no grant. It only forbids more (S3). That is what a compliant skill looks like.

## 6. Validation

A module conforms iff:

1. `SKILL.md` frontmatter parses as YAML; `name`, `description`, `specseyal` present; **no `model` key** (§1).
2. `specseyal.kind == "skill"`; `id` matches `^skl_[a-z0-9]+(_[a-z0-9]+)*$` and is unique across `.claude/skills/`.
3. `version` is valid semver; `schema_version` is `"1.0"`.
4. `origin ∈ {seed, generated, promoted}`; `origin ∈ {generated, promoted}` ⟹ `provenance.source_feature` non-null; `origin == promoted` ⟹ `provenance.promoted_at` non-null.
5. `taxonomy.tags` is a non-empty list of lowercase kebab-case strings. **No `type`, no `specialization`** (§2).
6. `grants` is a list of Claude Code tool names, disjoint from the base's immutable core (§4).
7. `central.body_sha256` equals the SHA-256 of the module body — same definition as `agent-library-schema.md` §2.
8. The module body is non-empty and satisfies S1, S2, S3 (§3).

## 7. Non-goals (v1)

- **No skill-to-skill composition.** Skills compose onto a base, never onto each other (`agent-library-schema.md` §7).
- **No conditional bodies.** A skill's text does not branch on the task. If it needs to, it is two skills.
- **No versioned dependency between skills.** `skl_a` may not require `skl_b`. The assembly cap makes dependency graphs unrepresentable, deliberately.
- **No automatic S4 detection.** Contradictory skill pairs are caught by the human at the workforce gate (§3).
