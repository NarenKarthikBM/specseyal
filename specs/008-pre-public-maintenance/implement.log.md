# Implement Log — 008-pre-public-maintenance

> One line per wave, append-only. Prior lines are never edited.
> Written by `/speckit-implement-parallel`.

2026-07-20T08:47:06Z | wave 1 | tasks: T001 | agents: 1 | outcome: success

---

## Pre-change baseline (T001, wave 1)

Recorded so T012's R1-S11 "witness the guard FAIL" is distinguishable from a pre-existing
failure, and so T018 can confirm a green final result against a known prior state.

| harness | exit | passed | failed |
|---|---|---|---|
| `extensions/git/test/run.sh` | 0 | 61 | 0 |
| `extensions/graphify/test/run.sh` | 0 | 28 | 0 |
| `extensions/workforce/test/run.sh` | 0 | 13 | 0 |
| `extensions/testing/test/run.sh` | 0 | 43 | 0 |
| `extensions/deck-render/test/run.sh` | 1 | 92 | 8 |

**OVERALL: not green — 8 pre-existing failures, all confined to `deck-render`.** The four
harnesses this feature actually touches (git, graphify, workforce, testing) are fully green,
so every one of them is a clean "witness FAIL → witness PASS" reference.

### The 8 pre-existing `deck-render` failures

**7 of 8 — `python-pptx` absent on this host.** The suite's own section-0 banner predicts
them (`python-pptx: ABSENT (via python3) -- SC-003-class checks will FAIL loud`). Environmental,
not a code defect:

- `SC-003 fidelity (bidirectional containment + block sequence)`
- `SC-002 derived-render stamp`
- `T7 overflow / determinism (S08)`
- `FR-016 override renders a file`
- `partial-failure exit 2 (render-good / fail-broken / disclose-both)`
- `I-B3 atomic mid-write failure (no partial .pptx + prior good render untouched)`
- `SC-007 staleness detection (FRESH/STALE verdict)`

**1 of 8 — a genuine repo-state defect, NOT fixed by installing `python-pptx`:**

- `SC-005 not in git -- git ls-files tracks 1 .pptx file(s) anywhere in the repo, e.g.
  specs/008-pre-public-maintenance/council/defense-deck/008-defense-deck.pptx -- a rendered
  deck must never be tracked, regardless of path`

  Added on **this** branch by commit `0786e9f` (the council human-gate commit). Out of scope
  for 008 (the path is outside the FR-015 allowlist, and the defect is a council/deck-render
  concern) — carried forward to T017 as a new I-row rather than fixed here. See the wave-2
  scope note below.

---

2026-07-20T08:56:30Z | wave 2 | tasks: T002 | agents: 1 | outcome: success

## Scope note — the FR-015 allowlist carve-out (T002, wave 2)

`tasks.md`'s declared allowlist enumerates 13 **implementation edit sites**. Taken literally,
the guard it specifies was unimplementable: at wave 2 the branch diff already held **30 paths**,
of which only `docs/90-DECISIONS-AND-IDEAS.md` was allowlisted. The other 29 — 27 SDD artifacts
under `specs/008-pre-public-maintenance/` and 2 workforce-persisted skills under
`.claude/skills/` — were committed by the spec/plan/council/tasks/categorize/agents phases
**before implementation began**. A literal guard would have failed on all 29 and hard-blocked
every remaining task on the first wave that ran it.

**Resolution (human-approved, this run):** the guard's allowlist is the **union** of the 13
declared source sites and exactly two pipeline-output prefixes —
`specs/008-pre-public-maintenance/` and `.claude/skills/` — each enumerated and commented in
the source as output-not-source. FR-015 asserts *source* non-interference ("no gate-schema or
gate-semantics file changed"); the pipeline's own artifact writes are not source edits.

**The teeth are retained and were witnessed.** Any path under `extensions/**`, `docs/**`, or
the repo root outside the 13 declared sites still FAILs, and any *other* feature's `specs/`
directory is unexempted. Verified both branches: PASS 14/14 on the clean tree; FAIL naming
`extensions/testing/STRAY.txt` on a deliberately-introduced stray path.

**Known property (not a defect):** `git diff --name-only <merge-base>..HEAD` sees committed
history only, so an *uncommitted* working-tree stray is not caught. This matches `tasks.md`'s
literal specification of the diff command, and is harmless under this run's discipline — every
wave commits before its tasks are marked `[X]`, so by T018 the full branch is committed.

---

2026-07-20T09:20:10Z | wave 3 | tasks: T003, T007, T013, T015 | agents: 4 | outcome: success

## Findings carried to T017 (wave 3)

Two items surfaced by wave-3 agents that belong in the `docs/90` close-out, recorded here so
they are not lost between waves:

1. **`hardening-invariants.md` H3's site description is inaccurate** (surfaced by T013). H3
   names the edit sites as `suggestions.md` "alongside the existing plan/deck SHAs" and
   `decision-record.md` "§5 Metadata". Neither matches the files: `suggestions.md` carries no
   plan/deck SHA lines at all (only `Feature`/`Prepared by`/`Reads`), and `decision-record.md`'s
   `## Metadata` is a cardinality-1 section of five fixed fields per `docs/contracts/
   decision-record.md` §3 that holds no SHAs — the real plan/deck provenance lives in the
   per-round `## Round N` block. T013 placed the apparatus line in `## Round N` beside the
   actual `Deck reviewed:`/`Plan reviewed:` lines, and had the orchestrator post-insert into
   `suggestions.md` rather than edit out-of-scope templates. Additive and contract-clean, but a
   council-approved contract carries a wrong site description that survived the round.

2. **`bootstrap.sh`'s default `--ref` is a forward reference** (surfaced at wave-3 dispatch).
   There are no release tags in this repo — only `complete/<spec-id>` completion tags, latest
   `complete/007-oss-docs`. `bootstrap.sh` is introduced by 008, so it exists in no earlier tag;
   the only correct pinned default is `complete/008-pre-public-maintenance`, minted by this
   feature's own cleanup. Until that tag lands the documented one-command install fails unless
   the user passes `--ref` explicitly. This is a second, independent reason SC-001/002/003
   sign-off is provisional, beyond R1-S06's private-repo reason — T006 must state it in the
   README and T016 cannot validate the default path.

## Orchestrator integration patch (wave 3)

T015's rule said only "before writing a task's record, probe whether the path is tracked",
without pinning the probe relative to the wave commit. Read at the wrong moment every
brand-new file is untracked, so a trace written pre-commit would null out legitimate outputs.
Patched inline (not re-dispatched) with a clause pinning the probe to **after** step 4's
commit, matching this skill's own step 4 → step 5 ordering. Contract H4.1–H4.3 were already
satisfied by the agent's text; this closes a misread, not a contract gap.

---

2026-07-20T09:36:20Z | wave 4 | tasks: T004, T008 | agents: 2 | outcome: success

## ⚠ Open blocker for T011 — `specs/000-sample` does not pass the checker (wave 4)

Surfaced by T008, independently confirmed by the orchestrator. **Not a defect in the checker** —
the checker and its delegation layer work correctly; the *golden fixture is stale*.

`FR-006`/`C4`/`SC-004` require `check-conformance.py` to **pass** `specs/000-sample`, and T011 is
tasked with pinning exactly that as a standing golden assertion. Today it exits 1:

```
specs/000-sample: NONCONFORMANT
  categorization.md · taxonomy.md (validate-categorization.py): no '## Categorization table'
  heading found -- this file is not shaped like a categorization.md (data-model.md SS1)
```

`specs/000-sample/categorization.md` is M0-era (`taxonomy-v0.md`-authored) and carries
`## \`general\` cap check`, `## Categorizer notes`, `## Assembly implication` — but not the
`## Categorization table` heading the current contract requires.

**The full extent is not yet visible.** Only the *delegated* categorization check fires today;
the six *direct* contract checks are still T009 stubs returning `[]`. `fixtures/README.md`
separately discloses that `specs/000-sample` also predates `completion-report.md`'s and
`testing-doc.md`'s M4 shape, so T009 is expected to surface **further** violations in the same
fixture.

**Decision deliberately deferred to T011 (wave 9), not taken now.** Deciding at wave 4 would mean
choosing a remedy against a partial failure list. T009 does not depend on `specs/000-sample`
passing — it only implements checks — so the correct sequencing is: let T009 land, obtain the
complete violation set, then choose with full information. The candidate remedies, none yet
adopted:

1. **Amend `specs/000-sample` to the current contracts** — follows the D49/D50 precedent of
   updating this exact fixture when contracts evolve. Requires widening the FR-015 allowlist,
   which is a real scope change the workforce gate did not approve.
2. **Re-point the golden assertion at `fixtures/conformant/`** — authored by T007 against the
   current contracts and verified passing. Scope-clean, but `FR-006`/`C4`/`SC-004` name
   `specs/000-sample` explicitly, so it is a recorded spec deviation.
3. **Disclose as a known gap** — T011 pins it as expected-FAIL with an I-row; the feature ships
   with SC-004 partially unmet.

---

2026-07-20T09:58:40Z | wave 5 | tasks: T005, T009 | agents: 2 | outcome: success

---

2026-07-20T10:14:50Z | wave 6 | tasks: T006, T010 | agents: 2 | outcome: success

## Orchestrator integration patch (wave 6) — README two-ref conflation

T006's `--ref` caveat conflated two distinct refs and would have misled the first reader of a
public README:

- `<pinned-ref>` in the `curl` URL selects which ref **`bootstrap.sh` itself** is fetched from
  (step 1).
- `--ref` selects which ref the **extension subtree** is fetched from (step 2).

The original text offered `--ref complete/007-oss-docs` as a workaround, implying the two-step
form becomes usable. It does not: no existing tag contains `bootstrap.sh`, so step 1's `curl`
404s for **every** substitutable ref. The clone-free path is currently unavailable in full, not
merely default-broken.

Rewritten as a leading blockquote stating the path is not yet available and directing the
reader to the local `install.sh` route (which works today and is unaffected), with the
step-1/step-2 ref distinction spelled out. Everything becomes correct once this feature's
cleanup mints `complete/008-pre-public-maintenance`.

## T011 decision recorded (human-approved, wave 6)

The `specs/000-sample` blocker opened at wave 4 is resolved: **T011 pins the PASS assertion
against `fixtures/conformant/`** (authored against current contracts, verified passing), and
`specs/000-sample`'s 12 violations are recorded as a T017 I-row for a follow-up feature.
Scope-clean; no gate re-approval needed. SC-004 is met in substance while deviating from the
fixture `FR-006`/`C4` names — recorded as an explicit deviation, not silently.

Complete `specs/000-sample` violation list (obtained by T009, hand-verified, none a parser
artifact — it predates D72, D77, and the M4 shapes of `completion-report.md`/`testing-doc.md`):

```
categorization.md    · no '## Categorization table' heading                    (delegated)
completion-report.md · frontmatter missing/malformed
completion-report.md · required core section '### Completed (N/N)' missing
completion-report.md · required core section '### Key results' missing
testing.md           · frontmatter missing/malformed
testing.md           · required section '## Coverage map' missing
testing.md           · required section '## Verified by reading vs. would-execute in v2' missing
testing.md           · 4 unexpected top-level headings (contract defines no optional appendix)
traces.jsonl:20      · role 'tester' missing required 'context_in'             (D72)
traces.jsonl:6,7,8   · role 'council-member' missing 'graph_queries'/'ceiling_hit' (D77)
```

---

2026-07-20T10:20:05Z | wave 7 | tasks: T012 | agents: 1 | outcome: success

## T012 lock-step evidence (R1-S11 / H1 / SC-006)

All five sub-steps executed in the mandated order; the FAIL-witness preceded the fix.

- **Step 1 — mirror resync: NOT TRIGGERED.** The git harness runs entirely against throwaway
  repos under `$TMPDIR` and never installs into this working tree, so no reinstall occurred.
  `.specify/extensions.yml` confirmed zero-diff. R1-S23 is satisfied vacuously, and this is
  recorded rather than silently skipped.
- **Step 2 — guard generalized.** `manifest_hook_names()` extracts all **13** top-level keys
  under `hooks:` from `extensions/git/extension/extension.yml` (line-based awk/sed, no PyYAML),
  and the assertion is scoped to `"$GIT_EXT/install.sh"` specifically — never a bare
  `print_manual_block` name match, which any of the five identical copies would satisfy
  (R1-S10/FR-011).
- **Step 3 — FAIL witnessed (pre-fix), verbatim:**
  `FAIL install.sh manual fallback missing hook(s) registered in extension.yml: after_complete after_testing`
  → `Result: 60 passed, 1 failed`
- **Step 4 — fix applied.** `print_manual_block()` +2 entries (`after_complete`, `after_testing`),
  matching the block's existing alignment and field order.
- **Step 5 — PASS witnessed (post-fix), verbatim:**
  `PASS install.sh manual fallback (extensions/git/install.sh) declares 100% of extension.yml-registered hooks`
  → `Result: 61 passed, 0 failed` — matching T001's baseline count exactly.

**Orchestrator independent re-verification.** Rather than accept the reported witness, the
orchestrator ran its own bite test: removed the `after_testing` entry from the manual block and
re-ran the suite, obtaining
`FAIL install.sh manual fallback missing hook(s) registered in extension.yml: after_testing`
→ `60 passed, 1 failed`; restored and re-confirmed `61 passed, 0 failed`. `git diff --stat`
confirms `install.sh` carries exactly the intended `+2` lines and no residue from the test.
This proves the guard derives from the manifest rather than matching a hardcoded list.

**Scope note for T017.** I-23 closes **git's copy only**. The other four structurally-identical
`print_manual_block()` definitions — `deck-render`, `graphify`, `testing`, `workforce` — carry
the same latent drift with no guard. The durable deliverable here is the guard pattern, not the
two-line fix (R1-S07).

---

2026-07-20T10:33:20Z | wave 8 | tasks: T014 | agents: 1 | outcome: success

## T014 both-branch evidence (H2 / SC-007 / R1-S03)

- **Pre-fix (parser reverted, fixtures kept):** `Result: 36 passed, 4 failed`, exit 1 — the three
  whitespace-variant checks plus the real-world `extensions/git/extension/extension.yml` pin went
  red, while all 8 boundary/regression assertions stayed green. That split matters: it proves the
  regression assertions are a genuine untouched baseline, not coincidentally passing.
- **Post-fix:** `Result: 40 passed, 0 failed`, exit 0 — T001's 28 plus 12 new.
- **The strip is scoped to `parse_hook_commands()`; `dequote()` is byte-for-byte unmodified**
  (confirmed by the orchestrator: `dequote` does not appear in the diff at all). This was the
  task's main hazard — stripping inside `dequote()` would have silently corrupted `parse_shell()`,
  which parses shell content where `#` is legitimate in paths, strings, and arguments. Committed
  regression fixtures cover `resolve_target()` and `parse_shell()`, including a quoted-path case
  containing an internal `" #"` that would have caught exactly that mistake.
- **Mirror resync: not triggered.** No `extension.yml` was touched, so a graphify reinstall would
  be a no-op against `.specify/extensions.yml`.

## Finding carried to T017 — graphify installed-mirror drift (wave 8)

Surfaced by T014, independently confirmed and quantified by the orchestrator. **Pre-existing and
unrelated to this feature's changes**; out of the FR-015 allowlist, so recorded rather than fixed.

`.specify/extensions/graphify/` (the installed `cp -R` mirror of `extension/`) is missing two
entries present in source:

```
MISSING from mirror:  graphify-version.pin
MISSING from mirror:  scripts
```

and `grep -rl augment_merge .specify/` returns nothing — the installed tree carries no reference
to that script at all.

**Consequence, stated carefully:** T014's fix is correct in source, and that is where
`extensions/graphify/test/run.sh` exercises it, so the 40/0 result is sound. But the installed
graphify extension does not carry `augment_merge.py`, so the fix cannot take effect for anything
running from `.specify/`. Whether the mirror *should* carry `scripts/` (drift) or deliberately
omits it because the script is a dev-time tool run from source (by design) is **not adjudicated
here** — T017 should decide which it is. This matches the repo's known install-mirror-drift
pattern, so drift is the more likely reading, but the orchestrator did not verify that and does
not assert it.

---

2026-07-20T10:43:00Z | wave 9 | tasks: T011 | agents: 1 | outcome: success

## T011 — checker wired; golden substitution implemented as adjudicated

`extensions/workforce/test/run.sh`: **25 passed, 0 failed** (14 prior + 11 new), also verified
clean under `dash`, not just bash-as-sh. Appended as sections 6–10 strictly after T002's guard
end-banner; T002's FR-015 section is unmodified.

- **§6 both-branch fixtures (FR-009).** All seven dirs. Violations are matched against each
  fixture's own `VIOLATION.md` "Expected checker message" — **not exit codes alone**, which would
  pass even when the checker named the wrong rule. `violation-bad-trace-line/` asserts both of its
  two independently-named cases.
- **§7 static no-import guard (R1-S22).** FR-008's composition-not-duplication is now a caught
  regression rather than an assertion.
- **§8 double-run byte-diff (R1-S21/SC-005).** Run against `violation-assembly-cap-exceeded/`
  because it emits real findings; `conformant/` would compare a one-liner. **SC-005 moves from
  manual to code-verified.**
- **§9 standing golden — substituted, disclosed.** Pinned against `fixtures/conformant/` per the
  human adjudication, with a ~20-line in-source comment recording that `FR-006`/`C4`/`SC-004` name
  `specs/000-sample`, that it is NONCONFORMANT on 12 counts, that this was discovered rather than
  assumed, and — explicitly — that the harness **does not** assert `specs/000-sample` fails, since
  that would pin its brokenness as expected behaviour. `specs/000-sample` is not read by the
  harness at all.
- **§10 `--self-test`** wired, exit 0 (89 assertions).

**Both-branch witnesses observed and restored** (scratch in `/tmp` only, `git status` clean before
and after): the no-import guard FAILed against a scratch copy carrying an injected
`import validate_profile`, naming the offending line; and a violation assertion FAILed when given
a deliberately wrong expected message, printing `expected message not found on stderr: …` —
confirming it refuses to pass on exit code alone.

**Disclosed contract deviation.** `contracts/conformance-checker-command.md` C4 (and its
"Both-branch fixtures" section, line 40) names `specs/000-sample` as the standing CI golden. That
literal text was **not** implemented, by human decision. Recorded here and in the harness comment
as a deliberate, disclosed deviation — carried to T017.

---

2026-07-20T10:53:00Z | wave 10 | tasks: T016 | agents: 1 | outcome: success

## T016 — quickstart integration gate: SC-001…SC-010 binding (R1-S09)

Read-only. `git status --porcelain | wc -l` → `0` before and after; scratch confined to `/tmp`
and removed. Independently re-confirmed by the orchestrator.

### Harness results vs. T001 baseline

| harness | baseline | this run | verdict |
|---|---|---|---|
| git | 61/0 | **61/0** | match |
| graphify | 28/0 → 40/0 expected post-T014 | **40/0** | match |
| workforce | 13/0 → 25/0 expected post-T002+T011 | **25/0** | match |
| testing | 43/0 | **43/0** | match |
| deck-render | 92/8 | **92/8**, same 8 | unchanged, out of scope |

### SC verdicts

| SC | Verdict | Basis |
|---|---|---|
| SC-001 | **PROVISIONAL** | `--self-test` 3 pass/0 fail/1 named skip; arg-injection + enum guards executed. Real default-ref install reproduced the two documented blockers exactly: `curl: (56) … 404` on `complete/008-pre-public-maintenance`. True outsider path not completable. |
| SC-002 | **PROVISIONAL** | README's "Not available yet" notice verified **accurate against live 404 behaviour**; step-1/step-2 ref distinction correct; no undocumented step. The doc's own honest verdict is "not available yet". |
| SC-003 | **PROVISIONAL** | Local-route idempotency **fully executed and PASS** — `install.sh <target>` run twice, sha256 of the whole `.claude/`+`.specify/` tree byte-identical. Clone-free half untestable until SC-001 clears. |
| SC-004 | **PASS** | All 7 fixture dirs correct. Additionally exercised against a **real live feature** (`specs/001-council-extension`): D50 rule-5 carve-out honored with **zero false positives** — a check beyond the brief, on real data. |
| SC-005 | **PASS** | §7 no-import guard `ok`; §8 double-run byte-identical (stdout, stderr, exit code); manually reproduced. **Genuinely moved from manual to code-verified** (R1-S21). |
| SC-006 | **PASS** | Both seam hooks present in the manual block; `61 passed, 0 failed`; guard's FAIL-on-divergence independently bite-tested at wave 7. |
| SC-007 | **PASS** | All three whitespace variants (`#x`, `  #  x`, tab) pass, plus `dequote`/`parse_shell`/`resolve_target` regressions. `40 passed, 0 failed`. |
| SC-008 | **NOT EXECUTED** | Rule text confirmed present in both council SKILL.md files, but **zero** council rounds anywhere carry the line — correct, since I-29 is forward-only (R1-S13) and 008's own round predates it. Nothing to observe yet. |
| SC-009 | **NOT EXECUTED** | No task in 008's own waves had a sole gitignored output, so the live rule was never exercised. The detector side is proven by T007's fixture, but that is an SC-004 concern, not a live run. |
| SC-010 | **NOT EXECUTED** | By design — T017 (wave 11) is strictly after this gate. All six I-rows found, **none yet resolved**. |

**Aggregate: 4 code-verified · 3 provisional · 3 not executed = 10/10 accounted for, none silently skipped.**

### Named executor + timing for the six manual-only criteria

- **SC-001 / SC-002 / SC-003** — repo maintainer, in one session immediately after **both** (a) this
  feature's cleanup mints `complete/008-pre-public-maintenance` and (b) the D73 visibility flip;
  from a machine with **zero prior git credential** for this repo. SC-003's local half is already
  discharged; only the clone-free half remains.
- **SC-008** — whoever runs `/speckit-council` on the next feature (≥ 009); verified by grepping
  that round's `decision-record.md`/`suggestions.md` for `Council apparatus`.
- **SC-009** — whoever runs `/speckit-implement-parallel` on the next feature containing a task
  whose sole output is gitignored (paradigm: a deck-render feature emitting only a `.pptx`);
  verified by grepping that feature's `traces.jsonl` for `"artifact": null` on that task.
- **SC-010** — this feature's own **T017**, the very next wave.

**SC-001/002/003 are PROVISIONAL for two independent reasons**, both requiring post-D73
re-confirmation: the repo is private (R1-S06's original reason), **and** the pinned default ref
does not exist until this feature's own cleanup tags it (discovered this run).
