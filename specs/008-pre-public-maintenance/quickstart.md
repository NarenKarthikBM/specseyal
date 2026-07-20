# Quickstart — 008 Pre-Public Maintenance (validation walkthrough)

Runnable validation for each of the six items, binding every Success Criterion to a concrete check. Run from repo root unless noted. This is a **validation guide** — implementation lives in `tasks.md` / the implement phase.

## Prerequisites

- POSIX `sh`, Python 3 (stdlib only — no `pip install`), `git`.
- A throwaway target repo for the US1 clone-free test (a bare `git init` dir is enough).

---

## US1 — Clone-free one-command install (I-32) → SC-001/002/003

```sh
# From a machine with ONLY the documented command (no prior specseyal clone):
curl -fsSLO <raw-repo-url>/<pinned-ref>/bootstrap.sh
sh bootstrap.sh git /path/to/throwaway-target      # acquire + install git-ext
```

**Expected**:
- `git`-ext skills land in `/path/to/throwaway-target/.claude/`, hooks register in `.../.specify/` — **no separate manual clone/download step** (SC-001, §US1-1).
- Re-run the same command → identical, consistent state, no duplication (SC-003, §US1-2).
- Verify the local route still works unchanged: `cd <checkout>/extensions/git && sh install.sh /path/to/other-target` (SC-003, additive/D45).
- Follow only the README quickstart's documented steps as a true outsider → reaches a runnable install with **no undocumented acquisition step** (SC-002, §US1-3).

---

## US2 — Contract conformance checker (I-11) → SC-004/005

```sh
# PASS on the executable contract fixture:
python3 extensions/workforce/extension/scripts/check-conformance.py specs/000-sample   # exit 0

# FAIL on an injected violation (names artifact + rule):
python3 .../check-conformance.py specs/008-pre-public-maintenance/fixtures/violation-missing-section   # exit !=0

# Determinism: same input twice → identical verdict
python3 .../check-conformance.py specs/000-sample; python3 .../check-conformance.py specs/000-sample

# Both-branch fixture suite (all cases):
sh extensions/workforce/test/run.sh
```

**Expected**: `specs/000-sample` PASSES (SC-004, §US2-1); each injected-violation fixture FAILS naming the offending artifact + rule (SC-004, §US2-2); verdict deterministic and CI-invocable with no third-party deps (SC-005, §US2-3); a D50 carve-out feature is honored, not flagged (§US2-4).

---

## US3 — Latent-defect hardenings

### I-23 git-ext manual fallback → SC-006

```sh
# Inspect the manual block declares after_complete + after_testing:
awk '/^print_manual_block/,/^MANUAL$/' extensions/git/install.sh | grep -E 'after_complete|after_testing'
# Run the divergence guard (must PASS post-fix, and would FAIL if a manifest hook were dropped):
sh extensions/git/test/run.sh
```
**Expected**: manual block enumerates 100% of `extension.yml` hooks incl. both seam hooks; the static guard FAILS on any manifest↔block divergence (SC-006).

### I-26 augment inline-comment strip → SC-007

```sh
sh extensions/graphify/test/run.sh    # includes the inline-comment fixture case
```
**Expected**: a `command: <id>  # comment` line parses to a clean `<id>` (zero ` # …` captured); `#x`, `  #  x`, tab-separated variants all strip (SC-007).

### I-29 council apparatus provenance → SC-008

```sh
# After a fresh council round, inspect the round's artifacts:
grep -i 'Council apparatus' specs/<feature>/council/decision-record.md specs/<feature>/council/suggestions.md
git rev-parse HEAD -- extensions/council/
```
**Expected**: the round records `extensions/council/` HEAD alongside plan + deck SHAs; a dirty tree is noted (SC-008).

### I-31 implement-parallel trace guard → SC-009

```sh
# For a task whose sole output is gitignored (e.g. renders/*.pptx), inspect its trace:
grep '"artifact"' specs/<feature>/traces.jsonl
```
**Expected**: that task's record has `"artifact": null` — never the gitignored path (SC-009).

---

## Close-out → SC-010 (FR-016)

```sh
grep -nE 'I-32|I-11|I-23|I-26|I-29|I-31' docs/90-DECISIONS-AND-IDEAS.md
```
**Expected**: on feature close, all six I-rows are resolved with updated `docs/90` status (same session), no change altered council/workforce gate semantics, and the repo is one bounded step from the D73 visibility flip.

---

## Coverage map (SC → check)

| SC | Where validated |
|----|-----------------|
| SC-001/002/003 | US1 block |
| SC-004/005 | US2 block |
| SC-006 | US3 · I-23 |
| SC-007 | US3 · I-26 |
| SC-008 | US3 · I-29 |
| SC-009 | US3 · I-31 |
| SC-010 | Close-out block |
