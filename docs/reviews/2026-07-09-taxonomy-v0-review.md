# Review Memo — Taxonomy v0 · **BLESSED WITH AMENDMENTS**

> **Date:** 2026-07-09
> **Reviewed:** `docs/contracts/taxonomy-v0.md` (status 0.1 DRAFT)
> **Verdict:** **Blessed** — the M0 exit criterion "taxonomy v0 reviewed and blessed by Babu" (docs/95 Part 3) is **satisfied upon application of the changes in §3–§5 below.**
> **Suggested location in repo:** `docs/reviews/2026-07-09-taxonomy-v0-review.md`
> **Numbering note:** this memo uses `D-next`, `D-next+1`, `D-next+2` because the repo's decision log has advanced past the brainstorm's D30 (the draft cites D36). The applying session MUST substitute the actual next available D-numbers in docs/90 and back-reference them from every file edited.

---

## 1. Overall assessment

The draft is approved on its merits: the derivation-rule acceptance test for types, the exclusion of an `integration` type on the deliverable-vs-scheduling distinction, the evidence-fitting against graphify's real example output, and the honest flagging of unexercised enum values as hypotheses are all endorsed as-is. The v0→v1 trigger in §8 (three real dogfood features) stands.

## 2. OQ verdicts (all six confirmed by Babu, 2026-07-09)

| OQ | Verdict | Consequence |
|---|---|---|
| **OQ1** | **OVERRULED** — `refactor` is a **modifier**, not a type | Remove `refactor` from the type enum (**9 → 8 types**). Add boolean task field `preserves_behavior`, inheriting the old derivation rule verbatim: *true when every file in `files=` already exists in the graph (`mutates=` has no `(new)`) and the task adds no new public surface.* When true, the **refactor-discipline skill is auto-injected** at assembly (see §3). |
| **OQ2** | Upheld — exactly one specialization | Lost cross-cutting signal is recovered via tag→skill injection (§3), not via `secondary[]`. Matching stays deterministic. |
| **OQ3** | Upheld, **cap adopted** | `general` stays as the honest escape hatch, capped at **20% of a feature's tasks**. Categorization exceeding the cap **fails** and must be redone with better evidence. Rule lives in taxonomy §4. |
| **OQ4** | Upheld — `T030` is `qa-automation` | Scope-based boundary accepted for v0; explicitly re-examined at the v0→v1 three-feature review. |
| **OQ5** | Upheld — `scaffold` and `infra` stay separate | Composability removes the cost that motivated merging: near-empty *skill* lanes are cheap; near-empty *agent* lanes were not. |
| **OQ6** | Upheld — `ai-agents` and `devtools-cli` stay | Dogfooding is decisive: SpecSeyal's own tasks dominate early features. Per-repo library (D17) contains the overfit; v0→v1 review re-tests it. |

**Resulting cardinality: 8 types × 11 specializations**, `general` capped.

## 3. Amendment A-1 — Composability (blessed by Babu, 2026-07-09) → `D-next`

**The library's unit of storage is the SKILL, not the agent. An agent is an assembly at dispatch time:**

```
agent = base (Sonnet, per D18)
      + base specialist config selected by (type, specialization)   ← fixed core
      + injected skill modules selected by tags                     ← free tags
      + declared tool grants aggregated from those skills
```

Consequences, all normative:

1. **Taxonomy roles:** the fixed core selects the base; free tags gain a **third job** — skill selection — alongside ranking and gap-briefing (amends taxonomy §6).
2. **The gap generator becomes a skill builder.** On ∅-match it authors a `SKILL.md` module (format: §5), not a whole agent. The flywheel (D24) persists skills.
3. **I-10 (central-library MCP) is reframed as a skill registry.** Update its I-row in docs/90 accordingly.
4. **Guardrails:**
   - **Assembly cap:** base + **3** injected skills maximum per dispatch. The assignment step must trim by tag-rank, never exceed.
   - **Additive-only:** skills extend the base; they MUST NOT override or contradict base-agent behavior. The skill-module format encodes this (§5).
5. **`preserves_behavior: true` auto-injects the refactor-discipline skill** (closes OQ1's "differently-disciplined agent" requirement without a type).

## 4. Amendment A-2 — Tool grants, including web search → `D-next+1`

- Tool access (web search first among them) is a **per-skill declared grant**, not an agent-level default. Example: a `scaffold` dependency-version-lookup skill declares `web_search`; a `data-model` skill declares nothing.
- The assembled agent's grant set = union of its skills' declarations.
- **The workforce-gate roster (D9) MUST display each assembled agent's grant set** — approving the roster is also approving network access. This is a binding requirement on M3 (roster artifact) and M5 (gate view).

## 5. Mechanical change list for the applying session

Work in this order; where a target file's actual structure resists an edit, **stop and flag rather than improvise**.

1. **`docs/contracts/taxonomy-v0.md`:**
   a. §2: delete the `refactor` row → 8 types. Add a new subsection defining the `preserves_behavior` modifier with the derivation rule from §2 verbatim, and the auto-injection consequence (§3.5 above).
   b. §3: implementation types become `scaffold · data-model · service · endpoint · ui · test · infra` (7 values); note that `preserves_behavior: true` tasks remain implementation tasks.
   c. §4: append the 20% `general` cap + categorization-failure rule to the `general` row.
   d. §6: add skill selection as the tags' third job; reference this memo.
   e. §7: mark all six OQs resolved with pointers to this memo; header status → **`v0 — BLESSED (normative), 2026-07-09`**.
2. **`docs/contracts/agent-library-schema.md`:** reconcile with A-1 — entries store skills (id, version, taxonomy tags, tool grants, module path); §3 matching = `(type, specialization)` → base, tag-Jaccard → skill ranking under the assembly cap; §6 rule 5 validates against **8** types; §4 model rule unchanged in spirit (Sonnet for implementation-type work per D18).
3. **Create `docs/contracts/skill-module.md`:** the skill builder's output format — aligned with Claude Code native `SKILL.md` conventions; required metadata (stable id, version per D17, taxonomy tags, declared tool grants); the additive-only rule stated as a hard constraint; the refactor-discipline skill specified as the first seed module.
4. **`docs/00` §4.3 (Agent layer):** rewrite to the skill-library model (assembly equation, guardrails, skill registry framing of I-10).
5. **`docs/90`:** append `D-next` (A-1), `D-next+1` (A-2), `D-next+2` (OQ verdicts + 8×11 cardinality + general cap); update I-10's row; add a session-log entry citing this memo.
6. **Revalidate `specs/000-sample/`** against the amended contracts; fix the sample, not the contracts.
7. **Stop.** Present a diff summary and the substituted D-numbers. Do not begin M1.

## 6. Sign-off

| Role | Name | Disposition | Date |
|---|---|---|---|
| Product owner / reviewer | **Babu** | Six OQ verdicts confirmed; amendments A-1, A-2 blessed | 2026-07-09 |
| Review facilitator | Claude (SpecSeyal brainstorm session) | Drafted verdicts and amendments; memo prepared for mechanical application | 2026-07-09 |

*This memo is the normative record of the taxonomy v0 review. On application of §5, taxonomy v0 is blessed and the M0 exit gate closes.*
