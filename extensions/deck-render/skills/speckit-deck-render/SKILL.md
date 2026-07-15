---
name: "speckit-deck-render"
description: "Render a council defense deck's markdown into .pptx — on demand, only when asked — by shelling out to extensions/deck-render/extension/scripts/render.py (installed at .specify/extensions/deck-render/scripts/render.py). An explicit technical|overview|both argument overrides profile.yaml's deck_render entirely, including when the profile says none (FR-016); with no argument, render.py renders per the profile, or nothing if deck_render is absent/none. --feature <dir> targets a specific feature (default: the active feature, resolved by render.py itself); --validate-profile checks the deck_render key only and renders nothing. A render failure degrades and discloses per deck — it never blocks the council gate or any pipeline phase (FR-009). Deterministic and model-free: this skill reads no deck markdown itself and invokes no model (FR-011), and writes no traces.jsonl record."
argument-hint: "Optional: [technical|overview|both] [--feature <dir>] [--validate-profile] — forwarded verbatim to render.py; an absent selector renders per profile.yaml's deck_render (or nothing, if none/unset)"
compatibility: "Requires the deck-render extension installed at .specify/extensions/deck-render/ (render.py, deck_md.py, profile_key.py under scripts/). The presentation toolchain (python-pptx) is optional — its absence degrades an individual deck's render to a disclosed failure (FR-015); it never blocks install or invocation of this command."
metadata:
  author: narenkarthikbm
  source: "extensions/deck-render/skills/speckit-deck-render/SKILL.md — speckit-ext-deck-render (specs/006-deck-render), T006"
user-invocable: true
disable-model-invocation: false
---

## User Input

```text
$ARGUMENTS
```

Optional. Trim surrounding whitespace. What remains, if anything, is passed through to `render.py`
**verbatim and unparsed** — this skill does not tokenize, validate, or interpret the deck selector
(`technical`/`overview`/`both`), `--feature <dir>`, or `--validate-profile` itself. `render.py`'s
own argument handling is the sole authority on what is well-formed (`contracts/commands.md` §1).
None of this command's tokens normally contain whitespace except a `--feature` path — quote that
path if it does. If `$ARGUMENTS` is empty, `render.py` is invoked with no arguments at all.

## What this is

This is the **only command** the deck-render extension provides
(`specs/006-deck-render/contracts/commands.md` §1) — a standalone, on-demand, human-invoked render
of a council defense deck's markdown into `.pptx`. The extension registers **zero hooks**
(`extension/extension.yml`): nothing in the pipeline triggers a render automatically, and this
command triggers nothing else in the pipeline. That is the deliberate seam this feature is built
around (FR-008/FR-012) — there is no seam a hook could attach to that would fire at the moment a
rendered deck would actually be current, so rendering only ever happens because a human asked for
it, right now.

**This skill is a thin wrapper — resolve context, shell out, relay the result. Nothing more.**
What it resolves: the location of the installed script. What it does *not* resolve: any deck
content, and it does not compute the target feature directory itself. `render.py` performs feature
resolution internally — `--feature` if given, else `.specify/feature.json`, else the current
branch (`contracts/commands.md` §2 step 1) — the same self-resolving shape `cleanup.sh` uses for
the git extension's one human-invoked command. This skill's only job regarding `--feature` is to
forward it through unmodified when the human supplied it, and to pass nothing when they didn't,
letting the script fall back on its own.

**This skill runs no model and reads no deck content — the FR-011 property, stated plainly.** It
never opens `council/defense-deck/*.md`, `profile.yaml`, or a rendered `.pptx` to reason about
their contents; that would put a model back in the deck-content path, which is exactly what this
feature exists to avoid — a model in that path could become a second author of what the council
already reviewed, making the pptx say what the reviewed markdown does not. Every rule that governs
what actually gets rendered — deck-selection precedence, profile validation, per-deck transform,
per-deck disclosure, exit codes — lives entirely in `render.py` (and the modules it imports,
`deck_md.py` and `profile_key.py`; T013–T015), never in this SKILL's own prose.

## Pre-Execution

1. **Resolve the argument string** per "User Input" above — a trimmed `$ARGUMENTS`, or nothing.
2. **Locate the script** at `.specify/extensions/deck-render/scripts/render.py` (the installed
   path — `install.sh` copies this extension's `extension/` directory to
   `.specify/extensions/deck-render/`, so `extension/scripts/render.py` lands there, alongside its
   sibling modules `deck_md.py` and `profile_key.py`, which it imports from the same directory).
   If it's missing, stop and report that the deck-render extension isn't installed in this repo —
   do not fall back to reading or transforming any deck content yourself as a substitute.

## Execution

Run the script:
- `$ARGUMENTS` empty → `python3 .specify/extensions/deck-render/scripts/render.py`
- `$ARGUMENTS` non-empty → `python3 .specify/extensions/deck-render/scripts/render.py <trimmed arguments>`

Relay its stdout, stderr, and exit code — do not reinterpret, retry, "fix", or re-render anything
it reports. What it does, per `contracts/commands.md` §2 (all of it the script's own behavior, not
this skill's):

1. Resolve the feature directory (`--feature`, else `.specify/feature.json`, else the current
   branch).
2. Resolve the deck selection: an explicit `technical`/`overview`/`both` argument overrides
   `profile.yaml`'s `deck_render` entirely (FR-016, including when the profile says `none`); absent
   an explicit argument, the profile's `deck_render` decides, defaulting to `none` when the key is
   absent. An out-of-enum `deck_render` value or an unreadable/unparseable `profile.yaml` is a hard
   failure (exit 3) — it **never** silently degrades to `none`.
3. `none` (no explicit argument and no/empty profile selection) ⇒ exit 0 immediately, nothing
   rendered, a one-line "nothing selected" notice.
4. For each selected deck: skip (not an error) if the source markdown is absent; otherwise hash,
   transform, and atomically write `renders/<deck>.pptx`, degrading to a disclosed per-deck failure
   on any transform error or on `ImportError` when the optional `python-pptx` toolchain is absent
   (FR-015) — never a partial or "fixed-up" file.
5. Disclose a per-deck outcome (`rendered` / `failed (<reason>)` / `skipped (no deck present)`) and
   exit per the code table below.

`--validate-profile` short-circuits step 4 entirely: it checks only the `deck_render` key and
renders nothing (exit 0 = valid, including absent; exit 3 = out-of-enum or an unreadable/
unparseable `profile.yaml`).

### Exit codes (`contracts/commands.md` §4) — relay, never reinterpret

| Code | Meaning |
|---|---|
| `0` | Every selected deck rendered, or nothing was selected, or a selected deck was skipped because its markdown is absent. |
| `2` | Partial — at least one deck rendered, at least one failed (`both` only). |
| `3` | Invalid input — out-of-enum `deck_render`, an unreadable/unparseable `profile.yaml`, or an unresolvable feature directory. Nothing written. |
| `4` | All selected renders failed (e.g. the toolchain is absent). Nothing written. |

**No non-zero exit from this command blocks anything (I5).** These codes are for the human and for
a test harness, not for any pipeline phase — unlike `verify-gate.sh`, whose non-zero exit *is* a
hard block, nothing downstream in this pipeline reads `render.py`'s exit code. Report it to the
human as-is; do not treat a non-zero exit here as a reason to halt, retry, or escalate anything
else in the session.

## Idempotent re-run

Re-running this skill is always safe. `render.py` removes any existing target render before
attempting a fresh one, so a failed re-run never leaves a stale file mistaken for current output,
and a successful re-run simply overwrites the prior `.pptx` with the current source's transform.
There is no state file and nothing here to get out of sync — the render always reflects whatever
markdown exists on disk at the moment this command runs.

## Observability — no trace

This skill invokes no model and writes no `traces.jsonl` record, in every outcome (FR-011, the
`/speckit-git-cleanup` FR-007 class). A mechanical, model-free transform is not a session, so there
is no session here to attribute a role, model, tokens, or duration to — just the script's own
per-deck result.

## Guardrails

- Never read `council/defense-deck/*.md`, `profile.yaml`, or a rendered `.pptx` in this skill's own
  reasoning — all deck-content handling belongs to `render.py`.
- Never invoke a model to author, summarize, reformat, or "improve" any part of a render — the
  transform is fully mechanical, and a model anywhere in this path would make the pptx a second,
  unreviewed author of the deck's content.
- Never parse, validate, or second-guess the deck selector, `--feature` value, or
  `--validate-profile` flag in this skill's own logic — forward the trimmed argument string as-is
  and let `render.py`'s own argument handling and `profile_key.py`'s validation be the sole
  authority.
- Never treat this command's non-zero exit as blocking anything else in the pipeline or the current
  session (I5) — report it and move on.
- Never reimplement or bypass `render.py`'s logic with ad hoc file reads or writes — this skill's
  only job is to invoke the script and relay its result.
- Never write to `traces.jsonl` for this command — it is sessionless by contract (FR-011).

## Completion Report

Report, concisely:
- The exact invocation run (arguments forwarded, or "none").
- The feature directory `render.py` resolved (from its own stdout/report), if disclosed.
- The per-deck outcome table `render.py` printed — `rendered` / `failed (<reason>)` /
  `skipped (no deck present)` — verbatim, never summarized into a single "success"/"failure" line
  when the run was `both` and outcomes differed.
- The exit code and its meaning from the table above.
- On any `failed` deck: the script's own reason, and the standing reminder it prints — the markdown
  is unaffected and remains the artifact of record.
- An explicit line: no `traces.jsonl` record was written (no session ran); no deck content was read
  or transformed by this skill itself.

## Done When

- [ ] `.specify/extensions/deck-render/scripts/render.py` located and invoked with either no
      arguments or the trimmed `$ARGUMENTS`, unparsed by this skill.
- [ ] The script's own stdout/stderr/exit code relayed verbatim — no reinterpretation, retry, or
      re-render logic added here.
- [ ] The per-deck disclosure relayed in full, never collapsed into a single pass/fail summary.
- [ ] The non-zero-exit-never-blocks guardrail (I5) honored — no downstream action gated on this
      command's exit code.
- [ ] No deck markdown, `profile.yaml`, or rendered `.pptx` read by this skill's own reasoning.
- [ ] No model invoked and no `traces.jsonl` record written.
- [ ] Completion reported to the human.
