#!/usr/bin/env sh
#
# speckit-ext-testing — CI test harness (R1-S03 / R1-S10 / R1-S19)
# Scripted, model-free tests for the testing extension's two contract-validated
# artifacts + its install/uninstall lifecycle. Mirrors extensions/git/test/run.sh's
# STYLE (PASS/FAIL counters, ok/bad/bold helpers, a throwaway temp root, the final
# `Result:` summary + `exit 1` on failure) — this extension does no AI work of its
# own to test (the `complete`/`testing` phases are model sessions, out of scope for
# a zero-AI harness); what IS testable mechanically is the two artifacts' contracts
# and the installer's file-system contract.
#
#   1. SC/FR coverage validator (R1-S03) — greps every SC-\d+/FR-\d+ id out of
#      spec.md (EXCLUDING any \d{3}- cross-feature reference, e.g. "001-FR-019" —
#      finding F4) and proves the exclusion is load-bearing (a naive grep
#      over-counts); asserts the real spec.md yields exactly 27 ids (10 SC + 17 FR).
#      Derives the two contracts' own golden section/field lists (R1-S19) so
#      sections 2/3 below never hand-copy a parallel list of their own.
#   2. Two-golden completion-report validation (R1-S10) — an appendix-bearing and
#      an appendix-free completion-report.md, each independently validated against
#      docs/contracts/completion-report.md; both pass (SC-005), plus negative
#      controls proving every §6 rule actually bites (bad status, a missing core
#      section, an illegal extra ## heading, an empty vs. a non-empty
#      Partial/Degraded body under status: partial).
#   3. Golden testing.md validation — a golden testing.md (27-row full coverage
#      map, one honest GAP) validated against docs/contracts/testing-doc.md,
#      reusing section 1's coverage checker end-to-end, plus negative controls
#      (a missing row — THE R1-S03 headline property — a stray row, a fabricated
#      "covered", a bad enum value, executed != none, a missing section).
#   4. install/uninstall round-trip — installs the extension into a throwaway
#      spec-kit fixture (git-ext pre-installed, so there is a realistic non-empty
#      pre-install .specify/extensions.yml to diff against — the 002 FR-014
#      byte-identical property is only a meaningful assertion against real prior
#      content, never an absent file); asserts payload + skills + `installed:
#      testing` land, then that uninstall restores extensions.yml byte-for-byte
#      and removes the payload + skills — nothing else touched.
#
# Runs entirely in throwaway dirs under a temp root; never touches this repo's own
# .specify/ or specs/. Usage:  sh extensions/testing/test/run.sh
#
set -eu

REPO="$(cd "$(dirname "$0")/../../.." && pwd)"          # repo root (…/specseyal)
TESTING_EXT="$REPO/extensions/testing"
GIT_EXT="$REPO/extensions/git"
CR_CONTRACT="$REPO/docs/contracts/completion-report.md"
TD_CONTRACT="$REPO/docs/contracts/testing-doc.md"
SPEC="$REPO/specs/004-testing-completion/spec.md"
FIXTURES="$TESTING_EXT/test/fixtures"
TMP="${TMPDIR:-/tmp}/speckit-testing-test.$$"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); printf '  \033[32mPASS\033[0m %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  \033[31mFAIL\033[0m %s\n' "$1"; }
bold() { printf '\n\033[1m%s\033[0m\n' "$1"; }

# ===========================================================================
# Shared helpers
# ===========================================================================

# extract_ids <file> -> stdout: every bare SC-\d+/FR-\d+ id, one per line,
# sorted+deduped, EXCLUDING any token immediately preceded by a \d{3}- prefix
# (a cross-feature reference, e.g. "001-FR-019" — finding F4). The single ERE
# below captures the OPTIONAL 3-digit prefix as part of the SAME token, never
# as a separate alternative, specifically so the match never depends on
# alternation-order semantics: greedily including the optional group is
# unambiguously the longer match at that position, so a first-match-wins
# engine and a leftmost-longest engine agree on what gets captured, and the
# second grep then drops every token that came out WITH a prefix attached.
extract_ids() {
  grep -oE '([0-9]{3}-)?(SC|FR)-[0-9]+' "$1" | grep -vE '^[0-9]{3}-' | sort -u
}

# bulleted_backticks <file> <start-regex> <end-regex> -> stdout: one item per
# line, for every `- \`...\`` bullet found strictly between a line matching
# <start-regex> and the next line matching <end-regex> — the shape both
# contracts use for their §2/§3 "greppable" heading/field lists (R1-S19).
# Unwraps the "- `" / "`" wrapper, leaving the raw heading or field text.
bulleted_backticks() {
  awk -v s="$2" -v e="$3" '
    $0 ~ s { grab = 1; next }
    grab && $0 ~ e { grab = 0 }
    grab && /^- `/ { print }
  ' "$1" | sed -E 's/^- `//; s/`$//'
}

# heading_glob <derived-heading-text> -> a shell case-glob pattern: the two
# placeholder tokens the completion-report contract's own §1 format names
# (`<name>`, `N/N`) become `*`; everything else in a derived heading is a
# literal, exact-match requirement. No regex escaping needed — `case` glob
# matching handles this natively and every literal heading here is free of
# glob metacharacters.
heading_glob() {
  printf '%s' "$1" | sed 's/<name>/*/; s#N/N#*#'
}

# section_nonempty <file> <exact-heading-line> -> exit 0 iff that heading is
# present AND carries at least one non-blank line before the next ##/###
# heading (or EOF). Literal-string heading match only (no placeholder).
section_nonempty() {
  awk -v h="$2" '
    $0 == h { grab = 1; next }
    grab && /^(## |### )/ { grab = 0 }
    grab && NF { found = 1 }
    END { exit !found }
  ' "$1"
}

# coverage_ids <testing.md> -> one id per line (trimmed), taken from the
# first column of every DATA row (header + separator rows excluded) in the
# '## Coverage map' table.
coverage_ids() {
  awk '
    /^## Coverage map[[:space:]]*$/ { grab = 1; next }
    grab && /^## / { grab = 0 }
    grab { print }
  ' "$1" \
    | grep '^|' \
    | grep -vE '^\|[-: |]+\|$' \
    | grep -viE '^\|[[:space:]]*id[[:space:]]*\|' \
    | awk -F'|' '{ v = $2; gsub(/^[ \t]+|[ \t]+$/, "", v); print v }'
}

# coverage_issues <testing.md> -> stdout: one line per bijection problem
# (a spec.md id with no row; a row whose id is not in spec.md; a duplicate
# row for the same id) against $TMP/spec_ids.txt (section 1). Silent + empty
# output means the coverage map is a clean, full bijection — the R1-S03
# headline check, and testing-doc.md §6 rule 3. Reused verbatim by section 3.
coverage_issues() {
  coverage_ids "$1" | sort > "$TMP/cis_have_raw.txt"
  sort -u "$TMP/cis_have_raw.txt" > "$TMP/cis_have.txt"
  cis_missing=$(comm -23 "$TMP/spec_ids.txt" "$TMP/cis_have.txt")
  cis_extra=$(comm -13 "$TMP/spec_ids.txt" "$TMP/cis_have.txt")
  cis_dupes=$(uniq -d "$TMP/cis_have_raw.txt")
  [ -z "$cis_missing" ] || printf 'MISSING row(s) for: %s\n' "$(printf '%s' "$cis_missing" | tr '\n' ' ')"
  [ -z "$cis_extra" ]   || printf 'STRAY row(s) for id(s) not in spec.md: %s\n' "$(printf '%s' "$cis_extra" | tr '\n' ' ')"
  [ -z "$cis_dupes" ]   || printf 'DUPLICATE row(s) for: %s\n' "$(printf '%s' "$cis_dupes" | tr '\n' ' ')"
}

# check_coverage_rows <testing.md> -> stdout: one line per row-level problem —
# an evidence-source/status value outside the contract's exact enum, or a
# `covered` row whose approach/grounding is a fabricated "—" (testing-doc.md
# §3/§6 rule 5, the "never relabeled covered" honesty rule).
check_coverage_rows() {
  awk '
    /^## Coverage map[[:space:]]*$/ { grab = 1; next }
    grab && /^## / { grab = 0 }
    grab { print }
  ' "$1" \
    | grep '^|' \
    | grep -vE '^\|[-: |]+\|$' \
    | grep -viE '^\|[[:space:]]*id[[:space:]]*\|' \
    | awk -F'|' '
      {
        id = $2; approach = $3; grounding = $4; evsrc = $5; status = $6
        gsub(/^[ \t]+|[ \t]+$/, "", id)
        gsub(/^[ \t]+|[ \t]+$/, "", approach)
        gsub(/^[ \t]+|[ \t]+$/, "", grounding)
        gsub(/^[ \t]+|[ \t]+$/, "", evsrc)
        gsub(/^[ \t]+|[ \t]+$/, "", status)
        st = status
        gsub(/\*/, "", st)
        if (evsrc != "—" && evsrc != "report-claimed" && evsrc != "log-verified")
          print id ": evidence-source not in {report-claimed, log-verified, em-dash}, got=" evsrc
        if (st != "covered" && st != "GAP")
          print id ": status not in {covered, GAP}, got=" st
        if (st == "covered" && (approach == "—" || grounding == "—"))
          print id ": status=covered but approach/grounding is em-dash (fabricated covered, rule 5)"
      }
    '
}

# validate_completion_report <file> -> stdout: a reason on failure (silent on
# success); return 0/1. Implements docs/contracts/completion-report.md §6
# rules 1,2,4,5,6 structurally (rule 3 falls out of the core-sequence
# presence check; rule 7 is "don't check the appendix", i.e. nothing to add).
validate_completion_report() {
  vcr_f="$1"
  [ -f "$vcr_f" ] || { printf 'file not found: %s\n' "$vcr_f"; return 1; }

  [ "$(sed -n '1p' "$vcr_f")" = "---" ] || { printf 'frontmatter does not open with ---\n'; return 1; }
  vcr_fm_end=$(awk 'NR>1 && /^---[[:space:]]*$/{print NR; exit}' "$vcr_f")
  [ -n "${vcr_fm_end:-}" ] || { printf 'no closing frontmatter delimiter\n'; return 1; }

  vcr_feature=$(sed -n "2,${vcr_fm_end}p" "$vcr_f" | sed -n 's/^feature:[[:space:]]*//p' | head -1 | sed 's/[[:space:]]*#.*$//; s/[[:space:]]*$//')
  vcr_phase=$(sed -n   "2,${vcr_fm_end}p" "$vcr_f" | sed -n 's/^phase:[[:space:]]*//p'   | head -1 | sed 's/[[:space:]]*#.*$//; s/[[:space:]]*$//')
  vcr_status=$(sed -n  "2,${vcr_fm_end}p" "$vcr_f" | sed -n 's/^status:[[:space:]]*//p'  | head -1 | sed 's/[[:space:]]*#.*$//; s/[[:space:]]*$//')

  [ -n "$vcr_feature" ] || { printf 'frontmatter missing feature\n'; return 1; }
  [ "$vcr_phase" = "complete" ] || { printf 'frontmatter phase != complete (got "%s")\n' "$vcr_phase"; return 1; }
  case "$vcr_status" in
    success|partial|failed) ;;
    *) printf 'frontmatter status not in {success,partial,failed} (got "%s")\n' "$vcr_status"; return 1 ;;
  esac

  tail -n "+$((vcr_fm_end+1))" "$vcr_f" | grep -E '^(## |### )' > "$TMP/vcr_headings.txt" || true
  vcr_total=$(wc -l < "$TMP/vcr_headings.txt" | tr -d ' ')
  if [ "$vcr_total" -lt 6 ]; then
    printf 'fewer than 6 top-level/second-level headings found in body (found %s)\n' "$vcr_total"
    return 1
  fi

  vcr_i=1
  while [ "$vcr_i" -le 6 ]; do
    vcr_core_h=$(sed -n "${vcr_i}p" "$TMP/core_headings.txt")
    vcr_actual=$(sed -n "${vcr_i}p" "$TMP/vcr_headings.txt")
    vcr_glob=$(heading_glob "$vcr_core_h")
    case "$vcr_actual" in
      $vcr_glob) ;;
      *) printf 'core section #%s: expected shape "%s", got "%s"\n' "$vcr_i" "$vcr_core_h" "$vcr_actual"; return 1 ;;
    esac
    vcr_i=$((vcr_i + 1))
  done

  vcr_i=7
  while [ "$vcr_i" -le "$vcr_total" ]; do
    vcr_actual=$(sed -n "${vcr_i}p" "$TMP/vcr_headings.txt")
    case "$vcr_actual" in
      "## "*)
        if ! grep -qxF "$vcr_actual" "$TMP/appendix_headings.txt"; then
          printf 'unexpected top-level (##) heading beyond core+appendix: "%s"\n' "$vcr_actual"
          return 1
        fi
        ;;
      *) : ;;   # a ###(+) heading inside the free-form appendix — unchecked (§6 rule 7)
    esac
    vcr_i=$((vcr_i + 1))
  done

  case "$vcr_status" in
    partial) section_nonempty "$vcr_f" '### Partial/Degraded' || { printf 'status: partial but "### Partial/Degraded" is empty\n'; return 1; } ;;
    failed)  section_nonempty "$vcr_f" '### Failed'           || { printf 'status: failed but "### Failed" is empty\n'; return 1; } ;;
  esac

  return 0
}

# validate_testing_doc <file> -> stdout: a reason on failure; return 0/1.
# Implements docs/contracts/testing-doc.md §6 rules 1,2,3,4,5,6 — rule 3 via
# coverage_issues() (the same R1-S03 checker section 1 exercises directly).
validate_testing_doc() {
  vtd_f="$1"
  [ -f "$vtd_f" ] || { printf 'file not found: %s\n' "$vtd_f"; return 1; }

  [ "$(sed -n '1p' "$vtd_f")" = "---" ] || { printf 'frontmatter does not open with ---\n'; return 1; }
  vtd_fm_end=$(awk 'NR>1 && /^---[[:space:]]*$/{print NR; exit}' "$vtd_f")
  [ -n "${vtd_fm_end:-}" ] || { printf 'no closing frontmatter delimiter\n'; return 1; }

  vtd_feature=$(sed -n  "2,${vtd_fm_end}p" "$vtd_f" | sed -n 's/^feature:[[:space:]]*//p'  | head -1 | sed 's/[[:space:]]*#.*$//; s/[[:space:]]*$//')
  vtd_phase=$(sed -n    "2,${vtd_fm_end}p" "$vtd_f" | sed -n 's/^phase:[[:space:]]*//p'    | head -1 | sed 's/[[:space:]]*#.*$//; s/[[:space:]]*$//')
  vtd_executed=$(sed -n "2,${vtd_fm_end}p" "$vtd_f" | sed -n 's/^executed:[[:space:]]*//p' | head -1 | sed 's/[[:space:]]*#.*$//; s/[[:space:]]*$//')

  [ -n "$vtd_feature" ] || { printf 'frontmatter missing feature\n'; return 1; }
  [ "$vtd_phase" = "testing" ] || { printf 'frontmatter phase != testing (got "%s")\n' "$vtd_phase"; return 1; }
  [ "$vtd_executed" = "none" ] || { printf 'frontmatter executed != none (got "%s")\n' "$vtd_executed"; return 1; }

  tail -n "+$((vtd_fm_end+1))" "$vtd_f" | grep -E '^## ' > "$TMP/vtd_headings.txt" || true
  vtd_total=$(wc -l < "$TMP/vtd_headings.txt" | tr -d ' ')
  vtd_req1=$(sed -n '1p' "$TMP/td_sections.txt")
  vtd_req2=$(sed -n '2p' "$TMP/td_sections.txt")
  vtd_h1=$(sed -n '1p' "$TMP/vtd_headings.txt")
  vtd_h2=$(sed -n '2p' "$TMP/vtd_headings.txt")

  [ "$vtd_h1" = "$vtd_req1" ] || { printf 'required section #1 mismatch: expected "%s", got "%s"\n' "$vtd_req1" "$vtd_h1"; return 1; }
  [ "$vtd_h2" = "$vtd_req2" ] || { printf 'required section #2 mismatch: expected "%s", got "%s"\n' "$vtd_req2" "$vtd_h2"; return 1; }
  [ "$vtd_total" = "2" ] || { printf 'found %s top-level (##) headings, expected exactly 2 (no appendix permitted, testing-doc.md §7)\n' "$vtd_total"; return 1; }

  vtd_issues=$(coverage_issues "$vtd_f")
  [ -z "$vtd_issues" ] || { printf 'coverage map: %s\n' "$vtd_issues"; return 1; }

  vtd_rowproblems=$(check_coverage_rows "$vtd_f")
  [ -z "$vtd_rowproblems" ] || { printf '%s\n' "$vtd_rowproblems"; return 1; }

  section_nonempty "$vtd_f" "$vtd_req2" || { printf '"%s" section is empty\n' "$vtd_req2"; return 1; }

  return 0
}

# assert_cr_valid/assert_cr_invalid — thin ok/bad wrappers around
# validate_completion_report so both a positive and a negative control read
# the same way section 2's PASS/BLOCK assertions do in the git harness.
assert_cr_valid() {
  acr_reason=$(validate_completion_report "$1") && acr_rc=0 || acr_rc=$?
  if [ "$acr_rc" -eq 0 ]; then ok "$2"; else bad "$2 -- $acr_reason"; fi
}
assert_cr_invalid() {
  acr_reason=$(validate_completion_report "$1") && acr_rc=0 || acr_rc=$?
  if [ "$acr_rc" -ne 0 ]; then
    case "$acr_reason" in
      *"$3"*) ok "$2 (correctly rejected: $acr_reason)" ;;
      *) bad "$2 -- rejected, but not for the expected reason [$3] -- got: $acr_reason" ;;
    esac
  else
    bad "$2 -- expected validate_completion_report to reject this, but it passed"
  fi
}

# assert_td_valid/assert_td_invalid — same idiom for validate_testing_doc.
assert_td_valid() {
  atd_reason=$(validate_testing_doc "$1") && atd_rc=0 || atd_rc=$?
  if [ "$atd_rc" -eq 0 ]; then ok "$2"; else bad "$2 -- $atd_reason"; fi
}
assert_td_invalid() {
  atd_reason=$(validate_testing_doc "$1") && atd_rc=0 || atd_rc=$?
  if [ "$atd_rc" -ne 0 ]; then
    case "$atd_reason" in
      *"$3"*) ok "$2 (correctly rejected: $atd_reason)" ;;
      *) bad "$2 -- rejected, but not for the expected reason [$3] -- got: $atd_reason" ;;
    esac
  else
    bad "$2 -- expected validate_testing_doc to reject this, but it passed"
  fi
}

# assert_coverage_clean/assert_coverage_catches — the coverage_issues()
# checker wrapped for a "must be clean" vs. "must catch a planted problem"
# assertion, mirroring the git harness's PASS-vs-BLOCK pairing.
assert_coverage_clean() {
  acc_issues=$(coverage_issues "$1")
  if [ -z "$acc_issues" ]; then
    ok "$2: Coverage map is a full 27-id bijection (no gap, no stray, no dupe)"
  else
    bad "$2: $acc_issues"
  fi
}
assert_coverage_catches() {
  acat_issues=$(coverage_issues "$1")
  if [ -z "$acat_issues" ]; then
    bad "$2 -- expected the coverage checker to catch a problem, but it reported none"
    return
  fi
  case "$acat_issues" in
    *"$3"*) ok "$2 (checker correctly flagged: $acat_issues)" ;;
    *) bad "$2 -- checker flagged something, but not the expected [$3] -- got: $acat_issues" ;;
  esac
}

# ===========================================================================
bold "1. SC/FR coverage validator (R1-S03 — validation FAILS on any gap)"

# --- 1a. unit-test the extraction/exclusion mechanism in isolation, so a
# future spec.md edit that happens to remove the 001-FR-019 hazard doesn't
# silently stop testing the exclusion logic itself. ------------------------
printf '%s\n' \
  'See FR-005 and also 001-FR-019 (a reference to another feature).' \
  'Also SC-002 and 042-SC-007 (another cross-feature reference).' \
  > "$TMP/unit_ids.md"
unit_out=$(extract_ids "$TMP/unit_ids.md")
unit_expected="$(printf 'FR-005\nSC-002')"
if [ "$unit_out" = "$unit_expected" ]; then
  ok "extract_ids() unit test: excludes NNN-prefixed cross-refs (001-FR-019, 042-SC-007), keeps bare ids"
else
  bad "extract_ids() unit test: expected 'FR-005 SC-002', got: $(printf '%s' "$unit_out" | tr '\n' ' ')"
fi

# --- 1b. confirm spec.md actually carries the hazard this exclusion guards
# against, so the count assertion below is not vacuously true. -------------
if grep -q '001-FR-019' "$SPEC"; then
  ok "spec.md carries the 001-FR-019 cross-feature reference (exclusion is exercised, not vacuous)"
else
  bad "spec.md no longer contains 001-FR-019 -- the exclusion-guard assertions below would be vacuous"
fi

# --- 1c. prove the fix matters: the naive regex (no NNN- exclusion)
# over-counts, introducing a phantom FR-019 that is not a real requirement
# in this spec (004's real range is FR-001..FR-017). -----------------------
naive_count=$(grep -oE '(SC|FR)-[0-9]+' "$SPEC" | sort -u | wc -l | tr -d ' ')
if [ "$naive_count" -gt 27 ]; then
  ok "naive extraction (no NNN- exclusion) over-counts at $naive_count ids -- confirms the exclusion is load-bearing"
else
  bad "naive extraction did not over-count (got $naive_count) -- the F4 hazard may no longer be present to guard against"
fi

# --- 1d. the real count: exactly 27 (10 SC + 17 FR). -----------------------
extract_ids "$SPEC" > "$TMP/spec_ids.txt"
n_ids=$(wc -l < "$TMP/spec_ids.txt" | tr -d ' ')
n_sc=$(grep -c '^SC-' "$TMP/spec_ids.txt" || true)
n_fr=$(grep -c '^FR-' "$TMP/spec_ids.txt" || true)
[ "$n_ids" = "27" ] && ok "extracted exactly 27 ids from spec.md (10 SC + 17 FR), 001-FR-019 cross-ref excluded" \
                     || bad "extracted $n_ids ids from spec.md, expected exactly 27"
[ "$n_sc" = "10" ]  && ok "...of which 10 are SC ids (SC-001..SC-010)" \
                     || bad "extracted $n_sc SC ids, expected 10"
[ "$n_fr" = "17" ]  && ok "...of which 17 are FR ids (FR-001..FR-017)" \
                     || bad "extracted $n_fr FR ids, expected 17"

# --- 1e. derive both contracts' own golden section/field lists (R1-S19) --
# — read straight out of docs/contracts/*.md at test time, never hand-copied
# into a parallel list here. Bounded by each file's own numbered §-headings.
bulleted_backticks "$CR_CONTRACT" '^## 2\. Core sections'      '^## 3\. Optional appendix'    > "$TMP/core_headings.txt"
bulleted_backticks "$CR_CONTRACT" '^## 3\. Optional appendix'   '^## 4\. Two contract files'   > "$TMP/appendix_headings.txt"
bulleted_backticks "$TD_CONTRACT" '^## 2\. Required sections'   '^## 3\. Coverage map'         > "$TMP/td_sections.txt"
bulleted_backticks "$TD_CONTRACT" '^## 3\. Coverage map'        '^## 4\. Verified by reading'  > "$TMP/td_fields.txt"

n=$(wc -l < "$TMP/core_headings.txt" | tr -d ' ')
[ "$n" = "6" ] && ok "derived exactly 6 core section headings from completion-report.md §2 (R1-S19)" \
               || bad "derived $n core headings from completion-report.md §2, expected 6"
n=$(wc -l < "$TMP/appendix_headings.txt" | tr -d ' ')
[ "$n" = "2" ] && ok "derived exactly 2 appendix headings from completion-report.md §3 (R1-S19)" \
               || bad "derived $n appendix headings from completion-report.md §3, expected 2"
n=$(wc -l < "$TMP/td_sections.txt" | tr -d ' ')
[ "$n" = "2" ] && ok "derived exactly 2 required section headings from testing-doc.md §2 (R1-S19)" \
               || bad "derived $n required sections from testing-doc.md §2, expected 2"
n=$(wc -l < "$TMP/td_fields.txt" | tr -d ' ')
[ "$n" = "5" ] && ok "derived exactly 5 coverage-row field names from testing-doc.md §3 (R1-S19)" \
               || bad "derived $n row fields from testing-doc.md §3, expected 5"

# check_coverage_rows() (below) hardcodes column positions ($2=id, $3=approach,
# $4=grounding, $5=evidence-source, $6=status) for speed rather than resolving
# them dynamically off td_fields.txt on every row — so this one extra
# assertion is the guard that keeps that hardcoding honest: if §3's field
# order in the contract ever changes, THIS fails loudly and points at the
# parser to update, rather than the row-checker silently mis-mapping columns.
td_fields_joined=$(tr '\n' ',' < "$TMP/td_fields.txt")
if [ "$td_fields_joined" = "id,approach,grounding,evidence-source,status," ]; then
  ok "derived field order matches this harness's row-parser assumption (id, approach, grounding, evidence-source, status)"
else
  bad "testing-doc.md §3's field order is now '$td_fields_joined' -- check_coverage_rows()'s hardcoded column mapping must be updated to match"
fi

# --- 1f. the headline property, exercised end-to-end against the golden
# testing.md (built in section 3) and a deliberately gapped variant -- proof
# that "FAILS on any gap" isn't merely asserted in prose. --------------------
assert_coverage_clean "$FIXTURES/testing.golden.md" "golden testing.md coverage map"
assert_coverage_catches "$FIXTURES/testing.gap.fixture.md" "gapped testing.md (FR-011 row missing entirely) correctly caught" "FR-011"

# ===========================================================================
bold "2. Two-golden completion-report validation (R1-S10, SC-005)"

assert_cr_valid "$FIXTURES/completion-report.appendix.golden.md"  "appendix-bearing golden validates (Milestone-close context + Decisions & log present)"
assert_cr_valid "$FIXTURES/completion-report.core-only.golden.md" "appendix-free golden validates identically (SC-005: no appendix, same core)"

# --- negative controls: prove §6's rules actually bite, not just that two
# hand-picked conforming documents happen to pass. --------------------------
CORE_GOLDEN="$FIXTURES/completion-report.core-only.golden.md"

sed 's/^status: success/status: done/' "$CORE_GOLDEN" > "$TMP/cr_bad_status.md"
assert_cr_invalid "$TMP/cr_bad_status.md" "bad status enum (status: done) rejected" "status"

awk '
  /^### Failed[[:space:]]*$/ { skip = 1; next }
  skip && /^(## |### )/ { skip = 0 }
  skip { next }
  { print }
' "$CORE_GOLDEN" > "$TMP/cr_missing_section.md"
assert_cr_invalid "$TMP/cr_missing_section.md" "missing core section (### Failed deleted entirely, heading count drops below 6) rejected" "fewer than 6"

sed 's/^### Failed$/### Failures/' "$CORE_GOLDEN" > "$TMP/cr_renamed_section.md"
assert_cr_invalid "$TMP/cr_renamed_section.md" "core section misspelled (### Failed -> ### Failures, count unchanged) rejected at its exact position" "core section #4"

{
  cat "$CORE_GOLDEN"
  printf '\n## Rogue Section\n\nThis heading is not permitted (rule 5).\n'
} > "$TMP/cr_illegal_heading.md"
assert_cr_invalid "$TMP/cr_illegal_heading.md" "illegal extra ## heading (## Rogue Section) rejected" "unexpected top-level"

awk '
  /^### Partial\/Degraded[[:space:]]*$/ { print; skip = 1; next }
  skip && /^(## |### )/ { skip = 0 }
  skip { next }
  { print }
' "$CORE_GOLDEN" > "$TMP/cr_step1.md"
sed 's/^status: success/status: partial/' "$TMP/cr_step1.md" > "$TMP/cr_empty_partial.md"
assert_cr_invalid "$TMP/cr_empty_partial.md" "status: partial with a truly-empty Partial/Degraded body rejected (rule 6)" "empty"

sed 's/^status: success/status: partial/' "$CORE_GOLDEN" > "$TMP/cr_partial_nonempty.md"
assert_cr_valid "$TMP/cr_partial_nonempty.md" "status: partial with a non-empty Partial/Degraded body ('None.') still validates (rule 6 boundary)"

# ===========================================================================
bold "3. Golden testing.md validation (docs/contracts/testing-doc.md §6)"

assert_td_valid "$FIXTURES/testing.golden.md" "golden testing.md validates (executed: none, both sections, 27-row bijection, one honest GAP)"

# --- reuse section 1's checker end-to-end against the full validator too --
assert_td_invalid "$FIXTURES/testing.gap.fixture.md" "gapped testing.md rejected by the full validator too" "MISSING row"

awk '
  /^\| FR-001 \|/ { print "| FR-001 | — | — | report-claimed | covered |"; next }
  { print }
' "$FIXTURES/testing.golden.md" > "$TMP/testing.fabricated.md"
assert_td_invalid "$TMP/testing.fabricated.md" "fabricated 'covered' (FR-001 approach/grounding blanked, status left covered) rejected" "fabricated covered"

verified_line=$(grep -n '^## Verified by reading' "$FIXTURES/testing.golden.md" | head -1 | cut -d: -f1)
{
  head -n "$((verified_line - 1))" "$FIXTURES/testing.golden.md"
  printf '| FR-999 | bogus verification approach | bogus grounding | report-claimed | covered |\n\n'
  tail -n "+${verified_line}" "$FIXTURES/testing.golden.md"
} > "$TMP/testing.stray.md"
assert_td_invalid "$TMP/testing.stray.md" "stray id (fabricated FR-999 row, not in spec.md) rejected" "STRAY row"

awk '
  /^\| FR-003 \|/ { print "| FR-003 | some approach text | `### Integration status` | report-claimed | done |"; next }
  { print }
' "$FIXTURES/testing.golden.md" > "$TMP/testing.bad_status_enum.md"
assert_td_invalid "$TMP/testing.bad_status_enum.md" "bad status enum value ('done' instead of covered/GAP) rejected" "status not in"

awk '
  /^\| FR-002 \|/ { print "| FR-002 | some approach text | `### Integration status` | maybe | covered |"; next }
  { print }
' "$FIXTURES/testing.golden.md" > "$TMP/testing.bad_evsrc_enum.md"
assert_td_invalid "$TMP/testing.bad_evsrc_enum.md" "bad evidence-source enum value ('maybe') rejected" "evidence-source not in"

sed 's/^executed: none/executed: partial/' "$FIXTURES/testing.golden.md" > "$TMP/testing.bad_executed.md"
assert_td_invalid "$TMP/testing.bad_executed.md" "executed != none rejected (FR-009/010 doc-only boundary)" "executed != none"

head -n "$((verified_line - 1))" "$FIXTURES/testing.golden.md" > "$TMP/testing.no_verified_section.md"
assert_td_invalid "$TMP/testing.no_verified_section.md" "missing '## Verified by reading...' section rejected" "required section #2"

# ===========================================================================
bold "4. install/uninstall round-trip (the 002 FR-014 byte-identical property)"

R4="$TMP/roundtrip"
mkdir -p "$R4/.specify"

# A realistic pre-existing extensions.yml baseline: git-ext already installed
# (the README's own quickstart order — "git-ext first"). This is what makes
# the byte-identical assertion below meaningful: an install/uninstall cycle
# starting from an ABSENT registry file would leave a freshly-scaffolded one
# behind (installed:[], settings:{...}, hooks:{} all get added on first
# write), not "no file" -- so the round-trip property needs real prior
# content to diff against, never a vacuous "nothing existed before either."
sh "$GIT_EXT/install.sh" "$R4" >/dev/null 2>&1

[ -f "$R4/.specify/extensions.yml" ] && ok "pre-install baseline: git-ext produced a real .specify/extensions.yml" \
                                      || bad "pre-install baseline: git-ext did not produce .specify/extensions.yml"

BASELINE="$TMP/extensions.yml.baseline"
cp "$R4/.specify/extensions.yml" "$BASELINE"
base_git_rows=$(grep -c 'extension: git' "$BASELINE" || true)

# --- install testing-ext ----------------------------------------------------
if sh "$TESTING_EXT/install.sh" "$R4" >/dev/null 2>&1; then ok "testing-ext install.sh exits 0"; else bad "testing-ext install.sh failed"; fi

[ -d "$R4/.specify/extensions/testing" ]                    && ok "payload landed at .specify/extensions/testing/"       || bad "payload missing after install"
[ -f "$R4/.specify/extensions/testing/extension.yml" ]      && ok "extension.yml present in installed payload"          || bad "extension.yml missing from installed payload"
[ -f "$R4/.specify/extensions/testing/testing-config.yml" ] && ok "testing-config.yml present in installed payload"     || bad "testing-config.yml missing from installed payload"

# Skill dirs are enumerated from the SOURCE tree at test time (whatever
# extension/skills/*/ currently provides), not hardcoded to a fixed pair —
# this is the same thing install.sh itself does, and it keeps the assertion
# correct regardless of how many command-skills the extension ships.
skill_names=$(ls "$TESTING_EXT/extension/skills" 2>/dev/null || true)
if [ -z "$skill_names" ]; then
  bad "extensions/testing/extension/skills/ has no skill directories to install"
else
  for s in $skill_names; do
    [ -d "$TESTING_EXT/extension/skills/$s" ] || continue
    [ -d "$R4/.claude/skills/$s" ] && ok "skill $s installed to .claude/skills/" || bad "skill $s NOT installed to .claude/skills/"
  done
fi

if grep -qE '^[[:space:]]*-[[:space:]]*testing[[:space:]]*$' "$R4/.specify/extensions.yml"; then
  ok "'installed: testing' registered in extensions.yml"
else
  bad "'testing' not found in extensions.yml's installed: list"
fi

after_install_git_rows=$(grep -c 'extension: git' "$R4/.specify/extensions.yml" || true)
[ "$base_git_rows" = "$after_install_git_rows" ] \
  && ok "git-ext's existing hook rows ($base_git_rows) untouched by testing's install (additive-only)" \
  || bad "git-ext's hook row count changed by testing install: was $base_git_rows, now $after_install_git_rows"

# --- uninstall testing-ext ---------------------------------------------------
if sh "$TESTING_EXT/uninstall.sh" "$R4" >/dev/null 2>&1; then ok "testing-ext uninstall.sh exits 0"; else bad "testing-ext uninstall.sh failed"; fi

[ ! -d "$R4/.specify/extensions/testing" ] && ok "payload removed after uninstall" || bad "payload still present after uninstall"

for s in $skill_names; do
  [ -d "$TESTING_EXT/extension/skills/$s" ] || continue
  [ ! -d "$R4/.claude/skills/$s" ] && ok "skill $s removed after uninstall" || bad "skill $s still present after uninstall"
done

if diff -q "$BASELINE" "$R4/.specify/extensions.yml" >/dev/null 2>&1; then
  ok "extensions.yml byte-identical to its pre-install baseline after uninstall (002 FR-014 round-trip)"
else
  bad "extensions.yml NOT byte-identical to its pre-install baseline -- diff: $(diff "$BASELINE" "$R4/.specify/extensions.yml" | head -20 | tr '\n' ' | ')"
fi

# ===========================================================================
bold "Result: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
