# arm2-equiv

Golden fixture for arm 2's **SC-004 equivalence exit test, case (c): 0 survivors**
(T012, 005-graphify-context). `input/graph.json` is a small 3-file base graph
(`src/cli/stable.sh`, `src/cli/parse.sh`, `src/cli/format.sh`); `input/changed-files.txt`
declares a bounded 2-file changed scope (`parse.sh`, `format.sh` -- `stable.sh` stays
untouched, proving the merge is scoped, not a whole-graph rebuild in disguise); and
`input/fresh-extraction.json` is the fresh extraction those two files would produce
post-change -- `parse.sh`'s sole function is renamed (`parse_args` purged, `parse_input`
added: a full node+edge swap), and `format.sh` retains `format_output` but with an updated
`source_location` (a real line-shift, not a no-op) alongside a genuinely new function
`format_error` and a new intra-file `calls` edge. `cmd.sh` runs `refresh.sh` against this
scenario in a `mktemp` scratch (never mutating the committed `input/`), then asserts both
halves of SC-004: the stale-survivor guard must report `stale_survivors: 0` (the base's
`parse_args` node, attributed to a changed file and absent from the fresh extraction, must
not survive the merge), and the refreshed graph's changed-scope slice must be
byte-equivalent -- under canonical JSON via `canonicalize_scope.py` (sorted keys, a stable
node/link ordering keyed off `id`/`(source,target,relation,source_location)`, compact
form, and top-level graph-global fields like `built_at_commit` deliberately excluded from
the comparison) -- to `input/fresh-extraction.json` itself. That reuse is not circular:
because extraction is deterministic (no LLM, the same byte-determinism argument arm 1/S11
relies on), the fresh extraction of a file legitimately IS what an independent full regen
of that file would produce, so one committed file can honestly serve double duty as both
the merge's input and the fixture's full-regen answer key, without needing a second,
hand-duplicated "answer" file that could silently drift from the first. A scratch
validation (correct-merge vs. a naive-union-no-purge merge, both simulated against this
exact fixture data, outside the repo tree) confirmed the check actually discriminates: the
correct merge yields `stale_survivors: 0` / `equivalent: yes`, while the naive union
yields `stale_survivors: 1` / `equivalent: no` -- this is not a vacuously-true diff.
`extensions/graphify/extension/scripts/refresh.sh` (T016, a later wave) does not exist
yet, so `cmd.sh` currently fails with "No such file or directory" -- the intended
red-for-the-right-reason TDD state (see `extensions/graphify/test/run.sh`'s
fixture-discovery convention), not a malformed fixture; once `refresh.sh` lands honoring
the contract below, this fixture goes green with no edits required.

## Shared test-seam contract with arm2-survivors (T013)

This fixture's sibling `arm2-survivors` (T013, case (d) -- the negative-path,
manufactured-survivor inverse of this fixture's 0-survivor positive case) binds the
exact same not-yet-built `refresh.sh`. `contracts/commands.md` pins down only "prints
`stale_survivors: <N>`" for that script, leaving its invocation shape open -- so rather
than each fixture independently guessing a CLI and leaving T016 two conflicting
proposals to reconcile for one script, **this fixture adopts `arm2-survivors`'s
already-established test seam verbatim**:

- **Invocation:** `refresh.sh <scratch-dir>`, run with cwd ALSO set to `<scratch-dir>`
  (hedges a cwd-relative or an argv-based implementation -- either satisfies both
  fixtures).
- **Reads** `<scratch-dir>/graphify-out/graph.json` (the D45 working-graph path
  convention) -- mutated in place.
- **Reads** `<scratch-dir>/changed-files.txt` -- newline list of changed file paths.
- **Reads** `<scratch-dir>/fresh-extraction.json` -- `{"nodes":[...],"links":[...]}`,
  the authoritative pre-computed fresh extraction (a deliberate test seam standing in
  for a live AST re-extraction; that fidelity is upstream `graphifyy`'s own concern,
  S22, not this equivalence check's).
- **Prints** `stale_survivors: <N>` to stdout; other lines are tolerated.

## Flags for T016 (beyond the shared invocation contract above)

- **`stale_survivors:` line extraction is tolerant, not verbatim:** `cmd.sh` greps the
  one documented line out of `refresh.sh`'s full stdout, so extra diagnostic output
  (e.g. the S06 re-invocation of `augment.sh` on the changed scope) will not break this
  fixture.
- **Scope of the equivalence diff is deliberately narrow:** only nodes/links whose
  `source_file` is in `changed-files.txt`, and only the `nodes`/`links` keys -- top-level
  graph metadata (`built_at_commit`, `directed`, `multigraph`, `hyperedges`) is excluded
  on purpose, since a full regen and an incremental refresh legitimately differ there
  without that being a real regression.
- **`community` values are held consistent by construction, not independently
  verified:** this fixture assumes an incremental merge does not run a full-corpus
  reclustering pass on every refresh (which would renumber communities and would also
  work against SC-004's cost goal) -- a defensible but S22-unverified assumption about
  upstream `graphifyy` internals. If the real merge legitimately recomputes `community`
  differently, T016 must either update the expected values here or exclude `community`
  from `canonicalize_scope.py`'s comparison; it must not silently widen the fixture's
  tolerance without saying so.
- **Only the common/cheap-refresh branch of the S02 table is exercised here:** this
  fixture assumes the `graphify-version.pin` check passes (no version mismatch forcing
  a full regen). The version-mismatch branch is `T017`'s own concern and is not covered
  by this fixture.
- **Survivor counting is node-scoped, matching the contract's literal wording** ("no
  *node* attributed to a changed file survives absent from the fresh extraction") --
  edge-level staleness (a dangling link to a purged node) is instead caught by the
  equivalence check, not double-counted into `stale_survivors`.
