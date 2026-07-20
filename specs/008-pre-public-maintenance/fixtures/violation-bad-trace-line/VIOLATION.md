# Violation — bad trace line (dual purpose)

**Contract:** `docs/contracts/trace-schema.md` §7. **This fixture is deliberately dual-purpose**
(per the T007 brief, R1-S03) — it is both an ordinary `trace-schema.md` violation case *and* the
sole committed pinning fixture for the I-31 hardening
(`specs/008-pre-public-maintenance/contracts/hardening-invariants.md` H4), because I-31 edits
`speckit-implement-parallel/SKILL.md` prose that no `run.sh` can drive (`plan.md`: "I-29/I-31 ...
carry no `run.sh` fixture and are instead pinned by a hand-authored violating/clean fixture
folded into `check-conformance.py`"). Both cases live in this one `traces.jsonl`, at two
different, independently-named lines — not entangled into a single ambiguous fault.

## Case 1 — ordinary trace-schema violation (line 1)

The `specify`/`orchestrator` record carries a non-null `agent_id`
(`"agt_fixture_generalist"`). Per §7 rule 4, `agent_id != null` must hold **iff**
`role == "implementer"` — this record's role is `orchestrator`.

**Expected checker message:**

```
traces.jsonl:1 · trace-schema.md §7 rule 4: role 'orchestrator' record carries non-null
agent_id (agent_id != null must imply role == "implementer")
```

## Case 2 — the I-31 pinning case (line 12)

The `implement`/`implementer` record's `artifact` field is
`specs/008-pre-public-maintenance/fixtures/violation-bad-trace-line/renders/technical.pptx` — a
path this directory's own `.gitignore` (`renders/`) makes genuinely git-ignored (verified: `git
check-ignore -v` resolves it). Per I-31 (`hardening-invariants.md` H4.1), a task whose **sole**
output is gitignored/untracked must record `artifact: null` — never the ignored path. This line
holds the ignored path instead of `null`.

**Expected checker message:**

```
traces.jsonl:12 (I-31 pinning case) · hardening-invariants.md H4.1: artifact
'specs/.../renders/technical.pptx' is a gitignored path — a task whose sole output is
gitignored/untracked must record artifact: null
```

**Why a local `.gitignore` lives in this directory:** the repo root `.gitignore`'s
`specs/*/renders/` pattern only matches a *single* path segment between `specs/` and `renders/`;
this fixture sits several segments deep
(`specs/008-pre-public-maintenance/fixtures/violation-bad-trace-line/renders/`), which that
shallow wildcard does not reach. A committed, directory-local `renders/` `.gitignore` reproduces
the same real-world fact (rendered decks are derived, gitignored, never tracked —
`artifact-layout.md` §1) at this fixture's actual depth, so `git check-ignore` genuinely agrees
with the fixture's claim rather than the claim resting on prose alone.

**Everything else in this directory is byte-identical to `conformant/`** (mechanical
`feature:`/path substitution aside) — both cases above are the only two edited lines in
`traces.jsonl`; every other file in the tree is unchanged and independently valid.
