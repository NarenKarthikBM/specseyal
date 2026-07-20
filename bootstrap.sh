#!/bin/sh
#
# bootstrap.sh — speckit clone-free extension installer (I-32, US1)
#
# Lets an adopter install ONE speckit extension into a target repo with no
# manual `git clone` of specseyal first:
#
#   curl -fsSLO <raw-repo-url>/<pinned-ref>/bootstrap.sh
#   sh bootstrap.sh <extension-name> [<target-repo-dir>] [--ref <pinned-ref>]
#
# Contract (authoritative): specs/008-pre-public-maintenance/contracts/
# bootstrap-install-command.md. Plan reference: specs/008-pre-public-
# maintenance/plan.md § Summary (R1-S05 pinned-ref rationale, R1-S24
# trap/exit-propagation rationale), D45 (additive-only).
#
# What this script IS: a thin wrapper. It fetches extensions/<name>/ from a
# pinned tag/commit into a temp dir, then DELEGATES to that extension's own,
# already-idempotent `install.sh <target>` — it never re-implements install
# logic (Contract B2). It never removes or alters the existing in-checkout
# `install.sh .` route, which keeps working offline/unchanged (Contract B5).
#
# POSIX `sh` throughout, matching extensions/deck-render/install.sh's own
# POSIX-sh precedent in this repo (the other sibling installers are
# `#!/usr/bin/env bash`). No bash-isms: no BASH_SOURCE (uses `$0` instead),
# no `local`, no `[[ ]]`, no arrays, no `pipefail` (nothing here pipes a
# command whose mid-pipe exit status matters, so plain `set -eu` suffices).
#
# Zero third-party dependencies in THIS file. No PyYAML, no `jq`. (T004's
# fetch step is allowed `git`, and `curl`/`tar` for its tarball fallback —
# Contract B7 — but that is T004's concern, not this file's argument-parsing
# and safety layer.)
#
# Never references ANTHROPIC_API_KEY or any credential (Constitution / D28 —
# all work runs on a Claude subscription; this installer authenticates
# nothing and bakes in no token of any kind — it only ever fetches source
# files from a public ref).
#
# --- STATUS OF THIS FILE (T003 vs T004) --------------------------------------
# T003 (this change) implements ONLY the argument surface and the safety
# layer below: enum/ref/target validation, argument-injection rejection, and
# the trap-based temp-dir cleanup. The actual fetch (sparse git clone +
# codeload tarball fallback) and the delegation call into the fetched
# extension's install.sh are T004's job, landing entirely inside the
# fetch_and_delegate() stub marked below — search for "SEAM FOR T004".
# Running this script today validates its arguments correctly and then fails
# loudly at that stub, by design.
#
set -eu

SCRIPT_NAME="$(basename "$0")"

# ---- closed enum of installable extensions (Contract §Invocation) ----------
# Deliberately a plain space-separated string, not an array — POSIX sh has no
# arrays. Iterated with an unquoted `for e in $VALID_EXTENSIONS` below: that
# is a fixed, internal, developer-controlled list (never user input), so the
# usual "always quote" rule does not apply to this one expansion.
VALID_EXTENSIONS="git graphify council workforce testing deck-render"

# ---- pinned --ref default (a decided point — implement exactly) ------------
# R1-S05: --ref MUST default to a concrete released tag, NEVER a moving
# branch (`main`, `HEAD`) — an undecided or moving default would contradict
# this contract's own pinned-posture rationale the instant it stopped being
# convenient.
#
# This repo's release tags follow the `complete/<spec-id>` convention
# (existing: complete/002-speckit-ext-git … complete/007-oss-docs).
# bootstrap.sh is introduced BY feature 008, so it is ABSENT from every
# EARLIER tag: defaulting to complete/007-oss-docs would fetch a tree with no
# bootstrap.sh in it at all. The only correct pinned default is therefore the
# tag 008's own completion will mint.
#
# FORWARD REFERENCE — documented deliberately, not a bug: this default
# resolves only once `complete/008-pre-public-maintenance` is tagged at this
# feature's own git cleanup (docs/00 git lifecycle, D25). Until that tag
# exists, a fetch against this default will fail to resolve (T004: a clear,
# named fetch-failure error, not a silent fallback) and a caller must pass
# `--ref <existing-tag-or-commit>` explicitly (e.g. `--ref
# complete/007-oss-docs` for every extension except this file itself). Do NOT
# "fix" this by substituting `main` or `HEAD` — that would defeat the pinned-
# posture requirement this default exists to satisfy.
DEFAULT_REF="complete/008-pre-public-maintenance"

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} <extension-name> [<target-repo-dir>] [--ref <pinned-ref>]
       ${SCRIPT_NAME} -h | --help

Fetch one speckit extension from a pinned ref of the specseyal repo and
install it into a target repo — no manual 'git clone' of specseyal required.
Delegates to that extension's own install.sh; never re-implements it.

Arguments:
  <extension-name>    Required. One of:
                         git | graphify | council | workforce | testing | deck-render
  <target-repo-dir>   Optional. Repo to install into. Must already exist.
                       Defaults to: .  (the current directory)

Options:
  --ref <pinned-ref>  Optional. Tag or commit to fetch extensions/<name>/
                       from. A concrete released tag — never a moving branch.
                       Defaults to: ${DEFAULT_REF}
                       (NOTE: that default only resolves once feature 008 is
                       tagged at its own cleanup; until then pass --ref
                       explicitly — see the DEFAULT_REF comment in this file.)
  -h, --help           Show this help and exit 0.

Examples:
  ${SCRIPT_NAME} git
  ${SCRIPT_NAME} workforce ./my-repo
  ${SCRIPT_NAME} council ./my-repo --ref complete/007-oss-docs

Exit codes:
  0          extension acquired and installed (or idempotent re-install)
             successfully.
  non-zero   bad usage, unknown extension name, fetch failure (bad ref /
             network), or the delegated install.sh failed — the message
             names the cause; the temp workspace is always cleaned up first.
EOF
}

# ---- output / error helpers (die/ok/warn/bold idiom — matches
# extensions/git/install.sh and extensions/workforce/install.sh) -------------
bold() { printf '\033[1m%s\033[0m\n' "$1"; }
ok()   { printf '  \033[32m\xe2\x9c\x93\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }

# die(): a plain runtime failure (e.g. target dir missing, or the T004 seam
# not implemented yet). No usage dump — the input SHAPE was fine, something
# else failed.
die() {
  printf '\033[31m\xe2\x9c\x97 %s\033[0m\n' "$1" >&2
  exit 1
}

# die_usage(): the input SHAPE itself was wrong (bad flag, unknown extension,
# injection-shaped value, missing required argument) — echo usage so the
# caller can self-correct without re-reading this file.
die_usage() {
  printf '\033[31m\xe2\x9c\x97 %s\033[0m\n\n' "$1" >&2
  usage >&2
  exit 1
}

is_valid_extension() {  # $1 = candidate name
  for e in ${VALID_EXTENSIONS}; do
    if [ "${e}" = "$1" ]; then
      return 0
    fi
  done
  return 1
}

# reject_leading_dash(): the argument-injection guard (plan.md § Summary,
# Contract is silent on the exact wording but names the vector explicitly).
# A --ref or <target-repo-dir> value beginning with '-' could later be
# misread as a FLAG by `git clone` / `git sparse-checkout` (T004) instead of
# a value — a known git argument-injection vector — so both are rejected
# HERE, before either is ever interpolated into any command, T004's included.
# This also has to run BEFORE any `cd "$value"` on target-repo-dir: `cd -`
# is itself a shell special case (jumps to $OLDPWD), so even the existence
# check below must never see an unvalidated leading-dash value.
reject_leading_dash() {  # $1 = value, $2 = human label for the error message
  case "$1" in
    -*)
      die_usage "${2} cannot begin with '-' (rejected as a possible argument-injection vector into the fetch step's git command — value was: '$1')"
      ;;
  esac
}

# ---- argument parsing --------------------------------------------------------
REF="${DEFAULT_REF}"
EXT_NAME=""
TARGET_DIR=""
POSITIONAL_COUNT=0

set_positional() {  # $1 = value; fills EXT_NAME then TARGET_DIR, in order
  POSITIONAL_COUNT=$((POSITIONAL_COUNT + 1))
  case "${POSITIONAL_COUNT}" in
    1) EXT_NAME="$1" ;;
    2) TARGET_DIR="$1" ;;
    *) die_usage "unexpected extra argument: '$1'" ;;
  esac
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --ref)
      [ "$#" -ge 2 ] || die_usage "--ref requires a value"
      REF="$2"
      shift 2
      ;;
    --ref=*)
      REF="${1#--ref=}"
      shift
      ;;
    --)
      shift
      while [ "$#" -gt 0 ]; do
        set_positional "$1"
        shift
      done
      ;;
    -*)
      die_usage "unknown option: '$1'"
      ;;
    *)
      set_positional "$1"
      shift
      ;;
  esac
done

# ---- validate: <extension-name> ---------------------------------------------
[ -n "${EXT_NAME}" ] || die_usage "missing required argument: <extension-name>"
is_valid_extension "${EXT_NAME}" || die_usage "unknown extension '${EXT_NAME}' — must be one of: ${VALID_EXTENSIONS}"

# ---- validate: --ref ----------------------------------------------------------
[ -n "${REF}" ] || die_usage "--ref value cannot be empty"
reject_leading_dash "${REF}" "--ref"

# ---- validate: <target-repo-dir> ---------------------------------------------
# Default per Contract: '.' (current directory) when omitted.
if [ -z "${TARGET_DIR}" ]; then
  TARGET_DIR="."
fi
reject_leading_dash "${TARGET_DIR}" "<target-repo-dir>"

# DECISION (documented, deliberate — target-repo-dir existence): require the
# target to already exist as a directory; never mkdir -p it. bootstrap.sh
# only ever writes INSIDE an existing checkout (its whole job is delegating
# to that checkout's extensions/<name>/install.sh, which itself requires a
# .specify/ tree already there — see extensions/*/install.sh's own
# precondition). Silently creating a typo'd path would trade a fast, legible
# failure for a confusing empty directory tree the adopter has to notice and
# clean up themselves — the opposite of fail-fast.
TARGET_DIR_INPUT="${TARGET_DIR}"
TARGET_DIR="$(cd "${TARGET_DIR}" 2>/dev/null && pwd)" || die "target-repo-dir not found or not a directory: '${TARGET_DIR_INPUT}'"

bold "${SCRIPT_NAME} → installing '${EXT_NAME}' @ '${REF}' into ${TARGET_DIR}"

# ---- safety layer: temp workspace + cleanup trap -----------------------------
# One scratch dir for whatever T004's fetch step stages, one EXIT trap that
# owns removing it — same one-scratch-dir/one-trap idiom
# extensions/workforce/install.sh uses, so a later `trap ... EXIT` can never
# silently replace this one (POSIX sh has no handler stacking: the LAST trap
# set for a given signal wins).
TMP_DIR="$(mktemp -d)" || die "could not create a temp directory (mktemp -d failed)"
[ -n "${TMP_DIR}" ] && [ -d "${TMP_DIR}" ] || die "mktemp -d did not return a usable directory"

# cleanup() is the ONLY place this script removes TMP_DIR, and it is reached
# on EVERY exit path: normal completion, any die()/die_usage() above OR
# below this point, a failure inside T004's fetch_and_delegate() body, or an
# interrupt (see the INT/TERM traps below). Per plan.md's R1-S24 intent: on a
# mid-install failure the target repo is left in a NAMED, DOCUMENTED state —
# TMP_DIR gone, TARGET_DIR exactly as far as the delegated install.sh got
# before failing (that extension's own install.sh idempotency contract, not
# this script's) — never a half-populated state inherited by assumption.
#
# Classic trap bug this avoids: if cleanup ran `rm -rf "$TMP_DIR"` and then
# fell off the end, the shell's FINAL exit status becomes rm's own exit
# status (normally 0) — silently turning a failed fetch or a failed
# delegated install.sh into a reported SUCCESS. `rc=$?` is therefore
# cleanup's FIRST statement, captured before `rm` can overwrite $?, and
# `exit "$rc"` at the end re-asserts the real status explicitly.
cleanup() {
  rc=$?
  if [ -n "${TMP_DIR:-}" ] && [ -d "${TMP_DIR}" ]; then
    rm -rf "${TMP_DIR}"
  fi
  exit "${rc}"
}
trap cleanup EXIT
# INT/TERM: exit with the conventional 128+signum status FIRST. That `exit`
# itself re-triggers the EXIT trap above (POSIX shells run the EXIT trap on
# every exit, including one caused by another trap calling `exit`), so
# cleanup() — and therefore the TMP_DIR removal — still runs on ^C or a kill,
# not only on normal completion or an explicit die().
trap 'exit 130' INT   # 128 + SIGINT(2)
trap 'exit 143' TERM  # 128 + SIGTERM(15)

# ==============================================================================
# SEAM FOR T004 — fetch_and_delegate() is a stub. Nothing else in this file
# should need to change to land T004: this function's signature and its sole
# call site (the last line of this file) are the whole seam.
#
# T004 replaces the BODY of this function with, per Contract B6/B7 and
# plan.md's R1-S08 test note:
#   1. a shallow, blobless, sparse `git clone` of extensions/"$ext_name"/ at
#      "$ref" into "$tmp_dir" — using the already-validated/escaped "$ref"
#      and "$tmp_dir" from this function's arguments, never re-deriving or
#      re-parsing either;
#   2. a `codeload` tarball fallback (curl + tar only — Contract B7, no
#      other third-party dependency) if the sparse clone is unavailable or
#      fails;
#   3. delegating to the fetched extensions/"$ext_name"/install.sh
#      "$target_dir" (Contract B2 — never re-implementing that extension's
#      own install logic), and returning ITS exit status verbatim.
# A fetch failure (bad ref / network) or a failed delegated install.sh must
# both surface as THIS script's own non-zero exit, with a message naming the
# cause (Contract §Exit codes). cleanup() above already guarantees TMP_DIR is
# removed on every one of these paths and that the real exit status survives
# — T004's body only needs to `return`/`exit` with the right code; it must
# NOT install its own EXIT/INT/TERM trap (that would replace this one — see
# the "no handler stacking" note above cleanup()).
# ==============================================================================
fetch_and_delegate() {  # $1=ext_name $2=ref $3=target_dir $4=tmp_dir
  ext_name="$1"
  ref="$2"
  target_dir="$3"
  tmp_dir="$4"

  # T004: replace this stub with the fetch + delegate steps described above.
  die "fetch_and_delegate() is not implemented yet (T004 — see the SEAM FOR T004 comment above this function). Cannot install '${ext_name}' @ '${ref}' into '${target_dir}' (tmp workspace: '${tmp_dir}')."
}

fetch_and_delegate "${EXT_NAME}" "${REF}" "${TARGET_DIR}" "${TMP_DIR}"
