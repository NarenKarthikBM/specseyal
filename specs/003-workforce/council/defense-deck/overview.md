# Defense Deck — Overview

**Feature**: `003-workforce`
**Prepared by**: Session A — deck-prep (Sonnet, D18)
**Sources**: `plan.md`, `spec.md`, `graphify-context.md`

> Format: markdown v1 (D15). Rendered at the human gate — the reviewer's primary artifact, alongside `round-N/suggestions.md` and the decision record — and, read on its own afterward, doubles as a shareable stakeholder summary (I-6). Git-versioned in place alongside `technical.md`, not round-scoped (D38): overwritten on every revision, prior versions live in git history on the feature branch.

*This is the one-page overview: written for a reader with no technical background. A reviewer must be able to reach an approve/reject decision from this page ALONE, without opening the companion `technical.md`.*

---

## 1. What We're Building and Why

Once a piece of work has been broken down into a task list, someone has to decide who should do each task and what tools or access they're allowed to use while doing it. This project automates that decision. It reads the finished task list, works out what kind of work each task is, and matches it to the right specialist — plus any extra skills that specialist needs for the job — before anyone starts building anything. When a task needs a skill nobody has yet, the system writes up that new skill itself and adds it to its own toolbox for next time, instead of a person having to build a one-off specialist from scratch every time. A person always reviews the final assignment list and has to sign off before any building starts — because signing off on who's assigned is also signing off on what access they get.

---

## 2. What Could Go Wrong

- The system promises that running the same assignment twice, on the same inputs, produces the exact same result every time — a strong "no surprises" guarantee. That promise only holds if the automatic-matching step stays strictly rule-based; if any judgment ever creeps into a part that's supposed to be purely mechanical, the guarantee could quietly stop being true. This gets the closest scrutiny in review.
- When nothing new needs to be built (every task already matches an existing specialist), the system may leave behind no record that this step ran at all. It's a bookkeeping question, not a safety one — reviewers will settle whether that's the right call.
- The starting lineup of specialists was chosen using evidence from only two earlier projects — and both of those projects happened to be about building this very system. So the starting lineup may be narrower, or more self-tailored, than it should be for general-purpose work. It's designed to fail honestly (fall back to a generic specialist and flag the gap) rather than guess, and it gets re-checked against outside evidence later.
- One open question is left for reviewers to decide directly: should the specialist that writes new skills be allowed to look things up online while it works? Granting that would be the very first time anything in this system reaches out to the internet *before* a person has approved it — every other network access currently happens only after sign-off. The recommendation is not to grant it for now; reviewers get the final say.
- Newly self-written skills get saved into a shared folder that also gets wiped and rebuilt whenever unrelated parts of the system are reinstalled — so there's a real risk a self-written skill could get accidentally deleted by an unrelated update. The build includes a specific safeguard against exactly that.

---

## 3. What It Costs

The review for this plan uses a deliberately cost-controlled process — a smaller panel review than earlier projects used, chosen specifically to keep review costs down while still getting independent scrutiny. The build itself covers two connected pieces of infrastructure delivered together, roughly comparable in size to each of the two earlier infrastructure projects. One difference from those earlier projects: this one does carry a small ongoing cost once it's live — every time it's used on a future piece of work, it costs a modest amount of AI-assisted effort to sort the tasks and, occasionally, to write up a new skill — rather than being a one-time build cost with nothing running afterward.

---

## 4. What "Done" Looks Like

You'll be able to hand the system a finished task list and watch it automatically sort every task by what kind of work it is, match each one to the right specialist, and hand you back a clear roster showing exactly who's doing what and what access they'll have — no hidden or blank entries. You approve that roster once, and the building work begins using exactly the assignments you signed off on. If a task needs a skill nobody has yet, you'll see a brand-new skill get written and visibly marked as new-and-untested, not silently treated as if it had always been there. The final proof point: this system will be used to assign the work for building itself, start to finish, before it's considered done.
