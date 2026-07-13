# extensions/graphify/extension/scripts/ — POSIX-`sh` idiom

This directory is the mechanical-script home for graphify's `005` arm-1/2
augmentation (D75): a fixed post-extraction pass and a freshness/refresh
wrapper that sit *alongside* the upstream `graphifyy` extractor — never
inside it, never forking it. `augment.sh` (+ `augment_merge.py`),
`explain-guard.sh`, `freshness.sh`, and `refresh.sh` all land here in later
waves. Every one of them is expected to open with the same preamble, not
reinvent it.

The house style is not invented here — it's read off the two exemplars
already shipping in `extensions/git/extension/scripts/`: `commit.sh` and
`verify-gate.sh`. This file pins that style as convention for this
directory. **It implements none of the scripts named above.**

## The six rules

### 1. Shebang + failure mode

`#!/bin/sh` on line 1, verbatim (`commit.sh:1`, `verify-gate.sh:1`), then
`set -eu` immediately after the header comment block (`commit.sh:59`,
`verify-gate.sh:102`). Use `-eu`, not bash's `-euo pipefail` — `pipefail`
isn't POSIX, and `/bin/sh` is not guaranteed to be bash. A step whose
failure is meant to be tolerated gets an explicit `|| true` / `if` guard
*at that line*, with a comment saying why — never a dropped `set -eu`.

### 2. Header comment block

Every script opens with a comment block, above `set -eu`, shaped like this:

1. `# <script>.sh — <namespaced command it implements>`, e.g.
   `# commit.sh — speckit.git.commit <phase> <summary> [extra-path...]`.
2. A short paragraph naming the contract/data-model doc the script
   implements, with the mechanical/no-LLM/no-trace disclosure stated up
   front, not left implicit.
3. A `# Usage:` block: the invocation line, then one line per argument.
4. As many named subsections as the contract needs — both exemplars use
   labeled sub-blocks such as "Self-heal", "Staging scope", "Spec ID
   resolution", "Fail-closed, never fail-open" — never free-floating prose.
5. A closing `# Out:` / `# Exit:` paragraph stating the stdout contract and
   the exit-code contract explicitly enough that a caller could read only
   this paragraph and know exactly what they get back.

### 3. No LLM, no network, no `traces.jsonl`

Constitution V (subscription-only, NON-NEGOTIABLE): these scripts invoke no
model and must never set or read `ANTHROPIC_API_KEY`. Constitution IV
(observability) governs *sessions*; a script that calls no model is not a
session, so — exactly like commit.sh ("Mechanical git only: no model call,
no traces.jsonl write", `commit.sh:8`) and verify-gate.sh ("Zero AI,
mechanical git only: ... no traces.jsonl write (FR-007)", `verify-gate.sh:
10`) — it correctly appends nothing to `traces.jsonl`. Say so in the
header's one-line disclosure (rule 2.2); don't leave it to be inferred.

### 4. Exit code is the contract

- `die() { printf '<script>.sh: error: %s\n' "$1" >&2; exit 1; }` — the
  script's own basename in every error line, so stderr is greppable back to
  its source (`commit.sh:61-64`, `verify-gate.sh:104-107`).
- `usage()` prints to stderr on bad invocation. `-h`/`--help` is checked
  *before any other argument validation* and exits **0**
  (`commit.sh:70-75`, `verify-gate.sh:113-118`) — help is a successful
  invocation, not a failure.
- Exactly one documented stdout contract per script: either a single
  summary line (commit.sh prints the new commit SHA and *nothing* else,
  ever — every informational message, including a sibling script's own
  stdout during self-heal, is redirected to stderr for exactly this reason)
  or silence-on-success with the exceptions named explicitly in the header
  (verify-gate.sh is silent on both streams when fresh, with exactly one
  documented stderr-only exception for a checkbox-delta PASS).
- Fail-closed: an unverifiable or ambiguous state is a hard non-zero, never
  a guessed 0 ("Fail-closed, never fail-open ... never guesses its way to
  exit 0" — verify-gate.sh header). No silent partial success, ever.

### 5. Determinism

Same repo state in, byte-identical output out — the same bar the workforce
extension's `assemble.py` already proves elsewhere in this repo
(byte-identical across `PYTHONHASHSEED` on a real fixture).

- No dependence on filesystem-iteration order — no unsorted `for f in
  dir/*`. Drive loops off explicit, ordered data (a fixed pathspec list, a
  sibling script's own ordered output), the way commit.sh's staging list
  and verify-gate.sh's binding walk both do.
- Reuse the one multi-line-splitting idiom both exemplars already share
  rather than inventing a new one: split into positional params via a
  newline-only `IFS` with `set -f` to suspend globbing, never piped into
  `while read` (a pipeline's last stage commonly runs in a subshell,
  silently dropping any loop state) — `commit.sh:210-216`,
  `verify-gate.sh:204-210`.
- A Python 3 helper is fine when the job is genuinely data-shape work (a
  JSON graph merge, AST-adjacent structure) that `sh` does badly — this
  directory's own `.gitignore` already anticipates one (`__pycache__/` /
  `*.pyc` / `.venv/`, "in case contributors run the merge scripts
  locally"). The `.sh` stays the entry point and invokes the `.py` as a
  subprocess; the `.py` may **read** graphify's own output artifacts but
  must never write into or otherwise modify the upstream `graphifyy`
  package (D75's extension-layer-augmentation boundary: augment, don't
  fork). A Python helper sorts its own keys/iteration explicitly — never
  relies on incidental dict order.

### 6. Repo-root / self-location resolution

Resolve the script's own directory first — so it can find sibling scripts
regardless of how it was itself invoked (relative, `./`-relative, or
absolute) — then the repo root independently, exactly as both exemplars do:

```sh
# own directory (either exemplar form works; pick one, be consistent within
# a script):
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd) || die "..."        # commit.sh:102
# — or the two-step form —
script_dir=$(dirname "$0")
script_dir=$(cd "$script_dir" 2>/dev/null && pwd) || die "..."              # verify-gate.sh:140-141

# repo root — identical in both exemplars:
repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || die "not inside a git repository"
cd "$repo_root"
```

Note what this directory's scripts do **not** inherit from git-ext: the
`.specify/feature.json` spec-ID resolution (D45) is git-ext's own
per-spec-artifact idiom, load-bearing there because every git-ext script
acts on one feature's `specs/<id>/` tree. graphify's augmentation operates
on the repo-wide dependency graph, not a single feature's artifacts — pull
spec-ID resolution in only if a specific script genuinely needs one; don't
default to it.

## Copy-paste preamble skeleton

```sh
#!/bin/sh
# <name>.sh — <one-line purpose>
#
# <what this implements / the contract doc it satisfies>. Mechanical only:
# no model call, no network, no ANTHROPIC_API_KEY, no traces.jsonl write.
#
# Usage:
#   <name>.sh <args...>
#
# Exit: 0 on success (stdout: <exact contract — a line, or silence>).
# Non-zero on failure, with a diagnostic on stderr.

set -eu

die() {
    printf '<name>.sh: error: %s\n' "$1" >&2
    exit 1
}

usage() {
    printf 'usage: <name>.sh <args...>\n' >&2
}

case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
esac

# --- validate all args here, before touching anything on disk (fail fast) --

[ "$#" -ge 1 ] || { usage; exit 1; }

# --- resolve locations (rule 6) ---------------------------------------------

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd) || die "cannot resolve own directory from \$0 ($0)"

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || die "not inside a git repository"
cd "$repo_root"
```

## Non-goals of this file

This README fixes the shared preamble idiom only. It does not implement
`augment.sh`, `explain-guard.sh`, `freshness.sh`, `refresh.sh`, or
`augment_merge.py` — those are separate tasks in later waves, each free to
add whatever script-specific body logic its own contract needs after this
preamble.
