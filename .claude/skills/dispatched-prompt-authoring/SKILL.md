---
name: dispatched-prompt-authoring
description: Authoring a prompt asset a session is dispatched with or renders at runtime — a system prompt, an agent prompt, a dispatched-session template. Injected when a task's tags include prompt, system-prompt, agent-prompt, or prompt-authoring.

specseyal:
  schema_version: "1.0"
  kind: skill
  id: skl_dispatched_prompt_authoring
  version: 1.0.0
  origin: seed

  taxonomy:
    tags: [prompt, system-prompt, agent-prompt, prompt-authoring, prompt-template]

  grants: []

  provenance:
    created: 2026-07-13
    created_by: human
    source_feature: null
    promoted_at: null
    seeding_evidence: "D71/I-20: two-feature gap demand — 003-workforce 14/32 (completion-report.md); 004-testing-completion 8/19 (findings.md F1); seeding bar met, NOT provisional"

  stats:
    assignments: 0
    success_rate: null
    last_used: null

  central:
    synced: false
    remote_id: null
    body_sha256: 7a6fe945c0c5c37cb3115fe0476f89d57ba1db5e70881d15d0b55cd3d79d7c3b
---

This task authors a prompt an agent is dispatched with or renders at runtime — a system prompt, a dispatched-session template, or a prompt fragment a model consumes.

In addition to your base instructions:

- **Make the rendered prompt the complete, literal instruction set.** A dispatched session cannot ask a follow-up question, so every rule it needs — its inputs, its single job, its output shape — is stated in the prompt itself, self-contained.
- **Name every substitution slot explicitly, and leave none unfilled.** State which tokens the caller substitutes and what each resolves to; a rendered prompt that still carries an unsubstituted placeholder is a defect, not a detail.
- **Specify the return-value contract precisely.** State the exact shape of what the session sends back — often a single status line — so only that compact result crosses back and the session's working context stays with the session. Under-specifying the return is what lets a session leak its whole transcript upward.
- **Ground the session in paths it reads itself.** Point the session at the files it must open and let it read them; passing large content inline bloats the prompt and couples it to a snapshot that goes stale.
- **State the boundaries as explicit obligations.** What the session writes, what it must not touch, and what it must never execute belong in the prompt as hard rules — a session left to infer its own scope guesses wrong exactly often enough to matter.
- **Keep the prompt honest about its own limits.** Where the session grounds a claim on second-hand evidence, have it label the evidence source; where it would be tempted to fabricate, have it flag a gap.
