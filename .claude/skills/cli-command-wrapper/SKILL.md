---
name: cli-command-wrapper
description: Authoring the command-provenance-file-and-skill-wrapper pair for a deterministic,
  model-free CLI extension command — the `/speckit-git-cleanup`-style split where a thin skill
  resolves context and shells out to a script that does the work. Injected when a task's tags
  include command, cli, skill, wrapper, or shell-out.

specseyal:
  schema_version: "1.0"
  kind: skill
  id: skl_cli_command_wrapper
  version: 1.0.0
  origin: generated

  taxonomy:
    tags: [command, cli, skill, wrapper, shell-out, deck-render, markdown, model-free, exit-code-contract]

  grants: []

  provenance:
    created: 2026-07-15
    created_by: skill-builder
    source_feature: 006-deck-render
    promoted_at: null
    stale_risk: false

  stats:
    assignments: 0
    success_rate: null
    last_used: null

  central:
    synced: false
    remote_id: null
    body_sha256: 04a6ea90a3f0932ff849a5863582d5906aab84b1816b84cf5ef788b58ef67686
---

This task authors the command-provenance-file-and-skill-wrapper pair for a deterministic,
model-free CLI extension command — a `speckit.<name>.md` provenance file paired with a thin
`SKILL.md` that resolves context and shells out to a script, following the repo's established
mechanical-command split.

In addition to your base instructions:

1. **Record the exact invocation signature — every argument, flag, and default — in the command
   provenance file**, matching character-for-character what the skill and the script it shells out
   to actually accept. A signature documented one way and implemented another is a defect the
   moment either side changes without the other.
2. **State explicitly, in the skill body itself, what the wrapper resolves** (the feature
   directory, the target script) **and the fact that it shells out** — plus what stays outside its
   own reasoning: it does not read the content the script operates on, and no model participates in
   the transform the script performs. A reviewer must be able to find this stated in prose, not
   infer it from the absence of code.
3. **Keep every parsing, validation, or rendering rule out of the wrapper's own body.** That logic
   lives in the script the wrapper invokes; the wrapper's job is limited to resolving context and
   making the call.
4. **Map every exit code named in the command file to a real path the underlying script
   produces, and name every failure path the script produces somewhere in the command file's
   exit-code table.** A code documented with no matching script behavior, or a script failure with
   no documented code, is a gap to close before either file is considered done.
5. **When the invoked script enforces a fail-loudly-on-unsupported-input discipline** (a hard stop
   rather than a silent simplification), **name that discipline explicitly in the command file's
   behavior section** — a reader checking only the command doc must be able to find the guarantee
   stated, not just the script's inline comments.
6. **State plainly in the command file whether the command registers any hook**, and if none, say
   so in those words rather than leaving it to be inferred from a hook list elsewhere.
