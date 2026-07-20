#!/usr/bin/env python3
"""check-conformance.py -- the whole-feature-directory contract checker
(I-11, T008/T009/T010).

Contracts implemented:
  - specs/008-pre-public-maintenance/contracts/conformance-checker-command.md
    (this file's own normative CLI/behavioral surface: C1-C9, the exit-code
    table, the both-branch fixture set)
  - specs/008-pre-public-maintenance/data-model.md E2/E3 (the checker's own
    entity + the docs/contracts/ schema set it enforces, direct vs.
    delegated)
  - docs/contracts/artifact-layout.md, decision-record.md,
    completion-report.md, testing-doc.md, trace-schema.md,
    agent-library-schema.md -- the SIX contracts this file checks DIRECTLY
    (see the `# T009:` markers below -- not yet implemented in this wave)
  - docs/contracts/profile-schema.md, taxonomy.md, skill-module.md -- the
    THREE contracts this file DELEGATES, never re-checks (below)

## What this tool is, and is not (Constitution)

This is a consumer/validator, not a pipeline phase: it reads an already-
written `specs/NNN-feature/` directory and prints a verdict. It writes no
pipeline artifact, mutates nothing, invokes no model, and appends no
`traces.jsonl` record -- the same zero-AI, zero-artifact posture as
`validate-profile.py` / `validate-categorization.py` / `validate-skill.py`
(principle I: it is a pure pass/fail over already-existing artifacts).

It is deliberately **detectable-on-demand** (R1-S14, plan.md), like
`/speckit-validate-profile` -- a maintainer or CI runs it explicitly. It is
NOT wired into any `before_*`/`after_*` hook: wiring an enforcement point
here would touch the gate/phase semantics this feature is required not to
alter (FR-015).

## Delegation, not duplication (C2/FR-008/R1-S22) -- READ THIS BEFORE EDITING

Three of the nine contracts this checker enforces (`profile-schema.md`,
`taxonomy.md`, `skill-module.md`) already have a dedicated, dependency-free
validator living beside this file: `validate-profile.py`,
`validate-categorization.py`, `validate-skill.py`. This file reaches every
one of them **by `subprocess` shell-out to the installed copy in this same
directory, and NEVER by a source-level `import`.** `extensions/workforce/
test/run.sh` (T011) adds a static guard that greps this file's source and
FAILs the build if it finds a source-level `import` of any of the three --
so this is not a style preference, it is a mechanically enforced build
constraint. Every delegate function below (`_delegate_validate_profile`,
`_delegate_validate_categorization`, `_delegate_validate_skill`) reaches its
sibling only via `_run_validator()`, which shells out and consumes stdout/
stderr/exit-code as plain data.

**Why a shell-out is the correct seam here, and why that is NOT a D57
citation (R1-S17):** D57 (`docs/90-DECISIONS-AND-IDEAS.md`) governs one
extension **patching** another's installer-overwritten SOURCE -- a `rm -rf`
+ `cp -R` reinstall silently wiping a foreign edit. That is not this case.
This file performs a **runtime READ** of a sibling validator's OUTPUT (its
exit code and stderr), never a write to or import of the sibling's source.
The plain rule that actually governs this seam is **"a read is not a
write"** -- a council correction (round 1, suggestion R1-S17) that
explicitly SHARPENED an earlier draft's D57 citation as inapt and had it
dropped. Cite R1-S17 / "a read is not a write" for this seam; do not
resurrect the D57 citation here.

## Exit codes (contract S2 / conformance-checker-command.md "Exit codes")

    0   CONFORMANT.     Every delegated check (profile.yaml, categorization.
        md, any generated skill) and every direct check (the six contracts
        above) passed. Silent on stderr; a single `<feature-dir>: OK` line
        on stdout.

    1   NONCONFORMANT.  One or more contract breaches. Always accompanied,
        on stderr, by one `<artifact> · <rule>` line per finding (the exact
        separator and shape `specs/008-pre-public-maintenance/fixtures/*/
        VIOLATION.md` pins) -- never an opaque Python traceback. This is a
        verdict ON the feature dir's artifacts, not on how this tool was
        invoked.

    2   USAGE error.    `<feature-dir>` is missing, does not exist, is not
        a directory, or the invocation is otherwise malformed (e.g. no
        argument at all -- argparse's own usage message, also exit 2).
        Deliberately DISTINCT from exit 1: a CI consumer must be able to
        tell "you called me wrong" from "the artifact tree is bad" without
        parsing stderr prose. Mirrors `validate-categorization.py`'s own
        1-vs-2 split exactly (content problem vs. invocation problem).

## Determinism (C6/FR-007, R1-S21)

Same input -> byte-identical output, every run. No timestamps, no wall-clock
reads, no dict/set iteration relied on for output order, no absolute paths
that vary by machine. Every collection this file iterates FOR OUTPUT is
sorted before printing (`ConformanceResult.render_lines()`); every
subprocess argv is a fixed, explicit list, never a shell-expanded glob
handed to a shell. `extensions/workforce/test/run.sh` (T011) asserts this
mechanically with a double-run byte-diff.

## Seams for follow-on tasks

T009 fills in the SIX `# T009:`-marked `check_*` functions below (currently
stubs returning `[]` -- every feature dir reads as conformant for these six
rules until T009 lands). T010 adds `_self_test()` at the `# T010:` marker
near the bottom of this file (not yet present). Neither is implemented in
this file as committed by T008.

## Usage

    check-conformance.py <feature-dir>
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path

__all__ = [
    "EXIT_CONFORMANT",
    "EXIT_NONCONFORMANT",
    "EXIT_USAGE",
    "Finding",
    "ConformanceResult",
    "emit_finding",
    "check_artifact_layout",
    "check_decision_record",
    "check_completion_report",
    "check_testing_doc",
    "check_trace_schema",
    "check_agent_library_schema",
    "check_feature_dir",
    "main",
]

# ---------------------------------------------------------------------------
# Exit codes -- contract S2 (see module docstring for the full meaning of
# each). Named constants, not bare literals, so a future revision touches
# one line (the same discipline `validate-profile.py`'s `EXIT_VALID`/
# `EXIT_INVALID` and `MAX_ROUNDS_REQUIRED` already follow).
# ---------------------------------------------------------------------------

EXIT_CONFORMANT = 0
EXIT_NONCONFORMANT = 1
EXIT_USAGE = 2

# ---------------------------------------------------------------------------
# Sibling validator locations -- resolved relative to THIS file's own
# directory, never guessed from a repo-root walk. <feature-dir> is not
# guaranteed to sit exactly two levels under a repo root (the both-branch
# fixtures this checker must pass live at
# specs/008-pre-public-maintenance/fixtures/<name>/, several directories
# deeper than a normal specs/NNN-feature/) -- but the three sibling
# validators are ALWAYS installed beside this file, by construction
# (extensions/workforce/extension/scripts/, the one directory this file's
# own graphify blast radius names). Resolving via __file__ is therefore the
# only anchor that is correct for every caller shape.
# ---------------------------------------------------------------------------

_SCRIPT_DIR = Path(__file__).resolve().parent
_VALIDATE_PROFILE = _SCRIPT_DIR / "validate-profile.py"
_VALIDATE_CATEGORIZATION = _SCRIPT_DIR / "validate-categorization.py"
_VALIDATE_SKILL = _SCRIPT_DIR / "validate-skill.py"

#: Generous headroom for validate-profile.py's own internal interpreter
#: ladder (up to ~4 candidate interpreters, each individually bounded, plus
#: its own `_UV_TIMEOUT_SECONDS = 8` final rung) -- this delegate must never
#: time out ahead of the sibling it is waiting on.
_DELEGATE_TIMEOUT_SECONDS = 120.0


# ---------------------------------------------------------------------------
# Findings -- the one shape every delegate and every (eventual) direct
# check reports through.
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class Finding:
    """One nonconformance. `artifact` is a feature-dir-relative path (or a
    `path:line` locator, e.g. `traces.jsonl:12`, per the trace-schema
    fixture's own convention); `rule` is `<contract-file>.md §N[ rule M]:
    <message>` -- the exact shape every VIOLATION.md under
    specs/008-pre-public-maintenance/fixtures/ pins as the "Expected checker
    message"."""

    artifact: str
    rule: str

    def render(self) -> str:
        # The exact separator (contract C5 / fixtures/README "shape:
        # <artifact> · <rule>") -- defined in exactly this one place.
        return f"{self.artifact} · {self.rule}"


@dataclass
class ConformanceResult:
    """The whole verdict for one feature dir. `ok` is the single bit
    `main()`'s exit code is derived from; `findings` is every breach found
    (delegated + direct), never just the first."""

    ok: bool
    findings: list[Finding] = field(default_factory=list)

    def render_lines(self) -> list[str]:
        """Sorted, deterministic rendering (Required behaviour #4/R1-S21) --
        never relies on the order checks happened to run in, or on set/dict
        iteration order."""
        return sorted(f.render() for f in self.findings)


def emit_finding(artifact: str, rule: str) -> Finding:
    """The single `<artifact> · <rule>` emission point (contract C5). Every
    delegate below, and every T009 `check_*` function to come, MUST route
    its findings through this helper (or construct a `Finding` with the
    same two fields directly) rather than hand-formatting a second string
    shape -- so the separator and field order are defined once, here."""
    return Finding(artifact=artifact, rule=rule)


# ---------------------------------------------------------------------------
# Subprocess plumbing -- the ONLY way this file ever reaches
# validate-profile.py / validate-categorization.py / validate-skill.py (see
# module docstring, "Delegation, not duplication"). Never raises: a launch
# failure, a timeout, or a nonzero exit all come back as data, never a
# traceback (the same "never an opaque fall-through" discipline
# validate-profile.py's own docstring names).
# ---------------------------------------------------------------------------


def _run_validator(cmd: list[str], *, timeout: float = _DELEGATE_TIMEOUT_SECONDS) -> tuple[int, list[str]]:
    """Run `cmd` (always `[sys.executable, <sibling script>, ...args]` --
    never a bare filename, so this works whether or not the sibling carries
    the executable bit) and return `(exit_code, stderr_lines)`. Never
    raises: a missing interpreter/script, a timeout, or any other launch
    failure is folded into a synthetic non-zero exit code plus a named
    message, exactly like every other failure mode this file reports."""
    try:
        proc = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout,
            text=True,
        )
    except FileNotFoundError as exc:
        return 127, [f"could not launch {cmd[0]!r}: {exc}"]
    except subprocess.TimeoutExpired:
        return 124, [f"timed out after {timeout:.0f}s: {' '.join(cmd)}"]
    except OSError as exc:
        return 1, [f"could not run {' '.join(cmd)}: {exc}"]

    stderr_lines = [ln for ln in proc.stderr.splitlines() if ln.strip()]
    return proc.returncode, stderr_lines


def _detail_from_stderr(stderr_lines: list[str]) -> str:
    """Reduce a delegated validator's stderr -- a header line plus one
    `  - <breach>` line per finding, the shape all three siblings in this
    directory share -- to one semicolon-joined detail string. Falls back to
    joining every non-empty line verbatim if none matches that bullet
    shape, so an unrecognized sibling output format still surfaces
    something rather than an empty, unhelpful detail."""
    bullets = [ln.strip()[2:].strip() for ln in stderr_lines if ln.strip().startswith("- ")]
    if bullets:
        return "; ".join(bullets)
    joined = "; ".join(ln.strip() for ln in stderr_lines if ln.strip())
    return joined or "no detail on stderr"


# ---------------------------------------------------------------------------
# Delegation layer (Required behaviour #2) -- the three existing per-
# artifact validators, shelled out to, never imported. Each delegate reads
# exactly the one artifact its sibling owns and is presence-conditional
# where the underlying artifact is not guaranteed to exist for every
# feature dir this checker may be pointed at (research.md: "the checker
# validates whatever feature dir it is pointed at", including features that
# have not reached every phase yet) -- an ABSENT artifact is not itself a
# delegate-level finding; only an artifact that is PRESENT and INVALID is.
# Whether a given artifact's absence is itself a violation is
# artifact-layout.md's own business (§7 rules 2/3, T009's
# `check_artifact_layout`), not this layer's.
# ---------------------------------------------------------------------------


def _delegate_validate_profile(feature_dir: Path) -> list[Finding]:
    """Delegate `profile.yaml` conformance to `validate-profile.py`
    (profile-schema.md, C2/FR-008). Always shells out -- never special-
    cases absence itself -- because `validate-profile.py` already treats an
    absent `profile.yaml` as VALID (its own P1 rule); duplicating that
    judgment here would be exactly the "re-checking their rules" C2
    forbids."""
    exit_code, stderr_lines = _run_validator(
        [sys.executable, str(_VALIDATE_PROFILE), "--feature", str(feature_dir)]
    )
    if exit_code == 0:
        return []
    return [
        emit_finding(
            "profile.yaml",
            f"profile-schema.md (validate-profile.py): {_detail_from_stderr(stderr_lines)}",
        )
    ]


def _delegate_validate_categorization(feature_dir: Path) -> list[Finding]:
    """Delegate `categorization.md` conformance to
    `validate-categorization.py` (taxonomy.md, C2/FR-008). Presence-
    conditional: an absent `categorization.md` (a feature that has not
    reached the categorize phase yet) is not flagged here."""
    categorization_path = feature_dir / "categorization.md"
    if not categorization_path.is_file():
        return []
    exit_code, stderr_lines = _run_validator(
        [sys.executable, str(_VALIDATE_CATEGORIZATION), str(categorization_path)]
    )
    if exit_code == 0:
        return []
    return [
        emit_finding(
            "categorization.md",
            f"taxonomy.md (validate-categorization.py): {_detail_from_stderr(stderr_lines)}",
        )
    ]


#: The one frontmatter scalar this file peeks at directly, for ROUTING only
#: (deciding whether a discovered SKILL.md is this feature's business to
#: shell out on at all) -- never a conformance judgment, which stays
#: entirely validate-skill.py's job below.
_ORIGIN_RE = re.compile(r"(?m)^\s*origin:\s*(\S+)\s*$")


def _skill_origin(skill_md_path: Path) -> str | None:
    """Best-effort read of a SKILL.md's own `specseyal.origin` scalar.
    Returns `None` on any read problem, which routes the caller to skip
    that file -- fail-open on DISCOVERY (skip what can't be read), fail-
    closed inside the delegated validator itself (where the real safety
    gate lives)."""
    try:
        text = skill_md_path.read_text(encoding="utf-8")
    except OSError:
        return None
    match = _ORIGIN_RE.search(text)
    return match.group(1) if match else None


def _feature_tag_universe(feature_dir: Path) -> list[str]:
    """Best-effort UNION of every `tags` cell in this feature's own
    `categorization.md` table. This is deliberately NOT a re-implementation
    of `validate-categorization.py`'s authoritative row model (that parse
    stays that file's own job, and this file's job is only to source a
    plausible "triggering task tags" argument for a generated skill's S04
    relevance check, below) -- it locates the `tags` column by its header
    text rather than a fixed index, since the categorization table's column
    count/order has already changed once across this repo's own history
    (`specs/000-sample/categorization.md`'s 5-column pre-`runtime_consumed`
    shape vs. the current 6-column `taxonomy.md` shape). Returns `[]` --
    fail-closed, matching validate-skill.py's own "no ambiguous case
    resolves to accept" posture -- when `categorization.md` is absent,
    unreadable, or carries no recognizable `tags` header."""
    categorization_path = feature_dir / "categorization.md"
    try:
        text = categorization_path.read_text(encoding="utf-8")
    except OSError:
        return []

    tags_col: int | None = None
    tags: set[str] = set()
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped.startswith("|"):
            continue
        cells = [c.strip() for c in stripped.strip("|").split("|")]
        if not cells or not cells[0]:
            continue
        if tags_col is None:
            headers = [c.strip("`").strip().lower() for c in cells]
            if "tags" in headers:
                tags_col = headers.index("tags")
            continue  # the header row itself is never a data row
        if set(cells[0]) <= {"-"}:
            continue  # the markdown `|---|---|...` separator row
        if tags_col >= len(cells):
            continue
        for token in re.split(r"[,\s]+", cells[tags_col]):
            token = token.strip("`").strip()
            if token and token != "-":
                tags.add(token)

    return sorted(tags)


def _delegate_validate_skill(feature_dir: Path) -> list[Finding]:
    """Delegate generated-skill conformance to `validate-skill.py`
    (skill-module.md, C2/FR-008/data-model.md E3 -- "generated skills",
    literally, not the whole library). Presence- and origin-conditional:

    - Discovery is scoped to `<feature-dir>/.claude/skills/*/SKILL.md` --
      the on-disk nesting `specs/000-sample/.claude/skills/` already
      carries, and the only anchor this checker's CLI (`<feature-dir>`
      alone, no separate library-dir argument) can resolve without
      guessing at a repo root (the fixture tree this checker must pass
      lives several directories deeper than `specs/NNN-feature/`, so
      "walk up N levels" is not a safe assumption).
    - Only `origin: generated` entries are checked. A `seed` skill (e.g.
      `specs/000-sample`'s own nested `refactor-discipline`, `origin:
      seed`) is library-wide, not authored BY this feature, and is out of
      scope by data-model.md E3's own "generated skills" wording.
    - "Triggering task tags" -- `validate-skill.py`'s own required third
      argument -- are sourced as the union of every tag in this feature's
      `categorization.md` (`_feature_tag_universe`), a documented
      simplification: the exact per-task join (which roster row actually
      injected this exact skill) lives in `agents/assignment.md` and is
      T009's `check_agent_library_schema` direct check's own parse, not
      duplicated here.

    No committed fixture exercises the "skills found" branch today
    (`specs/008-pre-public-maintenance/fixtures/README.md`: "validate-
    skill.py has nothing to check here, since this fixture ships no
    generated skills"; `specs/000-sample`'s own skill is `origin: seed`,
    also out of scope by the rule above) -- this function is exercised via
    its "nothing found" fast path by every fixture that exists today.
    """
    skills_dir = feature_dir / ".claude" / "skills"
    if not skills_dir.is_dir():
        return []

    triggering_tags = ",".join(_feature_tag_universe(feature_dir))
    findings: list[Finding] = []

    for skill_md in sorted(skills_dir.glob("*/SKILL.md")):
        if _skill_origin(skill_md) != "generated":
            continue
        exit_code, stderr_lines = _run_validator(
            [sys.executable, str(_VALIDATE_SKILL), str(skill_md), triggering_tags, str(skills_dir)]
        )
        if exit_code == 0:
            continue
        rel = skill_md.relative_to(feature_dir)
        findings.append(
            emit_finding(
                str(rel),
                f"skill-module.md (validate-skill.py): {_detail_from_stderr(stderr_lines)}",
            )
        )

    return findings


# ---------------------------------------------------------------------------
# Direct checks -- the six remaining docs/contracts/ schemas, checked
# without delegation (C3/FR-004, data-model.md E3). NOT YET IMPLEMENTED:
# T009 fills in each function body from the contract's own stated rules
# (FR-005 -- never from specs/000-sample's fixture shape). Each stub
# returns `[]` so `check_feature_dir()` below is fully wired and callable
# end-to-end today; every feature dir reads as conformant for these six
# rules until T009 lands.
# ---------------------------------------------------------------------------


# T009: docs/contracts/artifact-layout.md
def check_artifact_layout(feature_dir: Path) -> list[Finding]:
    """Required-artifact presence + layout paths (artifact-layout.md §1,
    §7 rules 1-4) -- e.g. `council/defense-deck/technical.md` must sit at
    exactly that nested path, not `council/technical.md`
    (violation-wrong-path/ fixture). MUST honor the D50 meta-feature rule-5
    carve-out (`^>\\s*\\*\\*Rule-5 exempt \\(meta-feature\\):` in the
    feature's own `spec.md`) as conformant, never as drift (C8/FR-006).
    Not yet implemented -- returns `[]`."""
    return []


# T009: docs/contracts/decision-record.md
def check_decision_record(feature_dir: Path) -> list[Finding]:
    """Required sections, in order, per decision-record.md §5's Sections
    table (`## Metadata`, `## Round N`, `## Human Gate`, `## Carried
    Constraints` -- the last always present, even if empty;
    violation-missing-section/ fixture). Not yet implemented -- returns
    `[]`."""
    return []


# T009: docs/contracts/completion-report.md
def check_completion_report(feature_dir: Path) -> list[Finding]:
    """Frontmatter `status` closed enum `{success, partial, failed}`
    (completion-report.md §6 rule 1; violation-bad-frontmatter/ fixture) +
    the six ordered core sections. Not yet implemented -- returns `[]`."""
    return []


# T009: docs/contracts/testing-doc.md
def check_testing_doc(feature_dir: Path) -> list[Finding]:
    """Frontmatter `executed` + the full `spec.md` SC/FR id <-> `##
    Coverage map` row bijection (testing-doc.md §6 rule 3;
    violation-coverage-gap/ fixture). Not yet implemented -- returns
    `[]`."""
    return []


# T009: docs/contracts/trace-schema.md
def check_trace_schema(feature_dir: Path) -> list[Finding]:
    """Every field present, per `traces.jsonl` line (trace-schema.md §7),
    including rule 4's `agent_id != null` iff `role == "implementer"`
    invariant (violation-bad-trace-line/ fixture, case 1). Also the sole
    committed pinning mechanism for the I-31 hardening
    (`hardening-invariants.md` H4.1 -- a gitignored/untracked sole output
    must record `artifact: null`, never the ignored path;
    violation-bad-trace-line/ fixture, case 2, R1-S03). Not yet implemented
    -- returns `[]`."""
    return []


# T009: docs/contracts/agent-library-schema.md
def check_agent_library_schema(feature_dir: Path) -> list[Finding]:
    """`agents/assignment.md` roster SHAPE only (data-model.md E3 /
    fixtures/README design note 5 -- not the base/skill library file
    formats, which stay delegate-or-untouched): the assembly cap of base +
    3 injected skills, maximum (§3 D40 Guardrails;
    violation-assembly-cap-exceeded/ fixture) and the §4 model-policy rule.
    Not yet implemented -- returns `[]`."""
    return []


# ---------------------------------------------------------------------------
# Orchestration
# ---------------------------------------------------------------------------


def check_feature_dir(feature_dir: Path) -> ConformanceResult:
    """Run every delegated check (profile/categorization/skill) and every
    direct check (the six `check_*` functions above) against `feature_dir`,
    and fold the results into one `ConformanceResult`. Never raises: every
    function this calls returns a plain list of `Finding`s, even on its own
    internal failure."""
    findings: list[Finding] = []

    findings += _delegate_validate_profile(feature_dir)
    findings += _delegate_validate_categorization(feature_dir)
    findings += _delegate_validate_skill(feature_dir)

    findings += check_artifact_layout(feature_dir)
    findings += check_decision_record(feature_dir)
    findings += check_completion_report(feature_dir)
    findings += check_testing_doc(feature_dir)
    findings += check_trace_schema(feature_dir)
    findings += check_agent_library_schema(feature_dir)

    return ConformanceResult(ok=not findings, findings=findings)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def _build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="check-conformance.py",
        description=(
            "Validate a specs/NNN-feature/ directory against the docs/contracts/ "
            "schema set. Delegates profile.yaml / categorization.md / any "
            "generated skill to the existing validate-{profile,categorization,"
            "skill}.py siblings by subprocess (never by import -- FR-008/R1-S22), "
            "and checks the remaining six contracts directly."
        ),
        epilog=(
            "Exit codes:\n"
            "  0  conformant -- every delegated and direct check passed.\n"
            "  1  nonconformant -- one or more contract breaches; each is named\n"
            "     on stderr as '<artifact> · <rule>' (one line per finding).\n"
            "  2  usage error -- <feature-dir> missing, nonexistent, not a\n"
            "     directory, or the invocation was otherwise malformed. NOT a\n"
            "     verdict on any feature dir's conformance.\n"
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "feature_dir",
        metavar="<feature-dir>",
        help="Path to a specs/NNN-feature/ directory to validate.",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    parser = _build_arg_parser()
    args = parser.parse_args(argv)  # a malformed invocation exits 2 here, on its own

    feature_dir = Path(args.feature_dir)

    # Usage error vs. conformance failure (Required behaviour #3): a
    # missing/nonexistent/non-directory <feature-dir> is a bad INVOCATION,
    # not a verdict on any artifact tree -- checked, and reported
    # distinctly, before any check runs (fail fast).
    if not feature_dir.exists():
        print(
            f"check-conformance.py: usage error: no such directory: {feature_dir}",
            file=sys.stderr,
        )
        return EXIT_USAGE
    if not feature_dir.is_dir():
        print(
            f"check-conformance.py: usage error: not a directory: {feature_dir}",
            file=sys.stderr,
        )
        return EXIT_USAGE

    result = check_feature_dir(feature_dir)

    if not result.ok:
        print(f"{feature_dir}: NONCONFORMANT", file=sys.stderr)
        for line in result.render_lines():
            print(f"  {line}", file=sys.stderr)
        return EXIT_NONCONFORMANT

    print(f"{feature_dir}: OK")
    return EXIT_CONFORMANT


# ---------------------------------------------------------------------------
# T010: the embedded `_self_test()` goes here (validate-profile.py's own
# `_self_test()`/`_write_fixture()` shape) -- asserting the contract section
# headers and field names this file's `check_*` functions parse still exist
# in each docs/contracts/*.md, per T010's brief (C9/R1-S19). Not present in
# this file as committed by T008; do not add a `--self-test` CLI flag ahead
# of it (a flag with no implemented behavior behind it is a promise this
# file cannot yet keep).
# ---------------------------------------------------------------------------


if __name__ == "__main__":
    raise SystemExit(main())
