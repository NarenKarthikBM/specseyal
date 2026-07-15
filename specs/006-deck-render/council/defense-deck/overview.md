# Defense Deck — Overview

**Feature**: `006-deck-render`
**Prepared by**: Session A — deck-prep (Sonnet, D18)
**Sources**: `plan.md`, `spec.md`, `graphify-context.md`

> Format: markdown v1 (D15). Rendered at the human gate — the reviewer's primary artifact, alongside `round-N/suggestions.md` and the decision record — and, read on its own afterward, doubles as a shareable stakeholder summary. Git-versioned in place alongside `technical.md`, not round-scoped: overwritten on every revision, prior versions live in git history on the feature branch.

---

## 1. What We're Building and Why

Right now, when someone reviews and approves a piece of work in this pipeline, the summary they read is a plain text file — fine for a quick read in a terminal, but awkward to open on a phone, project in a meeting, or hand to someone outside the team. This feature adds an optional switch that turns that same summary into a proper presentation file — the kind that opens in ordinary presentation software — without changing a single word of what's actually being reviewed or approved.

The presentation is always a copy of the text, never a replacement for it. It's clearly labeled on every page as a copy, and it names exactly which text file it came from and which version of that file, so nobody can mistake the pretty version for the real decision record. Most work won't use this feature at all — it's off by default, and turning it on for one piece of work has zero effect on any other. It's a convenience for whoever's reading, not a change to what's being reviewed.

---

## 2. What Could Go Wrong

- **The presentation-making software could produce a file that our automated checks approve of, but that doesn't actually open cleanly in real presentation software.** If that happened, it would only surface at the one point someone actually opens the file by hand — which is why opening it and looking at it is kept as an explicit, named step rather than assumed to just work.
- **A very long piece of text in the original summary could spill off the bottom of one slide.** If that happens, it simply continues onto a labeled "continued" slide — nothing gets cut off or silently dropped, it just isn't as tidy-looking as a hand-designed slide would be.
- **The example file used to test that the conversion works correctly could go stale over time**, if the shape of future summaries changes and nobody updates the test example to match. This is written down as a known thing to keep an eye on, not left as a silent assumption.
- **The small check this feature adds — which only catches one specific typo in one specific setting — could later be mistaken for a full safety check on all of a project's configuration.** It isn't, and that limitation is written down in three separate places so nobody assumes more coverage than actually exists. It also only fires at the moment someone actually tries to make a presentation, not the moment the setting is typed in — so a typo can sit unnoticed until then.
- **A separate, unrelated project that's midway through a big internal rewrite might finish around the same time as this one's review**, which could affect the timing of some of its own internal measurements. This is a scheduling detail for the people managing it, not a safety concern for this feature.

---

## 3. What It Costs

This is a small, self-contained addition — not a rewrite of anything that already exists. Getting it reviewed takes about the pipeline's standard-depth review pass, the same cost-controlled process used for similarly-sized work, not the most exhaustive review tier available. Building it afterward is a modest, well-scoped amount of AI-assisted effort, done in one clean piece rather than spread across the rest of the system. It adds no ongoing cost once it's built: the presentation feature never runs unless someone explicitly turns it on for a specific piece of work, and even then it uses no paid AI processing at all — it's a purely mechanical conversion. The one extra software library it optionally uses is free and is only ever downloaded on a machine where someone has actually chosen to use this feature.

---

## 4. What "Done" Looks Like

- Someone can turn on a single setting for a specific piece of work, run one command, and get back a real presentation file that opens normally in standard presentation software — no errors, no repair prompts.
- That presentation reads the same way, and leads to the same conclusion, as the original text summary — nothing important is missing, and nothing has been added that wasn't in the original.
- Every page of the presentation clearly states that it's a copy, and names exactly which text file and version it was copied from — so a stale copy is always identifiable as stale just by looking at it.
- If the feature is left off, which is the default, absolutely nothing about how reviews happen today changes.
- If the presentation tool isn't available on someone's machine, or something else goes wrong, the person is told plainly what happened and the review proceeds normally on the original text — it never gets stuck waiting on the presentation to work.

