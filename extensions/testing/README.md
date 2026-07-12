# speckit-ext-testing

The 4th pipeline extension — the last one before Checkpoint α (docs/00 §4.1, docs/05 M4: the whole notebook pipeline running CLI-only). It provides the two commands that close out a pipeline run:

| Command | Phase | Session | Writes |
|---|---|---|---|
| `/speckit-complete` | `complete` | main (the Opus orchestrator authors — no new model role) | `completion-report.md` — a finalized, contract-validated format (frontmatter `status ∈ {success, partial, failed}` + the fixed core sections) that *is* the future D19 `phase.completed` `artifact.body`, no reshaping |
| `/speckit-testing` | `testing` | separate — main dispatches one Sonnet `tester` subagent | `testing.md` — a coverage map (every `spec.md` Success Criterion **and** Functional Requirement → a verification approach); `executed: none` always |

## The doc-only boundary

The testing agent **produces a document; it does not execute tests** (docs/00 line 37: "a testing agent produces the doc now; runs tests later"). Running tests, pass/fail results, and a remediation feedback loop are testing-agent v2 — explicitly out of scope here, and the boundary is legible in `testing.md` itself (`executed: none`).

## What this extension does NOT own

The `complete(<id>)` / `testing(<id>)` phase-tagged git commits are **git-ext's own** `after_complete` / `after_testing` hooks — owned-source in `extensions/git/`, not this extension's (D57, artifact-layout.md §9 "Cross-extension seams"). This extension's own `extension.yml` declares no hooks of its own; `install.sh` still runs the same manifest-driven hook merge every sibling runs, so a future testing-ext hook would register with zero installer changes.

## Layout

```text
extensions/testing/
├── install.sh · uninstall.sh · README.md
├── extension/
│   ├── extension.yml               # provides: speckit.complete, speckit.testing
│   ├── testing-config.yml          # tester.model: sonnet (D18) + the doc-only guard
│   ├── commands/                   # speckit.complete.md · speckit.testing.md
│   ├── templates/                  # tester-prompt · completion-report/testing templates · trace-fragment
│   └── skills/{speckit-complete,speckit-testing}/SKILL.md
│       # nested under extension/ (this feature's own council-approved plan.md
│       # §1.1 Project Structure — not the top-level extensions/<name>/skills/
│       # convention graphify/council/git/workforce use)
└── test/run.sh                     # contract validation (goldens derived from docs/contracts/*.md) + install round-trip
```

## Install

```bash
bash extensions/git/install.sh .        # git-ext first — its after_complete/after_testing hooks are what commit these two phases
bash extensions/testing/install.sh .
```

Copies `extension/` → `.specify/extensions/testing/`, installs `speckit-complete` / `speckit-testing` to `.claude/skills/`, and merges testing's hook rows (none, as of this writing) into `.specify/extensions.yml` — append-only, idempotent, driven entirely off the installed `extension.yml` manifest.

## Uninstall

```bash
bash extensions/testing/uninstall.sh .
```

Deregisters testing's entry from `.specify/extensions.yml` **first**, then removes the installed payload and the two command skills (the 002 FR-014 pattern) — nothing else. Byte-identical round-trip: install → uninstall leaves `.specify/extensions.yml` exactly as it was before install.

Built by feature `004-testing-completion` (dogfood). See `specs/004-testing-completion/` for the spec, plan, council record, and tasks.

License: MIT.
