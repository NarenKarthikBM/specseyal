# Categorization — 001-council-extension

> **Manual pass.** The categorizer extension ships in M3; this is a hand-application of
> `docs/contracts/taxonomy-v0.md` (BLESSED, D42) so the taxonomy gets its **first real dogfood
> against a non-graphify feature** (taxonomy §8 v0→v1). Each task carries exactly one `type`, one
> `specialization`, the boolean `preserves_behavior`, and free `tags`. Written per D37 (this
> extension writes `categorization.md` and nothing else).

## Task table

| Task | `type` | `specialization` | `preserves_behavior` | `tags` |
|---|---|---|---|---|
| T001 installer + dir scaffold | `scaffold` | `devtools-cli` | false | `shell`, `installer`, `packaging`, `idempotent` |
| T002 `extension.yml` + README | `scaffold` | `devtools-cli` | false | `yaml`, `manifest`, `spec-kit` |
| T003 `council-config.yml` | `scaffold` | `devtools-cli` | false | `yaml`, `config`, `member-count` |
| T004 top-level README | `docs` | `devtools-cli` | false | `markdown`, `readme` |
| T005 token-capture spike | `docs` | `ai-agents` | false | `spike`, `observability`, `tokens`, `transcript` |
| T006 trace-fragment template | `data-model` | `ai-agents` | false | `trace`, `observability`, `jsonl`, `schema` |
| T007 deck-technical template | `docs` | `ai-agents` | false | `template`, `deck`, `prompt` |
| T008 deck-overview template | `docs` | `ai-agents` | false | `template`, `deck`, `non-technical` |
| T009 member-prompt template | `docs` | `ai-agents` | false | `prompt`, `reviewer`, `lens`, `graphify` |
| T010 chairman-prompt template | `docs` | `ai-agents` | false | `prompt`, `synthesis`, `classification` |
| T011 suggestions template | `docs` | `ai-agents` | false | `template`, `suggestions`, `chairman` |
| T012 `/speckit-council` skill | `endpoint` | `ai-agents` | false | `cli-command`, `orchestration`, `subagents`, `council` |
| T013 council provenance stub | `scaffold` | `devtools-cli` | false | `provenance`, `command-stub` |
| T014 `/speckit-council-triage` skill | `endpoint` | `ai-agents` | false | `cli-command`, `orchestration`, `triage`, `decision-record` |
| T015 triage provenance stub | `scaffold` | `devtools-cli` | false | `provenance`, `command-stub` |
| T016 `/speckit-council-approve` skill | `endpoint` | `ai-agents` | false | `cli-command`, `orchestration`, `human-gate` |
| T017 approve provenance stub | `scaffold` | `devtools-cli` | false | `provenance`, `command-stub` |
| T018 install/uninstall verification | `test` | `devtools-cli` | false | `install`, `idempotency`, `verification` |
| T019 conformance + quickstart | `test` | `qa-automation` | false | `conformance`, `e2e`, `contracts` |
| T020 finalize README + quickstart | `docs` | `devtools-cli` | false | `markdown`, `readme`, `results` |

## `general` cap check (taxonomy §4)

- `count(general)` = **0** of 20 tasks.
- Cap = `⌊0.20 × 20⌋` = **4**. **0 ≤ 4 → PASS.** Every task found a dominant lane; the escape hatch was not needed.

## Distributions

- **Type** (8 possible): `scaffold` ×6 · `docs` ×7 · `data-model` ×1 · `endpoint` ×3 · `test` ×2. (`service`, `ui`, `infra` unexercised.)
- **Specialization** (11 possible): `ai-agents` ×10 · `devtools-cli` ×9 · `qa-automation` ×1. (8 others unexercised.)
- **`preserves_behavior`**: false ×20 — the extension is all-new surface; `refactor-discipline` does not inject.

## v0→v1 evidence (booked into taxonomy §8)

This is the first feature categorized that **isn't** graphify's own example, so it is exactly the evidence §8 asked for:

1. **OQ6 vindicated so far.** `ai-agents` (10) and `devtools-cli` (9) dominate this feature — the two specializations §8 flagged as "do they belong in a general taxonomy?" A pipeline-tooling feature leans on both heavily. First real datapoint that they earn their place (the per-repo library, D17, contains any overfit).
2. **Prompt artifacts absorbed by the hybrid for v0 — resolution deferred (Call 2).** Member/chairman prompts and deck/suggestions templates are `*.md` → mechanically `docs` (§2 rule), with the real signal on `specialization: ai-agents` + tags (`prompt`, `reviewer`, `lens`). **Accepted for v0** as the D16 hybrid working (cheap mechanical type; nuance on the free axis). **Left open for the three-feature §8 review**, with two candidate resolutions: **(a)** a dedicated `prompt-asset` type, or **(b)** a *runtime-consumed* carve-out in the `docs` derivation rule (a prompt an agent consumes at runtime is not project documentation). **Assignment guard (D48):** a `prompt`-tagged task MUST assemble onto an implementation specialist under the D18 Sonnet floor — never onto a `docs`-only specialist that §3's "docs may take any model" rule would exempt.
3. **`endpoint` ⊃ CLI command — the endpoint/service body boundary (Call 1).** The three command skills are CLI commands (`endpoint`, §2) whose bodies are orchestration logic (service-flavored); all three now carry the `orchestration` tag. **Call 1 upheld `endpoint`** (deliverable = the invokable command). The **endpoint/service body boundary** — where a command's external surface ends and its service logic begins — is booked as v0→v1 evidence: the §8 review decides whether a fused command warrants splitting the classification.
4. **`preserves_behavior: true` still unexercised.** Like graphify's example, this feature creates only new surface — so the `refactor-discipline` auto-injection (§2.3, D40) has *still* never fired against real task output. Carried forward.
5. **A `docs`-typed spike (T005) is a poor fit.** A feasibility spike has no deliverable-based type; it landed on `docs` by the `*.md` rule. Minor, but recorded: the type enum has no "investigation/spike" lane, and that is probably correct (spikes are rare) — noted so the §8 review can rule explicitly.
