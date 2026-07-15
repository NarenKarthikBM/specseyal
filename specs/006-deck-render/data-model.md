# Data Model — 006-deck-render

**Phase 1 output.** Entities, fields, validation rules, and the deterministic transform that is this feature's whole substance.

---

## 1. `deck_render` — the profile key

The per-feature render selector, admitted to `profile.yaml` by amendment (`profile-schema.md` → 1.2).

| Field | Type | Default | Rule |
|---|---|---|---|
| `deck_render` | enum scalar | `none` | One of `none` \| `technical` \| `overview` \| `both`. Flat scalar, **not** a mapping — `profile-schema.md` §1 reserves mapping shape for the gate blocks; this follows the `council_tier` precedent (FR-005). |

**Validation rules.**

| # | Rule | Source |
|---|---|---|
| V1 | **Absent ⇒ `none`.** A profile naming no `deck_render` renders nothing. | FR-006 |
| V2 | An **out-of-enum** value is a hard failure: non-zero exit, nothing rendered, nothing written. It **never** falls back to `none`. | FR-006, SC-008 |
| V3 | A `deck_render` key that is a mapping, list, or empty is out-of-enum ⇒ V2. | FR-005 |
| V4 | `deck_render` is a **default selection, not a hard gate.** An explicit deck argument renders that deck regardless of the profile's value — including when the profile says `none`. | FR-016 |
| V5 | An **unreadable/unparseable** `profile.yaml` (bad YAML — a merge-conflict marker, a stray tab) is a **hard failure**: non-zero exit (**exit 3**, `contracts/commands.md` §4), nothing rendered, nothing written. It is **never** folded into the absent/`none` branch — routing the *worse* malformed-input signal to the *quieter* outcome is exactly what SC-008 forbids. | FR-006, SC-008, plan I-B1 |

**Scope of enforcement (the honest boundary — see research.md R4).** V1–V5 are enforced by the deck-render extension when it reads the profile. No general `profile.yaml` validator exists in this repo, so a malformed `deck_render` is caught at **render time**, not at profile-author time. The remaining keys (`full_auto`, `gates.*`, `council_tier`) are **not** validated by this feature and remain as unenforced as they are today.

**Resolution ladder** (deliberately shorter than `council_tier`'s):

1. An explicit deck argument on the command line ⇒ **that deck** (V4). The profile is not consulted for selection.
2. Else `profile.yaml`'s `deck_render`, validated per V2/V3.
3. Else, if the profile is **absent** or is present-and-parseable but names **no `deck_render` key** ⇒ **`none`** (V1).
4. But an **unparseable** profile (bad YAML) is *not* an absent one: it is a **hard failure per V5**, never `none`. Absence is a silence; a corrupt file is a signal, and it must not be routed to the quiet default.

There is deliberately **no repo-global config fallback**. `council_tier` has one (`council-config.yml`); `deck_render` must not, because `profile-schema.md` §6 forbids a repo-level default profile, and FR-006's "absent ⇒ `none`" already gives the safe default directly. A repo-global `deck_render: both` would render decks for features that never asked — the exact thing US2 exists to prevent.

---

## 2. Defense deck (markdown) — the artifact of record, and the renderer's only input

| Field | Value |
|---|---|
| Paths | `specs/NNN-feature/council/defense-deck/technical.md`, `.../overview.md` |
| Owner | **Council extension** (`artifact-layout.md` §6). The renderer **reads only**; it never writes here. |
| Versioning | Not round-scoped; overwritten in place on a revision round (D38). Git is its version store. |
| Commit state | **Often uncommitted at render time** — there is no `after_council` commit hook. The renderer must never assume the deck is committed. |

**Construct surface the renderer must handle** (censused across all ten committed decks — this is the real input, not a guess):

| Construct | Reality in the corpus | Renderer duty |
|---|---|---|
| Frontmatter | none, in any deck | — |
| H1 | exactly 1 per file | title slide |
| H2 | 4 (overview) / 6–7 (technical) | slide break |
| H3 | technical only | bold lead line in the current slide's body |
| H4+ | never | — |
| Tables | overview: **zero**; technical: 26–47 rows, 2–5 columns, always `\|---\|` (no alignment specs) | table shape |
| Fenced code | overview: **zero**; technical: 0–5 blocks; 17 bare fences, 1 ` ```text ` | monospace text box, **no reflow** (box-drawing must survive) |
| Bullets | flat `- ` only — **zero nesting** anywhere | bullet paragraph |
| Numbered lists | rare (one deck) | numbered paragraph |
| Blockquotes | 1–2 per file, always at the top (format/citation notes) | body text — **not** droppable (see below) |
| `---` HR | section separator | consumed as structure; carries no text |
| Links / images / raw HTML | **none** | — |
| Unicode | curly quotes, em-dashes, `→ ≤ ∈ ⌊⌋ ×`, box-drawing | preserved byte-exact |

**The blockquote preamble is source text.** Each deck opens with 1–2 long blockquote blocks (the D15 format note, the citation convention). FR-002(a) says *every* heading and text block must be present in the render's extractable text, and the spec grants no exclusion rule. They are therefore **rendered**, not dropped. (A "drop the preamble" rule would be a content decision — the renderer does not make those.)

---

## 3. Rendered deck (presentation file) — the derived output

| Field | Value |
|---|---|
| Path | `specs/NNN-feature/renders/{technical,overview}.pptx` |
| Owner | **deck-render extension** — `renders/` and nothing else (`artifact-layout.md` §6, amended) |
| Tracked by git | **Never.** `.gitignore` carries `specs/*/renders/`. SC-005 asserts `git ls-files` returns none. |
| Lifecycle | Derived build product. Overwritten on every render; regenerable at will; hand-edits are lost on the next render, by design. |
| Read by the pipeline | **Never.** Not a gate binding, not a phase input, not a trace artifact (FR-001). |
| Trace record | **None** (FR-011 — mechanical, model-free, so not a session). |

### The derived-render stamp (FR-003)

Carried on the file's own face, so a stakeholder holding only the pptx cannot mistake it for the reviewed thing.

| Element | Content |
|---|---|
| Declaration | *"Derived render — NOT the artifact of record."* |
| Source path | `specs/NNN-feature/council/defense-deck/<deck>.md` |
| Source SHA | **sha256** of the source markdown's bytes at invocation, 64 hex chars |
| Pointer | *"The markdown at the path above is what the council reviewed and what the gate binds."* |

**Placement:** the full stamp on the title slide; an abbreviated stamp (declaration + short SHA) in the footer of **every** slide — a slide photographed or screenshotted out of context still says what it is.

**Why sha256 and not the gate's SHA** (research.md R3, the load-bearing correction): git-ext's `sha.sh` yields the **commit** SHA of the last commit touching the path, and *fails closed on an uncommitted file* — which the deck routinely is at gate time. Worse, a commit SHA cannot detect a working-tree edit, which would silently break **SC-007** (staleness must be visible). sha256 is a content hash, works on uncommitted bytes, matches the repo's `body_sha256` convention, and at 64 hex chars is **self-evidently not** a 40-hex git commit SHA — so no reader can confuse the render's source stamp with what `gates.yml` bound.

**Staleness (SC-007)** is therefore detectable with no bookkeeping at all: recompute the source's sha256 and compare it to the stamp. Different ⇒ the render is stale.

---

## 4. The transform — deterministic markdown → slides

The whole feature. Same input bytes ⇒ same output slides, always. No model, no heuristics, no layout "improvement".

| # | Rule |
|---|---|
| T1 | **Slide 1 is the title slide:** the deck's H1, plus the full derived-render stamp. |
| T2 | **Each H2 opens a new slide**, titled with the H2's text (inline emphasis stripped to plain text). |
| T3 | Content before the first H2 (the metadata lines, the blockquote preamble, the scope note) goes on a **Preamble** slide, following the title slide. |
| T4 | **H3 becomes a bold lead line** inside the current slide's body — never its own slide (H3 is a sub-label, and the corpus shows at most 5 per deck). |
| T5 | Paragraphs, bullets, numbered items, blockquotes, and tables render in **source order** into the current slide's body. Order is never rearranged. |
| T6 | **Fenced code renders in a monospace box with no wrapping and no reflow.** Box-drawing diagrams and directory trees must survive visually intact. |
| T7 | **Overflow:** when a slide's content exceeds a fixed line budget, it continues on a `(cont.)` slide. The budget is a constant, so the split is deterministic. `(cont.)` is the only invented text besides the stamp, and it is on the FR-002 allowlist. |
| T8 | `---` horizontal rules are consumed as structure. They carry no text, so dropping them drops no content. |
| T9 | Inline markers are stripped to plain text (`**bold**` → bold text, `` `code` `` → monospace text). The *text* is preserved exactly; only the markdown syntax is consumed. |
| T10 | **The renderer never authors.** It has no path that adds, re-words, summarizes, or omits content. Anything it cannot lay out is a **failure** (degrade + disclose), never a silent simplification. |

### Fidelity, made falsifiable (FR-002 / SC-003)

Bidirectional text containment, asserted mechanically on the committed fixture deck — neither direction eyeballed.

- **(a) Nothing dropped.** Every source block's normalized plain text is a substring of the render's extracted text.
- **(b) Nothing invented.** Every extracted shape's text, minus the allowlist, is a substring of the source's normalized plain text.
- **Extraction is independent of the writer:** text is pulled from the raw OOXML (`zipfile` + `xml.etree` over `ppt/slides/*.xml`, every `<a:t>` run) — **not** by reading the file back through the rendering library, which would only prove the library round-trips itself.
- **Allowlist** — the complete set of text the render may add: the stamp lines, `(cont.)`, and slide numbers. Nothing else. Anything else appearing is a failure, and that is direction (b) doing its job.
- **Normalization is whitespace-only.** Unicode is never folded — curly quotes, arrows, and box-drawing must match exactly, or a real drop could hide behind a fold.

Direction (b) is the load-bearing half: a render that could add or re-word content could make the pptx say what the reviewed markdown does not — the precise failure FR-001 exists to prevent.

---

## 5. Render outcome — what the human is told (FR-010)

Not a persisted artifact; the command's disclosure to its invoker. **Per deck**, so a partial failure under `deck_render: both` can never be misread as success.

| Field | Values |
|---|---|
| deck | `technical` \| `overview` |
| outcome | `rendered` \| `failed` \| `skipped (no deck present)` |
| path | the written render, when `rendered` |
| reason | the failure, when `failed` (e.g. *toolchain absent*) |

**Rules.**

| # | Rule |
|---|---|
| O1 | **Degrade, never halt** (FR-009). A render failure never fails the council phase or the gate, and never modifies a markdown artifact. |
| O2 | **Silence is not an acceptable degradation** (FR-010). Every failure is disclosed to the invoker, naming the deck and the reason, and stating that the markdown is unaffected and remains the artifact of record. |
| O3 | **Per-deck reporting.** Under `both`, one rendered + one failed reports exactly that — never a summary "success". |
| O4 | **No deck present ⇒ `skipped`, not an error.** The council phase simply has not run yet. |
| O5 | **A stale render is never presented as current** (US3-3). The write is atomic (plan I-B3): `render.py` writes the new render to a temp file in the target directory and `os.replace()`s it into `renders/<deck>.pptx` only on full success. No target is removed up front — a failed render leaves a prior good render at that path completely untouched, never partially overwritten and never pre-deleted. Staleness is defended not by clearing the target but by the sha256 stamp embedded in every render plus the `FRESH`/`STALE` verdict `render.py` prints when a prior render already exists at the target (I-B6, SC-007). |
