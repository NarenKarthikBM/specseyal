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
import json
import re
import subprocess
import sys
from dataclasses import dataclass, field
from datetime import datetime
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


# ---------------------------------------------------------------------------
# Shared parsing/formatting helpers for the six T009 direct checks below.
# Every one of these is a line/regex-based reader over already-committed
# markdown/YAML/JSONL text -- Python 3 stdlib only, no PyYAML, mirroring the
# "line-based parsing for YAML-ish content" discipline this repo's other
# validators already follow. None of these ever raises on malformed input: a
# parse that can't find what it's looking for returns None/[] and the caller
# turns that into a Finding, never a traceback.
# ---------------------------------------------------------------------------

#: A level-1 or level-2 markdown heading line (`# ` or `## `, never `### `+
#: -- the leading-hash run is capped at exactly 1 or 2 by requiring
#: whitespace immediately after the captured hashes).
_HEADING12_RE = re.compile(r"(?m)^(#{1,2})\s+(.*)$")

#: A level-2 or level-3 heading (`## ` / `### `) -- completion-report.md and
#: testing-doc.md's own section grammar (core sections are `##`/`###`;
#: neither contract's core ever nests a `#### `).
_HEADING23_RE = re.compile(r"(?m)^(#{2,3})\s+(.*)$")


def _HEADING23_pairs(text: str) -> list[tuple[str, str]]:
    return [(m.group(1), m.group(2).strip()) for m in _HEADING23_RE.finditer(text)]


def _parse_frontmatter(text: str) -> dict[str, str] | None:
    """Best-effort line-based read of a `---`-delimited frontmatter block's
    top-level scalar keys (this repo's frontmatter blocks -- completion-
    report.md, testing.md -- are always flat `key: value`, never nested, so
    a full YAML parser is not needed here; PyYAML stays reserved for
    profile.yaml's own richer shape, delegated to validate-profile.py).
    Returns `None` when the text does not open with a `---` line or the
    closing `---` is never found -- the caller reports that as its own
    finding rather than this function raising."""
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return None
    end = None
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            end = i
            break
    if end is None:
        return None
    mapping: dict[str, str] = {}
    for line in lines[1:end]:
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or ":" not in stripped:
            continue
        key, _, value = stripped.partition(":")
        value = value.split(" #", 1)[0].strip()
        mapping[key.strip()] = value.strip("'\"")
    return mapping


def _section_body_h2(text: str, heading_title: str) -> str | None:
    """Body of the `## <heading_title>` section (exact match) up to the next
    `## ` heading or EOF. `None` when no such heading exists at all."""
    m = re.search(rf"(?m)^##\s+{re.escape(heading_title)}\s*$", text)
    if not m:
        return None
    rest = text[m.end():]
    nxt = re.search(r"(?m)^##\s+", rest)
    return rest[: nxt.start()] if nxt else rest


def _last_top_heading_body(text: str, heading_prefix: str) -> str | None:
    """Body of the LAST `## <heading_prefix>...` section (a *prefix* match,
    since gate headings carry a trailing timestamp, e.g. `## Human Gate --
    2026-07-08T15:40:02Z`) -- the R6/W3 "last one is authoritative" rule --
    up to the next `## ` heading or EOF. `None` when no such section exists
    at all."""
    matches = list(re.finditer(rf"(?m)^##\s+{re.escape(heading_prefix)}.*$", text))
    if not matches:
        return None
    rest = text[matches[-1].end():]
    nxt = re.search(r"(?m)^##\s+", rest)
    return rest[: nxt.start()] if nxt else rest


#: A gate section's `| decision | \`approved\` |` row (decision-record.md
#: §2, artifact-layout.md §8) -- shared by the council-gate and
#: workforce-gate readers below.
_GATE_DECISION_RE = re.compile(r"\|\s*decision\s*\|\s*`?([A-Za-z][A-Za-z-]*)`?\s*\|", re.IGNORECASE)


def _gate_decision(section_body: str) -> str | None:
    m = _GATE_DECISION_RE.search(section_body)
    return m.group(1) if m else None


def _gate_is_approved(feature_dir: Path, rel_path: str, heading_prefix: str) -> bool:
    """Whether `<feature_dir>/<rel_path>`'s LAST `## <heading_prefix>...`
    section records `decision: approved` or `approved-with-notes`. `False`
    whenever the file, the section, or a recognizable decision value is
    absent -- callers only reach this once they already know a downstream
    artifact exists and are asking whether the upstream gate cleared it."""
    path = feature_dir / rel_path
    if not path.is_file():
        return False
    body = _last_top_heading_body(path.read_text(encoding="utf-8", errors="replace"), heading_prefix)
    if body is None:
        return False
    return _gate_decision(body) in ("approved", "approved-with-notes")


def _read_gate_mode(profile_text: str, gate_name: str) -> str | None:
    """Best-effort, indentation-based read of `gates.<gate_name>.mode` out of
    a profile.yaml's raw text (`gate_name` is `"council"` or `"workforce"`).
    Deliberately NOT a YAML parse -- profile.yaml's *content* is
    validate-profile.py's business (C2); this reads exactly the one scalar
    artifact-layout.md §7 rule 3 needs to know, mirroring how
    `_delegate_validate_profile` never re-judges profile.yaml's own
    correctness. Returns `None` on any missing/malformed shape -- callers
    treat that as "not provably auto", the conservative branch (a profile
    this reader can't follow does not get to silently waive the gate)."""
    gates_indent: int | None = None
    target_indent: int | None = None
    in_target = False
    for raw_line in profile_text.splitlines():
        stripped = raw_line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        indent = len(raw_line) - len(raw_line.lstrip(" "))
        if gates_indent is None:
            if stripped == "gates:":
                gates_indent = indent
            continue
        if indent <= gates_indent:
            break  # left the gates: block without ever entering the target
        if not in_target:
            if stripped == f"{gate_name}:":
                in_target = True
                target_indent = indent
            continue
        if indent <= (target_indent or 0):
            break  # left the gates.<gate_name>: block without finding mode
        m = re.match(r"^mode:\s*(\S+)\s*$", stripped)
        if m:
            return m.group(1).strip("'\"")
    return None


#: The D50 meta-feature carve-out marker (artifact-layout.md §7 rule 5) --
#: a checker greps for exactly this line-start in the feature's own
#: `spec.md` and, if present, skips rule 5 for that feature alone.
_RULE5_EXEMPT_RE = re.compile(r"(?m)^>\s*\*\*Rule-5 exempt \(meta-feature\):")

#: Every `SC-###` / `FR-###` id token (testing-doc.md §3/§6 rule 3).
_ID_RE = re.compile(r"\b(?:FR|SC)-\d+\b")


def _pipe_table_rows(body: str, min_cells: int) -> list[list[str]]:
    """Every data row of the FIRST markdown pipe table in `body` (header row
    and the `|---|...|` separator row both skipped), each a list of
    stripped cell strings. Rows with fewer than `min_cells` cells are
    dropped rather than raising -- a malformed row is a validation finding
    for the caller to raise explicitly, not a crash here."""
    rows: list[list[str]] = []
    header_seen = False
    for line in body.splitlines():
        stripped = line.strip()
        if not stripped.startswith("|"):
            continue
        cells = [c.strip() for c in stripped.strip("|").split("|")]
        if not header_seen:
            header_seen = True
            continue
        if cells and set(cells[0]) <= {"-"}:
            continue  # the `|---|---|...` separator row
        if len(cells) < min_cells:
            continue
        rows.append(cells)
    return rows


#: The various "nothing here" spellings this repo's fixtures use in a table
#: cell -- treated as zero/absent, never as one entry.
_EMPTY_CELL = {"", "-", "—", "*(none)*", "(none)", "none"}


def _count_csv_cell(cell: str) -> int:
    """Count comma-separated entries in a table cell, treating `_EMPTY_CELL`
    spellings as zero."""
    stripped = cell.strip()
    if stripped in _EMPTY_CELL:
        return 0
    return len([p for p in stripped.split(",") if p.strip()])


#: `(type, specialization)` lane cell, e.g. `` `(scaffold, devtools-cli)` ``
#: (agent-library-schema.md §1.1 taxonomy block, rendered in
#: agents/assignment.md's own Roster table).
_LANE_RE = re.compile(r"\(\s*([a-z][a-z-]*)\s*,\s*([a-z][a-z-]*)\s*\)")


def _lane_type(cell: str) -> str | None:
    m = _LANE_RE.search(cell)
    return m.group(1) if m else None


#: taxonomy.md §3 -- the 7 implementation types (everything but `docs`) that
#: agent-library-schema.md §4 pins to `model: sonnet`.
_IMPLEMENTATION_TYPES = frozenset(
    {"scaffold", "data-model", "service", "endpoint", "ui", "test", "infra"}
)

#: agent-library-schema.md §3 D40 Guardrails -- "Assembly cap: base + 3
#: injected skills, maximum."
_ASSEMBLY_CAP = 3


def _git_repo_root(start: Path) -> Path | None:
    """`git -C <start> rev-parse --show-toplevel`, or `None` on any failure
    (no git binary, `start` outside a work tree, ...) -- never raises. Used
    only by the trace-schema check's I-31/H4.1 gitignored-artifact pinning
    (hardening-invariants.md H4.2: "tracked-state probed via git"); a
    missing git binary degrades that one sub-check to a silent skip rather
    than failing the whole run."""
    try:
        proc = subprocess.run(
            ["git", "-C", str(start), "rev-parse", "--show-toplevel"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=10,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    if proc.returncode != 0:
        return None
    out = proc.stdout.strip()
    return Path(out) if out else None


def _git_check_ignore(repo_root: Path, repo_relative_path: str) -> bool | None:
    """Whether `repo_relative_path` (as recorded verbatim in a trace
    record's own `artifact` field) is git-ignored, per `git check-ignore`
    (hardening-invariants.md H4.2). `True`/`False` on a clean answer, `None`
    on any inability to ask (no git binary, not a work tree, ...) -- the
    caller treats `None` as "cannot determine", not as "not ignored"."""
    try:
        proc = subprocess.run(
            ["git", "-C", str(repo_root), "check-ignore", "-q", repo_relative_path],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=10,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    if proc.returncode == 0:
        return True
    if proc.returncode == 1:
        return False
    return None  # returncode >= 2 -- a real git error, not a yes/no answer


def _parse_iso8601_ms(value: object) -> datetime | None:
    """Parse a trace-schema.md §1 `started_at`/`ended_at` timestamp
    (ISO-8601 UTC, ms precision, e.g. `2026-07-08T14:00:03.120Z`). `None` on
    anything that isn't a parseable string -- the caller skips the
    duration_ms cross-check rather than raising on a malformed timestamp
    that some other rule already reports."""
    if not isinstance(value, str):
        return None
    v = value[:-1] + "+00:00" if value.endswith("Z") else value
    try:
        return datetime.fromisoformat(v)
    except ValueError:
        return None


# ---------------------------------------------------------------------------
# check_artifact_layout -- artifact-layout.md
# ---------------------------------------------------------------------------

#: The two council/defense-deck/ files -- the one nested layout path in §1
#: whose content carries no OWN docs/contracts/*.md schema (unlike
#: decision-record.md/completion-report.md/testing.md/traces.jsonl, each
#: validated by one of this file's other five direct checks), so a
#: misplaced copy can only ever be an artifact-layout finding, never
#: mistaken for a second contract's (violation-wrong-path/'s own reasoning).
_DEFENSE_DECK_FILES = ("technical.md", "overview.md")


def _check_defense_deck_paths(feature_dir: Path) -> list[Finding]:
    findings: list[Finding] = []
    council_dir = feature_dir / "council"
    if not council_dir.is_dir():
        return findings  # council phase not reached yet -- not a violation
    for name in _DEFENSE_DECK_FILES:
        canonical_rel = f"council/defense-deck/{name}"
        if (feature_dir / canonical_rel).is_file():
            continue
        matches = sorted(p for p in council_dir.rglob(name) if p.is_file())
        if not matches:
            continue  # legitimately absent (resumability -- pending phase)
        found_rel = matches[0].relative_to(feature_dir).as_posix()
        findings.append(
            emit_finding(
                canonical_rel,
                "artifact-layout.md §1: required artifact not found at its layout path "
                f"(found instead at {found_rel}, missing the defense-deck/ subdirectory)",
            )
        )
    return findings


def _check_upstream_gates(feature_dir: Path) -> list[Finding]:
    """§7 rule 3 -- no artifact exists whose upstream phase is incomplete."""
    findings: list[Finding] = []
    profile_path = feature_dir / "profile.yaml"
    profile_text = (
        profile_path.read_text(encoding="utf-8", errors="replace") if profile_path.is_file() else ""
    )
    council_mode = _read_gate_mode(profile_text, "council")
    workforce_mode = _read_gate_mode(profile_text, "workforce")

    if (feature_dir / "tasks.md").is_file() and council_mode != "auto":
        if not _gate_is_approved(feature_dir, "council/decision-record.md", "Human Gate"):
            findings.append(
                emit_finding(
                    "tasks.md",
                    "artifact-layout.md §7 rule 3: tasks.md exists without an approved "
                    "council/decision-record.md '## Human Gate' section (required unless "
                    "profile.yaml sets gates.council.mode: auto)",
                )
            )

    if (feature_dir / "implement.log.md").is_file() and workforce_mode != "auto":
        if not _gate_is_approved(feature_dir, "agents/assignment.md", "Workforce Gate"):
            findings.append(
                emit_finding(
                    "implement.log.md",
                    "artifact-layout.md §7 rule 3: implement.log.md exists without an approved "
                    "agents/assignment.md '## Workforce Gate' section (required unless "
                    "profile.yaml sets gates.workforce.mode: auto)",
                )
            )
    return findings


def _check_opinions_leak(feature_dir: Path) -> list[Finding]:
    """§7 rule 5, with the D50 meta-feature carve-out (C8/FR-006)."""
    spec_path = feature_dir / "spec.md"
    if spec_path.is_file():
        if _RULE5_EXEMPT_RE.search(spec_path.read_text(encoding="utf-8", errors="replace")):
            return []  # declared meta-feature -- exempt, never reported as drift

    findings: list[Finding] = []
    for path in sorted(feature_dir.rglob("*")):
        if not path.is_file():
            continue
        rel = path.relative_to(feature_dir)
        if rel.parts and rel.parts[0] == "council":
            continue  # rule 5 only governs files OUTSIDE council/
        try:
            text = path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        if "opinions/" in text:
            findings.append(
                emit_finding(
                    rel.as_posix(),
                    "artifact-layout.md §7 rule 5: mentions the 'opinions/' path outside "
                    "council/ (context-hygiene leak -- a deliberately blunt grep, not a "
                    "judgment about whether the reference is a real read)",
                )
            )
    return findings


# T009: docs/contracts/artifact-layout.md
def check_artifact_layout(feature_dir: Path) -> list[Finding]:
    """Required-artifact presence + layout paths (artifact-layout.md §1,
    §7 rules 1-4) -- e.g. `council/defense-deck/technical.md` must sit at
    exactly that nested path, not `council/technical.md`
    (violation-wrong-path/ fixture). MUST honor the D50 meta-feature rule-5
    carve-out (`^>\\s*\\*\\*Rule-5 exempt \\(meta-feature\\):` in the
    feature's own `spec.md`) as conformant, never as drift (C8/FR-006).

    §7 rule 1 (the `^[0-9]{3}-[a-z0-9]+...$` directory-name regex) is
    deliberately NOT enforced here: this checker's own committed fixtures
    (`specs/008-pre-public-maintenance/fixtures/{conformant,violation-*}/`)
    are named for what they test, not `NNN-slug`, exactly as
    `fixtures/README.md`'s own design notes flag and recommend (option b --
    "simply not enforce rule 1 at all in the direct artifact-layout check,
    treating it as informational"). Enforcing it here would fail every
    fixture in this checker's own both-branch suite for an incidental
    directory-name mismatch, swallowing the real signal each fixture exists
    to carry.
    """
    findings: list[Finding] = []
    findings += _check_defense_deck_paths(feature_dir)
    findings += _check_upstream_gates(feature_dir)
    findings += _check_opinions_leak(feature_dir)
    return findings


# ---------------------------------------------------------------------------
# check_decision_record -- decision-record.md
# ---------------------------------------------------------------------------


# T009: docs/contracts/decision-record.md
def check_decision_record(feature_dir: Path) -> list[Finding]:
    """Required sections, in order, per decision-record.md §5's Sections
    table (`## Metadata`, `## Round N`, `## Human Gate`, `## Carried
    Constraints` -- the last always present, even if empty;
    violation-missing-section/ fixture). Presence-conditional on
    `council/decision-record.md` itself existing (R7: the file exists as
    soon as round 1 is triaged -- absence is a pending phase, not this
    check's business; artifact-layout.md §7 rule 3 owns "exists too early
    relative to its upstream")."""
    path = feature_dir / "council" / "decision-record.md"
    if not path.is_file():
        return []
    text = path.read_text(encoding="utf-8", errors="replace")
    artifact = "council/decision-record.md"
    findings: list[Finding] = []

    def _rule(msg: str) -> Finding:
        return emit_finding(artifact, f"decision-record.md §5: {msg}")

    headings = [(m.group(1), m.group(2).strip()) for m in _HEADING12_RE.finditer(text)]

    if not any(level == "#" and title.startswith("Decision Record") for level, title in headings):
        findings.append(_rule("required title heading '# Decision Record — <spec-id>' is missing"))

    if not any(level == "##" and title == "Metadata" for level, title in headings):
        findings.append(_rule("required section '## Metadata' is missing (cardinality 1, required)"))

    round_nums: list[int] = []
    for level, title in headings:
        if level == "##":
            m = re.match(r"^Round\s+(\d+)\b", title)
            if m:
                round_nums.append(int(m.group(1)))
    if not round_nums:
        findings.append(_rule("required section '## Round N' is missing (cardinality ≥1, required)"))
    elif round_nums != list(range(1, len(round_nums) + 1)):
        findings.append(
            _rule(
                "'## Round N' sections are not ascending/contiguous starting at 1 "
                f"(found order: {round_nums})"
            )
        )

    profile_path = feature_dir / "profile.yaml"
    profile_text = (
        profile_path.read_text(encoding="utf-8", errors="replace") if profile_path.is_file() else ""
    )
    council_mode = _read_gate_mode(profile_text, "council")

    has_human_gate = any(level == "##" and title.startswith("Human Gate") for level, title in headings)
    if not has_human_gate and council_mode != "auto":
        findings.append(
            _rule(
                "required section '## Human Gate' is missing (cardinality ≥1, required "
                "unless gates.council.mode: auto)"
            )
        )

    carried_positions = [
        i for i, (level, title) in enumerate(headings) if level == "##" and title == "Carried Constraints"
    ]
    if not carried_positions:
        findings.append(
            _rule(
                "required section '## Carried Constraints' is missing (cardinality 1, last, "
                "required — may be empty but never absent)"
            )
        )
    elif len(carried_positions) > 1 or carried_positions[-1] != len(headings) - 1:
        findings.append(
            _rule("'## Carried Constraints' is not the last top-level section (cardinality 1, last, required)")
        )

    return findings


# ---------------------------------------------------------------------------
# check_completion_report -- completion-report.md
# ---------------------------------------------------------------------------

_COMPLETION_STATUS_ENUM = ("success", "partial", "failed")

#: completion-report.md §2 -- the exact, ordered, greppable core heading
#: list; `<name>`/`(N/N)` are placeholders, matched by pattern rather than
#: literal text.
_COMPLETION_CORE_SECTIONS: list[tuple[str, "re.Pattern[str]", str]] = [
    ("##", re.compile(r"^Implementation Complete — .+$"), "## Implementation Complete — <name>"),
    ("###", re.compile(r"^Completed \(\d+/\d+\)$"), "### Completed (N/N)"),
    ("###", re.compile(r"^Partial/Degraded$"), "### Partial/Degraded"),
    ("###", re.compile(r"^Failed$"), "### Failed"),
    ("###", re.compile(r"^Integration status$"), "### Integration status"),
    ("###", re.compile(r"^Key results$"), "### Key results"),
]

#: §3 -- the ONLY additional top-level headings a completion report may
#: carry (unvalidated appendix; §6 rule 5 forbids any OTHER `##` heading).
_COMPLETION_APPENDIX_H2 = {"Milestone-close context", "Decisions & log"}


# T009: docs/contracts/completion-report.md
def check_completion_report(feature_dir: Path) -> list[Finding]:
    """Frontmatter `status` closed enum `{success, partial, failed}`
    (completion-report.md §6 rule 1; violation-bad-frontmatter/ fixture) +
    the six ordered core sections. Presence-conditional on
    `completion-report.md` itself existing."""
    path = feature_dir / "completion-report.md"
    if not path.is_file():
        return []
    text = path.read_text(encoding="utf-8", errors="replace")
    artifact = "completion-report.md"
    findings: list[Finding] = []

    def _rule(n: int, msg: str) -> Finding:
        return emit_finding(artifact, f"completion-report.md §6 rule {n}: {msg}")

    frontmatter = _parse_frontmatter(text)
    status: str | None = None
    if frontmatter is None:
        findings.append(_rule(1, "frontmatter is missing or malformed (expected a '---'-delimited block)"))
    else:
        for key in ("feature", "phase", "status"):
            if key not in frontmatter:
                findings.append(_rule(1, f"frontmatter is missing required key '{key}'"))
        phase = frontmatter.get("phase")
        if phase is not None and phase != "complete":
            findings.append(_rule(1, f"frontmatter 'phase' = '{phase}' must be 'complete'"))
        status = frontmatter.get("status")
        if status is not None and status not in _COMPLETION_STATUS_ENUM:
            findings.append(_rule(1, f"frontmatter 'status' = '{status}' is not one of {{success, partial, failed}}"))

    headings = [(m.group(1), m.group(2).strip()) for m in _HEADING23_RE.finditer(text)]

    matched_labels: list[str] = []
    for level, pattern, label in _COMPLETION_CORE_SECTIONS:
        hits = [title for hlevel, title in headings if hlevel == level and pattern.match(title)]
        if not hits:
            findings.append(_rule(2, f"required core section '{label}' is missing"))
        else:
            matched_labels.append(label)

    if len(matched_labels) == len(_COMPLETION_CORE_SECTIONS):
        expected_order = [label for _, _, label in _COMPLETION_CORE_SECTIONS]
        seen_order = [
            label
            for level, title in headings
            for lvl2, pattern, label in _COMPLETION_CORE_SECTIONS
            if level == lvl2 and pattern.match(title)
        ]
        if seen_order != expected_order:
            findings.append(_rule(2, f"core sections are not in the required order (expected: {expected_order})"))

    for level, title in headings:
        if level != "##":
            continue
        if title.startswith("Implementation Complete — "):
            continue
        if title in _COMPLETION_APPENDIX_H2:
            continue
        findings.append(
            _rule(
                5,
                f"unexpected top-level '## {title}' heading (only the core heading plus the "
                "optional §3 appendix headings are permitted)",
            )
        )

    def _body_of(name_pattern: "re.Pattern[str]") -> str | None:
        for m in _HEADING23_RE.finditer(text):
            if m.group(1) == "###" and name_pattern.match(m.group(2).strip()):
                rest = text[m.end():]
                nxt = _HEADING23_RE.search(rest)
                return (rest[: nxt.start()] if nxt else rest).strip()
        return None

    if status == "partial":
        if not _body_of(re.compile(r"^Partial/Degraded$")):
            findings.append(_rule(6, "status: partial requires '### Partial/Degraded' to be non-empty"))
    if status == "failed":
        if not _body_of(re.compile(r"^Failed$")):
            findings.append(_rule(6, "status: failed requires '### Failed' to be non-empty"))

    return findings


# ---------------------------------------------------------------------------
# check_testing_doc -- testing-doc.md
# ---------------------------------------------------------------------------

_TESTING_EVIDENCE_ENUM = ("report-claimed", "log-verified")
_TESTING_ROW_STATUS_ENUM = ("covered", "GAP")
_TESTING_REQUIRED_H2 = ["Coverage map", "Verified by reading vs. would-execute in v2"]


def _parse_coverage_rows(text: str) -> list[dict[str, str]]:
    body = _section_body_h2(text, "Coverage map")
    if body is None:
        return []
    rows = _pipe_table_rows(body, min_cells=5)
    return [
        {
            "id": cells[0],
            "approach": cells[1],
            "grounding": cells[2],
            "evidence-source": cells[3].strip("*"),
            "status": cells[4].strip("*"),
        }
        for cells in rows
    ]


# T009: docs/contracts/testing-doc.md
def check_testing_doc(feature_dir: Path) -> list[Finding]:
    """Frontmatter `executed` + the full `spec.md` SC/FR id <-> `##
    Coverage map` row bijection (testing-doc.md §6 rule 3;
    violation-coverage-gap/ fixture). Presence-conditional on `testing.md`
    itself existing."""
    path = feature_dir / "testing.md"
    if not path.is_file():
        return []
    text = path.read_text(encoding="utf-8", errors="replace")
    artifact = "testing.md"
    findings: list[Finding] = []

    def _rule(n: int, msg: str) -> Finding:
        return emit_finding(artifact, f"testing-doc.md §6 rule {n}: {msg}")

    frontmatter = _parse_frontmatter(text)
    if frontmatter is None:
        findings.append(_rule(1, "frontmatter is missing or malformed (expected a '---'-delimited block)"))
    else:
        for key in ("feature", "phase", "executed"):
            if key not in frontmatter:
                findings.append(_rule(1, f"frontmatter is missing required key '{key}'"))
        phase = frontmatter.get("phase")
        if phase is not None and phase != "testing":
            findings.append(_rule(1, f"frontmatter 'phase' = '{phase}' must be 'testing'"))
        executed = frontmatter.get("executed")
        if executed is not None and executed != "none":
            findings.append(
                _rule(1, f"frontmatter 'executed' = '{executed}' must be 'none' (the only conforming value)")
            )

    headings = [title for level, title in _HEADING23_pairs(text) if level == "##"]
    for label in _TESTING_REQUIRED_H2:
        if label not in headings:
            findings.append(_rule(2, f"required section '## {label}' is missing"))
    present_required = [h for h in headings if h in _TESTING_REQUIRED_H2]
    if all(label in headings for label in _TESTING_REQUIRED_H2) and present_required != _TESTING_REQUIRED_H2:
        findings.append(_rule(2, "required sections are not in the required order"))
    extra = sorted({h for h in headings if h not in _TESTING_REQUIRED_H2})
    if extra:
        findings.append(
            _rule(2, f"unexpected top-level heading(s) {extra} (this contract defines no optional appendix)")
        )

    rows = _parse_coverage_rows(text)
    row_ids = [r["id"] for r in rows]
    for dup in sorted({i for i in row_ids if row_ids.count(i) > 1}):
        findings.append(_rule(3, f"'{dup}' appears more than once in '## Coverage map' (no id repeated)"))

    spec_path = feature_dir / "spec.md"
    spec_ids: set[str] = set()
    if spec_path.is_file():
        spec_ids = set(_ID_RE.findall(spec_path.read_text(encoding="utf-8", errors="replace")))
    row_id_set = set(row_ids)

    for missing_id in sorted(spec_ids - row_id_set):
        findings.append(
            _rule(3, f"'{missing_id}' appears in spec.md but has no '## Coverage map' row (bijection broken)")
        )
    for extra_id in sorted(row_id_set - spec_ids):
        findings.append(
            _rule(3, f"'{extra_id}' has a '## Coverage map' row but does not appear in spec.md (bijection broken)")
        )

    for row in rows:
        es = row.get("evidence-source", "")
        if es not in _TESTING_EVIDENCE_ENUM:
            findings.append(
                _rule(
                    4,
                    f"'{row['id']}' row 'evidence-source' = '{es}' is not one of "
                    "{report-claimed, log-verified}",
                )
            )
        status = row.get("status", "")
        if status not in _TESTING_ROW_STATUS_ENUM:
            findings.append(_rule(4, f"'{row['id']}' row 'status' = '{status}' is not one of {{covered, GAP}}"))
        elif status == "covered" and (
            row.get("approach", "").strip() in _EMPTY_CELL or row.get("grounding", "").strip() in _EMPTY_CELL
        ):
            findings.append(
                _rule(
                    5,
                    f"'{row['id']}' row is 'covered' without a genuine approach/grounding "
                    "(must be 'GAP' instead)",
                )
            )

    verified_body = _section_body_h2(text, "Verified by reading vs. would-execute in v2")
    if verified_body is not None and not verified_body.strip():
        findings.append(
            _rule(6, "'## Verified by reading vs. would-execute in v2' is empty (must carry non-empty prose)")
        )

    return findings


# ---------------------------------------------------------------------------
# check_trace_schema -- trace-schema.md (+ hardening-invariants.md H4 / I-31)
# ---------------------------------------------------------------------------

#: trace-schema.md §1 -- every field a record must carry, MINUS the three
#: role-scoped fields (`context_in`, `graph_queries`, `ceiling_hit`), which
#: are validated by their own §7 rule 11/12 presence-iff-role checks below
#: rather than this flat presence list.
_TRACE_REQUIRED_FIELDS = (
    "schema_version", "trace_id", "parent_trace_id", "feature", "phase", "role",
    "agent_id", "skills", "elevated_grants", "model", "effort", "started_at",
    "ended_at", "duration_ms", "tokens", "capture_method", "outcome", "artifact",
    "cost_usd",
)

#: trace-schema.md §2 -- the closed `role` enum.
_TRACE_ROLE_ENUM = frozenset(
    {
        "orchestrator", "deck-prep", "council-member", "chairman", "triage",
        "categorizer", "agent-creator", "analyzer", "implementer",
        "wave-reviewer", "tester",
    }
)
_TRACE_OUTCOME_ENUM = frozenset({"success", "partial", "failed", "aborted"})
_TRACE_CAPTURE_METHOD_ENUM = frozenset({"sdk", "transcript", "unavailable"})
_TRACE_CORE_TOOLSET = frozenset({"Read", "Write", "Edit", "Bash", "Glob", "Grep"})
_TRACE_SKILL_ID_RE = re.compile(r"^skl_[a-z0-9]+(_[a-z0-9]+)*$")
_TRACE_SEMVER_RE = re.compile(r"^\d+\.\d+\.\d+")


def _trace_contains_newline(value: object) -> bool:
    if isinstance(value, str):
        return "\n" in value
    if isinstance(value, dict):
        return any(_trace_contains_newline(v) for v in value.values())
    if isinstance(value, list):
        return any(_trace_contains_newline(v) for v in value)
    return False


def _check_trace_record(loc: str, record: dict) -> list[Finding]:
    findings: list[Finding] = []
    role = record.get("role")

    missing = [f for f in _TRACE_REQUIRED_FIELDS if f not in record]
    if missing:
        findings.append(
            emit_finding(loc, f"trace-schema.md §7 rule 2: missing required field(s): {', '.join(missing)}")
        )

    has_context_in = "context_in" in record
    if role == "tester" and not has_context_in:
        findings.append(
            emit_finding(
                loc, "trace-schema.md §7 rule 11: role 'tester' record is missing the required 'context_in' field"
            )
        )
    elif has_context_in and role != "tester":
        findings.append(
            emit_finding(loc, f"trace-schema.md §7 rule 11: 'context_in' present on a non-tester record (role {role!r})")
        )

    has_gq = "graph_queries" in record
    has_ch = "ceiling_hit" in record
    if role == "council-member" and not (has_gq and has_ch):
        findings.append(
            emit_finding(
                loc,
                "trace-schema.md §7 rule 12: role 'council-member' record is missing the required "
                "'graph_queries'/'ceiling_hit' field(s)",
            )
        )
    elif (has_gq or has_ch) and role != "council-member":
        findings.append(
            emit_finding(
                loc,
                f"trace-schema.md §7 rule 12: 'graph_queries'/'ceiling_hit' present on a "
                f"non-council-member record (role {role!r})",
            )
        )

    if "role" in record and role not in _TRACE_ROLE_ENUM:
        findings.append(emit_finding(loc, f"trace-schema.md §2: role {role!r} is not one of the documented roles"))

    if "agent_id" in record:
        agent_id = record.get("agent_id")
        if agent_id is not None and role != "implementer":
            findings.append(
                emit_finding(
                    loc,
                    f"trace-schema.md §7 rule 4: role '{role}' record carries non-null agent_id "
                    "(agent_id != null must imply role == \"implementer\")",
                )
            )
        elif agent_id is None and role == "implementer":
            findings.append(
                emit_finding(
                    loc,
                    "trace-schema.md §7 rule 4: role 'implementer' record carries a null agent_id "
                    "(agent_id != null must imply role == \"implementer\")",
                )
            )

    if "skills" in record:
        skills = record["skills"]
        if not isinstance(skills, list):
            findings.append(emit_finding(loc, "trace-schema.md §7 rule 5: 'skills' must be an array"))
        else:
            if len(skills) > _ASSEMBLY_CAP:
                findings.append(
                    emit_finding(
                        loc,
                        f"trace-schema.md §7 rule 5: 'skills' carries {len(skills)} entries, exceeding "
                        f"the assembly cap of {_ASSEMBLY_CAP}",
                    )
                )
            if skills and role != "implementer":
                findings.append(
                    emit_finding(
                        loc,
                        f"trace-schema.md §7 rule 5: role '{role}' record carries a non-empty 'skills' "
                        "array (skills != [] must imply role == \"implementer\")",
                    )
                )
            for entry in skills:
                if not isinstance(entry, dict) or "id" not in entry or "version" not in entry:
                    findings.append(
                        emit_finding(loc, "trace-schema.md §7 rule 5: a 'skills' entry is missing 'id'/'version'")
                    )
                    continue
                sid, sver = entry.get("id"), entry.get("version")
                if not isinstance(sid, str) or not _TRACE_SKILL_ID_RE.match(sid):
                    findings.append(
                        emit_finding(loc, f"trace-schema.md §7 rule 5: skill id {sid!r} does not match ^skl_[a-z0-9_]+$")
                    )
                if not isinstance(sver, str) or not _TRACE_SEMVER_RE.match(sver):
                    findings.append(
                        emit_finding(loc, f"trace-schema.md §7 rule 5: skill version {sver!r} is not valid semver")
                    )

    if "elevated_grants" in record:
        grants = record["elevated_grants"]
        if not isinstance(grants, list):
            findings.append(emit_finding(loc, "trace-schema.md §7 rule 6: 'elevated_grants' must be an array"))
        else:
            for g in grants:
                if g in _TRACE_CORE_TOOLSET:
                    findings.append(
                        emit_finding(
                            loc,
                            f"trace-schema.md §7 rule 6: 'elevated_grants' lists core tool {g!r} (only "
                            "elevation beyond the core toolset is recorded)",
                        )
                    )
            if grants and role != "implementer":
                findings.append(
                    emit_finding(
                        loc,
                        f"trace-schema.md §7 rule 6: role '{role}' record carries a non-empty "
                        "'elevated_grants' array",
                    )
                )

    capture_method = record.get("capture_method")
    if "capture_method" in record and capture_method not in _TRACE_CAPTURE_METHOD_ENUM:
        findings.append(
            emit_finding(
                loc,
                f"trace-schema.md §7 rule 10: capture_method {capture_method!r} is not one of "
                "{sdk, transcript, unavailable}",
            )
        )
    if "tokens" in record and "capture_method" in record:
        tokens = record["tokens"]
        if capture_method == "unavailable":
            if tokens is not None:
                findings.append(
                    emit_finding(loc, "trace-schema.md §7 rule 10: capture_method 'unavailable' requires tokens: null")
                )
        else:
            if tokens is None:
                findings.append(
                    emit_finding(loc, "trace-schema.md §7 rule 10: 'tokens' is null but capture_method != 'unavailable'")
                )
            elif isinstance(tokens, dict):
                for key in ("input", "output", "cache_read", "cache_creation"):
                    v = tokens.get(key)
                    if not isinstance(v, int) or isinstance(v, bool) or v < 0:
                        findings.append(
                            emit_finding(
                                loc, f"trace-schema.md §7 rule 10: tokens.{key} must be a non-negative int, got {v!r}"
                            )
                        )
            else:
                findings.append(
                    emit_finding(
                        loc, "trace-schema.md §7 rule 10: 'tokens' must be an object when capture_method != 'unavailable'"
                    )
                )

    if "outcome" in record and record.get("outcome") not in _TRACE_OUTCOME_ENUM:
        findings.append(
            emit_finding(
                loc,
                f"trace-schema.md §1: 'outcome' {record.get('outcome')!r} is not one of "
                "{success, partial, failed, aborted}",
            )
        )

    started = _parse_iso8601_ms(record.get("started_at"))
    ended = _parse_iso8601_ms(record.get("ended_at"))
    duration_ms = record.get("duration_ms")
    if started is not None and ended is not None and isinstance(duration_ms, int) and not isinstance(duration_ms, bool):
        expected_ms = round((ended - started).total_seconds() * 1000)
        if abs(expected_ms - duration_ms) > 1:
            findings.append(
                emit_finding(
                    loc,
                    f"trace-schema.md §7 rule 3: duration_ms ({duration_ms}) != ended_at - started_at "
                    f"({expected_ms}ms)",
                )
            )

    if _trace_contains_newline(record):
        findings.append(emit_finding(loc, "trace-schema.md §7 rule 8: a field value contains a literal newline"))

    return findings


# T009: docs/contracts/trace-schema.md
def check_trace_schema(feature_dir: Path) -> list[Finding]:
    """Every field present, per `traces.jsonl` line (trace-schema.md §7),
    including rule 4's `agent_id != null` iff `role == "implementer"`
    invariant (violation-bad-trace-line/ fixture, case 1). Also the sole
    committed pinning mechanism for the I-31 hardening
    (`hardening-invariants.md` H4.1 -- a gitignored/untracked sole output
    must record `artifact: null`, never the ignored path;
    violation-bad-trace-line/ fixture, case 2, R1-S03). Presence-conditional
    on `traces.jsonl` itself existing."""
    path = feature_dir / "traces.jsonl"
    if not path.is_file():
        return []
    findings: list[Finding] = []
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()

    repo_root = _git_repo_root(feature_dir)
    trace_id_lines: dict[str, list[int]] = {}

    for lineno, raw in enumerate(lines, start=1):
        if not raw.strip():
            continue
        loc = f"traces.jsonl:{lineno}"
        try:
            record = json.loads(raw)
        except json.JSONDecodeError as exc:
            findings.append(emit_finding(loc, f"trace-schema.md §7 rule 1: not a complete JSON object ({exc})"))
            continue
        if not isinstance(record, dict):
            findings.append(emit_finding(loc, "trace-schema.md §7 rule 1: line does not parse to a JSON object"))
            continue

        findings += _check_trace_record(loc, record)

        tid = record.get("trace_id")
        if isinstance(tid, str):
            trace_id_lines.setdefault(tid, []).append(lineno)

        artifact_val = record.get("artifact")
        if repo_root is not None and isinstance(artifact_val, str) and artifact_val:
            if _git_check_ignore(repo_root, artifact_val) is True:
                findings.append(
                    emit_finding(
                        f"traces.jsonl:{lineno} (I-31 pinning case)",
                        f"hardening-invariants.md H4.1: artifact '{artifact_val}' is a gitignored path "
                        "— a task whose sole output is gitignored/untracked must record "
                        "artifact: null",
                    )
                )

    for tid in sorted(trace_id_lines):
        occurrences = trace_id_lines[tid]
        if len(occurrences) > 1:
            findings.append(
                emit_finding(
                    f"traces.jsonl:{occurrences[0]}",
                    f"trace-schema.md §7 rule 7: trace_id '{tid}' is not unique (also on line(s) "
                    f"{', '.join(str(n) for n in occurrences[1:])})",
                )
            )

    return findings


# ---------------------------------------------------------------------------
# check_agent_library_schema -- agent-library-schema.md
# ---------------------------------------------------------------------------


# T009: docs/contracts/agent-library-schema.md
def check_agent_library_schema(feature_dir: Path) -> list[Finding]:
    """`agents/assignment.md` roster SHAPE only (data-model.md E3 /
    fixtures/README design note 5 -- not the base/skill library file
    formats, which stay delegate-or-untouched): the assembly cap of base +
    3 injected skills, maximum (§3 D40 Guardrails;
    violation-assembly-cap-exceeded/ fixture) and the §4 model-policy rule.
    Presence-conditional on `agents/assignment.md` itself existing."""
    path = feature_dir / "agents" / "assignment.md"
    if not path.is_file():
        return []
    text = path.read_text(encoding="utf-8", errors="replace")
    artifact = "agents/assignment.md"
    findings: list[Finding] = []

    body = _section_body_h2(text, "Roster")
    rows = _pipe_table_rows(body, min_cells=6) if body is not None else []

    for cells in rows:
        task, lane, _base, _base_id, model, skills_cell = cells[:6]
        injected = _count_csv_cell(skills_cell)
        if injected > _ASSEMBLY_CAP:
            findings.append(
                emit_finding(
                    artifact,
                    f"agent-library-schema.md §3 (D40 Guardrails): assembled agent for {task} carries "
                    f"{injected} injected skills, exceeding the assembly cap of {_ASSEMBLY_CAP}",
                )
            )

        task_type = _lane_type(lane)
        if task_type in _IMPLEMENTATION_TYPES and model.strip().lower() != "sonnet":
            findings.append(
                emit_finding(
                    artifact,
                    f"agent-library-schema.md §4: assembled agent for {task} accepts implementation "
                    f"type '{task_type}' but runs model '{model.strip()}' (implementation types are "
                    "enforced to sonnet)",
                )
            )

    return findings


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
