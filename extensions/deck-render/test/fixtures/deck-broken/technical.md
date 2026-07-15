# Deck-Broken Fixture — Good Half

> Fixture. Committed for T027 (asymmetric partial-failure pair, S02, `specs/006-deck-render`).
> This deck parses cleanly and renders successfully. Its sibling `overview.md`, in this same
> directory, is deliberately unrenderable — see `PROVENANCE.md` for the exact construct that
> breaks it and why.

---

## Purpose

This is the **good** half of the asymmetric fixture pair under `test/fixtures/deck-broken/`.
Paired with `overview.md` under a `deck_render: both` invocation, it exercises the partial-failure
exit-2 branch (I-B2/S03): `technical.md` renders, `overview.md` fails, both outcomes are disclosed
in the same run, and `render.py` exits 2.

- every censused block kind (`deck_md.py`'s S2 census) appears here at least once
- content is deliberately small — this fixture proves the *branch*, not deck realism
- `deck_md.parse()` on this file returns cleanly, with zero `DeckMdError`s (verified below)

### A Bold Lead Line

Plain text carrying `inline code`, **bold**, and *italic* markers — all inside the censused inline
set (T9), none of them out-of-census constructs.

1. first numbered item, present for census coverage
2. second numbered item

| Deck | Expected outcome under `both` |
|---|---|
| `technical.md` (this file) | rendered |
| `overview.md` (sibling) | failed |

```text
this fenced code block's content is preserved byte-exact -- no reflow, no interpretation
```
