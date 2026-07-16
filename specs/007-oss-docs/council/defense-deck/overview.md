# Defense Deck — Overview

**Feature**: `007-oss-docs` — OSS Front Door + Profile Contract Validator
**Prepared by**: Session A — deck-prep (Sonnet, D18)
**Sources**: `plan.md`, `spec.md`, `graphify-context.md`

> Format: markdown v1 (D15). Rendered at the human gate — the reviewer's primary artifact, alongside `round-N/suggestions.md` and the decision record — and, read on its own afterward, doubles as a shareable stakeholder summary (I-6). Git-versioned in place alongside `technical.md`, not round-scoped (D38): overwritten on every revision, prior versions live in git history on the feature branch.

---

## 1. What We're Building and Why

This project is getting ready to go public, and two things need to happen first. First, it needs a proper "welcome mat" — a homepage that explains what the project is and how to use it, plus the standard guides every open-source project has: how to contribute, how to behave, and how to report a security problem privately. Right now, a stranger arriving at the project would find none of that.

Second, the project has a central settings file that controls how much human oversight is required before automated work happens. Today, that file is only checked by a person reading it carefully — there's no automatic check. This has already caused a real problem: a small typo in that file quietly weakened the oversight it was supposed to guarantee, and nothing caught it. This change adds a small, automatic checker that rejects a broken settings file outright, instead of letting it fail silently.

---

## 2. What Could Go Wrong

- The plan proposes making the new checker mandatory and automatic, running before certain pipeline steps. If it's wired in too aggressively, a settings file that should be fine could get wrongly blocked, stalling someone's work. The team is presenting a safer, "check it yourself when you want" alternative alongside the automatic option, so this can be dialed back if the reviewers prefer.
- The welcome-mat documents describe file locations and commands as they exist today. If the project's layout changes later, those documents could go stale and quietly mislead a newcomer. The team has decided, on purpose, not to build an automatic staleness-checker in this round — that's accepted as a small, known risk rather than solved here.
- Before anything goes public, the new documents need to be scrubbed of anything private, like a personal computer's file paths. The plan includes an automated scan for this, but automated scans aren't perfect, so there's a small chance something could slip through and still needs a careful final look.

---

## 3. What It Costs

A small-to-medium amount of work: a handful of short writing tasks for the welcome-mat documents (these can be done side by side, independently), one small standalone piece of software for the settings checker, plus this project's standard review process — a multi-reviewer check before the work starts, and a short check afterward to confirm it's done. No new paid tools, subscriptions, or ongoing costs are introduced.

---

## 4. What "Done" Looks Like

- Anyone can land on the project's homepage and, without reading any code, understand what it does, how the workflow is shaped, and how to try it themselves.
- Someone who wants to contribute can find clear, correct instructions for how to do it properly, plus a private way to report a security issue and templates for filing a bug or a request.
- The known typo-in-settings problem gets caught automatically from now on, with a plain message explaining exactly what's wrong — instead of silently letting a weaker oversight setting through.
- The project has everything it needs to be made public, with no missing pieces left over.
