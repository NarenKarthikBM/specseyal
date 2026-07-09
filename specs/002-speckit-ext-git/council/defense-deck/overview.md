# Defense Deck — Overview

**Feature**: `002-speckit-ext-git`
**Prepared by**: Session A — deck-prep (Sonnet, D18)
**Sources**: `plan.md`, `spec.md`, `graphify-context.md`

> Format: markdown v1 (D15). Rendered at the human gate — the reviewer's primary artifact, alongside `round-N/suggestions.md` and the decision record — and, read on its own afterward, doubles as a shareable stakeholder summary (I-6). Git-versioned in place alongside `technical.md`, not round-scoped (D38): overwritten on every revision, prior versions live in git history on the feature branch.

*This is the one-page overview: written for a reader with no technical background. A reviewer must be able to reach an approve/reject decision from this page ALONE, without opening the companion `technical.md`.*

---

## 1. What We're Building and Why

When the team builds a new feature, someone currently has to manage the underlying record-keeping by hand: starting a fresh workspace for the feature, saving progress at the right moments, and stitching everything back together when the feature is finished. We've done this manually for the first two builds. This project automates all of that record-keeping so it happens by itself, correctly, every time — freeing the engineer to focus on the actual work instead of the paperwork around it. It also adds a safeguard: once something has been reviewed and approved, the system will notice if it gets quietly changed afterward, and it will refuse to let work continue as if nothing happened until it's looked at again.

---

## 2. What Could Go Wrong

- Some of the automatic "save progress" steps depend on other parts of the system correctly triggering them. If one of those triggers is ever missed, that specific save point gets skipped — nothing is lost, because a broader safety-net save still catches the work, but the record becomes slightly less detailed at that one spot. This is the single connection point getting the closest scrutiny in review.
- The "has this changed since it was approved?" check only runs at the moment the next step is about to begin, not continuously. So if someone edits an already-approved document in the middle of an already-running step, that particular edit might not be caught right away.
- All of the automated steps are controlled by one shared settings file. If an update to that file were ever done incorrectly, it could disrupt every automated step across the whole system, not just this feature — so that update is handled with extra care (an automatic format check, plus a clean undo if anything looks wrong).
- If two people's work needs to be combined and it doesn't line up cleanly, the system deliberately stops and asks a person to sort it out rather than guessing — so this occasionally means an extra manual step, by design, instead of a silent risk.

---

## 3. What It Costs

This is behind-the-scenes infrastructure work, not a new feature end users will see or interact with directly. The review process is short and structured — a small panel of reviewers examines the plan from different angles before anything gets built. The build itself is intentionally small and mechanical: a handful of short, simple scripts and one new command, reusing plumbing that already exists rather than inventing anything new. All told, a modest, contained amount of effort — closer to days than weeks — and it has no ongoing running cost once built, since it does no automated "thinking" work of its own while it operates.

---

## 4. What "Done" Looks Like

You'll be able to watch a feature go from idea to finished work without anyone typing a single manual record-keeping command — a fresh workspace appears on its own, and a clear trail of save points builds up automatically as work progresses. If someone edits an already-approved plan, the next step will visibly refuse to proceed until it's re-approved — you'll see the block, not a silent pass-through. When a feature is finished, one command folds all of that work cleanly back into the main line of work while keeping every step of its history intact and visible — nothing gets quietly erased or collapsed together. Separately, a small time-boxed experiment about isolating parallel work will report back a plain recommendation — worth adopting later, or not — regardless of which way it lands.
