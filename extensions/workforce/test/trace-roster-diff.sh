#!/bin/sh
# trace-roster-diff.sh — SC-008 / FR-021 / S23 loop-closure check (zero-AI).
#
# Mechanically verifies that every `implementer` dispatch trace carries ONLY the
# assembly a human approved on the workforce roster: for each record with
# role=implementer, its (agent_id, skills{id@ver}, elevated_grants) must equal
# one of the `### Roster approved` rows' assemblies. Catches the D41/D43 failure
# that matters most — a dispatch reaching the network (or injecting a skill) the
# gate never approved (a grant/skill leak). Also enforces trace-schema §1 rule 5
# (|skills| ≤ 3) and rule 6 (no grant is a core-toolset name).
#
# Mapping note: the trace-schema §1 `implementer` record carries no task-id field,
# so a trace cannot be pinned to one specific roster ROW. The check is therefore
# assembly-MEMBERSHIP — every dispatched assembly is one the roster approved — which
# is exactly the grant-integrity property SC-008 exists to guarantee. (A per-row
# check would need a task id the schema doesn't carry; noted for a schema v1.)
#
# Usage:
#   trace-roster-diff.sh <traces.jsonl> <assignment.md>   # exit 0 iff every implementer assembly is approved
#   trace-roster-diff.sh --self-test                       # runs the frozen PASS + FAIL fixtures
#
# No `jq` dependency — JSONL parsed with python3 stdlib (already a repo dep via graphify).

set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

check() {
    traces="$1"; roster="$2"
    python3 - "$traces" "$roster" <<'PY'
import json, re, sys

traces_path, roster_path = sys.argv[1], sys.argv[2]
CORE = {"read", "write", "edit", "bash", "glob", "grep"}

def norm_skills(tokens):
    # tokens: iterable of "skl_x@1.2.0" strings
    return frozenset(t.strip() for t in tokens)

# --- parse the roster's "### Roster approved" table -------------------------
approved = set()          # {(base, frozenset(skills), frozenset(grants))}
rows = 0
in_roster = False
with open(roster_path, encoding="utf-8") as fh:
    for line in fh:
        s = line.strip()
        if s.startswith("### Roster approved"):
            in_roster = True; continue
        if in_roster and s.startswith("## "):   # next section ends the roster
            break
        if not in_roster or not s.startswith("|"):
            continue
        cells = [c.strip() for c in s.strip("|").split("|")]
        if len(cells) < 5:
            continue
        if cells[0] in ("Task(s)", "") or set(cells[1]) <= set("-: "):  # header / separator
            continue
        _tasks, base_cell, _model, skills_cell, grants_cell = cells[:5]
        m = re.search(r"agt_[a-z0-9_]+", base_cell)
        if not m:
            continue
        base = m.group(0)
        skills = norm_skills(re.findall(r"skl_[a-z0-9_]+@\d+\.\d+\.\d+", skills_cell))
        gclean = grants_cell.replace("`", "").replace("*", "").strip().lower()
        grants = frozenset() if gclean in ("none", "") else frozenset(
            g.strip() for g in re.split(r"[,\s]+", grants_cell.replace("`", "")) if g.strip() and g.strip().lower() != "none")
        approved.add((base, skills, grants))
        rows += 1

if rows == 0:
    print("  FAIL  no '### Roster approved' rows parsed from %s" % roster_path); sys.exit(1)

# --- check each implementer trace -------------------------------------------
fails = 0; checked = 0
with open(traces_path, encoding="utf-8") as fh:
    for ln, raw in enumerate(fh, 1):
        raw = raw.strip()
        if not raw:
            continue
        try:
            r = json.loads(raw)
        except Exception as e:
            print("  FAIL  line %d: unparseable JSON (%s)" % (ln, e)); fails += 1; continue
        if r.get("role") != "implementer":
            continue                       # only implementer dispatches carry an assembly
        checked += 1
        base = r.get("agent_id")
        skills = norm_skills("%s@%s" % (x["id"], x["version"]) for x in r.get("skills", []))
        grants = frozenset(r.get("elevated_grants", []))
        tid = r.get("trace_id", "?")
        # rule 5 / rule 6 (trace-schema §1)
        if len(skills) > 3:
            print("  FAIL  %s: |skills|=%d > 3 (rule 5)" % (tid, len(skills))); fails += 1; continue
        leak = {g for g in grants if g.lower() in CORE}
        if leak:
            print("  FAIL  %s: grant(s) %s are core-toolset (rule 6)" % (tid, sorted(leak))); fails += 1; continue
        if (base, skills, grants) not in approved:
            print("  FAIL  %s: assembly (base=%s skills=%s grants=%s) is NOT an approved roster row — unapproved grant/skill leak (SC-008)"
                  % (tid, base, sorted(skills), sorted(grants))); fails += 1; continue
        print("  ok    %s: %s + %s + grants %s matches an approved row" % (tid, base, sorted(skills), sorted(grants)))

if checked == 0:
    print("  FAIL  no implementer records found in %s" % traces_path); sys.exit(1)
if fails:
    print("  -> %d/%d implementer traces UNAPPROVED" % (fails, checked)); sys.exit(1)
print("  -> all %d implementer traces match an approved roster assembly" % checked); sys.exit(0)
PY
}

case "${1:-}" in
    --self-test|"")
        fx="$here/fixtures/trace-roster"
        rc=0
        printf 'trace-roster-diff self-test\n'
        printf '  [PASS fixture — expect all approved]\n'
        if check "$fx/traces.pass.jsonl" "$fx/assignment.fixture.md"; then
            printf '  PASS: clean traces accepted\n'
        else
            printf '  FAIL: clean traces were rejected\n'; rc=1
        fi
        printf '  [FAIL fixture — expect the leak/mismatch to be caught]\n'
        if check "$fx/traces.fail.jsonl" "$fx/assignment.fixture.md" >/dev/null 2>&1; then
            printf '  FAIL: negative control was NOT caught (script does not discriminate)\n'; rc=1
        else
            printf '  PASS: negative control (grant leak + version mismatch) correctly caught\n'
        fi
        exit "$rc"
        ;;
    -h|--help)
        printf 'usage: trace-roster-diff.sh <traces.jsonl> <assignment.md>\n       trace-roster-diff.sh --self-test\n'; exit 0 ;;
    *)
        [ "$#" -eq 2 ] || { printf 'usage: trace-roster-diff.sh <traces.jsonl> <assignment.md>\n' >&2; exit 2; }
        check "$1" "$2" ;;
esac
