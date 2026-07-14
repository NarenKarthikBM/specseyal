#!/bin/sh
#
# arm2-compose/cmd.sh — S06 cross-arm composition fixture (T014, 005-graphify-context).
# Sibling to arm2-equiv (T012) / arm2-survivors (T013); reuses their refresh.sh test-seam
# contract verbatim so T016 has ONE interface to satisfy, and extends it with the S06
# assertion those two do not make.
#
# The scenario (input/): a base graph.json with install.sh + util.sh AST nodes;
# changed-files.txt names install.sh; fresh-extraction.json is install.sh's fresh AST
# (unchanged -> 0 survivors); install.sh is the ACTUAL file — its `cp` is an arm-1 augment
# `installs` edge the AST layer cannot see. The composition invariant (S06): an incremental
# refresh MUST re-invoke arm-1's augment.sh on the changed scope, or every refresh silently
# regresses arm-1 coverage on exactly the changed files. A per-arm fixture cannot catch this.
#
# refresh.sh test-seam contract (T016, a later wave, must satisfy — matches T012/T013):
#   refresh.sh <scratch-dir>  (cwd also <scratch-dir>); reads <scratch>/graphify-out/graph.json
#   (mutated in place), changed-files.txt, fresh-extraction.json (ground-truth AST, treated as
#   authoritative — no live extractor). Prints "stale_survivors: <N>". PER S06 it also
#   re-invokes augment.sh on the changed scope, so the refreshed graph carries the augment
#   edge for install.sh. Other stdout lines are tolerated (we grep, not diff-the-stream).
#
# Until refresh.sh exists this fails naturally (no such file) — the intended TDD red.
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
cp "$FIXTURE_DIR/input/install.sh"            "$SCRATCH/install.sh"

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

# Independent read of the POST-refresh graph: is arm-1's augment `installs` edge for
# install.sh present? (source_file, not node id, so it is robust to augment's id scheme.)
present="$(python3 - "$SCRATCH/graphify-out/graph.json" <<'PY'
import json, sys
g = json.load(open(sys.argv[1]))
aug = [l for l in g.get("links", [])
       if l.get("relation") == "installs" and l.get("source_file") == "install.sh"]
print("yes" if aug else "no")
PY
)"

printf '%s\n' "$survivors_line"
printf 'augment_edge_present: %s\n' "$present"
