#!/usr/bin/env python3
"""canonicalize_scope.py -- test-only helper for the arm2-equiv fixture (T012).

Filters a graph (or a bare pre-build "extraction" fragment -- data-model.md's own
language distinguishes "the extraction (pre-build)" from the assembled "graph.json";
both shapes are accepted here since both are just {"nodes": [...], "links": [...]}
plus optional extra top-level keys this script ignores) down to the nodes/links
attributed to a bounded changed-file scope, then serializes that slice as canonical
JSON -- sorted object keys, a stable node/link ordering that does not depend on
input array position, compact separators -- so cmd.sh can byte-diff two
independently-produced graphs without tripping over dict-key or list-iteration order.

Deliberately excludes top-level graph-global fields (built_at_commit, directed,
multigraph, hyperedges): SC-004 equivalence is a claim about the changed SCOPE's own
nodes/links, not about graph-wide bookkeeping that legitimately differs between a
full regen run at one moment and an incremental refresh run at another.

This script is fixture-only test tooling. It says nothing about how refresh.sh
(T016) itself is implemented, or what language it is written in.

Usage: canonicalize_scope.py <graph-or-extraction.json> <changed-files.txt>
"""
import json
import sys


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: canonicalize_scope.py <graph.json> <changed-files.txt>", file=sys.stderr)
        return 2

    graph_path, scope_path = sys.argv[1], sys.argv[2]

    with open(graph_path, encoding="utf-8") as f:
        graph = json.load(f)
    with open(scope_path, encoding="utf-8") as f:
        scope = {line.strip() for line in f if line.strip()}

    nodes = [n for n in graph.get("nodes", []) if n.get("source_file") in scope]
    links = [l for l in graph.get("links", []) if l.get("source_file") in scope]

    # Stable ordering independent of how the input array happened to list them.
    nodes.sort(key=lambda n: n["id"])
    links.sort(key=lambda l: (l["source"], l["target"], l["relation"], l.get("source_location", "")))

    canonical = {"nodes": nodes, "links": links}
    print(json.dumps(canonical, sort_keys=True, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    sys.exit(main())
