# Contract — Latent-defect hardening invariants (US3 · I-23/I-26/I-29/I-31)

Behavioral contracts for the four surgical hardenings. Each is additive, gate-semantics-neutral (FR-015), and lands with a both-branch fixture.

## H1 — git-ext manual-fallback completeness + divergence guard (I-23)

**Site**: `extensions/git/install.sh` `print_manual_block()`; guard in `extensions/git/test/run.sh`.

| # | Guarantee | Maps to |
|---|-----------|---------|
| H1.1 | On a host with **neither PyYAML nor `uv`**, the printed manual block declares **100%** of `extension.yml`-registered hooks, including the `after_complete` + `after_testing` commit seams | FR-010, SC-006, Acceptance §US3-1 |
| H1.2 | A static check **FAILS** iff any manifest-registered hook is absent from the manual block (generalized from the current single-hook grep at `run.sh` L164) | FR-011, SC-006, Edge (guard must fail on real divergence) |

**Non-regression**: the guard must fail on the *current* pre-fix state (after_complete/after_testing missing), proving it is real.

## H2 — augment inline-comment strip (I-26)

**Site**: `extensions/graphify/extension/scripts/augment_merge.py` `parse_hook_commands()`; fixture in `extensions/graphify/test/run.sh`.

| # | Guarantee | Maps to |
|---|-----------|---------|
| H2.1 | A `command: <id>  # <comment>` line mints a clean command-node id (`<id>`), zero ` # …` captured | FR-012, SC-007, Acceptance §US3-2 |
| H2.2 | Strip is whitespace-preceded-`#` only; stays line-based (no PyYAML); `dequote()` + its other callers unaffected | FR-012, Research |
| H2.3 | Whitespace variants `#x`, `  #  x`, tab-separated all strip cleanly — proven by a committed fixture case | SC-007, Edge |

## H3 — council apparatus provenance (I-29)

**Site**: `speckit-council/SKILL.md` (`suggestions.md` provenance) + `speckit-council-triage/SKILL.md` (`decision-record.md` §5 Metadata).

| # | Guarantee | Maps to |
|---|-----------|---------|
| H3.1 | Every new council round records `Council apparatus: extensions/council/ @ <git rev-parse HEAD -- extensions/council/>` alongside the existing plan + deck SHAs | FR-013, SC-008, Acceptance §US3-3 |
| H3.2 | A dirty `extensions/council/` working tree mid-round is noted/flagged so the recorded sha's completeness is honest | Edge |
| H3.3 | **Additive only** — provenance metadata; no council-gate-semantics change | FR-015 |

## H4 — implement-parallel gitignored-artifact guard (I-31)

**Site**: `extensions/graphify/skills/speckit-implement-parallel/SKILL.md` trace-writing step.

| # | Guarantee | Maps to |
|---|-----------|---------|
| H4.1 | A task whose **sole** output is gitignored/untracked writes `artifact: null` — never the ignored path | FR-014, SC-009, Acceptance §US3-4 |
| H4.2 | Tracked-state probed via `git` (e.g. `git check-ignore` / `ls-files`); generalizes `006`'s SC-005 as a root-cause guard | FR-014 |
| H4.3 | `trace-schema.md`-compliant — a **value** change (null), no field added/removed | Constitution IV |

## Cross-cutting

- **FR-015**: none of H1–H4 alters council/workforce gate *semantics*.
- **Golden/regression fixtures** (FR-009): H1 guard fails on divergence; H2 fixture covers whitespace variants; H4 asserted against a gitignored-only-output task.
