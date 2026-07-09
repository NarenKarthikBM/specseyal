# Contract — `profile.yaml` (autonomy profile)

> **Status:** 1.1 (M0, amended 2026-07-10 by **D56**). Normative.
> **Implements:** D8 (per-feature automation posture), D9 (two gate-capable checkpoints), D13, D14, D33, **D56** (council ceremony tier).
> **Location:** `specs/NNN-feature/profile.yaml` — one per feature.

A profile declares, for one feature, which pipeline checkpoints stop for a human. v1 has exactly two gate-capable checkpoints (D9): the **council gate** (post-plan) and the **workforce gate** (post-tasks + agent assignment, before implementation spends tokens). Nothing else is gateable, and adding a third gate is a decision, not a config change.

---

## 1. Schema

```yaml
schema_version: "1.0"        # required, string, currently "1.0"
feature: "000-sample"        # required, must equal the containing directory name

full_auto: false             # required. See §2 — the safety handshake.

council_tier: full           # optional, default full (D56). full | standard.
                             # Selects the council-phase ceremony (see §7).

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
| `council_tier` | enum | `full` | `full` \| `standard` (D56). Selects the council-phase ceremony — §7. Absent ⇒ `full`, resolved against `council-config.yml`'s own `council_tier` default. Not a gate mode and not a model override (§6): it changes how many council sessions run and how they load context, never who signs or which model runs (D18 stays global). |
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
council_tier: full            # the fullest review; the default (D56).

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
council_tier: standard        # a mechanical bump has little to defend — the cheap tier fits.

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

## 7. Council ceremony tier (`council_tier`, D56)

`council_tier` selects **how much ceremony the council phase runs** for this feature — a cost/thoroughness knob raised by the M2 cost review (`002`'s first live council cost 5,249,858 billable tokens for one round; each member's 25–38 graphify tool-call turns churned `cache_creation`). It is orthogonal to the gate *mode*: `mode` says *who signs* (human vs auto), `council_tier` says *how the council deliberates before anyone signs*. A `standard`, `human`-gated council is normal and common; so is a `full`, `auto`-gated one under `full_auto`.

| Tier | Sessions / round | Peer review | Context loading | Member output |
|---|---|---|---|---|
| `full` (default) | 1 deck + 5 stage‑1 + **5** stage‑2 peer + 1 chairman = **12** | per‑member (each member critiques the other four) | **eager** — every member reads deck + plan + spec up front | uncapped |
| `standard` | 1 deck + 5 stage‑1 + **1** consolidated peer + 1 chairman = **8** | one consolidated critique of all five opinions → `opinions/peer/consolidated.md` | **lazy** — the technical deck is the sole up‑front read; plan/spec/graph are resolved on demand only to verify a specific deck claim | capped (`council-config.yml` `member_output_cap`) |

Rules:

| # | Rule |
|---|---|
| T1 | **Absent ⇒ `full`.** A profile that names no `council_tier` gets the fullest review — the same "absent is the safest posture, never the fastest" ethos as P1. The concrete default is read from `council-config.yml`'s own `council_tier` key (repo‑global fallback), which ships `full`. |
| T2 | **Per‑feature, by design.** The tier is a legitimate per‑feature choice — a mechanical dependency bump has nothing to defend (`standard`), a core‑architecture change earns the full bench (`full`). This is unlike the D18 model map, which is global policy and is **not** overridable here (§6). |
| T3 | **Tier changes ceremony, never the model map or who signs.** Both tiers run the same D18 roles (Sonnet members, Opus chairman) and honor the same `gates.council.mode`. `standard` is *not* a way to skip the council (that is `mode: auto`), and *not* a way to skip the human (that is `full_auto`). |
| T4 | **Measured before adopted as default.** `standard` is opt‑in until a real feature's `council_spend` proves it (docs/05 "tune only after SC-002"); M3 is that first measurement, reported per‑stage against the `full` 5.25M baseline. A later D‑row may flip the default. |

The tier's mechanics (session structure, lazy dispatch, caps) live in the council extension (`council-config.yml` `tiers` block + the `/speckit-council` orchestrator); this contract only defines the field, its default, and its meaning.
