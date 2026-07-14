#!/usr/bin/env sh
#
# severability/cmd.sh — S12 detached-configuration fixture (T034, 005-graphify-context).
#
# plan.md "Detach order (D74-2)" states the severability picture as a 1-vs-3 asymmetry
# (S15): only arm 1 (.sh/.yml coverage: augment.sh, augment_merge.py, explain-guard.sh)
# has a working fallback and is genuinely detachable; arms 2 (refresh.sh/freshness.sh),
# 3 (provenance.sh + the graphify-context generator), and 4 (council's ceiling-check.sh)
# are core — "never detach", because none has a fallback. S12 then demands this stop being
# rationale-only: "A detached-configuration fixture asserts arms 2 + 3 + 4 pass green with
# arm 1 absent (the fallback story realized as a test)." This is that fixture.
#
# Mechanism under test: refresh.sh (T016) re-invokes augment.sh on the changed scope
# per the S06 cross-arm invariant, but its own "arm 1 detached" branch (see the end of
# extensions/graphify/extension/scripts/refresh.sh) skips that re-invoke gracefully —
# printing a named stderr note, never dying — when augment.sh is absent. This fixture
# manufactures that absence for real (a COPIED scripts dir missing all three arm-1
# files, not a stubbed-out call) and proves the claim end to end:
#
#   Arm 2 — refresh.sh runs against a real refresh scenario from the arm-1-less scripts
#           dir, exits 0, and reports the correct stale_survivors count.
#   Arm 3 — provenance.sh (needs no sibling script at all, so no arm-1 linkage exists to
#           sever) computes a generation-id from that same now-refreshed graph — a small
#           2-then-3 composition, not just two isolated checks side by side.
#   Arm 4 — council's ceiling-check.sh lives in an entirely different extension
#           (extensions/council/) and has never depended on anything under
#           extensions/graphify/ — so it is run straight from the repo, with no scratch
#           assembly step, as the demonstration that there was nothing to detach it from.
#
# All mutable state lives under a mktemp scratch (trap-cleaned on EXIT); scripts are
# COPIED out of $REPO, never moved — this repo's real scripts/ tree is never touched.
# Mechanical only: no model call, no network, no ANTHROPIC_API_KEY, no traces.jsonl
# write. Deterministic: no wall-clock, no unseeded randomness, no dependence on
# filesystem enumeration order; the only moving part (mktemp's path) never reaches
# stdout, so this fixture's expected.txt is byte-stable across machines and runs.
#
# Until this fixture existed, arms 2-4's survival of arm 1's absence was rationale in
# plan.md's prose, never a checked fact — see the note in refresh.sh's own "arm 1
# detached" branch: "This is exactly what the severability fixture (T034) asserts."
#
set -eu

SRC_SCRIPTS="$REPO/extensions/graphify/extension/scripts"
COUNCIL_SCRIPTS="$REPO/extensions/council/extension/scripts"

SCRATCH="$(mktemp -d "${TMPDIR:-/tmp}/severability.XXXXXX")"
trap 'rm -rf "$SCRATCH"' EXIT

# ---------------------------------------------------------------------------------------
# Assemble the arm-1-detached scripts dir. COPY (never move/delete) the arm-2/3 scripts;
# deliberately do NOT copy any of the three arm-1 scripts. freshness.sh is included for
# completeness of a realistic assembled dir (a real "arm 1 detached" deployment would
# still ship it, and it needs only provenance.sh — also present — as a sibling); this
# fixture's own checks below call refresh.sh and provenance.sh directly, per the brief.
# ---------------------------------------------------------------------------------------
mkdir -p "$SCRATCH/scripts"
for f in refresh.sh refresh_merge.py freshness.sh provenance.sh; do
  cp "$SRC_SCRIPTS/$f" "$SCRATCH/scripts/$f"
done
chmod +x "$SCRATCH/scripts/refresh.sh" "$SCRATCH/scripts/freshness.sh" "$SCRATCH/scripts/provenance.sh"

# Defense-in-depth: assert the arm-1 scripts genuinely are absent from the assembled
# dir. A copy-paste regression here (accidentally adding one back) would silently turn
# this into an arm-1-present fixture and defeat the entire point — fail loudly instead.
for f in augment.sh augment_merge.py explain-guard.sh; do
  if [ -e "$SCRATCH/scripts/$f" ]; then
    printf 'severability fixture bug: %s present in the arm-1-detached scripts dir (must be absent)\n' "$f" >&2
    exit 1
  fi
done

# ---------------------------------------------------------------------------------------
# Arm 2 scenario. A base graph models two files: demo/util.sh (a file node + one function
# old_helper()) and an untouched demo/other.sh (a file node + stable_helper(), with no
# edge crossing into demo/util.sh). changed-files.txt names only demo/util.sh; its fresh
# extraction keeps the file node but replaces old_helper() with a new function
# new_helper() — a full node+edge swap, the same clean-replace shape arm2-equiv/T012
# exercises. Because no changed-scope node is cross-referenced from the untouched file,
# refresh_merge.py's clean-replace branch fires and 0 survivors is the correct,
# hand-verifiable answer (verified against a manual dry run before this fixture was
# committed). This fixture is not re-litigating arm 2's merge correctness — arm2-equiv
# and arm2-survivors already own that — only proving the whole thing still runs, end to
# end, with arm 1 physically absent from its own scripts directory.
# ---------------------------------------------------------------------------------------
WORK="$SCRATCH/work"
mkdir -p "$WORK/graphify-out"

cat >"$WORK/graphify-out/graph.json" <<'JSON'
{
  "directed": false,
  "multigraph": false,
  "graph": {"hyperedges": []},
  "nodes": [
    {
      "id": "demo_util_sh",
      "label": "util.sh",
      "file_type": "code",
      "source_file": "demo/util.sh",
      "source_location": "L1",
      "metadata": {"language": "sh", "kind": "file"},
      "_origin": "ast",
      "community": 0,
      "norm_label": "util.sh"
    },
    {
      "id": "demo_fn_old",
      "label": "old_helper",
      "file_type": "code",
      "source_file": "demo/util.sh",
      "source_location": "L3",
      "metadata": {"language": "sh", "kind": "function"},
      "_origin": "ast",
      "community": 0,
      "norm_label": "old_helper"
    },
    {
      "id": "demo_other_sh",
      "label": "other.sh",
      "file_type": "code",
      "source_file": "demo/other.sh",
      "source_location": "L1",
      "metadata": {"language": "sh", "kind": "file"},
      "_origin": "ast",
      "community": 0,
      "norm_label": "other.sh"
    },
    {
      "id": "demo_fn_stable",
      "label": "stable_helper",
      "file_type": "code",
      "source_file": "demo/other.sh",
      "source_location": "L2",
      "metadata": {"language": "sh", "kind": "function"},
      "_origin": "ast",
      "community": 0,
      "norm_label": "stable_helper"
    }
  ],
  "links": [
    {
      "relation": "defines",
      "confidence": "EXTRACTED",
      "source_file": "demo/util.sh",
      "source_location": "L3",
      "weight": 1.0,
      "confidence_score": 1.0,
      "source": "demo_util_sh",
      "target": "demo_fn_old"
    },
    {
      "relation": "defines",
      "confidence": "EXTRACTED",
      "source_file": "demo/other.sh",
      "source_location": "L2",
      "weight": 1.0,
      "confidence_score": 1.0,
      "source": "demo_other_sh",
      "target": "demo_fn_stable"
    }
  ],
  "hyperedges": [],
  "built_at_commit": "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
}
JSON

printf 'demo/util.sh\n' >"$WORK/changed-files.txt"

cat >"$WORK/fresh-extraction.json" <<'JSON'
{
  "nodes": [
    {
      "id": "demo_util_sh",
      "label": "util.sh",
      "file_type": "code",
      "source_file": "demo/util.sh",
      "source_location": "L1",
      "metadata": {"language": "sh", "kind": "file"},
      "_origin": "ast",
      "community": 0,
      "norm_label": "util.sh"
    },
    {
      "id": "demo_fn_new",
      "label": "new_helper",
      "file_type": "code",
      "source_file": "demo/util.sh",
      "source_location": "L3",
      "metadata": {"language": "sh", "kind": "function"},
      "_origin": "ast",
      "community": 0,
      "norm_label": "new_helper"
    }
  ],
  "links": [
    {
      "relation": "defines",
      "confidence": "EXTRACTED",
      "source_file": "demo/util.sh",
      "source_location": "L3",
      "weight": 1.0,
      "confidence_score": 1.0,
      "source": "demo_util_sh",
      "target": "demo_fn_new"
    }
  ]
}
JSON

# ---------------------------------------------------------------------------------------
# check_arm2 — refresh.sh (arm 2) must SUCCEED against the arm-1-detached scripts dir,
# report the correct stale_survivors count, AND — the genuine-absence proof, not merely
# "it happened not to crash" — emit refresh.sh's own documented augment-absent note on
# stderr, confirming this run actually took the "arm 1 detached" branch rather than
# skipping augment.sh for some unrelated reason. Run with cwd ALSO set to $WORK, matching
# the refresh.sh invocation contract arm2-equiv/arm2-survivors already established.
# ---------------------------------------------------------------------------------------
check_arm2() {
  err_log="$SCRATCH/arm2.stderr"
  if out=$(cd "$WORK" && "$SCRATCH/scripts/refresh.sh" "$WORK" 2>"$err_log"); then
    rc=0
  else
    rc=$?
  fi

  if [ "$rc" -ne 0 ]; then
    printf 'arm2 check failed: refresh.sh exited %s -- stderr:\n' "$rc" >&2
    cat "$err_log" >&2
    exit 1
  fi
  if [ "$out" != "stale_survivors: 0" ]; then
    printf "arm2 check failed: expected stdout 'stale_survivors: 0', got:\n" >&2
    printf '%s\n' "$out" >&2
    exit 1
  fi
  if ! grep -Fq 'augment.sh absent (arm 1 detached)' "$err_log"; then
    printf "arm2 check failed: refresh.sh's stderr did not name the augment-absent branch -- this run may not have genuinely exercised arm-1-detached behavior. stderr was:\n" >&2
    cat "$err_log" >&2
    exit 1
  fi
  printf 'arm2_without_arm1: ok\n'
}

# ---------------------------------------------------------------------------------------
# check_arm3 — provenance.sh (arm 3's shared generation-id helper) has no sibling-script
# dependency at all (unlike freshness.sh, which needs provenance.sh as a sibling), so
# there is no arm-1 linkage to sever in the first place. Deliberately run against the
# SAME graph.json arm 2 just refreshed above (built_at_commit passes through
# refresh_merge.py untouched) — a small 2-then-3 composition proving the chain a real
# generator run would make also survives arm 1's absence, not two unrelated checks
# placed side by side. Asserts the emitted id matches sha256:<64 lowercase hex> exactly
# (prefix AND length AND charset), not merely that the substring "sha256:" appears.
# ---------------------------------------------------------------------------------------
check_arm3() {
  err_log="$SCRATCH/arm3.stderr"
  if id=$("$SCRATCH/scripts/provenance.sh" generation-id "$WORK/graphify-out/graph.json" 2>"$err_log"); then
    rc=0
  else
    rc=$?
  fi

  if [ "$rc" -ne 0 ]; then
    printf 'arm3 check failed: provenance.sh exited %s -- stderr:\n' "$rc" >&2
    cat "$err_log" >&2
    exit 1
  fi
  case "$id" in
    sha256:*) hex="${id#sha256:}" ;;
    *)
      printf 'arm3 check failed: expected a sha256:<64-hex> generation-id, got: %s\n' "$id" >&2
      exit 1
      ;;
  esac
  if [ "${#hex}" -ne 64 ]; then
    printf 'arm3 check failed: expected 64 hex digits after sha256:, got %s (%s chars): %s\n' "$hex" "${#hex}" "$id" >&2
    exit 1
  fi
  case "$hex" in
    *[!0-9a-f]*)
      printf 'arm3 check failed: generation-id digest is not lowercase hex: %s\n' "$id" >&2
      exit 1
      ;;
  esac
  printf 'arm3_without_arm1: ok\n'
}

# ---------------------------------------------------------------------------------------
# check_arm4 — council's ceiling-check.sh (arm 4) lives entirely under extensions/council/
# and has never referenced anything under extensions/graphify/ (it reads only its own
# sibling ../council-config.yml) — so it is run straight from the real repo, with no
# scratch assembly step at all, as the demonstration that arm 4 was never coupled to
# arm 1 to begin with. tiers.standard.query_ceiling is 15 (council-config.yml); a count
# of 8 stays under it, so the quiet, no-disclosure "ceiling_hit: false" line (S18: the
# quiet path is checked too, not just assumed quiet) is the correct, hand-verifiable
# answer — this fixture is not re-litigating arm 4's ceiling math (arm4-ceiling/
# arm4-noceiling, T024/T025, already own that), only that it needs nothing from arm 1.
# ---------------------------------------------------------------------------------------
check_arm4() {
  err_log="$SCRATCH/arm4.stderr"
  if out=$("$COUNCIL_SCRIPTS/ceiling-check.sh" standard 8 2>"$err_log"); then
    rc=0
  else
    rc=$?
  fi

  if [ "$rc" -ne 0 ]; then
    printf 'arm4 check failed: ceiling-check.sh exited %s -- stderr:\n' "$rc" >&2
    cat "$err_log" >&2
    exit 1
  fi
  if [ "$out" != "ceiling_hit: false" ]; then
    printf "arm4 check failed: expected 'ceiling_hit: false', got:\n" >&2
    printf '%s\n' "$out" >&2
    exit 1
  fi
  printf 'arm4_without_arm1: ok\n'
}

check_arm2
check_arm3
check_arm4
