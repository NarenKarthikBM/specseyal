#!/usr/bin/env python3
"""profile_key.py -- the deck_render enum SSOT + a scoped profile.yaml validator.

This module is the single canonical source of truth for the deck-render
extension's closed enum ``{none, technical, overview, both}`` (exported below
as ``DECK_RENDER_ENUM``). Every contract doc that names this enum
(``profile-schema.md``, ``contracts/commands.md``) is asserted against THIS
export, never a re-typed copy (specs/006-deck-render T026).

It resolves and validates a feature's ``deck_render`` selection out of its
``profile.yaml`` per ``specs/006-deck-render/data-model.md`` Sec 1's V1-V5
rules, via exactly three resolution branches:

    1. ABSENT (profile.yaml missing, or present-and-parseable but naming no
       ``deck_render`` key) => resolves to ``'none'`` (render nothing).
       A silence.
    2. PRESENT BUT OUT-OF-ENUM (a value that is not one of the four
       literals -- including a mapping, a list, or empty) => hard failure:
       ``ProfileKeyError`` is raised (exit 3 at the CLI boundary). This
       NEVER falls back to ``'none'``.
    3. UNREADABLE / UNPARSEABLE YAML (bad YAML -- a merge-conflict marker, a
       stray tab) => hard failure: ``ProfileKeyError`` (exit 3). This is
       NEVER folded into branch 1 -- a corrupt file is a signal, not a
       silence, and routing it to the quieter 'none' outcome is exactly
       what SC-008 forbids.

Scope (research.md R4): this is a SCOPED validator. It checks the
``deck_render`` key ONLY. No general ``profile.yaml`` validator exists
anywhere in this repo -- the other keys (``full_auto``, ``gates.*``,
``council_tier``) are not touched here and remain exactly as unenforced as
they are today. This module does not (and must not) implement the V4
"explicit CLI argument overrides the profile" rule -- that override belongs
to ``render.py`` (T015); this module only resolves what the profile itself
says, and never blocks a caller that wants to override it.

Dependency posture -- stdlib-first, PyYAML discovered at RUNTIME: this file
has no hard import-time dependency on PyYAML and ships with no
requirements.txt. It first tries ``import yaml`` in the interpreter it is
already running under; if that interpreter lacks PyYAML, it walks the same
interpreter ladder ``extensions/deck-render/install.sh`` uses for its own
registry merge -- a `graphify`/`specify` shebang interpreter, then
`python3`, then `python`, then `uv run --with pyyaml python` -- and runs the
identical parse-and-classify logic out-of-process on whichever interpreter
is first found to have PyYAML importable. If NONE of those is reachable,
that is itself a loud failure (``ProfileKeyError``, exit 3), never a silent
`'none'` -- a validator that cannot parse YAML must not pretend the profile
said nothing.

Importable API:
    DECK_RENDER_ENUM      -- the closed-enum tuple, canonical order.
    DECK_RENDER_DEFAULT   -- 'none', the V1 default / absent-branch value.
    ProfileKeyError        -- raised for a branch-2/branch-3 hard failure.
    resolve_deck_render()  -- the three-branch resolver.

Standalone:
    python3 profile_key.py --validate-profile [--feature <dir> | <path>]
    Exit 0 = valid (including absent). Exit 3 = out-of-enum, or an
    unreadable/unparseable profile.yaml, or no YAML parser reachable.
"""

import argparse
import json
import os
import shutil
import subprocess
import sys

# --- the enum SSOT ----------------------------------------------------------

#: The closed enum for the `deck_render` profile.yaml key, in the canonical
#: order documented by data-model.md Sec 1. This tuple is the single source
#: of truth for the enum in this repo -- contract docs are asserted against
#: it (T026), never against a re-typed copy of these four literals.
DECK_RENDER_ENUM = ("none", "technical", "overview", "both")

#: V1's default: an absent profile, or a present-and-parseable profile with
#: no `deck_render` key, resolves to this value.
DECK_RENDER_DEFAULT = "none"

assert DECK_RENDER_DEFAULT in DECK_RENDER_ENUM


class ProfileKeyError(Exception):
    """A hard `deck_render` validation failure -- branch 2 or branch 3.

    Raised for an out-of-enum `deck_render` value, an unreadable or
    unparseable `profile.yaml`, or the loud failure of no reachable YAML
    parser. Callers (render.py / the --validate-profile CLI below) map this
    to exit code 3 per contracts/commands.md Sec 4. Never raised for an
    absent profile or an absent key -- those resolve to DECK_RENDER_DEFAULT
    instead (branch 1, V1).
    """


# --- the out-of-process probe script (mirrored logic, see _probe_yaml_inprocess) ---
#
# Run via `<interpreter> -c _YAML_PROBE_SCRIPT <path>` on a candidate
# interpreter discovered by the ladder below, only when the CURRENT
# interpreter lacks PyYAML. Emits exactly one line of JSON to stdout shaped
# like _probe_yaml_inprocess()'s return value, so both code paths feed the
# same _decide() logic downstream. Keep this in sync with
# _probe_yaml_inprocess if the classification rules ever change.
_YAML_PROBE_SCRIPT = r"""
import sys, os, json
try:
    import yaml
except Exception as exc:
    print(json.dumps({"status": "no_yaml_module", "error": str(exc)}))
    raise SystemExit(0)
path = sys.argv[1]
if not os.path.exists(path):
    print(json.dumps({"status": "missing"}))
    raise SystemExit(0)
try:
    with open(path, "r", encoding="utf-8") as fh:
        text = fh.read()
except OSError as exc:
    print(json.dumps({"status": "unreadable", "error": str(exc)}))
    raise SystemExit(0)
try:
    data = yaml.safe_load(text)
except Exception as exc:
    print(json.dumps({"status": "parse_error", "error": str(exc)}))
    raise SystemExit(0)
present = isinstance(data, dict) and "deck_render" in data
value_type = None
value = None
if present:
    raw = data["deck_render"]
    value_type = type(raw).__name__
    if isinstance(raw, str):
        value = raw
print(json.dumps({
    "status": "parsed",
    "present": present,
    "value_type": value_type,
    "value": value,
}))
"""


def _shebang_interpreter(cmd_name):
    """Return the #! interpreter path of a CLI found on PATH, or None.

    Mirrors extensions/deck-render/install.sh's shebang_python(): resolves
    e.g. `graphify` or `specify` on PATH to the (often venv-scoped) Python
    that installed them, which is where a repo's PyYAML is most likely to
    actually live.
    """
    resolved = shutil.which(cmd_name)
    if not resolved:
        return None
    try:
        with open(resolved, "r", encoding="utf-8", errors="ignore") as fh:
            first_line = fh.readline()
    except OSError:
        return None
    if not first_line.startswith("#!"):
        return None
    parts = first_line[2:].strip().split()
    return parts[0] if parts else None


def _candidate_interpreters():
    """The interpreter ladder, in try-order: graphify's, specify's, then
    generic python3/python. Mirrors install.sh's run_yaml_merge() ladder
    (shebang_python graphify, shebang_python specify, python3, python)
    minus the current interpreter (already tried before this ladder runs).
    """
    candidates = []
    for cmd in ("graphify", "specify"):
        interp = _shebang_interpreter(cmd)
        if interp:
            candidates.append(interp)
    candidates.extend(["python3", "python"])
    # de-dup, preserving first-seen order
    seen = []
    for c in candidates:
        if c not in seen:
            seen.append(c)
    return seen


def _interpreter_has_yaml(interp):
    try:
        result = subprocess.run(
            [interp, "-c", "import yaml"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=10,
        )
    except (OSError, subprocess.SubprocessError):
        return False
    return result.returncode == 0


def _run_probe_subprocess(argv):
    try:
        proc = subprocess.run(
            argv,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=30,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    if proc.returncode != 0 or not proc.stdout:
        return None
    try:
        # last non-empty line, in case the interpreter printed anything
        # else (e.g. a venv activation banner) ahead of our JSON.
        lines = [ln for ln in proc.stdout.decode("utf-8").splitlines() if ln.strip()]
        return json.loads(lines[-1]) if lines else None
    except (ValueError, IndexError):
        return None


def _probe_yaml_inprocess(path, yaml_module):
    """The same classification _YAML_PROBE_SCRIPT performs, run directly
    against a `yaml` module already imported in this process. Keep the two
    in sync -- see the comment above _YAML_PROBE_SCRIPT.
    """
    if not os.path.exists(path):
        return {"status": "missing"}
    try:
        with open(path, "r", encoding="utf-8") as fh:
            text = fh.read()
    except OSError as exc:
        return {"status": "unreadable", "error": str(exc)}
    try:
        data = yaml_module.safe_load(text)
    except Exception as exc:  # yaml.YAMLError and friends -- broad on purpose
        return {"status": "parse_error", "error": str(exc)}
    present = isinstance(data, dict) and "deck_render" in data
    value_type = None
    value = None
    if present:
        raw = data["deck_render"]
        value_type = type(raw).__name__
        if isinstance(raw, str):
            value = raw
    return {
        "status": "parsed",
        "present": present,
        "value_type": value_type,
        "value": value,
    }


def _probe_yaml(path):
    """Parse `path` as YAML and classify the `deck_render` key's
    presence/value. Never raises -- returns a status dict for _decide() to
    interpret. Tries the current interpreter's PyYAML first; only walks the
    interpreter ladder (see module docstring) when it is unavailable here.
    """
    try:
        import yaml as _yaml  # runtime-discovered, not a hard import-time dep
    except ImportError:
        _yaml = None

    if _yaml is not None:
        return _probe_yaml_inprocess(path, _yaml)

    for interp in _candidate_interpreters():
        if not _interpreter_has_yaml(interp):
            continue
        result = _run_probe_subprocess([interp, "-c", _YAML_PROBE_SCRIPT, path])
        if result is not None:
            return result

    if shutil.which("uv"):
        result = _run_probe_subprocess(
            ["uv", "run", "--quiet", "--with", "pyyaml", "python", "-c", _YAML_PROBE_SCRIPT, path]
        )
        if result is not None:
            return result

    return {
        "status": "no_yaml_module",
        "error": "no PyYAML-capable Python interpreter found (tried the current "
        "interpreter, graphify's/specify's shebang interpreter, python3, python, "
        "and `uv run --with pyyaml`)",
    }


def _decide(outcome, path):
    """Turn a _probe_yaml() outcome into the three-branch resolution.

    Returns a DECK_RENDER_ENUM member, or raises ProfileKeyError.
    """
    status = outcome["status"]

    if status == "missing":
        # V1: an absent profile.yaml resolves to the default. A silence.
        return DECK_RENDER_DEFAULT

    if status in ("unreadable", "parse_error"):
        # V5 / branch 3: an existing-but-broken profile is a signal, never
        # folded into the absent/'none' branch.
        raise ProfileKeyError(
            "profile.yaml at %r is unreadable or unparseable YAML (%s): %s"
            % (path, status, outcome.get("error", "unknown error"))
        )

    if status == "no_yaml_module":
        # The loud failure the module docstring promises: cannot validate
        # safely, so this must not be silently treated as 'none'.
        raise ProfileKeyError(
            "cannot validate deck_render at %r -- %s"
            % (path, outcome.get("error", "no YAML parser reachable"))
        )

    # status == "parsed"
    if not outcome["present"]:
        # V1: present-and-parseable but no `deck_render` key. A silence.
        return DECK_RENDER_DEFAULT

    value = outcome.get("value")
    value_type = outcome.get("value_type")
    if value_type == "str" and value in DECK_RENDER_ENUM:
        return value

    # V2/V3, branch 2: present but out-of-enum -- a non-string scalar, a
    # mapping, a list, empty (null), or a string outside the enum. Never
    # falls back to DECK_RENDER_DEFAULT.
    raise ProfileKeyError(
        "profile.yaml at %r has an out-of-enum deck_render value "
        "(type=%s, value=%r); must be one of %s"
        % (path, value_type, value, ", ".join(DECK_RENDER_ENUM))
    )


def _resolve_profile_path(feature_dir=None, profile_path=None):
    """The path this module reads -- NOT the feature-resolution ladder
    (--feature, else .specify/feature.json, else current branch) that
    render.py (T015) owns per contracts/commands.md Sec 2 step 1. This
    module only turns an already-resolved feature dir, or an explicit
    profile path, into the concrete profile.yaml to read; with neither
    given (standalone use), it falls back to ./profile.yaml.
    """
    if profile_path and feature_dir:
        raise ValueError("feature_dir and profile_path are mutually exclusive")
    if profile_path:
        return profile_path
    if feature_dir:
        return os.path.join(feature_dir, "profile.yaml")
    return os.path.join(os.getcwd(), "profile.yaml")


def resolve_deck_render(feature_dir=None, profile_path=None):
    """Resolve a feature's `deck_render` selection per V1-V5's three
    branches.

    Args:
        feature_dir: a feature directory containing profile.yaml. Mutually
            exclusive with profile_path.
        profile_path: an explicit path to a profile.yaml. Mutually
            exclusive with feature_dir.
        With neither given, resolves `./profile.yaml` (cwd) -- for
            standalone use only; render.py must pass one explicitly, since
            it owns the real feature-resolution ladder.

    Returns:
        One of DECK_RENDER_ENUM's four members.

    Raises:
        ProfileKeyError: an out-of-enum `deck_render` value (branch 2), an
            unreadable/unparseable profile.yaml (branch 3), or no YAML
            parser reachable anywhere (also branch 3 -- a loud failure).
            Never raised for an absent profile or an absent key (branch 1).
    """
    path = _resolve_profile_path(feature_dir=feature_dir, profile_path=profile_path)
    outcome = _probe_yaml(path)
    return _decide(outcome, path)


# --- standalone CLI ----------------------------------------------------------


def _build_arg_parser():
    parser = argparse.ArgumentParser(
        prog="profile_key.py",
        description="Resolve/validate a feature's deck_render profile.yaml key "
        "-- the deck-render extension's scoped, deck_render-only validator "
        "(not a general profile.yaml validator; see research.md R4).",
    )
    parser.add_argument(
        "--validate-profile",
        action="store_true",
        help="Validate the deck_render key and exit; renders nothing. "
        "Exit 0 = valid (including absent). Exit 3 = out-of-enum, or an "
        "unreadable/unparseable profile.yaml.",
    )
    parser.add_argument(
        "--feature",
        metavar="<dir>",
        default=None,
        help="Feature directory containing profile.yaml. Mutually exclusive "
        "with <profile-path>.",
    )
    parser.add_argument(
        "profile",
        nargs="?",
        default=None,
        metavar="<profile-path>",
        help="Explicit path to a profile.yaml. Mutually exclusive with --feature. "
        "Defaults to ./profile.yaml when neither is given.",
    )
    return parser


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    parser = _build_arg_parser()
    args = parser.parse_args(argv)

    if args.feature and args.profile:
        parser.error("--feature and <profile-path> are mutually exclusive")

    try:
        value = resolve_deck_render(feature_dir=args.feature, profile_path=args.profile)
    except ProfileKeyError as exc:
        print("deck_render: INVALID -- %s" % exc, file=sys.stderr)
        return 3

    print("deck_render: %s" % value)
    return 0


if __name__ == "__main__":
    sys.exit(main())
