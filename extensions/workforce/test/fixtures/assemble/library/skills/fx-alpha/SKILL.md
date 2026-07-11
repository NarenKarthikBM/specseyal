---
name: fx-alpha
description: T021 frozen test fixture skill (extensions/workforce/test/test_assemble.sh,
  SC-003/S09). Declares one grant unique to it (`zz_alpha_only`) plus one shared with
  fx-beta (`web_search`), so the pair exercises the grant-union total-order test. Injected
  when a task's tags include `alpha`. Not a real skill.

specseyal:
  schema_version: "1.0"
  kind: skill
  id: skl_fx_alpha
  version: 1.0.0
  origin: seed

  taxonomy:
    tags: [alpha]

  grants: [web_search, zz_alpha_only]

  provenance:
    created: 2026-07-11
    created_by: human
    source_feature: null
    promoted_at: null

  stats:
    assignments: 0
    success_rate: null
    last_used: null

  central:
    synced: false
    remote_id: null
    body_sha256: null
---

Frozen T021 test fixture. Declares grants `web_search` and `zz_alpha_only`
(deliberately NOT alphabetically first in this frontmatter list) purely so
`extensions/workforce/test/test_assemble.sh` can assert the grant union is
SORTED into total order (S01) at assembly, not left in whatever order the
skills were injected or the grants were declared. Not a real skill.
