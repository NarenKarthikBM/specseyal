# Provenance — `test/fixtures/deck/{technical.md,overview.md}`

Frozen golden fixture pair for the deck-render extension (`specs/006-deck-render`,
T018/S08). Consumed by T019 (SC-003 bidirectional fidelity, incl. block-sequence
order), T020 (SC-002 derived-render stamp), and T021 (T7 `(cont.)` overflow).

## Source

Seeded byte-identical (verified via `diff` + `md5`, zero drift) from the heaviest
real committed defense deck in the corpus:

- `specs/005-graphify-context/council/defense-deck/technical.md` (201 lines) →
  `technical.md`
- `specs/005-graphify-context/council/defense-deck/overview.md` (44 lines) →
  `overview.md`

No content was added, removed, or reworded in either file. No table cell was
extended — see "Overflow" below.

## Parse cleanliness (`deck_md.py` census)

Both files parse cleanly with zero `DeckMdError`s:

```
$ cd extensions/deck-render/extension/scripts && python3 -c "
import deck_md
deck_md.parse(open('../../test/fixtures/deck/technical.md', encoding='utf-8').read())
deck_md.parse(open('../../test/fixtures/deck/overview.md', encoding='utf-8').read())
print('parse OK')
"
parse OK
```

`technical.md` parses to 94 blocks, `overview.md` to 26 blocks — headings (H1-H3),
paragraphs, blockquote, `---` HR, GFM pipe tables (2-4 cols, bare `|---|`
separators), and one bare ` ```text ` fence carrying a box-drawing directory tree
(preserved byte-exact, per T6). No out-of-census construct (link, image, raw
HTML, nested list, H4+, footnote, task-list, definition list, setext heading,
frontmatter) is present in either file — no fixture modification was needed to
satisfy the census.

## Overflow (S08 — `render.py`'s `LINE_BUDGET_PER_SLIDE = 20`)

**`technical.md` forces the T7 `(cont.)` overflow branch as seeded, with no
modification required** — driven through `deck_md.parse()` →
`render._to_logical_slides()` → `render._split_for_overflow()`:

```
$ cd extensions/deck-render/extension/scripts && python3 -c "
import deck_md, render
text = open('../../test/fixtures/deck/technical.md', encoding='utf-8').read()
blocks = deck_md.parse(text)
logical = render._to_logical_slides(blocks)
physical = render._split_for_overflow(logical)
cont = [t for t, _ in physical if '(cont.)' in t]
print('total physical slides:', len(physical))
print('(cont.) slides:', len(cont))
"
total physical slides: 20
(cont.) slides: 12
```

12 of the deck's 20 physical slides are `(cont.)` continuations, spanning four
distinct H2 sections (`1. Problem Restatement`, `2. Chosen Approach & Rejected
Alternatives`, `3. Architecture & Data Flow` — five continuations alone, driven
by its long risk/rejected-alternatives table rows — `4. Project Structure &
Dependency / Graph Impact`, and `7. Testability Claim & Plan-Time
Verifications`). This is the real-world "long table cells overflow a slide"
shape the risk register's one High-likelihood row names, occurring naturally in
a real committed deck — no manufactured extension was needed to reach it.

`overview.md` is the companion one-page deck and is not required to force
overflow (S08 scopes the requirement to the technical deck only); it is left
unmodified.

## Byte-exactness

Both fixture files are byte-identical to their `005` sources (`diff` reports no
differences; `md5` matches):

| File | md5 |
|---|---|
| `technical.md` | `c524397b65fd58c719669733ba5705b1` |
| `overview.md` | `aa975eace5e54370a74f22adf6808f10` |

Frozen at commit time on branch `006-deck-render`; per golden-fixture discipline,
these files are not to be regenerated or reformatted going forward — any future
change to what they exercise is a deliberate, reviewed edit, not a silent
re-seed.
