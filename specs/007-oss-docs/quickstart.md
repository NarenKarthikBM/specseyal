# Quickstart / Validation — 007-oss-docs

Phase 1 output. Runnable scenarios that prove the feature works end-to-end. Every Success Criterion (SC-001…011) binds to a concrete check below. Run from the repo root.

## Prerequisites

- The repo, cloned. The pipeline tooling (`.claude/skills/speckit-*`, `.specify/`) is committed (D45).
- Claude Code on **subscription auth**; `ANTHROPIC_API_KEY` **unset** (D28 — the validator and pipeline never use it).
- A Python 3 the interpreter ladder can reach (the validator discovers PyYAML at runtime; none required to be pre-installed globally).

## Arm B — profile validator (US3)

### V1 — the M0 fixture is now executable (SC-008)
```
python3 extensions/workforce/extension/scripts/validate-profile.py specs/000-sample/profile.yaml ; echo "exit=$?"
```
**Expect:** `exit=0`. A test finally reads the M0 contract fixture (closes `artifact-layout.md` §7's "aspirational" gap).

### V2 — the live silent-degrade defect is caught (SC-009)
```
printf 'schema_version: "1.0"\nfeature: "x"\nfull_auto: false\ncouncil_tier: standrad\ngates:\n  council: {mode: human}\n  workforce: {mode: human}\n' > /tmp/bad.yaml
python3 extensions/workforce/extension/scripts/validate-profile.py /tmp/bad.yaml ; echo "exit=$?"
```
**Expect:** non-zero, message names `council_tier: 'standrad'` out-of-enum. (`feature ≠ dir` also fails — either cause is a correct rejection.)

### V3 — both branches, 100% correct verdict (SC-007)
```
bash extensions/workforce/test/run.sh          # or the profile-specific: bash extensions/workforce/test/test_profile.sh
```
**Expect:** all pass — conformant fixture exits 0; each malformed class (out-of-enum, unknown key, gate-scalar, P2/P3 handshake, feature-mismatch, max_rounds>1, out-of-enum deck_render, bad YAML) exits non-zero; the P4 case (workforce-auto-alone) exits 0 (no over-rejection); absent-file exits 0.

### V4 — deck_render subsumption, no divergent enum (FR-018)
```
python3 -c "import sys; sys.path.insert(0,'extensions/deck-render/extension/scripts'); import profile_key; print(profile_key.DECK_RENDER_ENUM)"
# the equivalence test in test_profile.sh asserts the validator's accepted deck_render set == this tuple
```
**Expect:** the validator rejects `deck_render: sparkle` and accepts `none|technical|overview|both`, and the committed equivalence test passes.

### V5 — no third-party deps, under 2s (SC-010)
```
time python3 extensions/workforce/extension/scripts/validate-profile.py specs/000-sample/profile.yaml
grep -rl "requirements.txt" extensions/workforce/ || echo "no requirements.txt (good)"
```
**Expect:** completes < 2s; no third-party dependency introduced.

### V6 — every existing committed profile validates correctly (regression)
```
for f in specs/*/profile.yaml; do python3 extensions/workforce/extension/scripts/validate-profile.py "$f" >/dev/null 2>&1 && echo "PASS $f" || echo "FAIL $f"; done
```
**Expect:** all `PASS` (000,001,003,004,005,006, and this feature's new 007). Absent profiles (P1) also validate when passed a missing path.

### V7 — enforcement point (FR-019, council-defended)
If the council ratifies the `before_plan` hook: a malformed `profile.yaml` hard-blocks the plan phase (an absent one passes). If the council selects standalone-only: V1–V6 stand and no hook is registered. Either way the malformed profile is mechanically rejectable, not silently accepted.

## Arm A — OSS front door (US1/US2)

### D1 — README front-door test (SC-001/SC-002)
Read `README.md` alone; confirm a reader can state what SpecSeyal is, name the phase sequence, identify the first command (`/graphify` then `/speckit-specify`), and locate `docs/00`, `docs/05`, `docs/90` — without opening another file.

### D2 — every citation resolves (SC-003 / I-REF)
```
# extract cited repo paths from the OSS docs and assert each exists
grep -rhoE '`[a-zA-Z0-9_./-]+`' README.md CONTRIBUTING.md SECURITY.md CODE_OF_CONDUCT.md .github/ 2>/dev/null \
  | tr -d '`' | grep -E '/|\.md$|\.py$|\.yml$' | sort -u \
  | while read p; do [ -e "$p" ] || echo "BROKEN REF: $p"; done
```
**Expect:** no `BROKEN REF` lines. (Command/extension names are checked against `.claude/skills/` and `extensions/`.)

### D3 — zero private/internal leakage (SC-004 / I-CLEAN)
```
grep -rnE '/Users/|/home/[a-z]' README.md CONTRIBUTING.md SECURITY.md CODE_OF_CONDUCT.md .github/ && echo "LEAK FOUND" || echo "clean"
```
**Expect:** `clean` — no machine-specific absolute path; no personal data beyond the author name already in `LICENSE`.

### D4 — contributor onboarding (SC-005/SC-006)
From `CONTRIBUTING.md` alone, produce a phase-tagged commit + the matching D-row/I-row per the log-discipline rule; from `SECURITY.md` + `.github/` templates, locate the private vulnerability channel and how to file an issue/PR — without reading source.

### D5 — publishable state (SC-011)
On feature close: `README.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `.github/` all exist and pass D2/D3; the visibility commit (public flip + `speckit-graphifyy` archive-with-pointer, D73 — out of scope here) can proceed with no further doc authoring and no blocking front-door gap.

## SC → check map

| SC | Check |
|---|---|
| SC-001, SC-002 | D1 |
| SC-003 | D2 |
| SC-004 | D3 |
| SC-005, SC-006 | D4 |
| SC-007 | V3 |
| SC-008 | V1 |
| SC-009 | V2 |
| SC-010 | V5 |
| SC-011 | D5 |
