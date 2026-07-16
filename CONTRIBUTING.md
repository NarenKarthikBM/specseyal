# Contributing to SpecSeyal

SpecSeyal is a spec-driven development orchestrator: a governed pipeline that
takes a feature from spec through a council-defended plan to specialized
parallel implementation and testing. This guide tells you how to contribute to
it *correctly* — the conventions below are non-negotiable project discipline,
not style preferences.

Before you open a PR, read (in order):

- `docs/00-VISION-AND-ARCHITECTURE.md` — the north star. Read first, always.
- `docs/05-IMPLEMENTATION-PLAN.md` — milestones M0–M7. Check which milestone is active.
- `docs/10-COUNCIL-EXTENSION-SPEC.md` — the council extension design.
- `docs/90-DECISIONS-AND-IDEAS.md` — the decision log this guide asks you to write to.

## Artifacts are the contract

Every phase of the pipeline reads artifacts in and writes exactly one artifact
out — this is the interface the CLI and the platform layer share, and it is
the assumption every extension in `extensions/` is built on. Feature artifacts
live under `specs/NNN-feature/` (`spec.md`, `plan.md`, `council/`, `tasks.md`,
and phase reports); the full per-artifact layout is normative in
`docs/contracts/artifact-layout.md`. `specs/000-sample/` and
`specs/001-council-extension/` are worked examples you can read for the real
shape.

If your change adds a phase, changes what a phase reads or writes, or alters
an artifact's schema, update the matching contract under `docs/contracts/` in
the same change — a contract that lags its implementation is the exact
shared-mutable-state hazard this project's tooling exists to catch.

## The dogfooding rule

From M1 onward, the pipeline builds itself: each milestone gets a spec, is run
through the pipeline, and the council reviews the plan for building the *next*
milestone. M0 was the only milestone built in a plain session. In practice
this means: if you change how a phase behaves, expect that behavior to be
exercised for real by the next feature that goes through the pipeline, not
just by a hand-run test.

## Branch and commit conventions (D25)

- **Branch before you plan.** Create the feature branch before starting the
  plan phase, and name it from the spec ID — no prefix, e.g. a feature at
  `specs/NNN-feature/` branches to `NNN-feature` (see `007-oss-docs`, the
  branch this guide itself was written on, for a real example).
- **Phase-tagged commits.** Every commit that corresponds to a pipeline phase
  is tagged with that phase's name: `<phase>(<spec-id>): <summary>`. Tags in
  use include `spec`, `plan`, `council`, `gate`, `tasks`, `categorize`,
  `agents`, `impl`, `testing`, `complete`, and `docs`/`fix` for out-of-band
  documentation or bug-fix commits not tied to a phase artifact. For example:
  `plan(007-oss-docs): validate-profile design + OSS front-door structure`
  or `tasks(007-oss-docs): graph-aware tasks.md — 17 tasks, 5 execution waves`.
- **One phase, one commit (or a tight, named sequence).** Don't squash phase
  history together — a gate approval binds to the artifact state at a
  specific commit, so the commit log is part of the audit trail, not
  incidental history.
- **Cleanup on completion.** A feature branch's lifecycle ends with cleanup
  once the feature completes; don't leave a merged feature branch behind as
  the ongoing home for unrelated follow-up work.

## The log discipline (non-negotiable)

This is the one rule in this guide with zero exceptions:

- **Any decision made in a session gets a D-row in
  `docs/90-DECISIONS-AND-IDEAS.md`, in that same session.** Not a follow-up
  PR, not a note to self — the same session in which the decision was made.
  Append it under "Decisions made" using the existing table shape:

  ```
  | # | Date | Decision | Notes |
  ```

  Continue the `D`-numbering from the highest existing row.

- **Every idea gets an I-row immediately, one line each** — even ideas you
  don't act on. Append under "Idea parking lot" using its table shape:

  ```
  | # | Idea | Origin | Ripeness |
  ```

  Continue the `I`-numbering from the highest existing row.

If your PR changes how the project works, resolves a tradeoff, or picks
between options, it needs a D-row committed alongside the change — a
rationale that only exists in a PR description is a rationale that gets lost
the moment the PR is squashed or the thread goes stale.

## Proposing a change

1. Branch from `main`, named per the convention above (spec ID for a feature;
   a short descriptive slug for a standalone fix or doc change).
2. Make the change. If it involved a decision, add the D-row (and any I-rows)
   to `docs/90-DECISIONS-AND-IDEAS.md` in the same working session, per the
   log discipline above.
3. Commit using the phase-tagged convention. Small non-pipeline changes
   (typo fixes, doc corrections) may use a plain `fix(...)` or `docs(...)`
   tag without going through a full spec-kit cycle.
4. Open a PR describing what changed and, if applicable, which D-row(s) or
   I-row(s) it added.

## Where things live

```
extensions/        # pipeline extensions (graphify, council, git, workforce, deck-render, testing)
platform/          # manager + GUI + orchestrator (empty until M5)
docs/              # vision, plan, council spec, decision log, and docs/contracts/ (per-artifact schemas)
specs/             # per-feature SDD artifacts: specs/NNN-feature/...
```

## License

Contributions are made under this project's license — see `LICENSE`.
