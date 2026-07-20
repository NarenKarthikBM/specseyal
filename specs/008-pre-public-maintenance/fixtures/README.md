# Fixtures — `check-conformance.py` both-branch coverage (T007, US2 · I-11)

Committed, deterministic, byte-stable fixtures for the contract conformance checker
(`check-conformance.py`, T008–T010) and its own test harness
(`extensions/workforce/test/run.sh`, T011). Authored **before** the checker, per
`specs/008-pre-public-maintenance/contracts/conformance-checker-command.md`'s "Both-branch
fixtures" section — the checker's failure messages are written to match these fixtures, not the
reverse.

Every rule enforced here is read from the contract's **own stated text**
(`docs/contracts/{artifact-layout,decision-record,completion-report,testing-doc,trace-schema,
agent-library-schema}.md`), not copied from `specs/000-sample/` — that fixture predates two of
these contracts (`completion-report.md` and `testing-doc.md` are both M4/1.0, `000-sample` is
M0) and is not itself in the current shape those two now require. `specs/000-sample/` was used
only as the structural model for what a feature-dir *tree* looks like (layout breadth), never as
the source of any specific validated rule.

## What "conformant" means here

`conformant/` satisfies **all nine** `docs/contracts/` schemas that govern a feature directory —
the six this checker validates **directly** (below) and the three it **delegates** to
already-existing validators (`validate-profile.py`, `validate-categorization.py`;
`validate-skill.py` has nothing to check here, since this fixture ships no generated skills).
Every violation dir is a full copy of `conformant/` with **exactly one** deliberate edit — every
other file, byte-for-byte, is what `conformant/` already has.

## Coverage table — all six directly-checked contracts (R1-S16)

| # | Contract (`docs/contracts/…`) | Conformant coverage | Violation fixture | Rule broken |
|---|---|---|---|---|
| 1 | `artifact-layout.md` | `conformant/` — full required-artifact tree at its stated layout paths | `violation-wrong-path/` | §1: `council/defense-deck/technical.md` present, but at `council/technical.md` (missing the `defense-deck/` nesting) |
| 2 | `decision-record.md` | `conformant/council/decision-record.md` — Metadata, Round 1 (one `rejected` row with rationale, exercising R3), Human Gate, Carried Constraints, in order | `violation-missing-section/` | §5: `## Carried Constraints` (cardinality 1, last, required) omitted entirely |
| 3 | `completion-report.md` | `conformant/completion-report.md` — frontmatter `status: success` + all six core sections, in order | `violation-bad-frontmatter/` | §6 rule 1: frontmatter `status: done` — not in `{success, partial, failed}` |
| 4 | `testing-doc.md` | `conformant/testing.md` — frontmatter `executed: none` + a full `spec.md` SC/FR ↔ Coverage-map bijection (`FR-001`, `FR-002`, `SC-001`, `SC-002`) | `violation-coverage-gap/` | §6 rule 3: `FR-002` is in `spec.md` but has no `## Coverage map` row |
| 5 | `trace-schema.md` | `conformant/traces.jsonl` — one record per session-running phase (15 lines), current 1.4 fields (`council-member.graph_queries`/`ceiling_hit`, `tester.context_in`) | `violation-bad-trace-line/` | §7 rule 4 (non-`implementer` record with non-null `agent_id`) **and**, dual-purpose, the I-31 gitignored-artifact-instead-of-`null` pinning case — see below |
| 6 | `agent-library-schema.md` | `conformant/agents/assignment.md` — roster shape: 0 skills injected, grants column present and empty, model `sonnet` for both implementation-type tasks | `violation-assembly-cap-exceeded/` | §3 (D40 Guardrails): T001's roster row carries 4 injected skills, exceeding the assembly cap of 3 |

**No gap.** All six directly-checked contracts have at least one injected-violation case
(FR-009); none is left silently uncovered.

## Directory index

| Directory | Verdict | Notes |
|---|---|---|
| `conformant/` | **PASS** | The golden tree. See its own `README.md`. |
| `violation-wrong-path/` | FAIL — `artifact-layout` | `VIOLATION.md` |
| `violation-missing-section/` | FAIL — `decision-record` | `VIOLATION.md` |
| `violation-bad-frontmatter/` | FAIL — `completion-report` | `VIOLATION.md` |
| `violation-coverage-gap/` | FAIL — `testing-doc` | `VIOLATION.md` |
| `violation-bad-trace-line/` | FAIL — `trace-schema` (two named sub-cases; the second doubles as I-31's pinning fixture, R1-S03) | `VIOLATION.md` |
| `violation-assembly-cap-exceeded/` | FAIL — `agent-library-schema` | `VIOLATION.md` |

The four dirs `conformance-checker-command.md` names as a floor (`violation-missing-section/`,
`violation-bad-frontmatter/`, `violation-wrong-path/`, `violation-bad-trace-line/`) are all
present; `violation-coverage-gap/` and `violation-assembly-cap-exceeded/` are the two additional,
self-describing dirs needed so **every** one of the six contracts — not just four — gets an
isolated case.

## The trace-schema fixture's dual purpose (R1-S03 / I-31)

`violation-bad-trace-line/` is deliberately not single-purpose. Per the plan
(`specs/008-pre-public-maintenance/plan.md`: *"I-29/I-31 ... carry no `run.sh` fixture and are
instead pinned by a hand-authored violating/clean fixture folded into `check-conformance.py`"*),
this is the **only** committed pinning mechanism for the I-31 hardening
(`extensions/graphify/skills/speckit-implement-parallel/SKILL.md`'s trace-writing rule) — no
`run.sh` can drive LLM-interpreted `SKILL.md` prose, so a fixture is the only lever available.
The directory's `traces.jsonl` carries two independently-named, independently-diagnosable lines:
an ordinary trace-schema §7 rule 4 breach (line 1), and a case where `artifact` holds a
gitignored `renders/*.pptx` path instead of the `null` I-31 requires (line 12). Full detail,
including why a directory-local `.gitignore` was necessary to make the ignored-path claim
mechanically true (`git check-ignore` verified), is in that directory's own `VIOLATION.md`.

## Design notes for T008 (`check-conformance.py`) and T011 (`run.sh` wiring)

These are honest disclosures of judgment calls made while authoring the fixtures, not gaps in
the fixtures themselves — flagged here so the checker's author isn't left to rediscover them.

1. **Fixture-dir naming vs. `artifact-layout.md` §7 rule 1.** Rule 1 requires a feature
   directory's own name to match `^[0-9]{3}-[a-z0-9]+(-[a-z0-9]+)*$`. These fixture directories
   are named `conformant/`, `violation-*/` — per
   `conformance-checker-command.md`'s explicit, authoritative naming — and do **not** match that
   pattern themselves. Every fixture's `feature:`/`spec-id` frontmatter and `traces.jsonl`
   `"feature"` field is instead set to **the fixture directory's own basename** (e.g.
   `feature: "conformant"`), consistently across every file in that tree — mirroring exactly how
   `validate-profile.py`'s `check_feature()` already derives the required `feature:` value from
   `path.resolve().parent.name` regardless of whether that name is an `NNN-slug`. Recommend T008
   either (a) scope rule 1's regex check to real top-level `specs/NNN-.../` invocations and skip
   it for a directory already identified as a test fixture, or (b) simply not enforce rule 1 at
   all in the "direct" artifact-layout check, treating it as informational — either reading
   leaves `conformant/` passing and every violation dir failing for its own named reason, never
   for an incidental directory-name mismatch that would swallow the real signal.
2. **Council membership.** `specs/000-sample/` runs three anonymized council members
   (`A`/`B`/`C.md` + `peer/`). These fixtures run exactly **one** (`A.md` + `peer/A.md`) — no
   contract read for this task fixes a minimum member count, and a single member is sufficient
   to exercise every decision-record rule these fixtures need (R1–R7). Simplification, not a
   gap.
3. **`traces.jsonl` is hand-authored, not measured** — same disclosed posture as
   `specs/000-sample/traces.jsonl` and `specs/000-sample/completion-report.md`'s own
   `### Observability` note. No session was ever spawned against any of these directories;
   `feature_spend()` over any of them is computable but counts nothing that happened.
4. **`agents/assignment.md` vs. `traces.jsonl` skill-injection consistency.** None of the six
   contracts states a cross-artifact rule requiring the roster's injected-skill set to match
   what a later `implement`-phase trace record shows. `violation-assembly-cap-exceeded/`'s
   over-cap roster and its (unedited, zero-skills) `traces.jsonl` are therefore not a second,
   unintended violation — see that directory's `VIOLATION.md`.
5. **No nested `.claude/agents/`/`.claude/skills/`.** Unlike `specs/000-sample/`'s two
   deliberate oddities, these fixtures ship none — `agent-library-schema.md`'s directly-checked
   surface here is scoped to `agents/assignment.md`'s roster shape alone
   (`specs/008-pre-public-maintenance/data-model.md` E3), not the base/skill library file
   formats (out of this feature's scope; those stay delegate-or-untouched).

## Determinism

Every timestamp, id, and path in this tree is a fixed literal — no wall-clock reads, no random
ids, no machine-relative absolute paths. Re-generating or re-reading this tree at any point in
the future produces the same bytes. The one exception any fixture tree of this shape must carry
is `graphify-context.md`, which `artifact-layout.md` §3 itself exempts from the resumability
rule (disposable, regenerable) — its content here is static too, just not load-bearing.
