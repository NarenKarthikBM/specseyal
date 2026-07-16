# Contract — `validate-profile.py` (general profile.yaml validator)

> Phase 1 output for `007-oss-docs` (FR-013…019). Normative for the validator's external surface.
> **Enforces:** `docs/contracts/profile-schema.md` v1.2 (the field/enum/handshake SSOT).
> **Consumes:** `DECK_RENDER_ENUM` from `extensions/deck-render/extension/scripts/profile_key.py` (FR-018, the deck_render enum SSOT).
> **Home:** `extensions/workforce/extension/scripts/validate-profile.py` (+ tracked install copy `.specify/extensions/workforce/scripts/validate-profile.py`).

## 1. CLI surface

Mirrors `profile_key.py --validate-profile` so the two are call-compatible:

```
validate-profile.py [--feature <dir> | <profile-path>]
```

- `--feature <dir>` — a feature directory; validates `<dir>/profile.yaml`. Mutually exclusive with `<profile-path>`.
- `<profile-path>` — an explicit path to a `profile.yaml`.
- neither — validates `./profile.yaml` (standalone/cwd use).

Runnable directly as a script (no third-party install); PyYAML is discovered at runtime (§4).

## 2. Exit-code contract

| Exit | Meaning |
|---|---|
| `0` | **VALID.** All contract rules pass. **Includes an absent file** (P1 — resolves to both-gates-`human`, the safest profile). |
| non-zero (`≥1`, a single reserved code e.g. `3` mirroring `profile_key.py`) | **INVALID.** One or more of: an out-of-enum value; an unknown key; a missing required key; a scalar where a gate mapping is required; `max_rounds ≠ 1`; a `feature` ≠ dir name; a `full_auto` handshake violation (P2/P3); unreadable/unparseable YAML; **or** no PyYAML-capable interpreter reachable. |

A non-zero exit is **always** accompanied by a human-readable message on stderr naming the offending key/value (§3). Success is silent or a single `OK` line.

## 3. Message contract (FR-014/SC-007)

Every failure names the cause — the offending key and, where applicable, its value and the allowed set. Examples (illustrative, not literal-required strings):

```
profile.yaml: INVALID — council_tier: 'standrad' is not one of {full, standard}     # SC-009
profile.yaml: INVALID — unknown key 'gates.counsel' (unknown keys are an error)
profile.yaml: INVALID — gates.council must be a mapping, got scalar 'human'
profile.yaml: INVALID — full_auto: true requires both gates.council.mode and gates.workforce.mode = auto (workforce.mode = human)   # P3
profile.yaml: INVALID — gates.council.mode: auto requires full_auto: true            # P2
profile.yaml: INVALID — feature 'oo6-deck-render' must equal the directory name '006-deck-render'
profile.yaml: INVALID — gates.council.max_rounds must be 1 (got 2)
profile.yaml: INVALID — unreadable or unparseable YAML: <parser detail>
profile.yaml: INVALID — no PyYAML-capable interpreter reachable (tried current, graphify/specify shebang, python3, python, uv)
```

**Never** an opaque Python traceback (spec Edge Cases). **Never** a silent fall-through to a "safe" default on a malformed value (the exact failure mode §3 / SC-009 forbid).

## 4. Dependency & portability contract (FR-016/SC-010)

- **No third-party dependency, no `requirements.txt`.** Reuses `profile_key.py`'s interpreter ladder: running interpreter → `graphify`/`specify` shebang interpreter → `python3` → `python` → `uv run --with pyyaml python`. If none has PyYAML, that is a **loud non-zero failure**, never a silent pass.
- Completes on a single profile in **< 2 seconds** (SC-010).
- Standard toolchain only (the same interpreters `profile_key.py` already probes).

## 5. FR-018 enum-consumption contract

- The validator's accepted `deck_render` set **is** `profile_key.DECK_RENDER_ENUM` — one authority, no re-typed independent copy.
- A committed test asserts the validator's accepted set **equals** `profile_key.DECK_RENDER_ENUM` (drift guard) and that both reject the same out-of-enum value.
- The validator checks `deck_render` at **validate/author time** — earlier than `006`'s render-time-only check — closing `profile-schema.md` §8's recorded honest limit. `profile_key.py` is unchanged and remains the render-time scoped resolver.

## 6. Test-coverage contract (FR-017/SC-007/SC-008)

Committed fixtures under `extensions/workforce/test/fixtures/profile/`, exercised by `extensions/workforce/test/test_profile.sh` (registered in `run.sh`):

| Fixture class | Expected |
|---|---|
| conformant | exit 0 |
| `specs/000-sample/profile.yaml` (real M0 fixture) | exit 0 — **SC-008** (a test finally reads it) |
| absent file | exit 0 (P1) |
| `council_tier: standrad` (out-of-enum) | non-zero — **SC-009** |
| unknown key | non-zero |
| gate block as scalar (`council: human`) | non-zero |
| `full_auto: true` with a `human` mode (P3) / `council.mode: auto` with `full_auto: false` (P2) | non-zero |
| `feature` ≠ dir name | non-zero |
| `max_rounds: 2` | non-zero |
| out-of-enum `deck_render` | non-zero (FR-018) |
| malformed YAML / merge-conflict marker | non-zero (loud) |
| `gates.workforce.mode: auto` alone, `full_auto: false` (P4) | exit 0 (must NOT over-reject) |

100% correct verdict across the set is SC-007.
