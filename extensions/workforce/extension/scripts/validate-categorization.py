#!/usr/bin/env python3
"""validate-categorization.py -- zero-AI gate for /speckit-categorize (T011).

Contracts implemented:
  - docs/contracts/taxonomy.md SS2   (8 types, closed enum)
  - docs/contracts/taxonomy.md SS4   (11 specializations incl. `general`,
    the max(1, floor(0.2n)) cap -- v1's floor'd form, D65 verdict 9)
  - docs/contracts/taxonomy.md SS2.3 (`preserves_behavior` boolean modifier)
  - docs/contracts/taxonomy.md SS2.4 (`runtime_consumed` boolean modifier -- v1, D65)
  - specs/003-workforce/data-model.md SS1 (the categorization record + its
    "File-level validation (validate-categorization.py, code)" row)
  - specs/003-workforce/spec.md FR-002, FR-004, SC-001, SC-002
  - specs/003-workforce/contracts/commands.md `/speckit-categorize` step 2
    ("Run validate-categorization.py ... on breach: exit non-zero, write no
    categorization.md, phase does not complete" -- S22)

This is a ZERO-AI script: no model session, no `traces.jsonl` record
(contracts/commands.md's header: "The scripts ... are zero-AI (no trace)").
It reads ONE file -- a categorization.md, or a not-yet-final draft of one --
and, per S21, reuses `frontmatter.py` (this directory's one shared
closed-shape parser) instead of hand-rolling a second copy of the same
scalar-parsing logic:

  - `FrontmatterError` is the base of `CategorizationShapeError` below, so
    "this file does not conform to the closed shape I understand" is one
    exception family across every workforce validator, whether the shape in
    question is a YAML frontmatter block (frontmatter.py's own job) or this
    file's markdown pipe-table (categorization.md carries no `---`
    frontmatter at all -- data-model.md SS1: "a markdown table + a
    `## Cap Check` line", D46 rule 3 -- so there is no frontmatter BLOCK
    here to parse; what *is* shared is the failure-reporting shape).
  - `_parse_scalar_token` (frontmatter.py's scalar primitive -- not in its
    `__all__`, imported directly rather than duplicated) is reused verbatim
    to decide whether a `preserves_behavior` cell is really a boolean,
    instead of writing a second, slightly-different `"true"/"false"`
    string check here.

WHAT IS CHECKED (both are hard FAILs, never a warning):

  1. Coverage (SC-001). Every task row under "## Categorization table"
     carries all five fields -- type, specialization, preserves_behavior,
     runtime_consumed, tags -- and:
       - `type`             is one of the closed 8 (taxonomy SS2)
       - `specialization`   is one of the closed 11 (taxonomy SS4: 10 lanes
                             + the `general` escape hatch)
       - `preserves_behavior` parses as an actual boolean (via the shared
                             scalar parser, not a bespoke check)
       - `runtime_consumed` parses as an actual boolean (v1 modifier,
                             taxonomy SS2.4/D65 -- same shared scalar parser)
       - `tags`             is an accepted "empty" marker, or a list of
                             lowercase-kebab tokens (`^[a-z0-9]+(-[a-z0-9]+)*$`)
     An un-enumerable `type`/`specialization` value is ALWAYS a FAIL -- this
     script never invents or coerces a value into one it recognizes
     (taxonomy.md SS8: a new value is a docs/90 D-row, never a validator
     special-case). `task_id` must additionally match `T\\d+` and be unique
     within the file (data-model.md SS1: "present, unique").

     Deliberately OUT OF SCOPE: whether the row *set* is 1:1 with a sibling
     tasks.md's task IDs (data-model.md SS1's "1:1 with tasks" clause). T011's
     task annotation depends only on T004/frontmatter.py -- this script's
     sole input is categorization.md itself, never tasks.md. That completeness
     concern is covered elsewhere: the categorizer prompt's own instruction
     (categorizer-prompt.md, "Non-negotiables": "100% coverage ... every task
     ID, done or not") plus assemble.py's S14 tasks.md-SHA freshness check at
     the *next* phase -- a different concern (drift after the fact) from this
     script's row-internal validation.

  2. The general cap (FR-004/SC-002, taxonomy SS4): count(general) must not
     exceed max(1, floor(0.20 x count(tasks))) -- the v1 floor'd cap (D65
     verdict 9). Computed by EXACT integer arithmetic (`limit = max(1, total
     // 5)`, breach iff `general > limit`, since 0.20 == 1/5), never a float,
     so the boundary can never drift on a binary floating-point rounding edge.
     The `max(1, .)` floor is the ONLY change from v0: a feature with n<5
     tasks now admits exactly ONE `general` task (v0's literal 20% cap admitted
     ZERO -- D44's formal absurdity, deleted by D65); for n>=5 the floor is
     inert and the cap is the same 20% it always was. This script recomputes
     the cap independently from the table rows; it never trusts the
     categorizer's own prose "## Cap Check" line (categorizer-prompt.md Step 2:
     "if its count and yours ever disagree, its count governs, not yours" --
     "its" is this validator's).

EXIT CONTRACT (S22 -- read this before wiring a command around this script):

    0   PASS.  Categorization is valid. Prints one line to stdout (or
        nothing). If an OUTPUT PATH was given (2nd CLI arg) and differs from
        the input path, the validated content is copied there -- this is the
        ONLY circumstance under which this script ever writes anything.

    1   FAIL.  A coverage/enum/boolean/tag/cap breach, OR the input file
        couldn't be located/read, OR its "## Categorization table" couldn't
        be found/parsed at all. A clear, itemized breach report goes to
        stderr. **No file is written or modified.** If an OUTPUT PATH was
        given: it is left absent if it didn't already exist, and byte-for-
        byte unchanged if it did -- this is what "write nothing on breach"
        means operationally (FR-004/SC-002).

    2   USAGE error (wrong number of CLI arguments). Not a categorization
        verdict either way -- the caller invoked this script incorrectly,
        not the categorizer session.

  Non-zero (1 or 2) is the phase's "stop here" signal either way
  (contracts/commands.md: "on fail, report the breach and stop the pipeline
  at categorize" -- Resumability III). A caller that only branches on
  `== 0` vs `!= 0` never needs to distinguish 1 from 2.

HOW THE NO-WRITE-ON-BREACH GUARANTEE (S22) IS REALIZED, mechanically:

  `main()` never touches `output_path` until AFTER `validate_categorization_
  text()` has returned `ok=True` -- the only `write_text` call in this file
  is lexically inside the success branch, past the `if not result.ok: return
  1` early return. There is no code path -- including the usage-error and
  file-not-found paths -- that creates, truncates, or deletes an output
  path. This is a property of the file's control flow, checkable by
  inspection (grep this file for `write_text`: there is exactly one call
  site, and it is unreachable unless `result.ok` is True), not a claim that
  rests on this docstring alone.

USAGE:

    validate-categorization.py <categorization_path>                # gate only
    validate-categorization.py <categorization_path> <output_path>  # gate + write-on-pass

  In "gate only" form, the caller is responsible for the write itself
  (e.g. `python3 validate-categorization.py draft.md && mv draft.md
  categorization.md`); this script performs no I/O beyond reading
  `categorization_path`. In the two-argument form, this script performs the
  guarded copy itself, so the no-write-on-breach guarantee lives in one
  place rather than being re-implemented by every caller.
"""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path

# Make the sibling frontmatter.py (S21's one shared parser) importable
# regardless of HOW this script is loaded. `python3 validate-categorization.py
# ...` auto-prepends this file's directory to sys.path (the normal CLI path,
# exercised by /speckit-categorize and by test/test_categorize.sh, T013) --
# but a test harness that loads this module in-process via
# `importlib.util.spec_from_file_location` from a different working
# directory does NOT get that for free. Inserting it explicitly makes both
# loading styles work identically; it is a harmless no-op duplicate entry in
# the already-working case.
sys.path.insert(0, str(Path(__file__).resolve().parent))

from frontmatter import FrontmatterError, _parse_scalar_token  # noqa: E402

__all__ = [
    "CATEGORIZATION_TYPES",
    "CATEGORIZATION_SPECIALIZATIONS",
    "GENERAL_CAP_NUMERATOR",
    "GENERAL_CAP_DENOMINATOR",
    "EXPECTED_HEADER",
    "CategorizationShapeError",
    "CategorizationRecord",
    "ValidationResult",
    "parse_categorization_table",
    "validate_record",
    "validate_cap",
    "general_cap_limit",
    "validate_categorization_text",
    "validate_categorization_file",
    "main",
]


# ---------------------------------------------------------------------------
# Closed taxonomy enums -- docs/contracts/taxonomy.md SS2 / SS4 (BLESSED,
# 2026-07-09). Adding a value here is a docs/90 D-row (taxonomy SS8), never a
# code fix -- these two sets are the enforcement of "closed enum", not a
# convenience default.
# ---------------------------------------------------------------------------

CATEGORIZATION_TYPES = frozenset(
    {
        "scaffold",
        "data-model",
        "service",
        "endpoint",
        "ui",
        "test",
        "docs",
        "infra",
    }
)

CATEGORIZATION_SPECIALIZATIONS = frozenset(
    {
        "frontend-web",
        "mobile",
        "backend-service",
        "data-persistence",
        "infra-platform",
        "security",
        "performance",
        "ai-agents",
        "devtools-cli",
        "qa-automation",
        "general",  # the escape hatch -- capped, never uncapped (SS4)
    }
)

assert len(CATEGORIZATION_TYPES) == 8, "taxonomy.md SS2: exactly 8 types"
assert len(CATEGORIZATION_SPECIALIZATIONS) == 11, (
    "taxonomy.md SS4: exactly 11 specializations (10 lanes + general)"
)

# FR-004/SC-002: count(general) <= max(1, floor(0.20 * count(tasks))) -- the v1
# one-task floor (D65 verdict 9; taxonomy.md SS4). Kept as an exact integer
# fraction (1/5) rather than the float 0.20 so the boundary (e.g. exactly 1/5 of
# the tasks) never drifts on a binary floating-point rounding edge, and the
# max(1, .) floor is exact integer arithmetic too; see validate_cap().
GENERAL_CAP_NUMERATOR = 1
GENERAL_CAP_DENOMINATOR = 5

EXPECTED_HEADER = [
    "task_id",
    "type",
    "specialization",
    "preserves_behavior",
    "runtime_consumed",  # v1, D65 -- taxonomy.md S2.4
    "tags",
]

_TASK_ID_RE = re.compile(r"^T\d+$")
_KEBAB_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
_TABLE_HEADING_RE = re.compile(r"^#{1,6}\s*Categorization table\s*$", re.IGNORECASE)
_SEPARATOR_CELL_RE = re.compile(r"^:?-{2,}:?$")

# "Tags is a comma-separated list; empty (--) is valid" (categorizer-prompt.md
# Output format). Accept a few equivalent spellings a hand-written or
# hand-edited categorization.md might reasonably use for "no tags" (e.g. the
# S28-grandfathered specs/003-workforce/categorization.md itself is machine-
# generated per-row but any manual fixture is fair game).
_EMPTY_TAGS_MARKERS = {"", "-", "—", "none", "n/a", "[]"}  # — = em dash


class CategorizationShapeError(FrontmatterError):
    """Raised when categorization.md's overall shape can't be located at
    all: no '## Categorization table' heading, no pipe-table beneath it, or
    a header row that doesn't match the five expected columns. Subclasses
    frontmatter.py's `FrontmatterError` (S21) rather than inventing a second
    "this file doesn't conform to the shape I understand" exception type --
    same failure mode, applied to a markdown-table shape instead of a YAML-
    frontmatter shape.

    Deliberately NOT used for per-row or per-field content problems (a bad
    enum value, a non-boolean, an over-cap run) -- those are collected as
    plain strings in `ValidationResult.errors` so a caller sees every
    breach in one pass, not just the first one raised.
    """


# ---------------------------------------------------------------------------
# Records
# ---------------------------------------------------------------------------


@dataclass
class CategorizationRecord:
    """One raw (unvalidated) row from '## Categorization table'. Field
    values are the cell text after `.strip()` only -- NOT yet backtick- or
    bold-stripped, NOT yet enum-checked. `validate_record()` is what turns
    this into pass/fail diagnostics; keeping the raw cell text here means a
    caller (e.g. T013's golden test) can inspect exactly what was on the
    line that failed.
    """

    task_id: str
    type_raw: str
    specialization_raw: str
    preserves_behavior_raw: str
    runtime_consumed_raw: str  # v1, D65 -- taxonomy.md S2.4
    tags_raw: str
    line_no: int


@dataclass
class ValidationResult:
    """The whole verdict for one categorization.md. `ok` is the single bit
    `main()`'s exit code is derived from; `errors` is every breach found
    (never just the first). `total_count`/`general_count` are this script's
    OWN independent recount (categorizer-prompt.md Step 2: "its count
    governs, not yours").
    """

    ok: bool
    errors: list[str]
    total_count: int
    general_count: int


# ---------------------------------------------------------------------------
# Markdown pipe-table primitives
# ---------------------------------------------------------------------------


def _split_row(line: str) -> list[str]:
    """Split one markdown pipe-table row into its cell strings (still
    whitespace-padded -- callers `.strip()` as needed). The categorization
    table's cell grammar never legitimately embeds a literal `|` (type/
    specialization are single closed-enum tokens, preserves_behavior is a
    bare boolean, tags are comma-separated kebab tokens), so a plain split
    on `|` is exact -- no escaping logic needed, unlike frontmatter.py's
    YAML scalars, which this table format doesn't use at all.
    """
    s = line.strip()
    if s.startswith("|"):
        s = s[1:]
    if s.endswith("|"):
        s = s[:-1]
    return s.split("|")


def _is_separator_row(line: str) -> bool:
    """`|---|---|---|---|---|`, optionally with GFM alignment colons
    (`|:---|:---:|---:|`)."""
    if "|" not in line:
        return False
    cells = [c.strip() for c in _split_row(line)]
    return bool(cells) and all(_SEPARATOR_CELL_RE.match(c) for c in cells)


def _clean_token(s: str) -> str:
    """Strip whitespace and markdown decoration (backticks, bold/italic `*`
    or `_` wrapping) from one cell/tag token.

    The real, hand-written `specs/003-workforce/categorization.md` (the
    S28-grandfathered bootstrap fixture) backtick-wraps type/specialization
    (`` `docs` ``) and bold-wraps selected tags for emphasis (`**prompt**`,
    `**web-search**`) -- decoration is styling, not part of the enum/tag
    value itself, so it is stripped before any taxonomy or kebab-case check
    ever runs. A legitimate kebab tag never starts or ends with `*`/`_`
    (`_KEBAB_RE` doesn't allow those characters at all), so stripping them
    here can only ever remove decoration, never real content.
    """
    s = s.strip().strip("`").strip()
    s = s.strip("*_").strip()
    return s


def _validate_tags(cell: str) -> str | None:
    """Return a violation message, or `None` if `cell` is a valid tags
    list -- an accepted "empty" marker, or a comma-separated list of
    lowercase-kebab tokens (decoration-stripped first, see `_clean_token`)."""
    stripped = cell.strip()
    if stripped.lower() in _EMPTY_TAGS_MARKERS:
        return None  # explicitly empty is valid (taxonomy SS6 / brief requirement 1)

    bad: list[str] = []
    saw_empty_entry = False
    for piece in stripped.split(","):
        token = _clean_token(piece)
        if token == "":
            saw_empty_entry = True
            continue
        if not _KEBAB_RE.match(token):
            bad.append(token)

    if saw_empty_entry:
        return f"tags cell has an empty entry (raw: {cell!r})"
    if bad:
        return (
            f"tags {bad!r} are not lowercase-kebab "
            f"(^[a-z0-9]+(-[a-z0-9]+)*$, taxonomy.md SS6)"
        )
    return None


def parse_categorization_table(
    text: str,
) -> tuple[list[CategorizationRecord], list[str]]:
    """Parse the '## Categorization table' section of a categorization.md's
    text into `(records, row_errors)`.

    Raises `CategorizationShapeError` when the file's overall SHAPE can't be
    located at all (no heading, no pipe-table beneath it, or a header row
    that doesn't match `EXPECTED_HEADER`) -- that is a structural failure,
    not a content one. A malformed individual ROW (wrong column count) is
    NOT fatal to the rest of the parse: it is collected into `row_errors`
    and skipped, so one bad line doesn't hide every other row's diagnostics.
    """
    lines = text.splitlines()
    n = len(lines)

    heading_idx = None
    for i, line in enumerate(lines):
        if _TABLE_HEADING_RE.match(line.strip()):
            heading_idx = i
            break
    if heading_idx is None:
        raise CategorizationShapeError(
            "no '## Categorization table' heading found -- this file is not "
            "shaped like a categorization.md (data-model.md SS1)"
        )

    # Find the header row: the first '|'-starting line under the heading,
    # stopping early (and failing clearly) if another heading arrives first.
    i = heading_idx + 1
    while i < n:
        s = lines[i].strip()
        if s.startswith("|"):
            break
        if s.startswith("#"):
            raise CategorizationShapeError(
                f"no pipe-table found under '## Categorization table' before "
                f"the next heading {s!r} (line {i + 1})"
            )
        i += 1
    if i >= n:
        raise CategorizationShapeError(
            "no pipe-table found under '## Categorization table' (reached "
            "end of file)"
        )

    header_cells = [c.strip().lower() for c in _split_row(lines[i])]
    if header_cells != EXPECTED_HEADER:
        raise CategorizationShapeError(
            f"categorization table header mismatch at line {i + 1}: expected "
            f"{EXPECTED_HEADER}, got {header_cells}"
        )
    i += 1

    if i >= n or not _is_separator_row(lines[i]):
        raise CategorizationShapeError(
            f"expected a '|---|...' separator row after the table header "
            f"(line {i + 1})"
        )
    i += 1

    records: list[CategorizationRecord] = []
    row_errors: list[str] = []
    while i < n:
        raw = lines[i]
        s = raw.strip()
        if s == "" or s.startswith("#") or not s.startswith("|"):
            break  # blank line / next heading / prose -- end of the table
        cells = _split_row(raw)
        if len(cells) != len(EXPECTED_HEADER):
            row_errors.append(
                f"line {i + 1}: expected {len(EXPECTED_HEADER)} columns, got "
                f"{len(cells)} (raw: {raw.strip()!r})"
            )
            i += 1
            continue
        task_id, type_raw, spec_raw, pb_raw, rc_raw, tags_raw = (c.strip() for c in cells)
        records.append(
            CategorizationRecord(
                task_id=task_id,
                type_raw=type_raw,
                specialization_raw=spec_raw,
                preserves_behavior_raw=pb_raw,
                runtime_consumed_raw=rc_raw,
                tags_raw=tags_raw,
                line_no=i + 1,
            )
        )
        i += 1

    return records, row_errors


# ---------------------------------------------------------------------------
# Requirement 1 -- Coverage (SC-001)
# ---------------------------------------------------------------------------


def validate_record(rec: CategorizationRecord) -> list[str]:
    """All four fields present + closed-enum membership + boolean +
    lowercase-kebab tags, for one row. Returns every violation found on
    this row (never just the first)."""
    errs: list[str] = []
    where = f"{rec.task_id or '<missing task_id>'} (line {rec.line_no})"

    if not rec.task_id:
        errs.append(f"line {rec.line_no}: missing task_id")
    elif not _TASK_ID_RE.match(rec.task_id):
        errs.append(f"{where}: task_id {rec.task_id!r} does not match ^T\\d+$")

    type_token = _clean_token(rec.type_raw)
    if not type_token:
        errs.append(f"{where}: missing 'type'")
    elif type_token not in CATEGORIZATION_TYPES:
        errs.append(
            f"{where}: type {type_token!r} is not a member of the closed "
            f"taxonomy v1 type enum {sorted(CATEGORIZATION_TYPES)} (never "
            f"invented -- taxonomy.md SS2/SS8)"
        )

    spec_token = _clean_token(rec.specialization_raw)
    if not spec_token:
        errs.append(f"{where}: missing 'specialization'")
    elif spec_token not in CATEGORIZATION_SPECIALIZATIONS:
        errs.append(
            f"{where}: specialization {spec_token!r} is not a member of the "
            f"closed taxonomy v1 specialization enum "
            f"{sorted(CATEGORIZATION_SPECIALIZATIONS)} (never invented -- "
            f"taxonomy.md SS4/SS8)"
        )

    pb_token = _clean_token(rec.preserves_behavior_raw)
    if not pb_token:
        errs.append(f"{where}: missing 'preserves_behavior'")
    else:
        # Reuse frontmatter.py's shared scalar parser (S21) rather than a
        # second, hand-rolled "true"/"false" check -- see module docstring.
        parsed = _parse_scalar_token(pb_token)
        if not isinstance(parsed, bool):
            errs.append(
                f"{where}: preserves_behavior {pb_token!r} is not a boolean "
                f"true/false (taxonomy.md SS2.3)"
            )

    # runtime_consumed -- the v1 modifier (taxonomy.md SS2.4, D65), validated
    # exactly like preserves_behavior: a real boolean via the same shared scalar
    # parser, never a bespoke string check.
    rc_token = _clean_token(rec.runtime_consumed_raw)
    if not rc_token:
        errs.append(f"{where}: missing 'runtime_consumed'")
    else:
        parsed_rc = _parse_scalar_token(rc_token)
        if not isinstance(parsed_rc, bool):
            errs.append(
                f"{where}: runtime_consumed {rc_token!r} is not a boolean "
                f"true/false (taxonomy.md SS2.4, D65)"
            )

    tags_error = _validate_tags(rec.tags_raw)
    if tags_error:
        errs.append(f"{where}: {tags_error}")

    return errs


# ---------------------------------------------------------------------------
# Requirement 2 -- the general cap (FR-004/SC-002)
# ---------------------------------------------------------------------------


def general_cap_limit(total_count: int) -> int:
    """The v1 floor'd cap ceiling for `total_count` tasks (D65 verdict 9):
    `max(1, floor(0.2 * total))`, computed by EXACT integer arithmetic
    (`floor(0.2 * n) == n // 5`, since 0.20 == 1/5). One source of truth for
    both `validate_cap`'s breach test and `main`'s reported ceiling.
    """
    return max(1, (total_count * GENERAL_CAP_NUMERATOR) // GENERAL_CAP_DENOMINATOR)


def validate_cap(general_count: int, total_count: int) -> str | None:
    """Return a violation message, or `None` if `general_count` is within
    the FR-004/SC-002 cap of `total_count`.

    v1 cap (D65 verdict 9, taxonomy.md SS4): `count(general) <= max(1,
    floor(0.20 * count(tasks)))`. Evaluated as EXACT integer arithmetic --
    `floor(0.20 * n) == n // 5` (0.20 == 1/5), then a `max(1, .)` one-task
    floor -- never a float comparison, so there is no binary floating-point
    rounding edge at an exact-fraction boundary (e.g. exactly 2 general out of
    10: limit == 2, `2 > 2` is False, not a breach; the cap is `>`, not `>=`).

    The floor changes exactly the n<5 case vs. v0: `floor(0.2 * 4) == 0`, but
    `max(1, 0) == 1`, so a <5-task feature now admits exactly ONE `general`
    task (v0's literal cap admitted zero -- D44's formal absurdity, deleted by
    D65). For n>=5 the `max(1, .)` is inert and the cap is the same 20% it
    always was.
    """
    if total_count <= 0:
        return None  # the zero-rows case is already reported as its own error
    limit = general_cap_limit(total_count)
    if general_count > limit:
        return (
            f"general cap breach: count(general)={general_count} exceeds "
            f"max(1, floor({GENERAL_CAP_NUMERATOR}/{GENERAL_CAP_DENOMINATOR} x "
            f"count(tasks)={total_count})) = {limit} (taxonomy.md SS4, "
            f"FR-004/SC-002, D65 verdict 9) -- redo with better evidence; never "
            f"widen the cap or retag a task to dodge it"
        )
    return None


# ---------------------------------------------------------------------------
# Orchestration
# ---------------------------------------------------------------------------


def validate_categorization_text(text: str) -> ValidationResult:
    """Run both requirements (coverage + cap) over `text` and return the
    combined `ValidationResult`. Never raises -- a structural parse failure
    (`CategorizationShapeError`) is caught and folded into `errors` too, so
    every caller (CLI, tests, a future command script) has exactly one
    result shape to branch on."""
    try:
        records, row_errors = parse_categorization_table(text)
    except CategorizationShapeError as exc:
        return ValidationResult(
            ok=False, errors=[str(exc)], total_count=0, general_count=0
        )

    errors: list[str] = list(row_errors)

    seen: dict[str, int] = {}
    general_count = 0
    for rec in records:
        errors.extend(validate_record(rec))
        if rec.task_id:
            if rec.task_id in seen:
                errors.append(
                    f"{rec.task_id} (line {rec.line_no}): duplicate task_id "
                    f"(first seen at line {seen[rec.task_id]})"
                )
            else:
                seen[rec.task_id] = rec.line_no
        if _clean_token(rec.specialization_raw) == "general":
            general_count += 1

    total_count = len(records)
    if total_count == 0:
        errors.append(
            "no task rows found in '## Categorization table' -- nothing to "
            "validate"
        )
    else:
        cap_error = validate_cap(general_count, total_count)
        if cap_error:
            errors.append(cap_error)

    return ValidationResult(
        ok=not errors,
        errors=errors,
        total_count=total_count,
        general_count=general_count,
    )


def validate_categorization_file(path: str | Path) -> ValidationResult:
    """Read `path` and validate it. Read-only -- never writes, never
    raises (I/O problems become `ValidationResult(ok=False, ...)` like any
    other breach)."""
    p = Path(path)
    if not p.is_file():
        return ValidationResult(
            ok=False, errors=[f"no such file: {p}"], total_count=0, general_count=0
        )
    try:
        text = p.read_text(encoding="utf-8")
    except OSError as exc:
        return ValidationResult(
            ok=False,
            errors=[f"could not read {p}: {exc}"],
            total_count=0,
            general_count=0,
        )
    return validate_categorization_text(text)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main(argv: list[str] | None = None) -> int:
    args = sys.argv[1:] if argv is None else argv

    if not (1 <= len(args) <= 2):
        print(
            "usage: validate-categorization.py <categorization_path> [output_path]\n"
            "  categorization_path : the categorization.md (or draft) to validate\n"
            "  output_path         : OPTIONAL. Written ONLY on a passing validation\n"
            "                        (S22) -- never created, modified, or removed on\n"
            "                        a breach.",
            file=sys.stderr,
        )
        return 2

    categorization_path = Path(args[0])
    output_path = Path(args[1]) if len(args) == 2 else None

    if not categorization_path.is_file():
        print(
            f"validate-categorization.py: FAIL -- no such file: "
            f"{categorization_path}",
            file=sys.stderr,
        )
        return 1
    try:
        text = categorization_path.read_text(encoding="utf-8")
    except OSError as exc:
        print(
            f"validate-categorization.py: FAIL -- could not read "
            f"{categorization_path}: {exc}",
            file=sys.stderr,
        )
        return 1

    result = validate_categorization_text(text)

    if not result.ok:
        print(
            f"validate-categorization.py: FAIL -- {categorization_path} "
            f"({result.total_count} task row(s), general "
            f"{result.general_count}/{result.total_count}):",
            file=sys.stderr,
        )
        for err in result.errors:
            print(f"  - {err}", file=sys.stderr)
        print(
            "categorization.md NOT written (or left unchanged if it already "
            "existed) -- phase does not complete (FR-004/SC-002, S22).",
            file=sys.stderr,
        )
        return 1

    # PASS. This is the ONLY branch of main() that may touch output_path,
    # and only now that result.ok is True (S22's write-gate -- see module
    # docstring "HOW THE NO-WRITE-ON-BREACH GUARANTEE IS REALIZED").
    if output_path is not None and output_path.resolve() != categorization_path.resolve():
        try:
            output_path.parent.mkdir(parents=True, exist_ok=True)
            output_path.write_text(text, encoding="utf-8")
        except OSError as exc:
            print(
                f"validate-categorization.py: validation PASSED but writing "
                f"{output_path} failed: {exc}",
                file=sys.stderr,
            )
            return 1

    limit = general_cap_limit(result.total_count)
    print(
        f"validate-categorization.py: OK -- {result.total_count} task(s), "
        f"general {result.general_count}/{result.total_count} "
        f"(cap {limit})."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
