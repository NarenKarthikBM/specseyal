# Categorization — 007-oss-docs

> **Source binding (S14):** derived from `tasks.md @ ef8325d` (17 tasks). `tasks.md` had no uncommitted
> local changes at read time (`git status --short` empty).

## Categorization table

| task_id | type | specialization | preserves_behavior | runtime_consumed | tags |
|---|---|---|---|---|---|
| T001 | `docs` | `devtools-cli` | false | false | markdown, readme, onboarding, pipeline, quickstart, license |
| T002 | `docs` | `devtools-cli` | false | false | markdown, contributing, log-discipline, dogfooding, commit-convention, branch-convention |
| T003 | `docs` | `general` | false | false | markdown, code-of-conduct, contributor-covenant, community, governance |
| T004 | `docs` | `security` | false | false | markdown, security-policy, vulnerability-disclosure, private-reporting |
| T005 | `docs` | `devtools-cli` | false | false | markdown, github, issue-template, bug-report |
| T006 | `docs` | `devtools-cli` | false | false | markdown, github, issue-template, feature-request |
| T007 | `docs` | `devtools-cli` | false | false | markdown, github, pull-request-template, commit-convention |
| T008 | `endpoint` | `devtools-cli` | false | false | bash, shell, posix, docs-check, reference-resolution, leakage-check, standalone, non-ci |
| T009 | `service` | `devtools-cli` | false | false | python, yaml, stdlib, validation, contract, enum, interpreter-ladder, fail-closed, cli |
| T010 | `test` | `qa-automation` | false | false | yaml, fixture, golden, profile, contract-derived, malformed-class |
| T011 | `test` | `qa-automation` | false | false | bash, test-harness, golden, regression, enum-equivalence, stderr-assertion, interpreter-shadowing, timing-assertion |
| T012 | `test` | `qa-automation` | false | false | install, reinstall, idempotent, mirror-sync, drift-guard, installer |
| T013 | `test` | `qa-automation` | true | false | verification, pre-flight, adoption, profile, regression-guard, dogfood |
| T014 | `endpoint` | `security` | false | false | skill, wrapper, cli-command-wrapper, shell-out, hard-block, fail-closed |
| T015 | `scaffold` | `security` | false | false | yaml, hooks, manifest, extension, fail-closed, priority-1, gate-critical, enforcement |
| T016 | `docs` | `devtools-cli` | true | false | graphify, graph-refresh, post-merge, housekeeping, provenance, cross-extension-coupling |
| T017 | `test` | `qa-automation` | true | false | quickstart, e2e, integration-gate, sc-mapping, validation, dogfood |

## Cap Check

`general 1 / total 17 (≤ max(1, ⌊0.20 × 17⌋) = 3)`

## Notes for the human reviewer

**Type distribution** (8-value enum): `docs` 8 (T001–T007, T016) · `endpoint` 2 (T008, T014) · `service` 1 (T009) · `scaffold` 1 (T015) · `test` 5 (T010–T013, T017) · (`data-model` 0, `ui` 0, `infra` 0). All in-enum.

**Specialization distribution** (11-value enum): `devtools-cli` 9 · `qa-automation` 5 · `security` 3 (T004, T014, T015) · `general` 1 (T003).

- **T001–T007, T016 are `docs`.** T001–T007 are all `*.md` outside `specs/`, matching the rule directly. **T016 is the one imperfect fit**: its deliverable is `graphify-out/graph.json` (not `*.md`), so the literal `docs` path clause doesn't fire; no other `type` clause fits either (it isn't build/tooling config, a schema/model path, a service/route/CLI-manifest, or under `tests/`). The task's actual character — regenerate an already-existing generated artifact via existing tooling, no new authored logic — mirrors `002-speckit-ext-git`'s T019 (`regenerate graphify-context.md`, typed `docs`/`devtools-cli`, `preserves_behavior: true` "inert — docs") closely enough that I've followed that precedent rather than force a worse-fitting type. Flagged here per instructions rather than silently reconciled; a `docs/90` D-row may be warranted if this "regenerate a non-`.md` generated artifact" shape recurs.
- **T008 vs T009 (`endpoint` vs `service`) — resolved by wrapper-layer position, following `003-workforce`'s own precedent.** `003` typed `validate-categorization.py`/`validate-skill.py` (helper scripts shelled out to by a separate command/skill wrapper) `service`, while the command/skill wrapper *itself* (`T012`, `T016`, `T017` in `003`) was `endpoint`. Here, `T014`'s own description says it "shell[s] out to `validate-profile.py`" — so `validate-profile.py` (T009) is the helper script → `service`, and `T014` (the wrapper skill + command provenance file that IS the directly-invoked `speckit.git.validate-profile` primitive) → `endpoint`. `T008` (`check-oss-docs.sh`) has **no separate wrapper** anywhere in this `tasks.md` — it is itself the standalone, directly-run, named acceptance check with its own non-zero+named-offender exit contract, matching `004`/`005`'s "named, directly-invoked CLI primitive with its own exit-code contract" `endpoint` precedent (`verify-gate.sh`, `commit.sh`, `augment.sh`, `freshness.sh`, etc.) rather than the `service` pattern.
- **T015 is `scaffold` regardless of its non-Setup phase heading** — `extension.yml`/`extensions.yml` edits match the taxonomy's own explicit `extension.yml` example, exactly as `004-testing-completion` noted for its own `T005`.
- **`security` specialization (T004, T014, T015).** `T004` (`SECURITY.md`) is pure vulnerability-reporting-channel content — no other lane's subject matter appears in it. `T014`/`T015` are the fail-closed gate-enforcement wiring (hard-block on non-zero, mandatory priority-1 hook, "no fail-open bypass by design" per plan.md's Complexity Tracking) — the same authorization/fail-closed pattern that earned `002-speckit-ext-git`'s `verify-gate.sh`/`gates.sh`/`on-council-approve.sh` trio their `security` lane, distinct from `T009` itself (the general contract validator, most of whose rule surface — required keys, enums, unknown-key-is-error, YAML parseability — is generic contract validation, not access control), which stays `devtools-cli` to match its structural siblings `validate-categorization.py`/`validate-skill.py`.
- **T003 is the sole `general`.** `CODE_OF_CONDUCT.md`'s content (Contributor Covenant) carries no dominating technical lane — unlike `T001`/`T002`/`T005`–`T007` (devtools/repo-tooling content) or `T004` (security-policy content), it is pure community-governance boilerplate. Not written `general` to fill room — it is the one task in this feature with a genuinely empty technical-lane signal.
- **`preserves_behavior: true` (T013, T016, T017).** All three are `mutates=-` or inert-regeneration tasks per the taxonomy's literal rule: `T013` is a read-only pre-flight verification run over existing `profile.yaml` files; `T016` regenerates an existing generated file with no new public surface; `T017` is the read-only quickstart integration-gate run. This matches the "read-only verification/regen task ⇒ true" pattern every prior feature's own final quickstart task established (`002` T023, `003` T032, `004` T019, `005` T036, `006` T037). `T011` stays `false` despite mutating the pre-existing `run.sh`, because its `files=` list also includes the brand-new `test_profile.sh` — condition (a) requires *every* path in `files=` to already exist, which fails here.
- **`runtime_consumed`: all 17 `false`.** No task in this feature authors a system prompt, agent-dispatched template, or prompt fragment — `007` dispatches no new model role at all (the validator is model-free per plan.md's Constitution Check Principle II; `T014`'s `SKILL.md` is read by the *same* orchestrating session as command/skill instructions, not dispatched to a new one, mirroring `006-deck-render`'s identical reasoning for its own `SKILL.md` wrapper task). No task carries the `prompt` tag, correctly.
