# Graphify Context — 007-oss-docs (OSS Front Door + Profile Contract Validator)

_Generated 2026-07-16 from `graphify-out/graph.json` (1611 nodes, 2674 edges, scope: repo). Graph snapshot predates `006-deck-render` and the latest `docs/contracts/*` (13 Jul) — `profile_key.py`, `deck_md.py`, `profile-schema.md` are **not in the graph** and were read directly from disk. Stale after large merges — regenerate with `/speckit-graphify-context`._

## Graph scope
- Repo graph: `/Users/narenkarthikbm/Coding/specseyal/graphify-out/graph.json`
- Merged stack graph: not present (single-repo feature — no cross-repo anchors)
- This run used: **repo**

## Relevant existing modules

**Validator precedent (the pattern the profile validator follows):**
- `extensions/workforce/extension/scripts/validate-skill.py` — self-testing, zero-AI, dependency-free contract validator. Structure: `main()`, `validate_skill()`, a set of `check_*()` predicates, `_self_test()`, embedded `_fixture_text()`. Imports **only** the shared `frontmatter.py` beside it (S21) — never a hand-rolled parser. Every ambiguous case resolves to REJECT. **Strongest exemplar.**
- `extensions/workforce/extension/scripts/validate-categorization.py` — sibling validator. Structure: `ValidationResult` dataclass, `CategorizationShapeError`, `parse_*` + `validate_*` functions, `main()`. Closed-enum + cap checks (mirrors closed-enum profile checks).
- `extensions/workforce/extension/scripts/frontmatter.py` — the ONE shared frontmatter parser both validators import. Profile validator parses **pure YAML**, not frontmatter, so it does NOT reuse this — but the "one shared parser, no second hand-rolled reader" discipline applies.

**The scoped validator FR-018 must subsume (read from disk — not in graph):**
- `extensions/deck-render/extension/scripts/profile_key.py` — "the `deck_render` enum SSOT + a scoped `profile.yaml` validator" (006). Key facts:
  - **Dependency-free YAML strategy**: no hard `import yaml` at top level, ships no `requirements.txt`. Probes interpreters (`python3` → `python` → `uv run --with pyyaml python`) for one with PyYAML importable; runs an out-of-process probe (`_probe_yaml_inprocess` mirror). If none reachable → loud non-zero failure, never silent. **This is the FR-016 portability pattern to reuse.**
  - Holds the canonical `deck_render` closed enum (the SSOT). FR-018 requires the general validator accept this enum without conflict/duplication — decide at plan whether it imports the SSOT from `profile_key.py` or `profile_key.py` defers to the general validator.
  - Classifies: ABSENT / present-but-no-key / present-with-key. Has fixtures under `extensions/deck-render/test/fixtures/profiles/`.

**Contract + fixture (read from disk — not in graph):**
- `docs/contracts/profile-schema.md` — the closed contract the validator enforces: enums, required keys, `full_auto` P1–P5 handshake, §3 "unknown key is an error". Also names the schema-content gaps I-27 flags (`reopen_tier` dead key; `max_rounds` sourced from `council-config.yml`) to reconcile at plan.
- `specs/000-sample/profile.yaml` — the M0 fixture FR-015/SC-008 require the validator to PASS (make executable).
- `extensions/council/extension/council-config.yml` — holds the `council_tier` config key and `max_rounds` (graph confirms `max_rounds`/tier ceremony live here, **not** in profile.yaml — supports the I-27 reconciliation note).

**OSS docs (all NEW — none exist yet):**
- `LICENSE` — **exists** (MIT, D27); README references it, not re-created.
- `README.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `.github/` (issue + PR templates) — **absent**, to be authored. Greenfield, no blast radius.

## Blast radius (per anchor)
- **profile validator** (new file, e.g. `extensions/.../validate-profile.py`)
  - depends on: `docs/contracts/profile-schema.md` (the contract), the `deck_render` enum SSOT in `profile_key.py`
  - depended on by: nothing at authoring (a standalone checker) — UNLESS FR-019 wires it into a gate hook, which would make the council/workforce gate depend on it (D79(2) gate-semantics weight — resolve enforcement point at plan, defend at council)
  - follow the pattern in: `validate-skill.py` (structure + self-test + fixtures), `profile_key.py` (dep-free YAML probe)
- **OSS docs** (README et al.) — no code blast radius; the constraint is FR-010/SC-003 (every cited path/command/extension must resolve) and FR-011/SC-004 (no private-context leakage).

## Shared / mutable files (collision watch)
> Tasks touching any of these must be serialized — never two in one parallel wave.
- `extensions/deck-render/extension/scripts/profile_key.py` — if FR-018 is implemented by making 006's validator defer to the general one (edit), it collides with the general-validator task. If the general validator instead imports the enum read-only, no collision.
- `docs/contracts/profile-schema.md` — if planning reconciles schema-content gaps (`reopen_tier`, `max_rounds`) the contract is edited; any doc/task that cites the schema must serialize behind that edit.
- `.specify/extensions.yml` — **only if** FR-019 registers a gate hook wiring the validator in; that file is the hook registry many phases read. Likely out of this feature's scope (standalone command is the lighter option — council decides).
- OSS docs are mutually independent (README, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, templates) — safe to parallelize across authors; they share only the FR-010 "paths must resolve" invariant.

## Patterns to follow
- **Dependency-free validator** (`validate-skill.py`, `validate-categorization.py`, `profile_key.py`): stdlib only, `main()` returns non-zero on failure with a human-readable message naming the offending key/value, embedded self-test + committed fixtures. FR-016/FR-017/SC-010.
- **Dep-free YAML parsing** (`profile_key.py`): probe for an interpreter with PyYAML rather than vendoring a parser; fail loud if none — matches FR-016 "no third-party dependencies, repo standard toolchain."
- **Closed-enum SSOT ownership** (`profile_key.py` owns `deck_render`): a single module owns each enum; the general validator becomes the owner or defers — never a duplicated second copy (FR-018, the "one shared parser" discipline generalized).
- **Golden/regression fixtures, both branches** (workforce validators ship pass+fail fixtures): one conformant fixture passes, one per malformed class fails (FR-017/SC-007).
