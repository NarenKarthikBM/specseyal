# arm4-ceiling

Golden fixture for arm 4's **query-ceiling disclosure, ceiling-HIT branch** (T024,
005-graphify-context) — the branch this feature's `arm4-noceiling` fixture (T025) inverts
(S18: "a check that can only ever fire proves nothing about its quiet path", plan.md Arm 4).
This fixture drives a council member's on-demand graph-query loop TO the `standard` tier's
enforced ceiling: `cmd.sh` invokes `extensions/council/extension/scripts/ceiling-check.sh
standard 15` (`council-config.yml`'s `tiers.standard.query_ceiling: 15`, D77) — 15 is the exact
boundary (`count == ceiling`), not merely "comfortably over it": this round's own measured
uncapped baseline never exceeded 9 (A=8 B=7 C=9 D=2 E=6), so 15 is a manufactured ceiling-hit,
and testing the boundary exactly (rather than, say, 30) is what forces a contract-conforming
implementation to use `count >= ceiling` — a `count > ceiling`-only implementation would
wrongly report `ceiling_hit: false` on this exact input, and this golden would catch it.

The golden (`expected.txt`) is exactly two lines:

```
ceiling_hit: true
> **Reduced grounding** — query ceiling (15) reached; further graph queries for this review were not run.
```

Line 1 is the mechanical `ceiling_hit` flag, printed the same way it lands in the member's
`traces.jsonl` record (`docs/contracts/trace-schema.md` §1/§7 rule 12, D77). Line 2 is the
**canonical ceiling-hit reduced-grounding disclosure** — this fixture is its spec, since no
earlier task pinned its exact text. It reuses the exact `> **Reduced grounding** —` prefix
(same bold span, same em dash, `U+2014`) the existing FR-019 no-graph note already carries
verbatim at `extensions/council/extension/templates/member-prompt.md` (line ~41/99: `> **Reduced
grounding** — no graphify-out/graph.json found; this review is deck-only.`), so the chairman's
existing reduced-grounding detection — a string match on that exact prefix — catches a
ceiling-hit disclosure identically to a missing-graph one, with no new detection logic required.
Past the shared prefix, the line states the *ceiling* reason (not "no graph found") and the
ceiling `N` (15), per this task's own requirement. The sentence is a template parameterized only
by `N`:

```
> **Reduced grounding** — query ceiling (N) reached; further graph queries for this review were not run.
```

— so a future round hitting a different tier's ceiling, or a future recalibrated `N`, substitutes
its own resolved ceiling value with no other change to the sentence. **T025 (arm4-noceiling),
the Wave-5 `ceiling-check.sh` author, and T028 (orchestrator enforcement + mechanical disclosure
append) should all reuse this line verbatim**, substituting `N` for whatever ceiling that
invocation resolved.

This is the SC-006/SC-008 **"never silent"** guarantee (D74-3) made concrete: the trace's
`ceiling_hit: true` and the opinion's disclosure line are the same fact recorded twice — once
for the chairman to weight the opinion mid-round, once for a post-round audit. plan.md's own
framing (Arm 4, S09 → D53) is explicit that the **mechanical flag + mechanical append** are the
guarantee, not the member's free-texted prose: a member scrambling at its ceiling is
prompt-following at its *least* reliable, so the orchestrator — not the member — appends this
line the instant it enforces the cap. `ceiling-check.sh` is this fixture's mechanical stand-in
for that append, tested in isolation from any actual member/LLM behavior (mechanical, no-LLM,
no-key, per this task's own constraint).

`ceiling-check.sh` does not exist yet — it is authored in a later wave, not by this task — so
`cmd.sh` currently fails with "ceiling-check.sh: No such file or directory" (or equivalent) and
this fixture is intentionally **RED**: the correct TDD red-for-the-right-reason (`test/run.sh`'s
own fixture-discovery convention — a script-under-test that doesn't exist yet is expected to
fail, not a malformed fixture), not a defect in this fixture. Once `ceiling-check.sh` lands
conforming to the pinned interface (`<tier> <query-count>` on argv; stdout's first line always
`ceiling_hit: true|false`; a second line — the disclosure above — iff hit; nothing else when not
hit or the tier's ceiling is `null`/unset — the exact contract `arm4-noceiling`'s `cmd.sh` header
also states, confirmed to match byte-for-byte at authoring time), this file goes green with no
edits required.

**Provenance:** authored 2026-07-14, task T024 (005-graphify-context), skill
`skl_golden_fixture_discipline@1.0.0`. Depends on T002 (harness convention, done), T023 (trace
`graph_queries`/`ceiling_hit` fields, done), T026 (`council-config.yml` `query_ceiling`, done).
Depended on by `ceiling-check.sh`'s own authoring (a later wave, must satisfy this golden) and
T028 (orchestrator enforcement + mechanical disclosure append) — both must reproduce line 2's
exact text, with `N` substituted, whenever a member's count reaches its tier's ceiling.
