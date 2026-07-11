#!/bin/sh
# gates.sh — read/write the git-ext-owned GateSHABinding record at
# specs/<spec-id>/gates.yml.
#
# This is the sole owner of gates.yml (data-model.md #GateSHABinding,
# owner ruling R1-S09/S20): no other command reads or writes this file.
# gates.yml is a BINDINGS RECORD, not phase state (D32) — the only phase
# state this extension ever touches is the git ref itself (branch.sh) —
# so this script never inspects or edits an artifact's own gate section
# (`## Human Gate` / `## Workforce Gate`), which carries only a one-line
# reference to this file (contracts/commands.md, "Gate-command
# integration points").
#
# Bindings recorded (contracts/commands.md):
#   council   -> plan.md @ <sha>
#   workforce -> tasks.md @ <sha>, agents/assignment.md @ <sha>
#
# <sha> is never computed here — every SHA comes from the sibling
# `speckit.git.sha` primitive (./sha.sh), composed as a subprocess, so
# this script can't drift from that primitive's definition of "the SHA
# of the HEAD commit that last touched <artifact-path>".
#
# gates.yml shape (version 1):
#   version: 1
#   council:
#     plan.md: <sha>
#   workforce:
#     tasks.md: <sha>
#     agents/assignment.md: <sha>
#
# The `version` field exists so a consumer (verify-gate.sh, a later
# task) can fail closed on a format it can't parse rather than fail
# open (R1-S10): this script itself refuses to read OR write a
# gates.yml whose version isn't the one it understands, rather than
# guess at a foreign shape.
#
# Freshness (data-model.md #GateSHABinding, FR-009) is NOT decided
# here: this script only records and reports bindings. Comparing a
# recorded <sha> to the artifact's current SHA, and to working-tree
# cleanliness, is verify-gate.sh's job (R1-S05/R1-S10).
#
# Usage:
#   gates.sh write <council|workforce> [artifact...]
#       Record a binding for <gate>: for each artifact (default —
#       council: plan.md; workforce: tasks.md agents/assignment.md — override
#       by passing an explicit list), resolve specs/<spec-id>/<artifact>
#       via sha.sh and (re)write that gate's block in gates.yml,
#       replacing it wholesale (idempotent — re-recording a gate
#       replaces its block, never appends a duplicate). The other
#       gate's block, if any, is preserved verbatim.
#   gates.sh read <council|workforce>
#       Print that gate's recorded bindings, one per line, as
#       "<artifact> @ <sha>" — the exact form verify-gate.sh consumes.
#
# Spec ID resolution (D45 — .specify/feature.json is the sole spec-ID
# resolver, same as branch.sh/cleanup.sh): basename of feature.json's
# "feature_directory".
#
# Mechanical only: no model call, no traces.jsonl write (FR-007). Not
# concurrency-guarded (unlike branch.sh's flock/mkdir-mutex) — two
# gates are never approved in the same instant in v1, so this is a
# known, accepted non-goal rather than an oversight.

set -eu

die() {
    printf 'gates.sh: error: %s\n' "$1" >&2
    exit 1
}

usage() {
    printf 'usage: gates.sh write <council|workforce> [artifact...]\n' >&2
    printf '       gates.sh read  <council|workforce>\n' >&2
}

case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
esac

if [ "$#" -lt 2 ]; then
    usage
    exit 1
fi

subcommand="$1"
gate="$2"
shift 2

case "$gate" in
    council|workforce) : ;;
    *) die "unknown gate '$gate' (expected 'council' or 'workforce')" ;;
esac

case "$subcommand" in
    write|read) : ;;
    *) usage; die "unknown subcommand '$subcommand' (expected 'write' or 'read')" ;;
esac

# ---------------------------------------------------------------------------
# gates.yml format version this script understands. Both read and write
# refuse to proceed against an existing file whose version differs —
# fail closed on format drift (R1-S10) rather than guess at a foreign
# shape.
# ---------------------------------------------------------------------------

supported_version=1

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# read_version <file> — value of the top-level "version:" line, or empty
# if the file doesn't exist or has none.
read_version() {
    [ -f "$1" ] || return 0
    grep -E '^version:' "$1" 2>/dev/null \
        | head -n 1 \
        | sed -E 's/^version:[[:space:]]*//; s/[[:space:]]*(#.*)?$//'
}

# gate_block <file> <gate> — the indented "  artifact: sha" lines under
# <gate>'s top-level block (stops at the next unindented line or EOF).
# Empty output if the file or the block doesn't exist.
gate_block() {
    [ -f "$1" ] || return 0
    awk -v gate="$2" '
        $0 ~ "^" gate ":[[:space:]]*$" { in_block = 1; next }
        in_block && /^[^[:space:]]/ { in_block = 0 }
        in_block && NF { print }
    ' "$1"
}

# other_gate_of <gate> — the complementary gate name.
other_gate_of() {
    case "$1" in
        council) printf 'workforce\n' ;;
        workforce) printf 'council\n' ;;
    esac
}

# ensure_supported_version <file> — dies (fail closed, R1-S10) if <file>
# exists and its "version:" field is missing, unparseable, or not
# $supported_version. No-op if <file> doesn't exist yet.
ensure_supported_version() {
    [ -f "$1" ] || return 0
    v=$(read_version "$1")
    if [ -z "$v" ]; then
        die "'$1' has no parseable 'version:' field — format-version drift, refusing to proceed (fail-closed, R1-S10)"
    fi
    if [ "$v" != "$supported_version" ]; then
        die "'$1' has version '$v'; this script only understands version '$supported_version' — format-version drift, refusing to proceed (fail-closed, R1-S10)"
    fi
}

# ---------------------------------------------------------------------------
# Repo root + feature.json (D45: feature.json is the sole spec-ID
# resolver — same resolution branch.sh/cleanup.sh use).
# ---------------------------------------------------------------------------

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || die "not inside a git repository"
cd "$repo_root"

feature_json=".specify/feature.json"
[ -f "$feature_json" ] || die "$feature_json not found — run /speckit-specify first"

feature_directory=$(grep '"feature_directory"' "$feature_json" 2>/dev/null \
    | head -n 1 \
    | sed -E 's/.*"feature_directory"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')

[ -n "$feature_directory" ] || die "could not read \"feature_directory\" from $feature_json"

spec_id=$(basename "$feature_directory")
gates_file="specs/$spec_id/gates.yml"

script_dir=$(dirname "$0")
script_dir=$(cd "$script_dir" 2>/dev/null && pwd) || die "cannot resolve script directory from '$0'"
sha_script="$script_dir/sha.sh"
[ -f "$sha_script" ] || die "sibling script not found: $sha_script (gates.sh composes sha.sh for every SHA lookup)"

# ---------------------------------------------------------------------------
# write
# ---------------------------------------------------------------------------

cmd_write() {
    # "$@" = optional explicit artifact list; falls back to the per-gate
    # default (contracts/commands.md: council -> plan.md; workforce ->
    # tasks.md + agents/assignment.md) when none is given.
    if [ "$#" -gt 0 ]; then
        artifact_list="$*"
    else
        case "$gate" in
            council)   artifact_list="plan.md" ;;
            workforce) artifact_list="tasks.md agents/assignment.md" ;;
        esac
    fi

    [ -d "specs/$spec_id" ] || die "specs/$spec_id does not exist (spec ID resolved from $feature_json) — nothing to bind"

    ensure_supported_version "$gates_file"

    new_block=""
    artifact_count=0
    for artifact in $artifact_list; do
        artifact_path="specs/$spec_id/$artifact"
        [ -f "$artifact_path" ] || die "artifact '$artifact_path' does not exist — cannot record a gate binding for a nonexistent artifact"
        sha=$("$sha_script" "$artifact_path") || die "could not resolve a SHA for '$artifact_path' via $sha_script (see message above)"
        new_block="${new_block}  ${artifact}: ${sha}
"
        artifact_count=$((artifact_count + 1))
    done

    other=$(other_gate_of "$gate")
    preserved_block=$(gate_block "$gates_file" "$other")

    tmp_file="${gates_file}.tmp.$$"
    trap 'rm -f "$tmp_file" 2>/dev/null || true' EXIT

    {
        printf '# gates.yml -- GateSHABinding record (git-ext-owned; see\n'
        printf '# data-model.md #GateSHABinding). Written and read only by\n'
        printf '# gates.sh -- do not hand-edit: a stale or malformed binding\n'
        printf '# hard-blocks its gated phase (verify-gate fails closed on\n'
        printf '# drift, R1-S10).\n'
        printf 'version: %s\n' "$supported_version"

        if [ "$gate" = "council" ]; then
            printf 'council:\n%s' "$new_block"
        elif [ -n "$preserved_block" ]; then
            printf 'council:\n%s\n' "$preserved_block"
        fi

        if [ "$gate" = "workforce" ]; then
            printf 'workforce:\n%s' "$new_block"
        elif [ -n "$preserved_block" ]; then
            printf 'workforce:\n%s\n' "$preserved_block"
        fi
    } > "$tmp_file"

    mv "$tmp_file" "$gates_file"
    trap - EXIT

    printf 'gates.sh: wrote gate "%s" (%d artifact(s)) to %s\n' "$gate" "$artifact_count" "$gates_file"
}

# ---------------------------------------------------------------------------
# read
# ---------------------------------------------------------------------------

cmd_read() {
    [ -f "$gates_file" ] || die "no gates.yml at '$gates_file' — gate '$gate' has never been recorded (fail-closed: nothing to verify)"

    ensure_supported_version "$gates_file"

    block=$(gate_block "$gates_file" "$gate")
    [ -n "$block" ] || die "gate '$gate' has no binding recorded in '$gates_file'"

    printf '%s\n' "$block" | while IFS= read -r line; do
        trimmed=$(printf '%s' "$line" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
        [ -n "$trimmed" ] || continue
        artifact=$(printf '%s' "$trimmed" | cut -d: -f1)
        sha_value=$(printf '%s' "$trimmed" | cut -d: -f2- | sed -E 's/^[[:space:]]+//')
        [ -n "$artifact" ] || die "unparseable binding line in '$gates_file': '$line' (fail-closed, R1-S10)"
        if ! printf '%s' "$sha_value" | LC_ALL=C grep -Eq '^[0-9a-f]+$'; then
            die "unparseable binding line in '$gates_file': '$line' (value is not a hex SHA — fail-closed, R1-S10)"
        fi
        printf '%s @ %s\n' "$artifact" "$sha_value"
    done
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------

case "$subcommand" in
    write) cmd_write "$@" ;;
    read)
        [ "$#" -eq 0 ] || die "'read' takes no artifact arguments (got: $*)"
        cmd_read
        ;;
    *) die "internal error: unhandled subcommand '$subcommand'" ;;
esac
