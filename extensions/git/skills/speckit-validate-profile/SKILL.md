---
name: "speckit-validate-profile"
description: "Validate a feature's profile.yaml against the full docs/contracts/profile-schema.md contract by shelling out to extensions/workforce/extension/scripts/validate-profile.py (installed at .specify/extensions/workforce/scripts/validate-profile.py). Resolves an explicit --feature <dir> or <profile-path> argument if given; otherwise resolves the active feature from .specify/feature.json's feature_directory, falling back to ./profile.yaml. Hard-blocks on any non-zero exit, relaying the script's own human-readable cause on stderr (FR-019) — an absent profile.yaml is VALID (P1), never a block. Adds no validation logic of its own; every rule lives in the script. Mechanical only — invokes no model and writes no traces.jsonl record."
argument-hint: "Optional: --feature <dir> | <profile-path> — forwarded verbatim to validate-profile.py; with neither given, resolves .specify/feature.json's feature_directory, falling back to ./profile.yaml"
compatibility: "Requires the workforce extension installed at .specify/extensions/workforce/ with its validator at .specify/extensions/workforce/scripts/validate-profile.py, and a PyYAML-capable Python interpreter reachable via that script's own interpreter ladder (the current interpreter, a graphify/specify shebang interpreter, python3/python, or a timeout-bounded `uv run --with pyyaml` as a last resort)."
metadata:
  author: narenkarthikbm
  source: "extensions/git/skills/speckit-validate-profile/SKILL.md — 007-oss-docs (specs/007-oss-docs), T014"
user-invocable: true
disable-model-invocation: false
---

## User Input

```text
$ARGUMENTS
```

Optional. Trim surrounding whitespace. What remains, if anything, is passed through to
`validate-profile.py` **verbatim and unparsed** — this skill does not tokenize, validate, or
interpret `--feature <dir>` vs. an explicit `<profile-path>` itself; the script's own argument
handling is the sole authority on what is well-formed, including their mutual exclusivity
(contract S1). If `$ARGUMENTS` is empty, this skill resolves context itself (see Pre-Execution) —
it does not just pass nothing through and hope the script guesses right, because unlike
`render.py`, `validate-profile.py` has no built-in awareness of `.specify/feature.json`; its own
no-argument default is the current working directory's `./profile.yaml`.

## What this is

This is the FR-019 wrapper skill for `validate-profile.py` (D-f) — the git extension owns it, the
same way it owns `verify-gate` as the mechanical hard-block primitive for a gate binding. Once
wired (T015 — **not this task**), `speckit.git.validate-profile` fires at `before_plan`,
`before_tasks`, and `before_implement`, the actual points profile.yaml's fields get consumed
(R1-S03/S21) — not `before_plan` alone. This `SKILL.md` is also directly user-invocable as
`/speckit-validate-profile` for an ad hoc check, the same dual role `verify-gate`'s primitive plays
for hooks while `cleanup` plays for a human.

**This skill is a thin wrapper — resolve context, shell out, relay the result. Nothing more.**
Every rule the profile must satisfy — `schema_version`, `feature` matching the containing
directory name, the `full_auto` P1-P4 handshake, the closed `council_tier`/`deck_render`/gate-mode
enums, unknown-key rejection at *every* nesting level, and the `gates.council`/`gates.workforce`
mapping-shape checks — lives entirely in `validate-profile.py`, never in this skill's own prose.
This skill is authored here in the git extension's **source** tree
(`extensions/git/skills/speckit-validate-profile/`); installation to `.claude/skills/` happens
later via the git extension's own reinstall — not this task's job. It shells out to the
**workforce** extension's installed validator, not a copy of its own.

## Pre-Execution

1. **Resolve the argument string** per "User Input" above — a trimmed `$ARGUMENTS`, or nothing.
2. **If `$ARGUMENTS` is non-empty**, forward it as-is in Execution below — do not parse or
   second-guess it.
3. **If `$ARGUMENTS` is empty, resolve the active feature** the same way `verify-gate`/`cleanup`
   do: read `.specify/feature.json` and extract its `"feature_directory"` value (a plain read of
   that one field — no JSON library assumed, same technique `verify-gate.sh` and `cleanup.sh` use).
   - If `.specify/feature.json` exists and `feature_directory` is readable, that becomes the
     `--feature <dir>` argument to the script (the value is already a repo-relative path, e.g.
     `specs/007-oss-docs` — pass it through whole, do not take its basename; `validate-profile.py`
     appends `/profile.yaml` to whatever directory it's given).
   - If `.specify/feature.json` is absent, unreadable, or the key can't be found, **do not guess a
     path** — fall back to invoking the script with no arguments at all, which is exactly the
     script's own `./profile.yaml`-relative-to-cwd default. This is the same fallback the task
     brief and the script's own contract both name explicitly; it is not this skill inventing a new
     default.
4. **Locate the script** at `.specify/extensions/workforce/scripts/validate-profile.py` (the
   installed path — the workforce extension's own installer copies its `extension/` directory to
   `.specify/extensions/workforce/`, so `extension/scripts/validate-profile.py` lands there). If
   it's missing, stop and report that the workforce extension's validator isn't installed in this
   repo — do not fall back to hand-checking `profile.yaml`'s shape yourself, and do not treat
   "cannot verify" as "valid." A verification that cannot run is not a passed verification.

## Execution

Run the script with `python3`:
- `$ARGUMENTS` non-empty → `python3 .specify/extensions/workforce/scripts/validate-profile.py <trimmed arguments>`
- `$ARGUMENTS` empty, `.specify/feature.json`'s `feature_directory` resolved → `python3 .specify/extensions/workforce/scripts/validate-profile.py --feature "<feature_directory>"`
- `$ARGUMENTS` empty, `.specify/feature.json` unavailable → `python3 .specify/extensions/workforce/scripts/validate-profile.py` (no arguments; the script defaults to `./profile.yaml`)

Relay its stdout, stderr, and exit code verbatim — do not reinterpret, retry, or "fix" anything it
reports. What each exit code means (all of it the script's own behavior, not this skill's):

- **`0` — VALID.** Every rule passed, INCLUDING an absent `profile.yaml` (P1 — the safest posture,
  never the fastest one; resolves to both gates `human`). Report this as valid; an absent file is
  deliberate, documented behavior, never a gap to "helpfully" flag.
- **`3` — INVALID.** A rule breach: an out-of-enum value, an unknown key at any nesting level, a
  missing required key, a scalar where a gate mapping is required (`gates.council: human` is the
  canonical example), `max_rounds != 1`, `feature` not matching the containing directory name, a
  P2/P3 `full_auto` handshake violation, or unreadable/unparseable YAML. Always accompanied by a
  human-readable message on stderr naming the offending key/value — **relay it verbatim**; this
  message IS the hard-block signal (FR-019), never fold it into a generic "invalid" summary.
- **`2` — USAGE error** (e.g. `--feature` and a positional path both given). Not a verdict on any
  `profile.yaml` — still non-zero, still relayed verbatim, but report it distinctly as a usage
  error rather than a validation failure.

**Every non-zero exit here is a hard block** on whatever phase or action this skill was invoked to
gate — this skill neither retries with a different path, nor silently proceeds past a failure, nor
attempts to edit `profile.yaml` itself to make the error go away.

## Observability — no trace

This skill invokes no model and writes no `traces.jsonl` record, in every outcome — valid, invalid,
or usage error. It is mechanical, the same class as `verify-gate.sh` and `/speckit-git-cleanup`:
there is no session here to attribute a role, model, tokens, or duration to, just the script's own
result.

## Guardrails

- Never parse or second-guess a forwarded `--feature`/`<profile-path>` argument — let
  `validate-profile.py`'s own argument handling be the sole authority, including their mutual
  exclusivity.
- Never reimplement any part of the schema, enum, gate-shape, or `full_auto` handshake checks with
  ad hoc YAML reads — every rule lives in the script; this skill's only job is resolve → shell out
  → relay.
- Never fold the script's named-cause stderr message into a generic "invalid" line — relay it in
  full; it is what lets a human or agent actually fix the offending key.
- Never treat exit `0` for an absent `profile.yaml` as anything other than valid (P1).
- Never silently treat a missing or unreachable validator script as "valid" — fail loud and report
  that the workforce extension isn't installed (default-deny: an unverifiable profile is never
  treated as a verified one).
- Never invoke a model to interpret, soften, or "fix" a validation failure.
- Never register or fire this skill as a hook, and never edit `.specify/extensions.yml` or
  `extensions/git/extension/extension.yml` — hook wiring at `before_plan`/`before_tasks`/
  `before_implement` is T015's job exclusively, not this skill's.
- Never write to `traces.jsonl` — this is a mechanical, model-free primitive.

## Completion Report

Report, concisely:
- The exact invocation resolved and run — the forwarded argument, the feature.json-derived
  `--feature <dir>`, or the bare no-argument `./profile.yaml` default.
- Outcome: VALID (including the absent-file P1 case) | INVALID | USAGE error.
- On INVALID: every violation line from stderr, verbatim, never summarized to one line.
- The exit code.
- An explicit line: no `traces.jsonl` record was written (no session ran), and no hook was
  registered or fired by this skill.

## Done When

- [ ] Context resolved in order: an explicit forwarded argument, else `.specify/feature.json`'s
      `feature_directory`, else the script's own `./profile.yaml` default — no path guessed outside
      that order.
- [ ] `.specify/extensions/workforce/scripts/validate-profile.py` located and invoked with the
      resolved argument(s) — no local reimplementation of any check.
- [ ] The script's own stdout/stderr/exit code relayed verbatim.
- [ ] Non-zero exit reported as a hard block, with the script's named-cause message surfaced in
      full.
- [ ] Exit `0` (including the absent-file P1 case) reported as valid, not flagged as suspicious.
- [ ] No model invoked, no `traces.jsonl` record written, no hook registered, no `.specify/` or
      `extension.yml` file touched.
- [ ] Completion reported to the human.
