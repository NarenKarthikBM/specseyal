# Workforce Pair Extension

Tags every task, matches it to a specialist deterministically, and gates the assembled roster
with a human — the M3 workforce pair, packaged as **one** extension (round-1 council S10). See
`../README.md` for the full picture; this file covers what lives in `extension/` (plus the two
sibling directories, `../seed/` and `../skills/`, that this payload depends on) — the
extension-internal reference, not the pitch.

## Flow

```
/speckit-analyze (D58) → /speckit-categorize → /speckit-agent-assign → /speckit-workforce-approve → /speckit-implement-parallel
```

Each command reads what the previous one wrote and writes exactly one artifact class.
`categorize` runs after `analyze` (not before) because `analyze` can still patch `tasks.md`
(D11 remediation) — classification follows stabilization.

## Provides

| Command | Dispatches | Writes |
|---|---|---|
| `speckit.categorize` → `/speckit-categorize` | one Sonnet `categorizer` subagent, then `validate-categorization.py` (code) | `categorization.md` — only on a passing validation (S22); `tasks.md` is never touched (D37) |
| `speckit.agent-assign` → `/speckit-agent-assign` | `assemble.py` (zero-AI) — then, only on a ∅-match gap, one Sonnet `skill-builder` subagent per shared-tag cluster (never per task, FR-006/SC-007) | `agents/assignment.md`'s `### Roster approved` table + a pending `## Workforce Gate`, written by `assemble.py` itself (S08); a gap run also persists new `SKILL.md`s into `.claude/skills/` (FR-008) |
| `speckit.workforce-approve` → `/speckit-workforce-approve` | no session — a human decides (or, under `gates.workforce.mode: auto`, verifies what `/speckit-agent-assign` already wrote itself) | resolves the six `[PENDING …]` fields of `agents/assignment.md`'s `## Workforce Gate` section only — never the roster table nested inside the same section |

`commands/` holds one provenance-stub `.md` per command (dots become hyphens on install, Spec
Kit's usual convention); the installed, user-invocable skills live at `../skills/` and are
copied to `.claude/skills/speckit-categorize|speckit-agent-assign|speckit-workforce-approve/`.
`disable-model-invocation: true` on `speckit-workforce-approve` alone — the other two are
model-invocable, this one is never waved through by an agent on its own initiative.

## The split that makes it work

**Categorization = inference (Sonnet) · assembly = code · skill-building = inference (Sonnet).**

- **Categorize (inference).** One Sonnet `categorizer` session tags every task's `type` (mechanical,
  read off graphify's `files=`/`deps=`/`mutates=` signals) and `preserves_behavior` (mechanical,
  same signals) plus `specialization` (interpretive — `plan.md`'s stack + domain) and free `tags`.
  It **proposes**; `validate-categorization.py` (code) is the **sole authority** on whether the run
  passes — 100% coverage + closed-enum membership (SC-001) and the `general ≤ 20%` cap, computed as
  the exact integer inequality `general * 5 > total * 1` (never a float, so no rounding-edge drift)
  — never the categorizer's own "## Cap Check" prose (FR-005).
- **Assemble (code, zero-AI).** `assemble.py` has no model call at all. It implements
  `agent-library-schema.md` §3 verbatim — base lookup by `(type, specialization)`, tag-Jaccard-ranked
  skill candidates, the forced `skl_refactor_discipline` injection on `preserves_behavior: true`, a
  cap of 3 injected skills (D40), a total-ordered grant union — and it **writes the roster table
  itself** into `agents/assignment.md` (S08, a tool-permission fact, not a prose promise). Every
  set-typed intermediate is routed through one `total_order()` helper before serialization (S01), so
  a gap-free run is byte-identical across two invocations (SC-005) — checkable in one line via the
  S18 library-snapshot content-hash stamped into the artifact header. (The S14 freshness check —
  comparing `categorization.md`'s recorded `tasks.md` SHA against the live one — is
  `/speckit-agent-assign`'s own precondition, not this script's; `assemble.py` only stamps what it's
  given.)
- **Skill-build (inference), only on a gap.** A task whose tags intersect no library skill is a
  "gap." One Sonnet `skill-builder` per shared-tag cluster authors exactly one additive-only
  `SKILL.md`, holding its own dispatch's `web_search` grant (below) to consult current docs.
  `validate-skill.py` (code) is the safety gate that decides whether it's ever persisted; a rejected
  candidate is surfaced, never persisted (FR-007).

## Scripts (`scripts/`)

- **`frontmatter.py`** — the one shared `specseyal:` frontmatter parser (S21), imported by both
  `assemble.py` and `validate-skill.py` so there is exactly one place that knows how a `specseyal:`
  block is shaped. Deliberately not a general YAML parser — it understands exactly the closed shape
  `agent-library-schema.md` §1.1/§2 and `skill-module.md` §1 use (block mappings, flow lists/maps,
  scalar line-folding, trailing comments) and fails clearly (`FrontmatterError`) on anything else.
  Also defines `body_sha256()` — the exact `sed '1,/^---$/d;1,/^---$/d' | shasum -a 256` recipe used
  to detect drift between a library entry's stamped hash and its actual content.
- **`assemble.py`** (agent-library-schema.md §3) — the deterministic matcher/assembler described
  above. Exit `0` = roster written; `2` = the D48 guard fired (a `prompt`-tagged task assembled onto
  a non-Sonnet base — FR-014/SC-006, nothing written); `3` = malformed input or a library invariant
  violation (duplicate id, non-unique lane, missing `agt_generic` fallback, missing
  `skl_refactor_discipline` when required, template render failure); `4` = a library entry's
  frontmatter failed to parse. Only `0` ever writes.
- **`validate-categorization.py`** — the code gate `/speckit-categorize` runs after the categorizer
  session: re-derives coverage + closed-enum membership and the general cap independently from the
  table on disk, never trusting the categorizer's own arithmetic. Exit `0` = PASS (write/keep);
  `1` = FAIL (nothing written, or reverted to the prior valid state — S22); `2` = usage error, not a
  categorization verdict either way.
- **`validate-skill.py`** — the safety gate a generated `SKILL.md` must pass before
  `/speckit-agent-assign` ever persists it into `.claude/skills/`: frontmatter/id/version/origin
  shape, grants disjoint from the core toolset (D41), three structural additive-only proxies (S1 no
  negation markers; S2 no dispatch/model content; S3 the fixed `"In addition to your base
  instructions:"` anchor present, plus no permission/relaxation language), and **S04** — the
  generated `taxonomy.tags` **must intersect** the triggering task's tags, the check that actually
  closes the gap (a structurally perfect module whose tags miss the task leaves it provably open).
  Fail-closed on anything unparseable; exit `0` only when every check passes.

## Hooks (registered in `.specify/extensions.yml`)

| Hook | Action |
|---|---|
| `after_categorize` | `speckit.git.commit categorize …` — phase-tagged commit, no-op on a clean tree |
| `after_agent-assign` | `speckit.git.commit agents …` — phase-tagged commit |

Both hooks target the **git extension's own** `speckit.git.commit` command through the shared hook
registry — no edit to git-ext's source (R7). Both are `optional: false`; enforcement is
prose-level in v1 (no `HookExecutor` yet — the invoking phase-skill runs the hook and honors its
exit code, D53), same as git's and council's own hooks. These fire-points are declared here and
dispatched by the installed registry, never assumed to "just work" by analogy (S25).

### The S02 seam — `after_workforce_approve`

`/speckit-workforce-approve` **emits** `after_workforce_approve` on `approved`/`approved-with-notes`
(never on `rejected`) — but that hook is **not registered in this file**, and that omission is
deliberate, not an oversight. Round-1 council triage flagged S02 as blocking: the pre-triage
two-extension draft left the workforce gate with no real gate-*write* path of its own. The fix,
clustered with S10 (one extension, not two) and S13 (a dedicated `/speckit-workforce-approve`
mirroring `/speckit-council-approve`), had **git-ext generalize its own source** (D57 S2): the
previously council-only `on-council-approve.sh` became the gate-agnostic
`on-gate-approve.sh <council|workforce>` (R8). Git's `extension.yml` — not this one — registers
`after_workforce_approve → speckit.git.record-gate (gate: workforce)`, resolving to that script,
which composes `gates.sh write workforce` to bind `tasks.md @ <sha>` + `assignment.md @ <sha>` into
the git-ext-owned `gates.yml` (the binding `before_implement`'s `verify-gate` checks). Registering a
second handler for the same event here would double-fire the write — the same reason
`after_council_approve` is council-invisible too, handled entirely in git's own source.

## Seed library (`../seed/`)

Read from `workforce-config.yml`'s `seed_library` manifest (the single source of truth for *which*
files — `install.sh` only knows how to copy them additively) into `.claude/agents/` and
`.claude/skills/` — the live, per-repo library (D17), **never** inside this extension's own
`rm -rf`'d payload and never overwritten on reinstall: a generated skill, a hand-edited seed, or a
user's own agent all survive a reinstall of this or any other extension (R5/S07).

**7 base specialists**, all `model: sonnet`, curated-static (D44) — one `(type-list, specialization)`
lane apiece: `agt_ai_agents` · `agt_devtools_cli` · `agt_security` · `agt_qa_automation` ·
`agt_backend_service` (provisional) · `agt_data_persistence` (provisional) · `agt_generic` (the
`general`-specialization fallback lane, FR-016 — never a silent default). `provisional: true` flags
the two bases seeded only from the taxonomy's worked examples, not dogfood evidence (S11) — visible
on any roster that assembles onto them, never silent.

**5 seed skills**, every one `grants: []` (D41) — the sole elevated grant anywhere in this system is
the skill-builder's own dispatch grant (below), never a seed default: `skl_refactor_discipline`
(auto-injected whenever `preserves_behavior: true`, taxonomy-v0.md §2.3) · `skl_orchestration` ·
`skl_shell_scripting` · `skl_yaml_hooks` · `skl_installer_hygiene`.

Bases are fixed; skills alone evolve (D24) — a skill the builder persists (`origin: generated`)
joins this same library for the *next* feature's `assemble.py` run to find, the flywheel's raw
material.

## The `web_search` grant (D60 / D63)

`workforce-config.yml`'s `skill_builder.web_search: true` is the system's **first elevated grant**
(D60) — and it belongs to the skill-builder **role**, not to anything the role produces. It is
realized entirely by `templates/skill-builder-prompt.md` (Step 5) telling the dispatched Sonnet
session it holds `WebSearch` this run; the audit trail is the trace record
(`elevated_grants: ["web_search"]`, only when the session actually searched, D43) and the roster's
`Elevated grants` column on a genuine skill-builder dispatch.

Every `SKILL.md` the builder authors still defaults to `grants: []`, exactly like every seed skill
(`templates/skill-module.template.md`) — the builder does **not** stamp its own grant onto what it
writes. A generated module declares an elevated grant only if *that module's own runtime function*
needs one — a rare, deliberate, per-module judgment, never a default.

**D63** sharpened this after `003`'s own hand-assembled roster briefly hand-attached `web_search` to
two build tasks as a "display convention," later corrected to `elevated: none` on both: *capability
authorization* (D60 — the role may hold `web_search`) and *dispatch approval* (a gate approving a
specific dispatch's grants) are **distinct acts** (FR-013 — "nothing else grants anything"). The
grant reaches a roster row only through a genuine skill-builder dispatch — a real gap event, never a
task that merely writes a prompt file or wires a handoff.

## Config (`workforce-config.yml`)

One config governs all three commands (S10 — replaces the drafted `categorize-config.yml` +
`agents-config.yml`):

| Key | Value | Enforced by |
|---|---|---|
| `general_cap` | `0.20` | `validate-categorization.py`, as the exact integer ratio `1/5` |
| `assembly_cap` | `3` | `assemble.py`'s `ASSEMBLY_CAP` (D40) |
| `model` | `sonnet` | D18 — the categorizer, the skill builder, and every seed base |
| `taxonomy` | `docs/contracts/taxonomy-v0.md` | the closed 8-type × 11-specialization enum both validators check against |
| `seed_library` | the bases/skills manifest | `install.sh`'s additive seed step |
| `skill_builder.web_search` | `true` | the role grant, above |

## Files here (`extension/`)

- `extension.yml` — the manifest: id `workforce`, the 3 commands, the two `after_*` hooks above.
- `workforce-config.yml` — the config table above.
- `commands/` — one provenance-stub `.md` per command: `speckit.categorize.md`,
  `speckit.agent-assign.md`, `speckit.workforce-approve.md`.
- `scripts/` — `frontmatter.py`, `assemble.py`, `validate-categorization.py`, `validate-skill.py`
  (above).
- `templates/` — `categorizer-prompt.md` (the categorizer's full system prompt, one slot:
  `{{feature}}`); `skill-builder-prompt.md` (the builder's, five slots:
  `{{feature}}`/`{{task_ids}}`/`{{task_type}}`+`{{task_specialization}}`/`{{task_tags}}`/
  `{{output_path}}`); `assignment.template.md` (the two-grammar roster template — `{{UPPER_SNAKE}}`
  tokens `assemble.py` substitutes mechanically, `[PENDING — …]` markers only
  `/speckit-workforce-approve` may resolve); `skill-module.template.md` (a reference template
  documenting the same generated-`SKILL.md` shape `skill-builder-prompt.md`'s own "Output format"
  section embeds inline — not itself mechanically read by any script, unlike `assignment.template.md`).

## Install order

```bash
bash extensions/git/install.sh .        # git BEFORE workforce
bash extensions/workforce/install.sh .
```

Git first, always: both hooks above target `speckit.git.commit`, and `after_workforce_approve`'s
handler lives in git-ext's own `on-gate-approve.sh` (the S02 seam) — neither resolves to anything
until git-ext is installed. `workforce`'s own `install.sh` only **warns**, never hard-blocks, if
git-ext isn't detected; workforce still installs cleanly either way, and the two hooks simply no-op
until git-ext lands.

## Requirements

- A completed `tasks.md` + `plan.md` for the feature — `/speckit-categorize`'s own precondition,
  ideally post-`/speckit-analyze` (D58, since `analyze` can still patch `tasks.md`).
- The seed library installed at `.claude/agents/` + `.claude/skills/` (`install.sh` step 3) —
  `assemble.py` exits `3` without it.
- `python3` on `PATH`. No third-party dependency: `frontmatter.py` is pure stdlib (R2's "no
  PyYAML" ruling — the `specseyal:` shape is closed, not arbitrary YAML).
- Git ≥ 2.20 and the git extension installed first (above), both for the two commit hooks and for
  `after_workforce_approve`'s handler to exist at all.
