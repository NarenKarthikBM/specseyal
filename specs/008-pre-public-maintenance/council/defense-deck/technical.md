# Defense Deck — Technical

**Feature**: `008-pre-public-maintenance`
**Prepared by**: Session A — deck-prep (Sonnet, D18)
**Sources**: `plan.md`, `spec.md`, `graphify-context.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/*.md`, independent `graphify explain` queries against `graphify-out/graph.json`

> Format: markdown v1 (D15). This deck is **git-versioned in place, not round-scoped** (D38) — `defense-deck/technical.md` is overwritten on every revision; prior versions live in git history on the feature branch, not in a `round-N/` copy.

*This is the technical deck: council members and the chairman read it in full (FR-005). The companion `overview.md` is the one-page non-technical rendering for the human gate — do not duplicate that scope here; this file can assume a technical reader.*

---

## 1. Problem Restatement

`008` is the pre-public maintenance sweep the repo needs after `007` shipped the OSS front door and before the D73 visibility flip makes the repo public. Six ripe items from the `docs/90` "Actionable-now cluster" (D84) are bundled across five owner piles: **US1/P1** — today every `extensions/*/install.sh` is a pure local `cp -R` with no acquisition step, so `007`'s README quickstart is only half-runnable for a true outsider who hasn't already cloned the whole repo (I-32). **US2/P2** — the only conformance checks that exist are per-artifact (`validate-profile`/`categorization`/`skill`); nothing validates a `specs/NNN-feature/` directory against the `docs/contracts/` schema set as a whole, so drift is caught by human review, not by machine (I-11). **US3/P3** — four latent defects (I-23 git-ext manual-fallback gap, I-26 augment inline-comment mis-parse, I-29 missing council-apparatus provenance, I-31 a gitignored-path leak into `traces.jsonl`) are each currently unhit or silently non-blocking, but would mislead an outside adopter, contributor, or auditor once the project is public.

Every item is explicitly additive, bounded, independently testable, and — the load-bearing invariant (FR-015) — none touches council/workforce gate *semantics*, the deliberate contrast with `007`'s gate-touching profile validator.

---

## 2. Chosen Approach & Rejected Alternatives

**Chosen approach**

All six items are implemented as bash (POSIX `sh`) + Python-3-stdlib only — zero new third-party dependencies, matching the repo's existing `validate-profile.py`/`validate-categorization.py`/`validate-skill.py` precedent. The clone-free install (I-32) is a new root-level `bootstrap.sh` that **wraps, never replaces,** each extension's existing `install.sh` (D45-additive) — it only adds a fetch step in front of unchanged install logic. The conformance checker (I-11) is a new pure-stdlib `check-conformance.py` that **delegates** to the three existing per-artifact validators for their artifacts and covers the remaining `docs/contracts/` schemas directly — composition, not duplication (FR-008). The four hardenings (I-23/I-26/I-29/I-31) are surgical edits at graph-confirmed sites, each landing with a both-branch committed fixture (with two exceptions surfaced in §7). No item introduces a new pipeline phase, a new session role, or any model invocation at runtime.

**Rejected alternatives**

| Alternative | Reason rejected |
|---|---|
| `curl \| bash` opaque pipe-to-shell as the *primary* install path (I-32) | The exact blind-pipe posture the spec's Edge Case explicitly flags as a security concern; kept only as an optional convenience line, never the sole documented instruction |
| Full GitHub-release tarball + checksum/signature pinning (I-32) | Strongest supply-chain posture, but needs release-artifact + checksum-publishing infrastructure the pre-public repo doesn't have yet; over-scopes a maintenance sweep. The pinned-ref design leaves room to add this later without changing the command shape |
| Fork/duplicate the local install logic into `bootstrap.sh` (I-32) | Violates additivity/DRY and creates a second installer to keep in sync — exactly the divergence class I-23 is fixing elsewhere in this same feature |
| A network-fetch path that *replaces* the local `install.sh` (I-32) | FR-003/D45 require the offline/in-checkout route to survive unchanged for the no-network adopter |
| A new repo-level `tools/`/`scripts/` home for the checker (I-11) | The repo has no such directory; the layout convention is `extensions/*/` — creating a new top-level home for one script over-scopes |
| Reviving the M0 fixture-coupled verifier `R1-S04` (I-11) | Explicitly rejected by FR-005 — the checker must derive from the contracts themselves, not the deferred throwaway fixture |
| Re-implementing profile/categorization/skill checks inside the new checker (I-11) | Rejected by FR-008 — duplication invites the exact manifest-vs-block divergence class I-23 fights; delegation keeps one source of truth per artifact |
| A hard requirement that the checker pass every historical feature dir (I-11) | Pre-contract and carve-out features would force either false failures or per-feature exceptions; pinning `specs/000-sample` + a both-branch fixture set is the deterministic, maintainable bar instead |

---

## 3. Architecture & Data Flow

*Note on sourcing*: `plan.md` has no section literally named `## Architecture & data flow` — this is a six-item maintenance bundle, not a phased pipeline. The step-by-step flow below is reconstructed from `data-model.md`'s per-entity state transitions and `research.md`'s decisions, which together are the plan's equivalent grounding for this section.

**E1 — `bootstrap.sh` pipeline (I-32)**

State machine: `absent → acquired (temp dir) → installed (target) → temp cleaned`

1. **Read** `<extension-name>`, optional `<target-repo-dir>` (default `.`), optional `--ref <pinned-ref>`. Writes nothing yet.
2. **Fetch**: shallow, blobless, sparse `git clone --depth 1 --filter=blob:none --sparse` + `sparse-checkout set extensions/<name>` against the pinned ref, into a temp dir; falls back to a `codeload` tarball if sparse-checkout is unavailable. Write target: temp dir only — the adopter's target repo is untouched at this step.
3. **Delegate**: invokes that extension's own **existing, unmodified** `install.sh <target>`. This is the load-bearing additivity guarantee (D45) — `bootstrap.sh` writes nothing into the target beyond what the pre-existing local installer already would, and idempotency is inherited for free from the already-idempotent `install.sh` (SC-003) rather than reimplemented.
4. **Cleanup**: temp dir removed on exit, including failure paths.

Component performing the write in step 3 is the **existing per-extension `install.sh`**, unchanged — `bootstrap.sh` itself performs only the fetch (step 2) and the cleanup (step 4). No model session appears anywhere in this pipeline.

**E2 — `check-conformance.py` pipeline (I-11)**

1. **Input**: a `<feature-dir>` path (arg-driven — e.g. `specs/000-sample`).
2. **Delegate step**: shells out to the *installed* `validate-profile.py` / `validate-categorization.py` / `validate-skill.py` for `profile.yaml` / `categorization.md` / generated skills respectively — reads their **verdicts** (exit code + stderr), never their source, never re-implements their rules (FR-008). This is a runtime process invocation, not a source import — the D57 cross-extension-seam rule already sanctioning `implement-parallel`'s read of workforce's `assignment.md`.
3. **Direct-check step**: for the six remaining contracts (`artifact-layout`, `decision-record`, `completion-report`, `testing-doc`, `trace-schema`, `agent-library-schema`), reads the rule text from `docs/contracts/*.md` itself and checks presence/frontmatter/record-format against the feature dir directly — never against the deferred M0 fixture (FR-005).
4. **Carve-out check**: a D50 meta-feature rule-5 carve-out is honored, not flagged as drift.
5. **Output**: a deterministic verdict to stdout, one `<artifact> · <rule>` line per nonconformance, exit `0`/non-zero.
6. **Self-test**: embeds a `_self_test()`, mirroring `validate-profile.py`'s own shape.

Component performing the write: **none** — the checker is read-only; it mutates no artifact (Constitution I: a consumer/validator, not a pipeline phase). No model session in this pipeline either.

**E4–E7 — surgical hardening edits (US3)**

| Item | Site | Fix |
|---|---|---|
| I-23 | `print_manual_block()` in `extensions/git/install.sh` (git's copy specifically — see §4, this function name is *not* unique across the repo) | Add `after_complete`/`after_testing` rows; generalize `extensions/git/test/run.sh`'s single-hook grep into a guard over the full manifest (FR-011) |
| I-26 | `parse_hook_commands()` in `augment_merge.py` L120 | Strip a whitespace-preceded trailing `#…` before the existing `dequote()` call; stays line-based (no PyYAML) |
| I-29 | `speckit-council/SKILL.md` (`suggestions.md`) + `speckit-council-triage/SKILL.md` (`decision-record.md` §5) | Add a `Council apparatus: extensions/council/ @ <sha>` provenance line; flag a dirty `extensions/council/` tree when present |
| I-31 | `speckit-implement-parallel/SKILL.md` trace-writing step | A task whose sole output is gitignored/untracked writes `artifact: null`, probed via `git` |

Each is a single-site text/value edit at a graph-confirmed location, performed by the edited script/skill file itself the next time it runs — not by deck-prep, the council apparatus, or any live model session at edit time. All four are additive and gate-semantics-neutral (FR-015).

---

## 4. Project Structure & Dependency / Graph Impact

**Project Structure** (from `plan.md`)

```text
bootstrap.sh                                    # NEW (I-32) — root clone-free installer; wraps per-ext install.sh
extensions/
├── git/install.sh, extension.yml, test/run.sh   # EDIT (I-23)
├── graphify/extension/scripts/augment_merge.py,
│            test/run.sh,
│            skills/speckit-implement-parallel/SKILL.md   # EDIT (I-26, I-31)
├── council/skills/speckit-council/SKILL.md,
│           skills/speckit-council-triage/SKILL.md         # EDIT (I-29)
└── workforce/extension/scripts/check-conformance.py,
              test/run.sh                                  # NEW/EDIT (I-11)
specs/008-pre-public-maintenance/fixtures/       # NEW (I-11) — conformant + injected-violation dirs
README.md                                        # EDIT (I-32/FR-002)
docs/90-DECISIONS-AND-IDEAS.md                   # EDIT (FR-016, close-out)
```

**Structure Decision**: no new top-level directory. `bootstrap.sh` is a single root entry point (mirroring how `install.sh .` is each extension's own root entry). The checker lives in `extensions/workforce/extension/scripts/` beside the three validators it delegates to — a *runtime shell-out* to their installed copies (data/composition, not a source dependency), consistent with the D57 cross-extension-seam rule already governing `implement-parallel`.

**Dependency / Graph Impact** — independently verified against `graphify-out/graph.json` (4863 nodes, 5788 edges, repo scope, generated 2026-07-16), not restated from `plan.md`'s prose unverified:

- **`validate-profile.py`** — `graphify explain "validate-profile.py"` returns **degree 27**, confirming `graphify-context.md`'s claim. It is the pattern-to-follow node for `check-conformance.py`; the checker adds no new *source* edge to it — only a runtime shell-out.
- **`parse_hook_commands()`** — `graphify explain` confirms **degree 4**: contained by `augment_merge.py`, called by `compute()`, calls `dequote()`. I-26's fix is scoped entirely inside this node's body.
- **`dequote()`** — `graphify explain` confirms **degree 4**, with three callers: `parse_shell()`, `resolve_target()`, and `parse_hook_commands()`. This independently verifies the "do not regress its callers" caution in `graphify-context.md` — the I-26 strip must happen inside `parse_hook_commands()` *before* the call to `dequote()`, never inside `dequote()` itself, or it risks the other two unrelated callers. See §7 for a gap this raises in the committed fixture set.
- **`print_manual_block()`** — the graph disambiguates **multiple same-named nodes**, one per extension installer. An unqualified `graphify explain "print_manual_block"` resolves by default to **deck-render's** copy (degree 2, community 262), not git's — a live illustration of exactly the collision-prone-name hazard `graphify-context.md` flags. I-23 must target only `extensions/git/install.sh`'s copy; the fix is not portable to, and must not be confused with, any other extension's `print_manual_block()`.

**Shared / mutable files (collision watch, from `graphify-context.md`)** — none of these may appear together in a parallel implementation wave:

- `docs/90-DECISIONS-AND-IDEAS.md` — all six items' close-out status updates land here (FR-016/SC-010); single append target → serialize the close-out step.
- `extensions/git/extension.yml` **and** `extensions/git/install.sh` — both edited by I-23; manifest and manual block must move in lock-step in one task, not split across a wave.
- `README.md` quickstart — the I-32 doc target (FR-002); serialize if anything else touches README.
- `.specify/extensions.yml` (installed mirror) — a git-ext reinstall triggered by the I-23 edit risks manifest↔mirror drift (a precedent already seen in this repo); re-sync as a separate commit if triggered.

---

## 5. Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Clone-free install's `curl`-based fetch invites a "blind pipe-to-shell" security posture | Med | Med | Documented default is the reviewable two-step form (`curl -fsSLO` + `sh bootstrap.sh`, inspectable before running), against a pinned ref; any one-line convenience form is secondary, never the sole instruction. Checksum/signature pinning explicitly deferred — flagged "open for council" (research R1) |
| `docs/90-DECISIONS-AND-IDEAS.md` close-out is a single shared append target hit by all six items in one session | High (by design — FR-016 requires same-session close) | Low (append-only) | `graphify-context.md` collision watch flags this file explicitly; close-out must run serialized, never inside a parallel wave |
| git-ext manifest/manual-block re-divergence after a *future* hook is added (the exact failure mode I-23 exists to fix — `after_complete`/`after_testing` were added to `extension.yml` but never mirrored into the manual block) | Med | Med (silently drops a commit seam on a fallback-only host) | FR-011's static guard is generalized to the full manifest, not one hook, and H1's contract explicitly requires proving the guard **fails on the current pre-fix state** before it can be trusted post-fix |
| I-23's `install.sh` edit triggers a reinstall that leaves `.specify/extensions.yml` (installed mirror) stale relative to the edited `extension.yml` | Med | Low–Med | Re-sync as a separate `infra(git)` commit, per the repo's known install-mirror-drift precedent |
| `check-conformance.py` scope ambiguity — validating a historical feature dir that predates contracts or carries an undocumented carve-out could read as a false-positive drift report | Med | Low | Research R2 explicitly bounds scope: the checker is capable of validating any dir but is only *required* to pass `specs/000-sample`; not a hard requirement across all historical dirs |
| I-26's inline-comment strip touches `dequote()`'s call site, and `dequote()` is graph-confirmed shared by two unrelated callers (`parse_shell()`, `resolve_target()`) | Low | Med (a misplaced strip could silently alter shell-arg or target-path parsing elsewhere in `augment_merge.py`) | Fix is scoped to strip *before* calling `dequote()`, inside `parse_hook_commands()` only — but see §7: no committed fixture proves the other two callers are unaffected |
| `bootstrap.sh`'s pinned `--ref` default goes stale at the D73 visibility flip (tag vs. commit choice) | Med | Low | Explicitly flagged "open for council" in research R1 — the transport/pin wording is the thing the council is asked to defend |

---

## 6. Cost / Complexity Estimate

- **Deck-prep**: 1 Sonnet session (this one).
- **Council (`standard` tier, D56)**: 5 Sonnet member sessions + 1 consolidated Sonnet peer-critique session + 1 Opus (xhigh) chairman synthesis = 7 sessions.
- **Triage**: 1 Opus session (`speckit-council-triage`, a judgment role per D18).
- **Implementation**: `tasks.md` is explicitly **not yet generated** by this plan (Phase 2, deferred to `/speckit-tasks` — see `plan.md` Project Structure). Bound at this stage by scope, not a task count: 6 items across 5 owner piles, ~2 new files (`bootstrap.sh`, `check-conformance.py`) + 1 new fixture tree + 5 surgical edit sites. Implementation sessions will be Sonnet per D18; exact count resolves at `/speckit-tasks`.
- **Testing**: 1 Sonnet tester session (`speckit-testing`'s single-dispatch pattern).

**Complexity drivers**: none beyond baseline — zero new third-party dependencies, no new pipeline phase, no gate-semantics change (FR-015), and the Complexity Tracking table in `plan.md` is empty (no Constitution violations). The one real complexity driver is scheduling, not architecture: the shared-file collision surface (`docs/90`, git's `extension.yml`+`install.sh` pair, `README.md`) requires serialized task ordering at implementation time.

---

## 7. Testability Claim & Plan-Time Verifications

*Note on sourcing*: `plan.md` has no section literally named `## Plan-time verifications & per-SC test coverage`. The nearest equivalent is `quickstart.md`'s per-US runnable walkthrough plus its own "Coverage map (SC → check)" table; the table below is built from that plus `plan.md`'s Testing/Project-Structure statements and `data-model.md`'s "Cross-entity invariants" section.

| SC / FR | Claim | Enforcement mechanism | Committed test? |
|---|---|---|---|
| SC-001/FR-001 | Single documented command, zero manual clone | `quickstart.md` US1 block: run from a clone-free machine against a throwaway target | **Manual** — quickstart walkthrough; no automated harness named for `bootstrap.sh` in `plan.md`'s Testing section |
| SC-002/FR-002 | README quickstart resolves end-to-end for a true outsider | `quickstart.md` US1 step 4 | **Manual** |
| SC-003/FR-003 | Idempotent + additive (local `install.sh` route unchanged) | `quickstart.md` US1: re-run same command; separately re-run local `install.sh` | **Manual** |
| SC-004/FR-006/FR-009 | Checker PASSES `specs/000-sample`; FAILS each injected violation naming the cause | `extensions/workforce/test/run.sh`, committed both-branch fixtures under `specs/008.../fixtures/` (`conformant/` + 4 `violation-*/`) | **Yes** — code-verified, both branches |
| SC-005/FR-007/FR-008 | Deterministic, single CI command, zero third-party deps, no duplication of existing validators | Same `run.sh` harness (determinism = run twice, compare); delegation-not-duplication is a code-shape claim | **Partial** — determinism is checkable via harness re-run but not shown as a distinct committed assertion; the no-duplication claim is a design property, not fixture-testable |
| SC-006/FR-010/FR-011 | Manual block declares 100% of hooks incl. seam hooks; guard FAILS on divergence | `extensions/git/test/run.sh` generalized grep guard | **Yes** — and H1's contract explicitly requires proving the guard fails on the **current pre-fix state** (non-regression), directly answering the round-1 "a guard that only ever passes proves nothing" lesson |
| SC-007/FR-012 | Inline-comment strip; whitespace variants all clean | `extensions/graphify/test/run.sh` fixture case (`#x`, `  #  x`, tab-separated) | **Yes, but see gap below** |
| SC-008/FR-013 | Every new council round records `extensions/council/` HEAD; dirty tree noted | `quickstart.md` US3·I-29: post-hoc grep on the *next real* council round | **Manual** — `data-model.md`'s own "Cross-entity invariants" list of fixture-covered entities (E2, E4, E5) does **not** include E6 (I-29); no committed fixture |
| SC-009/FR-014 | Zero task records a gitignored/untracked path; `null` instead | `quickstart.md` US3·I-31: grep `traces.jsonl` after a live run with a gitignored-output task | **Manual** — same `data-model.md` fixture list excludes E7 (I-31); no committed fixture |
| SC-010/FR-016 | All six I-rows resolved same session; no gate-semantics change; one step from D73 flip | `quickstart.md` close-out block: grep `docs/90` for all six I-codes | **Manual** |

**Tally**: of 10 Success Criteria, **3 of 10** (SC-004, SC-006, SC-007) carry a genuinely committed, automated, both-branch fixture. SC-005 is partially covered by the same harness. The remaining **6 of 10** (SC-001/002/003, SC-008/009/010) are manual-verification-only per `plan.md`'s own Project Structure and `data-model.md`'s own cross-entity invariants list — most of these are inherently hard to fixture (a live council round, a live implement-parallel run, a true first-time-outsider install), but that also means their guarantees rest entirely on the quickstart being run by a human, not on a regression suite that fails loudly on a future break.

**Guard/branch falsifiability**: two guards in this plan are conditionals whose fixture set should be checked for both-branch coverage per the round-1 lesson (a guard that can only ever pass proves nothing):

- **I-23 divergence guard (SC-006)** — genuinely both-branch: H1's contract explicitly requires the guard to **fail** on the current pre-fix manifest/block state (proving it's real) and to **pass** post-fix. This is falsifiable as designed.
- **I-26 inline-comment strip (SC-007)** — the committed fixture set proves the strip works across whitespace variants, but `dequote()` is graph-confirmed (§4, degree 4) to have **two other callers** (`parse_shell()`, `resolve_target()`) beyond `parse_hook_commands()`. `data-model.md`'s E5 row states "`dequote()` and its other callers unaffected" as an invariant, but **no committed fixture in the plan's file list exercises `parse_shell()` or `resolve_target()` to prove that invariant holds** after the edit — the fixture set can prove the strip works, but not that it didn't regress the two other call sites sharing the touched function. This is the same shape of gap round-1 found independently from two lenses (a guard/invariant claim with no fixture that could actually trip it).
