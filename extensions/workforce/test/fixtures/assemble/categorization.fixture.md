# Categorization — assemble.py golden-test fixture (T021)

> **Frozen test fixture.** Committed input for
> `extensions/workforce/test/test_assemble.sh`'s SC-005/S01 (double-run determinism
> including grant ORDER), SC-004 (>3-candidate cap trim), and SC-003/S09 (>=2
> grant-declaring-skill union) cases. Paired with the frozen library snapshot at
> `extensions/workforce/test/fixtures/assemble/library/`. Hand-authored, not categorizer
> output -- do not treat as a real feature's `categorization.md`.
>
> **Source binding (S14):** derived from `tasks.md @ deadbeef` (2 tasks) -- a fixture
> value; no real `tasks.md` exists for this synthetic feature.

## Categorization table

| task_id | type | specialization | preserves_behavior | tags |
|---|---|---|---|---|
| T001 | `service` | `qa-automation` | false | alpha, beta |
| T002 | `test` | `qa-automation` | false | cap-test |

## Fixture design notes

- **T001** matches exactly `skl_fx_alpha` and `skl_fx_beta` (tags `alpha`/`beta`) --
  both grant-declaring, one grant shared (`web_search`), one unique to each
  (`zz_alpha_only` / `aa_beta_only`). Neither is dropped (2 candidates, cap 3):
  SC-003/S09's grant-union total-order case.
- **T002** matches all four `cap-test`-tagged skills (`skl_fx_{delta,epsilon,gamma,zeta}`)
  -- 4 candidates, more than the assembly cap of 3. `skl_fx_zeta` (last by the `id`
  tie-break) MUST be dropped and logged: SC-004's cap-trim case.
- Neither task carries a `prompt` tag, and both resolve to the ordinary Sonnet fixture
  base (`agt_fx_sonnet`) -- this fixture is deliberately D48-clean; the guard's
  hard-error branch is exercised separately by `categorization.d48.fixture.md`.
