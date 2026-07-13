# Defense Deck — Overview

**Feature**: `005-graphify-context`
**Prepared by**: Session A — deck-prep (Sonnet, D18)
**Sources**: `plan.md`, `spec.md`, `graphify-context.md`

> Format: markdown v1 (D15). Rendered at the human gate — the reviewer's primary artifact, alongside `round-N/suggestions.md` and the decision record — and, read on its own afterward, doubles as a shareable stakeholder summary. Git-versioned in place alongside `technical.md`, not round-scoped: overwritten on every revision, prior versions live in git history on the feature branch.

---

## 1. What We're Building and Why

This pipeline uses an internal "map" of the codebase — a knowledge graph — to help every step (planning, building, reviewing) understand what connects to what. That map has four problems today: it can't see most of what this project is actually built from (its own scripts and config files); it goes stale silently, so a step can trust an out-of-date map without knowing it, which has already nearly caused a real mistake; it hands every reader the exact same one-size-fits-all readout even though a planner, a reviewer, and a code-builder each need something different; and a reviewer checking facts against it can ask it an unlimited number of questions, which quietly drives up cost.

This feature fixes all four, as four separate, independently-completable pieces of work: **(1) teach the map to see the project's own scripts and config files**, **(2) make "is the map still accurate?" something the system checks and warns about automatically, instead of a silent assumption**, **(3) give each reader its own right-sized readout instead of one file everyone over-reads**, and **(4) put a hard, visible cap on how many questions a reviewer can ask the map in one pass**. None of this touches the outside tool the map is built with — everything is added on top of it, so that tool stays swappable and unmodified. Because the pieces are independent, if any one turns out to be more than we want to take on right now, it can be dropped or deferred without unwinding the other three — that decision is never made silently; it always shows up as an explicit note in the review record.

**One honesty caveat, stated up front:** the piece that teaches the map to see scripts and config files (item 1) is, itself, made almost entirely of scripts and config files — exactly what the map cannot see yet. So this review is partly a case of checking a map's blind spot using the same map. Where that applies, this deck says so plainly rather than presenting an engineer's read-through of the code as if it were the map's own verified fact.

---

## 2. What Could Go Wrong

- **The piece that adds missing coverage to the map can't verify its own correctness using the map** (a chicken-and-egg problem — see the honesty caveat above). If it has a bug, the map itself won't catch it. Mitigated by hand-built test cases with known, checkable answers, plus a person reading the actual code rather than trusting the map to confirm it.
- **Splitting one readout into three separate versions for different readers could let them quietly drift out of sync with each other.** Mitigated by generating all three from a single pass over a single map, so they can't diverge by construction, plus a dedicated check per version.
- **Putting a hard cap on how many questions a reviewer can ask could cut a reviewer off mid-review, before it has fully checked its facts.** Mitigated by setting the cap generously — calibrated against real usage from this very review round — and by making sure a cut-off reviewer's findings are always flagged as partially-checked, never silently presented as fully verified.
- **The outside tool this all sits on top of could change in a future update and break the piece that keeps the map current.** Mitigated by pinning to a stable interface and by tests that are designed to catch a break immediately rather than let it pass unnoticed.
- **This review itself is being conducted using the same map that has the blind spot this feature is fixing.** Mitigated by disclosing that limitation everywhere it applies, including in this very review — never presenting a guess as a verified fact.

---

## 3. What It Costs

About eight to nine short automated review passes to check the plan itself (this is a standard-depth review, not the most exhaustive tier available), followed by a small, well-scoped amount of AI-assisted build work. The build work splits cleanly into four independent, bite-sized pieces rather than one large undertaking, and none of it requires new outside tools or a bigger review team than the pipeline already uses.

---

## 4. What "Done" Looks Like

- The map correctly shows the connections between the pipeline's own scripts and configs that it couldn't see before — checked against a specific, previously-broken example (a script that's called constantly but that the map today insists has no relationship to its caller).
- The map warns loudly and automatically when its readout is out of date, instead of silently letting a reader trust stale information.
- Refreshing the map after a small change is fast and cheap — not the expensive full rebuild the map currently requires for every update.
- Each of the six tools and roles that read the map gets its own right-sized version, and each of those six is individually tested so a future change can't quietly break one of them.
- A reviewer's fact-checking against the map is capped, and if a reviewer hits that cap, that fact is flagged plainly in its findings rather than hidden.
- And carried honestly to the end: because this feature's own changes are made of exactly the file types its blind spot covers, part of its own paper trail is double-checked by a person reading the code, not by the map — that will be true of this review too, and it is called out rather than smoothed over.
