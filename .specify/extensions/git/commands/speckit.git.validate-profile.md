---
description: "Validate a feature's profile.yaml against the full profile-schema.md contract; hard-block on invalid (FR-019)"
---

# Git Validate Profile

Resolve a feature's `profile.yaml` path and validate it against `docs/contracts/profile-schema.md`
via `validate-profile.py`. Wired (T015 — not this command file) at `before_plan`, `before_tasks`,
and `before_implement` — the actual profile-consumption points, not `before_plan` alone
(R1-S03/S21); a non-zero exit hard-blocks the phase. Also directly user-invocable as
`/speckit-validate-profile` for an ad hoc check.

## Behavior

- **In**: an optional `--feature <dir>` or explicit `<profile-path>` argument; else resolved from
  `.specify/feature.json`'s `feature_directory`, falling back to `./profile.yaml`.
- **Does**: shells out to `.specify/extensions/workforce/scripts/validate-profile.py` with the
  resolved path/flag — `schema_version`, feature-name match, the `full_auto` P1-P4 handshake,
  closed enums (`council_tier`, `deck_render`, gate modes), unknown-key rejection at every nesting
  level, and gate-shape checks (`gates.council`/`gates.workforce` must be mappings, never a scalar).
  No check lives in this command file itself.
- **Out**: exit `0` = VALID (including an absent `profile.yaml`, P1 — the safest posture); exit `3`
  = INVALID with a human-readable message on stderr naming the offending key/value (FR-019); exit
  `2` = a usage error (e.g. `--feature` and a path both given), not a verdict. Read-only, no trace.

## Execution

Run the `/speckit-validate-profile` skill, which shells out to
`.specify/extensions/workforce/scripts/validate-profile.py` (this command file is its provenance
source). No model is invoked.
