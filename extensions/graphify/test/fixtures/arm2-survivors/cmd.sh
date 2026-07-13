#!/usr/bin/env sh
#
# arm2-survivors/cmd.sh — S01 negative-path fixture (T013, 005-graphify-context) for arm
# 2's stale-survivor guard (plan.md "Arm 2", case (d); contracts/commands.md `refresh.sh`).
# Sibling to arm2-freshness (T011, cases a/b) and arm2-equiv (T012, case c — the
# 0-survivor positive path this fixture's inverse pairs with).
#
# The scenario (input/): a base graph.json models two files — demo/changed.sh (a file
# node + functions alpha/beta/gamma/delta) and an untouched demo/stable.sh (a file node +
# watcher(), which calls gamma() across files). fresh-extraction.json is the ground-truth
# fresh extraction of demo/changed.sh after an edit that keeps alpha, drops beta/gamma/
# delta, and adds a new epsilon — so beta/gamma/delta are MANUFACTURED STALE SURVIVORS:
# nodes attributed to a changed file that persist absent from its fresh extraction (the M3
# 86-node incident, S01, in miniature). changed-files.txt names the one changed file.
#
# Asserts BOTH branches of the guard: (1) detection — refresh.sh's own contracted
# `stale_survivors: <N>` line (contracts/commands.md); (2) recovery — an INDEPENDENT
# follow-up read of the post-refresh graphify-out/graph.json (never just refresh.sh's own
# self-report) confirming none of the 3 manufactured ids remain, AND that demo/stable.sh's
# untouched nodes are still there (S02: recovery is a targeted, scoped re-extract, never a
# whole-corpus sweep, for a bounded change).
#
# Test-seam contract this fixture requires of refresh.sh (T016, a later wave, must satisfy
# — this fixture DEFINES it, since refresh.sh does not exist yet):
#   Invocation:  refresh.sh <scratch-dir>   — run with cwd ALSO set to <scratch-dir>, so
#     either a cwd-relative or an argv-based implementation is satisfied.
#   Reads   <scratch-dir>/graphify-out/graph.json   — the graph to verify + heal (D45 path
#     convention); MUTATED IN PLACE on survivors>0 (prune-or-rebuild, FR-008).
#   Reads   <scratch-dir>/changed-files.txt         — newline list of changed file paths,
#     matching the graph nodes' "source_file" values (stands in for detect_incremental's
#     changed-file output).
#   Reads   <scratch-dir>/fresh-extraction.json     — {"nodes":[...],"links":[...]}: the
#     AUTHORITATIVE, already-computed fresh node/edge set for the file(s) named above. This
#     is a deliberate test seam — it stands in for a live AST re-extraction so this fixture
#     stays hermetic and decoupled from upstream graphifyy's exact parse output (that
#     fidelity is arm-1/upstream's own concern, not this guard's); when present, refresh.sh
#     MUST treat it as ground truth rather than invoking a real extractor.
#   Prints  "stale_survivors: <N>" to stdout (contracts/commands.md); other lines around it
#     (e.g. from re-invoking augment.sh per the S06 composition invariant) are tolerated —
#     this fixture greps for that one line rather than diffing the whole stream.
#
# Until refresh.sh exists, invoking it fails naturally (no such file / not executable) and
# this fixture is red FOR THAT REASON — the intended TDD red, not a malformed fixture.
#
set -eu

FIXTURE_DIR="$(cd "$(dirname "$0")" && pwd)"
REFRESH="$REPO/extensions/graphify/extension/scripts/refresh.sh"

SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

mkdir -p "$SCRATCH/graphify-out"
cp "$FIXTURE_DIR/input/graph.json"            "$SCRATCH/graphify-out/graph.json"
cp "$FIXTURE_DIR/input/changed-files.txt"     "$SCRATCH/changed-files.txt"
cp "$FIXTURE_DIR/input/fresh-extraction.json" "$SCRATCH/fresh-extraction.json"

out="$(cd "$SCRATCH" && "$REFRESH" "$SCRATCH" 2>"$SCRATCH/.refresh.stderr")" && rc=0 || rc=$?
if [ "$rc" -ne 0 ]; then
  echo "refresh.sh exited $rc — stderr:" >&2
  cat "$SCRATCH/.refresh.stderr" >&2
  exit 1
fi

survivors_line="$(printf '%s\n' "$out" | grep '^stale_survivors: ' | head -n1)"
if [ -z "$survivors_line" ]; then
  echo "refresh.sh printed no 'stale_survivors: <N>' line. Full stdout was:" >&2
  printf '%s\n' "$out" >&2
  exit 1
fi

# Independent follow-up (never just re-trust refresh.sh's own report): read the
# POST-refresh graph.json off disk and confirm (a) none of the 3 manufactured survivor
# ids (beta/gamma/delta, attributed to demo/changed.sh, absent from fresh-extraction.json)
# remain, and (b) demo/stable.sh's untouched nodes are still present (the S02 scoped-
# recovery guarantee — never a whole-corpus sweep for a bounded change).
check="$(python3 - "$SCRATCH/graphify-out/graph.json" <<'PY'
import json, sys

with open(sys.argv[1]) as f:
    g = json.load(f)

present = {n.get("id") for n in g.get("nodes", [])}
manufactured_survivors = {"fx_fn_beta", "fx_fn_gamma", "fx_fn_delta"}
untouched = {"fx_stable_file", "fx_stable_fn"}

leftover = manufactured_survivors & present
lost = untouched - present

if leftover:
    print("stale-remain:" + ",".join(sorted(leftover)))
elif lost:
    print("precision-violation:" + ",".join(sorted(lost)))
else:
    print(0)
PY
)"

printf '%s\n' "$survivors_line"
printf 'survivors_after_recovery: %s\n' "$check"
