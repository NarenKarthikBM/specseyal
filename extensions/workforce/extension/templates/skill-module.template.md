---
# TEMPLATE — strip every `#` comment in this frontmatter block before writing the final SKILL.md;
# every real module in .claude/skills/ is clean YAML with none left in. Filled by the `skill-builder`
# session per extensions/workforce/extension/templates/skill-builder-prompt.md.
name: {{name}}                          # kebab-case; Claude Code's dispatch handle + filename
description: {{description}}            # 1-3 sentences — trigger condition + what it does; wrap long
                                         # text on 2-space-indented continuation lines (plain YAML fold,
                                         # see extensions/workforce/seed/skills/*/SKILL.md for the shape)

specseyal:
  schema_version: "1.0"
  kind: skill                           # always "skill" — this shell never produces a base
  id: skl_{{skill_slug}}                # ^skl_[a-z0-9]+(_[a-z0-9]+)*$, unique across .claude/skills/
  version: {{semver}}                   # semver; 1.0.0 for a freshly generated module — there is no
                                         # prior version to bump from (agent-library-schema.md §2)
  origin: generated                     # fixed — this is the GENERATED-skill shape. A later
                                         # promotion mutates this same file's origin/promoted_at in
                                         # place; it does not re-render from this template.

  taxonomy:
    tags: [{{tags}}]                    # non-empty, lowercase kebab-case, intersecting the triggering
                                         # task's own tags (S04). NO type, NO specialization, ever —
                                         # those select bases, never skills (skill-module.md §6 rule 5)

  grants: [{{grants}}]                  # usually [] — most skills need nothing beyond the base's core
                                         # toolset. Disjoint from that core (D41, skill-module.md §6
                                         # rule 6). The skill-builder's OWN module is the one standing
                                         # exception: grants: [web_search] (D60).

  provenance:
    created: {{created}}                # ISO date, this run
    created_by: skill-builder
    source_feature: {{feature}}         # this feature's spec ID — required non-null (origin=generated)
    promoted_at: null
    # {{stale_risk_line}} — OPTIONAL (S17). Resolves to exactly `stale_risk: true` (4-space indented,
    # a sibling of the keys above) when this module was authored for a framework/library past the
    # model's training cutoff WITHOUT using the web_search grant to verify; resolves to nothing
    # (line omitted entirely) otherwise. Never write `stale_risk: false` — presence alone is the flag.
{{stale_risk_line}}

  stats:                                # fixed at creation — a brand-new module has no history yet.
    assignments: 0                      # never hand-edit; recomputed from traces.jsonl (D43)
    success_rate: null
    last_used: null

  central:
    synced: false
    remote_id: null
    body_sha256: {{body_sha256}}        # sha256 of every byte after this frontmatter's closing `---`
                                         # (agent-library-schema.md §2's exact recipe) — compute last
---

<!--
  Body guidance — strip this comment before writing the final SKILL.md; every real module in
  .claude/skills/ is clean prose + bullets, nothing left over. Additive-only, S1-S3 (skill-module.md
  §3), the hard constraint this whole format exists to enforce:
    - Opening line sets the trigger context, one sentence, in the base's own voice.
    - "In addition to your base instructions:" is FIXED text — keep it verbatim. It is what makes this
      module additive by construction, not merely by promise; every seed skill uses this exact line.
    - Every bullet ADDS an obligation or FORBIDS something further. Never permit, relax, weaken, or
      contradict a base instruction; never write "ignore" / "instead of" / "override" / "disregard" /
      "rather than the base" (S1).
    - No model, reasoning-effort, or dispatch instruction anywhere below (S2) — a skill is never a
      dispatch target; it has none to declare.
    - S4 (this module contradicting some OTHER skill it might be injected alongside) cannot be
      self-checked from inside one module — it is caught, if at all, by a human at the workforce gate.
      Nothing to do about it here.
-->

[PLACEHOLDER — one-sentence trigger context: "This task involves/touches …", matching the opening
line of every module in extensions/workforce/seed/skills/*/SKILL.md]

In addition to your base instructions:

- **[PLACEHOLDER — short obligation title].** [PLACEHOLDER — the obligation itself: additive or
  restrictive only, per S1/S3 above.]
- [PLACEHOLDER — one bullet per further obligation; the five seed skills run 3-6 bullets total —
  calibrate to roughly that range]
