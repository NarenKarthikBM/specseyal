# Implementation Plan: Optional pptx Render of the Defense Deck

**Branch**: `006-deck-render` | **Date**: 2026-07-14 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/006-deck-render/spec.md`

## Summary

Build a new, self-contained `deck-render` extension that turns a council defense deck's **markdown** into a **pptx** — on demand, only when asked, and never in a way that changes what the pipeline reviews or binds.

The technical approach in one line: **a deterministic, model-free Python transform, wrapped in a thin skill, shipped as a separately-uninstallable extension that declares zero hooks.** Every property the spec's boundary demands falls out of that shape rather than being enforced by discipline:

- **Model-free ⇒ trace-free ⇒ free** (FR-011, SC-006). A mechanical transform is not a session, so it writes no `traces.jsonl` record and costs zero tokens — the `/speckit-git-cleanup` precedent exactly. It is model-free for a *governance* reason, not a performance one: a model in this path would become a second author of the deck's content, and could make the pptx say what the reviewed markdown does not.
- **Zero hooks ⇒ the seam cannot rot** (FR-012, SC-010). The extension never touches the council or graphify trees, so FR-012 holds by construction, and `005`'s concurrent rewrite of those trees cannot collide with this feature.
- **A separate extension ⇒ removal is `uninstall.sh`** (FR-013). Cheap removability is the honest consequence of being interim-by-design (superseded by the M5 GUI, D15/D21).
- **Gitignored output ⇒ nothing to mistake for the record** (FR-014, SC-005).

Three findings from Phase 0 reshaped the design and are called out because a reader would otherwise assume the opposite:

1. **The stamp cannot use git-ext's `sha.sh`.** It returns a *commit* SHA and fails closed on an uncommitted file — and the deck is routinely uncommitted at gate time (there is no `after_council` commit hook). A commit SHA also cannot detect a working-tree edit, which would **silently break SC-007**. The stamp uses **sha256 of the source bytes** instead (research.md R3).
2. **No `profile.yaml` validator exists in this repo — at all.** FR-006/SC-008 ("an out-of-enum value fails validation") is therefore unsatisfiable as written; nothing validates profiles. This feature builds a **scoped** validator for its own key and books the systemic gap as an idea rather than swallowing it (research.md R4, and Complexity Tracking below).
3. **The deck's markdown surface is narrow and knowable.** Censused across all ten committed decks: H1–H3, 2–5 column tables, bare fences containing box-drawing diagrams, flat bullets, leading blockquotes. No images, links, HTML, frontmatter, or nested lists. The renderer targets exactly this, and **fails loudly** on anything else rather than silently simplifying.

## Technical Context

**Language/Version**: Python 3 (stdlib), `#!/usr/bin/env python3` — matching every existing extension script. POSIX `sh` for install/uninstall/test.

**Primary Dependencies**: **stdlib only**, with exactly one **optional, lazily-imported** third-party package: `python-pptx` (FR-015). It is imported *inside* the render function; `ImportError` routes to degrade-and-disclose. `install.sh` never requires it and never fails without it. There is no `requirements.txt` in this repo and this feature does not add one — the established policy is stdlib-only scripts, with PyYAML discovered at runtime by the installers' interpreter ladder (`003` R2).

**Storage**: Files only. Reads `council/defense-deck/*.md` + `profile.yaml`; writes `renders/*.pptx` (gitignored). No database, no state file (principle 3 forbids one).

**Testing**: `extensions/deck-render/test/run.sh` — POSIX sh, PASS/FAIL counters, throwaway temp dirs, following `extensions/git/test/run.sh` and `extensions/testing/test/run.sh`. Golden fixture deck committed under `test/fixtures/`.

**Target Platform**: macOS + Linux dev hosts, CLI-only. No CI exists in this repo; `test/run.sh` is run by hand.

**Project Type**: CLI pipeline extension (single project, `extensions/` layout).

**Performance Goals**: Not a concern — a deck is ≤ ~210 lines and renders in well under a second. The binding constraint is **determinism**, not speed (I6): same input bytes ⇒ same output content, no timestamps in rendered text.

**Constraints**: Zero model calls, zero tokens, zero trace records (FR-011). Never writes under `council/` (§6 ownership). Never modifies a markdown artifact. Never blocks a gate or a phase (FR-009). Never appears in git's tracked set (FR-014).

**Scale/Scope**: **S** (D73(2)). One new extension: ~2 scripts, 1 skill, 1 manifest, 1 test suite; two contract amendments; one `.gitignore` line; one D-row + I-rows.

## Constitution Check

*GATE: checked before Phase 0, re-checked after Phase 1 design. Result: **PASS**, no violations to justify.*

| Principle | Verdict | Reasoning |
|---|---|---|
| **I. Artifacts Are the Contract** | ✅ **Does not bind — and that is the point** | This is not a pipeline **phase**. It reads artifacts and writes a **derived build product** that no phase ever reads (FR-001). Principle 1 governs phases; `/speckit-git-cleanup` is the standing precedent for a mechanical command that is not a phase and writes no phase artifact. The renderer adds no phase to `artifact-layout.md` §2's phase table. |
| **II. Context Hygiene** | ✅ Pass | No session is dispatched at all. The main thread shells out to a script and reads back a status. Nothing to offload, nothing to leak. |
| **III. Resumability** | ✅ Pass | **No state file** (D32 forbids one). The render is idempotent and regenerable from the markdown at any time; re-running it is always safe. The on-demand trigger (FR-008) means there is no phase state to resume *into* — the command renders whatever markdown exists at invocation. |
| **IV. Observability** | ✅ **Does not bind** | "Every **session** appends exactly one trace record." The renderer runs **no session** — it is a deterministic, model-free transform. `/speckit-git-cleanup` (`002` FR-007) is the exact precedent: mechanical steps leave no trace record, because traces record sessions (D35). This is not a tracing opt-out; there is nothing to trace. |
| **V. Subscription-Only Billing** | ✅ Pass | No model, no API call, no `ANTHROPIC_API_KEY`, zero tokens (SC-006). |
| **Model Policy (D18)** | ✅ N/A | No role, no model. Deliberately: a model here would become a second author of deck content (FR-002). |
| **Autonomy & Gates (D9)** | ✅ Pass | No new gate. The council gate's binding is untouched — `gates.yml` continues to bind `.md` SHAs only, and no rendered file appears in it (SC-005). |

Two rows read "does not bind" rather than "pass." That is deliberate and is the shape of the feature's central claim: **this is not a phase and not a session**, so the two principles that govern phases and sessions have nothing to grip. If the council disagrees with that framing, the feature's whole cost model (free, untraced, unbound) is what changes — so it is stated here plainly rather than assumed.

## Project Structure

### Documentation (this feature)

```text
specs/006-deck-render/
├── spec.md                  # complete (clarified 2026-07-14)
├── plan.md                  # this file
├── profile.yaml             # authored at plan time (the 004 precedent)
├── research.md              # Phase 0 — R1–R9
├── data-model.md            # Phase 1 — entities + the deterministic transform
├── contracts/
│   └── commands.md          # Phase 1 — /speckit-deck-render
├── quickstart.md            # Phase 1 — the runnable validation walkthrough
├── checklists/
│   └── requirements.md      # from /speckit-specify
└── tasks.md                 # NOT created by /speckit-plan
```

### Source Code (repository root)

```text
extensions/deck-render/                     # ← the entire feature, one new extension
├── README.md
├── install.sh                              # payload + skill + `installed:` registration
│                                           #   (copies testing's flock+tempfile+os.replace
│                                           #    merge, NOT git's unlocked write)
├── uninstall.sh                            # deregister FIRST, then remove payload + skill
├── extension/                              # → .specify/extensions/deck-render/
│   ├── extension.yml                       # manifest — declares ZERO hooks (FR-008/FR-012)
│   ├── commands/
│   │   └── speckit.deck-render.md          # command provenance source
│   └── scripts/
│       ├── render.py                       # the deterministic transform (stdlib + lazy pptx)
│       ├── deck_md.py                      # markdown → block model (stdlib, no deps)
│       └── profile_key.py                  # scoped deck_render reader/validator (stdlib)
├── skills/
│   └── speckit-deck-render/
│       └── SKILL.md                        # → .claude/skills/  — thin wrapper, no model in the path
└── test/
    ├── run.sh                              # POSIX sh; PASS/FAIL; throwaway temp dirs
    ├── extract_pptx_text.py                # INDEPENDENT stdlib OOXML text extractor (SC-003)
    └── fixtures/
        ├── deck/{technical.md,overview.md} # frozen golden deck (seeded from 005's — the heaviest)
        └── profiles/{none,overview,both,invalid,absent-key}.yaml
```

**Files changed outside the new extension** — the complete list, deliberately short:

| File | Change | Why |
|---|---|---|
| `.gitignore` | `+ specs/*/renders/` | FR-014; makes SC-005 (`git ls-files`) true. |
| `docs/contracts/profile-schema.md` | → **1.2**: `deck_render` in §1 schema, §3 field table, §5 examples, new §8 | FR-005. Unknown keys are a validation error, so the key must be admitted before any profile may carry it. |
| `docs/contracts/artifact-layout.md` | → **1.5**: `renders/` in §1 (marked GITIGNORED); §6 gains a writer row | FR-014; `renders/` is a new path with a new owner. |
| `specs/000-sample/profile.yaml` | `+ deck_render: none` | Contract-change discipline (D47/D59): the canonical fixture moves **in the same commit** as the contract. |
| `docs/90-DECISIONS-AND-IDEAS.md` | one D-row + I-rows | Log discipline (non-negotiable). |

**Structure Decision.** One new extension, zero hooks, zero edits to any existing extension's source tree. This is the strongest available form of FR-012: the feature *cannot* patch council or graphify because it never reaches into them — which also keeps it disjoint from `005`'s concurrent rewrite of those trees by construction, not by luck (the spec's Sequencing note).

## Implementation approach

**Phase A — the seam and the contracts** (must land first; everything else depends on the key existing).
Amend `profile-schema.md` (+ `deck_render`) and `artifact-layout.md` (+ `renders/`, + the writer row), add the `.gitignore` line, and move `specs/000-sample/profile.yaml` in the same commit. Scaffold the extension: `extension.yml` (zero hooks), `install.sh` / `uninstall.sh` (copy `testing`'s locked, atomic registry merge — **not** `git`'s unlocked write), the skill, and a test suite that starts by asserting install/uninstall round-trips `extensions.yml` byte-identically.

**Phase B — the transform.**
`deck_md.py` parses the markdown into an ordered block model (the narrow construct set from data-model.md §2; anything outside it is a **loud failure**, never a silent simplification). `render.py` maps blocks to slides per the T1–T10 rules, lazily importing `pptx` and stamping every slide. `profile_key.py` resolves and validates `deck_render`.

**Phase C — the falsifiable checks.** This is where the feature is actually *proven*, and it is the bulk of the test work:
- **SC-003, both directions**, on the frozen fixture deck, using the **independent** stdlib OOXML extractor — not a `python-pptx` round-trip, which would only prove the library round-trips itself.
- **SC-004 degrade**, forcing `ImportError` via a `PYTHONPATH` shadow — a real import failure, with **no test-only backdoor in production code**.
- **SC-001 default path**: `none` and absent both produce zero files and zero output difference.
- **SC-005 boundary grep**: no render in `git ls-files`, `gates.yml`, or `traces.jsonl`.
- **SC-008**: out-of-enum ⇒ exit 3, nothing written.
- **SC-010 reinstall-survival**: install deck-render → reinstall **council** and **graphify** → the seam still fires and no council/graphify source file changed (the `extensions/git/test/run.sh` §3 model).

**Phase D — the dogfood exit (SC-009).** Render `006`'s own committed `overview.md` via the **explicit-invocation path** (FR-016), since `006`'s own profile is necessarily `deck_render: none` — the renderer does not exist when its own council convenes. That is a bootstrap fact, not a conformance gap, and the profile keeps telling the truth about what its council actually ran with.

## Complexity Tracking

> One item. It is a **scope limit**, not a constitution violation — recorded here because the council should weigh it, not discover it.

| Violation / limit | Why needed | Simpler alternative rejected because |
|---|---|---|
| **FR-006/SC-008 are satisfied by a *scoped* validator, not a real profile validator.** `deck_render` is mechanically rejected when out-of-enum — but only **when the render command reads the profile**, not at profile-author time. A profile carrying `deck_render: sparkle` sits happily on disk until someone renders. | **No `profile.yaml` validator exists in this repo at all.** The schema — closed enums, the P1–P5 `full_auto` handshake, §3's "unknown keys are a validation error" — is enforced entirely by prose and by a model reading the file. `council_tier`, the precedent FR-005 says to follow, shipped with **zero** enforcement (`council_tier: standrad` degrades silently today). So FR-006 had no existing validation step to attach to, and something had to be built. | **Building the general profile validator** was rejected as scope. It touches the `full_auto` handshake — the *correctness guard* on the council gate — and would turn an S-sized, additive, default-off polish feature (D73(2)) into one that changes gate semantics; it cannot honestly be defended at `standard` tier as a side quest. **Doing nothing** (the `council_tier` precedent) was rejected because FR-006 and SC-008 explicitly demand a mechanical failure, and repeating that precedent's weakest property is not honoring it. The systemic gap is **booked as an I-row** in docs/90 (no profile validator; `reopen_tier` has zero consumers — a dead key; `artifact-layout.md` §7's "conformance checker built later" is still unbuilt), and `006`'s scoped validator is shaped so a general one can absorb it. |

## Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| **`python-pptx` produces a file a real viewer rejects**, so SC-002 ("opens in a standard presentation viewer") passes the test suite but fails a human. | Low | High — it is the feature's whole point | The test asserts structural validity from the raw OOXML, but *"opens in a viewer"* is inherently a human check. Quickstart makes it an explicit, named manual step at the dogfood exit (SC-009), not an assumed one. |
| **Long table cells overflow a slide** (real decks carry 30–40-word mitigation cells). | High | Medium | T7's deterministic `(cont.)` overflow; fidelity is asserted on **text containment**, not on layout beauty. An ugly-but-faithful slide passes; a pretty-but-lossy one fails. That ordering is deliberate. |
| **Fixture drift** — the frozen fixture deck diverges from what deck-prep actually emits, so SC-003 passes against a deck shape that no longer exists. | Medium | Medium | Fixture is seeded from a real, current deck and its provenance is recorded in the fixture dir. A deck-template change is a `council` extension change; the I-row notes the coupling. |
| **The scoped validator is mistaken for a real profile validator** by a later reader, who then trusts profiles to be validated. | Medium | Medium | Named explicitly as *not that* in three places: contracts/commands.md §5, data-model.md §1, and Complexity Tracking above. Plus the I-row. |
| `005` merges after `006`'s council convenes, and its arm-4 measurement lands on this round. | Medium | Low | Out of this spec's hands — a scheduling matter for the owner, flagged in the spec's Sequencing note. No file-level dependency exists in either direction. |
