---
name: fx-beta
description: T021 frozen test fixture skill (extensions/workforce/test/test_assemble.sh,
  SC-003/S09). Declares one grant unique to it (`aa_beta_only`) plus one shared with
  fx-alpha (`web_search`), so the pair exercises the grant-union total-order test. Injected
  when a task's tags include `beta`. Not a real skill.

specseyal:
  schema_version: "1.0"
  kind: skill
  id: skl_fx_beta
  version: 1.0.0
  origin: seed

  taxonomy:
    tags: [beta]

  grants: [aa_beta_only, web_search]

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

Frozen T021 test fixture. Declares grants `aa_beta_only` and `web_search`.
Paired with `fx-alpha`: together the two skills' raw injection-order grant
concatenation is `web_search, zz_alpha_only, aa_beta_only` (alpha injects
first by id tie-break) -- deliberately NOT already sorted, so a passing
grant-union test proves `total_order()` actually re-sorted the union rather
than merely preserving injection/dict order. Not a real skill.
