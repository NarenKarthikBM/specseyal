# Defense Deck — Technical

**Feature**: `006-deck-render`
**Prepared by**: Session A — deck-prep (Sonnet, D18)
**Sources**: `plan.md`, `spec.md`, `graphify-context.md`

> Format: markdown v1 (D15). This deck is **git-versioned in place, not round-scoped** (D38) — `defense-deck/technical.md` is overwritten on every revision; prior versions live in git history on the feature branch, not in a `round-N/` copy.

*This is the technical deck: council members and the chairman read it in full (FR-005). The companion `overview.md` is the one-page non-technical rendering for the human gate — do not duplicate that scope here; this file can assume a technical reader.*

---

## 1. Problem Restatement

The plan-defense council's decision artifact — `council/defense-deck/overview.md`, a one-page non-technical markdown file — is read today only in a terminal or a git diff (001-FR-001, 001-SC-007). That is fine for the council itself, but it is an awkward medium for the human gate reviewer the D21 GUI roadmap already anticipates: someone approving a governance gate from a phone, or projecting the argument in a meeting, or reusing a past feature's overview as a stakeholder demo (the I-6 lineage). D15 fixed the deck's format as markdown v1 and explicitly deferred "presentational rendering" to the M5 platform GUI.

This feature (`006`, the second of the D73 α-polish trio `005`→`006`→`007`) lands that deferral clause early, in the CLI, without reopening D15: it takes the defense deck the council extension already writes as markdown and, only when a feature's profile asks for it, emits a presentation-format copy for a human to read. The markdown stays the artifact of record; nothing the council reads, nothing a gate binds, and nothing a trace records changes. The problem is narrowly the *readability* of an already-produced artifact, not a new pipeline function.

---

## 2. Chosen Approach & Rejected Alternatives

**Chosen approach**

A new, self-contained `extensions/deck-render/` extension that turns the defense deck's markdown into pptx — on demand, only when asked, never in a way that changes what the pipeline reviews or binds. The technical approach in one line: **a deterministic, model-free Python transform, wrapped in a thin skill, shipped as a separately-uninstallable extension that declares zero hooks.** Every boundary property the spec demands (FR-001/002/003) falls out of that shape rather than being enforced by discipline: model-free ⇒ trace-free ⇒ free (FR-011/SC-006); zero hooks ⇒ the seam cannot rot and cannot collide with `005`'s concurrent rewrite of the council/graphify trees (FR-012/SC-010); a separate extension ⇒ removal is `uninstall.sh` (FR-013); gitignored output ⇒ nothing to mistake for the record (FR-014/SC-005).

**Rejected alternatives**

| Alternative | Reason rejected |
|---|---|
| Fold the renderer into the **council** extension | Directly contradicts FR-013 — removal would mean surgery on council, not `uninstall.sh` — and puts render code in the tree `005-graphify-context` is concurrently rewriting, the exact collision the spec's Sequencing note exists to avoid (research.md R1). |
| A bare script under `.specify/scripts/` | No install/uninstall lifecycle, no manifest, no reinstall-survival seam to test — SC-010 would have nothing to assert against (research.md R1). |
| A `platform/` module | `platform/` is empty until M5, and this feature is explicitly *superseded* by M5 (D15/D21) in its gate-review role. Building it there would mean building the thing it is a stopgap for (research.md R1). |
| **Hand-rolled OOXML** via stdlib `zipfile` + XML templates, zero third-party dependencies | Matches the repo's stdlib-only script policy, but a minimal pptx needs a slide master/layout/theme — ~400 lines of XML boilerplate whose failure mode is a file PowerPoint silently refuses to open, exactly SC-002's risk. It would also make FR-015/SC-004's toolchain-absent path vacuous by construction, since there would be no real optional dependency to be absent (research.md R2). |
| **pandoc** (`md → pptx`) | Present on the dev host by luck, absent in general, and a *document converter the feature does not control* — FR-002's "nothing invented" would then rest on pandoc's own rendering choices rather than a deterministic mapping the team owns (research.md R2). |
| **LibreOffice headless** | Very large dependency, absent on the dev host, slow, same loss-of-control problem as pandoc (research.md R2). |
| **Build a general `profile.yaml` validator** (all enums, the P1–P5 `full_auto` handshake, unknown-key rejection) to satisfy FR-006/SC-008 | The right fix for the *system*, the wrong scope for *this feature*: it touches the `full_auto` handshake — the correctness guard on the council gate — and would turn an S-sized, additive, default-off polish feature into one that changes gate semantics, indefensible at `standard` tier as a side quest. Booked instead as an I-row; `006` ships a scoped, `deck_render`-only validator shaped so a general one can later absorb it (research.md R4, plan.md Complexity Tracking). |
| Follow the `council_tier` precedent — prose-only validation, no mechanical enforcement | Rejected: FR-006/SC-008 explicitly demand a mechanical failure on an out-of-enum value, and `council_tier` itself is the repo's live counterexample of that precedent's weakness (`council_tier: standrad` degrades silently today) — repeating it is not honoring it (research.md R4). |
| Reuse git-ext's `sha.sh` for the derived-render stamp | Returns a **commit** SHA and fails closed on an uncommitted file — the deck is routinely uncommitted at gate time (no `after_council` commit hook exists). It also cannot detect a working-tree edit, which would silently break SC-007 (research.md R3). |
| `git hash-object` (blob SHA-1) for the stamp | Works on uncommitted content, but at 40 hex chars is visually indistinguishable from a git commit SHA — inviting the exact confusion between "the render's source" and "what the gate bound" that FR-001 exists to prevent. Also needlessly requires a git subprocess (research.md R3). |

---

## 3. Architecture & Data Flow

**Grounding note.** `plan.md` does not carry a section literally titled `## Architecture & data flow`. The pipeline below is assembled faithfully from three plan-phase artifacts that together describe it: `plan.md`'s own "Implementation approach" (Phases A–D), `contracts/commands.md` §2 ("Behavior" + "Invariants"), and `data-model.md` §4 (the T1–T10 transform rules) and §5 (the O1–O5 disclosure rules). No step below is invented; each is traceable to one of those three sources.

**Performed by:** every step in this pipeline is performed by `render.py` (and its two collaborators `deck_md.py`, `profile_key.py`) — a **mechanical script**, not a model session. The `SKILL.md` wrapper only resolves the feature directory and shells out; it never reads deck content itself, and no live model session participates anywhere in the transform (FR-011). This is the load-bearing distinction the template calls out (D53): a script vs. a session is a governance fact, not a paraphrasing detail, because a model in this path would become a second author of the deck's content (FR-002).

**The pipeline, step by step:**

1. **Resolve the feature directory** — `--feature <dir>`, else `.specify/feature.json`, else the current branch (contracts/commands.md §2.1).
2. **Resolve the selection.** An explicit deck argument on the command line wins outright (FR-016); else `profile.yaml`'s `deck_render` key, validated against the closed enum `{none, technical, overview, both}`; else `none` if the file/key is absent or unreadable. **Guarantee claimed:** an out-of-enum value is a **hard failure** — exit 3, nothing rendered, nothing written — and it never silently degrades to `none` (V2, FR-006/SC-008).
3. **`none` ⇒ exit 0 immediately.** No file, one "nothing selected" line. **Guarantee claimed:** this path is byte-identical to the feature not existing (SC-001) — no observable difference in the council phase's behavior or artifacts.
4. **For each selected deck**, in order:
   a. If the source markdown is absent ⇒ **`skipped`**, not an error (O4) — the council phase simply has not run yet.
   b. **Compute the source's sha256** — a content hash of the bytes as they exist right now, via stdlib `hashlib`. **Guarantee claimed:** unlike a commit-SHA stamp, this is computable on an uncommitted file and detects a working-tree edit (research.md R3) — the property SC-007 (staleness visibility) depends on.
   c. **Remove any existing target render before attempting.** **Guarantee claimed:** a failure can never leave a stale file to be mistaken for fresh output (O5) — a failed render leaves *no* file, never an old one.
   d. **Lazily `import pptx`** inside the render function, never at module top level. `ImportError` ⇒ `failed (toolchain absent)`, routed to degrade-and-disclose, never a hard stop (FR-009/FR-010/FR-015).
   e. **Transform deterministically** per data-model.md §4's T1–T10 rules (H1 → title slide + stamp; each H2 → a new slide; H3 → a bold lead line, never its own slide; paragraphs/bullets/numbered items/blockquotes/tables render in source order, never rearranged; fenced code → a monospace box with no reflow; overflow → a deterministic `(cont.)` continuation slide; `---` consumed as structure, carrying no text; inline markup stripped to plain text) and write `renders/<deck>.pptx`. **Guarantee claimed:** same input bytes ⇒ same output content, always (I6) — no timestamps in rendered text, no heuristics, no "layout improvement," and no path that adds, re-words, summarizes, or omits content (T10) — anything the transform cannot lay out is a loud failure, never a silent simplification.
   f. Any other failure ⇒ `failed (<reason>)`. Never a partial or "fixed-up" file.
5. **Disclose a per-deck outcome** — `rendered` / `failed (<reason>)` / `skipped` — and exit per the code table below. **Guarantee claimed:** silence is never an acceptable degradation (O2); under `deck_render: both`, one rendered + one failed is reported as exactly that, never summarized as success (O3, the SC-004 "per-deck outcome" property).

**Exit codes** (contracts/commands.md §4): `0` — every selected deck rendered, or nothing selected, or a deck skipped because its markdown is absent. `2` — partial (`both` only: at least one rendered, at least one failed). `3` — invalid input (out-of-enum `deck_render`, or an unresolvable feature directory); nothing written. `4` — all selected renders failed (e.g., toolchain absent); nothing written. No non-zero exit from this command blocks anything (I5) — the codes are for the human and the test harness; no pipeline phase reads them.

**Invariants asserted across every step** (contracts/commands.md §2, Invariants I1–I7): never writes under `council/` (I1); never modifies any markdown artifact, anywhere, for any reason (I2); never writes `traces.jsonl` (I3); never invokes a model (I4); deterministic (I6); output is never git-tracked (I7).

**Fidelity verification's own architecture (SC-003)** is a second, independent pipeline worth stating separately (research.md R5, data-model.md §4): the render is produced by `render.py` via `python-pptx`, then its text is extracted by a **separate, independent** stdlib reader (`zipfile` + `xml.etree.ElementTree` pulling every `<a:t>` run out of `ppt/slides/*.xml`) — not by reading the file back through `python-pptx`, which would only prove the library round-trips its own object model, not that the *file* says what the markdown says. The comparison is bidirectional: (a) every source block's normalized plain text is a substring of the render's extracted text (nothing dropped); (b) every extracted shape's text, minus a literal, committed allowlist (the stamp lines, `(cont.)`, slide numbers), is a substring of the source's normalized text (nothing invented). Normalization is whitespace-only — Unicode (curly quotes, em-dashes, `→ ≤ ∈ ⌊⌋`, box-drawing) is never folded, so a real drop cannot hide behind a fold.

---

## 4. Project Structure & Dependency / Graph Impact

**Project Structure** (from `plan.md`)

```text
extensions/deck-render/                     # ← the entire feature, one new extension
├── README.md
├── install.sh                              # payload + skill + `installed:` registration
│                                            #   (copies testing's flock+tempfile+os.replace
│                                            #    merge, NOT git's unlocked write)
├── uninstall.sh                             # deregister FIRST, then remove payload + skill
├── extension/                               # → .specify/extensions/deck-render/
│   ├── extension.yml                        # manifest — declares ZERO hooks (FR-008/FR-012)
│   ├── commands/speckit.deck-render.md      # command provenance source
│   └── scripts/
│       ├── render.py                        # the deterministic transform (stdlib + lazy pptx)
│       ├── deck_md.py                       # markdown → block model (stdlib, no deps)
│       └── profile_key.py                   # scoped deck_render reader/validator (stdlib)
├── skills/speckit-deck-render/SKILL.md      # → .claude/skills/ — thin wrapper, no model in the path
└── test/
    ├── run.sh                               # POSIX sh; PASS/FAIL; throwaway temp dirs
    ├── extract_pptx_text.py                 # INDEPENDENT stdlib OOXML text extractor (SC-003)
    └── fixtures/
        ├── deck/{technical.md,overview.md}  # frozen golden deck (seeded from 005's — the heaviest)
        └── profiles/{none,overview,both,invalid,absent-key}.yaml
```

**Structure Decision** (verbatim from plan.md): one new extension, zero hooks, zero edits to any existing extension's source tree. This is the strongest available form of FR-012 — the feature *cannot* patch council or graphify because it never reaches into them — which keeps it disjoint from `005`'s concurrent rewrite of those trees **by construction, not by luck** (the spec's Sequencing note).

**Files changed outside the new extension** (the complete list, from plan.md — deliberately short):

| File | Change | Why |
|---|---|---|
| `.gitignore` | `+ specs/*/renders/` | FR-014; makes SC-005 (`git ls-files`) true. |
| `docs/contracts/profile-schema.md` | → 1.2: `deck_render` in §1 schema, §3 field table, §5 examples, new §8 | FR-005. Unknown keys are a validation error, so the key must be admitted before any profile may carry it. |
| `docs/contracts/artifact-layout.md` | → 1.5: `renders/` in §1 (marked GITIGNORED); §6 gains a writer row | FR-014; `renders/` is a new path with a new owner. |
| `specs/000-sample/profile.yaml` | `+ deck_render: none` | Contract-change discipline (D47/D59): the canonical fixture moves in the same commit as the contract. |
| `docs/90-DECISIONS-AND-IDEAS.md` | one D-row + I-rows | Log discipline (non-negotiable). |

**Dependency / Graph Impact — no graphify grounding was available for this feature.** Confirmed directly: `specs/006-deck-render/graphify-context.md` does not exist, and the repo root's `graphify-out/graph.json` (gitignored, D45) is also absent. `research.md`'s own Grounding note discloses the same thing and states why: `005`'s `before_plan` graphify hook is `optional: true`, and the plan was instead grounded by direct read of the extension trees, the M0 contracts, and the ten real committed decks, rather than triggering a full graph build for an S-sized feature. This section therefore states plainly what `plan.md`'s own prose claims and does **not** promote any of it to a verified graph metric (per the template's own R1-round-1 lesson: a number restated from prose unverified is exactly the failure mode that produced round-1's wrong "degree 15" claim).

What can be honestly derived from plan.md's prose alone, labeled as **engineer assertion, not graph fact**:
- The new extension touches no file under `extensions/council/` or `extensions/graphify/` — this is FR-012's own claim, verified in-plan by the "zero hooks" design (Structure Decision above) rather than by a graph query; SC-010's test suite (Phase C) is what actually checks it mechanically, via grep, not via the graph.
- The five files listed above are, per plan.md, the complete set of files touched outside the new extension. No independent fan-in/fan-out count (e.g., how many other features' profiles reference `profile-schema.md`, or how many consumers read `artifact-layout.md`) is available to corroborate or contest "deliberately short" — that word is plan.md's own characterization, not a graph-derived measurement.
- No shared/mutable-file collision list (the kind `005`'s deck produced from its own `graphify-context.md`, e.g., `.specify/extensions.yml` as a flagged highest-collision point) can be produced here, because there is no graph to query. Given this feature's install/uninstall does merge into `.specify/extensions.yml`'s `installed:` list (per the Project Structure above), a reader should treat that merge point as an *un-instrumented* collision risk, not a verified-safe one — the same caution `005`'s deck applied to its own graph blind spots, but here the whole tree is a blind spot, not one arm of it.

---

## 5. Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| **`python-pptx` produces a file a real viewer rejects**, so SC-002 ("opens in a standard presentation viewer") passes the test suite but fails a human. | Low | High — it is the feature's whole point | The test suite asserts structural validity from the raw OOXML, but "opens in a viewer" is inherently a human check. Quickstart Scenario 3 makes it an explicit, named manual step at the dogfood exit (SC-009), not an assumed one. |
| **Long table cells overflow a slide** (real decks carry 30–40-word mitigation cells). | High | Medium | T7's deterministic `(cont.)` overflow rule; fidelity is asserted on text containment, not layout beauty — an ugly-but-faithful slide passes, a pretty-but-lossy one fails, and that ordering is deliberate. |
| **Fixture drift** — the frozen fixture deck diverges from what deck-prep actually emits, so SC-003 passes against a deck shape that no longer exists. | Medium | Medium | The fixture is seeded from a real, current deck (`005`'s — the heaviest, per research.md R5) and its provenance is recorded in the fixture dir. A deck-template change is a `council` extension change; the systemic coupling is booked as an I-row. |
| **The scoped validator is mistaken for a real profile validator** by a later reader, who then trusts profiles to be validated generally. | Medium | Medium | Named explicitly as *not that* in three places: `contracts/commands.md` §5, `data-model.md` §1, and plan.md's Complexity Tracking. Plus the I-row (research.md R4). |
| `005` merges after `006`'s council convenes, and its arm-4 measurement lands on this round. | Medium | Low | Out of this spec's hands — a scheduling matter for the owner, flagged in the spec's Sequencing note. No file-level dependency exists in either direction. |
| **The scoped `deck_render` validator only fires at render time, not at profile-author time** (Complexity Tracking, plan.md) — a profile carrying `deck_render: sparkle` sits happily on disk until someone actually renders. | Medium (no author-time check exists to catch it earlier) | Low (the failure is caught, just later than ideal — the human is not silently given the wrong default) | Explicitly scoped and named as a limit rather than a defect: building the general profile validator was rejected as out of this feature's size class (it would touch the `full_auto` handshake and change gate semantics). Booked as an I-row so a later, general validator can absorb this key; the render command's own out-of-enum check remains a hard, mechanical failure (SC-008) at the point it does fire. |

---

## 6. Cost / Complexity Estimate

**This council round (`standard` tier, per `006`'s own `profile.yaml`, D61):** the D56 `standard`-tier ceremony implies **8 sessions** — 1 deck-prep (Sonnet, mechanical role, this session), 5 council members (Sonnet, mechanical role per D18), 1 consolidated peer critique (Sonnet — `standard` tier replaces `full` tier's 5 per-member peer reviews with one consolidated pass + lazy context), 1 chairman synthesis (Opus, xhigh — judgment role). `006` is **S**-sized (D73(2)) and not architecture-changing, which is exactly why `profile.yaml` selects `standard` rather than `full`.

**Downstream of this round:** council-triage — 1 session (Opus, judgment role per D18: analyze/triage), +1 conditional chairman-only delta check if a blocking suggestion forces a plan revision (the council-triage contract's FR-010 class).

**Implementation (not yet session-counted — `tasks.md` is explicitly NOT created by `/speckit-plan` for this feature; plan.md's Project Structure lists it as a future artifact):** bounded by plan.md's own Scale/Scope line — **S** (D73(2)) — "one new extension: ~2 scripts, 1 skill, 1 manifest, 1 test suite; two contract amendments; one `.gitignore` line; one D-row + I-rows." Per D18, implementation agents are Sonnet; the feature introduces **no new model role** at runtime (the renderer itself is mechanical — see §3). The one dependency it adds, `python-pptx`, is optional and lazily imported, never a hard install requirement (FR-015) — it does not enter the repo's `install.sh` cost surface at all.

**What drives complexity up, honestly stated:** the two contract amendments (`profile-schema.md`, `artifact-layout.md`) touch shared, cross-feature-consumed documents rather than files scoped to this extension alone — the kind of change the `cost`/`simplicity` lenses should weigh against the chosen approach in §2. The scoped-validator limit (§5, last row) is the other complexity signal worth the council's attention: it is a deliberate scope cut, not an oversight, but it is a cut that leaves a real gap (author-time validation) unclosed.

**Runtime cost, once shipped:** zero, by design. A rendered run's `council_spend` is claimed identical to an unrendered run's (SC-006) — the renderer makes zero model calls and writes zero trace records (FR-011), so it adds no ongoing session cost to any future council round that uses it.

---

## 7. Testability Claim & Plan-Time Verifications

**Grounding note.** `plan.md` does not carry a section literally titled `## Plan-time verifications & per-SC test coverage`. The equivalent content — every SC and FR bound to a concrete check — lives in `quickstart.md`, whose own "Coverage" table is reproduced below, cross-checked against `plan.md`'s "Phase C — the falsifiable checks" list (the six SCs Phase C names explicitly as building the committed `test/run.sh` suite: SC-001, SC-003, SC-004, SC-005, SC-008, SC-010).

### 7a. Per-SC/FR verification (from quickstart.md's Coverage table)

| SC / FR | Claim | Bound by (quickstart scenario) | Committed to `test/run.sh` per plan.md Phase C? |
|---|---|---|---|
| SC-001 | Default path untouched: zero rendered files, zero new trace records, `council/` byte-identical | Scenario 1 | **Yes** ("SC-001 default path") |
| SC-002 | Rendered overview opens in a standard viewer, stamped | Scenario 3 | No — explicitly, irreducibly manual (the file-opens-in-a-viewer check) |
| SC-003 | Bidirectional fidelity, mechanical, neither direction eyeballed | Scenario 4 | **Yes** ("SC-003, both directions") |
| SC-004 | Degrade, never halt; per-deck failure notice reaches the human | Scenario 2 | **Yes** ("SC-004 degrade") |
| SC-005 | Boundary holds mechanically: no render in `gates.yml`, `traces.jsonl`, context-in, or `git ls-files` | Scenario 5 | **Yes** ("SC-005 boundary grep") |
| SC-006 | Free: rendered run's `council_spend` identical to unrendered | Scenario 5 (same grep pass as SC-005) | Not separately named in Phase C's list, but described as part of the same Scenario-5 grep group SC-005 is committed under |
| SC-007 | Staleness visible from the stamp alone (sha256 mismatch) | Scenario 6 | **Not named** in Phase C's explicit list — quickstart shows the commands but frames them as a walkthrough, not a stated `test/run.sh` inclusion |
| SC-008 | Out-of-enum `deck_render` fails validation, exit 3 | Scenario 7 | **Yes** ("SC-008") |
| SC-009 | Dogfood exit: explicit render of `006`'s own committed overview | Scenario 9 | **Not named** in Phase C — this is a one-time, post-implement dogfood invocation (Phase D), not a repeatable suite entry |
| SC-010 | Seam survives reinstall of self, council, and graphify; clean removal | Scenario 8 | **Yes** ("SC-010 reinstall-survival") |
| FR-001–FR-016 | Every FR binds to at least one of the scenarios above | Coverage table, quickstart.md | (inherits its bound scenario's committed/manual status) |

### 7b. Tally

**7 of 10 SCs (SC-001, SC-003, SC-004, SC-005, SC-006, SC-008, SC-010) are explicitly or reasonably-inferred committed to the automated `test/run.sh` suite per plan.md's own Phase C description** (SC-006 is inferred as riding the same Scenario-5 grep pass as SC-005, since both check the same boundary in one command block, but plan.md's own Phase C bullet list does not name it separately — flagged rather than assumed). **1 of 10 (SC-002) is explicitly, irreducibly manual** — quickstart.md states this plainly ("the one genuinely manual check in this file"). **2 of 10 (SC-007, SC-009) are demonstrated in quickstart.md with runnable commands but are not named in plan.md's Phase C list of committed suite items** — SC-009 is inherently a one-time post-implement dogfood check rather than a repeatable regression test, which is a reasonable exclusion; SC-007's absence from Phase C is less clearly reasoned and is worth the council confirming rather than assuming, since staleness detection is a load-bearing SC (FR-003, FR-008) and its committed-test status is the one genuinely ambiguous entry in this table.

### 7c. Guard / branch falsifiability — does the fixture set exercise both branches?

- **The closed-enum guard (SC-008): YES, both branches are exercised.** The committed fixture set (`extensions/deck-render/test/fixtures/profiles/{none,overview,both,invalid,absent-key}.yaml`, per plan.md's Project Structure) includes `invalid.yaml`, which trips the out-of-enum failure branch, alongside `none`/`overview`/`both`/`absent-key`, which trip the valid/absent success branches. Both sides of V1/V2 (data-model.md §1) are demonstrably reachable from committed fixtures, not just the passing side.
- **The toolchain-absence guard (SC-004 vs. SC-002/SC-003): YES, both branches are exercised, by explicit design.** Research.md R6 states the degrade test forces `import pptx` to fail via a `PYTHONPATH` shadow containing a `pptx/__init__.py` that raises `ImportError` — a genuine import failure, deterministic on any host regardless of whether `python-pptx` is actually installed there — while the real-toolchain-present path (SC-002/SC-003) runs the same suite with the real library. R6 states this directly: "Both SC-003's arm (toolchain present) and SC-004's arm (toolchain absent) therefore run on the same machine, in the same suite." No test-only backdoor exists in production code (the guard's failure branch is a real `ImportError`, not a simulated flag).
- **The exit-code partiality guard (`both` producing one `rendered` + one `failed` ⇒ exit 2): AMBIGUOUS — worth flagging to the council.** Quickstart Scenario 2 states this case is "Covered by the suite; verify by hand once by making one deck unreadable" — but plan.md's Project Structure lists only a single, symmetric fixture deck (`fixtures/deck/{technical.md,overview.md}`, both present) and no fixture that deliberately makes exactly one of the two decks fail while the other succeeds. Unlike the two guards above, no committed fixture is named anywhere in plan.md, data-model.md, or the Project Structure tree that would deterministically exercise the exit-2 partial-failure branch under `deck_render: both` — quickstart's own phrasing ("verify by hand once") reads as a manual, one-time check rather than a repeatable committed assertion. This is the one guard in this feature with the same shape as round-1's flagged gap (a conditional whose failure branch has no demonstrated fixture), and it is surfaced here rather than assumed covered.

