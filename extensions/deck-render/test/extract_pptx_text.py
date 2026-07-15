#!/usr/bin/env python3
"""extract_pptx_text.py — independent stdlib OOXML text extractor (SC-003, R5).

Deliberately independent of `python-pptx`. This module imports nothing but
`zipfile` and `xml.etree.ElementTree` and reads a `.pptx` the way OOXML
actually stores it: a zip archive whose slide text lives as `<a:t>` runs
inside `ppt/slides/slideN.xml`, in the DrawingML namespace
(`http://schemas.openxmlformats.org/drawingml/2006/main`).

Why independence matters (data-model.md §4, plan.md Phase C): the whole
point of the SC-003 bidirectional fidelity check is to prove that what
`render.py` WROTE into the pptx matches what the source markdown SAID.
Reading the render back through `python-pptx` — the same library that wrote
it — would only prove the library round-trips its own output faithfully; a
writer-side bug that mis-encodes or drops text on the way out could just as
easily mis-decode or re-drop it on the way back in, and the two bugs would
cancel out and the check would pass while fidelity is actually broken. This
module never imports `pptx` / `python-pptx`, so it cannot share a bug with
the renderer. It is the independent oracle T019 (bidirectional fidelity),
T020 (stamp check), and T031 (staleness) all shell out to or import.

What this module returns — and, just as important, what it does NOT do:

  - Every `<a:t>` run's `.text`, in **slide order** (slides visited by their
    numeric suffix — `slide1.xml`, `slide2.xml`, ... `slide10.xml`,
    `slide11.xml` — sorted numerically, never lexically, since a lexical
    sort would put `slide10.xml` before `slide2.xml`) and in **document
    order within each slide** (the order `<a:t>` elements appear in the
    slide's XML tree — the same depth-first order `ElementTree.iter()`
    walks, which matches source/reading order for a well-formed OOXML
    slide: paragraph by paragraph, run by run, table cell by table cell).
  - A run with no text content (`<a:t/>` or `<a:t></a:t>`, whose `.text` is
    `None`) is returned as `""`, not skipped and not fabricated — it is a
    real run at a real position, just an empty one.
  - Text is returned **byte-exact / Unicode-exact**. This module performs
    NO normalization of any kind — no whitespace collapsing, no Unicode
    folding, no stripping. Curly quotes, em-dashes, arrows (`→ ≤ ∈ ⌊⌋ ×`),
    and box-drawing characters must survive exactly as OOXML stored them.
    data-model.md §4 places whitespace normalization on the CALLER (the
    fidelity check does whitespace-only normalization on both sides before
    comparing) — this extractor does not pre-empt that decision by doing
    any normalization itself.

Public API:

    extract_runs(path) -> list[str]
        Every `<a:t>` run's text, slide order then document order, exactly
        as described above. This is the primitive the other two are built on.

    extract_text(path, separator="\\n") -> str
        `separator.join(extract_runs(path))` — a single string, for callers
        that just want to do substring/containment checks (SC-003a/b) and
        don't care about individual run boundaries.

CLI:

    python3 extract_pptx_text.py <file.pptx>

    Prints every run on its own line, in the order `extract_runs` returns
    them (one run per output line — the documented separator is "\\n",
    matching `extract_text`'s default). A run that itself contains embedded
    newlines is not expected in OOXML (a:t runs do not carry them — line
    breaks inside a paragraph are separate `<a:br/>` elements, which this
    extractor does not represent as text), so "one run per line" is
    unambiguous in practice. Output is written as UTF-8 explicitly (via
    `sys.stdout.reconfigure`) so Unicode survives regardless of the host's
    locale settings. Exit code 0 on success; non-zero with a message on
    stderr for a missing file, a non-zip file, or a zip with no
    `ppt/slides/slideN.xml` members at all.
"""

from __future__ import annotations

import re
import sys
import zipfile
from xml.etree import ElementTree

# DrawingML namespace — where <a:t> (and <a:p>, <a:r>, ...) live.
_DRAWINGML_NS = "http://schemas.openxmlformats.org/drawingml/2006/main"
_A_T_TAG = f"{{{_DRAWINGML_NS}}}t"

# Matches ppt/slides/slideN.xml — deliberately anchored so it does NOT match
# ppt/slides/_rels/slideN.xml.rels or ppt/notesSlides/notesSlideN.xml, which
# carry rel bookkeeping / speaker notes, not slide body text.
_SLIDE_PATH_RE = re.compile(r"^ppt/slides/slide(\d+)\.xml$")


def _numbered_slide_members(names) -> list[tuple[int, str]]:
    """Filter a zip's namelist to slide XML members, paired with their
    numeric slide index, ready to sort numerically (not lexically)."""
    numbered = []
    for name in names:
        match = _SLIDE_PATH_RE.match(name)
        if match:
            numbered.append((int(match.group(1)), name))
    return numbered


def extract_runs(path: str) -> list[str]:
    """Return every `<a:t>` run's text from `path` (a .pptx file), in slide
    order (numeric) then document order within each slide. See the module
    docstring for the full contract: no normalization, Unicode preserved
    byte-exact, empty runs returned as `""`.

    Raises FileNotFoundError / zipfile.BadZipFile for a missing or
    non-pptx-shaped input, and xml.etree.ElementTree.ParseError for a slide
    whose XML is malformed — none of these are swallowed, since a silent
    empty result here would be exactly the kind of quiet failure the
    fidelity check exists to prevent.
    """
    runs: list[str] = []
    with zipfile.ZipFile(path) as archive:
        numbered_members = _numbered_slide_members(archive.namelist())
        # Numeric sort on the captured slide index — slide2 before slide10.
        numbered_members.sort(key=lambda pair: pair[0])
        for _, member_name in numbered_members:
            slide_xml = archive.read(member_name)
            root = ElementTree.fromstring(slide_xml)
            # .iter() walks the tree depth-first / pre-order, i.e. document
            # order — the same order the runs appear in the slide's source.
            for t_elem in root.iter(_A_T_TAG):
                runs.append(t_elem.text if t_elem.text is not None else "")
    return runs


def extract_text(path: str, separator: str = "\n") -> str:
    """`separator.join(extract_runs(path))` — convenience for callers doing
    plain substring/containment checks rather than per-run comparison."""
    return separator.join(extract_runs(path))


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        sys.stderr.write(f"usage: {argv[0]} <file.pptx>\n")
        return 2

    pptx_path = argv[1]

    try:
        runs = extract_runs(pptx_path)
    except FileNotFoundError:
        sys.stderr.write(f"error: no such file: {pptx_path}\n")
        return 1
    except zipfile.BadZipFile:
        sys.stderr.write(f"error: not a valid .pptx (zip) file: {pptx_path}\n")
        return 1
    except ElementTree.ParseError as exc:
        sys.stderr.write(f"error: malformed slide XML in {pptx_path}: {exc}\n")
        return 1

    if not runs and not zipfile.is_zipfile(pptx_path):
        # Unreachable in practice (extract_runs would already have raised
        # BadZipFile above), kept only as a defensive belt-and-braces check.
        sys.stderr.write(f"error: not a valid .pptx (zip) file: {pptx_path}\n")
        return 1

    # Reconfigure stdout to UTF-8 explicitly so Unicode (curly quotes,
    # arrows, box-drawing) survives byte-exact regardless of host locale.
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")

    for run in runs:
        print(run)

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
