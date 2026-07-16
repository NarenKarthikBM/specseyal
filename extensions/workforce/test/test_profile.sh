#!/usr/bin/env sh
#
# speckit-ext-workforce — validate-profile.py CODE-gate tests (T011)
#
# Zero-AI, CI-runnable, no model calls: this is the both-branch golden/
# regression harness for extension/scripts/validate-profile.py, the general
# profile.yaml contract validator (docs/contracts/profile-schema.md v1.2,
# specs/007-oss-docs/contracts/validate-profile.md,
# specs/007-oss-docs/data-model.md S3). Covers seven requirement classes:
#
#   1. FIXTURE VERDICTS -- every fixture under test/fixtures/profile/*.yaml
#      exits the code its OWN leading "# PASS ..." / "# FAIL ..." comment
#      names (4 PASS -> exit 0, 11 FAIL -> exit 3). The expected verdict is
#      read FROM the fixture, not duplicated as a second hardcoded list here
#      -- the fixture is the single source of truth (golden-fixture
#      discipline); a fixture and this harness can never silently drift
#      apart on what a given file is supposed to do. All 15 fixtures live in
#      a `profile/` directory, so `feature: "profile"` makes the directory-
#      name check pass for every fixture except feature-mismatch.yaml, which
#      deliberately uses a different value to isolate that one check.
#
#   2. SC-008 -- the real specs/000-sample/profile.yaml (M0's own committed
#      profile) passes: exit 0. A test finally reads the M0 fixture.
#
#   3. P1 -- an absent path exits 0 (both gates resolve to human, the
#      safest posture, never the fastest one).
#
#   4. R1-S10 -- stderr CONTENT, not just an exit code: out-of-enum.yaml's
#      stderr names the offending key (`council_tier`) AND the offending
#      value (`standrad`, the SC-009 typo class), and is asserted to NOT
#      contain a raw Python traceback (contract S3 / SC-009's exact
#      forbidden failure mode).
#
#   5. FR-018 / contract S5 -- enum equivalence: validate-profile.py pins
#      its own LOCAL DECK_RENDER_ENUM constant rather than importing
#      extensions/deck-render/extension/scripts/profile_key.py's (see that
#      file's own module docstring for why) -- so nothing in the tree
#      guarantees the two never drift apart except a committed test. This
#      section IS that test: it loads both modules independently (the
#      validator via importlib.util.spec_from_file_location, since its
#      filename has a hyphen and can't be `import`ed directly; profile_key
#      via a sys.path insert) and asserts their two enum tuples are equal
#      as sets AND by mutual membership, plus that both independently
#      reject the same out-of-enum value ("sparkle") via their own public
#      APIs (check_deck_render / resolve_deck_render).
#
#   6. R1-S09 -- no PyYAML-capable interpreter reachable anywhere -> a
#      LOUD non-zero exit with a message naming the missing-interpreter
#      cause, never a silent "valid" or "absent". See the long comment
#      immediately above the shim construction below for exactly how this
#      is forced deterministically (independent of what happens to be
#      installed on the machine running this harness). This mechanism is
#      NEW to this file -- no sibling harness (test_categorize.sh,
#      test_skill_builder.sh) needed it, since neither validates YAML.
#
#   7. R1-S18 / SC-010 -- a committed wall-clock timing assertion: a single
#      validator run over specs/000-sample/profile.yaml completes in under
#      2 seconds. macOS's `date` has no `%N` (sub-second) field, so timing
#      is done with Python's time.time() around a subprocess call rather
#      than `date +%s.%N`, and compared with `awk` (float-capable, POSIX,
#      always present) rather than shell integer arithmetic.
#
# Runs entirely against the frozen fixtures + a throwaway TMP dir; never
# touches the frozen fixtures, specs/000-sample/, or any file outside
# extensions/workforce/test/ and $TMPDIR. Writes nothing itself --
# validate-profile.py has no write-capable code path (module docstring:
# "this is a ZERO-AI, zero-artifact gate: it writes nothing, ever").
#
# Usage:  sh extensions/workforce/test/test_profile.sh
#
set -eu

REPO="$(cd "$(dirname "$0")/../../.." && pwd)"                 # repo root (…/specseyal)
WF="$REPO/extensions/workforce"
VALIDATE="$WF/extension/scripts/validate-profile.py"
FIX="$WF/test/fixtures/profile"
DECKKEY="$REPO/extensions/deck-render/extension/scripts/profile_key.py"
SAMPLE="$REPO/specs/000-sample/profile.yaml"

PY="${PYTHON:-python3}"

TMP="${TMPDIR:-/tmp}/speckit-profile-test.$$"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); printf '  \033[32mPASS\033[0m %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  \033[31mFAIL\033[0m %s\n' "$1"; }
bold() { printf '\n\033[1m%s\033[0m\n' "$1"; }

[ -f "$VALIDATE" ] || { echo "FATAL: validate-profile.py not found at $VALIDATE" >&2; exit 1; }
[ -d "$FIX" ]       || { echo "FATAL: fixtures dir not found at $FIX" >&2; exit 1; }
[ -f "$DECKKEY" ]   || { echo "FATAL: profile_key.py not found at $DECKKEY" >&2; exit 1; }
[ -f "$SAMPLE" ]    || { echo "FATAL: specs/000-sample/profile.yaml not found at $SAMPLE" >&2; exit 1; }

# ===========================================================================
bold "1. Fixture verdicts -- exit code matches each fixture's OWN leading '# PASS'/'# FAIL' comment"

fixture_count=0
for f in "$FIX"/*.yaml; do
  fixture_count=$((fixture_count+1))
  name=$(basename "$f")
  verdict=$(head -1 "$f" | sed -E -n 's/^# (PASS|FAIL).*/\1/p')
  case "$verdict" in
    PASS) expected=0 ;;
    FAIL) expected=3 ;;
    *)
      bad "$name: no leading '# PASS'/'# FAIL' verdict comment found (golden-fixture discipline violated)"
      continue
      ;;
  esac
  rc=0
  "$PY" "$VALIDATE" "$f" >"$TMP/fx.stdout" 2>"$TMP/fx.stderr" || rc=$?
  if [ "$rc" -eq "$expected" ]; then
    ok "$name: exit $rc matches its own '# $verdict' verdict"
  else
    bad "$name: exit $rc, expected $expected (fixture says '# $verdict'): $(cat "$TMP/fx.stderr")"
  fi
done
[ "$fixture_count" -eq 15 ] && ok "all 15 committed fixtures were exercised (4 PASS + 11 FAIL)" \
  || bad "expected 15 fixtures under $FIX, found $fixture_count"

# ===========================================================================
bold "2. SC-008 -- the real specs/000-sample/profile.yaml passes"

rc=0
"$PY" "$VALIDATE" "$SAMPLE" >"$TMP/sample.stdout" 2>"$TMP/sample.stderr" || rc=$?
if [ "$rc" -eq 0 ]; then
  ok "specs/000-sample/profile.yaml exits 0 (SC-008 -- a test finally reads the M0 fixture)"
else
  bad "specs/000-sample/profile.yaml exited $rc, expected 0: $(cat "$TMP/sample.stderr")"
fi

# ===========================================================================
bold "3. P1 -- an absent profile.yaml exits 0 (both gates resolve to human)"

ABSENT="$TMP/no-such-feature-dir/profile.yaml"
[ -e "$ABSENT" ] && { echo "FATAL: $ABSENT unexpectedly pre-exists" >&2; exit 1; }
rc=0
"$PY" "$VALIDATE" "$ABSENT" >"$TMP/absent.stdout" 2>"$TMP/absent.stderr" || rc=$?
if [ "$rc" -eq 0 ]; then
  ok "an absent path exits 0 (P1, profile-schema.md SS2)"
else
  bad "an absent path exited $rc, expected 0 (P1): $(cat "$TMP/absent.stderr")"
fi

# ===========================================================================
bold "4. R1-S10 -- stderr CONTENT on out-of-enum.yaml, never a raw traceback"

rc=0
"$PY" "$VALIDATE" "$FIX/out-of-enum.yaml" >"$TMP/oe.stdout" 2>"$TMP/oe.stderr" || rc=$?
if grep -qF -- 'council_tier' "$TMP/oe.stderr"; then
  ok "out-of-enum.yaml: stderr names the offending key ('council_tier')"
else
  bad "out-of-enum.yaml: stderr does not name 'council_tier': $(cat "$TMP/oe.stderr")"
fi
if grep -qF -- 'standrad' "$TMP/oe.stderr"; then
  ok "out-of-enum.yaml: stderr names the offending value ('standrad', SC-009 typo class)"
else
  bad "out-of-enum.yaml: stderr does not name 'standrad': $(cat "$TMP/oe.stderr")"
fi
if grep -qF -- 'Traceback (most recent call last)' "$TMP/oe.stderr"; then
  bad "out-of-enum.yaml: stderr contains a raw Python traceback (contract S3 forbids this)"
else
  ok "out-of-enum.yaml: stderr contains NO raw Python traceback (contract S3)"
fi

# ===========================================================================
bold "5. FR-018/S5 -- DECK_RENDER_ENUM equivalence with profile_key.py"

# validate-profile.py's filename has a hyphen, so it can't be `import`ed
# directly -- loaded via importlib.util.spec_from_file_location instead.
# profile_key.py has no such problem -- loaded via a plain sys.path insert.
# Both modules' public APIs (check_deck_render / resolve_deck_render) are
# then independently exercised against the SAME out-of-enum value
# ('sparkle') to prove the equivalence isn't just the two tuples matching
# by coincidence, but that both validators actually enforce it.
rc=0
"$PY" - "$VALIDATE" "$DECKKEY" >"$TMP/enum.stdout" 2>"$TMP/enum.stderr" <<'PYEOF' || rc=$?
import importlib.util
import sys
import tempfile
from pathlib import Path

validate_path, deckkey_path = sys.argv[1], sys.argv[2]

spec = importlib.util.spec_from_file_location("validate_profile_mod", validate_path)
vp = importlib.util.module_from_spec(spec)
# Register in sys.modules BEFORE exec_module: validate-profile.py uses
# @dataclass, whose 3.11+ implementation looks itself up via
# sys.modules[cls.__module__] to resolve type hints -- skipping this step
# raises an unrelated-looking AttributeError from inside dataclasses.py.
sys.modules["validate_profile_mod"] = vp
spec.loader.exec_module(vp)

sys.path.insert(0, str(Path(deckkey_path).parent))
import profile_key as pk  # noqa: E402

a = tuple(vp.DECK_RENDER_ENUM)
b = tuple(pk.DECK_RENDER_ENUM)

assert set(a) == set(b), f"enum sets differ: validate-profile={a!r} profile_key={b!r}"
for v in a:
    assert v in b, f"{v!r} is in validate-profile.DECK_RENDER_ENUM but missing from profile_key.DECK_RENDER_ENUM"
for v in b:
    assert v in a, f"{v!r} is in profile_key.DECK_RENDER_ENUM but missing from validate-profile.DECK_RENDER_ENUM"
assert "sparkle" not in a and "sparkle" not in b, "test assumption broken: 'sparkle' is already a member of an enum"

violations = vp.check_deck_render({"deck_render": "sparkle"})
assert violations, "validate-profile.check_deck_render did not flag 'sparkle' as a violation"
assert any("sparkle" in v for v in violations), f"violation does not name 'sparkle': {violations}"

with tempfile.TemporaryDirectory() as td:
    p = Path(td) / "profile.yaml"
    p.write_text("deck_render: sparkle\n", encoding="utf-8")
    rejected = False
    try:
        pk.resolve_deck_render(profile_path=str(p))
    except pk.ProfileKeyError as exc:
        rejected = True
        assert "sparkle" in str(exc), f"profile_key.ProfileKeyError does not name 'sparkle': {exc}"
    assert rejected, "profile_key.resolve_deck_render did not reject 'sparkle'"

print("FR-018-ENUM-EQUIVALENCE-OK")
PYEOF
if [ "$rc" -eq 0 ] && grep -qF -- 'FR-018-ENUM-EQUIVALENCE-OK' "$TMP/enum.stdout"; then
  ok "DECK_RENDER_ENUM is set-equal + mutual-membership-equal between validate-profile.py and profile_key.py"
  ok "both validators independently reject the SAME out-of-enum value ('sparkle') via their own public APIs"
else
  bad "enum-equivalence check failed (rc=$rc): $(cat "$TMP/enum.stdout" "$TMP/enum.stderr")"
fi

# ===========================================================================
bold "6. R1-S09 -- no PyYAML-capable interpreter reachable anywhere -> loud non-zero, named cause"

# validate-profile.py discovers PyYAML at RUNTIME via a ladder: the CURRENT
# interpreter first, then a graphify/specify shebang interpreter, then bare
# python3/python, then `uv run --with pyyaml` as a last resort (see the
# module's own docstring). To exercise "none of those has PyYAML"
# deterministically -- NOT relying on whatever happens to be installed on
# whichever machine runs this harness -- this section builds a throwaway
# PATH/interpreter-shadowing shim:
#
#   1. A "yaml-block" dir holding a stub yaml.py that unconditionally raises
#      ImportError. Placed first on PYTHONPATH, Python's own import order
#      (script dir, then PYTHONPATH, then stdlib/site-packages) means this
#      stub shadows ANY real PyYAML installed in site-packages, for ANY
#      interpreter that respects PYTHONPATH -- including the validator's
#      own running interpreter (invoked directly below, not through PATH).
#   2. A "shim-bin" dir holding ONLY python3/python wrapper scripts -- no
#      graphify/specify/uv stand-ins at all. Each wrapper execs the REAL
#      system python3 with that same PYTHONPATH shadow applied (inherited
#      automatically by any subprocess spawned with it set, but re-exported
#      explicitly here too for clarity), so the python3/python ladder rungs
#      ALSO fail to import yaml. This dir is set as the SOLE PATH for the
#      invocation below, so shutil.which("graphify")/("specify")/("uv")
#      all resolve to nothing -- those rungs are never even reached, not
#      just made to fail, and the ladder is exhausted down to its final,
#      loud failure branch.
SHIM="$TMP/no-yaml-shim"
YAMLBLOCK="$SHIM/site"
SHIMBIN="$SHIM/bin"
mkdir -p "$YAMLBLOCK" "$SHIMBIN"

cat > "$YAMLBLOCK/yaml.py" <<'PYEOF'
raise ImportError("yaml intentionally shadowed by test_profile.sh's no-interpreter shim (R1-S09)")
PYEOF

REAL_PY=$(command -v "$PY")

cat > "$SHIMBIN/python3" <<WRAPEOF
#!/bin/sh
# no-YAML shim wrapper (R1-S09, test_profile.sh) -- execs the REAL system
# python3 but with PYTHONPATH shadowed so 'import yaml' always fails here,
# regardless of what is actually installed on this host.
PYTHONPATH="$YAMLBLOCK:\${PYTHONPATH:-}"
export PYTHONPATH
exec "$REAL_PY" "\$@"
WRAPEOF
cp "$SHIMBIN/python3" "$SHIMBIN/python"
chmod +x "$SHIMBIN/python3" "$SHIMBIN/python"

rc=0
env PATH="$SHIMBIN" PYTHONPATH="$YAMLBLOCK" "$REAL_PY" "$VALIDATE" "$SAMPLE" \
  >"$TMP/noyaml.stdout" 2>"$TMP/noyaml.stderr" || rc=$?

if [ "$rc" -eq 3 ]; then
  ok "no-YAML shim over an otherwise-VALID profile: exits loudly non-zero (3), never a silent valid/absent"
else
  bad "no-YAML shim: exited $rc, expected 3 (loud failure): $(cat "$TMP/noyaml.stdout" "$TMP/noyaml.stderr")"
fi
if grep -qF -- 'no PyYAML-capable interpreter reachable' "$TMP/noyaml.stderr"; then
  ok "no-YAML shim: stderr names the missing-interpreter cause"
else
  bad "no-YAML shim: stderr missing the missing-interpreter message: $(cat "$TMP/noyaml.stderr")"
fi
if grep -qF -- 'Traceback (most recent call last)' "$TMP/noyaml.stderr"; then
  bad "no-YAML shim: stderr contains a raw Python traceback (should be a clean, caught message)"
else
  ok "no-YAML shim: stderr contains NO raw Python traceback"
fi

# ===========================================================================
bold "7. R1-S18/SC-010 -- a single validator run completes in under 2 seconds (wall clock)"

# macOS's `date` has no %N (sub-second) field, so timing uses Python's
# time.time() around a subprocess call instead of `date +%s.%N`; the
# resulting float is compared with `awk` (POSIX, float-capable) rather than
# shell integer arithmetic.
elapsed=$("$PY" - "$VALIDATE" "$SAMPLE" <<'PYEOF'
import subprocess
import sys
import time

validate_path, sample_path = sys.argv[1], sys.argv[2]
t0 = time.time()
subprocess.run(
    [sys.executable, validate_path, sample_path],
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL,
)
print("%.3f" % (time.time() - t0))
PYEOF
)
if awk "BEGIN { exit !($elapsed < 2.0) }"; then
  ok "single validator run over specs/000-sample/profile.yaml completed in ${elapsed}s (< 2s, SC-010)"
else
  bad "single validator run over specs/000-sample/profile.yaml took ${elapsed}s, expected < 2s (SC-010 breach)"
fi

# ===========================================================================
bold "Result: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
