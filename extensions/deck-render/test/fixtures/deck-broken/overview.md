# Deck-Broken Fixture — Broken Half

> Fixture. Committed for T027 (asymmetric partial-failure pair, S02, `specs/006-deck-render`).
> This deck is deliberately unrenderable. Its sibling `technical.md`, in this same directory,
> parses and renders cleanly. See `PROVENANCE.md` for the exact construct that breaks this file
> and why it was chosen.

---

## Purpose

This is the **broken** half of the asymmetric fixture pair under `test/fixtures/deck-broken/`.
Paired with `technical.md` under a `deck_render: both` invocation, it exercises the partial-failure
exit-2 branch (I-B2/S03): `technical.md` renders, this file fails, both outcomes are disclosed in
the same run, and `render.py` exits 2.

See [technical.md](technical.md) for the sibling deck that renders successfully.

- this bullet is never reached: `deck_md.parse()` raises `DeckMdError` on the paragraph line
  immediately above, the moment it scans that line's inline content
