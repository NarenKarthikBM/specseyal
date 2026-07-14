#!/usr/bin/env python3
"""refresh_merge.py — arm-2 incremental refresh + stale-survivor guard (005, T016).

Invoked only by refresh.sh. Reads, from <scratch-dir>:
  graphify-out/graph.json   — the graph to refresh (mutated in place)
  changed-files.txt         — newline list of changed source_file paths
  fresh-extraction.json     — {"nodes":[...],"links":[...]}: the authoritative fresh
                              node/edge set for the changed file(s) (test seam standing
                              in for a live AST re-extraction; when present it is ground
                              truth — no upstream extractor is called).

Applies the fresh extraction to the graph, runs the stale-survivor guard, prints
`stale_survivors: <N>` on stdout, prunes any survivors, and writes the graph back
(canonical JSON — deterministic).

The merge is per-changed-file and mirrors the real build_merge failure mode the M3
incident exposed:
  - A changed file NOT referenced by any edge from an unchanged file is **clean-replaced**
    — its old nodes/links are dropped, the fresh ones inserted. No survivors (a rename's
    stale node is purged here, as arm2-equiv/T012 requires).
  - A changed file whose node IS referenced cross-file by an unchanged file is
    **conservatively upserted** — old nodes kept (removing one would orphan an edge from a
    file we did not re-extract), fresh upserted on top. This is exactly where build_merge
    left survivors (the M3 86-node incident); the guard below catches and prunes them
    (arm2-survivors/T013).

Mechanical, deterministic, no LLM/network/ANTHROPIC_API_KEY/trace. Imports no graphifyy.
"""

import json
import os
import sys


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def main(argv):
    if len(argv) < 2:
        sys.stderr.write("usage: refresh_merge.py <scratch-dir>\n")
        return 2
    scratch = argv[1]
    graph_path = os.path.join(scratch, "graphify-out", "graph.json")
    changed_path = os.path.join(scratch, "changed-files.txt")
    fresh_path = os.path.join(scratch, "fresh-extraction.json")

    graph = load(graph_path)
    graph.setdefault("nodes", [])
    graph.setdefault("links", [])
    with open(changed_path, encoding="utf-8") as f:
        changed = {line.strip() for line in f if line.strip()}
    fresh = load(fresh_path)
    fresh_nodes = fresh.get("nodes", [])
    fresh_links = fresh.get("links", [])
    fresh_ids = {n["id"] for n in fresh_nodes}

    node_srcfile = {n["id"]: n.get("source_file") for n in graph["nodes"]}

    # Which changed files are referenced by an edge from an *unchanged* file?
    crossref = set()
    for l in graph["links"]:
        if l.get("source_file") in changed:
            continue
        for endpoint in (l.get("source"), l.get("target")):
            sf = node_srcfile.get(endpoint)
            if sf in changed:
                crossref.add(sf)

    clean = changed - crossref

    # Clean-replace: drop old nodes/links attributed to a cleanly-replaceable changed file.
    graph["nodes"] = [n for n in graph["nodes"] if n.get("source_file") not in clean]
    graph["links"] = [l for l in graph["links"] if l.get("source_file") not in clean]

    # Upsert fresh nodes (update existing attributes in place; append new). For clean files
    # these were just dropped, so this re-inserts them; for crossref files it updates old +
    # adds new WITHOUT removing the ones the fresh extraction no longer lists — the survivors.
    by_id = {n["id"]: n for n in graph["nodes"]}
    for fn in fresh_nodes:
        if fn["id"] in by_id:
            by_id[fn["id"]].update(fn)
        else:
            new = dict(fn)
            graph["nodes"].append(new)
            by_id[fn["id"]] = new

    # Upsert fresh links (dedup on relation/source/target).
    link_keys = {(l.get("relation"), l.get("source"), l.get("target")) for l in graph["links"]}
    for fl in fresh_links:
        k = (fl.get("relation"), fl.get("source"), fl.get("target"))
        if k not in link_keys:
            graph["links"].append(dict(fl))
            link_keys.add(k)

    # Stale-survivor guard: a node attributed to a changed file that persists absent from
    # the fresh extraction (the M3 shape). Report, then prune (the recovery, FR-008).
    survivors = {
        n["id"] for n in graph["nodes"]
        if n.get("source_file") in changed and n["id"] not in fresh_ids
    }
    sys.stdout.write("stale_survivors: %d\n" % len(survivors))

    if survivors:
        graph["nodes"] = [n for n in graph["nodes"] if n["id"] not in survivors]
        # Drop links that now dangle onto a pruned survivor node (keep the graph consistent).
        graph["links"] = [
            l for l in graph["links"]
            if l.get("source") not in survivors and l.get("target") not in survivors
        ]

    with open(graph_path, "w", encoding="utf-8") as f:
        json.dump(graph, f, sort_keys=True, separators=(",", ":"))
        f.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
