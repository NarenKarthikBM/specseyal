#!/usr/bin/env python3
"""augment_merge.py — the arm-1 coverage-pass engine (005-graphify-context, T008).

Invoked only by augment.sh (the thin POSIX-sh wrapper). Two modes:

  augment_merge.py --emit <root>
      Walk <root> for .sh/.yml/.yaml/.md, compute the added nodes + the three
      cross-file edge kinds (registers_hook / installs / invokes) plus the
      labeled-assertion fallback (asserted), and print a canonical, sorted,
      byte-stable NODE/EDGE projection to stdout. No merge. Exit 0.

  augment_merge.py --merge <graph.json> [<root>]
      Compute the same additions for <root> (default: graph.json's parent dir)
      and merge them into <graph.json> in place, then print
      'augmented: +<N> nodes / +<M> edges'. Exit 0.

Mechanical and fully deterministic (same input -> byte-identical output): sorted
iteration, canonical JSON key order, no filesystem-iteration-order dependence
(S11). No LLM, no network, no ANTHROPIC_API_KEY, no traces.jsonl. Imports no
graphifyy code; only reads/writes graph.json (D75 — augment, never fork).

Projection grammar (each section sorted by whole line under C/byte order):
  NODE<TAB><id><TAB><kind>                         kind in {sh,yml,md,command}
  EDGE<TAB><relation><TAB><from><TAB><to><TAB><confidence>
    relation in {registers_hook, installs, invokes, asserted}
    confidence in {EXTRACTED (the three definite kinds), ASSERTED (fallback)}
"""

import os
import re
import sys
import json

EXT_KIND = {".sh": "sh", ".yml": "yml", ".yaml": "yml", ".md": "md"}
KIND_FILETYPE = {"sh": "code", "yml": "code", "md": "document", "command": "concept"}

COMPOUND_OPEN = {"if", "for", "while", "case", "until"}
COMPOUND_CLOSE = {"fi", "done", "esac"}


def norm(relpath):
    """Normalize a POSIX relpath, resolving '.'/'..' without escaping above root."""
    parts = []
    for p in relpath.split("/"):
        if p == "" or p == ".":
            continue
        if p == "..":
            if parts:
                parts.pop()
        else:
            parts.append(p)
    return "/".join(parts)


def dequote(tok):
    tok = tok.strip()
    if len(tok) >= 2 and tok[0] == tok[-1] and tok[0] in ("'", '"'):
        return tok[1:-1]
    return tok


def walk_files(root):
    """Return sorted list of (relpath, kind, fullpath) for tracked artifact types."""
    found = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames.sort()
        for fn in filenames:
            ext = os.path.splitext(fn)[1]
            if ext in EXT_KIND:
                full = os.path.join(dirpath, fn)
                rel = os.path.relpath(full, root).replace(os.sep, "/")
                found.append((rel, EXT_KIND[ext], full))
    found.sort()
    return found


def resolve_target(raw, filedir, selfloc):
    """Resolve a path token to a root-relative path, or None if unresolvable.

    'Self-locating' constructs ($(dirname "$0"), or a var assigned from that
    idiom) resolve to the file's own directory; a plain relative token resolves
    against the file's directory; any surviving $VAR / $(...) is unresolvable.
    """
    t = dequote(raw)
    had_selfloc = False
    fd = filedir if filedir else "."

    dpat = re.compile(r'\$\(\s*dirname\s+"?\$0"?\s*\)|`\s*dirname\s+"?\$0"?\s*`')
    if dpat.search(t):
        t = dpat.sub(fd, t)
        had_selfloc = True

    for v in selfloc:
        vpat = re.compile(r"\$\{" + re.escape(v) + r"\}|\$" + re.escape(v) + r"(?![A-Za-z0-9_])")
        if vpat.search(t):
            t = vpat.sub(fd, t)
            had_selfloc = True

    if "$" in t or "`" in t:
        return None  # a variable we cannot resolve remains

    if had_selfloc:
        return norm(t)
    return norm((filedir + "/" + t) if filedir else t)


def first_token(s):
    """First shell token of a line, respecting a leading quoted span."""
    s = s.lstrip()
    m = re.match(r'"[^"]*"|\'[^\']*\'|\S+', s)
    return m.group(0) if m else ""


def last_operand(s):
    """Last shell token of an operand string, respecting quotes."""
    toks = re.findall(r'"[^"]*"|\'[^\']*\'|\S+', s)
    return toks[-1] if toks else ""


def parse_hook_commands(text):
    """Line-based (no PyYAML — unavailable) extraction of hooks.*.command values."""
    cmds = []
    in_hooks = False
    for line in text.split("\n"):
        if re.match(r"^\S", line):  # a top-level (column-0) key or comment
            in_hooks = line.rstrip().startswith("hooks:")
            continue
        if in_hooks:
            m = re.match(r"^\s+command:\s*(.+?)\s*$", line)
            if m:
                raw = m.group(1).strip()
                # I-26/FR-012/H2.1-2: strip a trailing inline YAML comment before
                # dequote() so it never leaks into the minted command id (e.g.
                # "speckit.git.record-gate  # hook-internal action: ..." must mint
                # "speckit.git.record-gate", not the comment tail too). Only a
                # whitespace-preceded '#' counts as a comment start (mirrors YAML's
                # own rule); a '#' glued directly onto the id with no preceding
                # space/tab is left alone as part of the id. Scoped to THIS caller
                # only, applied before dequote() — dequote() itself is untouched, so
                # its other two callers (resolve_target, parse_shell) — which parse
                # shell content where '#' is legitimate inside paths/strings/args —
                # are unaffected.
                raw = re.sub(r"[ \t]+#.*$", "", raw)
                cmds.append(dequote(raw))
    return cmds


def parse_shell(rel, text):
    """Return (relation, from, to, confidence) edges for one .sh file."""
    filedir = os.path.dirname(rel)
    selfloc = set()
    depth = 0
    edges = []
    for raw_line in text.split("\n"):
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue

        tok0 = first_token(line)

        if tok0 in COMPOUND_OPEN:
            depth += 1
            continue
        if tok0 in COMPOUND_CLOSE:
            depth = max(0, depth - 1)
            continue

        massign = re.match(r"^([A-Za-z_]\w*)=(.*)$", line)
        if massign:
            var, rhs = massign.group(1), massign.group(2)
            if "dirname" in rhs and "$0" in rhs:
                selfloc.add(var)
            continue

        mcp = re.match(r"^cp\s+(.+)$", line)
        if mcp:
            raw_dest = last_operand(mcp.group(1))
            dest = resolve_target(raw_dest, filedir, selfloc)
            to = dest if dest is not None else dequote(raw_dest)
            if depth > 0:
                edges.append(("asserted", rel, to, "ASSERTED"))
            else:
                edges.append(("installs", rel, to, "EXTRACTED"))
            continue

        msrc = re.match(r"^(?:\.|source)\s+(.+?)\s*$", line)
        if msrc:
            tgt = resolve_target(msrc.group(1), filedir, selfloc)
            if tgt is not None:
                edges.append(("invokes", rel, tgt, "EXTRACTED"))
            else:
                edges.append(("asserted", rel, dequote(msrc.group(1)), "ASSERTED"))
            continue

        msh = re.match(r"^sh\s+(\S+)", line)
        if msh and dequote(msh.group(1)).endswith(".sh"):
            tgt = resolve_target(msh.group(1), filedir, selfloc)
            if tgt is not None:
                edges.append(("invokes", rel, tgt, "EXTRACTED"))
            else:
                edges.append(("asserted", rel, dequote(msh.group(1)), "ASSERTED"))
            continue

        mcat = re.match(r"^cat\s+(.+?)\s*$", line)
        if mcat:
            tgt = resolve_target(mcat.group(1), filedir, selfloc)
            lit = dequote(mcat.group(1))
            if (tgt or lit).endswith(".md"):
                edges.append(("asserted", rel, tgt if tgt is not None else lit, "ASSERTED"))
            continue

        d0 = dequote(tok0)
        if "=" not in tok0 and d0.endswith(".sh"):
            tgt = resolve_target(tok0, filedir, selfloc)
            if tgt is not None:
                edges.append(("invokes", rel, tgt, "EXTRACTED"))
            else:
                edges.append(("asserted", rel, d0, "ASSERTED"))
            continue

    return edges


def compute(root):
    """Return (nodes, edges): nodes=set of (id,kind); edges=set of (rel,from,to,conf)."""
    nodes = set()
    edges = set()
    for rel, kind, full in walk_files(root):
        nodes.add((rel, kind))
        try:
            text = open(full, "r", encoding="utf-8", errors="replace").read()
        except OSError:
            continue
        if kind == "sh":
            for e in parse_shell(rel, text):
                edges.add(e)
        elif kind == "yml":
            for cmd in parse_hook_commands(text):
                nodes.add((cmd, "command"))
                edges.add(("registers_hook", rel, cmd, "EXTRACTED"))
    return nodes, edges


def emit(root):
    nodes, edges = compute(root)
    node_lines = sorted("NODE\t%s\t%s" % (nid, kind) for nid, kind in nodes)
    edge_lines = sorted(
        "EDGE\t%s\t%s\t%s\t%s" % (rel, frm, to, conf) for rel, frm, to, conf in edges
    )
    lines = node_lines + edge_lines
    sys.stdout.write("\n".join(lines))
    if lines:
        sys.stdout.write("\n")
    return 0


def merge(graph_path, root):
    with open(graph_path, "r", encoding="utf-8") as f:
        graph = json.load(f)
    graph.setdefault("nodes", [])
    graph.setdefault("links", [])
    existing_ids = {n.get("id") for n in graph["nodes"]}
    existing_edges = {
        (l.get("relation"), l.get("source"), l.get("target")) for l in graph["links"]
    }
    nodes, edges = compute(root)
    added_n = 0
    for nid, kind in sorted(nodes):
        if nid in existing_ids:
            continue
        graph["nodes"].append({
            "id": nid,
            "label": os.path.basename(nid) if "/" in nid else nid,
            "file_type": KIND_FILETYPE.get(kind, "code"),
            "source_file": nid if kind in ("sh", "yml", "md") else None,
            "metadata": {"kind": "file" if kind in ("sh", "yml", "md") else kind},
            "_origin": "augment",
        })
        existing_ids.add(nid)
        added_n += 1
    added_e = 0
    for rel, frm, to, conf in sorted(edges):
        key = (rel, frm, to)
        if key in existing_edges:
            continue
        graph["links"].append({
            "relation": rel,
            "confidence": conf,
            "source": frm,
            "target": to,
            "source_file": frm,
            "_origin": "augment",
        })
        existing_edges.add(key)
        added_e += 1
    with open(graph_path, "w", encoding="utf-8") as f:
        json.dump(graph, f, sort_keys=True, separators=(",", ":"))
        f.write("\n")
    sys.stdout.write("augmented: +%d nodes / +%d edges\n" % (added_n, added_e))
    return 0


def main(argv):
    if len(argv) >= 3 and argv[1] == "--emit":
        return emit(argv[2])
    if len(argv) >= 3 and argv[1] == "--merge":
        graph_path = argv[2]
        root = argv[3] if len(argv) >= 4 else os.path.dirname(os.path.abspath(graph_path))
        return merge(graph_path, root)
    sys.stderr.write(
        "usage: augment_merge.py --emit <root>\n"
        "       augment_merge.py --merge <graph.json> [<root>]\n"
    )
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
