---
feature: 008-pre-public-maintenance
phase: complete
status: success
---

## Implementation Complete — Pre-Public Maintenance & Adopter Experience

**Shape of the run.** 12 waves, all logged `outcome: success`. Widest parallel wave: **4 agents** (wave 3 — T003 `bootstrap.sh`, T007 fixture tree, T013 council provenance, T015 implement-parallel guard). Waves 1, 2 and 7–12 were serial barriers by design: setup, the FR-015 scope guard, the I-23 lock-step task, the `.specify/` mirror contention, the shared `extensions/workforce/test/run.sh`, and the three terminal polish steps.

**Roster summary** (from `agents/assignment.md` `### Roster approved`, 17 rows over 18 tasks, all Sonnet):

- **8× `agt_devtools_cli`** — T003+T005, T004, T006, T008, T009, T010, T012, T014. Skills drawn from `skl_shell_scripting`, `skl_installer_hygiene`, `skl_refactor_discipline`, `skl_cli_command_wrapper`, `skl_docs_contract_authoring`, `skl_quickstart_integration_gate`, `skl_extension_tree_scaffold`, `skl_yaml_hooks`, `skl_baseline_capture`.
- **6× `agt_qa_automation`** — T001, T002, T007, T011, T016, T018. Skills from `skl_refactor_discipline`, `skl_baseline_capture`, `skl_shell_scripting`, `skl_decision_log_close_out`, `skl_golden_fixture_discipline`, `skl_docs_contract_authoring`, `skl_quickstart_integration_gate`.
- **2× `agt_ai_agents`** — T013, T015. Skills: `skl_refactor_discipline`, `skl_dispatched_prompt_authoring`, `skl_cli_command_wrapper` (T013); `skl_refactor_discipline`, `skl_orchestration`, `skl_dispatched_prompt_authoring` (T015).
- **1× `agt_generic`** ⚠ **empty lane** — T017 (`docs × general` matched no base lane; approved as assembled at the workforce gate, FR-016). Skills: `skl_refactor_discipline`, `skl_decision_log_close_out`.

Every row carries `Elevated grants: none` — the D67 grant tripwire was clear for the whole run. Two skills carry `built` marks from a prior run (`skl_baseline_capture`, `skl_decision_log_close_out`); the gap-cluster list was empty (FR-006/SC-007) — the skill-builder authored nothing during this feature.

### Completed (18/18)

| Wave | Tasks | Agents | Outcome |
|---|---|---|---|
| 1 | T001 pre-change baseline across 5 harnesses | 1 | success |
| 2 | T002 FR-015 branch-scope allowlist guard | 1 | success |
| 3 | T003 `bootstrap.sh` skeleton · T007 fixture tree · T013 I-29 council provenance · T015 I-31 gitignored-artifact rule | 4 | success |
| 4 | T004 fetch+delegate body · T008 checker CLI/delegation shell | 2 | success |
| 5 | T005 `--self-test` both fetch branches · T009 six direct contract checks | 2 | success |
| 6 | T006 README clone-free quickstart · T010 checker `_self_test()` | 2 | success |
| 7 | T012 I-23 git-ext manual-fallback guard (5-step lock-step) | 1 | success |
| 8 | T014 I-26 inline-comment strip in `parse_hook_commands()` | 1 | success |
| 9 | T011 checker wired into workforce harness | 1 | success |
| 10 | T016 quickstart integration gate (SC-001…SC-010) | 1 | success |
| 11 | T017 `docs/90` close-out | 1 | success |
| 12 | T018 final verification | 1 | success |

All three user stories landed complete: **US1** clone-free one-command install (T003–T006), **US2** machine-checked contract drift (T007–T011), **US3** four latent-defect hardenings (T012–T015), plus the full polish phase (T016–T018).

### Partial/Degraded

No task or wave finished partial — the record is 18/18 `[X]` and 12/12 `outcome: success`, which is why `status` is `success`. Three items are nonetheless **degraded in what they can currently demonstrate**, and are recorded here rather than buried:

1. **The clone-free install path is not yet exercisable end-to-end (SC-001/002/003 provisional).** Two independent blockers, both discovered during the run and both documented in the README as a leading "not available yet" notice: the repo is still private (R1-S06's original reason), **and** the pinned default `--ref complete/008-pre-public-maintenance` does not exist until this feature's own `/speckit-git-cleanup` mints it — so step 1's `curl` 404s for every substitutable ref. The code, arg-injection guards, enum validation and `--self-test` all execute and pass; the *outsider* path does not. Re-confirmation is owed to the repo maintainer immediately after both the tag lands and the D73 visibility flip. SC-003's local-route half is already fully discharged (`install.sh <target>` run twice, sha256 of the whole `.claude/`+`.specify/` tree byte-identical).

2. **The standing golden assertion was substituted, by human decision, and disclosed.** `contracts/conformance-checker-command.md` C4 (and FR-006/SC-004) name `specs/000-sample` as the CI golden. It is NONCONFORMANT on **12 counts** — it predates D72, D77 and the M4 shapes of `completion-report.md`/`testing-doc.md`. T011 pins the PASS assertion against `fixtures/conformant/` instead, with a ~20-line in-source comment recording the deviation; the harness deliberately does **not** assert `specs/000-sample` fails, which would pin its brokenness as expected behaviour. Carried to `docs/90` as an I-row for a follow-up feature. SC-004 is met in substance, deviating from the fixture the contract names — recorded, not silent.

3. **Three of the four US3 hardenings carry a disclosed coverage gap (R1-S15), as planned.** I-23 (T012) has a real both-branch `run.sh` fixture. I-26 (T014) is partial by design — primary fix plus regressions for `dequote()`'s other two callers. I-29 (T013) and I-31 (T015) edit LLM-interpreted `SKILL.md` prose no `run.sh` can drive: I-31 is pinned indirectly by T007's `trace-schema` violation fixture; **I-29 carries a genuine, disclosed gap**. Both are recorded in `docs/90` as *landed but not yet observed live* — SC-008 and SC-009 are NOT EXECUTED because no council round and no sole-gitignored-output task has run since the rules shipped.

Additionally: `extensions/deck-render/test/run.sh` was **not green at baseline** (92 passed / 8 failed) and is unchanged at 92/8 with the same 8 failures. 7 of 8 are environmental (`python-pptx` absent on this host, predicted by the suite's own banner); the 8th is a genuine repo-state defect — a `.pptx` tracked in git, admitted by commit `0786e9f` on this branch during the council human gate. Out of the FR-015 allowlist and out of 008's scope; carried to `docs/90` as I-34 rather than fixed here.

### Failed

None. No task and no wave finished `failed`; no task was abandoned or left unresolved.

### Integration status

Concretely, what was checked and how — this is T018's final verification, run read-only with `git status --porcelain` returning 0 lines before and after, and independently re-confirmed by the orchestrator:

| Check | Result | How verified |
|---|---|---|
| **FR-015 branch-scope allowlist guard** over the complete branch diff | **PASS — 169 paths, zero strays** | `git diff --name-only $(git merge-base <base>..HEAD)` run through T002's guard in `extensions/workforce/test/run.sh` |
| `extensions/git/test/run.sh` | **61 passed / 0 failed** | matches T001 baseline exactly |
| `extensions/graphify/test/run.sh` | **40 passed / 0 failed** | baseline 28/0, +12 new from T014 |
| `extensions/workforce/test/run.sh` | **25 passed / 0 failed** | baseline 13/0, +1 from T002, +11 from T011; also verified clean under `dash`, not only bash-as-sh |
| `extensions/testing/test/run.sh` | **43 passed / 0 failed** | matches T001 baseline exactly |
| `extensions/deck-render/test/run.sh` | **92 passed / 8 failed** | unchanged in count **and composition** vs. baseline — no 9th failure introduced |
| `check-conformance.py --self-test` | **exit 0, 89/89 assertions** | the R1-S19 contract-header self-check |
| Seven both-branch fixture verdicts | **7/7 correct** | `conformant/` → exit 0; each of six `violation-*` → exit 1, matched against that fixture's own `VIOLATION.md` "Expected checker message", **not exit codes alone** |
| Static no-import guard (R1-S22) | **ok** | asserts `check-conformance.py` shells out via `subprocess` and never source-`import`s the three validators; bite-tested — FAILed against a scratch copy carrying an injected `import validate_profile`, naming the offending line |
| Double-run byte-diff determinism (R1-S21) | **byte-identical** stdout, stderr, exit code | run against `violation-assembly-cap-exceeded/` (emits real findings); **SC-005 genuinely moved from manual to code-verified** |
| Checker vs. a real live feature | **zero false positives** | run against `specs/001-council-extension`; D50 rule-5 meta-feature carve-outs honored — a check beyond the brief, on real data |
| I-23 guard derives from the manifest, not a hardcoded list | **proven** | orchestrator's own bite test: removed `after_testing` from the manual block → `60 passed, 1 failed` naming exactly that hook; restored → `61 passed, 0 failed`; `git diff --stat` confirms `install.sh` carries exactly the intended `+2` lines, no residue |
| I-26 strip is scoped to `parse_hook_commands()` | **`dequote()` byte-for-byte unmodified** | `dequote` does not appear in the diff at all; committed regressions cover `resolve_target()` and `parse_shell()`, including a quoted-path case with an internal `" #"` that would have caught a mis-scoped strip |
| SC-010 six ripe I-rows resolved | **6/6** | `grep -nE 'I-32\|I-11\|I-23\|I-26\|I-29\|I-31' docs/90-DECISIONS-AND-IDEAS.md`; each carries a `[Bb]uilt at .008. (D84… 2026-07-20)` marker, re-verified after an orchestrator false alarm (see below) |
| All 18 tasks marked `[X]` | **yes** | T018 marked by the orchestrator — a read-only task cannot self-mark |

**Shared-file and mirror integrations are clean.** `.specify/extensions.yml` was confirmed zero-diff after T012 (the git harness runs entirely against throwaway repos under `$TMPDIR` and never installs into this working tree, so R1-S23's resync is satisfied vacuously — recorded, not silently skipped) and after T014 (no `extension.yml` touched). `gates.yml` appears in the branch diff but last changed at `06bd974` (agents phase, before wave 1 at `93ad2a1`); `git diff 06bd974..HEAD -- gates.yml` is **empty across all ten implementation waves** — it is a gate *binding record* written by the `record-gate` hooks, data rather than schema or semantics. The FR-015 sign-off therefore rests on evidence: the branch's **source** diff is exactly the 12 declared paths, zero strays.

**One integration claim is deliberately bounded.** T014's fix is correct **in source**, which is where `extensions/graphify/test/run.sh` exercises it (40/0). But `.specify/extensions/graphify/` is missing `scripts` and `graphify-version.pin` relative to source, and `grep -rl augment_merge .specify/` returns nothing — so the fix **cannot take effect for anything running from the installed mirror**. Whether that mirror *should* carry `scripts/` (drift) or deliberately omits it (a dev-time tool run from source) was **not adjudicated**; it is recorded in `docs/90` as an open question, not asserted as a bug.

**Not verified by this run:** SC-001/002/003's unauthenticated outsider path, SC-008's live council-round observation, SC-009's live gitignored-output trace. Named executors and timing for all six manual-only criteria are recorded in `implement.log.md`'s wave-10 section. `/speckit-testing` is doc-only (`executed: none`) and cannot discharge them.

### Key results

- **18/18 tasks, 12/12 waves success, zero regressions** against the T001 baseline on every one of the five harnesses. Net test delta: **+24 assertions** (graphify +12, workforce +12) with no harness losing ground.
- **A dependency-free conformance checker now exists** — `extensions/workforce/extension/scripts/check-conformance.py`, Python-3-stdlib only, delegating to the three existing validators by `subprocess` rather than import (FR-008 composition, now a *caught regression* via the static guard), covering all six directly-checked contracts with seven committed both-branch fixtures.
- **SC-005 moved from manual to code-verified** — the double-run byte-diff assertion replaces a re-run-and-eyeball step.
- **The I-23 guard's durable deliverable is the pattern, not the fix.** It derives the required hook set from `extensions/git/extension/extension.yml` (all 13 keys) and scopes the assertion to `extensions/git/install.sh` specifically, so no other `print_manual_block()` copy can satisfy it by name. The four structurally-identical unclosed copies (`deck-render`, `graphify`, `testing`, `workforce`) are recorded as **I-33** — this closes git's copy only, not the repo-wide pattern.
- **Aggregate SC verdict: 4 code-verified · 3 provisional · 3 not-executed = 10/10 accounted for, none silently skipped.** The provisional and not-executed rows each carry a named executor and a trigger condition.
- **`docs/90` close-out is complete and sequential**: six ripe I-rows resolved in-session, four newly-discovered findings added as I-34…I-37, rows verified gap-free at D1–D84 / I-1–I-37, plus an FR-015 gate sign-off stated on concrete diff evidence rather than on the SC-010 grep (which proves bookkeeping, not non-interference).
- **Two honest self-corrections are on the record.** The orchestrator's wave-12 suspicion of fabricated evidence was **wrong** — the markers existed; the grep missed markdown backticks and a `head -1` extraction returned the oldest of three `→` markers on I-11's row. It is logged as a retracted accusation because a retraction should leave a trace as durable as the accusation. Separately, `hardening-invariants.md` H3's site description is inaccurate (neither `suggestions.md` nor `decision-record.md § Metadata` holds the SHAs it claims); T013 placed the apparatus line where the real provenance lives and the discrepancy is recorded as I-35 rather than papered over.
- **Immediate follow-on:** `/speckit-git-cleanup` mints `complete/008-pre-public-maintenance`, which is the tag `bootstrap.sh`'s default `--ref` points at. Until it exists, the documented clone-free install cannot succeed — that tag is a hard prerequisite for the maintainer's post-D73 SC-001/002/003 re-confirmation.
