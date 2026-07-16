# Defense Deck — Technical

**Feature**: `007-oss-docs` — OSS Front Door + Profile Contract Validator
**Prepared by**: Session A — deck-prep (Sonnet, D18)
**Sources**: `plan.md`, `spec.md`, `graphify-context.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/validate-profile.md`

> Format: markdown v1 (D15). This deck is **git-versioned in place, not round-scoped** (D38) — `defense-deck/technical.md` is overwritten on every revision; prior versions live in git history on the feature branch, not in a `round-N/` copy.

*This is the technical deck: council members and the chairman read it in full (FR-005). The companion `overview.md` is the one-page non-technical rendering for the human gate — do not duplicate that scope here; this file can assume a technical reader.*

---

## 1. Problem Restatement

The repository is not yet ready to go public. Two independent gaps stand in the way. First, there is no "front door" — no root `README.md`, no `CONTRIBUTING`/`CODE_OF_CONDUCT`/`SECURITY`, no `.github/` issue or PR templates — so a newcomer arriving cold cannot learn what SpecSeyal is, how the spec → … → testing pipeline works, or how to run it, and a prospective contributor has no documented convention to follow or private channel to report a vulnerability through.

Second, the pipeline's central autonomy config, `profile.yaml` — the file that sets `council_tier` and the `council`/`workforce` gate modes, including the `full_auto` handshake — is enforced today only by prose (`docs/contracts/profile-schema.md`) and by a model reading the file at run time (I-27). This is not hypothetical: a real committed profile currently carries `council_tier: standrad` (a typo) and degrades silently rather than failing. `007` is the last α-polish feature (D73) before a manual "visibility commit" flips the repo public; both gaps must close, and the profile-validator arm (US3) was folded into this docs feature by explicit owner scope decision (D82) because it is judged the cheapest real win left in the maintenance pile (I-27) even though it touches gate-correctness territory (D79(2)).

---

## 2. Chosen Approach & Rejected Alternatives

**Chosen approach**

Two independently-shippable arms in one feature, sharing no code:

- **Arm A (US1/US2, FR-001…012):** author the OSS front door — `README.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `.github/ISSUE_TEMPLATE/*`, `.github/PULL_REQUEST_TEMPLATE.md` — at the repo root/`.github/`, per GitHub community-health convention. Reference-accuracy (FR-010) and no-leakage (FR-011) are treated as *mechanical, grep-checkable acceptance gates* (quickstart D2/D3), not reviewer judgment calls. No code blast radius.
- **Arm B (US3, FR-013…019):** build `validate-profile.py`, a dependency-free general contract validator, home'd at `extensions/workforce/extension/scripts/` (+ tracked install copy) alongside the repo's two existing general validators (`validate-skill.py`, `validate-categorization.py`), whose structure it mirrors (`main()`, small `check_*`/`validate_*` predicates, a `ValidationResult`-style accumulator, embedded self-test, committed fixtures). It reuses `profile_key.py`'s interpreter-ladder PyYAML discovery verbatim (no third-party dependency, FR-016) and enforces `docs/contracts/profile-schema.md` v1.2 exactly as written — including *not* pruning the I-27-flagged `reopen_tier` (dead key) or reconnecting `max_rounds` to its real consumer (`council-config.yml`); that reconciliation is explicitly deferred as a future schema amendment (D-e), out of this feature's scope. It subsumes `006`'s scoped `deck_render` check by treating `profile_key.DECK_RENDER_ENUM` as the single SSOT (read-only consumption or a pinned module constant, guarded by a committed equivalence test) — `profile_key.py` itself is left unchanged. FR-019's enforcement point is recommended as a **fail-closed, mandatory `before_plan` hook**, but is structured as a **separable task** so the council can cut it to standalone-only without touching the validator.

**Rejected alternatives**

| Alternative | Reason rejected |
|---|---|
| A new "core/contracts" extension to host the validator | No such extension exists today; creating one to host a single S/M-scope file is disproportionate (D-a, research.md). |
| Validator lives inside `extensions/deck-render/` (where the only existing profile code sits) | A *general* profile validator does not belong inside the deck-specific extension — naming/ownership smell; `deck-render` owns only one of the two gates the profile configures (D-a). |
| Vendor a mini-YAML parser instead of the interpreter-ladder probe | Rejected on correctness: a hand-rolled parser risks mishandling comments/strings/nested maps in a real profile; correctness beats avoiding a subprocess (D-b). |
| Require PyYAML as a hard dependency | Directly forbidden by FR-016 (no third-party dependencies). |
| Re-declare the four `deck_render` enum literals independently in the general validator | Rejected by FR-018's explicit "without duplication" — would recreate exactly the divergent-copy risk the subsumption exists to close (D-d). |
| Edit `profile_key.py` to import from the general validator (reverse the dependency) | Needlessly mutates `006`'s already-shipped code for no gain; the enum SSOT stays where it is (D-d). |
| Prune `reopen_tier` / rewire `max_rounds` to its real consumer now | Out of scope: a schema-content change is a `profile-schema.md` amendment + its own D-row, not something this validator-authoring feature redesigns (D-e). A dead-but-valid key still catches a typo in it — pruning it early would remove exactly the check that closes I-27's defect class. |
| FR-019 enforcement as standalone-only (script/command, no hook) | Presented, not chosen: fully honors D79(2)'s original coupling caution but downgrades FR-019's "before the pipeline acts on it" MUST to a convention someone must remember to run. Kept as the council's alternative — the wiring is cuttable independent of the validator (D-f). |

---

## 3. Architecture & Data Flow

*Note on sourcing: `plan.md` has no section literally named "Architecture & Data Flow" — this section is reconstructed faithfully from `plan.md`'s Technical Context/Project Structure, `data-model.md`'s validator state machine, and `contracts/validate-profile.md`'s exit-code/message contract, so a lazy-context council member does not need to open those three files separately.*

**Arm B — validator run, step by step** (a pure function, no state file, no artifact written — Constitution I):

1. **Invocation** — `validate-profile.py [--feature <dir> | <profile-path>]` (no argument ⇒ `./profile.yaml`, cwd use). Resolves to one concrete path.
2. **Existence check** — file absent ⇒ **VALID, exit 0** immediately (P1: resolves to both-gates-`human`, the safest posture). No further steps run. Deterministic, stateless.
3. **YAML acquisition** — try PyYAML in the current interpreter first; if absent, walk the interpreter ladder (`graphify`/`specify` shebang interpreter → `python3` → `python` → `uv run --with pyyaml python`), mirroring `profile_key.py`'s out-of-process `_probe_yaml_inprocess` pattern. **Guarantee**: if no PyYAML-capable interpreter is reachable, this is a **loud non-zero failure** — never silently treated as "absent" or "said nothing." Malformed/unreadable YAML is likewise always a loud non-zero failure, never folded into the absent branch.
4. **Rule evaluation** (only reached once parsed as a mapping) — required keys present and typed (`schema_version`, `feature` == containing directory name, `full_auto` bool); gate blocks are mappings not scalars (`gates.council`/`gates.workforce`, each with a `mode` ∈ {human, auto}); closed enums (`council_tier` ∈ {full, standard}; `deck_render` ∈ `DECK_RENDER_ENUM`; `reopen_tier` ∈ {auto, delta, full}); `max_rounds` must equal `1`; **unknown key at any level ⇒ error**, never a warning; the `full_auto` handshake — P2 (`council.mode: auto` requires `full_auto: true`), P3 (`full_auto: true` requires **both** modes `auto`), P4 (`workforce.mode: auto` alone with `full_auto: false` is valid — an economic guard, not protected) are machine-enforced; P5 (the mandatory why-comment) is explicitly **not** machine-enforced — the contract states it is "enforced by the person reviewing the diff," and the validator does not attempt it.
5. **`deck_render` subsumption** — the validator's accepted set for this one field **is** `profile_key.DECK_RENDER_ENUM`, consumed rather than duplicated (either a runtime import, or a module constant a committed equivalence test pins equal to `profile_key.DECK_RENDER_ENUM`). `profile_key.py` performs no write and is not edited by this feature; it remains the render-time scoped resolver. This closes the honest limit `profile-schema.md` §8 records ("caught at render time, not at profile-author time") by moving the check earlier, to validate/author time.
6. **Verdict emission** — VALID ⇒ exit 0 (silent or single `OK` line); INVALID ⇒ non-zero exit **and** a human-readable stderr message naming the offending key/value — never an opaque parser traceback.

**Which component performs each write** (load-bearing per D53): the validator writes **nothing** — it is a mechanical pass/fail check on an existing artifact, exactly like `verify-gate`/`cleanup.sh` (Constitution I). The OSS docs (Arm A) are each written once by a dispatched Sonnet implementation-agent session as ordinary file output — no model transforms structured data through the validator's logic; the validator path is 100% code, 0% model, at both author time and (if FR-019 is ratified) enforcement time.

**FR-019 enforcement flow (if ratified)** — a mandatory `before_plan` hook, registered in `.specify/extensions.yml`, whose thin skill wrapper (the `cli-command-wrapper` pattern) resolves the feature's profile path, shells out to `validate-profile.py`, and hard-blocks the `plan` phase on a non-zero exit — structurally identical to how `verify-gate` hard-blocks today. Because this sits at the pipeline's **front**, before `council` or `tasks`, **no gate ever reasons about an invalid profile** — gate internals are untouched; only well-formed profiles reach them. An absent profile still passes (P1), so profile-less features are never spuriously blocked. This wiring is a separate task from the validator itself, so the council can excise it (standalone-only alternative, §2) with zero impact on Arm B's code.

**Arm A — doc flow**: no runtime data flow. Each OSS doc is authored once by an implementation agent; FR-010 (reference-resolution) and FR-011 (leakage) are checked mechanically, once, at authoring time via grep (quickstart D2/D3) — there is no live/repeated data path, and (by explicit scope decision) no automated freshness re-check after authoring.

---

## 4. Project Structure & Dependency / Graph Impact

**Project Structure** (from `plan.md`)

```text
# Arm B — the profile validator
extensions/workforce/extension/scripts/
├── validate-profile.py          # NEW — the general profile.yaml contract validator
├── validate-categorization.py   # exists — structural exemplar
└── validate-skill.py            # exists — structural exemplar
.specify/extensions/workforce/scripts/
└── validate-profile.py          # NEW — committed installed copy (both trees tracked)

extensions/deck-render/extension/scripts/
└── profile_key.py               # UNCHANGED — DECK_RENDER_ENUM SSOT (FR-018 consumes it)

extensions/workforce/test/
├── run.sh                        # exists — register the new test here
├── test_profile.sh               # NEW — both-branch golden/regression harness
└── fixtures/profile/             # NEW — 1 conformant + 1-per-malformed-class + the enum-equivalence pin

# FR-019 enforcement wiring (SEPARABLE — council may cut to standalone-only)
.specify/extensions.yml           # + a mandatory before_plan hook (fail-closed)
<owner-ext>/skills/speckit-validate-profile/   # thin skill wrapper

# Arm A — the OSS front door (all NEW; LICENSE already exists, referenced not recreated)
README.md
CONTRIBUTING.md
CODE_OF_CONDUCT.md
SECURITY.md
.github/ISSUE_TEMPLATE/{bug_report.md, feature_request.md}
.github/PULL_REQUEST_TEMPLATE.md
```

**Structure Decision narrative** (`plan.md`): the validator lives with the repo's two existing general contract validators — the lowest-surprise home, and the one I-27 named directly. `profile_key.py` is **not edited**; the general validator consumes its enum export read-only or pins it, never duplicates it. OSS docs sit at repo root / `.github/` per GitHub convention. The FR-019 hook is isolated to `.specify/extensions.yml` + one thin skill specifically so it can be excised without touching Arm B's validator.

**Dependency / Graph Impact** (from `graphify-context.md`, independently re-verified against `graphify-out/graph.json` this session)

- The repo graph (1611 nodes, 2674 edges, repo scope) **predates `006-deck-render`**, as `graphify-context.md` states. Independently confirmed: querying the graph directly for `profile_key.py` returns **zero matches** ("No node matching 'profile_key.py' found") — the staleness claim holds, it is not merely asserted.
- The two existing validators this feature mirrors are present as graph nodes: `validate-skill.py` (degree 13, community 11) and `validate-categorization.py` (degree 14, community 24) — each with one "contains" edge per top-level function/class (e.g. `validate_skill()`, `check_grants()`, `_self_test()` for the former; `ValidationResult`, `validate_categorization_file()`, `general_cap_limit()` for the latter). `frontmatter.py`, the one parser both are claimed to share, is also present (degree 12, community 9), again with contains-only edges to its own parse functions.
- **Caveat, stated plainly rather than silently omitted**: the graph's extraction here captures file→function "contains" edges only — it does **not** capture cross-file *import* edges. So the "both validators import only `frontmatter.py`, never a hand-rolled parser" claim (`graphify-context.md`) is **not** independently graph-verifiable this session; it rests on direct source reading, not a graph metric. Flagged rather than restated as graph-confirmed.
- **Blast radius** (per `graphify-context.md`, consistent with the above): the new validator depends on `docs/contracts/profile-schema.md` (the contract) and `profile_key.DECK_RENDER_ENUM`; it is depended on by **nothing at authoring time** — a standalone checker — *unless* FR-019's hook is ratified, at which point the council/workforce gate becomes indirectly dependent on it (the D79(2) gate-semantics weight the council is asked to weigh).
- **Shared/mutable-file collision watch** (never two touching tasks in one parallel wave):
  - `extensions/deck-render/extension/scripts/profile_key.py` — collision risk **only** if FR-018 were implemented by editing `006`'s file to defer to the general validator; the plan's chosen mechanism (D-d) is a read-only import or a pinned constant, so **no edit, no collision** under the chosen approach.
  - `docs/contracts/profile-schema.md` — the spec's edge cases flagged this as a possible collision point if schema-content gaps were reconciled; the plan's D-e explicitly does **not** prune `reopen_tier`/`max_rounds` in this feature, so this file is **not edited** by this feature at all — a lower collision risk than the original edge case implied.
  - `.specify/extensions.yml` — genuinely touched, and only, if the FR-019 hook is ratified; this is the hook registry many phases read, so any such task must serialize behind/around other hook-registering work in flight.
  - The five OSS docs are mutually independent and safe to parallelize; they share only the FR-010 "paths resolve" invariant, checked mechanically after authoring, not enforced at write time.

---

## 5. Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| FR-019 enforcement wiring couples a docs feature to the council gate's correctness guard (D79(2)) — a malformed profile now blocks a phase, changing gate-adjacent behavior. | Certain (explicitly named in Complexity Tracking) | Medium — only genuinely malformed profiles are blocked; an absent profile (P1) still passes, so profile-less features are unaffected. | The hook wiring is a separable task; council may ratify the recommended `before_plan` hook or select the standalone-only alternative, cutting the task with zero impact on the validator itself. |
| `deck_render` subsumption (FR-018) drifts from `profile_key.DECK_RENDER_ENUM` if the import/pin mechanism is implemented loosely, silently reintroducing the "divergent second copy" problem the subsumption exists to prevent. | Low–medium (mechanism explicitly flagged as an "implement-phase detail" in `research.md` D-d) | Medium — a drifted enum would mean the general validator and the render-time check disagree, reintroducing exactly the ambiguity FR-018 closes. | A committed equivalence test asserts the validator's accepted set **equals** `profile_key.DECK_RENDER_ENUM` and that both reject the same out-of-enum value, regardless of which mechanism (import vs. pinned constant) is chosen. |
| OSS doc reference staleness after authoring — a cited path/command/extension moves post-close, silently breaking the front door for a later reader. | Medium, over time | Low–medium — no code blast radius; degrades documentation quality, not pipeline correctness. | Explicit scope boundary: FR-010/SC-003 is an authoring-time grep check only (quickstart D2); an automated docs-freshness/link-check mechanism is named as a future concern, not built here — an accepted, scoped-out residual risk, not a plan gap. |
| Private-context leakage (FR-011) not caught by the leakage grep — the check pattern-matches `/Users/`/`/home/` paths and known personal-data shapes; a leak in an unmatched form (e.g. a hostname, an internal handle) could slip through. | Low | High — a privacy exposure in a repository about to go public. | The grep (quickstart D3) is a floor, not a ceiling; SC-004 states the outcome (zero leakage) as the acceptance bar, implying human review at the gate remains expected alongside the mechanical check. |
| Schema reconciliation deferral (D-e): `reopen_tier` stays a documented dead key and `max_rounds` stays disconnected from its real consumer (`council-config.yml`); a conforming-but-semantically-inert value still passes, which could confuse a future contributor. | Certain (an explicit, recorded decision, not an oversight) | Low — documented, and the validator still catches a *typo* in either key (e.g. `reopen_tier: fulll`), which is the actual I-27 defect class being closed; pruning early would remove that exact protection. | `research.md` D-e records the reconciliation stance and defers the schema-content question to a future D-row / standalone amendment; not acted on here by design. |

---

## 6. Cost / Complexity Estimate

**Feature's own `profile.yaml`**: `council_tier: standard`, both gates `human` — confirmed by reading `specs/007-oss-docs/profile.yaml` directly (not merely plan prose).

**Session count implied** (D18 role→model map):

- Deck-prep: **1 Sonnet** session (this one).
- Council, standard tier (D56): **5 Sonnet member sessions** + **1 Sonnet consolidated peer-critique session** (lazy context) + **1 Opus xhigh chairman synthesis** = 7 sessions.
- Triage: **1 Opus** session (`/speckit-council-triage`).
- Implementation (post-council, task-count not yet fixed by `tasks.md`): roughly one **Sonnet** dispatch per independent OSS doc artifact (README, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, issue templates, PR template — mutually parallelizable per §4) + one or more Sonnet dispatches for the validator + test harness + fixtures, + one further Sonnet dispatch for the FR-019 hook wiring **if the council does not cut it**.
- Complete + testing: **1 Sonnet tester** session (`/speckit-testing`, context-in = completion-report.md + spec.md only).

**Total ballpark across the feature's full lifecycle**: on the order of **15–18 sessions**, dominated by the standard-tier council ceremony (7) and the doc-authoring fan-out (~6-8 parallelizable implementation dispatches).

**Complexity drivers**: zero new third-party dependencies (FR-016 keeps Arm B's footprint small); Arm B's only cross-module coupling is a **read-only** consumption of `profile_key.DECK_RENDER_ENUM` (import or pinned constant), never an edit to `006`'s shipped code — contained coupling, not a spreading one; the one genuinely complexity-adding decision is FR-019's enforcement point, and it is structured as a **separable, council-cuttable task** specifically to keep that complexity optional rather than baked in.

---

## 7. Testability Claim & Plan-Time Verifications

*Note on sourcing: `plan.md` has no section literally named "Plan-time verifications & per-SC test coverage" — the table below is reconstructed faithfully from `quickstart.md`'s runnable scenarios + SC → check map, `data-model.md`'s verdict/rule tables, and `contracts/validate-profile.md`'s test-coverage contract (§6).*

| SC / FR | Claim | Enforcement mechanism (quickstart ref) | Committed test? |
|---|---|---|---|
| SC-001, SC-002 | A newcomer states what SpecSeyal is, the phase sequence, the first command, and doc locations from the README alone; the quickstart reaches a runnable pipeline with zero undocumented steps. | D1 — manual read-through walkthrough | No — manual-only |
| SC-003 / FR-010 | 100% of cited paths/commands/extensions resolve at authoring. | D2 — grep-extracted references checked for existence | Mechanical grep, run at authoring; **not** a committed CI regression test |
| SC-004 / FR-011 | Zero private/internal leakage. | D3 — grep for `/Users/`/`/home/` patterns + personal-data review | Mechanical grep, run at authoring; **not** a committed CI regression test |
| SC-005, SC-006 | A contributor produces a phase-tagged commit + matching D/I-row from CONTRIBUTING alone; locates the vulnerability channel and issue/PR process from SECURITY/`.github/`. | D4 — manual walkthrough | No — manual-only |
| SC-007 / FR-017 | 100% correct verdict across a fixture set covering both branches of every targeted class. | V3 — `extensions/workforce/test/run.sh` / `test_profile.sh` | **YES** — committed golden/regression harness |
| SC-008 / FR-015 | `specs/000-sample/profile.yaml` passes; the M0 fixture becomes executable. | V1 (direct invocation) + folded into V3/V6 | **YES** — committed fixture case |
| SC-009 | `council_tier: standrad` is rejected, not silently degraded. | V2 (direct invocation on a crafted bad profile) + a fixture class in `test_profile.sh` | **YES** — committed fixture case |
| SC-010 / FR-016 | No third-party dependency; completes in < 2s. | V5 — `time` invocation + `grep -rl requirements.txt` absence check | **Partial** — the no-`requirements.txt` check is a repo-state grep; the <2s timing is quickstart-run, not asserted as a pass/fail threshold inside `test_profile.sh` itself |
| FR-018 | Validator's accepted `deck_render` set equals `profile_key.DECK_RENDER_ENUM`; no divergent copy. | V4 + contract §5 — committed equivalence test | **YES** — committed equivalence test |
| SC-011 | On close, all OSS docs exist and pass D2/D3; the repo is publishable with no further doc authoring needed. | D5 — manual close-out checklist | No — manual-only |
| FR-019 | A malformed profile is mechanically rejected before the pipeline acts on it. | V7 — conditional on which enforcement point the council ratifies | **Not yet** — contingent on this council's decision; no test can be written until the enforcement point is fixed |

**Tally**: of the 11 Success Criteria, **3 (SC-007, SC-008, SC-009)** — all Arm B/validator claims — plus FR-018's enum-equivalence check are backed by a **committed, automated test** today (`test_profile.sh`). SC-010 is exercised at quickstart time but not pinned as a committed pass/fail regression. The remaining **7 (SC-001, SC-002, SC-003, SC-004, SC-005, SC-006, SC-011)** — all Arm A/docs claims — are **manual-only**: SC-003/SC-004 via a mechanical (but not CI-committed) grep, the rest via human walkthrough. This split is by design, not an oversight: the spec's Edge Cases explicitly place an automated docs-freshness/link-check mechanism out of scope, so Arm A's testability ceiling is deliberately lower than Arm B's.

**Guard/branch falsifiability check** (per this deck's own discipline — a fixture-backed guard that can only ever pass its own assertion proves nothing about its failure branch, and vice versa):

- **P1** (absent file ⇒ VALID): both branches are named explicitly — an absent-file case (P1, pass) sits alongside malformed-YAML and unreachable-interpreter cases (fail) in the V3/V6 fixture set (contract §6). Both-branch coverage confirmed.
- **P4** (`gates.workforce.mode: auto` alone with `full_auto: false` ⇒ VALID — "must NOT over-reject"): contract §6 names this explicitly as its own fixture row with an expected PASS verdict, alongside the P2/P3 FAIL fixtures. Both-branch coverage confirmed for P4.
- **P2/P3** (the reverse: `full_auto: true` **and** both gate modes `auto` ⇒ VALID — the pass branch of the handshake's strictest rule): the named fixture list (`plan.md` Project Structure + contract §6) explicitly enumerates the **fail** branch (`full-auto-unsatisfied.yaml`, and the P2/P3 combined non-zero row) but **no fixture is explicitly named** for the corresponding **pass** branch — a profile with `full_auto: true` and both gates `auto`, which the handshake requires to validate cleanly. `conformant.yaml` may or may not be that profile; its `full_auto` value is not stated in any plan-time artifact read for this deck. If `conformant.yaml` is not itself a `full_auto: true`/both-`auto` profile, **the P3-pass branch would have no committed fixture that could ever exercise it** — the same class of gap D62 flagged in round-1 (a guard whose only committed exercise is its failure branch). This is a concrete, named gap for the `testability` lens and/or a task-writing-time check, not yet something plan-time artifacts resolve either way.
