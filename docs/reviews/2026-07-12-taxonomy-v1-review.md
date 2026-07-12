# Review Memo — Taxonomy v0 → v1 · **BLESSED**

> **Date:** 2026-07-12
> **Trigger:** taxonomy §8 three-feature rule — 001-council, 002-speckit-ext-git, 003-workforce categorized (~75 tasks, two live gate types, one live council).
> **Evidence:** `docs/reviews/taxonomy-v0-evidence.md` (12 booked items, positions taken here, not there).
> **Suggested repo location:** `docs/reviews/2026-07-12-taxonomy-v1-review.md`
> **Numbering:** `D-next` placeholders — the applying session substitutes actual next-available numbers (log last seen at D64) and back-references from every touched file.

---

## 1. Verdicts (all twelve)

| # | Item | Verdict |
|---|---|---|
| 1 | OQ4 test-scope boundary | **Upheld unchanged** — applied consistently ×3 features; the "softest boundary" concern never materialized. |
| 2 | OQ6 overfit (`ai-agents`/`devtools-cli`) | **Retained, caveat carried** — dogfood evidence cannot acquit; explicitly untested until the first non-SpecSeyal install (post-α). |
| 3 | Endpoint↔service body fusion | **Upheld** — type = deliverable. Codified as a categorizer note: slash commands are `endpoint`; body flavor rides in tags. |
| 4 | `preserves_behavior` | **Retained as marked hypothesis** — zero refactor tasks in three greenfield features; no evidence either way. |
| 5 | Assembly cap ≤3 | **Upheld** — ceiling touched once (003 T008), exceeded-needed never. |
| 6 | §1 derivability claim (I-13 class) | **Amended for honesty** — type is graph-derived *where the graph covers the files*, with a documented path-convention fallback otherwise (three features' actual practice). Graph coverage of `.sh/.yml/.md` remains a graphify enhancement (I-13), not a taxonomy patch. |
| 7 | `docs × devtools-cli` empty lane | **Widen the base** — `agt_devtools_cli` accepts `docs`. Base config edit; this memo is the D-row a curated-static base edit requires (D17/Flag-3). |
| 8 | Provisional bases | **Kept provisional** — exercise date effectively scheduled: M5's manager backend is `backend-service × data-persistence` work. |
| 9 | Small-feature general cap | **Adopt `max(1, floor(0.2n))`** — the v0 candidate, adopted on evidence: general ran 0/23 and 0/32; the floor costs nothing and deletes a formal absurdity before M4 (S-sized) meets the edge. |
| 10 | Prompt assets (owner-delegated) | **Promote to modifier: `runtime_consumed: true`** — derivation: the file is loaded or rendered by an agent at runtime. Consequences, structural: the docs-only model exemption is inapplicable; the D18 Sonnet floor self-enforces (D48 becomes this modifier's enforcement, not a tag convention). Grounds: taxonomy §6's own promotion rule — D48's `prompt` tag was gating assignment, and a tag that gates has earned the fixed core; modifier-over-type per the OQ1 precedent. |
| 11 | Flywheel economics (owner-ruled) | **Gap-batching primary + evidence-backed seeding only** — the builder clusters ∅-matches by tag similarity and authors one skill per cluster (003's 14 gaps ≈ 3–4 dispatches). Speculative mass-seeding rejected (violates evidence-based curation); pure 1:1 firing rejected (network-session fan-out on every sparse feature). |
| 12 | I-19 auto-mode drift (owner-ruled) | **Standalone workforce-auto is valid (P4 wins over FR-020's coupling) WITH a grant tripwire: any elevated grant in the roster forces that gate to human regardless of profile.** D8/D9 never coupled the gates; A-2's display duty demands the tripwire. FR-020 amended to match, with D-row pointer. |

## 2. Mechanical change list for the applying session

Order matters; stop-and-flag where structure resists.

1. **Taxonomy contract:** `git mv` `docs/contracts/taxonomy-v0.md` → `taxonomy.md`, header **v1.0 — BLESSED 2026-07-12**, sweep all references (grep-verified). Apply: §1 derivability amendment (verdict 6); new modifier subsection `runtime_consumed` with derivation rule + structural consequences (verdict 10) alongside `preserves_behavior`; §4 cap → `max(1, floor(0.2n))` (verdict 9); categorizer note per verdict 3; OQ ledger updated per verdicts 1/2/4; §8 sets the v1→v2 trigger: **first non-SpecSeyal repo categorized, or M5 close, whichever first**.
2. **Workforce extension code + tests:** categorizer detects `runtime_consumed` (path/consumption heuristics + tag fallback) and applies the floor'd cap; assembler enforces the modifier's Sonnet floor structurally (retire the tag-convention check); **gap-batching** in the gap handoff (tag-similarity clustering, one builder dispatch per cluster, cluster membership recorded in the roster); **grant tripwire** in the workforce-approve path (elevated grants + auto mode → force human, loudly). Tests for each; fixture suite + `test/run.sh` re-run green.
3. **Base config:** `agt_devtools_cli` accepts `docs` (version bump per library schema; cite this memo's D-row).
4. **003 spec FR-020:** amend to the verdict-12 ruling with D-row pointer (S16-class correction).
5. **docs/90:** three D-rows — taxonomy v1 blessed (verdicts 1–10), gap-batching economics (verdict 11), auto-mode + tripwire (verdict 12, resolves I-19); session-log row; evidence dossier marked consumed.
6. **Out of scope, carried:** I-16/I-17 (git-ext freshness defects — git-ext follow-up, not taxonomy); I-13 (graphify coverage — graphify backlog).
7. **Stop before M4.** Present diff summary + substituted D-numbers.

## 3. Sign-off

| Role | Name | Disposition | Date |
|---|---|---|---|
| Product owner | **Babu** | Verdicts 11–12 ruled; verdict 10 delegated and adopted; memo blessed | 2026-07-12 |
| Review facilitator | Claude (SpecSeyal sessions) | Verdicts 1–9 ruled on evidence; memo prepared | 2026-07-12 |

*On application of §2, taxonomy v1 is normative and M4 is unblocked.*
