# Research — 005-graphify-context

Phase 0. Every decision cites its D-row or the spec/clarify ruling it executes. No open NEEDS CLARIFICATION remain (the four spec forks were resolved at clarify; the architecture fork at D75).

## D1 — Extractor boundary: extension-layer augmentation

- **Decision:** `005` never edits upstream `graphifyy`; it augments at the extension seam (D75).
- **Rationale:** `graphifyy` (`build_merge`/`detect_incremental`/AST `extract`) is a pip package outside the repo (`~/.local/share/uv/tools/graphifyy/…`, verified). Keeping it upstream preserves the D26/D31 migration + the D29 archive (graphify stays archivable). The augmentation lives in `extensions/graphify/` source, reinstall-survival-tested (D57/I-14).
- **Alternatives rejected:** *fork/vendor graphifyy into the repo* — too heavy for α-polish, and it moots the D29 archive by making the repo own the engine; *descope arms 1+2* — guts the cost/quality thesis the step-0 before-picture exists for.

## D2 — Coverage bounded to three edge kinds (arm 1)

- **Decision:** emit `.sh`/`.yml`/`.md` nodes + exactly **hook-registration**, **install-copy**, **script→script** edges; labeled fallback for the rest (clarify 2026-07-13; FR-002/004).
- **Rationale:** these three are precisely the plumbing relationships every dogfood feature (002–004) needed and the graph missed (the live `verify-gate.sh → implement-parallel` "No path found"). Bounded → deterministic + testable for size-M; broad semantic inference is out of scope (would be re-architecture).
- **Alternatives rejected:** *nodes + intra-file only* (leaves the every-wave call class invisible); *broad semantic coverage* (scope-creep, D73 tension).

## D3 — Freshness: hard-warn + regenerate, with a committed survivor guard (arm 2)

- **Decision:** the staleness check **hard-warns and routes to regeneration** (S14 pattern, not a hard-block gate — clarify); the incremental refresh carries the **stale-survivor guard** as a committed check (FR-005–008).
- **Rationale:** the 002 mtime failure and 003 stale-claim drift were both "nobody checked"; a mechanical, artifact-inferred check (no state file, D32) makes freshness a property. The survivor guard is the exact check step-0 ran by hand (0 caught; M3 caught 86) — promoting it to committed code is the honest fix for the #1361/#1344 hazard at the specseyal layer.
- **Alternatives rejected:** *hard gate* (new blocking surface on every graph-consuming phase — heavier than the failure warrants); *warn-only* (the 002/003 failure mode, relies on a human noticing).

## D4 — Tiered products: separate files, one generator (arm 3)

- **Decision:** three separate token-bounded products from one skill run (blast-radius / receipts / type-signal); `graphify-context.md` keeps its shape for plan/tasks/implement (FR-009/010/013).
- **Rationale:** separate products make FR-010 **structural** — a consumer opening only its file cannot pay for another's tokens; a sectioned file leaves "read only your section" as unenforced prose (the D53 lesson). D62 already proved a better-targeted slice cuts spend (−25.1% stage-1, graph pulls 3/5→1/5) — generalizing it needs real separation. One generator/one graph pass keeps the diets coherent.
- **Alternatives rejected:** *one sectioned file* (prose-enforced hygiene); *N ad-hoc generators* (drift, violates one-graph-one-pass).

## D5 — Query ceiling: enforced count cap + weightable disclosure (arm 4)

- **Decision:** a hard, tier-aware cap on member graph-query **count**, recorded in the trace **and** disclosed in the member's opinion (FR-011/012, SC-008; D74-3).
- **Rationale:** `--budget` caps per-call output but not call count; the 25–38-call loop drove 002's 3.4× cache multiplier / 5.25M-tok round. A count ceiling attacks the multiplier at its source. Disclosure-in-output extends the member-prompt's existing FR-019 reduced-grounding hook (degree-16 confirmed), so a ceiling-limited opinion is weightable, never silently truncated.
- **Alternatives rejected:** *demand-reduction only* (no guaranteed ceiling — another 38-call outlier possible); *silent truncation* (D74-3 forbids — the chairman must be able to weight it).

## D6 — Non-regression: six named fixtures (FR-013/SC-009)

- **Decision:** one committed regression fixture per live consumer.
- **Rationale:** the S04 lesson — a named guarantee without a committed test is prose (D74-4). The augmentation touches shared grounding; each consumer's fixture is its tripwire.
- **Alternatives rejected:** *a single end-to-end test* (can't localize which consumer broke).

## Open items for the council (positions taken; council reviews)

- The detach order (core=2+3+4, detach-first=1) and its fallback rationale (D74-2) — reviewed as the severability concern.
- The separate-products packaging (D4) vs a sectioned file — the council may challenge the token-bound tradeoff.
- The query-ceiling `N` — this round's per-member counts calibrate it; the council sees the uncapped baseline.
