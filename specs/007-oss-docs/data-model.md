# Data Model — 007-oss-docs

Phase 1 output. Four entities (spec §Key Entities). Arm A (OSS docs) is content, not schema; Arm B (validator) carries the real data model — the `profile.yaml` contract it enforces.

---

## 1. OSS doc set (Arm A)

The public-facing files the visibility commit reveals. No schema — each has required *content obligations* (the FR that governs it) and two cross-cutting invariants.

| Artifact | Governing FR | Required content |
|---|---|---|
| `README.md` | FR-001..005, FR-012 | Elevator pitch (what SpecSeyal is); problem solved; relation to Spec Kit + graphify; the full pipeline phase sequence (§4); quickstart (prereqs, install, first command); repo layout + links to `docs/00`, `docs/05`, `docs/90`; license (MIT) + subscription-only billing stance; graphify's in-repo home (`extensions/graphify/`). |
| `CONTRIBUTING.md` | FR-006 | Log discipline (decision → D-row same session; idea → I-row); dogfooding rule; artifact-is-the-contract; commit/branch conventions (phase-tagged commits; branch from spec ID — D25). |
| `CODE_OF_CONDUCT.md` | FR-007 | A code of conduct (Contributor Covenant is the chosen standard). |
| `SECURITY.md` | FR-008 | A **private** vulnerability-reporting channel (GitHub private security advisories) + supported scope. |
| `.github/ISSUE_TEMPLATE/*` | FR-009 | Prompts for repro + affected artifact/phase. |
| `.github/PULL_REQUEST_TEMPLATE.md` | FR-009 | Prompts for a phase-tagged commit + the matching D-row/I-row. |

**Cross-cutting invariants (mechanically checkable):**
- **I-REF (FR-010/SC-003):** every file path, command, doc reference, and extension name cited resolves to something that exists at authoring — zero broken/aspirational references.
- **I-CLEAN (FR-011/SC-004):** zero private/internal leakage — no machine-specific absolute path (`/Users/…`, `/home/…`), no personal data beyond the author name already in `LICENSE`.

`LICENSE` (MIT, D27) **already exists** — referenced, never recreated (spec Assumptions).

---

## 2. Profile validator (Arm B) — the entity under test

`validate-profile.py` — a dependency-free general contract validator. **State machine** (verdict per profile):

```
input: a profile.yaml path (or an absent file)
        │
        ├─ file absent .......................... VALID  (exit 0)   [P1: absent ⇒ both gates human]
        ├─ unreadable / unparseable YAML ........ INVALID (non-zero) [loud; never folded into "absent"]
        ├─ no PyYAML-capable interpreter ........ INVALID (non-zero) [loud failure]
        └─ parsed as a mapping
              ├─ all rules pass ................. VALID  (exit 0)
              └─ any rule fails ................. INVALID (non-zero) + message naming the offending key/value
```

Exit-code and message contract: see [contracts/validate-profile.md](./contracts/validate-profile.md). A VALID verdict is silent-success or a one-line OK; an INVALID verdict is non-zero **and** a human-readable message identifying the *cause* (FR-014/SC-007) — never an opaque parser traceback (spec Edge Cases).

---

## 3. Profile contract — the rules the validator enforces

The full field table (SSOT: `docs/contracts/profile-schema.md` v1.2). Every row below is a check `validate-profile.py` implements.

| Field | Type | Required | Rule enforced |
|---|---|---|---|
| `schema_version` | string | ✔ | present; string (currently `"1.0"`). |
| `feature` | string | ✔ | present; **must equal the containing directory name**. |
| `full_auto` | bool | ✔ | present; boolean; participates in the handshake below. |
| `council_tier` | enum | optional (dflt `full`) | ∈ {`full`,`standard`}. Out-of-enum (e.g. `standrad`) ⇒ FAIL — **SC-009**. |
| `deck_render` | enum | optional (dflt `none`) | ∈ `DECK_RENDER_ENUM` (`none`,`technical`,`overview`,`both`) — consumed from `profile_key.py`, equivalence-pinned (**FR-018**). Out-of-enum / mapping / list / empty ⇒ FAIL. |
| `gates` | mapping | ✔ | present; a mapping. |
| `gates.council` | mapping | ✔ | present; a **mapping** (`council: human` scalar ⇒ FAIL). |
| `gates.council.mode` | enum | ✔ | ∈ {`human`,`auto`}. |
| `gates.council.max_rounds` | int | optional (dflt `1`) | **must be `1`** (reject `>1`). Not pruned — **D-e**. |
| `gates.council.reopen_tier` | enum | optional (dflt `auto`) | ∈ {`auto`,`delta`,`full`}. Not pruned — **D-e**. |
| `gates.workforce` | mapping | ✔ | present; a **mapping**. |
| `gates.workforce.mode` | enum | ✔ | ∈ {`human`,`auto`}. |
| *(any other key)* | — | — | **unknown key ⇒ validation error** (§3), at every level. |

**The `full_auto` handshake (machine-enforceable subset of P1–P5):**

| Rule | Check | Enforced? |
|---|---|---|
| P1 | absent file ⇒ valid (both `human`) | ✔ (verdict = VALID) |
| P2 | `gates.council.mode: auto` invalid unless `full_auto: true` | ✔ |
| P3 | `full_auto: true` invalid unless **both** modes `auto` | ✔ |
| P4 | `gates.workforce.mode: auto` alone (with `full_auto: false`) is valid | ✔ (must NOT fail this) |
| P5 | `full_auto: true` requires a *why* comment | ✘ (human-enforced per contract — validator does not check) |

---

## 4. profile.yaml — the subject, and the M0 fixture

`specs/NNN-feature/profile.yaml` — one per feature; the autonomy config validated. Known subjects at authoring (all must validate correctly — a regression guard):

| Profile | Present? | Expected verdict |
|---|---|---|
| `specs/000-sample/profile.yaml` | ✔ | **VALID** — the M0 fixture the validator must make executable (**FR-015/SC-008**). |
| `specs/001/003/004/005/006/…` | ✔ | VALID (checked — all conform). |
| `specs/002-…`, `specs/007-…` (pre-this-feature) | ✘ absent | VALID (P1). `007`'s profile is **created by this feature** (standard tier, both human) — see plan Structure. |

**Authoritative pipeline phase sequence** (README FR-002, verified against `.claude/skills/speckit-*`):

```
specify → clarify → plan → council → tasks → analyze → categorize → agents → parallel-implement → complete → testing
```
