#!/usr/bin/env python3
"""frontmatter.py -- the one shared `specseyal:` frontmatter parser (S21).

Contracts implemented, verbatim:
  - docs/contracts/agent-library-schema.md S1.1  (base specialist shape)
  - docs/contracts/agent-library-schema.md S2    (body_sha256, defined exactly)
  - docs/contracts/skill-module.md S1            (skill module shape)
  - specs/003-workforce/research.md R2           (decision: one shared stdlib
    parser, no PyYAML -- the shape is a closed contract, not arbitrary YAML)
  - specs/003-workforce/data-model.md S2/S3      (the base/skill fields)

This module is imported by BOTH `assemble.py` and `validate-skill.py` (R2)
so there is exactly one place that knows how a `specseyal:` block is
shaped -- never two hand-rolled copies that can silently diverge (the same
divergence hazard that motivated rejecting Bash for the matcher, R1).

It is deliberately NOT a general YAML parser (alternative (b) in R2 was
rejected as over-engineering for a closed, contract-defined shape). It
understands exactly the syntactic forms the two contracts actually use:

  - a two-fence `---` frontmatter header followed by a body
  - block mappings, indented with spaces (`key:` / `key: value`)
  - flow lists                        (`[a, b, c]`, `[]`)
  - flow mappings                     (`{ k: v, k: v }`, `{}` -- both styles
    appear for provenance/stats/central across the two contract files)
  - scalars: quoted strings, plain strings, `null` / `~` / empty, `true` /
    `false`, integers, floats
  - YAML's own plain-scalar line folding (used by `description:`), and
    trailing `# comment` stripping (used by the contracts' own examples,
    e.g. `tools: ... # the immutable core -- see S4.1`)

Nothing else. Block (`- item`) lists, anchors, tags, multi-document
markers and block scalars (`|`, `>`) are all outside the closed shape; a
file that uses them fails to parse with a clear `FrontmatterError` rather
than being silently misread.

Every function here is pure (no I/O, no module-level state) except
`parse_entry`, which is the file-reading convenience wrapper around the
three pure primitives. Nothing executes at import time beyond `def`s.
"""

from __future__ import annotations

import hashlib
from pathlib import Path
from typing import Any

__all__ = [
    "FrontmatterError",
    "split_frontmatter",
    "body_sha256",
    "parse_frontmatter",
    "parse_entry",
]


class FrontmatterError(ValueError):
    """The `.md` file does not conform to the closed frontmatter shape this
    module understands: missing/malformed fences, or a line that is not
    valid `key:` / `key: value` at its expected indentation. Always raised
    with a message naming what was expected and, where possible, the
    offending line -- "fail clearly", per T004's brief.
    """


_FENCE = "---"


# ---------------------------------------------------------------------------
# 1. Fence splitting + body hashing -- agent-library-schema.md S2
# ---------------------------------------------------------------------------


def split_frontmatter(content: str) -> tuple[str, str]:
    """Split a `.md` file's content into `(frontmatter_text, body_text)`.

    `frontmatter_text` is everything between the two `---` fence lines
    (neither fence line itself included), taken verbatim.

    `body_text` is everything after the CLOSING fence's line and its
    newline, taken verbatim -- no trimming, no normalization. It is
    byte-for-byte (char-for-char, before UTF-8 encoding) what

        sed '1,/^---$/d; 1,/^---$/d' <file> | shasum -a 256

    would hash: the first `1,/^---$/d` deletes everything through the
    OPENING fence, the second deletes everything through the CLOSING
    fence (now line 1 of what remains), leaving exactly the body. Pass
    the result straight to `body_sha256`.

    Raises `FrontmatterError` if the file does not open with a lone
    `---` line, or no closing `---` line can be found.
    """
    if not content.startswith(_FENCE):
        raise FrontmatterError(
            "frontmatter missing: file must start with a lone '---' fence line"
        )

    first_nl = content.find("\n")
    first_line = content if first_nl == -1 else content[:first_nl]
    if first_line.rstrip("\r") != _FENCE:
        raise FrontmatterError(
            f"frontmatter missing: first line must be exactly '---', got {first_line!r}"
        )
    if first_nl == -1:
        raise FrontmatterError(
            "frontmatter malformed: file contains only the opening fence, no body"
        )

    search_pos = first_nl + 1
    while True:
        nl = content.find("\n", search_pos)
        line = content[search_pos:] if nl == -1 else content[search_pos:nl]
        if line.rstrip("\r") == _FENCE:
            frontmatter_text = content[first_nl + 1 : search_pos]
            body_text = "" if nl == -1 else content[nl + 1 :]
            return frontmatter_text, body_text
        if nl == -1:
            raise FrontmatterError(
                "frontmatter malformed: no closing '---' fence line found"
            )
        search_pos = nl + 1


def body_sha256(body_text: str) -> str:
    """sha256 hexdigest of `body_text`, encoded as UTF-8 bytes.

    This IS the `agent-library-schema.md` S2 reference definition
    (`sed '1,/^---$/d; 1,/^---$/d' | shasum -a 256`) applied to the
    `body_text` `split_frontmatter` returns: no trimming, no
    normalization, UTF-8 bytes straight into sha256.
    """
    return hashlib.sha256(body_text.encode("utf-8")).hexdigest()


# ---------------------------------------------------------------------------
# 2. The closed-shape block parser
#    agent-library-schema.md S1.1 (base) / skill-module.md S1 (skill)
# ---------------------------------------------------------------------------


def parse_frontmatter(frontmatter_text: str) -> dict[str, Any]:
    """Parse a `specseyal:` frontmatter block into a plain `dict`.

    Returns the FULL top-level frontmatter -- `name`, `description`, and
    (bases only) `tools` / `model` -- plus `specseyal` as a nested dict;
    not just the `specseyal:` sub-block. Both consumers need the outer
    keys: `assemble.py` reads `model` off a base, and `validate-skill.py`
    rule 1 (skill-module.md S6) must see that `model` is ABSENT on a
    skill, which only the outer dict exposes.

    Handles both shapes via the shared `specseyal.kind` discriminator
    (`parsed["specseyal"]["kind"] == "base" | "skill"`):
      - base:  agent-library-schema.md S1.1 (taxonomy.type / .specialization)
      - skill: skill-module.md S1            (taxonomy.tags, grants, stats)

    Raises `FrontmatterError` on a line that is not valid `key:` /
    `key: value` at its expected indentation.
    """
    lines = frontmatter_text.split("\n")
    result, _ = _parse_block(lines, 0, 0)
    return result


def _parse_block(lines: list[str], start: int, indent: int) -> tuple[dict[str, Any], int]:
    """Parse consecutive `key: value` entries at exactly `indent` leading
    spaces, starting at `lines[start]`. Stops at the first non-blank line
    with LESS indentation (or end of input). Returns `(dict, next_index)`.
    """
    result: dict[str, Any] = {}
    i, n = start, len(lines)
    while i < n:
        raw = lines[i]
        if raw.strip() == "":
            i += 1
            continue
        cur_indent = len(raw) - len(raw.lstrip(" "))
        if cur_indent < indent:
            break
        if cur_indent > indent:
            raise FrontmatterError(
                f"unexpected indentation ({cur_indent} spaces, expected {indent}): {raw!r}"
            )

        key, rest = _split_key_value(raw[indent:])
        if key is None:
            raise FrontmatterError(f"expected 'key:' or 'key: value', got: {raw!r}")
        i += 1

        if rest.strip() == "":
            # Empty value: either a nested block follows (more-indented
            # content ahead) or this is a bare null (nothing follows at
            # a deeper indent -- e.g. skill-module.md S1's own
            # `body_sha256: ` template line).
            j = i
            while j < n and lines[j].strip() == "":
                j += 1
            nxt_indent = (len(lines[j]) - len(lines[j].lstrip(" "))) if j < n else -1
            if nxt_indent > indent:
                value, i = _parse_block(lines, j, nxt_indent)
            else:
                value = None
        else:
            value, consumed = _parse_scalar_with_folding(rest, lines, i, indent)
            i += consumed

        result[key] = value
    return result, i


def _split_key_value(line: str) -> tuple[str | None, str]:
    """Split one un-indented `key: value` (or bare `key:`) line.

    The separator is the FIRST `': '` (colon-space) -- not the first bare
    colon -- so a value that itself contains a colon (e.g.
    `description: Handles X: Y`) still splits at the true key/value
    boundary: the key precedes the value, so the key's own colon-space is
    always the leftmost `': '` in the line. This mirrors YAML's own rule
    that only `': '` (or a trailing `':'`) ends a plain-scalar key.

    Returns `(None, "")` if `line` is not a valid key line.
    """
    idx = line.find(": ")
    if idx != -1:
        return line[:idx].strip(), line[idx + 2 :]
    stripped = line.rstrip("\r")
    if stripped.endswith(":"):
        return stripped[:-1].strip(), ""
    return None, ""


def _parse_scalar_with_folding(
    first: str, lines: list[str], i: int, key_indent: int
) -> tuple[Any, int]:
    """Parse a scalar value that starts on the key's own line, folding in
    any following lines indented MORE than the key -- YAML's plain-scalar
    line folding (join with a single space), used by `description:`.

    A flow list/map or a quoted string never folds across lines in these
    contracts' examples, so those short-circuit immediately with
    `consumed == 0`.
    """
    first = _strip_trailing_comment(first).strip()
    if first[:1] in ("[", "{", "'", '"'):
        return _parse_scalar_token(first), 0

    parts = [first] if first != "" else []
    consumed = 0
    n = len(lines)
    j = i
    while j < n:
        raw = lines[j]
        if raw.strip() == "":
            break
        cur_indent = len(raw) - len(raw.lstrip(" "))
        if cur_indent <= key_indent:
            break
        piece = _strip_trailing_comment(raw.strip())
        if piece != "":
            parts.append(piece)
        consumed += 1
        j += 1

    return _parse_scalar_token(" ".join(parts)), consumed


def _strip_trailing_comment(s: str) -> str:
    """Strip a trailing `  # comment` (quote-aware) the way the contracts'
    own examples use them, e.g. `kind: base   # base | (skills use
    skill-module.md)`. A `#` inside a quoted string is left alone.
    """
    in_quote = ""
    for idx, ch in enumerate(s):
        if in_quote:
            if ch == in_quote:
                in_quote = ""
            continue
        if ch in ("'", '"'):
            in_quote = ch
        elif ch == "#" and (idx == 0 or s[idx - 1].isspace()):
            return s[:idx].rstrip()
    return s


def _parse_scalar_token(s: str) -> Any:
    """Parse one fully-assembled scalar: quoted string, flow list/map,
    `null` / `~` / empty, `true` / `false`, int, float, else a plain
    string (this is where ids, kebab-tags, and semver-as-string like
    `1.0.0` all land -- semver never collides with int/float parsing).
    """
    s = s.strip()
    if s == "" or s == "~" or s.lower() == "null":
        return None
    if len(s) >= 2 and s[0] == s[-1] == '"':
        return s[1:-1]
    if len(s) >= 2 and s[0] == s[-1] == "'":
        return s[1:-1]
    if s.startswith("[") and s.endswith("]"):
        return _parse_flow_list(s)
    if s.startswith("{") and s.endswith("}"):
        return _parse_flow_map(s)
    if s.lower() == "true":
        return True
    if s.lower() == "false":
        return False
    try:
        return int(s)
    except ValueError:
        pass
    try:
        return float(s)
    except ValueError:
        pass
    return s


def _parse_flow_list(s: str) -> list[Any]:
    """`[a, b, c]` / `[]` -- used by `taxonomy.type`, `taxonomy.tags`,
    `grants`. Items are simple scalars in every contract example (never a
    nested flow list/map), so a plain comma-split is exact and sufficient.
    """
    inner = s[1:-1].strip()
    if inner == "":
        return []
    return [_parse_scalar_token(item) for item in inner.split(",")]


def _parse_flow_map(s: str) -> dict[str, Any]:
    """`{ k: v, k: v }` / `{}` -- the compact form `provenance:` /
    `stats:` / `central:` may take (skill-module.md S5's seed-module
    example uses it; the equivalent block form is handled by
    `_parse_block`'s recursion). Keys and values here are always simple
    identifiers/scalars with no embedded colons, so splitting each piece
    on the first bare colon is exact.
    """
    inner = s[1:-1].strip()
    if inner == "":
        return {}
    result: dict[str, Any] = {}
    for piece in inner.split(","):
        piece = piece.strip()
        if piece == "":
            continue
        key, _, val = piece.partition(":")
        result[key.strip()] = _parse_scalar_token(val)
    return result


# ---------------------------------------------------------------------------
# 3. File-level convenience. The three primitives above are the
#    independently-testable surface (T005); this just saves both
#    consumers from re-deriving the same read+split+parse glue -- S21's
#    whole point is that this happens in exactly one place.
# ---------------------------------------------------------------------------


def parse_entry(path: str | Path) -> dict[str, Any]:
    """Read a library entry (`.claude/agents/*.md` or
    `.claude/skills/*/SKILL.md`) and return:

        {"frontmatter": <dict>, "body": <str>, "body_sha256": <str>}

    `frontmatter` is `parse_frontmatter`'s dict; `body` is the verbatim
    body text; `body_sha256` is `body_sha256(body)` -- compare it against
    `frontmatter["specseyal"]["central"]["body_sha256"]` to detect drift
    (agent-library-schema.md S2's whole reason for existing: the registry
    detecting a repo that edited a shared entry without bumping version).
    """
    content = Path(path).read_text(encoding="utf-8")
    frontmatter_text, body_text = split_frontmatter(content)
    return {
        "frontmatter": parse_frontmatter(frontmatter_text),
        "body": body_text,
        "body_sha256": body_sha256(body_text),
    }


if __name__ == "__main__":
    # Light smoke test over small inline fixtures, self-consistent (no
    # dependency on transcribing a large external example, which would
    # risk a false failure from one stray character). Full independent
    # unit tests are T005 (extensions/workforce/test/test_frontmatter.py).

    _BASE_FIXTURE = (
        "---\n"
        "name: agt-example\n"
        "description: One line, then a folded\n"
        "  continuation that YAML joins with a space.\n"
        "tools: Read, Write, Edit, Bash, Glob, Grep     # the immutable core\n"
        "model: sonnet\n"
        "\n"
        "specseyal:\n"
        '  schema_version: "2.0"\n'
        "  kind: base                                   # base | (skills use skill-module.md)\n"
        "  id: agt_example\n"
        "  version: 1.0.0\n"
        "\n"
        "  taxonomy:\n"
        "    type: [service, endpoint]\n"
        "    specialization: backend-service\n"
        "\n"
        "  provenance:\n"
        "    created: 2026-07-09\n"
        "    created_by: human\n"
        "\n"
        "  central:\n"
        "    synced: false\n"
        "    remote_id: null\n"
        "    body_sha256: null\n"
        "---\n"
        "line one of the body\n"
        "line two of the body\n"
    )

    fm_text, body = split_frontmatter(_BASE_FIXTURE)
    parsed = parse_frontmatter(fm_text)

    assert parsed["name"] == "agt-example"
    assert parsed["description"] == (
        "One line, then a folded continuation that YAML joins with a space."
    )
    assert parsed["tools"] == "Read, Write, Edit, Bash, Glob, Grep"  # comment stripped
    assert parsed["model"] == "sonnet"
    sx = parsed["specseyal"]
    assert sx["kind"] == "base"  # trailing comment stripped
    assert sx["schema_version"] == "2.0"  # quoted -> stays a string, not a float
    assert sx["version"] == "1.0.0"  # semver -> stays a string
    assert sx["taxonomy"] == {
        "type": ["service", "endpoint"],
        "specialization": "backend-service",
    }
    assert sx["provenance"] == {"created": "2026-07-09", "created_by": "human"}
    assert sx["central"] == {"synced": False, "remote_id": None, "body_sha256": None}
    assert body == "line one of the body\nline two of the body\n"
    assert body_sha256(body) == hashlib.sha256(body.encode("utf-8")).hexdigest()

    _SKILL_FIXTURE = (
        "---\n"
        "name: skl-example\n"
        "description: A skill.\n"
        "\n"
        "specseyal:\n"
        "  kind: skill\n"
        "  id: skl_example\n"
        "  version: 1.0.0\n"
        "  taxonomy:\n"
        "    tags: [refactor, blast-radius]\n"
        "  grants: [web_search]\n"
        "  provenance: { created: 2026-07-09, created_by: human, source_feature: null,"
        " promoted_at: null }\n"
        "  stats: { assignments: 0, success_rate: null, last_used: null }\n"
        "  central: { synced: false, remote_id: null, body_sha256: null }\n"
        "---\n"
        "Additive-only body.\n"
    )
    fm2, body2 = split_frontmatter(_SKILL_FIXTURE)
    parsed2 = parse_frontmatter(fm2)
    assert "model" not in parsed2  # skills carry no model (skill-module.md S6 rule 1)
    sx2 = parsed2["specseyal"]
    assert sx2["kind"] == "skill"
    assert sx2["taxonomy"] == {"tags": ["refactor", "blast-radius"]}
    assert sx2["grants"] == ["web_search"]
    # flow-map form (skill-module.md S5's compact style) parses the same as block form:
    assert sx2["stats"] == {"assignments": 0, "success_rate": None, "last_used": None}
    assert sx2["central"] == {"synced": False, "remote_id": None, "body_sha256": None}

    # split_frontmatter fails clearly on malformed fences.
    for bad in ("no fence at all", "---\nonly one fence\nno close"):
        try:
            split_frontmatter(bad)
        except FrontmatterError:
            pass
        else:
            raise AssertionError(f"expected FrontmatterError for: {bad!r}")

    print("frontmatter.py: self-check OK")
