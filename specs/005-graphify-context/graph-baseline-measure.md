# D59 Baseline Regen — MEASURED (005 step-0, the before-picture)

**Date:** 2026-07-13 · **Feature:** `005-graphify-context` · **Snapshot:** `graph-baseline.json` (1611 nodes)

> This is the **before-picture** the whole feature exists to change. `005` is built to retire this ritual — the incremental-freshness arm (spec FR-005–008) turns a full-corpus regen into a partial-cost partial-refresh, and the freshness check (FR-005) makes staleness mechanically caught instead of assumed. The **completion report's before/after comparison starts from these numbers.** Per owner directive (Phase-2 step-0): *the last full-ritual regen the current machinery should ever need.*

## What the ritual cost (this run)

| Dimension | Measurement |
|---|---|
| **Trigger** | `/graphify . --update` — but `detect_incremental` saw **76 changed files** (9 code, 67 docs), **580,866 words**, 0 deletions since the M4 manifest (12 Jul 17:08) — the familiar "most of the corpus moved" degeneration (M3 saw 202, M4 saw 156) |
| **AST (structural)** | 79 nodes / 140 edges over 9 code files — **deterministic, free, ~seconds** |
| **Semantic (the expensive arm)** | **0 cache hits** → all 67 changed docs re-extracted by **5 parallel general-purpose subagents** |
| **Semantic token spend** | **~753,633 tokens** (I-21 aggregate — Agent-tool dispatches return an aggregate only, no input/output/cache split; not fabricated, D47). Per-chunk: 146,761 · 131,636 · 185,781 · 151,412 · 138,043 |
| **Wall-clock** | **~11 min** subagent fan-out (5-way parallel; longest chunk the `docs/90` D1–D74 giant at ~10.8m) + merge/build; **~19 min** end-to-end (detect → snapshot, incl. orchestration) |
| **Sessions** | 5 fresh subagent sessions dispatched (the D59 "fresh session, not this session's tail" cost) |

## Result — the fresh baseline

- **1611 nodes / 2674 edges / 141 communities** — typed **519 code · 541 concept · 277 rationale · 274 document**
- **Stale survivors caught: 0** · duplicate IDs: 0 — the `build_merge` replace-on-re-extract (root-relativized, #1361/#1344) was **clean this run** (unlike M3's **86** stale council-node survivors that forced a clean rebuild; like M4's clean merge). A stale-survivor check ran explicitly (changed-file nodes absent from the fresh extraction): **none**.
- **NEW extraction (changed files only): 446 nodes / 676 edges** (79 AST-free + 367 semantic, 6 cross-chunk dupes deduped) folded into the 1343-node base.
- God nodes: `assemble.py`, `speckit-implement-parallel`, `speckit-testing`, `FrontmatterError`, `run.sh`, the council member/chairman prompts, `speckit.agent-assign`, `seed_library` manifest.

## Node-count curve (the growth this feature must make sustainable)

| Milestone | Nodes | Edges | Comm | Note |
|---|---|---|---|---|
| M1 (`001`) | 638 | 574 | 76 | flat doc/code, no concept/rationale typing |
| M2 (`002`) | 1013 | 917 | — | AST-only, deterministic |
| M3 (`003`) | 497 | 888 | 44 | **rebuilt clean** (86 stale survivors pruned), higher-signal typed |
| M4 (`004`) | 1343 | 2177 | 130 | taxonomy-v1 + deeper 6-way extraction |
| **005 (this)** | **1611** | **2674** | **141** | 004-close + 005-spec + docs/90 D69–D74; 5-way extraction |

**The curve is the problem.** Every feature to date has paid ~1M semantic tokens + ~15–20 min + N fresh sessions to re-ground, because the incremental path degenerates to full-corpus whenever "most files changed" — which is *every* feature, since docs/90 alone changes each session. `005` FR-007/008 make the incremental refresh trustworthy (so a real partial change stays partial); FR-005/006 make staleness a checked property with regenerate-don't-rewrite. **This regen is the last time the ritual should cost this much.**
