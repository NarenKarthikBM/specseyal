# Defense Deck — Overview

**Feature**: `004-testing-completion`
**Prepared by**: Session A — deck-prep (Sonnet, D18)
**Sources**: `plan.md`, `spec.md`, `graphify-context.md`

> Format: markdown v1 (D15). Rendered at the human gate — the reviewer's primary artifact, alongside `round-N/suggestions.md` and the decision record — and, read on its own afterward, doubles as a shareable stakeholder summary (I-6). Git-versioned in place alongside `technical.md`, not round-scoped (D38): overwritten on every revision, prior versions live in git history on the feature branch.

*This is the one-page overview: written for a reader with no technical background. A reviewer must be able to reach an approve/reject decision from this page ALONE, without opening the companion `technical.md` (SC-007, principle 8) — so nothing here may assume the reader has, or needs, that file. No jargon, no code, no internal tool or process names. If a sentence needs an engineering background to parse, cut it or replace it with a plain analogy. Keep the whole page to about one page — a reviewer should be able to read it in under two minutes.*

---

## 1. What We're Building and Why

This plan does two different things, reviewed together but worth judging on their own terms.

**First**, it finishes the last piece of an assembly line that turns a finished piece of work into a clear record of what happened. Right now, when a piece of work is done, the wrap-up write-up is produced informally, a little differently each time. This plan locks that write-up into a standard, predictable shape — including a plain pass/fail-type status anyone, or any downstream system, can read without wading through prose. That standard write-up then feeds a brand-new step: an assistant reads it alongside the original request and produces a checking plan — for every single thing that was asked for, it writes down how someone could verify it actually happened, and honestly flags anything the write-up doesn't show evidence for, instead of assuming it's fine. This assistant does not run any checks itself, only plans them. Together, these two steps complete the system's assembly line, one step short of being trusted to run entirely on its own.

**Second, and separately:** while preparing to let this system build itself for the first time with nobody stepping in partway through, a bug turned up in the safety-check step that has to approve a piece of work before it starts. The safety check is too strict — it treats the system's own normal, expected progress-marking during a multi-step build as if the approved plan had been tampered with, and blocks the work partway through. This plan also fixes that bug. It is a different kind of change from the first — a security- and safety-relevant fix, not a new feature — and it is called out here so it gets judged on that basis.

---

## 2. What Could Go Wrong

- The new checking-plan write-up is authored by an AI reading a summary of the work, not by mechanically comparing against the original request line by line. It is designed to flag anything it cannot confirm rather than claim false coverage, but that honesty depends on the assistant following instructions correctly — there is no independent, automatic double-check behind it yet.
- The hand-off between the wrap-up write-up and the checking-plan write-up is designed to pass along only the minimum information needed, for cost and focus reasons — but that boundary is currently kept by instruction, not by a hard technical wall.
- The safety-check fix (the second piece, above) works by looking closely at exactly what changed in a piece of tracking information and only waving through changes that look like simple progress-marking — anything else gets blocked, no matter who made the change. That is a deliberately strict, security-relevant design, and it deserves particular scrutiny for edge cases that have not been tried yet.
- The two pieces of this plan happen to touch the very same underlying safety-check file, built in the same round of work. That is a sequencing risk — the pieces need to land in the right order — not a safety risk on its own, but worth knowing about.

---

## 3. What It Costs

The review for this plan uses the standard cost-conscious process now used for right-sized pieces of work — a smaller review panel than the most thorough option, chosen deliberately to control cost while still getting independent scrutiny. The build itself is modest: smaller than each of the two previous pieces of infrastructure this system has built for itself — roughly one new self-contained piece of the system plus a handful of small, targeted edits to something that already exists. Going forward, the first piece (the wrap-up-and-checking-plan work) carries a small ongoing cost: every time this system finishes a future piece of work, it costs a modest amount of AI-assisted effort to write the two documents. The second piece (the safety-check fix) is a one-time cost with no ongoing cost once it is shipped.

---

## 4. What "Done" Looks Like

You'll be able to watch any finished piece of work end with a clean, standardized wrap-up report and a matching checking plan that spells out exactly how every requirement could be verified — with anything unverifiable clearly called out rather than glossed over. Separately, you'll be able to watch a multi-step build run from start to finish without anyone needing to step in by hand to clear a stuck safety check partway through. The final proof point for both halves of this plan: this very system will be used to finish building itself, start to finish, with nobody stepping in — including surviving its own safety check the whole way through.
