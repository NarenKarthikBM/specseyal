# Graphify Context — 008-pre-public-maintenance

_Generated 2026-07-16T23:42:45Z from `graphify-out/graph.json` (4863 nodes, 5788 edges, scope: repo). Stale after large merges — regenerate with `/speckit-graphify-context`._

## Graph scope
- Repo graph: `/Users/narenkarthikbm/Coding/specseyal/graphify-out/graph.json`
- Merged stack graph: `../graphify-out/graph.json` — **absent** (single-repo feature; not used)
- This run used: **repo**

## Relevant existing modules
- `extensions/graphify/extension/scripts/augment_merge.py` — hook-command → command-node parser; owns `parse_hook_commands()` (I-26 fix site)
- `extensions/git/install.sh` — git-ext installer; defines `print_manual_block()` (I-23 fix site)
- `extensions/git/extension/extension.yml` — git-ext hook manifest; the divergence-guard source-of-truth (I-23)
- `extensions/git/test/run.sh` — git-ext test harness; §4-style static-grep precedent for the I-23 divergence guard
- `extensions/workforce/extension/scripts/validate-profile.py` — closed-contract, dependency-free validator (degree 27); the **pattern to follow** for the I-11 conformance checker
- `extensions/workforce/extension/scripts/validate-categorization.py`, `validate-skill.py` — the other per-artifact validators the checker must compose/delegate to, not duplicate (FR-008)
- `extensions/graphify/skills/speckit-implement-parallel/SKILL.md` — parallel trace writer; the `artifact:` field null-out site (I-31)
- `extensions/council/skills/speckit-council/`, `speckit-council-triage/` — council-round + decision-record/suggestions provenance writers (I-29)
- `specs/000-sample/` — the executable contract fixture the checker MUST pass (FR-006); `docs/contracts/` — the schema set it enforces
- Clone-free root bootstrap (FR-001/US1) — **(not in graph — new code)**; the conformance checker itself (FR-004) — **(not in graph — new code)**

## Blast radius (per anchor)
- **`parse_hook_commands()`** (`augment_merge.py` L120)
  - depended on by: `compute()` [calls], `augment_merge.py` [contains]
  - depends on: `dequote()` [calls] — the quote-stripper the inline-comment strip must run alongside (`dequote()` L55, also called by `parse_shell()`/`resolve_target()` — do not regress its callers)
  - follow the pattern in: line-based (no-PyYAML) extraction already in this file — the fix stays PyYAML-free
- **`print_manual_block()`** (`extensions/git/install.sh`) — one copy per extension installer (deck-render/graphify/testing/workforce/git all define one); I-23 targets **git's** only. Defined by + called by `install.sh` script; must enumerate 100% of `extension.yml` hooks incl. the `after_complete`/`after_testing` seam
- **`extension.yml`** (git) — registers `after_complete` (L76) and `after_testing` (L81) commit-seam hooks, and carries the exact `command: … # hook-internal action: …` inline-comment shape (L87/L92) that is I-26's real-world hazard — the two fixes meet here
- **`validate-profile.py`** (degree 27) — self-contained: `main()`, `_build_arg_parser()`, `check_*` rule fns, `_self_test()`/`_write_fixture()`. The conformance checker should mirror this shape (single command, `_self_test`, no third-party deps) and **delegate** profile validation to it rather than re-checking (FR-008, 007/I-27 already shipped it)

## Shared / mutable files (collision watch)
> Tasks that touch any of these must be serialized — never put two of them in the same parallel wave.
- `docs/90-DECISIONS-AND-IDEAS.md` — all six items update their I-row status here on close (FR-016/SC-010); a single append-target every US touches → serialize the close-out
- `extensions/git/extension/extension.yml` **and** `extensions/git/install.sh` — both edited by the I-23 fix (manifest ↔ manual block must move in lock-step); keep in one task, not split across a wave
- `README.md` quickstart — the I-32 install-doc target (FR-002); if any other item touches README, serialize
- `.specify/extensions.yml` (installed manifest, mirror of `extension.yml`) — reinstall-driven drift risk per install-mirror-drift precedent; re-sync separately if the git-ext fix triggers a reinstall

## Patterns to follow
- **Dependency-free, closed-contract validator** — mirror `validate-profile.py`: single `python3` command, embedded `_self_test()`, named-cause stderr, non-zero = hard fail, no third-party imports (FR-007, I-11)
- **PyYAML-optional parsing** — `augment_merge.py` is deliberately line-based ("no PyYAML — unavailable"); the I-26 strip must stay in that no-dep style (mirrors git-ext's PyYAML-or-`uv`-or-manual fallback that I-23 hardens)
- **Both-branch committed fixtures** — golden/regression discipline: a conformant dir passes + each injected violation fails naming the cause (FR-009); whitespace-variant fixture for the inline-comment strip (SC-007); guard that FAILS on real manifest/block divergence (FR-011)
- **Manifest ↔ installed-mirror re-sync** — a git-ext reinstall surfaces stale `extension.yml` → `.specify/` drift; commit the re-sync as a separate `infra(git)` commit
