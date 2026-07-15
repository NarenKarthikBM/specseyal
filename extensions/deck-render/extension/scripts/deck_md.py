#!/usr/bin/env python3
"""deck_md.py -- markdown -> ordered block model (data-model.md S2 / S4).

Parses a council defense-deck markdown file (`council/defense-deck/*.md`)
into an ORDERED list of `Block`s over a deliberately narrow, censused
construct set -- the set actually observed across all ten committed decks
(data-model.md S2). `render.py` (T015) imports `parse()` to get blocks in
source order and maps each one to slide content per the T1-T10 transform
rules (data-model.md S4). This module owns ONLY the parse: it never lays
anything out, never strips inline markers (T9 is `render.py`'s job), and
never authors text of its own (T10).

The guardrail this module exists to be: ANY construct outside the census
below is a LOUD FAILURE (`DeckMdError`, naming the offending 1-indexed
source line) -- never a silent simplification, drop, or best-effort
reinterpretation. `render.py` can trust that every `Block` it receives is
one of the ten kinds below; nothing else can reach it.

Censused constructs (data-model.md S2) -> `Block.kind`:
  - H1, H2, H3 headings (ATX `#`/`##`/`###` only; H4+ is out of census)
  - flat bullets (`- `, zero nesting)
  - numbered items (`1. `, zero nesting)
  - blockquotes (`> `, contiguous lines merged into one block)
  - GFM pipe tables, 2-5 columns, a bare `|---|` separator (no alignment
    specs)
  - fenced code, bare ``` ``` ``` or ` ```text ` only, content preserved
    BYTE-EXACT (no reflow, no processing of any kind)
  - `---` horizontal rules (structural; carry no text)
  - paragraphs (the catch-all for plain text lines; contiguous plain
    lines merge into one block, joined with a single space -- markdown's
    own soft-break-within-a-paragraph semantics)

Out of census (data-model.md S2 "Links / images / raw HTML | none";
task brief's explicit list) -- every one of these raises `DeckMdError`
rather than being silently dropped or reinterpreted:
  frontmatter, links (`[t](u)` / `[t][r]`), images (`![t](u)`), raw HTML
  / autolinks, nested/indented bullets or numbered items, H4+ headings,
  setext headings (`Title\n=====` / `Title\n-----`), task-list items
  (`- [ ]` / `- [x]`), footnote refs/definitions (`[^n]`), definition
  lists (`term\n: definition`).

Block schema (the contract `render.py` consumes)
--------------------------------------------------
`Block` is one frozen dataclass, tagged by `kind`; only the fields that
kind actually uses are populated, everything else keeps its empty
default. `line` is always the 1-indexed source line the block begins at
(for error/debug traceability downstream; not itself rendered).

  kind="h1"|"h2"|"h3"   text            heading text (inline markup, e.g.
                                         `**bold**`, left INTACT -- T9's
                                         stripping is render.py's job)
  kind="paragraph"      text            merged plain-text line(s)
  kind="bullet"         text            one flat bullet item's text
  kind="numbered"       number, text    `number` is the literal digits as
                                         written (e.g. "1", "12"); `text`
                                         is the item body
  kind="blockquote"     text            merged `> `-prefixed line(s),
                                         `> ` prefix stripped
  kind="table"          header, rows    `header`: tuple of 2-5 raw cell
                                         strings. `rows`: tuple of body
                                         rows, each a same-length tuple of
                                         raw cell strings. The `|---|`
                                         separator row itself carries no
                                         text and is not represented.
  kind="code"           lang, lines     `lang` is `""` (bare fence) or
                                         `"text"`. `lines` is a tuple of
                                         the fence's content lines,
                                         BYTE-EXACT, in source order, no
                                         processing whatsoever.
  kind="hr"             (none)          structural only; carries no text.

Source order is preserved exactly (T5): `parse()` returns blocks in the
order their constructs appear in the source text, and never reorders,
merges across, or drops anything from that order.

Caller responsibilities NOT enforced here (deliberately, to keep this
module's job to "is this construct in the census", not deck semantics):
  - Exactly-one-H1-per-file (data-model.md S2 notes it as the corpus's
    reality, used by T1 as the title slide) is `render.py`'s concern.
  - T9 inline-marker stripping (`**bold**` -> bold text) is `render.py`'s
    concern; heading/paragraph/bullet/etc. `text` fields here still carry
    raw markdown inline syntax.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path

__all__ = [
    "DeckMdError",
    "Block",
    "H1",
    "H2",
    "H3",
    "PARAGRAPH",
    "BULLET",
    "NUMBERED",
    "BLOCKQUOTE",
    "TABLE",
    "CODE",
    "HR",
    "KINDS",
    "parse",
    "parse_file",
]


class DeckMdError(ValueError):
    """The input markdown contains a construct outside the censused set
    (data-model.md S2). Always raised with a message naming the
    offending 1-indexed source line and what was out of census -- never
    raised silently, and `deck_md.py` never simplifies around one of
    these instead of raising.
    """


# ---------------------------------------------------------------------------
# Block kinds and the schema documented in the module docstring above.
# ---------------------------------------------------------------------------

H1 = "h1"
H2 = "h2"
H3 = "h3"
PARAGRAPH = "paragraph"
BULLET = "bullet"
NUMBERED = "numbered"
BLOCKQUOTE = "blockquote"
TABLE = "table"
CODE = "code"
HR = "hr"

KINDS = frozenset({H1, H2, H3, PARAGRAPH, BULLET, NUMBERED, BLOCKQUOTE, TABLE, CODE, HR})


@dataclass(frozen=True)
class Block:
    """One block of the ordered model. `kind` is one of `KINDS`; only the
    fields that kind uses (per the docstring's schema table) are ever
    populated -- everything else keeps its empty default.
    """

    kind: str
    line: int
    text: str = ""
    number: str = ""
    header: tuple[str, ...] = ()
    rows: tuple[tuple[str, ...], ...] = ()
    lang: str = ""
    lines: tuple[str, ...] = field(default_factory=tuple)


# ---------------------------------------------------------------------------
# Line-level construct patterns -- the censused set.
# ---------------------------------------------------------------------------

_ATX = re.compile(r"^(#{1,6})(?:\s+(.*))?\s*$")
_FENCE_OPEN = re.compile(r"^```(?!`)(.*)$")
_BLOCKQUOTE = re.compile(r"^>\s?(.*)$")
_BULLET = re.compile(r"^-\s+(.*)$")
_NUMBERED = re.compile(r"^(\d+)\.\s+(.*)$")
_NESTED_BULLET = re.compile(r"^\s+-\s+(.*)$")
_NESTED_NUMBERED = re.compile(r"^\s+\d+\.\s+(.*)$")
_DEF_LIST = re.compile(r"^:\s+(.*)$")
_TASK = re.compile(r"^\[[ xX]\]\s+")
_DASH_RUN = re.compile(r"^-+$")
_EQ_RUN = re.compile(r"^=+$")
_HR = re.compile(r"^-{3,}$")
_SEP_CELL = re.compile(r"^:?-+:?$")

# Out-of-census inline constructs, checked against any text-bearing field
# (heading/paragraph/bullet/numbered/blockquote/table-cell text) -- never
# checked against fenced-code content, which is preserved byte-exact and
# never interpreted as markdown at all.
_IMAGE = re.compile(r"!\[[^\]]*\]\([^)]*\)")
_FOOTNOTE_REF = re.compile(r"\[\^[^\]]+\]")
_LINK_INLINE = re.compile(r"\[[^\]]*\]\([^)]*\)")
_LINK_REF = re.compile(r"\[[^\]]*\]\[[^\]]*\]")
_AUTOLINK = re.compile(r"<[a-zA-Z][a-zA-Z0-9+.-]*:[^ <>]+>")
_RAW_HTML = re.compile(r"</?[a-zA-Z][a-zA-Z0-9]*(?:\s[^<>]*)?/?>")
_CODE_SPAN = re.compile(r"`[^`]*`")


def _mask_code_spans(text: str) -> str:
    """Blank out single-backtick inline code spans before scanning for
    forbidden inline constructs. Per CommonMark, a backtick code span is
    inert -- nothing inside it is interpreted as other markdown syntax --
    and the corpus routinely writes CLI placeholders that way (e.g.
    `` `git checkout -b <id>` ``, `` `--feature <dir>` ``). Scanning the
    raw text would misfire on those as "raw HTML"; scanning the masked
    text does not, while an actual link/image/HTML construct OUTSIDE a
    code span is still caught untouched. The stored `Block.text` is never
    touched by this -- only the copy used for this check.
    """
    return _CODE_SPAN.sub("", text)


def _check_inline(text: str, line_no: int) -> None:
    """Raise `DeckMdError` if `text` carries an out-of-census inline
    construct (image, footnote ref, link, raw HTML/autolink) OUTSIDE any
    inline code span. Checked against every text-bearing field this
    module produces -- headings, paragraphs, bullets, numbered items,
    blockquotes, table cells.
    """
    scan = _mask_code_spans(text)
    if _IMAGE.search(scan):
        raise DeckMdError(
            f"line {line_no}: image syntax is out of census "
            f"(no deck in the corpus carries one): {text!r}"
        )
    if _FOOTNOTE_REF.search(scan):
        raise DeckMdError(
            f"line {line_no}: footnote syntax ('[^...]') is out of census: {text!r}"
        )
    if _LINK_INLINE.search(scan) or _LINK_REF.search(scan):
        raise DeckMdError(
            f"line {line_no}: link syntax is out of census "
            f"(no deck in the corpus carries one): {text!r}"
        )
    if _AUTOLINK.search(scan) or _RAW_HTML.search(scan):
        raise DeckMdError(
            f"line {line_no}: raw HTML / autolink syntax is out of census: {text!r}"
        )


def _strip_atx_closing(s: str) -> str:
    """Strip an ATX heading's optional closing `#`s (`# Title #` -> `# Title`)."""
    return re.sub(r"\s+#+\s*$", "", s.rstrip())


def _split_row(line: str) -> list[str]:
    """Split one GFM pipe-table row into raw (unstripped-of-markup) cell
    strings. Handles the optional leading/trailing `|` and `\\|` escapes;
    does not otherwise interpret cell content.
    """
    s = line.strip()
    if s.startswith("|"):
        s = s[1:]
    if s.endswith("|") and not s.endswith("\\|"):
        s = s[:-1]
    cells: list[str] = []
    cur: list[str] = []
    i, n = 0, len(s)
    while i < n:
        ch = s[i]
        if ch == "\\" and i + 1 < n and s[i + 1] == "|":
            cur.append("|")
            i += 2
            continue
        if ch == "|":
            cells.append("".join(cur).strip())
            cur = []
            i += 1
            continue
        cur.append(ch)
        i += 1
    cells.append("".join(cur).strip())
    return cells


def _try_parse_table(lines: list[str], i: int) -> tuple[Block, int] | None:
    """Attempt to parse a GFM pipe table starting at 0-indexed `lines[i]`
    (the header row), with `lines[i + 1]` as the candidate separator row.

    Returns `None` if `lines[i + 1]` is not GFM separator syntax at all
    (every cell matching `:?-+:?`) -- meaning `lines[i]` is not actually a
    table header and should fall through to ordinary line classification
    (e.g. a paragraph that merely contains a literal `|`).

    Once the separator syntax is confirmed, this IS a table, and every
    further deviation from the census (alignment colons, wrong column
    count, a body row with a mismatched column count) is a loud
    `DeckMdError` -- never a silent best-effort table.
    """
    sep_line = lines[i + 1]
    if "|" not in sep_line:
        return None
    sep_cells = _split_row(sep_line)
    if not sep_cells or not all(_SEP_CELL.match(c) for c in sep_cells):
        return None

    header_line_no = i + 1
    sep_line_no = i + 2
    header_cells = _split_row(lines[i])

    if len(sep_cells) != len(header_cells):
        raise DeckMdError(
            f"line {sep_line_no}: table separator has {len(sep_cells)} column(s) "
            f"but the header row (line {header_line_no}) has {len(header_cells)}"
        )
    if any(":" in c for c in sep_cells):
        raise DeckMdError(
            f"line {sep_line_no}: table separator carries an alignment spec (':'), "
            "which is out of census -- only bare '|---|' separators appear in the corpus"
        )
    if not (2 <= len(header_cells) <= 5):
        raise DeckMdError(
            f"line {header_line_no}: table has {len(header_cells)} column(s); "
            "the census supports 2-5"
        )
    for cell in header_cells:
        _check_inline(cell, header_line_no)

    rows: list[tuple[str, ...]] = []
    j = i + 2
    n = len(lines)
    while j < n and lines[j].strip() != "" and "|" in lines[j]:
        row_cells = _split_row(lines[j])
        if len(row_cells) != len(header_cells):
            raise DeckMdError(
                f"line {j + 1}: table row has {len(row_cells)} column(s), "
                f"expected {len(header_cells)} to match the header (line {header_line_no})"
            )
        for cell in row_cells:
            _check_inline(cell, j + 1)
        rows.append(tuple(row_cells))
        j += 1

    block = Block(kind=TABLE, line=header_line_no, header=tuple(header_cells), rows=tuple(rows))
    return block, j


# ---------------------------------------------------------------------------
# The parser.
# ---------------------------------------------------------------------------


def parse(text: str) -> list[Block]:
    """Parse `text` (a defense-deck markdown file's full contents, `\\n`
    line endings -- as `Path.read_text()` gives via universal-newline
    translation) into an ordered `list[Block]`.

    Raises `DeckMdError`, naming the offending 1-indexed source line, on
    any construct outside the censused set (see module docstring).
    Never drops, reorders, or silently reinterprets content: source
    order is preserved exactly (T5), fenced-code content is preserved
    byte-exact with no reflow (T6), and the blockquote preamble is kept
    as ordinary content (never dropped).
    """
    lines = text.split("\n")
    n = len(lines)
    blocks: list[Block] = []

    para_lines: list[str] = []
    para_start = 0
    bq_lines: list[str] = []
    bq_start = 0
    prev_was_para = False

    def flush_para() -> None:
        nonlocal para_lines
        if para_lines:
            blocks.append(Block(kind=PARAGRAPH, line=para_start, text=" ".join(para_lines)))
            para_lines = []

    def flush_bq() -> None:
        nonlocal bq_lines
        if bq_lines:
            blocks.append(Block(kind=BLOCKQUOTE, line=bq_start, text=" ".join(bq_lines)))
            bq_lines = []

    def flush_all() -> None:
        flush_para()
        flush_bq()

    i = 0
    while i < n:
        raw = lines[i]
        line_no = i + 1
        stripped = raw.strip()

        if stripped == "":
            flush_all()
            prev_was_para = False
            i += 1
            continue

        # A leading '---' as the file's literal first line reads as a YAML
        # frontmatter fence, not a horizontal rule -- and no deck in the
        # corpus carries frontmatter (data-model.md S2).
        if i == 0 and stripped == "---":
            raise DeckMdError(
                "line 1: a leading '---' fence looks like YAML frontmatter, "
                "which is out of census (no deck in the corpus carries one)"
            )

        # Fenced code -- bare ``` or ```text only; content byte-exact, no reflow.
        m = _FENCE_OPEN.match(raw)
        if m is not None:
            flush_all()
            prev_was_para = False
            lang = m.group(1).strip()
            if lang not in ("", "text"):
                raise DeckMdError(
                    f"line {line_no}: fenced code info string {lang!r} is out of "
                    "census (only bare ``` or ```text fences appear in the corpus)"
                )
            start = line_no
            i += 1
            content: list[str] = []
            closed = False
            while i < n:
                if lines[i] == "```":
                    closed = True
                    i += 1
                    break
                content.append(lines[i])
                i += 1
            if not closed:
                raise DeckMdError(f"line {start}: fenced code block not closed before end of file")
            blocks.append(Block(kind=CODE, line=start, lang=lang, lines=tuple(content)))
            continue

        # ATX headings -- H1-H3 only; H4+ is out of census.
        m = _ATX.match(raw)
        if m is not None:
            flush_all()
            prev_was_para = False
            level = len(m.group(1))
            if level >= 4:
                raise DeckMdError(
                    f"line {line_no}: H{level} heading is out of census "
                    "(only H1-H3 appear in the corpus)"
                )
            heading_text = _strip_atx_closing((m.group(2) or "").strip())
            _check_inline(heading_text, line_no)
            blocks.append(Block(kind={1: H1, 2: H2, 3: H3}[level], line=line_no, text=heading_text))
            i += 1
            continue

        # Setext headings ('Title' immediately followed, no blank line, by
        # an all-'=' or all-'-' underline) are out of census -- only ATX
        # '#' headings appear in the corpus. Must be checked before HR,
        # since a bare '---' run is ambiguous between HR and a setext H2
        # underline; adjacency to an in-progress paragraph disambiguates.
        if prev_was_para and (_DASH_RUN.match(stripped) or _EQ_RUN.match(stripped)):
            raise DeckMdError(
                f"line {line_no}: setext heading underline is out of census "
                "(only ATX '#' headings appear in the corpus)"
            )

        # '---' horizontal rule -- structural, carries no text.
        if _HR.match(stripped):
            flush_all()
            prev_was_para = False
            blocks.append(Block(kind=HR, line=line_no))
            i += 1
            continue

        # Blockquote -- contiguous '> ' lines merge into one block.
        m = _BLOCKQUOTE.match(raw)
        if m is not None:
            flush_para()
            prev_was_para = False
            if not bq_lines:
                bq_start = line_no
            _check_inline(m.group(1), line_no)
            bq_lines.append(m.group(1))
            i += 1
            continue
        flush_bq()

        # GFM pipe table (only if lines[i+1] is real separator syntax).
        if "|" in raw and i + 1 < n:
            result = _try_parse_table(lines, i)
            if result is not None:
                flush_all()
                prev_was_para = False
                block, next_i = result
                blocks.append(block)
                i = next_i
                continue

        # Nested/indented bullets and numbered items are out of census --
        # flat lists only, zero nesting anywhere in the corpus.
        if _NESTED_BULLET.match(raw):
            raise DeckMdError(
                f"line {line_no}: nested/indented bullet is out of census "
                "(flat bullets only, zero nesting)"
            )
        if _NESTED_NUMBERED.match(raw):
            raise DeckMdError(
                f"line {line_no}: nested/indented numbered item is out of census "
                "(flat lists only, zero nesting)"
            )

        # Flat bullet.
        m = _BULLET.match(raw)
        if m is not None:
            flush_all()
            prev_was_para = False
            item_text = m.group(1)
            if _TASK.match(item_text):
                raise DeckMdError(
                    f"line {line_no}: task-list item ('- [ ]' / '- [x]') is out of "
                    "census (plain flat bullets only)"
                )
            _check_inline(item_text, line_no)
            blocks.append(Block(kind=BULLET, line=line_no, text=item_text))
            i += 1
            continue

        # Numbered item.
        m = _NUMBERED.match(raw)
        if m is not None:
            flush_all()
            prev_was_para = False
            _check_inline(m.group(2), line_no)
            blocks.append(Block(kind=NUMBERED, line=line_no, number=m.group(1), text=m.group(2)))
            i += 1
            continue

        # Definition lists ('term' / ': definition') are out of census.
        if _DEF_LIST.match(raw):
            raise DeckMdError(
                f"line {line_no}: definition-list syntax (': definition') is out of census"
            )

        # Catch-all: a plain-text line, part of the current (or a new)
        # paragraph. Contiguous plain lines merge into one PARAGRAPH block.
        _check_inline(raw, line_no)
        if not para_lines:
            para_start = line_no
        para_lines.append(stripped)
        prev_was_para = True
        i += 1

    flush_all()
    return blocks


def parse_file(path: str | Path) -> list[Block]:
    """Convenience wrapper: read `path` as UTF-8 text (universal-newline
    translated, matching `frontmatter.py`'s `parse_entry` convention) and
    `parse()` it.
    """
    return parse(Path(path).read_text(encoding="utf-8"))


if __name__ == "__main__":
    # Self-check: a small in-memory sample covering every censused
    # construct parses cleanly, and a representative sample of
    # out-of-census constructs each raise `DeckMdError`. Full independent
    # coverage lives in extensions/deck-render/test/run.sh (Phase C).

    _GOOD = (
        "# Defense Deck Title\n"
        "\n"
        "> A blockquote preamble note, at the top -- the D15 format note.\n"
        "> A second preamble line.\n"
        "\n"
        "---\n"
        "\n"
        "## Section One\n"
        "\n"
        "A plain paragraph with curly quotes “like this” and an arrow →.\n"
        "\n"
        "- a flat bullet\n"
        "- another flat bullet with ≤ ∈ ⌊ ⌋ ×\n"
        "\n"
        "1. a numbered item\n"
        "2. a second numbered item\n"
        "\n"
        "### A Bold Lead Line\n"
        "\n"
        "| Col A | Col B | Col C |\n"
        "|---|---|---|\n"
        "| 1 | 2 | 3 |\n"
        "| 4 | 5 | 6 |\n"
        "\n"
        "```text\n"
        "┌────────┐\n"
        "│ box-drawn │\n"
        "└────────┘\n"
        "```\n"
    )

    blocks = parse(_GOOD)
    kinds_seen = [b.kind for b in blocks]
    for expected in (H1, BLOCKQUOTE, HR, H2, PARAGRAPH, BULLET, NUMBERED, H3, TABLE, CODE):
        assert expected in kinds_seen, f"expected a {expected!r} block, got kinds {kinds_seen}"
    assert kinds_seen == [
        H1, BLOCKQUOTE, HR, H2, PARAGRAPH, BULLET, BULLET, NUMBERED, NUMBERED, H3, TABLE, CODE,
    ], f"source order not preserved: {kinds_seen}"

    table_block = next(b for b in blocks if b.kind == TABLE)
    assert table_block.header == ("Col A", "Col B", "Col C")
    assert table_block.rows == (("1", "2", "3"), ("4", "5", "6"))

    code_block = next(b for b in blocks if b.kind == CODE)
    assert code_block.lang == "text"
    assert code_block.lines == (
        "┌────────┐",
        "│ box-drawn │",
        "└────────┘",
    ), "fenced content must survive byte-exact, no reflow"

    bq_block = next(b for b in blocks if b.kind == BLOCKQUOTE)
    assert bq_block.text == (
        "A blockquote preamble note, at the top -- the D15 format note. "
        "A second preamble line."
    )

    _BAD = {
        "markdown link": "# Title\n\nSee [the doc](https://example.com) for more.\n",
        "image": "# Title\n\n![alt text](image.png)\n",
        "nested bullet": "# Title\n\n- top level\n  - nested, out of census\n",
        "nested numbered": "# Title\n\n1. top level\n   1. nested, out of census\n",
        "H4": "# Title\n\n#### too deep\n",
        "task list": "# Title\n\n- [ ] unchecked item\n",
        "footnote": "# Title\n\nSee note[^1] for detail.\n",
        "definition list": "# Title\n\nTerm\n: a definition\n",
        "setext heading": "# Title\n\nA Paragraph Heading\n===================\n",
        "raw html": "# Title\n\nText with <div>raw html</div> inline.\n",
        "frontmatter": "---\ntitle: sneaky\n---\n\n# Title\n",
        "unclosed fence": "# Title\n\n```text\nunterminated\n",
        "bad fence lang": "# Title\n\n```python\nprint(1)\n```\n",
        "table alignment spec": "# Title\n\n| A | B |\n|:---|---:|\n| 1 | 2 |\n",
        "table too many columns": (
            "# Title\n\n| A | B | C | D | E | F |\n|---|---|---|---|---|---|\n| 1 | 2 | 3 | 4 | 5 | 6 |\n"
        ),
    }
    for label, bad_text in _BAD.items():
        try:
            parse(bad_text)
        except DeckMdError:
            pass
        else:
            raise AssertionError(f"expected DeckMdError for {label!r}")

    print("deck_md.py: self-check OK")
