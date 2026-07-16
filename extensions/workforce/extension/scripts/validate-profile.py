#!/usr/bin/env python3
"""validate-profile.py -- the general, dependency-free contract validator for
a feature's `profile.yaml` (T009).

Contracts implemented, verbatim:
  - docs/contracts/profile-schema.md v1.2   (the field/enum/handshake SSOT --
    S1 schema, S2 the full_auto handshake P1-P5, S3 field table + "unknown
    keys are a validation error, not a warning", S7 council_tier, S8
    deck_render)
  - specs/007-oss-docs/contracts/validate-profile.md (this validator's own
    normative external surface: CLI S1, exit-code S2, message S3, dependency/
    portability S4, FR-018 enum-consumption S5, test-coverage S6)
  - specs/007-oss-docs/data-model.md S3   (the full field/type/required/rule
    table this file's check_* functions implement one-for-one, plus the
    full_auto P1-P5 handshake table -- P1-P4 machine-enforced, P5 NOT
    enforced, human-reviewed per the contract)
  - specs/007-oss-docs/spec.md FR-013..019, SC-007..010

Like `validate-skill.py` and `validate-categorization.py`, this is a ZERO-AI,
zero-artifact gate: it writes nothing, ever (Principle I -- it is a pure
pass/fail on an already-existing `profile.yaml`, exactly like
`profile_key.py --validate-profile`). Unlike those two siblings, this file's
subject is plain YAML, not a frontmatter block or a markdown pipe-table, so
it does NOT import the shared `frontmatter.py` parser in this directory --
there is no frontmatter shape here to reuse a parser for. Its own dependency
posture instead mirrors `extensions/deck-render/extension/scripts/
profile_key.py`: no hard import-time dependency on PyYAML, no
`requirements.txt`, no vendored parser. PyYAML is discovered at RUNTIME via
the same interpreter ladder `profile_key.py` already walks -- the current
interpreter, then a `graphify`/`specify` shebang interpreter, then
`python3`/`python`, then `uv run --with pyyaml python` as a last, timeout-
bounded resort (Principle V: stdlib, no network as a *requirement*, no API
key -- `uv`'s own network fetch is an already-installed-tool's business, not
this script's, and is never assumed to succeed).

`profile_key.py` is a SCOPED validator: it checks the single `deck_render`
key and nothing else (its own docstring says so explicitly -- "no general
profile.yaml validator exists anywhere in this repo", the exact gap
profile-schema.md S8's honest-limit paragraph records and this file closes).
`profile_key.py` is NOT edited, imported, or otherwise depended on at
runtime by this file -- the interpreter-ladder *functions* below
(`_shebang_interpreter`, `_candidate_interpreters`, `_interpreter_has_yaml`,
`_run_probe_subprocess`, `_probe_yaml`, and the `_YAML_PROBE_SCRIPT` out-of-
process probe) are a self-contained MIRROR of that file's pattern, adapted to
return the full parsed document (every key, not just `deck_render`) rather
than a single-key classification -- a deliberate duplication, not an
oversight: this file ships standalone at
`.specify/extensions/workforce/scripts/validate-profile.py` too (this
contract's own "Home" line), and a cross-tree `sys.path` reach into a
sibling extension's scripts directory would make that installed copy fragile
in exactly the way FR-018's own note warns against for the enum constant
below.

FR-018 / contract S5 -- the `deck_render` enum:  `DECK_RENDER_ENUM` is held
here as a PINNED LOCAL CONSTANT, value-identical to
`profile_key.DECK_RENDER_ENUM`, and is NOT imported across the tree (a
committed equivalence test, authored separately per the contract, is what
guarantees the two never drift apart -- this file does not attempt to prove
that itself). This lets `validate-profile.py` catch an out-of-enum
`deck_render` at validate/author time -- earlier than `006`'s render-time-
only check -- closing the honest limit profile-schema.md S8 records, without
`profile_key.py` changing at all.

WHAT IS CHECKED (data-model.md S3, every row a hard FAIL, never a warning):

  - schema_version   present, string, value MUST equal "1.0" (a version
                      check, not presence-only)
  - feature          present, string, MUST equal the containing directory
                      name
  - full_auto        present, bool; participates in the P1-P4 handshake
  - council_tier     optional (default full); closed enum {full, standard}
  - deck_render      optional (default none); closed enum DECK_RENDER_ENUM
  - gates            present, a mapping
  - gates.council    present, a MAPPING (`council: human` scalar -> FAIL)
  - gates.council.mode        required; enum {human, auto}
  - gates.council.max_rounds  optional (default 1); MUST be 1 (reject > 1)
  - gates.council.reopen_tier optional (default auto); enum {auto,delta,full}
  - gates.workforce  present, a MAPPING
  - gates.workforce.mode      required; enum {human, auto}
  - any other key    unknown key -> FAIL, at EVERY nesting level (top-level,
                      gates, gates.council, gates.workforce -- recursive by
                      construction: every mapping this file descends into
                      gets its own check_unknown_keys() call against that
                      level's own closed key set)

The full_auto handshake (profile-schema.md S2, data-model.md S3):

  P1  absent file                              => VALID  (both gates human)
  P2  gates.council.mode: auto  requires full_auto: true            -- FAIL
  P3  full_auto: true  requires BOTH modes auto                     -- FAIL
  P4  gates.workforce.mode: auto alone, full_auto: false             -- VALID
                                          (must NOT be over-rejected)
  P5  full_auto: true requires a top-of-file "why" comment    -- NOT enforced
      here (profile-schema.md S2: "Not machine-enforced. Enforced by the
      person reviewing the diff.") -- deliberately absent from this file's
      check_* set, not an oversight.

EXIT CONTRACT (contract S2):

    0   VALID.    All rules pass, INCLUDING an absent profile.yaml (P1 --
        the safest posture, never the fastest one). Silent, or a single
        `<path>: OK` line on stdout.

    3   INVALID.  Any rule breach: an out-of-enum value, an unknown key, a
        missing required key, a scalar where a gate mapping is required,
        max_rounds != 1, feature != dir name, a P2/P3 handshake violation,
        unreadable/unparseable YAML, or no PyYAML-capable interpreter
        reachable anywhere. Always accompanied by a human-readable message
        on stderr naming the offending key/value (and, where apt, the
        allowed set) -- NEVER an opaque Python traceback, NEVER a silent
        fall-through to a "safe" default on a malformed value (contract S3 /
        SC-009's exact forbidden failure mode).

    2   USAGE error (argparse: e.g. --feature and a positional path both
        given). Not a verdict on any profile.yaml.

HOW THE "NEVER AN OPAQUE TRACEBACK" GUARANTEE IS REALIZED, mechanically:
`validate_profile_path()` is the only caller of `_load_profile_mapping()`
(and `main()` the only caller of `validate_profile_path()`); the sole
exception type either one is prepared to catch is `ProfileShapeError`, and
`_load_profile_mapping()` is the only function in this file that raises it,
always with a human-readable message already attached at the raise site --
there is no code path in this file that lets a raw `yaml.YAMLError`,
`OSError`, or any other unnamed exception propagate out of `main()`.

USAGE:

    validate-profile.py [--feature <dir> | <profile-path>]
    validate-profile.py --self-test         # inline self-test, no I/O outside tempfile

  `--feature <dir>` validates `<dir>/profile.yaml`; a positional path
  validates that exact file; neither validates `./profile.yaml`. `--feature`
  and a positional path are mutually exclusive (contract S1).
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path

__all__ = [
    "DECK_RENDER_ENUM",
    "DECK_RENDER_DEFAULT",
    "SCHEMA_VERSION_REQUIRED",
    "COUNCIL_TIER_ENUM",
    "COUNCIL_TIER_DEFAULT",
    "GATE_MODE_ENUM",
    "REOPEN_TIER_ENUM",
    "REOPEN_TIER_DEFAULT",
    "MAX_ROUNDS_REQUIRED",
    "TOP_LEVEL_KEYS",
    "GATES_KEYS",
    "COUNCIL_KEYS",
    "WORKFORCE_KEYS",
    "EXIT_VALID",
    "EXIT_INVALID",
    "ProfileShapeError",
    "ValidationResult",
    "check_unknown_keys",
    "check_schema_version",
    "check_feature",
    "check_full_auto",
    "check_council_tier",
    "check_deck_render",
    "check_gates_shape",
    "check_council_block",
    "check_workforce_block",
    "check_full_auto_handshake",
    "validate_profile_mapping",
    "validate_profile_path",
    "main",
]

# ---------------------------------------------------------------------------
# Constants -- docs/contracts/profile-schema.md v1.2 SS1/SS2/SS3/SS7/SS8
# ---------------------------------------------------------------------------

#: FR-018 / contract S5 -- pinned LOCAL constant, value-identical to
#: `extensions/deck-render/extension/scripts/profile_key.py`'s
#: `DECK_RENDER_ENUM`. Deliberately NOT a runtime cross-tree import (see the
#: module docstring); a committed equivalence test (authored separately) is
#: what guarantees this stays in sync.
DECK_RENDER_ENUM = ("none", "technical", "overview", "both")
DECK_RENDER_DEFAULT = "none"

#: profile-schema.md SS3: "Required. Bump on any breaking change to this
#: file." v1 accepts exactly this one value -- a value-check, not a
#: presence-only check (T009 brief).
SCHEMA_VERSION_REQUIRED = "1.0"

#: profile-schema.md SS7 (D56).
COUNCIL_TIER_ENUM = frozenset({"full", "standard"})
COUNCIL_TIER_DEFAULT = "full"

#: profile-schema.md SS1/SS3 -- both gates.council.mode and
#: gates.workforce.mode share this one enum.
GATE_MODE_ENUM = frozenset({"human", "auto"})

#: profile-schema.md SS3 (D14).
REOPEN_TIER_ENUM = frozenset({"auto", "delta", "full"})
REOPEN_TIER_DEFAULT = "auto"

#: profile-schema.md SS3 (D13): "v1 rejects anything but 1." Kept as a named
#: constant (not a bare literal `1` scattered through the checks) so a future
#: schema revision that relaxes this rule touches one line.
MAX_ROUNDS_REQUIRED = 1

#: The closed top-level key set. Anything else is an unknown-key FAIL
#: (profile-schema.md SS3: "Unknown keys are a validation error, not a
#: warning.").
TOP_LEVEL_KEYS = frozenset(
    {"schema_version", "feature", "full_auto", "council_tier", "deck_render", "gates"}
)
GATES_KEYS = frozenset({"council", "workforce"})
COUNCIL_KEYS = frozenset({"mode", "max_rounds", "reopen_tier"})
WORKFORCE_KEYS = frozenset({"mode"})

#: Contract S2 -- a single reserved non-zero exit code, mirroring
#: `profile_key.py`'s own `ProfileKeyError` -> exit 3 mapping.
EXIT_VALID = 0
EXIT_INVALID = 3

#: contract S4 -- the final `uv` rung's bound, so an offline host (or a
#: `uv` that would otherwise try a real network fetch) cannot hang this
#: validator. Short enough that a caller waiting on this script still gets a
#: prompt, loud, non-zero answer rather than an indefinite stall.
_UV_TIMEOUT_SECONDS = 8


class ProfileShapeError(Exception):
    """Raised when a profile.yaml's overall shape can't be established at
    all: unreadable/unparseable YAML, no PyYAML-capable interpreter reachable
    anywhere, or a document that parses but is not a mapping at the top
    level. Always carries a human-readable message naming the cause (contract
    S3) -- never left to a bare `yaml.YAMLError` or `OSError` to propagate.

    Deliberately NOT used for per-field content problems (a bad enum value,
    a non-mapping gate block, a handshake violation) -- those are collected
    as plain strings in `ValidationResult.errors` so a caller sees every
    breach in one pass, exactly like `validate-categorization.py`'s
    `CategorizationShapeError` / row-error split.
    """


@dataclass
class ValidationResult:
    """The whole verdict for one profile.yaml. `ok` is the single bit
    `main()`'s exit code is derived from; `errors` is every breach found
    (never just the first)."""

    ok: bool
    errors: list[str]


# ---------------------------------------------------------------------------
# Interpreter ladder + YAML probe -- mirrors profile_key.py's pattern (see
# module docstring for why this is a self-contained mirror, not an import).
# Adapted to return the FULL parsed document, not a single-key
# classification, since this validator checks every key, not just
# deck_render.
# ---------------------------------------------------------------------------

# Out-of-process probe: parses `sys.argv[1]` as YAML and emits exactly one
# line of JSON describing the outcome, so both the in-process and
# out-of-process code paths below feed the same status-dict shape into
# `_load_profile_mapping()`. Keep this in sync with `_probe_yaml_inprocess`
# if the classification rules ever change.
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
try:
    json.dumps(data)
except (TypeError, ValueError) as exc:
    print(json.dumps({
        "status": "parse_error",
        "error": "profile.yaml contains a value that cannot be represented "
                 "as JSON: %s" % exc,
    }))
    raise SystemExit(0)
print(json.dumps({"status": "parsed", "data": data}))
"""


def _shebang_interpreter(cmd_name: str) -> str | None:
    """Return the #! interpreter path of a CLI found on PATH, or None.

    Mirrors profile_key.py's own `_shebang_interpreter` / install.sh's
    `shebang_python()`: resolves e.g. `graphify` or `specify` on PATH to the
    (often venv-scoped) Python that installed them, which is where a repo's
    PyYAML is most likely to actually live.
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


def _candidate_interpreters() -> list[str]:
    """The interpreter ladder, in try-order: graphify's, specify's, then
    generic python3/python. Mirrors profile_key.py's own ladder (minus the
    current interpreter, already tried before this ladder runs)."""
    candidates: list[str] = []
    for cmd in ("graphify", "specify"):
        interp = _shebang_interpreter(cmd)
        if interp:
            candidates.append(interp)
    candidates.extend(["python3", "python"])
    seen: list[str] = []
    for c in candidates:
        if c not in seen:
            seen.append(c)
    return seen


def _interpreter_has_yaml(interp: str) -> bool:
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


def _run_probe_subprocess(argv: list[str], timeout: float = 30) -> dict | None:
    """Run `argv`, expecting one line of JSON on stdout (see
    `_YAML_PROBE_SCRIPT`). Returns None -- never raises -- on any failure,
    including a timeout, so a hung/misbehaving interpreter just falls
    through the ladder to the next rung (or the final loud failure) instead
    of crashing this script."""
    try:
        proc = subprocess.run(
            argv, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=timeout
        )
    except subprocess.TimeoutExpired:
        return None
    except (OSError, subprocess.SubprocessError):
        return None
    if proc.returncode != 0 or not proc.stdout:
        return None
    try:
        lines = [ln for ln in proc.stdout.decode("utf-8").splitlines() if ln.strip()]
        return json.loads(lines[-1]) if lines else None
    except (ValueError, IndexError):
        return None


def _probe_yaml_inprocess(path: str, yaml_module) -> dict:
    """The same classification `_YAML_PROBE_SCRIPT` performs, run directly
    against a `yaml` module already imported in this process."""
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
    try:
        json.dumps(data)
    except (TypeError, ValueError) as exc:
        return {
            "status": "parse_error",
            "error": f"profile.yaml contains a value that cannot be "
            f"represented as JSON: {exc}",
        }
    return {"status": "parsed", "data": data}


def _probe_yaml(path: str) -> dict:
    """Parse `path` as YAML and return a status dict for
    `_load_profile_mapping()` to interpret. Never raises. Tries the current
    interpreter's PyYAML first; only walks the interpreter ladder when it is
    unavailable here; only tries `uv` (bounded by `_UV_TIMEOUT_SECONDS`) as
    the last resort, after every named interpreter has been tried."""
    try:
        import yaml as _yaml  # runtime-discovered, not a hard import-time dep
    except ImportError:
        _yaml = None

    if _yaml is not None:
        return _probe_yaml_inprocess(path, _yaml)

    for interp in _candidate_interpreters():
        if not _interpreter_has_yaml(interp):
            continue
        result = _run_probe_subprocess([interp, "-c", _YAML_PROBE_SCRIPT, path], timeout=30)
        if result is not None:
            return result

    if shutil.which("uv"):
        result = _run_probe_subprocess(
            [
                "uv",
                "run",
                "--quiet",
                "--with",
                "pyyaml",
                "python",
                "-c",
                _YAML_PROBE_SCRIPT,
                path,
            ],
            timeout=_UV_TIMEOUT_SECONDS,
        )
        if result is not None:
            return result

    return {
        "status": "no_yaml_module",
        "error": "no PyYAML-capable Python interpreter found (tried the "
        "current interpreter, graphify's/specify's shebang interpreter, "
        f"python3, python, and `uv run --with pyyaml` bounded by a "
        f"{_UV_TIMEOUT_SECONDS}s timeout)",
    }


def _load_profile_mapping(path: str) -> dict | None:
    """Resolve `path` to a parsed top-level mapping, or `None` for an absent
    file (P1 -- the caller treats `None` as VALID). Raises
    `ProfileShapeError` -- always with a human-readable message -- for every
    other non-mapping outcome: unreadable/unparseable YAML, no PyYAML-
    capable interpreter reachable, or a document that parses to something
    other than a mapping (a list, a scalar, null)."""
    outcome = _probe_yaml(path)
    status = outcome["status"]

    if status == "missing":
        return None

    if status in ("unreadable", "parse_error"):
        raise ProfileShapeError(
            f"{path}: unreadable or unparseable YAML: "
            f"{outcome.get('error', 'unknown error')}"
        )

    if status == "no_yaml_module":
        raise ProfileShapeError(
            f"{path}: no PyYAML-capable interpreter reachable (tried "
            f"current, graphify/specify shebang, python3, python, uv): "
            f"{outcome.get('error', 'unknown error')}"
        )

    # status == "parsed"
    data = outcome.get("data")
    if not isinstance(data, dict):
        raise ProfileShapeError(
            f"{path}: must parse to a mapping at the top level, got "
            f"{type(data).__name__} ({data!r})"
        )
    return data


# ---------------------------------------------------------------------------
# Individual check groups -- data-model.md S3's field table, one function per
# row group. Each returns a list of violation strings (empty == that group
# passes), mirroring validate-skill.py / validate-categorization.py's shape.
# ---------------------------------------------------------------------------


def check_unknown_keys(mapping: dict, allowed: frozenset, where: str) -> list[str]:
    """Unknown key -> FAIL, at whichever nesting level `mapping`/`where`
    names (profile-schema.md SS3: "Unknown keys are a validation error, not
    a warning."). Called once per level this file descends into (top-level,
    gates, gates.council, gates.workforce) -- so a top-level AND a nested
    unknown key are both caught, independently, in the same pass."""
    errs: list[str] = []
    for key in mapping:
        if key not in allowed:
            full_key = f"{where}.{key}" if where else str(key)
            errs.append(
                f"unknown key {full_key!r} (unknown keys are an error, "
                "profile-schema.md SS3)"
            )
    return errs


def check_schema_version(mapping: dict) -> list[str]:
    if "schema_version" not in mapping:
        return [f"missing required key 'schema_version' (must be {SCHEMA_VERSION_REQUIRED!r})"]
    v = mapping["schema_version"]
    if not isinstance(v, str):
        return [f"schema_version must be a string, got {v!r} ({type(v).__name__})"]
    if v != SCHEMA_VERSION_REQUIRED:
        return [
            f"schema_version must be {SCHEMA_VERSION_REQUIRED!r}, got {v!r} "
            "(version mismatch)"
        ]
    return []


def check_feature(mapping: dict, feature_dir_name: str | None) -> list[str]:
    if "feature" not in mapping:
        return ["missing required key 'feature' (must equal the containing directory name)"]
    v = mapping["feature"]
    if not isinstance(v, str):
        return [f"feature must be a string, got {v!r} ({type(v).__name__})"]
    if feature_dir_name is not None and v != feature_dir_name:
        return [
            f"feature {v!r} must equal the directory name {feature_dir_name!r}"
        ]
    return []


def check_full_auto(mapping: dict) -> tuple[list[str], bool | None]:
    """Returns (violations, parsed_value). `parsed_value` is `None` when the
    key is missing/mistyped -- callers use that as a sentinel to skip the
    P2/P3 handshake rather than cascade a second, confusing error."""
    if "full_auto" not in mapping:
        return (["missing required key 'full_auto' (bool)"], None)
    v = mapping["full_auto"]
    if not isinstance(v, bool):
        return ([f"full_auto must be a boolean, got {v!r} ({type(v).__name__})"], None)
    return ([], v)


def check_council_tier(mapping: dict) -> list[str]:
    if "council_tier" not in mapping:
        return []  # optional, default full (T1)
    v = mapping["council_tier"]
    if not isinstance(v, str) or v not in COUNCIL_TIER_ENUM:
        return [f"council_tier {v!r} is not one of {sorted(COUNCIL_TIER_ENUM)}"]
    return []


def check_deck_render(mapping: dict) -> list[str]:
    if "deck_render" not in mapping:
        return []  # optional, default none (R1)
    v = mapping["deck_render"]
    if not isinstance(v, str) or v not in DECK_RENDER_ENUM:
        return [f"deck_render {v!r} is not one of {sorted(DECK_RENDER_ENUM)} (FR-018)"]
    return []


def _describe_non_mapping(v: object) -> str:
    kind = "list" if isinstance(v, list) else "scalar"
    return f"{kind} {v!r}"


def check_gates_shape(mapping: dict) -> tuple[list[str], dict | None, dict | None]:
    """Validates `gates` is present and a mapping, and that
    `gates.council`/`gates.workforce` are each present and a MAPPING (never
    a scalar -- `council: human` is the canonical FAIL example in the
    contract). Returns `(violations, council_mapping_or_None,
    workforce_mapping_or_None)`; a `None` sub-mapping signals the caller to
    skip that block's own field checks rather than raise on a malformed
    shape."""
    errs: list[str] = []

    if "gates" not in mapping:
        errs.append("missing required key 'gates' (mapping)")
        return errs, None, None

    gates = mapping["gates"]
    if not isinstance(gates, dict):
        errs.append(f"gates must be a mapping, got {_describe_non_mapping(gates)}")
        return errs, None, None

    errs += check_unknown_keys(gates, GATES_KEYS, "gates")

    council: dict | None = None
    if "council" not in gates:
        errs.append("missing required key 'gates.council' (mapping)")
    else:
        c = gates["council"]
        if not isinstance(c, dict):
            errs.append(f"gates.council must be a mapping, got {_describe_non_mapping(c)}")
        else:
            council = c

    workforce: dict | None = None
    if "workforce" not in gates:
        errs.append("missing required key 'gates.workforce' (mapping)")
    else:
        w = gates["workforce"]
        if not isinstance(w, dict):
            errs.append(f"gates.workforce must be a mapping, got {_describe_non_mapping(w)}")
        else:
            workforce = w

    return errs, council, workforce


def check_council_block(council: dict) -> tuple[list[str], str | None]:
    """Validates gates.council.{mode,max_rounds,reopen_tier} + unknown keys
    at this nesting level. Returns `(violations, mode_or_None)`."""
    errs: list[str] = []
    errs += check_unknown_keys(council, COUNCIL_KEYS, "gates.council")

    mode: str | None = None
    if "mode" not in council:
        errs.append("missing required key 'gates.council.mode'")
    else:
        raw_mode = council["mode"]
        if not isinstance(raw_mode, str) or raw_mode not in GATE_MODE_ENUM:
            errs.append(
                f"gates.council.mode {raw_mode!r} is not one of {sorted(GATE_MODE_ENUM)}"
            )
        else:
            mode = raw_mode

    if "max_rounds" in council:
        mr = council["max_rounds"]
        # bool is an int subclass in Python -- exclude explicitly, a bare
        # `True`/`False` is not a round count.
        if not isinstance(mr, int) or isinstance(mr, bool) or mr != MAX_ROUNDS_REQUIRED:
            errs.append(
                f"gates.council.max_rounds must be {MAX_ROUNDS_REQUIRED} (got {mr!r})"
            )

    if "reopen_tier" in council:
        rt = council["reopen_tier"]
        if not isinstance(rt, str) or rt not in REOPEN_TIER_ENUM:
            errs.append(
                f"gates.council.reopen_tier {rt!r} is not one of {sorted(REOPEN_TIER_ENUM)}"
            )

    return errs, mode


def check_workforce_block(workforce: dict) -> tuple[list[str], str | None]:
    """Validates gates.workforce.mode + unknown keys at this nesting level.
    Returns `(violations, mode_or_None)`."""
    errs: list[str] = []
    errs += check_unknown_keys(workforce, WORKFORCE_KEYS, "gates.workforce")

    mode: str | None = None
    if "mode" not in workforce:
        errs.append("missing required key 'gates.workforce.mode'")
    else:
        raw_mode = workforce["mode"]
        if not isinstance(raw_mode, str) or raw_mode not in GATE_MODE_ENUM:
            errs.append(
                f"gates.workforce.mode {raw_mode!r} is not one of {sorted(GATE_MODE_ENUM)}"
            )
        else:
            mode = raw_mode

    return errs, mode


def check_full_auto_handshake(
    full_auto: bool | None, council_mode: str | None, workforce_mode: str | None
) -> list[str]:
    """P2/P3 (profile-schema.md SS2). P4 requires no code: a
    `gates.workforce.mode: auto` with `full_auto: false` trips neither rule
    below, so it is valid by simply never being flagged -- "must not be
    over-rejected" is satisfied by absence of a check, not by a special
    case. P5 (the top-of-file 'why' comment) is NOT machine-enforced here,
    per the contract, and has no corresponding check.

    Skips entirely when any of the three inputs is `None` -- i.e. the
    underlying field already failed its own type/enum/presence check, which
    already reported the root cause; re-flagging the handshake on top of an
    already-broken field would be cascading noise, not a second, distinct
    diagnosis.
    """
    if full_auto is None or council_mode is None or workforce_mode is None:
        return []

    errs: list[str] = []

    if council_mode == "auto" and not full_auto:
        errs.append(
            "gates.council.mode: auto requires full_auto: true (P2, "
            "profile-schema.md SS2)"
        )

    if full_auto:
        offenders = []
        if council_mode != "auto":
            offenders.append(f"council.mode = {council_mode}")
        if workforce_mode != "auto":
            offenders.append(f"workforce.mode = {workforce_mode}")
        if offenders:
            errs.append(
                "full_auto: true requires both gates.council.mode and "
                "gates.workforce.mode = auto (" + ", ".join(offenders) + ") "
                "(P3, profile-schema.md SS2)"
            )

    return errs


# ---------------------------------------------------------------------------
# Orchestration
# ---------------------------------------------------------------------------


def validate_profile_mapping(mapping: dict, feature_dir_name: str | None) -> list[str]:
    """Run every check over an already-parsed top-level mapping and return
    the combined list of violations (empty == VALID). Never raises -- a
    malformed sub-mapping (e.g. `gates.council` as a scalar) is reported as
    a violation by `check_gates_shape` and simply skipped by the block-level
    checks below, rather than raising."""
    errs: list[str] = []

    errs += check_unknown_keys(mapping, TOP_LEVEL_KEYS, "")
    errs += check_schema_version(mapping)
    errs += check_feature(mapping, feature_dir_name)

    full_auto_errs, full_auto_val = check_full_auto(mapping)
    errs += full_auto_errs

    errs += check_council_tier(mapping)
    errs += check_deck_render(mapping)

    gates_errs, council, workforce = check_gates_shape(mapping)
    errs += gates_errs

    council_mode: str | None = None
    if council is not None:
        c_errs, council_mode = check_council_block(council)
        errs += c_errs

    workforce_mode: str | None = None
    if workforce is not None:
        w_errs, workforce_mode = check_workforce_block(workforce)
        errs += w_errs

    errs += check_full_auto_handshake(full_auto_val, council_mode, workforce_mode)

    return errs


def validate_profile_path(path: str | Path) -> ValidationResult:
    """Validate the profile.yaml at `path`. Never raises: an absent file is
    P1 (VALID); every other failure -- structural or field-level -- comes
    back as `ValidationResult(ok=False, errors=[...])`.

    `feature_dir_name` (the value `feature:` must equal) is derived from
    `path`'s own resolved parent directory name, so this works identically
    whichever of the three CLI forms produced `path` (--feature <dir>, an
    explicit <profile-path>, or the bare ./profile.yaml default) -- in every
    case the file's parent directory IS the feature directory.
    """
    path = Path(path)
    feature_dir_name = path.resolve().parent.name

    try:
        mapping = _load_profile_mapping(str(path))
    except ProfileShapeError as exc:
        return ValidationResult(ok=False, errors=[str(exc)])

    if mapping is None:
        return ValidationResult(ok=True, errors=[])  # P1

    errors = validate_profile_mapping(mapping, feature_dir_name)
    return ValidationResult(ok=not errors, errors=errors)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def _build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="validate-profile.py",
        description="Validate a feature's profile.yaml against the full "
        "docs/contracts/profile-schema.md contract (not scoped to "
        "deck_render alone -- see profile_key.py for that narrower check).",
    )
    parser.add_argument(
        "--feature",
        metavar="<dir>",
        default=None,
        help="Feature directory containing profile.yaml. Mutually exclusive "
        "with <profile-path>.",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run the embedded self-test (hermetic, tempfile-only) and exit.",
    )
    parser.add_argument(
        "profile",
        nargs="?",
        default=None,
        metavar="<profile-path>",
        help="Explicit path to a profile.yaml. Mutually exclusive with "
        "--feature. Defaults to ./profile.yaml when neither is given.",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    parser = _build_arg_parser()
    args = parser.parse_args(argv)

    if args.self_test:
        _self_test()
        return EXIT_VALID

    if args.feature and args.profile:
        parser.error("--feature and <profile-path> are mutually exclusive")

    if args.feature:
        path = Path(args.feature) / "profile.yaml"
    elif args.profile:
        path = Path(args.profile)
    else:
        path = Path.cwd() / "profile.yaml"

    result = validate_profile_path(path)

    if not result.ok:
        print(f"{path}: INVALID", file=sys.stderr)
        for err in result.errors:
            print(f"  - {err}", file=sys.stderr)
        return EXIT_INVALID

    if not path.exists():
        print(f"{path}: OK (absent -- resolves to both gates human, P1)")
    else:
        print(f"{path}: OK")
    return EXIT_VALID


# ---------------------------------------------------------------------------
# Inline self-test -- no repo-relative paths, so this script proves itself
# correct hermetically (via tempfile), mirroring validate-skill.py's own
# `_fixture_text()` / `_self_test()` pattern. The real repo fixtures
# (specs/000-sample/profile.yaml, specs/007-oss-docs/profile.yaml, a bad
# deck_render value) are checked separately, outside this function, per the
# T009 brief's own verification instructions -- this self-test stays
# hermetic on purpose.
# ---------------------------------------------------------------------------


def _fixture_text(
    *,
    feature: str = "fixture-feature",
    schema_version: str = '"1.0"',
    full_auto: str = "false",
    council_tier: str | None = None,
    deck_render: str | None = None,
    council_mode: str = "human",
    max_rounds: int | None = None,
    reopen_tier: str | None = None,
    workforce_mode: str = "human",
    extra_top_level: str = "",
    extra_council: str = "",
    council_block_override: str | None = None,
) -> str:
    """Build a profile.yaml text body. Every knob defaults to a conformant
    value; a caller overrides exactly the field(s) it wants to break. `None`
    for an optional field means "omit the key entirely" (exercises the
    field's own default), matching how the real committed profiles under
    `specs/*/profile.yaml` mostly omit `deck_render` (R1: absent => none).
    """
    lines = [
        f"schema_version: {schema_version}",
        f'feature: "{feature}"',
        f"full_auto: {full_auto}",
    ]
    if council_tier is not None:
        lines.append(f"council_tier: {council_tier}")
    if deck_render is not None:
        lines.append(f"deck_render: {deck_render}")
    if extra_top_level:
        lines.append(extra_top_level)

    lines.append("gates:")
    if council_block_override is not None:
        lines.append(council_block_override)
    else:
        lines.append("  council:")
        lines.append(f"    mode: {council_mode}")
        if max_rounds is not None:
            lines.append(f"    max_rounds: {max_rounds}")
        if reopen_tier is not None:
            lines.append(f"    reopen_tier: {reopen_tier}")
        if extra_council:
            lines.append(extra_council)
    lines.append("  workforce:")
    lines.append(f"    mode: {workforce_mode}")

    return "\n".join(lines) + "\n"


def _write_fixture(tmp_path: Path, feature_dir: str, text: str) -> Path:
    """Write `text` to `<tmp_path>/<feature_dir>/profile.yaml`, so the
    resulting path's own parent-directory name is `feature_dir` -- exactly
    what `check_feature`'s directory-name rule is checked against."""
    d = tmp_path / feature_dir
    d.mkdir(parents=True, exist_ok=True)
    p = d / "profile.yaml"
    p.write_text(text, encoding="utf-8")
    return p


def _self_test() -> None:
    with tempfile.TemporaryDirectory(prefix="validate-profile-selftest-") as tmp:
        tmp_path = Path(tmp)

        # 1. A fully conformant profile -> VALID.
        good = _write_fixture(
            tmp_path,
            "fixture-good",
            _fixture_text(
                feature="fixture-good",
                council_tier="full",
                deck_render="none",
                max_rounds=1,
                reopen_tier="auto",
            ),
        )
        result = validate_profile_path(good)
        assert result.ok, f"expected VALID, got violations: {result.errors}"

        # 2. council_tier: standrad (out-of-enum, misspelled) -> INVALID,
        #    named message.
        bad_tier = _write_fixture(
            tmp_path, "fixture-tier", _fixture_text(feature="fixture-tier", council_tier="standrad")
        )
        result = validate_profile_path(bad_tier)
        assert not result.ok, "expected INVALID for council_tier: standrad"
        assert any("council_tier" in e and "standrad" in e for e in result.errors), (
            f"expected a council_tier violation naming 'standrad', got: {result.errors}"
        )

        # 3. Unknown key at the TOP level -> INVALID, named message.
        bad_unknown_top = _write_fixture(
            tmp_path,
            "fixture-unk-top",
            _fixture_text(feature="fixture-unk-top", extra_top_level="sparkle_mode: true"),
        )
        result = validate_profile_path(bad_unknown_top)
        assert not result.ok, "expected INVALID for an unknown top-level key"
        assert any("sparkle_mode" in e for e in result.errors), (
            f"expected a violation naming 'sparkle_mode', got: {result.errors}"
        )

        # 4. Unknown key NESTED under gates.council -> INVALID, named
        #    message (proves the recursive per-level check, not just
        #    top-level).
        bad_unknown_nested = _write_fixture(
            tmp_path,
            "fixture-unk-nested",
            _fixture_text(feature="fixture-unk-nested", extra_council="    bogus_field: 1"),
        )
        result = validate_profile_path(bad_unknown_nested)
        assert not result.ok, "expected INVALID for an unknown gates.council key"
        assert any("bogus_field" in e and "gates.council" in e for e in result.errors), (
            f"expected a violation naming 'gates.council.bogus_field', got: {result.errors}"
        )

        # 5. gates.council as a bare scalar (`council: human`) -> INVALID.
        bad_scalar = _write_fixture(
            tmp_path,
            "fixture-scalar",
            _fixture_text(feature="fixture-scalar", council_block_override="  council: human"),
        )
        result = validate_profile_path(bad_scalar)
        assert not result.ok, "expected INVALID for gates.council as a scalar"
        assert any("gates.council" in e and "mapping" in e for e in result.errors), (
            f"expected a 'gates.council must be a mapping' violation, got: {result.errors}"
        )

        # 6. P2 -- gates.council.mode: auto with full_auto: false -> INVALID.
        bad_p2 = _write_fixture(
            tmp_path,
            "fixture-p2",
            _fixture_text(feature="fixture-p2", full_auto="false", council_mode="auto"),
        )
        result = validate_profile_path(bad_p2)
        assert not result.ok, "expected INVALID for P2 (council auto without full_auto)"
        assert any("P2" in e for e in result.errors), f"expected a P2 violation, got: {result.errors}"

        # 7. P3 -- full_auto: true with only council.mode auto (workforce
        #    stays human) -> INVALID.
        bad_p3 = _write_fixture(
            tmp_path,
            "fixture-p3",
            _fixture_text(
                feature="fixture-p3", full_auto="true", council_mode="auto", workforce_mode="human"
            ),
        )
        result = validate_profile_path(bad_p3)
        assert not result.ok, "expected INVALID for P3 (full_auto true, workforce still human)"
        assert any("P3" in e for e in result.errors), f"expected a P3 violation, got: {result.errors}"

        # 8. P4 -- gates.workforce.mode: auto ALONE, full_auto: false ->
        #    VALID. Must NOT be over-rejected.
        good_p4 = _write_fixture(
            tmp_path,
            "fixture-p4",
            _fixture_text(
                feature="fixture-p4", full_auto="false", council_mode="human", workforce_mode="auto"
            ),
        )
        result = validate_profile_path(good_p4)
        assert result.ok, f"expected VALID for P4 (must not over-reject), got: {result.errors}"

        # 9. max_rounds: 2 -> INVALID.
        bad_rounds = _write_fixture(
            tmp_path, "fixture-rounds", _fixture_text(feature="fixture-rounds", max_rounds=2)
        )
        result = validate_profile_path(bad_rounds)
        assert not result.ok, "expected INVALID for max_rounds: 2"
        assert any("max_rounds" in e and "2" in e for e in result.errors), (
            f"expected a max_rounds violation naming 2, got: {result.errors}"
        )

        # 10. feature != containing directory name -> INVALID.
        bad_feature = _write_fixture(
            tmp_path, "real-dir-name", _fixture_text(feature="wrong-name")
        )
        result = validate_profile_path(bad_feature)
        assert not result.ok, "expected INVALID for feature != directory name"
        assert any(
            "feature" in e and "wrong-name" in e and "real-dir-name" in e for e in result.errors
        ), f"expected a feature/dir-name mismatch violation, got: {result.errors}"

        # 11. Absent file -> VALID (P1).
        absent_dir = tmp_path / "fixture-absent"
        absent_dir.mkdir()
        result = validate_profile_path(absent_dir / "profile.yaml")
        assert result.ok, f"expected VALID for an absent profile.yaml (P1), got: {result.errors}"

        # 12. Out-of-enum deck_render -> INVALID (FR-018), and DECK_RENDER_ENUM
        #     itself pinned to the exact four-member contract enum.
        assert DECK_RENDER_ENUM == ("none", "technical", "overview", "both")
        bad_deck = _write_fixture(
            tmp_path, "fixture-deck", _fixture_text(feature="fixture-deck", deck_render="sparkle")
        )
        result = validate_profile_path(bad_deck)
        assert not result.ok, "expected INVALID for deck_render: sparkle"
        assert any("deck_render" in e and "sparkle" in e for e in result.errors), (
            f"expected a deck_render violation naming 'sparkle', got: {result.errors}"
        )

        # 13. Malformed YAML (a merge-conflict marker) -> INVALID, loud (never
        #     folded into the absent/P1 branch).
        conflict_dir = tmp_path / "fixture-conflict"
        conflict_dir.mkdir()
        conflict_path = conflict_dir / "profile.yaml"
        conflict_path.write_text(
            "<<<<<<< HEAD\nfeature: a\n=======\nfeature: b\n>>>>>>> branch\n",
            encoding="utf-8",
        )
        result = validate_profile_path(conflict_path)
        assert not result.ok, "expected INVALID for a merge-conflict-marker YAML file"
        assert any(
            "unparseable" in e.lower() or "unreadable" in e.lower() or "mapping" in e.lower()
            for e in result.errors
        ), f"expected a loud parse-failure violation, got: {result.errors}"

        # 14. schema_version value mismatch ("2.0") -> INVALID, ONE clear
        #     version-mismatch message (not folded into a generic type error).
        bad_version = _write_fixture(
            tmp_path, "fixture-version", _fixture_text(feature="fixture-version", schema_version='"2.0"')
        )
        result = validate_profile_path(bad_version)
        assert not result.ok, "expected INVALID for schema_version: 2.0"
        assert any("schema_version" in e and "2.0" in e for e in result.errors), (
            f"expected a schema_version mismatch violation, got: {result.errors}"
        )

    print(
        "validate-profile.py: self-check OK (14/14 fixtures behaved as "
        "expected: conformant, council_tier enum, top-level unknown key, "
        "nested unknown key, gate-as-scalar, P2, P3, P4, max_rounds, "
        "feature/dir mismatch, absent-file P1, deck_render enum, malformed "
        "YAML, schema_version mismatch)"
    )


if __name__ == "__main__":
    raise SystemExit(main())
