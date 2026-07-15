---
description: "Render the council defense deck's markdown to .pptx, on demand, model-free"
---

# Deck Render

Render the council defense deck's markdown into `.pptx` slides — on demand, deterministically, and only when a human asks for it. Adds no pipeline phase, blocks no gate (FR-004, FR-008, FR-009).

## Command

```
/speckit-deck-render [technical|overview|both] [--feature <dir>] [--validate-profile]
```

## Arguments

| Argument | Meaning |
|---|---|
| *(none)* | Render exactly what the feature's `profile.yaml` selects (`deck_render`). Absent or `none` ⇒ render nothing, exit 0. |
| `technical` \| `overview` \| `both` | Explicit deck selection. **Overrides the profile entirely** (FR-016), including when the profile says `none` — config declares what the pipeline does on its own; an explicit human invocation is an explicit act. |
| `--feature <dir>` | Target a specific feature directory. Defaults to the active feature (`.specify/feature.json`, then the current branch). Lets a past feature's overview be rendered without rewriting its settled profile. |
| `--validate-profile` | Validate the profile's `deck_render` key **only**, and exit. Renders nothing. Exit 0 = valid (including absent); exit 3 = out-of-enum or an unreadable/unparseable `profile.yaml`. |

## Behavior

- **In**: the feature's `council/defense-deck/*.md` (`technical.md` / `overview.md`) + `profile.yaml`'s `deck_render` key (unless overridden by an explicit argument).
- **Does**: resolve the feature directory (`--feature`, else `.specify/feature.json`, else the current branch) → resolve the selection (explicit argument wins over the profile; else the profile's `deck_render`; else `none`) → for each selected deck: hash the source (sha256 of its bytes), remove any existing target render before attempting, lazily `import pptx`, transform per the deterministic rendering rules, and write `renders/<deck>.pptx`.
- **Out**: `specs/<feature>/renders/{technical,overview}.pptx` — gitignored, derived, never bound by a gate. **Never writes under `council/`** (the council extension owns that subtree) and **never modifies any markdown artifact**, anywhere, for any reason (FR-009). Every invocation prints a per-deck disclosure line — a requested render that did not happen is always said out loud, never silently absorbed into a success-looking exit (FR-010).
- **Idempotent**: re-running with the same source bytes produces byte-comparable output. There is no state file; the render is recomputed fresh from the markdown on every invocation.
- **Fails loudly, never silently simplifies**: an out-of-enum `deck_render`, or a `profile.yaml` that is unreadable/unparseable, is a hard failure (exit 3, nothing written) — the worse malformed-input signal is never folded into the quieter "nothing selected" (`none`) outcome. A source markdown that is absent is a `skipped` outcome, not an error (the council phase may simply not have run yet). Under `both`, one deck's failure never prevents the other from being attempted and disclosed — each deck is isolated.

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Success — every selected deck rendered, **or** nothing was selected, **or** a selected deck was skipped because its source markdown does not exist. |
| `2` | Partial — under `both`, at least one deck rendered and at least one failed (or was skipped alongside a failure). Disclosed per deck. |
| `3` | Invalid input — out-of-enum `deck_render`, an unreadable/unparseable `profile.yaml`, or an unresolvable feature directory. Nothing written. |
| `4` | All selected renders failed (e.g. the `python-pptx` toolchain is absent). Nothing written. Disclosed. |

No exit code from this command blocks any pipeline phase or gate. The codes exist for the human and the test harness only — this is the deliberate difference from `verify-gate.sh`, whose non-zero exit is a hard block (FR-009).

## Execution

Run the `/speckit-deck-render` skill, which shells out to `scripts/render.py` (this command file is its provenance source). The skill resolves the feature directory and the invocation only — it does not itself read deck content, and **no model participates in the transform** (FR-011). This command registers **no hook**, of any kind: not `after_council`, not `after_plan`, not `after_council_approve`, none. It is a standalone, on-demand command that is never invoked by another skill or pipeline phase (FR-008, FR-012). Because it is model-free, it writes **no `traces.jsonl` record** — a mechanical transform is not a session, so there is nothing to trace (FR-011, the `/speckit-git-cleanup` FR-007 precedent).
