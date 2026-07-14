# Quickstart — 006-deck-render

The runnable validation walkthrough. Every **Success Criterion** and every **Functional Requirement** in [spec.md](./spec.md) binds to a concrete check below — none is left to inspection.

Details live elsewhere and are referenced, not duplicated: the command's behavior in [contracts/commands.md](./contracts/commands.md), the transform rules in [data-model.md](./data-model.md) §4, the design reasoning in [research.md](./research.md).

---

## Prerequisites

```sh
cd <repo-root>
bash extensions/deck-render/install.sh .        # installs payload + skill; requires NO toolchain
```

The optional presentation toolchain is **deliberately not installed yet** — the first scenario below is the toolchain-absent degrade path (FR-015/SC-004), which is the likeliest state in the field. Install it only when you reach Scenario 3:

```sh
pip install python-pptx        # optional, lazily checked, never required by install.sh
```

Run the full suite at any point:

```sh
sh extensions/deck-render/test/run.sh           # expect: N passed, 0 failed
```

---

## Scenario 1 — The default path is untouched (SC-001, FR-007, FR-013)

**The most important scenario in this file.** A feature that says nothing gets nothing.

```sh
# A profile with no deck_render key, and one with deck_render: none
/speckit-deck-render --feature specs/001-council-extension     # no key at all
/speckit-deck-render --feature specs/005-graphify-context      # add deck_render: none first
```

**Expect:** exit 0. One line saying nothing was selected. **Zero** files created. Then assert the pipeline is byte-identical to pre-006:

```sh
git status --porcelain          # clean — nothing rendered, nothing staged
find specs -name '*.pptx'       # empty
```

✅ **SC-001** (zero rendered files, zero new trace records, `council/` byte-identical) · **FR-007** · **FR-013** (removal ⇒ `uninstall.sh`; verify with the round-trip in Scenario 8)

---

## Scenario 2 — A render failure never blocks the gate, and is disclosed per deck (SC-004, FR-009, FR-010, FR-015)

Run this **before** installing `python-pptx` — the toolchain-absent case, unforced.

```sh
/speckit-deck-render both --feature specs/005-graphify-context
```

**Expect:** a per-deck disclosure naming the deck and the reason, and stating the markdown is unaffected:

```
  overview   FAILED     presentation toolchain not available (python-pptx not installed)
  technical  FAILED     presentation toolchain not available (python-pptx not installed)

The markdown decks are unaffected and remain the artifact of record.
```

Then assert the invariants that make the failure *safe*:

```sh
git diff --stat specs/005-graphify-context/council/    # EMPTY — no markdown touched
find specs -name '*.pptx'                              # EMPTY — no partial file left behind
```

The council gate remains reachable and approvable. Nothing halted.

✅ **SC-004** (phase completes, gate reachable, every `council/` `.md` byte-identical, per-deck notice reaches the human) · **FR-009** (degrade, never halt) · **FR-010** (disclosed, per deck — silence is not acceptable) · **FR-015** (toolchain optional, lazily checked)

> **A partial failure must not read as success.** Under `deck_render: both` with one deck rendering and one failing, the disclosure reports exactly that and the command exits `2`. Covered by the suite; verify by hand once by making one deck unreadable.

---

## Scenario 3 — Render an overview deck, stamped (SC-002, FR-003, FR-004)

```sh
pip install python-pptx
/speckit-deck-render overview --feature specs/005-graphify-context
```

**Expect:** `specs/005-graphify-context/renders/overview.pptx` exists.

**Now the one genuinely manual check in this file — open it.** SC-002 says "opens in a standard presentation viewer," and no test can assert that on the reader's behalf:

```sh
open specs/005-graphify-context/renders/overview.pptx    # PowerPoint / Keynote / LibreOffice
```

**Confirm, by eye:**
- It opens without a repair prompt.
- The title slide carries the **derived-render stamp**: the declaration that this is *not* the artifact of record, the source path, and a **64-hex sha256**.
- Every slide's footer carries the abbreviated stamp — a slide screenshotted out of context still says what it is.
- A non-technical reader could reach an approve/reject decision from it alone (the 001-SC-007 property, preserved through the render), **and** could see from the file itself that the markdown is what the council reviewed.

✅ **SC-002** · **FR-003** (stamp: source path + source SHA, on the file's face) · **FR-004** (per-deck-type selection) · **US1** acceptance 1 & 2

---

## Scenario 4 — Fidelity, both directions, mechanically (SC-003, FR-002)

The load-bearing check. Runs against the **frozen fixture deck**, not a live one.

```sh
sh extensions/deck-render/test/run.sh            # the fidelity section
```

**What it asserts** (see [data-model.md](./data-model.md) §4):
- **(a) Nothing dropped** — 100% of the fixture's headings and text blocks appear in the render's extractable text.
- **(b) Nothing invented** — no text appears beyond the source plus the committed allowlist (stamp + `(cont.)` + slide numbers).

**Why it is trustworthy:** the render's text is extracted from the **raw OOXML** by an independent stdlib reader (`zipfile` + `xml.etree` over every `<a:t>` run), **not** by reading the file back through `python-pptx` — which would only prove the library round-trips its own object model, not that the *file* says what the markdown says.

**Falsify it deliberately, once**, so you know the check has teeth:

```sh
# add a line to the fixture deck, DON'T re-render, re-run → direction (a) must FAIL
# hand-add a word to the renderer's output text, re-run  → direction (b) must FAIL
```

Direction (b) is the dangerous half: it is what stops the pptx from ever saying something the council never reviewed.

✅ **SC-003** (bidirectional containment, mechanical, neither direction eyeballed) · **FR-002** (the renderer transforms; it never authors)

---

## Scenario 5 — The boundary holds mechanically (SC-005, SC-006, FR-001, FR-011, FR-014)

Grep-able, not asserted. Run after any rendered run:

```sh
git ls-files | grep -i '\.pptx$'                        # EMPTY — never tracked (FR-014)
grep -ri 'pptx\|renders/' specs/*/gates.yml             # EMPTY — no render is gate-bound
grep -ri 'pptx\|renders/' specs/*/traces.jsonl          # EMPTY — no render is traced
git check-ignore -v specs/005-graphify-context/renders/ # confirms the gitignore rule fires
```

And the cost claim — a rendered run's `council_spend` is **identical** to an unrendered one's, because the renderer makes zero model calls:

```sh
grep -c '"role"' specs/005-graphify-context/traces.jsonl   # unchanged by any render
```

✅ **SC-005** (no render in `gates.yml`, `traces.jsonl`, any council session's context-in, or `git ls-files`) · **SC-006** (free — zero model calls, zero tokens) · **FR-001** (markdown remains the artifact of record) · **FR-011** (mechanical ⇒ no trace record) · **FR-014** (gitignored derived build product)

---

## Scenario 6 — Staleness is visible from the render's own face (SC-007, FR-008)

```sh
/speckit-deck-render overview --feature specs/005-graphify-context   # render
# now edit council/defense-deck/overview.md — add a sentence, DON'T commit
```

Recompute the source's sha256 and compare it to the SHA printed on the render's title slide.

**Expect:** they differ ⇒ the render on disk is **stale**, and you can tell *from the file itself*, with no bookkeeping anywhere.

This is the check that would have **silently failed** had the stamp used git-ext's `sha.sh`: a commit SHA does not move when the working tree changes, and it fails closed on an uncommitted deck — which the deck usually is at gate time (there is no `after_council` commit hook). See [research.md](./research.md) R3.

Re-run the render ⇒ the stamp matches again. Because the trigger is on-demand (FR-008), there is no re-derivation bookkeeping to get wrong: the render always corresponds to the markdown the human is about to read.

✅ **SC-007** · **FR-008** (on-demand; renders the markdown as it exists at invocation)

---

## Scenario 7 — The enum is closed, and explicit invocation overrides the profile (SC-008, FR-005, FR-006, FR-016)

```sh
# 1. An out-of-enum value is a hard failure — it never degrades to `none`
#    (set deck_render: sparkle in a scratch profile)
/speckit-deck-render --feature <scratch> ; echo "exit=$?"     # → exit=3, nothing written
/speckit-deck-render --validate-profile --feature <scratch>   # → exit=3

# 2. Absent ⇒ none (never renders something you didn't ask for)
/speckit-deck-render --validate-profile --feature specs/001-council-extension  # → exit=0

# 3. `deck_render: both` renders both decks
/speckit-deck-render --feature <profile with both>            # → two .pptx files

# 4. FR-016 — an EXPLICIT deck renders regardless of the profile, including `none`
/speckit-deck-render overview --feature <profile with none>   # → renders anyway
```

**Read the scope limit before trusting (4).** `--validate-profile` checks the **`deck_render` key only**. This repo has **no general `profile.yaml` validator** — the closed enums, the `full_auto` handshake, and "unknown keys are a validation error" are enforced by prose alone, and `council_tier` typos degrade silently today. See [plan.md](./plan.md) Complexity Tracking and [research.md](./research.md) R4. Do not read this scenario as "profiles are validated." They are not.

✅ **SC-008** (out-of-enum fails validation) · **FR-005** (closed enum in `profile.yaml`) · **FR-006** (absent ⇒ `none`; out-of-enum never falls back) · **FR-016** (default selection, not a hard gate) · **US2** acceptance 1–3

---

## Scenario 8 — The seam survives reinstall, and removal is clean (SC-010, FR-012)

```sh
sh extensions/deck-render/test/run.sh      # the reinstall-survival section
```

**What it asserts** (the `extensions/git/test/run.sh` §3 model):
- Install deck-render → **reinstall `council`** and **reinstall `graphify`** → the payload, the skill, and the `installed:` entry all survive, and the command still fires.
- **No file under `extensions/council/` or `extensions/graphify/` was modified by this feature** — grep-able. The extension declares **zero hooks** and never reaches into another extension's tree, so FR-012 holds by construction.
- `uninstall.sh` returns `.specify/extensions.yml` **byte-identical** to its pre-install baseline (the `testing` round-trip test) — which is what FR-013 (cheap removability) actually means.

✅ **SC-010** (clean seam; survives own + foreign reinstall) · **FR-012** (hook/seam; no source edits into council or graphify) · **FR-013** (cheaply removable)

---

## Scenario 9 — The dogfood exit (SC-009)

The feature renders **its own** defense deck.

```sh
/speckit-deck-render overview --feature specs/006-deck-render
open specs/006-deck-render/renders/overview.pptx
```

**Expect:** a valid, stamped, content-faithful render of `006`'s own committed `council/defense-deck/overview.md`.

**Note which path this uses.** `006`'s own profile is necessarily `deck_render: none` — the renderer does not exist when `006`'s own council convenes. So this exit test runs through **FR-016's explicit-invocation path**, not through the profile. That is a bootstrap fact, not a conformance gap, and it is why the profile keeps telling the truth about what `006`'s council actually ran with. `007-oss-docs` is the first feature that can set the flag at council time and have it fire by default.

✅ **SC-009**

---

## Coverage

| | Bound by |
|---|---|
| **SC-001** | Scenario 1 |
| **SC-002** | Scenario 3 *(includes the one irreducibly manual check — it opens in a viewer)* |
| **SC-003** | Scenario 4 |
| **SC-004** | Scenario 2 |
| **SC-005** | Scenario 5 |
| **SC-006** | Scenario 5 |
| **SC-007** | Scenario 6 |
| **SC-008** | Scenario 7 |
| **SC-009** | Scenario 9 |
| **SC-010** | Scenario 8 |
| **FR-001** | Scenario 5 |
| **FR-002** | Scenario 4 |
| **FR-003** | Scenario 3, 6 |
| **FR-004** | Scenario 3 |
| **FR-005** | Scenario 7 |
| **FR-006** | Scenario 7 |
| **FR-007** | Scenario 1 |
| **FR-008** | Scenario 6 |
| **FR-009** | Scenario 2 |
| **FR-010** | Scenario 2 |
| **FR-011** | Scenario 5 |
| **FR-012** | Scenario 8 |
| **FR-013** | Scenario 1, 8 |
| **FR-014** | Scenario 5 |
| **FR-015** | Scenario 2 |
| **FR-016** | Scenario 7, 9 |

All 10 SCs and all 16 FRs bind to an executable check. The single irreducibly manual step is SC-002's "opens in a standard presentation viewer" (Scenario 3) — named as manual rather than quietly asserted.
