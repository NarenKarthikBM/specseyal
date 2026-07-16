#!/usr/bin/env bash
#
# scripts/check-oss-docs.sh
#
# Committed, standalone, re-runnable acceptance check for the Arm A OSS
# front-door docs (README.md, CONTRIBUTING.md, CODE_OF_CONDUCT.md,
# SECURITY.md, .github/). Not wired into CI — run it by hand:
#
#   bash scripts/check-oss-docs.sh
#
# Two checks, each bound to a success criterion from specs/007-oss-docs:
#
#   (a) I-REF   / SC-003 — every cited repo path, slash-command, and
#                          extension name resolves to something real.
#   (b) I-CLEAN / SC-004 — no machine-specific absolute paths or private
#                          data leaked into the docs.
#
# A naive `grep` for backticked tokens over-flags: it treats illustrative
# placeholders (`specs/NNN-feature/`), feature-relative artifact basenames
# (`plan.md`, which only ever lives under a feature dir), and slash-commands
# (`/speckit-specify`, `/status`) as if they were repo-root paths. This
# script classifies each cited token before deciding whether it needs to
# resolve, and where.
#
# Exit code: 0 when both checks are fully clean. Non-zero (1) the moment
# any broken reference or leak is found; every offender found is still
# reported (the script does not stop at the first failure).

set -u

# ---------------------------------------------------------------------------
# Locate the repo root so this script works regardless of invocation cwd.
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT" || { echo "FAIL: could not cd to repo root"; exit 1; }

DOCS="README.md CONTRIBUTING.md CODE_OF_CONDUCT.md SECURITY.md"
GH_DIR=".github"

fail_count=0

note_fail() {
  fail_count=$((fail_count + 1))
  echo "  FAIL: $1"
}

echo "check-oss-docs.sh — Arm A OSS front-door acceptance check"
echo "Scope: $DOCS $GH_DIR/"
echo ""

# ===========================================================================
# Check (a): I-REF / SC-003 — every citation resolves
# ===========================================================================
echo "== (a) I-REF / SC-003: citation resolution =="

# --- Pass 1: backticked tokens restricted to path-shaped characters --------
# (letters, digits, '.', '/', '-', '_'). This intentionally excludes
# multi-word prose spans in backticks, like commit-message examples
# (`plan(007-oss-docs): validate-profile design ...`) or angle-bracket
# templates (`<phase>(<id>): ...`) — those contain characters outside this
# set and never match, so they fall out of consideration for free rather
# than needing individual rules.
backtick_tokens="$(grep -rhoE '`[a-zA-Z0-9_./-]+`' $DOCS "$GH_DIR" 2>/dev/null \
  | tr -d '`' | sort -u)"

# --- Pass 2: slash-command tokens, independent of backticks ----------------
# Catches bare slash-commands inside fenced code blocks (e.g. the literal
# `/graphify` and `/speckit-specify` command lines in README.md's Quickstart
# fence, which are not individually backtick-wrapped) as well as the
# `/speckit-*` wildcard notation (which contains '*', outside pass 1's
# charset). The leading `(^|[^A-Za-z0-9_/])` guard means a slash preceded by
# a path/word character — e.g. the second slash in `extensions/graphify/` —
# is NOT mistaken for a command; only a slash at start-of-line or preceded
# by punctuation/whitespace/backtick counts.
slash_tokens="$(grep -rhoE '(^|[^A-Za-z0-9_/])/[A-Za-z][A-Za-z0-9_*-]*' $DOCS "$GH_DIR" 2>/dev/null \
  | grep -oE '/[A-Za-z][A-Za-z0-9_*-]*' | sort -u)"

# Union of anything that is a slash-command (from either pass), so it is
# handled once by the slash-command rules below and skipped by the generic
# path rules.
all_slash_tokens="$(printf '%s\n%s\n' "$backtick_tokens" "$slash_tokens" \
  | grep -E '^/[A-Za-z]' | sort -u)"

# Everything else from pass 1 that is not a slash-command goes through the
# generic path classification.
generic_tokens="$(printf '%s\n' "$backtick_tokens" | grep -vE '^/[A-Za-z]')"

# --- Classify slash-commands ------------------------------------------------
# /speckit-*   -> MUST resolve to .claude/skills/<name>/ (strip leading '/').
#                 The literal wildcard `/speckit-*` is a family reference:
#                 it passes if at least one .claude/skills/speckit-* exists.
# /graphify    -> resolves to the extension that provides it: assert
#                 extensions/graphify/ exists. (There is deliberately no
#                 .claude/skills/graphify/ — graphify is an upstream/global
#                 command; its in-repo home is the extension.)
# anything else beginning with '/' (e.g. /status) -> a Claude Code builtin.
#                 A docs feature cannot validate host builtins, so these are
#                 intentionally not flagged.
while IFS= read -r tok; do
  [ -z "$tok" ] && continue
  case "$tok" in
    /speckit-\*)
      if ! ls -d .claude/skills/speckit-* >/dev/null 2>&1; then
        note_fail "no .claude/skills/speckit-*/ directories exist (cited as \`$tok\`)"
      fi
      ;;
    /speckit-*)
      name="${tok#/}"
      if [ ! -d ".claude/skills/$name" ]; then
        note_fail "broken slash-command ref: $tok -> .claude/skills/$name/ does not exist"
      fi
      ;;
    /graphify)
      if [ ! -d "extensions/graphify" ]; then
        note_fail "broken slash-command ref: $tok -> extensions/graphify/ does not exist"
      fi
      ;;
    *)
      : # other slash-command (e.g. /status) — Claude Code builtin, not flagged
      ;;
  esac
done <<SLASH_EOF
$all_slash_tokens
SLASH_EOF

# --- Classify generic (non-slash-command) tokens ----------------------------
# Feature-relative artifact basenames: these only ever live under a feature
# dir (specs/NNN-feature/...), never at repo root. Resolved by asserting at
# least one match under specs/*/.
feature_relative_names="plan.md spec.md tasks.md research.md data-model.md quickstart.md council/ profile.yaml"

# Per-extension script basenames: same shape of problem — install.sh and
# uninstall.sh are cited generically (every extension ships one), never as a
# repo-root file. Resolved by asserting at least one match under extensions/*/.
extension_relative_names="install.sh uninstall.sh"

while IFS= read -r tok; do
  [ -z "$tok" ] && continue

  # Rule 1 — placeholder pattern: never a real path, always illustrative.
  case "$tok" in
    *NNN*|*'<'*|*'>'*) continue ;;
  esac

  # Rule 3 — feature-relative artifact basename -> resolve via specs/*/.
  is_feature_relative=0
  for name in $feature_relative_names; do
    if [ "$tok" = "$name" ]; then
      is_feature_relative=1
      break
    fi
  done
  if [ "$is_feature_relative" -eq 1 ]; then
    if ! ls -d specs/*/"$tok" >/dev/null 2>&1; then
      note_fail "feature-relative artifact never appears under specs/*/: $tok"
    fi
    continue
  fi

  # Extension-relative script basename -> resolve via extensions/*/.
  is_extension_relative=0
  for name in $extension_relative_names; do
    if [ "$tok" = "$name" ]; then
      is_extension_relative=1
      break
    fi
  done
  if [ "$is_extension_relative" -eq 1 ]; then
    if ! ls -d extensions/*/"$tok" >/dev/null 2>&1; then
      note_fail "extension-relative script never appears under extensions/*/: $tok"
    fi
    continue
  fi

  # Rule 4 — looks like a repo path (contains '/', or ends in a recognized
  # extension) -> must exist relative to repo root.
  case "$tok" in
    */*|*.md|*.py|*.yml|*.yaml|*.sh)
      if [ ! -e "$tok" ]; then
        note_fail "broken ref: $tok"
      fi
      ;;
    *)
      : # Rule 5 — bare word, not a path (e.g. `auto`, `council`, `main`) — skip.
      ;;
  esac
done <<GENERIC_EOF
$generic_tokens
GENERIC_EOF

if [ "$fail_count" -eq 0 ]; then
  echo "  PASS: every cited path/command/extension resolves"
fi

check_a_failures="$fail_count"

echo ""

# ===========================================================================
# Check (b): I-CLEAN / SC-004 — no machine-specific paths or private data
# ===========================================================================
echo "== (b) I-CLEAN / SC-004: no leaked absolute paths =="

leak_hits="$(grep -rnE '/Users/|/home/[a-z]' $DOCS "$GH_DIR" 2>/dev/null)"

if [ -n "$leak_hits" ]; then
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    note_fail "leaked machine-specific path: $line"
  done <<LEAK_EOF
$leak_hits
LEAK_EOF
else
  echo "  PASS: no /Users/... or /home/<user>... literal found"
fi

echo ""
echo "=========================================================="
if [ "$fail_count" -eq 0 ]; then
  echo "RESULT: PASS — 0 broken refs, 0 leaks"
  exit 0
else
  echo "RESULT: FAIL — $fail_count offender(s) named above"
  exit 1
fi
