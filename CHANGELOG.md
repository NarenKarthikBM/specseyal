# Changelog

All notable changes to this project are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.1.0] — 2026-06-22

Initial release. Extracted from an existing in-house integration into a portable, repo-agnostic template.

### Added
- **Graphify grounding extension** (`extension/`) — a spec-kit extension that registers optional
  `before_plan` / `before_tasks` / `before_implement` hooks and holds the graph-path + token-budget config.
- **`speckit-graphify-context` skill** — writes a token-bounded `graphify-context.md` (relevant modules,
  per-file blast radius, shared/mutable files, patterns) for the active feature.
- **`speckit-tasks-graph` skill** — stock `tasks.md` + graphify-verified `[P]` markers + a
  machine-readable `## Execution Waves` DAG.
- **`speckit-implement-parallel` skill** — executes the waves as parallel subagents (dev-orchestrator
  model), reviewing each wave before the next.
- **`install.sh` / `uninstall.sh`** — idempotent add-on installer that layers onto a spec-kit repo
  without forking it; YAML registration via a PyYAML-capable interpreter or `uv`, with a manual-paste fallback.
- Docs (`docs/`) and worked examples (`examples/`).
