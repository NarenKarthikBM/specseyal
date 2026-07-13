# Graphify Context — 900-widget

_Generated 2026-01-01T00:00:00Z from `graphify-out/graph.json` (7 nodes, 5 edges, scope: repo). Stale after large merges — regenerate with `/speckit-graphify-context`._

<!-- graphify-provenance:v1
graph-path: graphify-out/graph.json
graph-scope: repo
node-count: 7
edge-count: 5
generated-at: 2026-01-01T00:00:00Z
generation-id: sha256:40f136910c6c60587cf31a50eb7f2c157b53e0868140184201623f056545986f
source-fingerprint: git-commit:fab1a5edfab1a5edfab1a5edfab1a5edfab1a5ed
-->

## Graph scope
- Repo graph: `graphify-out/graph.json`
- Merged stack graph: (not used this run)
- This run used: **repo**

## Relevant existing modules
- `src/widget/service.py` — widget catalog service; calls into the model, called by routes and tests
- `src/widget/model.py` — widget data model
- `src/widget/routes.py` — HTTP routes for widgets (shared/mutable — see below)

## Blast radius (per anchor)
- **widget_service.py** (`src/widget/service.py`)
  - depends on: `src/widget/model.py`
  - depended on by: `src/widget/routes.py`, `tests/test_widget.py`
  - follow the pattern in: `src/widget/model.py`

## Shared / mutable files (collision watch)
> Tasks that touch any of these must be serialized — never put two of them in the same parallel wave.
- `src/widget/routes.py` — route registrations multiple tasks would append to

## Patterns to follow
- Soft-delete over hard-delete for domain entities (`docs/90-DECISIONS-AND-IDEAS.md` D1), exemplified in `src/widget/model.py`
