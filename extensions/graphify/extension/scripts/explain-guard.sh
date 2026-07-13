#!/bin/sh
# explain-guard.sh — ambiguous-match guard for `graphify explain` (S04)
#
# `graphify explain <label>` (upstream graphifyy CLI, D75: consumed, never
# modified/forked) resolves <label> to its single top-scoring graph node
# with NO signal on a near-tie, while `graphify path` already warns on the
# identical near-tie condition when resolving its own source/target. This
# wrapper closes that silent footgun: it forwards straight through to
# `graphify explain`, and — before doing so — reuses graphify's own
# node-scoring engine as a read-only sidecar check so a near-tie is no
# longer silent. Mechanical only: no model call, no network, no
# ANTHROPIC_API_KEY, no traces.jsonl write.
#
# Usage:
#   explain-guard.sh "<label>" [--graph path] [explain-args...]
#
#   <label>            the node label/short-name to explain — forwarded to
#                       `graphify explain` verbatim.
#   [explain-args...]  any further arguments `graphify explain` itself
#                       accepts (today: `--graph path`) — forwarded
#                       byte-for-byte and never validated or reinterpreted
#                       here, so a future `explain` flag this script
#                       doesn't know about still passes straight through.
#
# Seam (D75) — mechanism explored, and one candidate rejected:
#   A "self-path" (`graphify path "<label>" "<label>"`) was the first
#   candidate investigated. It does NOT work: `path` short-circuits with
#   "'<label>' and '<label>' both resolved to the same node ..." (exit 1)
#   the instant source and target resolve identically — which a self-path
#   always does, deterministically — *before* it ever reaches its own
#   ambiguity-warning check. Confirmed live: `graphify path X X` never
#   prints a "match was ambiguous" warning, for any X. No `graphify`
#   subcommand prints ranked candidate scores as parseable text either
#   (`query` emits BFS prose, not scores). What's left, and what this
#   script uses, is the exact mechanism `path` itself already uses: a
#   read-only, in-process import of `graphify.serve._score_nodes` — the
#   SAME private function graphify's own installed `path` subcommand
#   imports for its identical check — run under the SAME python
#   interpreter the installed `graphify` executable itself runs under
#   (sniffed from its own shebang, never hardcoded: a uv-tool install, a
#   pipx install, and a plain pip/venv install all place it somewhere
#   different), with a plain system python3/python fallback. This never
#   edits, patches, or forks graphifyy — it is a read-only library call
#   into the exact package `graphify explain` is about to invoke anyway.
#   If the interpreter can't be resolved, or the import/graph load fails
#   for any reason (older graphify without `_score_nodes`, a missing,
#   oversized, or corrupt graph.json, ...), the check is silently
#   skipped — never a hard failure, and never a reason to withhold or
#   alter `explain`'s own output below.
#
# Near-tie criterion — byte-identical to graphify path's own
# (__main__.py's `path` handler / graphify.serve._tool_shortest_path):
# score <label> against the graph with `_score_nodes`; with >=2 scored
# candidates, it is a near-tie iff top score > 0 and
# (top - runner-up) / top < 0.10 — the same 10% gap-ratio `path` already
# applies (it fires on both an exact tie and a ~0.7% gap, per the S04
# write-up this task closes) — never a bespoke threshold invented here.
#
# Out: stdout is exactly `graphify explain`'s own stdout, byte for byte —
# this wrapper never writes to stdout itself. stderr gains at most one
# additional line, printed BEFORE explain's own output (matching where
# `path` places its own warnings):
#   warning: <label> match was ambiguous (top score <X>, runner-up <Y>)
# emitted only on a near-tie; explain's own stderr is otherwise unchanged.
# Exit: exactly `graphify explain`'s own exit code, always — the ambiguity
# check never introduces a new failure mode of its own; "can't check"
# degrades to "no warning", never to an error.

set -eu

die() {
    printf 'explain-guard.sh: error: %s\n' "$1" >&2
    exit 1
}

usage() {
    printf 'usage: explain-guard.sh "<label>" [--graph path] [explain-args...]\n' >&2
}

case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
esac

[ "$#" -ge 1 ] || { usage; exit 1; }

label=$1
shift
# "$@" is now exactly graphify explain's own [explain-args...] (possibly
# empty) — read-only rescanned below for --graph, then forwarded to
# graphify explain unexamined and unmodified at the very end.

command -v graphify >/dev/null 2>&1 || die "graphify: command not found on PATH (pip install graphifyy)"

# ---------------------------------------------------------------------------
# Resolve the graph file exactly as graphify explain itself resolves it:
# the GRAPHIFY_OUT env var (graphify's own override, __main__.py's
# _GRAPHIFY_OUT) if set, else the literal default "graphify-out", then
# "/graph.json" — overridden by the LAST "--graph <path>" pair in
# [explain-args...], matching explain's own last-one-wins scan
# (`for i, a in enumerate(args): if a == "--graph" ...` has no break, so a
# repeated flag's final occurrence wins). No "--graph=value" form: explain
# itself doesn't support one, so neither does this rescan.
# ---------------------------------------------------------------------------

graph_path="${GRAPHIFY_OUT:-graphify-out}/graph.json"
prev=""
for arg in "$@"; do
    if [ "$prev" = "--graph" ]; then
        graph_path="$arg"
    fi
    prev="$arg"
done

# ---------------------------------------------------------------------------
# Resolve the python interpreter graphify itself runs under (never
# hardcoded — see "Seam" above). Sniffed from the installed `graphify`
# script's own shebang line so the sidecar check below imports the SAME
# graphify.serve the real `graphify explain` call is about to use.
#
# Deliberately NOT a `case '#!'*)` match, and deliberately NOT nested
# inside a $(...) command substitution: bash 3.2 (still `/bin/sh` on
# Darwin, frozen pre-GPLv3) mis-parses a `case` arm whose body is itself a
# compound command (an `if...fi`) once that whole `case` is nested inside
# $(...) — confirmed live on this platform, independent of the pattern
# text (a bare `*)`/`env)` dispatch nested the same way reproduces it too,
# not just a leading `#`/`!`). Every step below is therefore a plain
# top-level statement (never nested in a substitution) and prefix
# extraction uses parameter expansion, not `case`, so this script's own
# "$@" (still needed, untouched, for the final passthrough call below) is
# never at risk either way.
# ---------------------------------------------------------------------------

graphify_bin=$(command -v graphify)
py_interp=""

shebang_line=""
if head_out=$(head -n 1 "$graphify_bin" 2>/dev/null); then
    shebang_line=$head_out
fi

case "$shebang_line" in
    '#!'*)
        rest=${shebang_line#'#!'}
        # First whitespace-delimited field, via pure parameter expansion
        # (longest-suffix-from-first-whitespace removal) — no `set --`,
        # so this can't touch "$@" even in principle.
        first_tok=${rest%%[[:space:]]*}
        first_base=$(basename -- "$first_tok" 2>/dev/null) || first_base=""
        # A plain "#!/abs/path/to/python" is what pip/uv/pipx console
        # scripts always generate; an "env"-indirected shebang is left
        # unresolved here (falls through to the plain python3/python
        # fallback below) rather than adding a second-token extraction
        # path for a shape this install never actually produces.
        if [ "$first_base" != "env" ] && [ -n "$first_tok" ] && [ -x "$first_tok" ]; then
            py_interp=$first_tok
        fi
        ;;
esac

if [ -z "$py_interp" ]; then
    # Shebang-sniffing found nothing usable: best-effort fallback to a
    # plain system interpreter. If graphify.serve isn't importable there
    # either, the sidecar's own try/except below just finds nothing to
    # check — same graceful degradation as every other failure mode here.
    py_interp=$(command -v python3 2>/dev/null || command -v python 2>/dev/null || true)
fi

# ---------------------------------------------------------------------------
# The sidecar ambiguity check itself — read-only, in-process reuse of
# graphify's own scorer (see "Seam" above). Tolerated failure: the python
# body already catches every internal failure mode itself and exits 0, but
# "|| true" is kept here too as an outer guard against the interpreter
# process itself misbehaving (crash, disappearing between the checks above
# and here, etc.) — either way this can never abort this script or change
# what runs next (shell-scripting skill: a tolerated step is guarded
# explicitly at that line, not by dropping set -eu).
# ---------------------------------------------------------------------------

if [ -n "$py_interp" ] && [ -x "$py_interp" ]; then
    EXPLAIN_GUARD_LABEL="$label" EXPLAIN_GUARD_GRAPH="$graph_path" "$py_interp" - >/dev/null <<'PYEOF' || true
import os
import sys


def _skip():
    # Nothing trustworthy to check (missing dep, missing/oversized/corrupt
    # graph.json, older graphify without _score_nodes, ...) — degrade to
    # "no warning", never a traceback, never a nonzero exit; see
    # explain-guard.sh's own header ("Seam").
    sys.exit(0)


label = os.environ.get("EXPLAIN_GUARD_LABEL", "")
graph_path = os.environ.get("EXPLAIN_GUARD_GRAPH", "")
if not label or not graph_path:
    _skip()

try:
    from pathlib import Path
    from networkx.readwrite import json_graph
    from graphify.serve import _score_nodes
except Exception:
    _skip()

gp = Path(graph_path)
if not gp.exists():
    # graphify explain will itself report "graph file not found" momentarily.
    _skip()

try:
    from graphify.security import check_graph_file_size_cap
    check_graph_file_size_cap(gp)
except ImportError:
    pass  # older graphify without this guard: proceed without it.
except Exception:
    _skip()  # oversized/unreadable per the cap: nothing safe to score.

try:
    import json

    raw = json.loads(gp.read_text(encoding="utf-8"))
    if "links" not in raw and "edges" in raw:
        raw = dict(raw, links=raw["edges"])
    # Force directed, matching explain's own loader exactly.
    raw = {**raw, "directed": True}
    try:
        graph = json_graph.node_link_graph(raw, edges="links")
    except TypeError:
        graph = json_graph.node_link_graph(raw)
    scored = _score_nodes(graph, [t.lower() for t in label.split()])
except Exception:
    _skip()

if len(scored) >= 2:
    top, runner = scored[0][0], scored[1][0]
    if top > 0 and (top - runner) / top < 0.10:
        sys.stderr.write(
            f"warning: {label} match was ambiguous "
            f"(top score {top:g}, runner-up {runner:g})\n"
        )
PYEOF
fi

exec graphify explain "$label" "$@"
