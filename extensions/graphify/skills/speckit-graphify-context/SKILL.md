---
name: "speckit-graphify-context"
description: "Generate three token-bounded graphify grounding products from one graph pass for the current feature: graphify-context.md (relevant existing modules, per-file blast radius, shared/mutable files, patterns to follow — unchanged path and shape, read by the graph-aware speckit variants), graphify-receipts.md (the concept/rationale/contracts diet for the council member and deck-prep), and graphify-type-signal.md (the per-file type-signal diet for the categorizer) — all three share one provenance header and generation-id from a single generator run. Runs as a before_plan / before_tasks / before_implement hook and inline from the graph-aware speckit variants."
argument-hint: "Optional: a feature dir override, or the word 'merged' to force the cross-repo stack graph"
compatibility: "Requires spec-kit .specify/ structure, a graphify-out/graph.json built for the repo (run /graphify first), and extensions/graphify/extension/scripts/provenance.sh for the shared provenance header (present)."
metadata:
  author: narenkarthikbm
  source: "graphify:commands/speckit.graphify.context.md"
user-invocable: true
disable-model-invocation: false
---

## User Input

```text
$ARGUMENTS
```

Consider the user input (e.g. an explicit feature dir, or the word `merged` to force the cross-repo stack graph).

## Goal

Produce `<FEATURE_DIR>/graphify-context.md` — a compact, token-bounded grounding file that the graph-aware Spec Kit commands (`/speckit-plan`, `/speckit-tasks-graph`, `/speckit-implement-parallel`) read so they don't re-explore the repo from scratch. It captures what already exists around this feature, the dependency blast radius of the files it will touch, and the shared/mutable files that constrain parallel execution.

The same generator run also emits two sibling, token-bounded diet products from the identical graph pass, so one invocation grounds every downstream consumer instead of three separate explorations: `<FEATURE_DIR>/graphify-receipts.md` (the concept/rationale/contracts slice the council member and deck-prep read) and `<FEATURE_DIR>/graphify-type-signal.md` (the per-file type-signal slice the categorizer reads). All three products carry one shared-provenance header and generation-id (see "Shared-provenance header" below); `graphify-context.md` itself keeps its current path and section grammar unchanged (FR-013).

## Steps

1. **Resolve feature paths.** Run `.specify/scripts/bash/check-prerequisites.sh --paths-only` from the repo root and parse `REPO_ROOT`, `BRANCH`, `FEATURE_DIR`, `FEATURE_SPEC`, `IMPL_PLAN`. If `$ARGUMENTS` names a feature dir, prefer it. All paths absolute.

2. **Locate the graph.** Read `.specify/extensions/graphify/graphify-config.yml` for `graph.repo`, `graph.merged`, and `query.budget`.
   - Default graph root = `REPO_ROOT` (queries `REPO_ROOT/graphify-out/graph.json`, this repo only).
   - Use the **merged** graph root = `dirname(REPO_ROOT)` (the stack root, queries `../graphify-out/graph.json`) when ANY of: `$ARGUMENTS` contains `merged`; the spec/plan references the sibling repo by name; or the feature spans both frontend and backend.
   - If the chosen `graph.json` does not exist, STOP and tell the user to run `/graphify` in that root first. Do **not** fabricate context.

3. **Extract anchors and map them to graph labels.** Read `FEATURE_SPEC` (spec.md) and, if present, `IMPL_PLAN` (plan.md), `data-model.md`, and `contracts/`. Pull the concrete nouns this feature is about: entities, services, endpoints, routes, components, modules, and existing file names. Then map each to a **concrete graph node label** — a file basename (`tournaments.server.ts`) or a symbol (`TournamentHubLayout()`), not a generic phrase. These exact labels are what `explain` resolves cleanly.

4. **Query the graph.** Run `graphify` from the chosen graph root so it reads the right `graph.json` (use a subshell, e.g. `(cd "<GRAPH_ROOT>" && graphify explain "…" --budget <budget>)`). Cap every call with `--budget <budget>`.
   - **Lead with `explain` on the concrete labels from Step 3.** `graphify explain "<file-or-symbol label>"` returns exact directional edges (`-->` depends-on, `<--` depended-on-by, `contains`) and is the authoritative source for each anchor's role and blast radius. This is your primary call.
   - Use broad NL `query` for **discovery only** (surfacing anchors you didn't know to name): `graphify query "<one-sentence feature summary>: which existing modules and files does this touch?"`. Treat its hits as *candidate labels* to re-run through `explain` — keyword matching anchors noisily on token overlap (a constant, a plan doc, the wrong `Layout()`), so never quote a raw NL-query result as a dependency fact.
   - Per pair of anchors that may interact: `graphify path "<A>" "<B>"`.
   - Keep total queries proportional to feature size (typically 3–8). Never cat or dump `graph.json`.

5. **Identify shared / mutable files.** From the results, flag files that many things depend on and that multiple tasks would edit — route manifests (e.g. `app/routes.ts`), barrels / `index` re-exports, DI / registry / settings modules, URL confs, migration directories. These are the collision points that force serialization during parallel implementation.

6. **Obtain the shared-provenance header once, then write `<FEATURE_DIR>/graphify-context.md`.** Call `<REPO_ROOT>/extensions/graphify/extension/scripts/provenance.sh header <absolute path to the chosen <GRAPH_ROOT>/graphify-out/graph.json> <repo|merged, from Step 2>` **exactly once per run** — `<REPO_ROOT>` is always this repo (from Step 1); only the `graph.json` and scope arguments change for a merged run. Omit the optional 4th argument so it stamps the real generation instant (a fixture harness passes a fixed literal instead — see "Golden-fixture guidance" below). Capture its full 9-line `<!-- graphify-provenance:v1 ... -->` block verbatim: this single captured block is what Steps 7 and 8 also stamp into their own products, byte-for-byte — never recompute it or re-invoke `provenance.sh` per product (that risks a different `generated-at` per call and is wasted work when the entire point is one shared identity). If the call fails — e.g. the graph has no `built_at_commit`, a hard error by `provenance.sh`'s own design — STOP and surface the error verbatim; never fabricate a header or write a product without one. Then write `graphify-context.md` per the template below: keep it lean (target < ~1500 tokens, unchanged), insert the captured header near the top (after the intro italic line, before the first `##` — the header's own "Placement" rule, below), cite real `source_file` paths from the graph, and mark anything absent as `(not in graph — new code)`.

7. **Write `<FEATURE_DIR>/graphify-receipts.md`** — the concept/rationale diet for the council member and deck-prep. Stamp it with the identical header captured in Step 6. Populate `## Concept / rationale receipts` from concept-/rationale-typed nodes (and any `participate_in` hyperedge clustering them) already surfaced by Step 4's queries, or reachable from an already-resolved anchor via a `rationale_for` / `participate_in` / `references` edge — never a fresh full-graph scan for every concept/rationale node in the repo, which would blow past Step 4's own query budget. Populate `## Contracts cited` directly from the `contracts/` directory already read in Step 3 — no additional graph query needed — one line per contract file with a one-line gloss of what it specifies, or the literal line `(none found in this slice)` when the feature has no `contracts/` directory or it is empty. Keep it lean (target < ~800 tokens — about half of `graphify-context.md`'s budget, since this slice carries no blast-radius/shared-file analysis). Template below.

8. **Write `<FEATURE_DIR>/graphify-type-signal.md`** — the per-file type-signal diet for the categorizer. Stamp it with the identical header captured in Step 6. One line per file already named as an anchor or blast-radius file in Steps 3–5 (the same file universe `graphify-context.md` draws from — issue no new queries to build this diet): if the file is a graph node, cite its own `file_type` attribute directly under `## Per-file type signal (graph-grounded)`; if the file was named by this feature's spec/plan/tasks but never resolved to a graph node, apply the path-convention fallback table below under `## Path-convention fallback (not in graph)`, labeled plainly `convention-derived / engineer assertion, not graph fact` (FR-004's honesty phrasing) — never presented as graph-grounded. Keep it lean (target < ~500 tokens — one short line per file, the leanest of the three). Template below.

## Output template — `graphify-context.md`

Unchanged from before this task (FR-013) except for one insertion: the shared-provenance header, placed as shown.

```markdown
# Graphify Context — <feature>

_Generated <ISO-8601> from `<graph path>` (<N> nodes, <M> edges, scope: repo|merged). Stale after large merges — regenerate with `/speckit-graphify-context`._

<shared-provenance header — captured once in Step 6, inserted verbatim; exact 9-line syntax in "Shared-provenance header" below>

## Graph scope
- Repo graph: `<REPO_ROOT>/graphify-out/graph.json`
- Merged stack graph: `<stack>/graphify-out/graph.json` (use for cross-repo features)
- This run used: **<repo|merged>**

## Relevant existing modules
- `<source_file>` — <role, from explain/query>
- ...

## Blast radius (per anchor)
- **<anchor>** (`<source_file>`)
  - depends on: `<file>`, `<file>`
  - depended on by: `<file>`, `<file>`
  - follow the pattern in: `<file>`

## Shared / mutable files (collision watch)
> Tasks that touch any of these must be serialized — never put two of them in the same parallel wave.
- `<file>` — <why it is shared>
- (or: none found)

## Patterns to follow
- <convention surfaced by the graph, with the exemplar file>
```

## Output template — `graphify-receipts.md`

The concept/rationale/contracts diet (Step 7). Same captured header as above, same placement rule; body is this feature's concept/rationale/contract slice only — no blast-radius or shared-file sections.

```markdown
# Graphify Receipts — <feature>

_Generated <ISO-8601> from `<graph path>` (<N> nodes, <M> edges, scope: repo|merged) — concept/rationale diet for the council member and deck-prep. Stale after large merges — regenerate with `/speckit-graphify-context`._

<shared-provenance header — the identical block captured in Step 6, inserted verbatim>

## Concept / rationale receipts
- **<concept-or-rationale node label>** (`<source_file>`) — <the node's own `rationale` text>. (`<relation>` → <target node label>, when a grounding edge links it to another cited node)
- **<hyperedge label>** (hyperedge, <confidence>, confidence <score>) — <which nodes it clusters and why, when a relevant hyperedge exists>
- ...

## Contracts cited
- `<contracts/... path>` — <one-line gloss of what it specifies>
- ...
- (or, if none: `(none found in this slice)`)
```

## Output template — `graphify-type-signal.md`

The per-file type-signal diet (Step 8). Same captured header as above, same placement rule; body is one short line per file, nothing else.

```markdown
# Graphify Type Signals — <feature>

_Generated <ISO-8601> from `<graph path>` (<N> nodes, <M> edges, scope: repo|merged) — per-file type-signal diet for the categorizer. Stale after large merges — regenerate with `/speckit-graphify-context`._

<shared-provenance header — the identical block captured in Step 6, inserted verbatim>

## Per-file type signal (graph-grounded)
- `<source_file>` — file_type: <file_type>
- ...

## Path-convention fallback (not in graph)
- `<path named by this feature but absent from the graph>` — file_type: <fallback file_type> — convention-derived / engineer assertion, not graph fact (`<the convention applied>`; file absent from the graph)
- (or, if none needed: `(none needed — every named file resolved to a graph node)`)
```

**Path-convention fallback table** (Step 8) — applied only to a file Steps 3–5 named that never resolved to a graph node; never applied speculatively to a file nobody named. The six `file_type` values are the graph's own enum (`code|document|paper|image|rationale|concept`, per data-model.md "Knowledge graph") — the fallback never invents a seventh:

| Path / extension pattern | Fallback `file_type` |
|---|---|
| `*.md` under this feature's own `specs/**` (spec.md, plan.md, data-model.md, tasks.md, research.md, quickstart.md, checklists/**) | `concept` |
| `*.md` naming a decision/rationale log (e.g. `docs/90-DECISIONS-AND-IDEAS.md`, `council/decision-record.md`) | `rationale` |
| any other `*.md` (READMEs, `SKILL.md`, command/template docs) | `document` |
| source/config-as-code extension (`.py`, `.ts`, `.tsx`, `.js`, `.jsx`, `.go`, `.rs`, `.sh`, `.yml`/`.yaml`) | `code` |
| image extension (`.png`, `.jpg`, `.jpeg`, `.svg`, `.gif`) | `image` |
| `.pdf` | `paper` |
| anything else | `document` (least specific, safest default) |

## Shared-provenance header (arm-2 ↔ arm-3 coherence contract)

This is the single authoritative contract for the header every arm-3 context product emits and `freshness.sh` (arm 2) reads. It is fixed precisely enough that a POSIX `sh` script extracts any field with `grep`/`sed` alone — no YAML/JSON parser — and a committed golden fixture asserts on it byte-for-byte. **Nothing in this section changes today's output.** The generator that stamps this header into all three arm-3 products, and `freshness.sh` itself, are later work; this section is the contract that work must satisfy.

**Backward compatibility (FR-013).** The existing italic provenance line in the Output template above (`_Generated <ISO-8601> from ... regenerate with /speckit-graphify-context._`) is unchanged — this section *adds* a machine-readable block alongside it, it does not replace or reword it. `graphify-context.md`'s path and section grammar stay exactly as today; `/speckit-plan`, `/speckit-tasks-graph`, and `/speckit-implement-parallel` read it unchanged.

**Placement.** Exactly one header block per product file, near the top (after the product's own title/intro prose, before its first `##` section) — position is a readability nicety only; every consumer locates the block by its sentinel marker, never by line number.

### Literal syntax (normative)

The header is a single HTML comment — invisible when the Markdown renders, present in the raw bytes for `grep`/`sed` and for byte-diffing — carrying exactly seven `field-name: value` lines, one per line, in this fixed order, no blank lines inside the block, no trailing whitespace:

```
<!-- graphify-provenance:v1
graph-path: graphify-out/graph.json
graph-scope: repo
node-count: 1611
edge-count: 2674
generated-at: 2026-07-14T18:32:05Z
generation-id: sha256:1f3c9a7d0e6b5c2a4f8d9e1b3c5a7f9d2e4b6c8a0f2d4e6b8c0a2f4e6d8c0b2a
source-fingerprint: git-commit:9cc8479978f5f1986246e0fb6a9eb11ab8106dd5
-->
```

(The `generation-id` hex above is an illustrative placeholder; `node-count`/`edge-count`/`source-fingerprint` reuse real values verified against this feature's own committed `graph-baseline.json`, cited below.) Extraction is one `sed` to isolate the block plus one `grep`/`sed` per field, e.g.:

```sh
sed -n '/<!-- graphify-provenance:v1/,/-->/p' "$product" | grep '^generation-id:' | sed 's/^generation-id: //'
```

### Field reference (normative)

The first five fields are read directly off the `graph.json` named by `graph-path` — a NetworkX node-link-json document with top-level keys `directed`, `multigraph`, `graph`, `nodes`, `links`, `hyperedges`, `built_at_commit` (verified against `specs/005-graphify-context/graph-baseline.json`; no other top-level key exists at time of writing). A future upstream `graphifyy` schema change would need this section's extraction recipes amended to match — `graphifyy` itself stays unmodified (D75), this contract adapts to it, never the reverse.

| Field | Format | Identical across all 3 products of one run? |
|---|---|---|
| `graph-path` | the `graph.json` path, written relative to this feature's repo root (`REPO_ROOT`) — `graphify-out/graph.json` for repo scope, `../graphify-out/graph.json` for merged scope (never absolute — an absolute path breaks byte-identical goldens across machines/CI) | Yes |
| `graph-scope` | `repo` \| `merged` | Yes |
| `node-count` | decimal integer — `len(graph.json["nodes"])`, the **full graph's** total (not this product's own diet-slice count) | Yes |
| `edge-count` | decimal integer — `len(graph.json["links"])` (NetworkX calls edges "links"; this is the same figure the plan's own baseline cites as "edges") | Yes |
| `generated-at` | `YYYY-MM-DDTHH:MM:SSZ`, UTC, second precision, literal `Z` (no fractional seconds, no numeric offset) | Yes |
| `generation-id` | `sha256:` + 64 lowercase hex chars | Yes |
| `source-fingerprint` | `git-commit:` + 40 lowercase hex chars (the common case), or `sha256:` + 64 lowercase hex chars (fallback — see below) | Yes |

Every field is stamped once per generator run and copied verbatim into all three products (see *Coherence*, below).

### `generation-id` — the graph content-hash

`generation-id = sha256:<hex(SHA-256(canonical-bytes))>`, where `canonical-bytes` is produced by:

1. Parse `graph.json` as JSON.
2. **Remove the top-level `built_at_commit` key.** It is tracked separately, as `source-fingerprint` (below) — folding it in here would correlate the two checks (a refresh that re-stamps the commit marker with byte-identical node/edge content would needlessly flip both hashes at once, when the two are designed to answer different questions independently).
3. Re-serialize the remainder with object keys sorted lexicographically (`LC_ALL=C` byte order) at every nesting level; arrays (`nodes`, `links`, `hyperedges`) keep their existing, already-stable element order — canonicalization never reorders array content, only object keys; compact form (no insignificant whitespace); UTF-8; LF line endings.
4. SHA-256 the result.

```sh
python3 -c "
import json
d = json.load(open('graph.json'))
d.pop('built_at_commit', None)
print(json.dumps(d, sort_keys=True, separators=(',', ':')))
" | shasum -a 256 | cut -d' ' -f1
```

(`shasum -a 256` matches this codebase's own existing hash-reference-definition convention — `docs/contracts/agent-library-schema.md` S2's `body_sha256`, `extensions/workforce/extension/scripts/frontmatter.py` — rather than a second, differently-named hashing convention. A GNU/Linux implementation may use `sha256sum` instead; both emit the identical lowercase-hex digest for identical bytes.)

The generator (stamping `generation-id` at product-write time) and `freshness.sh` (recomputing it at check time) **MUST** perform identical canonicalization — share one implementation rather than reimplement it twice; any divergence between the two reproduces, mechanically, the exact false-staleness failure this contract exists to prevent. Step 2's "no other volatile field" claim is verified against the current upstream extraction, not assumed: if a future `graphifyy` release adds a second self-referential build-time field, apply the same rule (exclude it here; consider it for `source-fingerprint` instead if it is a more precise source-basis marker than `built_at_commit`).

### `source-fingerprint` — the source-basis marker (why a sixth field, and why it is not an invented digest)

The five fields above let a check compare a **product to the graph it was generated from** (did the graph change since this product was written) — they say nothing about whether the **graph itself still describes the current working tree** (did the tracked source change since the graph was built). Per data-model.md, freshness is defined against "the graph's manifest/hashes **vs the current working tree**," and closing that gap needs a value recorded *at generation time* that a later check can cheaply, mechanically recompute against *whatever the worktree looks like right now* — without a state file (D32).

Rather than inventing a parallel content-hashing mechanism, reuse what is already there: `graph.json`'s own top-level `built_at_commit` field is exactly this basis — a git commit SHA (verified: `specs/005-graphify-context/graph-baseline.json` carries `built_at_commit: 9cc8479978f5f1986246e0fb6a9eb11ab8106dd5`, a real, valid, currently-reachable commit object in this repo's history). Carrying it forward costs nothing extra to compute (the upstream extraction already produced it) and lets the worktree-side check run as a single `git diff` plumbing call rather than a full re-hash of every tracked file.

**Common case — `source-fingerprint: git-commit:<40-hex>`.** Copy `graph.json["built_at_commit"]` verbatim, prefixed for self-description. This is git's native SHA-1 commit id, not a digest this contract invents.

**Fallback — `source-fingerprint: sha256:<64-hex>`** (merged/stack scope, or any future extraction path that does not emit `built_at_commit` — unverified either way, since no merged-scope `graph.json` sample exists in this repo to inspect): enumerate every git-tracked file under the graph's own scope root via `git ls-files -z`, sort `LC_ALL=C`, hash each file's *current on-disk content* (not git's cached index blob-sha, which would miss an edited-but-unstaged file) with `shasum -a 256`, concatenate the `<hash>  <path>` lines, and SHA-256 that concatenation. Using `git ls-files` rather than a raw filesystem walk has a free side effect worth naming: it automatically excludes `graphify-out/` (gitignored, D45) and everything else gitignored, so the graph's own disposable output never perturbs the fingerprint of the source it describes.

`freshness.sh` distinguishes the two forms by the field's prefix and recomputes accordingly (below) — never by guessing.

**Known, accepted limit.** An untracked file (never `git add`ed even once) that the upstream extraction nonetheless picked up from the raw filesystem would not perturb either form of this fingerprint — a narrow, accepted gap given this pipeline's git-native, branch-per-feature discipline (D25), where in-progress work is normally tracked-but-uncommitted rather than fully untracked.

### Freshness decision — what `freshness.sh` reads and how it decides

`freshness.sh <product-path>` (contracts/commands.md: exit `0` = fresh; exit non-zero + `stale: regenerate <product>` on stdout = stale) decides using **only** this header plus the current state of `graph.json` and the current worktree — no state file, nothing cached from a previous run (D32) — recomputed on every call, never reused across hook invocations.

1. **Product-vs-graph check.** Read `graph-path` and `generation-id` from the header. Recompute `generation-id` fresh, right now, from the *current* `graph-path` file (canonicalization above). A mismatch means the graph has been rebuilt/changed since this product was generated → **stale**.
2. **Graph-vs-worktree check.** Read `graph-scope` and `source-fingerprint` from the header.
   - If `git-commit:<sha>`: run `git diff --quiet <sha>` from the graph's scope root. Exit `0` (no difference) → this check passes; a real diff, or an error (e.g. `<sha>` no longer reachable — an unusual case, such as a history rewrite) → **stale**. An error is never silently treated as fresh — unprovable freshness is stale, the safe default.
   - If `sha256:<hex>`: recompute the `git ls-files`-based digest (above) against the current worktree and compare for exact string equality; a mismatch → **stale**.
3. **Fresh** only if both checks pass. Either failing alone is sufficient for **stale** — the two checks are independent and complementary (check 1 catches "graph rebuilt, product not regenerated"; check 2 catches "source edited, graph never rebuilt"), not restatements of each other.

Because `git diff --quiet` compares the recorded commit against the *current* working tree content (not merely commit identity), check 2 is genuinely content-based, not version-count-based: two different commits with byte-identical tracked content compare as fresh. It is also deliberately whole-tree, not narrowed to the file types the graph explicitly models — a tracked change to a file `graphify` doesn't parse still trips **stale**, by design: given `freshness.sh` only ever hard-warns and routes to regeneration (never a hard-block, per contracts/commands.md), an occasional over-cautious warning on an irrelevant change is the acceptable cost against the alternative of silently missing a relevant one.

This maps directly onto the fixture branches this arm must prove — both branches of the guard, never only the passing one:
- **stale-positive:** a graph + a mutated worktree → mutate any git-tracked file under the scope root without rebuilding the graph → check 2's recomputation differs from the recorded `source-fingerprint` → **stale**. (A distinct stale sub-case is separately exercisable: rebuild `graph.json` without regenerating the product, tripping check 1 instead of check 2 — the two are independently triggerable if finer-grained fixtures are wanted.)
- **stale-negative / no false alarm:** a graph + an unmutated worktree → neither `graph.json` nor any tracked source file changed since generation → both recomputations match their recorded values exactly → **fresh**, exit `0`, nothing warned.

Both checks are cheap: field extraction via `sed`/`grep`, one canonicalize-and-hash pass over `graph.json` for check 1, and one `git diff --quiet` plumbing call for check 2 (common case) — POSIX/git tools only, no state file, sub-second at this repo's current scale (FR-005).

### Coherence across the three products

All seven fields are stamped once per generator run and copied **verbatim** into all three products — not `generation-id` alone, the entire header block, byte-for-byte identical across `graphify-context.md`, the receipts diet, and the type-signal diet (one graph, one run, one set of facts about it; the same "structural, not aspirational" bar this plan already applied when it chose separate products over a single sectioned file, D53). This makes the cross-product coherence check mechanical and simple: extract the header block from each of the three products and diff them — the diffs must be empty. A per-product golden still independently covers each product's own diet-specific *body* beneath the header (the header's byte-identity does not substitute for that); the coherence fixture is what catches drift **between** products that no single product's own golden can ever catch alone.

### Golden-fixture guidance

`generated-at` is the one field that is not reproducible from a clean checkout by construction — it is real wall-clock time at generation, so it differs between any two separate runs, including two runs of a fixture harness. Goldens for this header **MUST NOT** assert `generated-at` byte-for-byte against a captured real timestamp; every other field (`graph-path`, `graph-scope`, `node-count`, `edge-count`, `generation-id`, `source-fingerprint`) **is** byte-stable given fixed input and **MUST** be asserted byte-for-byte. Recommended, singular convention, so fixture authors don't each invent a different one: normalize the actual output's `generated-at` line to a fixed sentinel (e.g. `generated-at: <FIXED-FOR-GOLDEN>`) before diffing, and commit the golden with that same sentinel rather than a captured real timestamp.

### Worked example

```
<!-- graphify-provenance:v1
graph-path: graphify-out/graph.json
graph-scope: repo
node-count: 1611
edge-count: 2674
generated-at: 2026-07-14T18:32:05Z
generation-id: sha256:1f3c9a7d0e6b5c2a4f8d9e1b3c5a7f9d2e4b6c8a0f2d4e6b8c0a2f4e6d8c0b2a
source-fingerprint: git-commit:9cc8479978f5f1986246e0fb6a9eb11ab8106dd5
-->
```

`node-count`/`edge-count` above are this feature's own real, verified baseline (`specs/005-graphify-context/graph-baseline.json`); `generation-id`'s hex is an illustrative placeholder (not a real computed digest); `source-fingerprint`'s commit is real and reachable in this repo's history but illustrates the *field's shape*, not a pinned/special commit.

## Done When

- [ ] `<FEATURE_DIR>/graphify-context.md` exists and cites real graph paths
- [ ] Shared/mutable files section is populated (or explicitly "none found")
- [ ] If the graph was missing, the user was told to run `/graphify` (no file fabricated)
- [ ] `<FEATURE_DIR>/graphify-receipts.md` and `<FEATURE_DIR>/graphify-type-signal.md` also exist, written in the same run
- [ ] All three products carry the identical shared-provenance header, byte-for-byte — one `provenance.sh header` call (Step 6), never three
- [ ] `graphify-context.md`'s five section headings are unchanged (FR-013); the two new diets follow their own templates above, including honest fallback labeling on any convention-derived line
