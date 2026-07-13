# Graphify Context — 005-graphify-context

_Generated 2026-07-13 from `graphify-out/graph.json` (1611 nodes, 2674 edges, scope: repo — the fresh D59 step-0 baseline, `graph-baseline.json`). Stale after large merges — regenerate with `/speckit-graphify-context`._

> **⚠ This feature's grounding is doubly reduced (S22 / I-13 / D10), and this file is Exhibit A.** `005` changes (a) the graphify **extension** it is generated *by*, and (b) targets whose relationships the graph **cannot see**. Concretely, verified live against this baseline:
> - `explain "verify-gate.sh"` → **degree 5, every edge intra-file** (`contains` + `defines` die/mark_stale/usage/count_lines). **Zero cross-file edges.**
> - `path "verify-gate.sh" "implement-parallel"` → **"No path found"** — though `implement-parallel` calls `verify-gate.sh` **every wave**. That is arm-1's exact target relationship, and the graph is blind to it *today*.
> - The upstream `graphifyy` extractor (`build_merge` / `detect_incremental` / AST `extract`) — arm-2's subject — is a **pip package outside the repo**, so it has **no nodes at all** (D75).
>
> **Every blast-radius claim below on a `.sh` / `.yml` / upstream-`.py` file is engineer assertion re-derived by reading source, NOT graph fact** (S22). The concept/rationale layer (277 rationale + 541 concept nodes — the spec, D-rows, contracts) grounds well; the code-plumbing layer does not.

## Graph scope
- Repo graph: `graphify-out/graph.json` (gitignored working copy, D45); committed baseline `specs/005-graphify-context/graph-baseline.json` (D59).
- This run used: **repo**.

## Relevant existing modules (the six live consumers + the arm homes)
- `.claude/skills/speckit-graphify-context/SKILL.md` — **arm-3 home**; the one-diet context generator (degree 2: referenced by tasks-graph + implement-parallel). Source of record: `extensions/graphify/skills/speckit-graphify-context/`.
- `extensions/graphify/skills/speckit-implement-parallel/` · `speckit-tasks-graph/` — two live consumers (read `graphify-context.md`).
- `extensions/council/extension/templates/member-prompt.md` — **arm-4 home**; the council member prompt (degree 16; already references `member_lenses`, `plan.md`, and the **reduced-grounding note (FR-019)** — the D74-3 disclosure hook to extend).
- `extensions/council/…/deck-prep` + `categorizer` (workforce ext) — the other consumers (receipts diet; type-signal diet).
- `.specify/extensions.yml` — the hook registry (arm-1 "hook registration" edge source); the pipeline's highest-collision shared file.

## Blast radius (per anchor) — code-layer entries are ASSERTION, not graph fact (I-13)
- **verify-gate.sh** (`.specify/extensions/git/scripts/verify-gate.sh`) — graph sees degree 5, all intra-file. Real callers (`implement-parallel` per wave, `before_implement`) are **graph-invisible**. *(assertion — arm-1 fixes exactly this class.)*
- **speckit-graphify-context skill** (`extensions/graphify/skills/…/SKILL.md`) — depended-on-by tasks-graph + implement-parallel *(graph-grounded)*; arm-3 modifies its generator to emit ≥3 products.
- **member-prompt.md** (`extensions/council/…/templates/`) — references deck, `member_lenses`, `plan.md`, FR-019 reduced-grounding *(graph-grounded)*; arm-4 adds the query ceiling + ceiling-hit disclosure here.
- **install.sh / extension.yml** (`extensions/graphify/`) — arm-1's "install-copy" + "hook-registration" edge sources; **no `.sh`/`.yml` cross-file edges in the graph** *(assertion)*.
- **upstream `graphifyy` build/detect/extract** — **absent from the graph** (out-of-repo pip pkg, D75); arm-2 wraps them from the extension seam, never edits them.

## Shared / mutable files (collision watch)
> Serialize any tasks that touch these — never co-schedule two in one parallel wave.
- `.specify/extensions.yml` — the hook registry; every extension's installer merges into it (flock/atomic-rename). Highest collision point. *(assertion — no graph edges, but the M2 live bug is on record, R1-S17.)*
- `extensions/graphify/skills/speckit-graphify-context/SKILL.md` + its installed copy under `.claude/skills/` — arm-3's central edit; the installer `rm -rf`+`cp`s it (D57 — edits live in `extensions/graphify/` **source**, reinstall-survival-tested).
- `extensions/council/extension/templates/member-prompt.md` + installed `.specify/extensions/council/` copy — arm-4's edit (same D57 source-edit rule).

## Patterns to follow
- **Extension seam, source-owned (D57 / I-14):** every arm-1..4 edit lives in `extensions/<name>/` **source** and survives a reinstall (`extensions/git/test/run.sh §3` is the model); never a source edit to another extension's installer-overwritten file.
- **Mechanical, no-LLM augmentation (arm 1/2):** the post-extraction pass and the freshness/merge guard are deterministic scripts (like `commit.sh` / `verify-gate.sh`) — no model call, no trace, no `ANTHROPIC_API_KEY` (constitution V).
- **Fail-closed + labeled fallback (S22):** where a `.sh`/`.yml` relationship still can't be modeled, emit the labeled-assertion fallback, never a silent gap (taxonomy §1).
- **Disposable grounding, not phase artifact:** these context products regenerate from the graph; they are not artifacts-of-record (so tiering to ≥3 products does not engage principle I's one-artifact-per-phase rule).
