# Graphify Context — arm3-coherence-fixture

_Generated 2026-07-14T12:00:00Z from `graphify-out/graph.json` (3 nodes, 2 edges, scope: repo). Stale after large merges — regenerate with `/speckit-graphify-context`._

<!-- graphify-provenance:v1
graph-path: graphify-out/graph.json
graph-scope: repo
node-count: 3
edge-count: 2
generated-at: 2026-07-14T12:00:00Z
generation-id: sha256:44a90c48cdb9ce84d527d4655720c762932232f8d62deca7541a5cf1c5957a9e
source-fingerprint: git-commit:7a23d80aad4ff9c83905932854e44bf6868729ec
-->

## Graph scope
- Repo graph: `graphify-out/graph.json`
- This run used: **repo**

## Relevant existing modules
- `src/alpha/widget.py` — defines `make_widget()`, depends on `src/beta/gadget.py`

## Blast radius (per anchor)
- **widget.py** (`src/alpha/widget.py`)
  - depends on: `src/beta/gadget.py`
  - depended on by: (none found)

## Shared / mutable files (collision watch)
- none found

## Patterns to follow
- follow the existing module-per-file convention in `src/alpha/widget.py`
