# Research — 006-deck-render

**Phase 0 output.** Every NEEDS CLARIFICATION from Technical Context resolved below. Each entry: **Decision → Rationale → Alternatives rejected**.

Grounding note: this feature's `graphify-context.md` was **not** generated — the `before_plan` graphify hook is `optional: true` and `graphify-out/graph.json` does not exist in this clone (it is gitignored, D45). Rather than trigger a full graph build for an S-sized feature, the plan was grounded by direct read of the extension trees, the M0 contracts, and the ten real committed decks. Disclosed here rather than left implicit (the D46(4) reduced-grounding ethos).

---

## R1 — Where the renderer lives: a new `extensions/deck-render/` extension

**Decision.** A new, self-contained extension at `extensions/deck-render/`, following the majority convention (`git`, `council`, `graphify`, `workforce`): payload at `extension/`, skills at top-level `skills/`, tests at `test/`.

**Rationale.** FR-013 requires the feature be **cheaply removable** — "with it absent or disabled, the council/gate pipeline is byte-identical to its pre-006 behavior." An extension is precisely the repo's unit of install/uninstall, and `uninstall.sh` *is* the removability mechanism, already proven byte-identical by the round-trip test (`extensions/testing/test/run.sh` §4 diffs `extensions.yml` against its pre-install baseline). FR-012 forbids source edits into the council extension; a separate extension satisfies that by construction, not by discipline.

**Alternatives rejected.**

| Alternative | Reason rejected |
|---|---|
| Fold the renderer into the **council** extension | Directly contradicts FR-013 (removal would mean surgery on council, not `uninstall.sh`) and puts render code in the tree that `005-graphify-context` is concurrently rewriting — the exact collision the spec's Sequencing note exists to avoid. |
| A bare script under `.specify/scripts/` | No install/uninstall lifecycle, no manifest, no reinstall-survival seam to test — SC-010 would have nothing to assert against. |
| A `platform/` module | `platform/` is empty until M5 and this feature is explicitly *superseded* by M5 (D15/D21). Building it there would mean building the thing it is a stopgap for. |

---

## R2 — Rendering toolchain: `python-pptx`, lazily imported

**Decision.** `python-pptx`, imported **inside** the render function, never at module top level. `ImportError` is caught and routed to the degrade-and-disclose path (FR-009/FR-010). Nothing in `install.sh` requires it; nothing in the repo declares it.

**Rationale.** The clarify session (2026-07-14) ratified the dependency posture as **optional/lazy** — FR-015. `python-pptx` is the minimal library that emits OOXML a real viewer accepts, which is what SC-002 ("opens in a standard presentation viewer") actually demands. The lazy import *is* the FR-015 check; it costs no new machinery.

Verified on this host: `python-pptx` is **absent**. That is not a problem — it means SC-004's toolchain-absent arm is the *default* state here, testable without contrivance, and it confirms FR-015's premise that a hard dependency would fail installs in the field.

**Alternatives rejected.**

| Alternative | Reason rejected |
|---|---|
| **Hand-rolled OOXML** via stdlib `zipfile` + XML templates (zero dependencies) | Tempting, and it matches the repo's stdlib-only script policy (`003` R2). Rejected on two grounds: (a) a minimal pptx needs a slide master, layout, and theme — ~400 lines of XML boilerplate whose failure mode is *a file PowerPoint silently refuses to open*, which is exactly SC-002; (b) it would make FR-015/SC-004's toolchain-absent path **vacuous by construction** — the spec's clarified posture presupposes a real optional dependency. Worth revisiting only if the optional dep proves a field problem. |
| **pandoc** (`md → pptx`) | Present on this host by luck, absent in general; a heavier dependency than the library. Worse: it is a *document converter* we do not control, so FR-002's "nothing invented" would rest on pandoc's rendering choices rather than on our own deterministic mapping. |
| **LibreOffice headless** | Very large dependency, absent here, slow, and the same loss-of-control problem as pandoc. |

---

## R3 — The stamp's SHA is a **content** hash (sha256), *not* git-ext's commit SHA

**Decision.** The derived-render stamp (FR-003) names the source path and the **sha256 of the source markdown's bytes as they exist at invocation** — computed with stdlib `hashlib`. It is labeled in the stamp as a content SHA.

**Rationale — this is a load-bearing correction, not a detail.** The obvious move would be to reuse git-ext's `sha.sh`. It is wrong here, twice over:

1. `sha.sh` returns `git log -1 --format=%H -- <path>` — the **commit** SHA of the last commit touching the file, and it **fails closed (exit 1) when the file has never been committed.** There is **no `after_council` commit hook** in `.specify/extensions.yml` (only `after_council_approve`, which writes `gates.yml`), so the freshly-written defense deck is routinely **uncommitted** at exactly the moment the human renders it at the gate. `sha.sh` would simply refuse.
2. Even when the deck *is* committed, a commit SHA cannot detect a **working-tree edit**. SC-007 requires that "when a deck's markdown changes after a render, the stale render is detectable from its own stamp." A commit-SHA stamp would stay byte-identical across an uncommitted deck revision — **silently breaking SC-007**, the very property the stamp exists to provide.

sha256 also has a happy structural property: at 64 hex chars it is **self-evidently not** a git commit SHA (40 hex), so a reader can never confuse the render's content stamp with the commit SHA that `gates.yml` binds. The two SHAs mean different things, and now they *look* different. This matches the repo's existing content-hash convention — `body_sha256` in `agent-library-schema.md` §2.

**Alternatives rejected.**

| Alternative | Reason rejected |
|---|---|
| Reuse `sha.sh` (commit SHA) | Fails closed on the uncommitted deck (the common case at the gate); cannot detect working-tree edits ⇒ breaks SC-007. |
| `git hash-object` (blob SHA-1) | Works on uncommitted content, but it is 40 hex chars — visually identical to a commit SHA, inviting exactly the confusion between "the render's source" and "what the gate bound" that FR-001 exists to prevent. Also needlessly requires a git subprocess. |

---

## R4 — Profile validation: a **scoped** `deck_render` validator, and the systemic gap booked as an idea

**Decision.** The deck-render extension ships a **stdlib, closed-enum reader/validator for its own key only**. It hard-fails (non-zero exit, nothing written) on an out-of-enum `deck_render`, and it is invoked before any rendering work. It is also runnable standalone (`--validate-profile`) so the check is a real, executable step and not merely a side effect. It does **not** validate the rest of `profile.yaml`.

**Rationale — and the finding that forced it.** Research surfaced that **no profile validator exists anywhere in this repo.** `profile.yaml`'s schema — the closed enums, the P1–P5 `full_auto` handshake, and §3's "unknown keys are a **validation error**, not a warning" — is enforced entirely by prose and by a model reading the file in a SKILL.md instruction. Every consuming skill explicitly disclaims validation and defers to an owner that does not exist ("that is `profile.yaml`'s own conformance, owned upstream"). `council_tier`, the exact precedent FR-005 tells this key to follow, shipped with **zero** mechanical enforcement: a typo'd `council_tier: standrad` degrades silently today.

That makes FR-006 and SC-008 — "an out-of-enum value MUST **fail validation**" — **unsatisfiable as written**, because there is no "when the profile is validated" step in the system to hook onto. Something had to be built.

The scoped validator is the smallest honest thing that satisfies FR-006/SC-008: a closed enum that mechanically rejects `deck_render: sparkle` rather than silently degrading to the default that happens to be safe (`none`) — which is precisely the failure `profile-schema.md` §3 names.

**The honest limit, stated rather than buried:** because nothing validates profiles *at author time*, a profile carrying `deck_render: sparkle` is rejected **when the render command reads it**, not when it is written. A user who never renders never sees the error. This is a narrower guarantee than "the profile is invalid," and it is recorded in plan.md's **Complexity Tracking** for the council to weigh rather than smuggled past it.

**Alternatives rejected.**

| Alternative | Reason rejected |
|---|---|
| **Build the general `profile.yaml` validator** (all enums, P1–P5 handshake, unknown-key rejection) | This is the right thing for the *system* and the wrong thing for *this feature*. It is a feature in its own right: it touches the `full_auto` handshake — the **correctness guard** on the council gate — and would turn an **S**-sized, additive, default-off polish feature (D73(2)) into one that changes gate semantics. It cannot be defended at `standard` tier as a side quest. **Booked as an I-row instead** (see below). |
| **Follow the `council_tier` precedent — prose only, no enforcement** | Rejected: FR-006 and SC-008 explicitly demand a mechanical failure, and the whole point of a closed enum is that a typo must not silently degrade. Repeating `council_tier`'s weakest property is not a precedent worth honoring. |

**Booked to `docs/90` in this session (log discipline):** an **I-row** recording that no `profile.yaml` validator exists, that `council_tier`/`reopen_tier`/`max_rounds` are consequently unenforced (`reopen_tier` has **zero** consumers — a dead key), and that `artifact-layout.md` §7's "any conformance checker built later must pass it" remains unbuilt. A later feature should own it; `006` shapes its scoped validator so a general one can absorb it.

---

## R5 — Fidelity verification (SC-003): render with the library, extract with an **independent** stdlib reader

**Decision.** The bidirectional containment check (FR-002) renders with `python-pptx`, then extracts the render's text with a **separate, stdlib-only reader**: `zipfile` + `xml.etree`, pulling every `<a:t>` text run out of `ppt/slides/*.xml`. The two directions are then substring assertions over whitespace-normalized text.

**Rationale.** Verifying a `python-pptx` render by reading it back *with `python-pptx`* would only prove the library round-trips its own object model — it would not prove the **file** says what the markdown says. An independent reader that goes to the raw OOXML is adversarially stronger and is what makes SC-003 a real check rather than a tautology. It is also ~20 lines of stdlib.

**The comparison, made precise** (otherwise the test is nonsense):

- **Source side.** Parse the markdown into blocks; for each block take its **plain text with inline markers stripped** (`**bold**` → `bold`, `` `code` `` → `code`). The render contains rendered text, not markdown syntax, so the comparison must be against stripped text.
- **Render side.** Concatenate the `<a:t>` runs per shape into shape-text.
- **(a) Nothing dropped:** every source block's normalized plain text is a substring of the render's concatenated normalized text.
- **(b) Nothing invented:** every render shape-text, after removing the allowlist, is a substring of the source's normalized plain text.
- **Allowlist (the only permitted additions):** the derived-render stamp lines, and structural chrome — the continuation marker (`(cont.)`) and slide numbering. Nothing else. The allowlist is a literal, committed list; anything not on it that appears in the render is a **failure**, which is direction (b) doing its job.
- **Normalization is whitespace-only.** Unicode is **not** folded: real decks carry curly quotes, em-dashes, `→`, `≤`, `∈`, `⌊⌋`, and box-drawing characters, and folding them would hide genuine drops.

**Fixture.** A **frozen** deck committed at `extensions/deck-render/test/fixtures/deck/`, seeded from the heaviest real deck (`005`'s technical deck: 201 lines, 38 table rows, H3s, a box-drawing tree in a fence, long multi-sentence table cells) plus a real overview. **Not** the live `specs/000-sample/` deck: it is a legacy-shaped artifact (its overview has *no* H2 headings at all, and it hard-wraps mid-sentence), it can legitimately change under the test, and a golden fixture must be byte-stable and owned by the test.

---

## R6 — Forcing toolchain absence (SC-004) without a production backdoor

**Decision.** The degrade test forces `import pptx` to fail by prepending a temp dir to `PYTHONPATH` containing a `pptx/__init__.py` that raises `ImportError`. No environment variable, flag, or branch exists in production code to simulate absence.

**Rationale.** A test-only backdoor (`SPECSEYAL_FORCE_NO_TOOLCHAIN=1`) in the render script would be a code path that ships to users and can be tripped in the field — and the council would rightly attack it. The `PYTHONPATH` shadow makes the import *genuinely* fail, exercising the real degrade path, and it is deterministic on **any** host regardless of whether `python-pptx` is actually installed there. Both SC-003's arm (toolchain present) and SC-004's arm (toolchain absent) therefore run on the same machine, in the same suite.

---

## R7 — Output location and gitignore (FR-014)

**Decision.** Renders are written to `specs/NNN-feature/renders/{technical,overview}.pptx`. `.gitignore` gains `specs/*/renders/`.

**Rationale.** FR-014 requires a gitignored, derived build product **outside** the council-owned `council/` subtree (`artifact-layout.md` §6 — no writer touches another's artifact). Keeping it inside the feature directory keeps the render beside the thing it renders (discoverable, and the on-demand command needs no path config); the gitignore keeps it out of the tracked set, which is what SC-005 greps for (`git ls-files` returns no rendered output).

This requires **two contract amendments**, both in the same commit as the code (the D47/D59 contract-change discipline):

- `artifact-layout.md` §1 gains the `renders/` path (marked GITIGNORED) and §6 gains a writer row: **deck-render extension → `renders/` and nothing else.**
- `profile-schema.md` gains the `deck_render` field (→ 1.2), and the canonical fixture `specs/000-sample/profile.yaml` gains `deck_render: none` in that same commit.

---

## R8 — The seam (FR-012 / SC-010): zero hooks

**Decision.** `deck-render`'s `extension.yml` declares **no hooks at all**. Its seam is its registration in `.specify/extensions.yml`'s `installed:` list plus its skill at `.claude/skills/speckit-deck-render/`.

**Rationale.** FR-008 requires a standalone, on-demand command explicitly *not* wired into the council phase's execution — so there is no hook to declare. The `testing` extension is the exact precedent: its manifest declares zero hooks and documents why. This is the strongest possible form of FR-012: the extension cannot make a source edit into council or graphify because it never touches them.

**SC-010 is then a concrete regression** (modeled on `extensions/git/test/run.sh` §3): install deck-render → reinstall **council** and **graphify** → assert the payload, the skill, and the `installed:` entry all survive, and assert no file under `extensions/council/` or `extensions/graphify/` was modified.

---

## R9 — Model-free, therefore trace-free (FR-011 / SC-006)

**Decision.** The SKILL.md is a thin human wrapper that shells out to the render script. No subagent is dispatched, no model reads or writes deck content, and **no `traces.jsonl` record is written**.

**Rationale.** Precedent is exact: `/speckit-git-cleanup` wraps `cleanup.sh` and writes no trace record (`002` FR-007) because traces record **sessions**, and a deterministic mechanical transform is not a session (D35 + principle 4). This is also what makes SC-006 (`council_spend` identical) true by construction rather than by measurement.

The deeper reason the renderer is model-free is FR-002: a model in this path would become a **second author** of the deck's content and could make the pptx say what the reviewed markdown does not. Determinism here is a governance property, not a performance one.
