# Plan Defense Council Extension

Forces every `plan.md` through an adversarial council before task breakdown — deck prep, an
llm-council review round (independent opinions, anonymized peer review, chairman synthesis),
a triage step, and a human gate — so a plan survives contact with skepticism before
`/speckit-tasks` ever runs.

## Provides

- `speckit.council` → `/speckit-council`: deck prep + one council round (5 Sonnet members ×
  two stages, plus an Opus chairman) against `plan.md` / `spec.md`; writes
  `council/defense-deck/` and `council/round-N/`, and returns the `suggestions.md` summary.
- `speckit.council.triage` → `/speckit-council-triage`: applies accepted suggestions to
  `plan.md` and writes `council/decision-record.md`.
- `speckit.council.approve` → `/speckit-council-approve`: records the human-gate decision on
  the decision record; unlocks `/speckit-tasks`.

## Flow

```
/speckit-plan → /speckit-council → /speckit-council-triage → /speckit-council-approve → /speckit-tasks
```

Each command reads what the previous one wrote and writes exactly one artifact class — no
command mutates another's artifact. The plan only advances past the gate once a human (or,
under `full_auto`, an automated reviewer) records an `approved*` decision.

## Command skills (siblings, not hooks)

The 3 commands above are Claude Code skills, **authored in `extensions/council/skills/`** and
installed by `install.sh` to `.claude/skills/speckit-council/`,
`.claude/skills/speckit-council-triage/`, and `.claude/skills/speckit-council-approve/` —
siblings of the stock Spec Kit skills, not edits to them. A Spec Kit re-init does not clobber
them.

## Hooks

None. The council is **command-invoked**, not a pipeline hook — nothing registers under
`.specify/extensions.yml`'s `hooks:` section (unlike graphify's `before_plan` /
`before_tasks` / `before_implement`).

## Requirements

- A completed `plan.md` for the feature (the council reviews a plan, not a spec).
- A graphify graph (`graphify-out/graph.json`) is **optional**: members use it for
  receipts-checking during review. If it's absent, the council still runs deck-only and the
  chairman raises a reduced-grounding flag in `suggestions.md` — it degrades gracefully
  rather than blocking.

## Config

See `council-config.yml` for member count, lens assignments, the model map, and
`max_rounds`.
