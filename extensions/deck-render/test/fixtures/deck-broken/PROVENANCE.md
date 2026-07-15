# Provenance — `test/fixtures/deck-broken/{technical.md,overview.md}`

The **asymmetric fixture pair** for the deck-render extension (`specs/006-deck-render`, T027/S02).
Consumed by T029 (partial-failure exit-2: run the pair under `deck_render: both`, assert
render-good / fail-broken / disclose-both / exit 2 — I-B2's per-deck isolation invariant made
mechanical, not "verify by hand once").

## Which is which

| File | Role | `deck_md.parse()` | Expected `render.py` outcome |
|---|---|---|---|
| `technical.md` | **good** | succeeds, 14 blocks | `rendered` (pending only the optional `pptx` toolchain) |
| `overview.md` | **broken** | raises `DeckMdError` at line 17 | `failed` |

Named `technical.md`/`overview.md` deliberately — the same two names `render.py`'s `RENDERABLE_DECKS`
resolves and the same two filenames real decks use under `council/defense-deck/`. T029 can copy
this directory's two files verbatim into a throwaway `<feature>/council/defense-deck/` and invoke
`render.py both --feature <feature>` with no renaming step.

## Source

Authored fresh for this fixture (not seeded from a real committed deck, unlike the frozen golden
pair under `test/fixtures/deck/`) — this pair exists to prove the exit-2 *branch*, not to exercise
deck realism at scale. `technical.md` deliberately touches every censused block kind at least once
(H1, blockquote, `---` HR, H2, paragraph, bullet, numbered, H3, table, fenced code) so it stands as
a legitimate, complete, small deck in its own right, not a stub.

## The exact construct that breaks `overview.md`

Line 17 of `overview.md`:

```
See [technical.md](technical.md) for the sibling deck that renders successfully.
```

This is a **markdown inline link** (`[text](url)`) — out of census per `deck_md.py`'s module
docstring ("Links / images / raw HTML | none" — data-model.md S2) and its own
`_LINK_INLINE`/`_check_inline` check. `deck_md.parse()` scans every text-bearing line's inline
content (`_check_inline`, called on every catch-all paragraph line) and raises `DeckMdError`
immediately upon reaching this line — parsing never continues past it, so the bullet on the line
below (`- this bullet is never reached: ...`) is intentionally unreachable and exists only to
document that fact in place.

The construct was chosen over the other out-of-census candidates (image, raw HTML, H4, nested
list, footnote, task-list, definition list, setext heading, frontmatter — all listed in
`deck_md.py`'s docstring) because a markdown link referencing a sibling file is the most realistic
authoring mistake for this exact fixture: someone drafting a real defense deck reaching for a
familiar markdown idiom ("see the other file") that the censused corpus simply never uses. It is
also the construct `deck_md.py`'s own error message calls out most directly: "no deck in the
corpus carries one."

## Verified behavior

Good deck parses cleanly and clears `render.py`'s deterministic T1-T10 mapping stage
(`_to_logical_slides` / `_split_for_overflow`) without raising — i.e. it would render, blocked only
by whether the optional `python-pptx` toolchain happens to be installed on the host running the
suite, exactly the condition `require_pptx()` in `test/run.sh` exists to gate:

```
$ cd extensions/deck-render/extension/scripts && python3 -c "
import deck_md, render
good = open('../../test/fixtures/deck-broken/technical.md', encoding='utf-8').read()
blocks = deck_md.parse(good)
print('GOOD parse OK --', len(blocks), 'blocks')
print('kinds:', [b.kind for b in blocks])
logical = render._to_logical_slides(blocks)
physical = render._split_for_overflow(logical)
print('GOOD maps to', len(physical), 'physical slide(s) beyond the title slide')
"
GOOD parse OK -- 14 blocks
kinds: ['h1', 'blockquote', 'hr', 'h2', 'paragraph', 'bullet', 'bullet', 'bullet', 'h3', 'paragraph', 'numbered', 'numbered', 'table', 'code']
GOOD maps to 2 physical slide(s) beyond the title slide
```

Broken deck raises `deck_md`'s typed error, naming the offending line, exactly as `render.py`'s
`_render_deck()` expects to catch it (`except deck_md.DeckMdError as exc: return Result(deck,
OUTCOME_FAILED, None, f"markdown outside supported constructs -- {exc}")`):

```
$ cd extensions/deck-render/extension/scripts && python3 -c "
import deck_md
broken = open('../../test/fixtures/deck-broken/overview.md', encoding='utf-8').read()
deck_md.parse(broken)
"
Traceback (most recent call last):
  ...
deck_md.DeckMdError: line 17: link syntax is out of census (no deck in the corpus carries one): 'See [technical.md](technical.md) for the sibling deck that renders successfully.'
```

## What T029 still needs to observe end-to-end

This dev host has no `python-pptx` installed (research.md R2's confirmed default state) — running
`render.py both --feature <dir wired from this pair>` here reports **both** decks `failed` with
reason `"toolchain absent (python-pptx not installed)"` (exit 4), because the toolchain's lazy
`import pptx` is checked before `deck_md.parse()` ever runs for either deck. That is expected and
is not this fixture's fault: it does not by itself demonstrate the `rendered`/`failed` split. T029
must guard its render-dependent assertions with `require_pptx()` (per `run.sh`'s CONTRACT block) so
the exit-2/render-good/fail-broken assertions are exercised for real when the toolchain is present,
and fail loud (not silently skip) when it is not. What this fixture guarantees independently of the
toolchain: `technical.md` never reaches the `DeckMdError` branch and `overview.md` always does,
which is the entire behavioral difference between the two outcomes once `pptx` is available.
