# speckit-ext-deck-render — Optional pptx Render of the Defense Deck

**The markdown is the artifact of record. The pptx is a derived render — never reviewed, never
gate-bound, never traced, never an input to any phase.**

`speckit-ext-deck-render` turns a council defense deck's **markdown**
(`council/defense-deck/technical.md` / `overview.md`, written by the `council` extension) into a
**presentation file**, on demand, only when a human asks for it. It lands D15's deferral clause
("presentational rendering") early, in the CLI, **without reopening D15**: nothing the council
reads, nothing a gate binds, and nothing a trace records changes. It is the CLI-era precursor to
the M5 platform gate view (D21) and is designed to be superseded, cheaply, when that ships
(FR-013) — small, additive, default-off, disposable.

Built by feature `006-deck-render`. See `specs/006-deck-render/` for the spec, plan, contracts,
and quickstart.

---

## The zero-hook seam (FR-008 / FR-012)

`extension/extension.yml` declares **ZERO hooks**. There is no `after_council`,
`before_render`, or any other fire-point — this extension is not wired into the council phase's
execution at all.

That is a deliberate consequence of two facts the spec's clarification session settled:

- The registered hook set **cannot serve the gate**: `after_plan` fires before the deck exists,
  and `after_council_approve` fires after the human has already signed. There is no seam a hook
  could attach to that would fire at the right moment.
- Adding one would mean a source edit into the `council` extension's installer-overwritten tree —
  exactly what FR-012 (D57, `artifact-layout.md` §9) forbids: cross-extension coupling attaches
  at a hook point, never a source edit into another extension's tree.

So the render is triggered by a **standalone, on-demand command** instead (`/speckit-deck-render`,
FR-008) — the human runs it before or at the council gate, and it always renders whatever markdown
exists at that instant, so staleness is structurally rather than procedurally avoided.

The practical payoff (SC-010): because this extension never touches a single file under
`extensions/council/` or `extensions/graphify/`, it is disjoint **by construction** from those
trees — including `005-graphify-context`'s concurrent rewrite of both. A reinstall of
`deck-render` itself, or of a foreign extension like `council` or `graphify`, cannot break this
seam, because there is no seam inside either tree to break.

## The optional, lazily-imported `python-pptx` dependency (FR-015)

`python-pptx` is the only third-party package this extension ever touches, and it is **never** a
hard dependency:

- `install.sh` installs the payload and skill only. It never requires, checks for, or fails
  without `python-pptx` — a host with the toolchain and a host without it install identically.
- `extension/scripts/render.py` imports `pptx` **lazily, inside the render function itself** —
  not at module load, not anywhere `install.sh` or the skill wrapper touches.
- If the import raises `ImportError` at invocation time, the command **degrades and discloses**
  rather than failing install or crashing: it reports, per deck, `failed (toolchain absent)`,
  names the install command (`pip install python-pptx`), and states plainly that the markdown is
  unaffected and remains the artifact of record (FR-009/FR-010). This is the likeliest failure
  mode in the field (SC-004), and it is a normal, expected, non-fatal outcome — never an
  installer error.

## Model-free, trace-free, free (FR-011)

The renderer is a **deterministic, mechanical transform**. It never invokes a model:

- No AI role, no subagent, no token spend.
- **No `traces.jsonl` record** — the same class as `/speckit-git-cleanup`'s FR-007: traces record
  *sessions*, and a mechanical, model-free transform is not a session, so there is nothing to
  trace.
- `council_spend` before and after a rendered run is identical (SC-006).

This is deliberate for a governance reason, not a performance one: a model in this path would
become a second author of the deck's content, and could make the pptx say what the reviewed
markdown does not (FR-002).

## Provides

One command skill:

| Command | What it does | Writes |
|---|---|---|
| `/speckit-deck-render [technical\|overview\|both] [--feature <dir>] [--validate-profile]` | Renders the selected defense deck(s) to `.pptx` — the profile's `deck_render` selection by default, or an explicit deck argument that overrides it regardless of profile (FR-016) | `specs/NNN-feature/renders/{technical,overview}.pptx` — **gitignored**, never committed (FR-014) |

Full argument grammar, exit codes (`0`/`2`/`3`/`4`), and the per-deck disclosure format are
normatively defined in `specs/006-deck-render/contracts/commands.md`.

Everything this command does is safe to no-op: `deck_render` absent or `none` and no explicit
invocation produces **zero** rendered files, zero new trace records, and a `council/` subtree
byte-identical to the pre-006 pipeline (SC-001). A render failure never blocks or fails the
council gate, the council phase, or any markdown artifact (FR-009) — it is disclosed to the
human, per deck, and the pipeline proceeds (FR-010).

## Layout

```text
extensions/deck-render/
├── README.md                       # this file
├── install.sh · uninstall.sh       # payload + skill install/removal; NEVER requires python-pptx
├── extension/                      # → .specify/extensions/deck-render/
│   ├── extension.yml                # manifest — declares ZERO hooks (FR-008/FR-012)
│   ├── commands/
│   │   └── speckit.deck-render.md   # command provenance source
│   └── scripts/
│       ├── render.py                # the deterministic transform (stdlib + lazy pptx import)
│       ├── deck_md.py               # markdown → block model (stdlib, no deps)
│       └── profile_key.py           # scoped `deck_render` reader/validator (stdlib) — the
│                                    #   sole canonical source of the closed enum {none,
│                                    #   technical, overview, both}
├── skills/
│   └── speckit-deck-render/
│       └── SKILL.md                 # → .claude/skills/ — thin wrapper, no model in the path
└── test/
    ├── run.sh                       # POSIX sh; PASS/FAIL counters; throwaway temp dirs
    ├── extract_pptx_text.py         # independent stdlib OOXML text extractor (SC-003) —
    │                                #   never a python-pptx round-trip
    └── fixtures/
        ├── deck/                    # frozen golden defense deck
        ├── deck-broken/             # intentionally-malformed deck (partial-failure branch)
        └── profiles/                # {none,overview,both,invalid,unreadable,absent-key}.yaml
```

`extension/`, `skills/speckit-deck-render/`, and `test/fixtures/` exist now as scaffolded,
git-tracked directories; the files listed above land as later tasks in this feature fill them in.

## Install

```bash
bash extensions/deck-render/install.sh .
```

Copies `extension/` → `.specify/extensions/deck-render/`, installs `speckit-deck-render` to
`.claude/skills/`, and merges deck-render's hook rows — **there are none** — into
`.specify/extensions.yml`, using the same locked, atomic (`flock` + tempfile + `os.replace()`)
registry merge `extensions/testing/install.sh` uses, not `extensions/git/install.sh`'s unlocked
write. No presentation toolchain is required or checked at install time (FR-015).

There is no install-order dependency on `council`, `graphify`, `git`, `workforce`, or any other
extension: `deck-render` reads council's markdown output at render time, never at install time,
and writes nothing any other extension's installer touches.

## Uninstall

```bash
bash extensions/deck-render/uninstall.sh .
```

Deregisters deck-render's entry from `.specify/extensions.yml` **first**, then removes the
installed payload and the `speckit-deck-render` skill — nothing else. With the extension absent
or disabled, the council/gate pipeline is byte-identical to its pre-006 behavior (FR-013): no
render command, no `renders/` output, no observable difference. Uninstall never touches
`council/` or `graphify/`'s installed trees, and never deletes a `renders/` directory a prior run
may have left on disk — that directory is gitignored build output, not registry state, and
removal of the extension does not retroactively delete files a human already generated.

## Test

```bash
sh extensions/deck-render/test/run.sh
```

POSIX `sh`, PASS/FAIL counters, throwaway temp dirs — following `extensions/git/test/run.sh` and
`extensions/testing/test/run.sh`. Covers, among other checks: install/uninstall round-trip
byte-identity against `.specify/extensions.yml` (including a combined manifest shared with
`005`'s entries, SC-010); bidirectional fidelity on the frozen fixture deck via the independent
OOXML extractor, never a `python-pptx` round-trip (SC-003); the toolchain-absent degrade path
forced via a `PYTHONPATH` shadow, never a test-only backdoor in production code (SC-004); the
`deck_render: both` partial-failure branch on an asymmetric good/broken fixture pair (exit 2);
atomic-write survival on a forced mid-write failure; staleness detection via sha256 stamp
mismatch (SC-007); the default-off path producing zero files and zero trace records (SC-001); and
the git/gates/traces boundary grep (SC-005). See `specs/006-deck-render/quickstart.md` for the
full runnable walkthrough and `specs/006-deck-render/contracts/commands.md` for the normative
command contract.

License: MIT.
