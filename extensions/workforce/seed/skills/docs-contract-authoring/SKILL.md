---
name: docs-contract-authoring
description: Authoring contract-validated documentation artifacts — docs/contracts/ schemas, frontmatter-bearing records, and the templates that render into them. Injected when a task's tags include contract, schema, frontmatter, template, or spec-kit-docs.

specseyal:
  schema_version: "1.0"
  kind: skill
  id: skl_docs_contract_authoring
  version: 1.0.0
  origin: seed

  taxonomy:
    tags: [contract, schema, frontmatter, template, spec-kit-docs, documentation, contract-authoring]

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
    body_sha256: 9b68a8b3f52ca1ec826419488b55df4bf22311ef8e52f1678580cc6e2815ca10
---

This task authors a documentation artifact that a contract validates — a docs/contracts/ schema, a frontmatter-bearing record, or a template that renders into one.

In addition to your base instructions:

- **Author to the contract's own section list.** Every section the contract requires is present, in the contract's order, spelled exactly as the contract names it. Where a contract and a validator both exist, derive the artifact's structure from the contract itself, never from a hand-maintained parallel copy that can drift.
- **Put the machine-readable fields in frontmatter, exact.** A status, a phase, an enum value — anything a downstream reader parses without prose — belongs in YAML frontmatter, and every closed-enum value is spelled character-for-character as the contract enumerates it.
- **Keep the normative core and any appendix cleanly separated.** The contract validates the core; extra material rides outside it, clearly fenced, so the core still validates on its own with the appendix absent.
- **Validate before calling it done.** A contract-bound artifact is complete only when it validates against its contract; a document that fails validation is an incomplete phase, and the honest state is to say so.
- **State coverage as code, not as a promise.** When a document must map or enumerate every item of some set, add a mechanical check that greps the source of truth and asserts each item appears — the completeness claim is enforced by the check, not by careful reading.
- **Mark a genuine gap as a gap.** When the source material does not evidence something the artifact must cover, flag it an explicit gap; never fabricate a covered row to make the coverage number look whole.
