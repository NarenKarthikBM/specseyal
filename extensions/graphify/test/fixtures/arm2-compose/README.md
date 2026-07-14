# arm2-compose — cross-arm composition fixture (T014, case (e), S06)

Asserts the **S06 cross-arm invariant**: an incremental `refresh.sh` MUST re-invoke
arm-1's `augment.sh` on the changed scope. Without it, every incremental refresh silently
regresses arm-1's `.sh`/`.yml` coverage on exactly the changed files — falsifying SC-004's
"equivalent to a full regen" — and no *per-arm* fixture can catch it, since each tests its
arm in isolation.

**Scenario.** `install.sh` changed. Its AST (the `old_stage` function) re-extracts
unchanged, so the incremental merge leaves `stale_survivors: 0`. Its `cp` line is an arm-1
augment `installs` edge (`install.sh` → `.specify/extensions/demo`) that the AST layer does
not model — a refresh that did only the AST merge would drop it. This fixture reads the
post-refresh graph off disk (not `refresh.sh`'s self-report) and requires that augment edge
to be present (`augment_edge_present: yes`), which forces `refresh.sh` to re-run augment.

**Seam.** Reuses the `refresh.sh <scratch-dir>` contract T012/T013 pinned (graph.json in
place, `changed-files.txt`, `fresh-extraction.json` as authoritative fresh AST, prints
`stale_survivors: <N>`), plus the S06 re-invoke-augment requirement. Red until T016 ships
`refresh.sh`; a stand-in that does the AST merge but skips augment fails on
`augment_edge_present: no`.
