# Contract — `/speckit-deck-render`

> **Status:** draft (006, plan phase). Normative for this feature.
> **Implements:** FR-004, FR-008, FR-009, FR-010, FR-011, FR-015, FR-016.
> **Follows:** `specs/002-speckit-ext-git/contracts/commands.md` (the mechanical-command precedent — `/speckit-git-cleanup`).

This feature exposes **exactly one** external interface: a standalone, human-invoked command. It registers **no hooks**, adds no pipeline phase, and is never called by another skill.

---

## 1. The command

```
/speckit-deck-render [technical|overview|both] [--feature <dir>] [--validate-profile]
```

| Layer | What it is |
|---|---|
| Skill | `.claude/skills/speckit-deck-render/SKILL.md` — a **thin wrapper**. It resolves the feature directory and shells out. It does **not** read deck content, and no model participates in the transform (FR-011). |
| Script | `.specify/extensions/deck-render/scripts/render.py` — the deterministic renderer. All behavior below is the script's. |

The skill/script split matches `/speckit-git-cleanup` → `cleanup.sh`: the model resolves context, the script does the work, and the work is therefore reproducible without a model.

### Arguments

| Argument | Meaning |
|---|---|
| *(none)* | Render exactly what the feature's `profile.yaml` selects (`deck_render`). Absent or `none` ⇒ render nothing, exit 0. |
| `technical` \| `overview` \| `both` | **Explicit selection — overrides the profile entirely** (FR-016), including when the profile says `none`. Config declares what the pipeline does on its own; an explicit human invocation is an explicit act. |
| `--feature <dir>` | Target a specific feature directory. Defaults to the active feature (`.specify/feature.json`, then the current branch). Enables the I-6 lineage: render a past feature's overview without rewriting its settled profile. |
| `--validate-profile` | Validate the profile's `deck_render` key and exit. Renders nothing. Exit 0 = valid (including absent); exit 3 = out-of-enum **or unreadable/unparseable YAML** (plan I-B1). |

**The boundary is unchanged by an explicit invocation.** A deck rendered via an explicit argument is still derived, still un-bound, still un-traced, still gitignored (FR-001, FR-014).

---

## 2. Behavior

1. **Resolve the feature directory** — `--feature`, else `.specify/feature.json`, else the current branch.
2. **Resolve the selection** — explicit argument (§1) wins; else `profile.yaml`'s `deck_render`; else `none`.
   - An **out-of-enum** `deck_render` is a hard failure: **exit 3**, nothing rendered, nothing written (FR-006, SC-008). It never degrades to `none`.
   - An **unreadable/unparseable `profile.yaml`** (bad YAML) is likewise a hard failure: **exit 3**, nothing written (plan I-B1). It is **not** folded into the `none` branch — the worse malformed-input signal must not route to the quieter outcome (SC-008).
3. **`none` ⇒ exit 0 immediately.** No file, no output beyond a one-line "nothing selected" notice. This is the default path, and it must be indistinguishable from the feature not existing (SC-001).
4. **For each selected deck:**
   a. If the source markdown is absent ⇒ **`skipped`**, not an error (O4). The council phase has not run.
   b. Compute the source's **sha256** (content hash, of the bytes as they exist now).
   c. **Write atomically — never pre-delete the target.** `render.py` writes the new render to a temp file in the target directory, then `os.replace()`s it into `renders/<deck>.pptx` only on full success (plan I-B3). No existing target is removed up front: if the attempt fails at any point, a prior good render at that path is left completely untouched, never a partial or missing file (O5).
   d. Lazily `import pptx`. **`ImportError` ⇒ `failed (toolchain absent)`** — degrade and disclose, do not halt (FR-015).
   e. Transform per the deterministic rules (data-model.md §4) and write `renders/<deck>.pptx`.
   f. Any other failure ⇒ **`failed (<reason>)`**. Never a partial or "fixed-up" file.
5. **Disclose a per-deck outcome** (§3) and exit per §4.

### Invariants

| # | Invariant |
|---|---|
| I1 | **Never writes under `council/`.** The council extension owns that subtree (`artifact-layout.md` §6). The renderer reads it and nothing more. |
| I2 | **Never modifies any markdown artifact**, anywhere, for any reason (FR-009). |
| I3 | **Never writes `traces.jsonl`.** Mechanical, model-free ⇒ not a session ⇒ no record (FR-011, the `/speckit-git-cleanup` FR-007 class). |
| I4 | **Never invokes a model.** No subagent, no token spend. SC-006 (`council_spend` identical) holds by construction. |
| I5 | **Never blocks a gate or a phase.** There is no exit code and no failure mode of this command that any pipeline phase reads (FR-009). |
| I6 | **Deterministic.** Same input bytes ⇒ byte-comparable output content. No timestamps in the rendered text, no randomness, no model. |
| I7 | **Output is never git-tracked.** `specs/*/renders/` is gitignored; SC-005 asserts `git ls-files` returns no render. |

---

## 3. Disclosure (FR-010)

Reports **per deck** — a partial failure under `both` must never read as success.

```
Deck render — 006-deck-render
  overview   rendered   specs/006-deck-render/renders/overview.pptx
  technical  FAILED     presentation toolchain not available (python-pptx not installed)

The markdown decks are unaffected and remain the artifact of record.
Install the optional toolchain to render:  pip install python-pptx
```

**Rules.** Every failure names the deck and the reason. Every disclosure — success or failure — restates that the markdown is the artifact of record. **Silence is not an acceptable degradation:** a requested render that did not happen is always said out loud.

---

## 4. Exit codes

Following the repo's script exit-code convention (workforce's `assemble.py` / `validate-categorization.py`).

| Code | Meaning |
|---|---|
| `0` | Success — every selected deck rendered, **or** nothing was selected, **or** every selected deck that lacked source markdown was skipped (skip is not a failure). |
| `2` | **Partial** — at least one selected deck rendered or was skipped, and at least one other selected deck failed (`both` only). Disclosed per deck. |
| `3` | **Invalid input** — out-of-enum `deck_render` (SC-008), an **unreadable/unparseable `profile.yaml`** (bad YAML — plan I-B1; never degrades to `none`), or an unresolvable feature directory. Nothing written. |
| `4` | **All selected decks that had a render attempted failed** — e.g. the toolchain is absent. Nothing written. Disclosed. |

**No non-zero exit from this command blocks anything** (I5). The codes are for the human and for the test harness; no pipeline phase reads them. This is the deliberate difference from `verify-gate.sh`, whose non-zero exit *is* a hard block.

### The `both` outcome matrix (I-B4)

Under `deck_render: both`, two per-deck outcomes combine. Order does not matter — `technical` and `overview` are interchangeable in this table. All six unordered pairs of `{rendered, failed, skipped}` are mapped; none is left to whatever `render.py` happens to do.

| Deck A | Deck B | Exit | Why |
|---|---|---|---|
| `rendered` | `rendered` | `0` | Both selected decks rendered. |
| `rendered` | `failed` | `2` | Partial — one succeeded, one failed. |
| `rendered` | `skipped` | `0` | A skip is not a failure — one deck rendered, the other simply had no source markdown yet (O4). |
| `failed` | `failed` | `4` | Every selected deck that was attempted failed. |
| `failed` | `skipped` | `2` | **Partial**, treated exactly like `rendered`+`failed` — a skip never counts toward "all attempted renders failed," so this is never exit `4`. |
| `skipped` | `skipped` | `0` | Neither selected deck has source markdown yet. Nothing was attempted and nothing failed. |

---

## 5. What this contract does **not** provide

Stated so a reader cannot infer it:

- **No `after_council` hook**, and no hook of any kind. The registered hook set cannot serve the gate — `after_plan` fires before the deck exists, `after_council_approve` fires after the human has already signed — and creating a new seam inside the council extension would violate FR-012. The command is on-demand precisely because of this (FR-008).
- **No general `profile.yaml` validation.** `--validate-profile` checks the `deck_render` key **only**. The other keys remain as unvalidated as they are today (research.md R4).
- **No branding, templating, export pipeline, redaction, or work-context adaptation.** Explicitly out of scope (spec, Constraints — the I-6 door is held open; nothing walks through it here).
- **No render of anything but the two defense decks.** Not the plan, not the spec, not the suggestions.
