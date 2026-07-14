#!/bin/sh
# augment.sh — arm-1 post-extraction coverage pass (005-graphify-context, T008).
#
# A THIN POSIX-sh wrapper: it resolves its sibling augment_merge.py (Python 3) and
# delegates ALL work to it — file walking, .sh/.yml/.md parsing, edge detection, the
# --emit projection, and the JSON merge. Keeping the logic in Python (not sh) is
# deliberate: robust parsing/JSON, and no /bin/sh (Darwin bash-3.2) parsing traps.
# Implements specs/005-graphify-context/contracts/commands.md § "Arm 1 — augment.sh".
# Mechanical only: no model call, no network, no ANTHROPIC_API_KEY, no traces.jsonl
# write (constitution V/IV). The upstream graphifyy package is never modified (D75) —
# augment_merge.py only reads/writes graph.json.
#
# Usage:
#   augment.sh --emit <root>          -> canonical NODE/EDGE projection on stdout.
#   augment.sh <graph.json> [<root>]  -> merge additions into graph.json in place;
#                                        prints 'augmented: +<N> nodes / +<M> edges'.
#
# Exit: 0 on success (stdout as above). Non-zero on bad invocation / parse failure,
# with a diagnostic on stderr; never a silent partial.

set -eu

die() {
    printf 'augment.sh: error: %s\n' "$1" >&2
    exit 1
}

usage() {
    printf 'usage: augment.sh --emit <root>\n' >&2
    printf '       augment.sh <graph.json> [<root>]\n' >&2
}

case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
esac

[ "$#" -ge 1 ] || { usage; exit 1; }

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd) || die "cannot resolve own directory from \$0 ($0)"
engine="$script_dir/augment_merge.py"
[ -f "$engine" ] || die "sibling augment_merge.py not found at $engine"

if [ "$1" = "--emit" ]; then
    [ "$#" -ge 2 ] || { usage; exit 1; }
    exec python3 "$engine" --emit "$2"
fi

# Production merge: the first argument is the graph.json to augment in place.
exec python3 "$engine" --merge "$@"
