# Contract — `profile.yaml` (autonomy profile)

> **Status:** 1.0 (M0). Normative.
> **Implements:** D8 (per-feature automation posture), D9 (two gate-capable checkpoints), D13, D14, D33.
> **Location:** `specs/NNN-feature/profile.yaml` — one per feature.

A profile declares, for one feature, which pipeline checkpoints stop for a human. v1 has exactly two gate-capable checkpoints (D9): the **council gate** (post-plan) and the **workforce gate** (post-tasks + agent assignment, before implementation spends tokens). Nothing else is gateable, and adding a third gate is a decision, not a config change.

---

## 1. Schema

```yaml
schema_version: "1.0"        # required, string, currently "1.0"
feature: "000-sample"        # required, must equal the containing directory name

full_auto: false             # required. See §2 — the safety handshake.

gates:                       # required
  council:                   # required
    mode: human              # required: human | auto
    max_rounds: 1            # optional, default 1. v1 rejects anything but 1 (D13).
    reopen_tier: auto        # optional, default auto: auto | delta | full (D14)
  workforce:                 # required
    mode: human              # required: human | auto
```

Gate blocks are **mappings, not scalars**. `council: human` is invalid; `council: {mode: human}` is the only form. One shape, one parser, one thing to get wrong.

## 2. The full-auto handshake (D9, D33)

D9 says the council gate is default-on in every profile and that skipping it "requires an explicit full-auto profile." That is encoded as a two-key handshake — you cannot reach full autonomy by editing one line:

| # | Rule |
|---|---|
| P1 | **`profile.yaml` absent ⟹ both gates are `human`.** A missing file is the safest profile, never the fastest one. |
| P2 | `gates.council.mode: auto` is **invalid** unless `full_auto: true`. |
| P3 | `full_auto: true` is **invalid** unless *both* `gates.council.mode` and `gates.workforce.mode` are `auto`. A profile that calls itself full-auto and isn't, lies. |
| P4 | `gates.workforce.mode: auto` alone is valid with `full_auto: false`. The workforce gate is an economic guard (don't spend tokens on a bad roster); the council gate is a correctness guard. Only the correctness guard is protected. |
| P5 | `full_auto: true` requires a top-of-file comment stating why. Not machine-enforced. Enforced by the person reviewing the diff. |

P2 ∧ P3 ⟹ `full_auto: true` ⟺ both gates `auto`. The field is therefore redundant *as data* and load-bearing *as ceremony*. That is the intent: it makes the diff that disables adversarial review impossible to read as an accident.

## 3. Fields

| Field | Type | Default | Notes |
|---|---|---|---|
| `schema_version` | string | — | Required. Bump on any breaking change to this file. |
| `feature` | string | — | Required. Must equal the directory name. A profile that names another feature is invalid — this catches copy-paste. |
| `full_auto` | bool | `false` | §2. |
| `gates.council.mode` | enum | `human` | `human` \| `auto`. |
| `gates.council.max_rounds` | int | `1` | v1: must be `1`. The field exists so profiles that allow a second full round (docs/10 §5, "later") need no schema change. Validators reject `> 1` until the convergence rule is revised. |
| `gates.council.reopen_tier` | enum | `auto` | `auto` \| `delta` \| `full` (D14). `auto` = triage proposes, human gate confirms. `delta`/`full` pin the tier and skip the proposal. Pinning `delta` with `gates.council.mode: auto` means a reopened plan never sees a human — allowed only under `full_auto`. |
| `gates.workforce.mode` | enum | `human` | `human` \| `auto`. |

Unknown keys are a **validation error**, not a warning. A typo'd `gates.counsel` must not silently degrade to a default that happens to be safe today.

## 4. Effect on the pipeline

| Gate | `mode: human` | `mode: auto` |
|---|---|---|
| council | Pipeline stops after triage. Human reads `defense-deck/overview.md` + `suggestions.md` + `decision-record.md`, appends a `## Human Gate` section (see `decision-record.md` §2), pipeline resumes. | Triage writes the gate section itself with `reviewer: auto`, `decision: approved`. Blocking suggestions still force one revision cycle (D13) — `auto` skips the *human*, never the *council*. |
| workforce | Pipeline stops after agent assignment. Human reads `tasks.md` + `agents/assignment.md`, appends a `## Workforce Gate` section, pipeline resumes. | Assignment writes the gate section itself. |

**`auto` never means "skip the phase."** It means "do not block on a human." The council still convenes, the deck is still written, the record is still appended. Autonomy is about who signs, not about what runs.

Consequence for resumability (`artifact-layout.md` §3): because an `auto` gate still writes its gate section, phase state stays inferable from artifacts alone under every profile.

## 5. Example

The canonical example, also committed at `specs/000-sample/profile.yaml`:

```yaml
# Autonomy profile — 000-sample
# Both gates human: the default posture (D9). See docs/contracts/profile-schema.md.
schema_version: "1.0"
feature: "000-sample"

full_auto: false

gates:
  council:
    mode: human
    max_rounds: 1
    reopen_tier: auto
  workforce:
    mode: human
```

A full-auto profile, for contrast — note the mandatory `why` comment (P5):

```yaml
# Autonomy profile — 014-dependency-bump
# full_auto: this feature is a mechanical dependency bump with no architectural surface;
# the council has nothing to defend and the roster is a single scripted agent.
# Approved by Babu, 2026-07-20.
schema_version: "1.0"
feature: "014-dependency-bump"

full_auto: true

gates:
  council:
    mode: auto
    max_rounds: 1
    reopen_tier: auto
  workforce:
    mode: auto
```

## 6. Non-goals (v1)

- **No model overrides.** The D18 role→model map is global policy, not per-feature preference. If a feature needs a different model for a role, that is an amendment to D18, argued in docs/90 — not a line in a profile.
- **No observability toggle.** Tracing is unconditional (principle 4). A feature cannot opt out of leaving a trace.
- **No repo-level default profile.** P1 already gives the safe default. A repo default that silently makes every new feature full-auto is exactly the failure mode P1–P5 exist to prevent. The M7 setup wizard (D23) may *write* per-feature profiles; it may not introduce an inherited one.
- **No third gate.** Spec/clarify and post-implement are not gate-capable in v1 (D9).
