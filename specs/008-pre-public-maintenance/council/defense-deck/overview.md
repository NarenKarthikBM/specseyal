# Defense Deck — Overview

**Feature**: `008-pre-public-maintenance`
**Prepared by**: Session A — deck-prep (Sonnet, D18)
**Sources**: `plan.md`, `spec.md`, `graphify-context.md`

> Format: markdown v1 (D15). Rendered at the human gate — the reviewer's primary artifact, alongside `round-N/suggestions.md` and the decision record — and, read on its own afterward, doubles as a shareable stakeholder summary (I-6). Git-versioned in place alongside `technical.md`, not round-scoped (D38): overwritten on every revision, prior versions live in git history on the feature branch.

*This is the one-page overview: written for a reader with no technical background.*

---

## 1. What We're Building and Why

Before this project opens up to the public, we're clearing out the last few rough edges. Right now, someone trying it out for the first time has to download the entire project just to install one small piece of it — we're adding a single, one-line command that fetches and installs just what they need, with no separate download step first. We're also adding an automatic checker that reads a piece of project paperwork and tells you whether it's filled out correctly, instead of relying on a person to catch mistakes by review. Finally, we're fixing four small, currently-invisible problems that would otherwise quietly mislead a newcomer, a contributor, or an outside reviewer once the project goes public — none of these fixes change who approves anything or how approvals work.

---

## 2. What Could Go Wrong

- The new one-command install works by downloading files over the internet — "download and run" commands can be risky if done carelessly. We're addressing this by making the command reviewable (you can see what it downloads before running it) and pointing it at a fixed, known version rather than "whatever is newest" — but the exact wording of that safety approach is one of the things this review is meant to weigh in on.
- Six separate fixes are landing in the same batch, and a couple of them touch the same shared files (the project's decision log, one installer's setup file). If done carelessly, two people working at once could step on each other. The plan handles this by doing those steps one at a time, in a fixed order.
- Two of the six fixes — one that records which version of the review process was used, and one that keeps a placeholder file path out of certain internal records — can currently only be checked by hand, on the next real run. There isn't yet an automatic, repeatable test proving they keep working over time.
- One of the fixes changes a small piece of shared code that's also used in two unrelated places elsewhere in the system. The tests written for it prove the intended fix works, but don't yet prove the other two places are left undisturbed.

---

## 3. What It Costs

A small amount of AI-assisted review effort up front (this defense session), followed by a bounded, pre-scoped batch of maintenance work — six independently-checkable fixes spread across five parts of the project. No new ongoing cost, subscription, or dependency is introduced by any of it.

---

## 4. What "Done" Looks Like

A newcomer can install one piece of the project with a single copy-pasted command — no separate download step. A new automatic checker can be pointed at any feature's paperwork and will say pass or fail, naming exactly what's wrong if it fails. Four small, previously-silent problems stop happening. And the project's own tracking log shows all six items closed out, leaving the project one clean step away from going public.
