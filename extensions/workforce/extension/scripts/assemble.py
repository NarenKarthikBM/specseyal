#!/usr/bin/env python3
"""assemble.py -- the zero-AI, deterministic matcher/assembler (T014).

Implements, verbatim, the matching/assembly algorithm at
`docs/contracts/agent-library-schema.md` S3 (base lookup by
`(type, specialization)`; tag-ranked skill injection; grant union; the
D48 Sonnet-floor guard) plus the surrounding contracts it depends on:

  - docs/contracts/agent-library-schema.md S3   the matching/assembly algorithm
  - docs/contracts/agent-library-schema.md S4   model policy / the D48 guard
  - docs/contracts/agent-library-schema.md S4.1 tool grants (core vs. elevated)
  - docs/contracts/taxonomy-v0.md S2.3          preserves_behavior -> force-inject
                                                 skl_refactor_discipline
  - docs/contracts/skill-module.md              skill fields (tags, grants, stats)
  - docs/contracts/artifact-layout.md S8        the '## Workforce Gate' / roster
                                                 format (columns, rules W1-W4)
  - specs/003-workforce/data-model.md S4/S5     the Assembled agent / roster row
                                                 entities this script produces
  - specs/003-workforce/plan.md                 S01 (total order), S08 (this
                                                 script writes the roster itself),
                                                 S18 (library-snapshot hash),
                                                 FR-022 (library|built marks),
                                                 D48 (the Sonnet-floor guard)

This module is imported by the shared `frontmatter.py` (S21) for all
frontmatter parsing -- it does not re-implement that closed-shape parser.

Determinism (S01, non-negotiable). SC-005's golden test asserts a
byte-identical roster across two runs over the same categorization.md +
the same library, INCLUDING grant order, not just membership. Every
set-typed intermediate that reaches output -- the injected-skill grant
union above all -- is total-ordered via `total_order()` before it is
serialized. This module never iterates a raw Python `set` into output;
see `total_order()`'s docstring for why that matters and how the few
`set()` calls that do appear (Jaccard arithmetic, membership tests) are
safe despite the rule.

Write boundary (S08). `main()` writes exactly one file: the rendered
`agents/assignment.md`, filling only the template's `{{UPPER_SNAKE}}`
tokens (FEATURE, TASK_COUNT, TASKS_SHA, LIBRARY_SNAPSHOT_HASH,
ROSTER_ROWS, EMPTY_LANE_NOTES, DROPPED_SKILL_NOTES). Every
`[PENDING ...]` bracket marker in the template -- the Workforce Gate's
timestamp, reviewer, decision, reviewed, Notes, and Overrides fields --
is copied through unchanged, because this script only ever `.replace()`s
a `{{...}}` token and never touches bracket-marker text. Those fields are
`/speckit-workforce-approve`'s alone (T017).

Scope note (S14). `categorization.md` records the `tasks.md` SHA it was
derived from; this script extracts and stamps that value for visibility
but does NOT compare it against the current `tasks.md` -- that freshness
check is `/speckit-agent-assign`'s job (S14, T016), not this pure
matcher's.

Scope note (S3 step 4 / the skill-builder gap). A task whose tag-based
skill candidates are empty (but whose own tags are non-empty) is a
"gap": something the Sonnet skill-builder should author a new SKILL.md
for (D2, D40.2) -- out of this zero-AI script's scope. This script only
detects and reports it: each `Assembly.skill_gap` flag, and a
`GAP_TASKS: T005,T012` line on stdout for the calling command
(`/speckit-agent-assign`, T016) to act on. The gap is never written into
the roster artifact itself -- the template has no slot for it.

CLI
---
    assemble.py CATEGORIZATION.md [--output PATH]
                                   [--library-dir DIR]
                                   [--agents-dir DIR] [--skills-dir DIR]
                                   [--template PATH]
                                   [--built-skill ID [--built-skill ID ...]]

Defaults: `--library-dir .claude` (agents at `<library-dir>/agents`,
skills at `<library-dir>/skills`, both overridable independently);
`--output` defaults to `<categorization's dir>/agents/assignment.md`;
`--template` defaults to the sibling `../templates/assignment.template.md`.

Exit codes
----------
  0  success -- the roster was written.
  2  D48 guard violated (FR-014/SC-006): a `prompt`-tagged task assembled
     onto a non-Sonnet base. Hard error. Nothing was written.
  3  malformed input or a library invariant violation: categorization.md
     did not parse, a duplicate id, a non-unique `(type, specialization)`
     lane, a missing FR-016 generic fallback base, a missing
     `skl_refactor_discipline` when `preserves_behavior` required it, or
     the template failed to render cleanly. Nothing was written.
  4  a library entry's frontmatter failed to parse (a `FrontmatterError`
     from the shared `frontmatter.py` bubbled up). Nothing was written.

The logic lives in plain, importable functions (`parse_categorization`,
`load_bases`/`load_skills`, `assemble_task`/`assemble_all`,
`compute_library_snapshot_hash`, `group_into_rows`, the `render_*`
functions) precisely so a golden test can call them directly, or invoke
`main()` twice and diff the two output files byte-for-byte, without
going through a subprocess.
"""

from __future__ import annotations

import argparse
import hashlib
import re
import sys
from collections.abc import Iterable
from dataclasses import dataclass
from pathlib import Path

import frontmatter

__all__ = [
    "AssembleError",
    "D48GuardError",
    "ASSEMBLY_CAP",
    "REFACTOR_DISCIPLINE_ID",
    "GENERAL_SPECIALIZATION",
    "Task",
    "Base",
    "Skill",
    "Categorization",
    "Library",
    "InjectedSkill",
    "Assembly",
    "RosterRow",
    "total_order",
    "parse_categorization",
    "load_bases",
    "load_skills",
    "assemble_task",
    "assemble_all",
    "compute_library_snapshot_hash",
    "group_into_rows",
    "render_roster_table",
    "render_empty_lane_notes",
    "render_dropped_notes",
    "render_assignment_md",
    "main",
]


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

ASSEMBLY_CAP = 3  # D40: base + at most 3 injected skills, no exceptions.
REFACTOR_DISCIPLINE_ID = "skl_refactor_discipline"  # taxonomy-v0.md S2.3
GENERAL_SPECIALIZATION = "general"  # taxonomy-v0.md S4 -- the FR-016 fallback lane


# ---------------------------------------------------------------------------
# Errors -- always caught at the __main__ boundary and reported without a
# Python traceback (fail clearly, matching frontmatter.py's own philosophy).
# ---------------------------------------------------------------------------


class AssembleError(Exception):
    """Malformed input, or a library invariant this script depends on for
    a deterministic, total-ordered result was violated. Always raised
    with a message naming what was expected and, where possible, the
    offending file/line.
    """


class D48GuardError(AssembleError):
    """FR-014/SC-006: at least one `prompt`-tagged task assembled onto a
    non-Sonnet base. Hard error, non-zero exit, nothing written (D48).
    """


# ---------------------------------------------------------------------------
# 1. Data model
# ---------------------------------------------------------------------------


@dataclass
class Task:
    """One row of categorization.md's table (data-model.md S1)."""

    task_id: str
    type: str  # taxonomy-v0.md S2 -- one of 8
    specialization: str  # taxonomy-v0.md S4 -- one of 11 (incl. `general`)
    preserves_behavior: bool  # taxonomy-v0.md S2.3
    tags: list[str]  # taxonomy-v0.md S6 -- free, lowercase kebab-case


@dataclass
class Base:
    """A base specialist entry (agent-library-schema.md S1.1). Bases are
    curated-static (D44) -- this script only ever reads them.
    """

    id: str
    version: str
    model: str
    accepted_types: list[str]  # specseyal.taxonomy.type
    specialization: str  # specseyal.taxonomy.specialization -- exactly one lane
    body_sha256: str
    path: str


@dataclass
class Skill:
    """A skill module entry (skill-module.md S1)."""

    id: str
    version: str
    tags: list[str]  # specseyal.taxonomy.tags
    grants: list[str]  # specseyal.grants -- beyond the core toolset (D41)
    success_rate: float | None  # specseyal.stats.success_rate -- a cache, nulls allowed
    body_sha256: str
    path: str


@dataclass
class Categorization:
    """The parsed `categorization.md` (data-model.md S1)."""

    feature: str
    tasks_sha: str | None  # the S14 freshness binding, best-effort extracted
    tasks: list[Task]


@dataclass
class Library:
    """Everything `load_bases`/`load_skills` found on disk when this run
    started -- the fixed snapshot the whole assembly algorithm runs
    against (FR-015's "fixed library snapshot").
    """

    bases: dict[str, Base]
    skills: dict[str, Skill]

    def generic_base(self) -> Base:
        """The FR-016 fallback: the one base declaring
        `taxonomy.specialization: general` (agent-library-schema.md S3's
        "no lane -> generic base"). A library invariant, not a per-task
        condition, so a violation here is a library bug, not a task bug.
        """
        candidates = [
            b for b in self.bases.values() if b.specialization == GENERAL_SPECIALIZATION
        ]
        if not candidates:
            raise AssembleError(
                f"library invariant violated: no base declares "
                f"taxonomy.specialization: {GENERAL_SPECIALIZATION!r} "
                f"(the FR-016 fallback base is required)"
            )
        if len(candidates) > 1:
            raise AssembleError(
                f"library invariant violated: {len(candidates)} bases declare "
                f"specialization {GENERAL_SPECIALIZATION!r}: "
                f"{sorted(b.id for b in candidates)} -- the fallback lane must be unique"
            )
        return candidates[0]


@dataclass
class InjectedSkill:
    skill: Skill
    forced: bool  # True iff force-injected via preserves_behavior (taxonomy-v0.md S2.3)
    mark: str  # "library" | "built" (FR-022)


@dataclass
class Assembly:
    """One task's full S3 assembly result. A pure function's output --
    `assemble_task` never raises on the D48 guard (`assemble_all` does,
    across the whole batch); this makes `assemble_task` independently
    testable and keeps guard-enforcement in exactly one place.
    """

    task: Task
    base: Base
    empty_lane: bool  # S3 step 1: no (type, specialization) lane matched
    injected: list[InjectedSkill]  # forced ++ ranked, capped at ASSEMBLY_CAP, in injection order
    dropped: list[Skill]  # the ranked remainder beyond the cap (FR-011/SC-004)
    grants: list[str]  # union of injected skills' grants, total-ordered (S01/FR-013)
    skill_gap: bool  # S3 step 4: tag-based candidates were empty, task.tags non-empty


@dataclass
class RosterRow:
    """One grouped roster row (artifact-layout.md S8 rule W1): every task
    sharing the exact same (base, injected-skills, grants) signature
    collapses into one row, task ids comma-joined.
    """

    task_ids: list[str]
    base: Base
    empty_lane: bool
    injected: list[InjectedSkill]
    grants: list[str]


# ---------------------------------------------------------------------------
# 2. The determinism helper (S01) -- read this docstring before touching
#    any set-typed collection anywhere else in this file.
# ---------------------------------------------------------------------------


def total_order(items: Iterable[str]) -> list[str]:
    """De-duplicate and sort strings into one fixed total order (S01):
    ascending, case-sensitive Unicode code point order.

    This is the ONLY function in this module that turns a not-yet-ordered
    collection into output-bound order. Every set-typed intermediate that
    reaches serialized output -- the injected-skill grant union above all
    (agent-library-schema.md S3 step 3) -- routes through it.

    Deliberately never touches Python's `set` type. Iterating a `set` of
    strings is `PYTHONHASHSEED`-dependent (str hashing is salted per
    process by default), so even a "build a set, then sort it" pattern
    invites a future edit that drops the sort and silently reintroduces
    nondeterminism. `dict.fromkeys` de-duplicates via first-seen
    insertion order instead -- a language-guaranteed total order since
    Python 3.7, unrelated to hashing -- and `sorted` then imposes the
    actual total order this function promises, independent of whatever
    order the input arrived in.

    (Elsewhere in this module, `set()` is still used a few times --
    `_jaccard`'s arithmetic, `_find_candidates`'s intersection test, the
    `forced_ids`/`built_skill_ids` membership checks -- but only ever for
    `len()` or `in`, never iterated into output. Grep this file for
    `set(` if you need to re-verify that claim.)
    """
    return sorted(dict.fromkeys(items))


# ---------------------------------------------------------------------------
# 3. categorization.md parsing
# ---------------------------------------------------------------------------

_HEADER_RE = re.compile(r"^\|\s*task_id\s*\|", re.IGNORECASE)
_TASK_ID_RE = re.compile(r"^T(\d+)$")


def _strip_decoration(s: str) -> str:
    """Strip one layer of backticks and/or one layer of `**bold**`
    markdown decoration from a trimmed table-cell string.
    categorization.md wraps `type`/`specialization` in backticks and
    sometimes emphasizes a tag (e.g. `**prompt**`) for human readability;
    the underlying value never carries that markup.
    """
    s = s.strip()
    if len(s) >= 2 and s[0] == "`" and s[-1] == "`":
        s = s[1:-1].strip()
    if len(s) >= 4 and s[:2] == "**" and s[-2:] == "**":
        s = s[2:-2].strip()
    return s


def _split_row(line: str) -> list[str]:
    inner = line.strip().rstrip("\r")
    if inner.startswith("|"):
        inner = inner[1:]
    if inner.endswith("|"):
        inner = inner[:-1]
    return [cell.strip() for cell in inner.split("|")]


def _is_separator_row(line: str) -> bool:
    cells = _split_row(line)
    return bool(cells) and all(re.fullmatch(r":?-+:?", c) for c in cells)


def _parse_tags(cell: str) -> list[str]:
    if cell.strip() == "":
        return []
    return [_strip_decoration(tok) for tok in cell.split(",") if tok.strip() != ""]


def _task_sort_key(task: Task) -> tuple[int, int, str]:
    """Ascending, numeric-aware task-id order (T2 before T10), falling
    back to plain string order for any id that doesn't match `T<digits>`
    -- so the sort is still total (no crash, no ambiguity) even on an
    unexpected id shape.
    """
    m = _TASK_ID_RE.match(task.task_id)
    if m:
        return (0, int(m.group(1)), task.task_id)
    return (1, 0, task.task_id)


def parse_categorization(path: str | Path) -> Categorization:
    """Parse `categorization.md`'s `## Categorization table` into a
    `Categorization` (data-model.md S1). Tolerant of the cosmetic
    markdown the categorizer/hand-authors use (backtick-wrapped
    `type`/`specialization`, `**bold**` tags -- stripped by
    `_strip_decoration`), but strict about structure: a missing header, a
    missing separator row, a short row, or a `preserves_behavior` cell
    that isn't `true`/`false` all raise `AssembleError` naming the
    offending line (fail clearly).

    Also extracts the S14 freshness binding (`` `tasks.md @ <sha>` ``) on
    a best-effort basis: this script stamps whatever it finds into the
    roster for visibility. Comparing it against the *current* `tasks.md`
    is `/speckit-agent-assign`'s job (S14), out of this script's scope.

    `Categorization.feature` is the file's own parent directory name
    (`specs/003-workforce/categorization.md` -> `"003-workforce"`) --
    robust to markdown title formatting, and matches the `specs/NNN-
    feature/` convention exactly.
    """
    p = Path(path)
    text = p.read_text(encoding="utf-8")
    lines = text.split("\n")

    header_i = None
    for i, line in enumerate(lines):
        if _HEADER_RE.match(line.strip()):
            header_i = i
            break
    if header_i is None:
        raise AssembleError(
            f"{p}: no categorization table found (expected a "
            f"'| task_id | type | specialization | preserves_behavior | tags |' header row)"
        )

    sep_i = header_i + 1
    if sep_i >= len(lines) or not _is_separator_row(lines[sep_i]):
        raise AssembleError(
            f"{p}: line {sep_i + 1}: expected a markdown table separator row "
            f"('|---|---|---|---|---|') immediately after the header"
        )

    tasks: list[Task] = []
    seen: dict[str, int] = {}
    i = sep_i + 1
    while i < len(lines):
        raw = lines[i]
        stripped = raw.strip().rstrip("\r")
        if not stripped.startswith("|"):
            break
        cells = _split_row(stripped)
        if len(cells) < 5:
            raise AssembleError(
                f"{p}: line {i + 1}: expected 5 columns "
                f"(task_id, type, specialization, preserves_behavior, tags), "
                f"got {len(cells)}: {raw!r}"
            )
        task_id = _strip_decoration(cells[0])
        type_ = _strip_decoration(cells[1])
        specialization = _strip_decoration(cells[2])
        pb_raw = _strip_decoration(cells[3]).lower()
        if pb_raw not in ("true", "false"):
            raise AssembleError(
                f"{p}: line {i + 1}: preserves_behavior must be 'true' or 'false', "
                f"got {cells[3]!r}"
            )
        tags = _parse_tags(cells[4])
        if not task_id or not type_ or not specialization:
            raise AssembleError(
                f"{p}: line {i + 1}: task_id, type, and specialization must all be "
                f"non-empty: {raw!r}"
            )
        if task_id in seen:
            raise AssembleError(
                f"{p}: duplicate task_id {task_id!r} (line {seen[task_id] + 1} and line {i + 1})"
            )
        seen[task_id] = i
        tasks.append(Task(task_id, type_, specialization, pb_raw == "true", tags))
        i += 1

    if not tasks:
        raise AssembleError(f"{p}: categorization table has a header but no task rows")

    tasks.sort(key=_task_sort_key)

    sha_m = re.search(r"tasks\.md\s*@\s*([0-9a-fA-F]{4,40})", text)
    tasks_sha = sha_m.group(1) if sha_m else None

    feature = p.resolve().parent.name

    return Categorization(feature=feature, tasks_sha=tasks_sha, tasks=tasks)


# ---------------------------------------------------------------------------
# 4. Library loading -- globs `.claude/agents/*.md` and
#    `.claude/skills/*/SKILL.md` per agent-library-schema.md S7 ("no
#    index file"), via the shared frontmatter.py parser (S21).
# ---------------------------------------------------------------------------


def load_bases(agents_dir: str | Path) -> dict[str, Base]:
    """Glob `<agents_dir>/*.md`, parse each via the shared `frontmatter`
    module, and keep the ones with `specseyal.kind == "base"`
    (agent-library-schema.md S1.1). A non-conforming `.md` file in the
    directory is a library-corruption signal, not something to skip
    silently: `frontmatter.parse_entry` raises `FrontmatterError`, which
    the caller (`main`) surfaces as exit code 4.
    """
    d = Path(agents_dir)
    if not d.is_dir():
        raise AssembleError(f"agents dir not found: {d} (pass --agents-dir or --library-dir)")

    bases: dict[str, Base] = {}
    for path in sorted(d.glob("*.md")):
        entry = frontmatter.parse_entry(path)
        fm = entry["frontmatter"]
        sx = fm.get("specseyal") or {}
        if sx.get("kind") != "base":
            continue

        id_ = sx.get("id")
        if not id_:
            raise AssembleError(f"{path}: base entry missing specseyal.id")
        if id_ in bases:
            raise AssembleError(
                f"duplicate base id {id_!r}: {bases[id_].path} and {path} "
                f"(agent-library-schema.md S6 rule 2: id must be unique)"
            )

        model = fm.get("model")
        if not model:
            raise AssembleError(f"{path}: base entry missing top-level 'model'")

        version = sx.get("version")
        if not version:
            raise AssembleError(f"{path}: base entry missing specseyal.version")

        taxonomy = sx.get("taxonomy") or {}
        specialization = taxonomy.get("specialization")
        if not specialization:
            raise AssembleError(f"{path}: base entry missing specseyal.taxonomy.specialization")
        accepted_types = [str(t) for t in (taxonomy.get("type") or [])]

        bases[id_] = Base(
            id=str(id_),
            version=str(version),
            model=str(model),
            accepted_types=accepted_types,
            specialization=str(specialization),
            body_sha256=entry["body_sha256"],
            path=str(path),
        )
    return bases


def load_skills(skills_dir: str | Path) -> dict[str, Skill]:
    """Glob `<skills_dir>/*/SKILL.md`, parse each via the shared
    `frontmatter` module, and keep the ones with `specseyal.kind ==
    "skill"` (skill-module.md S1).
    """
    d = Path(skills_dir)
    if not d.is_dir():
        raise AssembleError(f"skills dir not found: {d} (pass --skills-dir or --library-dir)")

    skills: dict[str, Skill] = {}
    for path in sorted(d.glob("*/SKILL.md")):
        entry = frontmatter.parse_entry(path)
        fm = entry["frontmatter"]
        sx = fm.get("specseyal") or {}
        if sx.get("kind") != "skill":
            continue

        id_ = sx.get("id")
        if not id_:
            raise AssembleError(f"{path}: skill entry missing specseyal.id")
        if id_ in skills:
            raise AssembleError(
                f"duplicate skill id {id_!r}: {skills[id_].path} and {path} "
                f"(skill-module.md S6 rule 2: id must be unique)"
            )

        version = sx.get("version")
        if not version:
            raise AssembleError(f"{path}: skill entry missing specseyal.version")

        taxonomy = sx.get("taxonomy") or {}
        tags = [str(t) for t in (taxonomy.get("tags") or [])]
        grants = [str(g) for g in (sx.get("grants") or [])]
        stats = sx.get("stats") or {}
        success_rate = stats.get("success_rate")

        skills[id_] = Skill(
            id=str(id_),
            version=str(version),
            tags=tags,
            grants=grants,
            success_rate=float(success_rate) if success_rate is not None else None,
            body_sha256=entry["body_sha256"],
            path=str(path),
        )
    return skills


# ---------------------------------------------------------------------------
# 5. Matching + ranking + assembly -- agent-library-schema.md S3, steps 1-8
# ---------------------------------------------------------------------------


def _jaccard(a: list[str], b: list[str]) -> float:
    """|a intersect b| / |a union b|. Pure arithmetic over `set` sizes --
    NOT an ordering concern (S01): the `set()` calls here are consumed
    only by `len()`, never iterated, so PYTHONHASHSEED cannot leak into
    output through this function.
    """
    sa, sb = set(a), set(b)
    union = sa | sb
    if not union:
        return 0.0
    return len(sa & sb) / len(union)


def _semver_tuple(version: str) -> tuple[int, int, int]:
    parts = version.strip().split(".")
    if len(parts) != 3:
        raise AssembleError(f"invalid semver {version!r}: expected exactly 'X.Y.Z'")
    try:
        major, minor, patch = (int(part) for part in parts)
    except ValueError as exc:
        raise AssembleError(f"invalid semver {version!r}: {exc}") from exc
    return (major, minor, patch)


def _rank_key(task_tags: list[str], skill: Skill) -> tuple:
    """agent-library-schema.md S3 step 4, encoded as a single ascending
    sort key so plain `sorted()` produces the required order: Jaccard
    descending; `success_rate` descending with nulls last; `version`
    descending; `id` ascending. Every component is a total order and the
    last (`id`) is unique across the library, so this key never ties --
    "a TOTAL order, no ties" is a property of the key itself, not an
    accident of the input order.
    """
    jaccard = _jaccard(task_tags, skill.tags)
    sr = skill.success_rate
    sr_key = (0, -sr) if sr is not None else (1, 0.0)
    major, minor, patch = _semver_tuple(skill.version)
    return (-jaccard, sr_key, (-major, -minor, -patch), skill.id)


def _find_candidates(task_tags: list[str], skills: dict[str, Skill]) -> list[Skill]:
    """agent-library-schema.md S3 step 2: `{ s : s.tags ∩ t.tags != ∅ }`.
    Iterates `skills.values()` (a `dict` -- insertion-order-preserving by
    language guarantee since Python 3.7, unlike `set`, so this is NOT
    PYTHONHASHSEED-dependent), but the iteration order doesn't even
    matter here: the caller always sorts the result with `_rank_key`,
    whose `id` tiebreak makes the sort's output independent of input
    order.
    """
    tset = set(task_tags)
    if not tset:
        return []
    return [s for s in skills.values() if tset & set(s.tags)]


def _mark(skill_id: str, built_skill_ids: frozenset[str]) -> str:
    """FR-022: `built` iff the caller told us (via `--built-skill`) that
    the skill-builder authored this id during *this*
    `/speckit-agent-assign` run; `library` otherwise -- including a skill
    whose lifetime `origin` is `generated` from a *prior* feature
    (FR-022's own distinction: origin is not this run's provenance).
    """
    return "built" if skill_id in built_skill_ids else "library"


def assemble_task(task: Task, library: Library, built_skill_ids: frozenset[str]) -> Assembly:
    """agent-library-schema.md S3, steps 1-3 and 5-8, for exactly one
    task. Step 4 (the ∅-match "gap") is recorded on the result as
    `skill_gap` for the caller to act on -- authoring a new SKILL.md is a
    Sonnet skill-builder session, out of this zero-AI script's scope. The
    D48 guard (step 7) is enforced by the caller (`assemble_all`), not
    here, so this function is a pure total function: same `(task,
    library, built_skill_ids)` in, same `Assembly` out, and it never
    raises on a guard violation.
    """
    # ---- 1. Base: the fixed core selects exactly one lane ----
    matches = [
        b
        for b in library.bases.values()
        if task.type in b.accepted_types and task.specialization == b.specialization
    ]
    if len(matches) > 1:
        raise AssembleError(
            f"library invariant violated: task {task.task_id}: {len(matches)} bases match "
            f"(type={task.type!r}, specialization={task.specialization!r}): "
            f"{sorted(b.id for b in matches)} -- lanes must be unique "
            f"(agent-library-schema.md S3)"
        )
    if matches:
        base = matches[0]
        empty_lane = False
    else:
        base = library.generic_base()
        empty_lane = True

    # ---- 2. Skills: free tags rank the candidates ----
    candidates = _find_candidates(task.tags, library.skills)
    skill_gap = len(candidates) == 0 and len(task.tags) > 0

    forced: list[InjectedSkill] = []
    forced_ids: set[str] = set()
    if task.preserves_behavior:
        rd = library.skills.get(REFACTOR_DISCIPLINE_ID)
        if rd is None:
            raise AssembleError(
                f"task {task.task_id}: preserves_behavior=true requires "
                f"{REFACTOR_DISCIPLINE_ID!r} in the skill library, but it is not present "
                f"(taxonomy-v0.md S2.3)"
            )
        forced.append(InjectedSkill(skill=rd, forced=True, mark=_mark(rd.id, built_skill_ids)))
        forced_ids.add(rd.id)  # membership test only -- never iterated for output (S01)

    ranked = sorted(
        (s for s in candidates if s.id not in forced_ids),
        key=lambda s: _rank_key(task.tags, s),
    )
    ranked_injected = [
        InjectedSkill(skill=s, forced=False, mark=_mark(s.id, built_skill_ids)) for s in ranked
    ]

    all_ordered = forced + ranked_injected  # forced ++ ranked (S3)
    injected = all_ordered[:ASSEMBLY_CAP]
    dropped = [it.skill for it in all_ordered[ASSEMBLY_CAP:]]

    # ---- 3. Grants: the union, nothing more (D41), total-ordered (S01) ----
    grant_items: list[str] = []
    for it in injected:
        grant_items.extend(it.skill.grants)
    grants = total_order(grant_items)

    return Assembly(
        task=task,
        base=base,
        empty_lane=empty_lane,
        injected=injected,
        dropped=dropped,
        grants=grants,
        skill_gap=skill_gap,
    )


def assemble_all(
    tasks: list[Task], library: Library, built_skill_ids: frozenset[str]
) -> list[Assembly]:
    """Assemble every task, then enforce the D48 guard (FR-014/SC-006)
    across the whole batch before returning anything -- so a violation
    aborts before `main()` writes a single byte (mirrors the
    categorizer's own "exit non-zero, write nothing" discipline,
    FR-004/SC-002). `tasks` is expected in task_id-ascending order (as
    `parse_categorization` returns it); the roster's row order and
    grouping (`group_into_rows`) depend on that.
    """
    assemblies = [assemble_task(t, library, built_skill_ids) for t in tasks]

    violations = [a for a in assemblies if "prompt" in a.task.tags and a.base.model != "sonnet"]
    if violations:
        detail = "; ".join(
            f"{a.task.task_id} -> base {a.base.id!r} (model={a.base.model!r})"
            for a in violations
        )
        raise D48GuardError(
            f"D48 guard violated (FR-014/SC-006) on {len(violations)} task(s): {detail}. "
            f"A `prompt`-tagged task MUST assemble onto a Sonnet implementation specialist, "
            f"never a docs-exempt non-Sonnet base (agent-library-schema.md S4, "
            f"taxonomy-v0.md S3, D48). Nothing was written."
        )

    return assemblies


# ---------------------------------------------------------------------------
# 6. Library-snapshot content-hash (S18)
# ---------------------------------------------------------------------------


def compute_library_snapshot_hash(library: Library) -> str:
    """S18: a content-hash of the WHOLE consulted base+skill set -- every
    entry `load_bases`/`load_skills` found on disk when this run
    started, not just the ones injected into some task's assembly -- so
    a gap-free run's reproducibility (SC-005) is checkable in one line:
    two runs stamping the same hash consulted byte-identical library
    content, and the assembly algorithm being a pure function of
    (categorization, library) then guarantees byte-identical output.

    Each entry contributes one line, `"{kind}:{id}@{version}:{body_sha256}"`
    -- `body_sha256` is the COMPUTED hash of the entry's actual body
    (agent-library-schema.md S2), not the entry's own possibly-stale
    `central.body_sha256` frontmatter field, so a hand-edited-without-
    rebumping entry changes the snapshot honestly. Lines are
    total-ordered (S01) before joining and hashing.
    """
    lines = [f"base:{b.id}@{b.version}:{b.body_sha256}" for b in library.bases.values()]
    lines += [f"skill:{s.id}@{s.version}:{s.body_sha256}" for s in library.skills.values()]
    canonical = "\n".join(["specseyal-library-snapshot-v1", *total_order(lines)])
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


# ---------------------------------------------------------------------------
# 7. Grouping into roster rows -- artifact-layout.md S8 rule W1
# ---------------------------------------------------------------------------


def group_into_rows(assemblies: list[Assembly]) -> list[RosterRow]:
    """One row per assembled agent (a base + its <=3 injected skills +
    its grant set); every task appears in exactly one row (W1). Rows are
    emitted in first-appearance order over `assemblies` (which the
    caller hands in task_id-ascending order) -- a `dict` keyed on the
    assembly signature preserves that deterministically (insertion order
    is a language guarantee, not a `set`'s hash order; see
    `total_order`'s docstring).
    """
    groups: dict[tuple, RosterRow] = {}
    for a in assemblies:
        signature = (
            a.base.id,
            a.empty_lane,
            tuple((it.skill.id, it.skill.version, it.mark) for it in a.injected),
            tuple(a.grants),
        )
        row = groups.get(signature)
        if row is None:
            row = RosterRow(
                task_ids=[],
                base=a.base,
                empty_lane=a.empty_lane,
                injected=a.injected,
                grants=a.grants,
            )
            groups[signature] = row
        row.task_ids.append(a.task.task_id)
    return list(groups.values())


# ---------------------------------------------------------------------------
# 8. Rendering -- fills the template's {{UPPER_SNAKE}} tokens only (S08)
# ---------------------------------------------------------------------------

_MODEL_DISPLAY = {"sonnet": "Sonnet", "opus": "Opus", "haiku": "Haiku", "inherit": "Inherit"}


def render_model_cell(model: str) -> str:
    return _MODEL_DISPLAY.get(model, model.capitalize())


def render_base_cell(row: RosterRow) -> str:
    cell = f"`{row.base.id}`"
    if row.empty_lane:
        cell += " ⚠ **empty lane**"
    return cell


def render_skills_cell(injected: list[InjectedSkill]) -> str:
    if not injected:
        return "none"
    return ", ".join(f"`{it.skill.id}@{it.skill.version}` ({it.mark})" for it in injected)


def render_grants_cell(grants: list[str]) -> str:
    # `grants` is already total-ordered by assemble_task (S01); this just
    # formats it -- it must NOT re-derive order from anything unordered.
    if not grants:
        return "none"
    return ", ".join(f"`{g}`" for g in grants)


def render_roster_table(rows: list[RosterRow]) -> str:
    """The `### Roster approved` body rows (S08) -- the header and
    separator rows already live in the template; this renders only the
    `{{ROSTER_ROWS}}` substitution.
    """
    lines = [
        f"| {', '.join(row.task_ids)} | {render_base_cell(row)} | "
        f"{render_model_cell(row.base.model)} | {render_skills_cell(row.injected)} | "
        f"{render_grants_cell(row.grants)} |"
        for row in rows
    ]
    return "\n".join(lines)


def render_empty_lane_notes(assemblies: list[Assembly]) -> str:
    """FR-016: "never a silent fallback" -- one bullet per task whose
    `(type, specialization)` matched no base lane, in addition to the
    inline `⚠ empty lane` marker `render_base_cell` puts on its row.
    """
    hits = sorted((a for a in assemblies if a.empty_lane), key=lambda a: _task_sort_key(a.task))
    if not hits:
        return "**Empty lane(s) (FR-016):** none."
    lines = ["**Empty lane(s) (FR-016):**", ""]
    lines += [
        f"- {a.task.task_id} — `{a.task.type} × {a.task.specialization}` matched no "
        f"base lane; assembled onto `{a.base.id}`."
        for a in hits
    ]
    return "\n".join(lines)


def render_dropped_notes(assemblies: list[Assembly]) -> str:
    """FR-011/SC-004: whatever the cap trims is logged, never silently
    discarded.
    """
    hits = sorted((a for a in assemblies if a.dropped), key=lambda a: _task_sort_key(a.task))
    if not hits:
        return f"**Dropped skills (cap={ASSEMBLY_CAP}, FR-011/SC-004):** none."
    lines = [f"**Dropped skills (cap={ASSEMBLY_CAP}, FR-011/SC-004):**", ""]
    for a in hits:
        total = len(a.injected) + len(a.dropped)
        names = ", ".join(f"`{s.id}@{s.version}`" for s in a.dropped)
        lines.append(
            f"- {a.task.task_id} — {total} candidate(s) ranked by tag-Jaccard "
            f"(agent-library-schema.md S3 step 4); cap is {ASSEMBLY_CAP}; dropped {names}."
        )
    return "\n".join(lines)


_COMMENT_RE = re.compile(r"<!--.*?-->\n?", re.DOTALL)
_TOKEN_RE = re.compile(r"\{\{[A-Z_]+\}\}")


def render_assignment_md(template_text: str, substitutions: dict[str, str]) -> str:
    """Fill `assignment.template.md`'s `{{UPPER_SNAKE}}` tokens (S08).

    Strips the template's own "TEMPLATE SOURCE NOTE" HTML comment first
    (it documents the substitution mechanics for whoever implements this
    function -- not the artifact's own content, per the template's own
    instruction). Every `[PENDING ...]` bracket marker is left byte-for-
    byte as written in the template: this function only ever `.replace()`s
    a `{{...}}` token, so it is structurally incapable of writing into
    the reviewer/decision/reviewed/Notes/Overrides fields those markers
    guard (S08's write boundary) -- `/speckit-workforce-approve` (T017)
    is the only writer that ever touches `[PENDING ...]` text.

    Raises `AssembleError` if any `{{UPPER_SNAKE}}` token remains after
    substitution (the `substitutions` dict is out of sync with the
    template) -- fail clearly rather than ship a literal `{{TOKEN}}` into
    the artifact.
    """
    text = _COMMENT_RE.sub("", template_text, count=1)
    for token, value in substitutions.items():
        text = text.replace("{{" + token + "}}", value)

    remaining = total_order(_TOKEN_RE.findall(text))
    if remaining:
        raise AssembleError(
            f"template has unsubstituted token(s) after rendering: {remaining} "
            f"(assemble.py's substitutions dict is out of sync with the template)"
        )

    text = re.sub(r"\n{3,}", "\n\n", text)  # cosmetic: collapse to at most one blank line
    return text.rstrip("\n") + "\n"


# ---------------------------------------------------------------------------
# 9. CLI
# ---------------------------------------------------------------------------


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="assemble.py",
        description=(
            "Deterministic matcher/assembler (agent-library-schema.md S3). Reads "
            "categorization.md and the base+skill library, writes the roster into "
            "agents/assignment.md (the S08 write boundary: only the '### Roster "
            "approved' sub-table and its notes -- never the Workforce Gate's "
            "reviewer/decision/reviewed fields, which stay '[PENDING ...]')."
        ),
    )
    parser.add_argument("categorization", help="path to categorization.md")
    parser.add_argument(
        "--output",
        default=None,
        help="path to write the assignment artifact "
        "(default: <categorization's dir>/agents/assignment.md)",
    )
    parser.add_argument(
        "--library-dir",
        default=".claude",
        help="root containing agents/ and skills/ (default: .claude)",
    )
    parser.add_argument(
        "--agents-dir",
        default=None,
        help="override: dir of base-specialist *.md files (default: <library-dir>/agents)",
    )
    parser.add_argument(
        "--skills-dir",
        default=None,
        help="override: dir of */SKILL.md skill modules (default: <library-dir>/skills)",
    )
    parser.add_argument(
        "--template",
        default=None,
        help="path to assignment.template.md "
        "(default: the sibling extension/templates/assignment.template.md)",
    )
    parser.add_argument(
        "--built-skill",
        action="append",
        default=[],
        metavar="ID",
        help="mark this skill id as 'built' this run rather than 'library' (FR-022); "
        "repeatable. Pass the id(s) the skill-builder persisted during THIS "
        "/speckit-agent-assign run; omit entirely for a gap-free run.",
    )
    args = parser.parse_args(argv)

    categorization_path = Path(args.categorization)
    agents_dir = args.agents_dir or str(Path(args.library_dir) / "agents")
    skills_dir = args.skills_dir or str(Path(args.library_dir) / "skills")
    template_path = (
        Path(args.template)
        if args.template
        else Path(__file__).resolve().parent.parent / "templates" / "assignment.template.md"
    )
    output_path = (
        Path(args.output)
        if args.output
        else categorization_path.resolve().parent / "agents" / "assignment.md"
    )

    try:
        categorization = parse_categorization(categorization_path)
        library = Library(bases=load_bases(agents_dir), skills=load_skills(skills_dir))

        built_skill_ids = frozenset(args.built_skill)
        unknown = total_order(built_skill_ids - library.skills.keys())
        if unknown:
            raise AssembleError(
                f"--built-skill named {unknown!r}, not found in the loaded skill "
                f"library ({skills_dir})"
            )

        assemblies = assemble_all(categorization.tasks, library, built_skill_ids)
    except D48GuardError as exc:
        print(f"assemble.py: {exc}", file=sys.stderr)
        return 2
    except AssembleError as exc:
        print(f"assemble.py: {exc}", file=sys.stderr)
        return 3
    except frontmatter.FrontmatterError as exc:
        print(f"assemble.py: library entry failed to parse: {exc}", file=sys.stderr)
        return 4

    snapshot_hash = compute_library_snapshot_hash(library)
    rows = group_into_rows(assemblies)

    substitutions = {
        "FEATURE": categorization.feature,
        "TASK_COUNT": str(len(categorization.tasks)),
        "TASKS_SHA": categorization.tasks_sha or "unknown",
        "LIBRARY_SNAPSHOT_HASH": snapshot_hash,
        "ROSTER_ROWS": render_roster_table(rows),
        "EMPTY_LANE_NOTES": render_empty_lane_notes(assemblies),
        "DROPPED_SKILL_NOTES": render_dropped_notes(assemblies),
    }

    try:
        template_text = template_path.read_text(encoding="utf-8")
        rendered = render_assignment_md(template_text, substitutions)
    except OSError as exc:
        print(f"assemble.py: could not read template {template_path}: {exc}", file=sys.stderr)
        return 3
    except AssembleError as exc:
        print(f"assemble.py: {exc}", file=sys.stderr)
        return 3

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(rendered, encoding="utf-8")

    gap_ids = [a.task.task_id for a in assemblies if a.skill_gap]
    empty_lane_ids = [a.task.task_id for a in assemblies if a.empty_lane]
    dropped_count = sum(len(a.dropped) for a in assemblies)

    print(
        f"assemble.py: wrote {output_path} "
        f"({len(rows)} roster row(s) over {len(categorization.tasks)} task(s))"
    )
    print(f"GAP_TASKS: {','.join(gap_ids)}")
    if empty_lane_ids:
        print(f"assemble.py: empty lane (FR-016) on: {', '.join(empty_lane_ids)}")
    if dropped_count:
        print(f"assemble.py: {dropped_count} skill(s) dropped by the cap (FR-011/SC-004)")
    print(f"LIBRARY_SNAPSHOT_HASH: {snapshot_hash}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
