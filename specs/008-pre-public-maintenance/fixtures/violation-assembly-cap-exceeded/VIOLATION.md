# Violation — assembly cap exceeded

**Contract:** `docs/contracts/agent-library-schema.md` §3 Guardrails / D40 ("Assembly cap: base +
3 injected skills, maximum. The assignment step trims by tag-rank; it never exceeds.").

**What's broken:** `agents/assignment.md`'s roster row for T001 lists **four** injected skills
(`skl_a@1.0.0`, `skl_b@1.0.0`, `skl_c@1.0.0`, `skl_d@1.0.0`) — one past the cap of three. The
`## Workforce Gate` section's own `### Roster approved` table repeats the same (wrong) four-skill
list, so the file is internally self-consistent about the fault rather than contradicting itself
in two places. The assembly-trace block below the roster narrates the same over-injection rather
than showing the correct trim-and-log behavior (`dropped = ∅` where a correct assembly would log
`skl_d` as dropped).

**Everything else in this directory is byte-identical to `conformant/`** (mechanical
`feature:`/path substitution aside) — `T002`'s row is untouched (`*(none)*` injected, as in
`conformant/`), and every other artifact (`decision-record.md`, `completion-report.md`,
`testing.md`, `traces.jsonl`) is unchanged and independently valid.

**Expected checker message:**

```
agents/assignment.md · agent-library-schema.md §3 (D40 Guardrails): assembled agent for T001
carries 4 injected skills, exceeding the assembly cap of 3
```

**Note:** `traces.jsonl`'s `implement`/`implementer` record still shows `"skills": []`, matching
`conformant/` — this fixture's roster describes what a (fictitious, never-dispatched) assignment
would look like, exactly as `specs/000-sample/agents/assignment.md` and `specs/000-sample/
traces.jsonl` are themselves both hand-authored and illustrative rather than measured (see this
tree's own `completion-report.md` disclosure convention, and the top-level `fixtures/README.md`
note on this). No cross-artifact consistency rule between the roster and the trace record is
stated in any of the six directly-checked contracts, so this does not introduce a second,
unintended violation.
