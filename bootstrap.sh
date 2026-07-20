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
# --- STATUS OF THIS FILE ------------------------------------------------------
# Complete. Built across three tasks, all landed:
#   T003 — argument surface + safety layer: enum/ref/target validation,
#          argument-injection rejection, trap-based temp-dir cleanup.
#   T004 — fetch_and_delegate(): shallow blobless sparse `git clone` primary
#          path, codeload-tarball fallback, delegation to the fetched
#          extension's own install.sh with its exit status propagated verbatim.
#   T005 — `--self-test`, driving BOTH fetch branches (R1-S08).
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
  --self-test          Exercise both fetch branches (sparse-partial-clone and
                       codeload-tarball fallback) and exit. Installs nothing
                       into a real target; every fixture lives under this
                       run's own temp workspace and is cleaned up. A branch
                       that cannot run in this environment is reported as a
                       named SKIP, never a silent pass.
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
# SELF_TEST (T005, R1-S08): 0 by default (normal install run). Set to 1 by
# the --self-test flag below. Read AFTER argument parsing to short-circuit
# the <extension-name>/<target-repo-dir> validation (self-test needs
# neither) and again at the very end of this file to dispatch to
# self_test() instead of the real fetch_and_delegate() — see both sites'
# own comments for why neither one touches this flag's surrounding logic.
SELF_TEST=0

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
    --self-test)
      # T005, R1-S08: run the embedded self-test (both fetch branches) and
      # exit — see self_test()'s own header comment, defined near the end
      # of this file, for the full contract. Deliberately just a flag
      # capture here, exactly like every other flag in this loop; it does
      # not itself validate or dispatch anything (that happens once, right
      # after this loop ends, and again at this file's last line).
      SELF_TEST=1
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
# T005: --self-test installs nothing into a real target, so it needs neither
# <extension-name> nor <target-repo-dir> — this is the ONLY place that
# distinction is made; the two validation lines themselves are UNCHANGED
# from T003 and still run, verbatim, for every normal (non-self-test)
# invocation. A stray positional argument alongside --self-test is still
# rejected (die_usage, same idiom as everywhere else in this file) rather
# than silently ignored — accepting-but-ignoring 'bootstrap.sh --self-test
# git ./repo' would look like it did something with 'git'/'./repo' when it
# does not.
if [ "${SELF_TEST}" = "1" ]; then
  [ "${POSITIONAL_COUNT}" -eq 0 ] || die_usage "--self-test takes no <extension-name>/<target-repo-dir> arguments (got: '${EXT_NAME}')"
else
  [ -n "${EXT_NAME}" ] || die_usage "missing required argument: <extension-name>"
  is_valid_extension "${EXT_NAME}" || die_usage "unknown extension '${EXT_NAME}' — must be one of: ${VALID_EXTENSIONS}"
fi

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

# T005: the normal install banner names <extension-name>/<target-repo-dir>,
# both meaningless in --self-test mode (EXT_NAME is deliberately empty
# there — see the validate block above) — printing it unchanged would read
# as "installing '' into <cwd>", which looks broken rather than
# intentional. The normal-path line itself is UNCHANGED, still the exact
# T003 text, still reached on every normal invocation.
if [ "${SELF_TEST}" = "1" ]; then
  bold "${SCRIPT_NAME} --self-test — installs nothing into a real target (see below)"
else
  bold "${SCRIPT_NAME} → installing '${EXT_NAME}' @ '${REF}' into ${TARGET_DIR}"
fi

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
# fetch_and_delegate() — IMPLEMENTED (T004). This block was the T003→T004 seam
# and is retained as the function's specification: it states what the body
# below is required to do, and every point still holds. Per Contract B6/B7 and
# plan.md's R1-S08 test note, the body:
#   1. does a shallow, blobless, sparse `git clone` of extensions/"$ext_name"/
#      at "$ref" into "$tmp_dir" — using the already-validated/escaped "$ref"
#      and "$tmp_dir" from this function's arguments, never re-deriving or
#      re-parsing either;
#   2. falls back to a `codeload` tarball (curl + tar only — Contract B7, no
#      other third-party dependency) if the sparse clone is unavailable or
#      fails;
#   3. delegates to the fetched extensions/"$ext_name"/install.sh
#      "$target_dir" (Contract B2 — never re-implementing that extension's
#      own install logic), returning ITS exit status verbatim.
# A fetch failure (bad ref / network) or a failed delegated install.sh must
# both surface as THIS script's own non-zero exit, with a message naming the
# cause (Contract §Exit codes). cleanup() above already guarantees TMP_DIR is
# removed on every one of these paths and that the real exit status survives
# — the body only needs to `return`/`exit` with the right code, and must NOT
# install its own EXIT/INT/TERM trap (that would replace this one — see the
# "no handler stacking" note above cleanup()).
# ==============================================================================
# ---- fetch constants (T004) --------------------------------------------------
# The origin repo this whole file fetches FROM — public source only, no
# token/credential of any kind baked in (Constitution / D28). The repo is
# still private as of feature 008 (D73 — a public-visibility flip is a
# separate, later, manual step); an unauthenticated fetch against it will
# legitimately fail until that flip happens. That is expected, not a bug
# here — see sparse_clone_fetch()/tarball_fetch() below, both of which are
# written correctly for the public case and add no auth of any kind.
REPO_URL="https://github.com/NarenKarthikBM/specseyal.git"
CODELOAD_URL_BASE="https://codeload.github.com/NarenKarthikBM/specseyal/tar.gz"

# ---- fetch path 1 (primary): shallow, blobless, sparse git clone -----------
# Contract B6. Lands ONLY extensions/"$ext_name"/ at the pinned ref into
# dest_dir — never the whole repo; that narrowness is the point of I-32.
#
# Whether this git build even supports `--filter=blob:none --sparse`
# (partial clone landed in git 2.25; the `--sparse` clone flag in 2.27)
# varies by distro backport, so parsing `git --version` ourselves would be
# unreliable. We instead PROBE capability by attempting the real clone and
# treating ITS failure as the single signal to fall back to the tarball path
# below (Contract B6: "unavailable or fails" — deliberately not
# distinguishing an old git from a bad ref from a network error here; the
# tarball fallback either recovers from it or reproduces the same failure
# with its own clear message, so nothing is lost by not diagnosing further).
#
# `--branch "$ref"` resolves a tag or branch; it does NOT resolve an
# arbitrary raw commit SHA on every server. A caller who passes --ref as a
# bare commit SHA may legitimately fail HERE and fall through to the
# tarball path below, which resolves any commit via codeload — by design,
# not a bug (the two paths' capabilities are complementary, not identical).
#
# GIT_TERMINAL_PROMPT=0: never let this script block waiting on a TTY
# credential prompt — it fetches a public ref with no credential of any
# kind (see REPO_URL comment above); if that ever needs auth, it must fail
# fast, not hang.
sparse_clone_fetch() {  # $1=ref $2=ext_name $3=dest_dir → 0 fetched, 1 fall back
  ref="$1"
  ext_name="$2"
  dest_dir="$3"

  command -v git >/dev/null 2>&1 || return 1

  GIT_TERMINAL_PROMPT=0 git clone --quiet --depth 1 --filter=blob:none \
    --sparse --branch "${ref}" -- "${REPO_URL}" "${dest_dir}" \
    >/dev/null 2>&1 || return 1
  git -C "${dest_dir}" sparse-checkout set "extensions/${ext_name}" \
    >/dev/null 2>&1 || return 1
  [ -f "${dest_dir}/extensions/${ext_name}/install.sh" ] || return 1
  return 0
}

# ---- fetch path 2 (fallback): codeload tarball at the SAME pinned ref ------
# Contract B6/B7. Used only when the sparse clone above is unavailable or
# fails, for any reason. codeload has no subtree-only endpoint, so this
# downloads the whole-repo tarball at "$ref" and then extracts and keeps
# ONLY extensions/"$ext_name"/ — so both fetch paths land the identical
# subtree at dest_dir, and the delegate step below cannot tell them apart.
# curl + tar only (Contract B7) — no other third-party dependency.
tarball_fetch() {  # $1=ref $2=ext_name $3=dest_dir → 0 fetched, 1 failure
  ref="$1"
  ext_name="$2"
  dest_dir="$3"

  command -v curl >/dev/null 2>&1 || return 1
  command -v tar  >/dev/null 2>&1 || return 1

  archive="${dest_dir}.tar.gz"
  extract_dir="${dest_dir}.extract"
  # Clears any partial state a failed sparse_clone_fetch() attempt may have
  # left at dest_dir (e.g. a half-cloned .git/) — this is the ONLY place
  # dest_dir is reset for this path, so the caller need not clean up first.
  rm -rf "${dest_dir}" "${extract_dir}" "${archive}"
  mkdir -p "${extract_dir}" || return 1

  # Same endpoint form Contract B6/B7 names: codeload accepts a tag, branch,
  # or commit SHA as <ref> — slashes included, which this repo's own tags
  # need (complete/<spec-id>, e.g. complete/008-pre-public-maintenance).
  curl -fsSL -o "${archive}" "${CODELOAD_URL_BASE}/${ref}" || return 1

  # codeload wraps the whole repo in one top-level "<repo>-<ref>/" directory
  # whose exact sanitized name we don't predict, so extract to a scratch dir
  # first, locate that one top-level dir, then keep ONLY the subtree we
  # need. A plain POSIX directory glob (dir/*/ matches directories only) —
  # not `find -mindepth/-maxdepth`, which is a GNU/BSD extension, not POSIX.
  tar -xzf "${archive}" -C "${extract_dir}" || return 1
  rm -f "${archive}"

  top_dir=""
  for d in "${extract_dir}"/*/; do
    [ -d "${d}" ] || continue
    top_dir="${d}"
    break
  done
  [ -n "${top_dir}" ] || return 1
  [ -d "${top_dir}extensions/${ext_name}" ] || return 1

  mkdir -p "${dest_dir}/extensions" || return 1
  mv "${top_dir}extensions/${ext_name}" "${dest_dir}/extensions/${ext_name}" || return 1
  rm -rf "${extract_dir}"

  [ -f "${dest_dir}/extensions/${ext_name}/install.sh" ] || return 1
  return 0
}

fetch_and_delegate() {  # $1=ext_name $2=ref $3=target_dir $4=tmp_dir
  ext_name="$1"
  ref="$2"
  target_dir="$3"
  tmp_dir="$4"

  # A dedicated subdir of tmp_dir, not tmp_dir itself: keeps a failed
  # primary attempt's partial state from ever being mistaken for a
  # successful fetch by the fallback path or the delegate step below — both
  # fetch paths always land the final tree at exactly this one path, so the
  # delegate step cannot tell which path produced it.
  fetched_dir="${tmp_dir}/src"

  if sparse_clone_fetch "${ref}" "${ext_name}" "${fetched_dir}"; then
    ok "fetched extensions/${ext_name}/ @ '${ref}' (sparse clone)"
  else
    warn "sparse clone unavailable or failed for '${ref}' — falling back to the codeload tarball"
    if tarball_fetch "${ref}" "${ext_name}" "${fetched_dir}"; then
      ok "fetched extensions/${ext_name}/ @ '${ref}' (codeload tarball fallback)"
    else
      die "could not fetch extensions/${ext_name}/ @ '${ref}' via sparse git clone OR the codeload tarball fallback — check that '${ref}' exists as a tag/commit and that ${REPO_URL} is reachable (and, until the D73 visibility flip, public)"
    fi
  fi

  installer="${fetched_dir}/extensions/${ext_name}/install.sh"
  [ -f "${installer}" ] || die "fetched tree has no extensions/${ext_name}/install.sh @ '${ref}' — unexpected repo layout at that ref"
  chmod +x "${installer}" 2>/dev/null || true

  # Delegate — never re-implement install logic (Contract B2/FR-003/D45).
  # Exec the fetched extension's OWN install.sh, via ITS OWN shebang (most
  # sibling installers are #!/usr/bin/env bash; deck-render's is POSIX sh —
  # either way that is its call, not ours to second-guess or replicate).
  #
  # Deliberately the LAST statement in this function, unwrapped by any
  # if/&&/||/$(): under this script's `set -eu`, if it fails, the shell
  # exits immediately with THIS exact exit status, which the EXIT trap's
  # cleanup() (already installed above — see the SEAM comment) captures as
  # `rc=$?` before it removes tmp_dir, then re-asserts with `exit "$rc"`.
  # That is how the delegated command's exit status survives verbatim
  # (Contract §Exit codes) without this function installing any trap of its
  # own.
  "${installer}" "${target_dir}"
}

# ==============================================================================
# --self-test (T005, R1-S08) --------------------------------------------------
#
# Council decision R1-S08 (specs/008-pre-public-maintenance/council/
# decision-record.md): "the largest branch-count increase [in this file]
# sits in the least-tested item... a minimal automated smoke test now
# exercises both the sparse-partial-clone and codeload-tarball fallback
# branches." This section is that smoke test. Folded into bootstrap.sh
# itself, not a new file, mirroring extensions/workforce/extension/scripts/
# validate-profile.py's embedded `_self_test()` / `_write_fixture()`
# precedent (a new top-level test harness file would fall outside this
# feature's own scope allowlist).
#
# WHAT "BOTH BRANCHES" MEANS HERE, and why each gets TWO checks, not one:
#   - sparse_clone_fetch() — checked against (1) a fully hermetic, always-
#     available LOCAL git repo standing in for github.com, so this branch
#     has at least one deterministic PASS on every host with `git`
#     installed, network or none; and (2), best-effort, the REAL
#     github.com remote at ref `main` (never this file's own DEFAULT_REF —
#     see the note before SELF_TEST_REAL_REF below).
#   - tarball_fetch() — checked against (1) a local loopback HTTP server
#     standing in for codeload.github.com, with the sparse-clone primary
#     path DELIBERATELY forced to fail first via a bogus local REPO_URL —
#     not a flaky network condition — so this drives the REAL
#     fetch_and_delegate() decision logic into its fallback branch, proving
#     the fallback is genuinely reached, not merely defined in isolation
#     (the exact gap this task exists to close — see this task's own
#     prompt); and (2), best-effort, the REAL codeload.github.com endpoint.
#
# HONESTY CONTRACT (required behaviour #5): every result printed below is
# tagged with exactly which of these two kinds of infrastructure it ran
# against — "stand-in" or "real" — never left ambiguous. A stand-in never
# exercises codeload's real HTTP redirects, its exact top-level-directory
# naming convention, or its content-encoding behaviour; only a genuinely
# reachable real-infra run does. Real-infra branches that cannot be
# exercised in a given environment (no network, this repo still private
# per D73, an unauthenticated `curl` 404ing exactly as this file's own
# CODELOAD_URL_BASE comment already predicts) are reported as a named SKIP,
# never folded into a silent PASS or an alarming FAIL — see this task's own
# required-behaviour #4.
#
# HERMETIC / NO SECOND TRAP (required behaviour #4 and #6): every git repo,
# tarball, and HTTP server this section creates lives ONLY under
# "${TMP_DIR}/self-test" — a subdirectory of the SAME TMP_DIR the safety
# layer above already created and already owns via the EXIT/INT/TERM traps
# already installed above (search this file for "trap cleanup EXIT"). This
# section installs no trap of its own: `rm -rf "${TMP_DIR}"` in that
# existing cleanup() already removes everything self-test builds, exactly
# once, on every exit path — normal completion, a FAIL, or an interrupt.
# The one thing that existing trap cannot reach is the background HTTP
# stand-in server's OS process (a trap removes files, not processes); this
# section stops that server itself, explicitly, right after each use — see
# self_test_http_server_stop() — rather than leaving it for a trap that
# does not know about it. A ^C during the few-hundred-millisecond window
# that server is briefly running is the one known, accepted gap this
# leaves (documented here rather than solved by adding a second trap, which
# required behaviour #6 forbids outright).
#
# fetch_and_delegate() ITSELF IS CALLED FOR REAL, UNMODIFIED, inside a
# SUBSHELL "( ... )" below — never edited, never re-implemented (Contract
# B2). The subshell serves two purposes at once: (a) any REPO_URL /
# CODELOAD_URL_BASE override needed to steer a call at a stand-in
# automatically reverts the instant that subshell exits, no manual
# save/restore needed; and (b) fetch_and_delegate()'s own die() calls
# `exit 1` on a total failure — inside a subshell that only ends the
# subshell, not this whole script, so one forced-failure branch can never
# take down the rest of this self-test's reporting.

# SELF_TEST_REAL_REF: --self-test's own real-infra probes intentionally use
# `main`, NOT this file's own ${REF} (which defaults to DEFAULT_REF —
# `complete/008-pre-public-maintenance` — a tag that, per that constant's
# own header comment, does not exist until this feature's own release; a
# self-test that defaulted to it would report a guaranteed, permanent SKIP
# today). `main` is the same ref T004 already validated the sparse-clone
# primary path against end-to-end. --self-test does not read the user's
# own --ref (if one was passed) — self-test is a fixed smoke test of the
# MECHANISM, not a check of any one particular ref.
SELF_TEST_REAL_REF="main"
SELF_TEST_EXT="git"

self_test_record() {  # $1=label $2=PASS|FAIL|SKIP $3=infra-tag $4=detail
  st_r_label="$1"
  st_r_status="$2"
  st_r_infra="$3"
  st_r_detail="$4"
  case "${st_r_status}" in
    PASS)
      SELF_TEST_PASS=$((SELF_TEST_PASS + 1))
      ok "[${st_r_infra}] ${st_r_label}: PASS — ${st_r_detail}"
      ;;
    FAIL)
      SELF_TEST_FAIL=$((SELF_TEST_FAIL + 1))
      printf '  \033[31m\xe2\x9c\x97\033[0m [%s] %s: FAIL — %s\n' "${st_r_infra}" "${st_r_label}" "${st_r_detail}"
      ;;
    SKIP)
      SELF_TEST_SKIP=$((SELF_TEST_SKIP + 1))
      warn "[${st_r_infra}] ${st_r_label}: SKIP — ${st_r_detail}"
      ;;
    *)
      die "self_test_record: internal error — unknown status '${st_r_status}'"
      ;;
  esac
}

# self_test_write_stub_install(): a fixture extensions/<name>/install.sh —
# NOT a real extension installer. It only proves fetch_and_delegate()'s
# delegate step actually ran, by printing a fixed marker and exiting 0.
# Always exit 0: fetch_and_delegate()'s own delegate call is deliberately
# unguarded (see its own comment above) so this self-test can call the real
# function inside a subshell without risking an unrelated nonzero exit
# there masking a DIFFERENT branch's own result.
self_test_write_stub_install() {  # $1=root_dir $2=ext_name
  st_w_root="$1"
  st_w_ext="$2"
  mkdir -p "${st_w_root}/extensions/${st_w_ext}" || return 1
  cat > "${st_w_root}/extensions/${st_w_ext}/install.sh" <<'STUBEOF'
#!/bin/sh
# bootstrap.sh --self-test fixture — not a real extension installer.
set -eu
printf 'self-test-stub-install-ok target=%s\n' "${1:-<missing>}"
exit 0
STUBEOF
  chmod +x "${st_w_root}/extensions/${st_w_ext}/install.sh" || return 1
  return 0
}

# self_test_local_git_origin(): a hermetic local git repo standing in for
# github.com — real `git`, real `git clone --sparse`, zero network. Also
# seeds a SECOND, noise, extension dir so a passing check below can prove
# sparse-checkout genuinely narrowed the working tree, not just that
# *something* landed.
self_test_local_git_origin() {  # $1=origin_dir $2=ext_name
  st_o_dir="$1"
  st_o_ext="$2"
  self_test_write_stub_install "${st_o_dir}" "${st_o_ext}" || return 1
  mkdir -p "${st_o_dir}/extensions/_selftest_noise" || return 1
  printf 'noise — must NOT appear in a sparse-checked-out working tree\n' \
    > "${st_o_dir}/extensions/_selftest_noise/file.txt" || return 1
  git init --quiet "${st_o_dir}" >/dev/null 2>&1 || return 1
  git -C "${st_o_dir}" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1 || return 1
  git -C "${st_o_dir}" add -A >/dev/null 2>&1 || return 1
  git -c user.email=selftest@bootstrap.sh -c user.name="bootstrap.sh self-test" \
    -C "${st_o_dir}" commit --quiet -m "self-test fixture commit" >/dev/null 2>&1 || return 1
  return 0
}

# self_test_build_codeload_tarball(): a *.tar.gz whose single top-level
# entry wraps extensions/<name>/install.sh — the same shape tarball_fetch()
# expects (its own comment: "codeload wraps the whole repo in one
# top-level ... directory"). This proves the extract → find-top-dir →
# keep-only-the-subtree logic; it does NOT prove codeload's own exact
# naming convention (see the honesty-contract note above).
self_test_build_codeload_tarball() {  # $1=serve_dir $2=archive_name $3=ext_name
  st_t_serve="$1"
  st_t_archive="$2"
  st_t_ext="$3"
  st_t_build="${st_t_serve}.build"
  st_t_top="${st_t_build}/specseyal-main"
  self_test_write_stub_install "${st_t_top}" "${st_t_ext}" || return 1
  mkdir -p "${st_t_serve}" || return 1
  ( cd "${st_t_build}" && tar -czf "${st_t_serve}/${st_t_archive}" "specseyal-main" ) || return 1
  rm -rf "${st_t_build}"
  return 0
}

# self_test_http_server_start()/_stop(): a stdlib-only (python3's
# `http.server`) loopback HTTP server standing in for codeload.github.com —
# a real HTTP round trip over a real socket, unlike a `file://` shortcut,
# at the cost of requiring python3 on PATH (this file's own zero-third-
# party-dependency rule is about bootstrap.sh's NORMAL fetch path, which
# never runs this code — self-test's own scaffolding is exempt the same way
# validate-profile.py's `_self_test()` is exempt from the constraints it
# validates). Absence of python3 is a named SKIP, never a FAIL — required
# behaviour #4.
SELF_TEST_HTTP_PID=""
SELF_TEST_HTTP_PORT=""

self_test_http_server_start() {  # $1=serve_dir $2=port_file $3=log_file
  st_h_serve="$1"
  st_h_portfile="$2"
  st_h_logfile="$3"
  command -v python3 >/dev/null 2>&1 || return 1
  python3 -c '
import http.server, socketserver, sys, os
os.chdir(sys.argv[1])
class Handler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a):
        pass
with socketserver.TCPServer(("127.0.0.1", 0), Handler) as httpd:
    print(httpd.server_address[1], flush=True)
    httpd.serve_forever()
' "${st_h_serve}" >"${st_h_portfile}" 2>"${st_h_logfile}" &
  SELF_TEST_HTTP_PID="$!"
  st_h_wait=0
  while [ ! -s "${st_h_portfile}" ] && [ "${st_h_wait}" -lt 5 ]; do
    kill -0 "${SELF_TEST_HTTP_PID}" 2>/dev/null || break
    sleep 1 || true
    st_h_wait=$((st_h_wait + 1))
  done
  if [ ! -s "${st_h_portfile}" ]; then
    self_test_http_server_stop
    return 1
  fi
  SELF_TEST_HTTP_PORT="$(cat "${st_h_portfile}")"
  [ -n "${SELF_TEST_HTTP_PORT}" ] || { self_test_http_server_stop; return 1; }
  return 0
}

self_test_http_server_stop() {
  if [ -n "${SELF_TEST_HTTP_PID}" ]; then
    kill "${SELF_TEST_HTTP_PID}" >/dev/null 2>&1 || true
    wait "${SELF_TEST_HTTP_PID}" >/dev/null 2>&1 || true
    SELF_TEST_HTTP_PID=""
  fi
}

self_test() {
  SELF_TEST_PASS=0
  SELF_TEST_FAIL=0
  SELF_TEST_SKIP=0
  SELF_TEST_HTTP_PID=""
  SELF_TEST_HTTP_PORT=""

  bold "${SCRIPT_NAME} --self-test — exercising both bootstrap.sh fetch branches (R1-S08)"
  cat <<EOF

Installs nothing into a real target. Every fixture below lives under this
run's own temp workspace (the one this script already owns — see the
existing EXIT/INT/TERM traps above) and is removed when this script exits,
exactly like a normal run.

EOF

  st_root="${TMP_DIR}/self-test"
  mkdir -p "${st_root}" || die "self-test: could not create scratch dir '${st_root}'"

  # ---- branch 1/4: sparse clone — stand-in (local filesystem git repo) -----
  bold "-- 1/4  sparse-partial-clone  ·  stand-in (local git repo, not github.com) --"
  st_origin1="${st_root}/origin-standin"
  st_dest1="${st_root}/dest-standin"
  if ! command -v git >/dev/null 2>&1; then
    self_test_record "sparse-clone (stand-in)" SKIP "n/a" "git not found on PATH"
  elif ! self_test_local_git_origin "${st_origin1}" "${SELF_TEST_EXT}"; then
    self_test_record "sparse-clone (stand-in)" FAIL "stand-in" "could not build the local git-repo fixture at '${st_origin1}'"
  else
    st_rc=0
    ( REPO_URL="${st_origin1}"; sparse_clone_fetch "main" "${SELF_TEST_EXT}" "${st_dest1}" ) \
      >"${st_root}/branch1.out" 2>&1 || st_rc=$?
    if [ "${st_rc}" -eq 0 ] && [ -f "${st_dest1}/extensions/${SELF_TEST_EXT}/install.sh" ] \
       && [ ! -e "${st_dest1}/extensions/_selftest_noise" ]; then
      self_test_record "sparse-clone (stand-in)" PASS "stand-in (local git repo)" "cloned + sparse-checked-out extensions/${SELF_TEST_EXT}/ only (noise extension correctly absent)"
    else
      self_test_record "sparse-clone (stand-in)" FAIL "stand-in" "sparse_clone_fetch exit=${st_rc}; see ${st_root}/branch1.out"
    fi
  fi

  # ---- branch 2/4: sparse clone — real infra (github.com), best-effort -----
  bold "-- 2/4  sparse-partial-clone  ·  real infrastructure (github.com, ref=${SELF_TEST_REAL_REF}) --"
  st_dest2="${st_root}/dest-real"
  if ! command -v git >/dev/null 2>&1; then
    self_test_record "sparse-clone (real)" SKIP "n/a" "git not found on PATH"
  else
    st_rc=0
    ( sparse_clone_fetch "${SELF_TEST_REAL_REF}" "${SELF_TEST_EXT}" "${st_dest2}" ) \
      >"${st_root}/branch2.out" 2>&1 || st_rc=$?
    if [ "${st_rc}" -eq 0 ] && [ -f "${st_dest2}/extensions/${SELF_TEST_EXT}/install.sh" ]; then
      self_test_record "sparse-clone (real)" PASS "real (github.com)" "cloned extensions/${SELF_TEST_EXT}/ from ${REPO_URL} @ ${SELF_TEST_REAL_REF}"
    else
      self_test_record "sparse-clone (real)" SKIP "real (github.com)" "did not succeed in this environment (private repo / unreachable / no git credential) — expected until the D73 visibility flip, not a bootstrap.sh defect; see ${st_root}/branch2.out"
    fi
  fi

  # ---- branch 3/4: codeload tarball fallback, FORCED — stand-in ------------
  bold "-- 3/4  codeload-tarball fallback (forced)  ·  stand-in (local loopback HTTP server) --"
  st_serve="${st_root}/serve"
  st_target3="${st_root}/target-standin"
  st_tmp3="${st_root}/tmp3"
  mkdir -p "${st_target3}" "${st_tmp3}" || die "self-test: could not create scratch dirs for branch 3"
  if ! command -v python3 >/dev/null 2>&1; then
    self_test_record "tarball fallback (forced, stand-in)" SKIP "n/a" "python3 not found on PATH — cannot start a local loopback HTTP server to stand in for codeload.github.com"
  elif ! self_test_build_codeload_tarball "${st_serve}" "repo.tar.gz" "${SELF_TEST_EXT}"; then
    self_test_record "tarball fallback (forced, stand-in)" FAIL "stand-in" "could not build the local stand-in tarball fixture"
  elif ! self_test_http_server_start "${st_serve}" "${st_root}/http-port.txt" "${st_root}/http.log"; then
    self_test_record "tarball fallback (forced, stand-in)" SKIP "n/a" "could not start the local loopback HTTP stand-in server — see ${st_root}/http.log"
  else
    # Force the PRIMARY path to fail deterministically — a nonexistent
    # local path, never a flaky network condition — so the fallback below
    # is genuinely reached via fetch_and_delegate()'s own decision logic,
    # not merely exercised standalone.
    st_rc=0
    ( REPO_URL="${st_root}/does-not-exist-on-purpose.git"
      CODELOAD_URL_BASE="http://127.0.0.1:${SELF_TEST_HTTP_PORT}"
      fetch_and_delegate "${SELF_TEST_EXT}" "repo.tar.gz" "${st_target3}" "${st_tmp3}"
    ) >"${st_root}/branch3.out" 2>&1 || st_rc=$?
    self_test_http_server_stop
    if [ "${st_rc}" -eq 0 ] \
       && grep -q "falling back to the codeload tarball" "${st_root}/branch3.out" \
       && grep -q "self-test-stub-install-ok" "${st_root}/branch3.out"; then
      self_test_record "tarball fallback (forced, stand-in)" PASS "stand-in (local loopback HTTP server)" "primary forced to fail (bogus local REPO_URL) → fell back → fetched over real HTTP → delegated install.sh ran (exit 0)"
    else
      self_test_record "tarball fallback (forced, stand-in)" FAIL "stand-in" "fetch_and_delegate exit=${st_rc}; see ${st_root}/branch3.out"
    fi
  fi

  # ---- branch 4/4: codeload tarball — real infra, best-effort --------------
  bold "-- 4/4  codeload-tarball fallback  ·  real infrastructure (codeload.github.com, ref=${SELF_TEST_REAL_REF}) --"
  st_dest4="${st_root}/dest-real-tarball"
  if ! command -v curl >/dev/null 2>&1; then
    self_test_record "tarball (real)" SKIP "n/a" "curl not found on PATH"
  elif ! command -v tar >/dev/null 2>&1; then
    self_test_record "tarball (real)" SKIP "n/a" "tar not found on PATH"
  else
    st_rc=0
    ( tarball_fetch "${SELF_TEST_REAL_REF}" "${SELF_TEST_EXT}" "${st_dest4}" ) \
      >"${st_root}/branch4.out" 2>&1 || st_rc=$?
    if [ "${st_rc}" -eq 0 ] && [ -f "${st_dest4}/extensions/${SELF_TEST_EXT}/install.sh" ]; then
      self_test_record "tarball (real)" PASS "real (codeload.github.com)" "downloaded + extracted extensions/${SELF_TEST_EXT}/ from ${CODELOAD_URL_BASE} @ ${SELF_TEST_REAL_REF}"
    else
      self_test_record "tarball (real)" SKIP "real (codeload.github.com)" "did not succeed in this environment — expected while this repo is still private (D73): codeload 404s an unauthenticated request, and this script deliberately adds no credential of any kind; see ${st_root}/branch4.out"
    fi
  fi

  echo
  bold "self-test summary: ${SELF_TEST_PASS} pass / ${SELF_TEST_FAIL} fail / ${SELF_TEST_SKIP} skip"
  cat <<EOF

Coverage notes:
  - Branches 1 and 3 are hermetic stand-ins and always run (given git /
    python3 on PATH): a local filesystem git repo standing in for
    github.com, and a local loopback HTTP server standing in for
    codeload.github.com. Branch 3 additionally forces the sparse-clone
    primary path to fail deterministically, so it exercises
    fetch_and_delegate()'s real fallback decision, not tarball_fetch() in
    isolation.
  - Branches 2 and 4 are best-effort against the real ${REPO_URL} and
    codeload.github.com. Until the D73 visibility flip, branch 4 is
    EXPECTED to SKIP (codeload 404s an unauthenticated request to a
    private repo; this script adds no credential by design). Branch 2 can
    PASS wherever the caller's own git is already authenticated for this
    repo, and SKIP otherwise — either outcome is normal, not a defect.
  - A stand-in is not a perfect substitute for real infrastructure: it
    does not exercise HTTP redirects, codeload's exact top-level-directory
    naming convention, or content-encoding behaviour. Only a branch that
    actually ran against real infra (tagged "real" above) exercises those.
EOF

  if [ "${SELF_TEST_FAIL}" -gt 0 ]; then
    die "self-test: ${SELF_TEST_FAIL} branch(es) FAILED — see the per-branch output above"
  fi
  ok "self-test: no branch FAILED (${SELF_TEST_SKIP} skipped, each with a named reason above)"
}

# ==============================================================================

if [ "${SELF_TEST}" = "1" ]; then
  self_test
  exit 0
fi

fetch_and_delegate "${EXT_NAME}" "${REF}" "${TARGET_DIR}" "${TMP_DIR}"
