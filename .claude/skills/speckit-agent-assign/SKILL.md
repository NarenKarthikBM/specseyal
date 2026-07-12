---
name: "speckit-agent-assign"
description: "Run the deterministic assemble.py matcher over categorization.md and the .claude/agents / .claude/skills library: verify categorization.md's recorded tasks.md SHA is still fresh (S14 — hard-warn and route to /speckit-categorize on drift), assemble the roster into agents/assignment.md's ### Roster approved table (S08), and report the ∅-match gap list. On a non-empty gap list, dispatch one Sonnet skill-builder session per shared-tag gap cluster (dedup — SC-007/FR-006), validate each candidate (validate-skill.py — S1-S3 + S04), persist a pass to .claude/skills/ (origin: generated, source_feature — FR-008) with a hard-fail/rename on a live-library collision (S07), then re-run assemble.py once more with --built-skill for every persisted id (S15) before handing off to gate resolution."
argument-hint: "None — behavior is fully determined by categorization.md, the on-disk library, and profile.yaml. Any text passed is ignored."
compatibility: "Requires specs/<feature>/categorization.md (written by /speckit-categorize) and a base+skill library at .claude/agents/ + .claude/skills/ (seeded by extensions/workforce/install.sh). The workforce extension must be installed (.specify/extensions/workforce/). On a ∅-match gap, also requires templates/skill-builder-prompt.md and scripts/validate-skill.py (same extension, T022/T024)."
metadata:
  author: narenkarthikbm
  source: "extensions/workforce/skills/speckit-agent-assign/SKILL.md — speckit-ext-workforce (specs/003-workforce), T016 (static assembly) + T025 (gap handoff)"
user-invocable: true
disable-model-invocation: false
---

## User Input

```text
$ARGUMENTS
```

This command takes no arguments — its behavior is fully determined by `categorization.md`, the on-disk `.claude/agents`/`.claude/skills` library, and `profile.yaml`'s `gates.workforce.mode`. Non-empty `$ARGUMENTS` is unexpected; ignore it rather than inventing a flag `commands.md` doesn't define.

## What this is

`/speckit-agent-assign` is the **agent-assign** phase (`artifact-layout.md` §2 phase table), running immediately after `/speckit-categorize`. Per the plan's technical-approach split — "categorization = inference (Sonnet), assembly = code, skill-building = inference (Sonnet)" — this command's deterministic core is **not an LLM session**: `assemble.py` (`agent-library-schema.md` §3, verbatim) reads `categorization.md` and the base+skill library, matches every task to a base specialist plus up to 3 ranked skills, and **writes `agents/assignment.md`'s `### Roster approved` table itself** — a tool-permission fact (S08), not a prose promise, and the mechanism that makes SC-005's byte-identical-on-gap-free-rerun claim real.

**Full contract, as of T025.** This command implements all three of `commands.md`'s behavior steps: (1) run `assemble.py`, emit the roster + gap list; (2) on a non-empty gap list, dispatch one Sonnet `skill-builder` per shared-tag gap cluster, validate, and persist each pass into `.claude/skills/` (`## 2. Gap handoff`, below); (3) re-run `assemble.py` once more so newly-built skills carry the `built` mark (FR-022) before the roster is handed to gate resolution. A run whose Step 1 `GAP_TASKS` is empty never dispatches anything — `tasks.md`'s own dependency notes call this "US2 … viable without the builder," and that stays true: the builder is additive, not load-bearing, for a feature whose tags the static library already covers. A run that dispatches the builder and still can't close every gap (a hard-fail collision, S07, or a rejected module, FR-007) is not a failure either — `## 2. Gap handoff` surfaces exactly which task(s) remain open, and the roster stays a valid, committable interim state (the same "no fabricated skill, ever" posture this command has always held) pending a human decision or a later re-run.

## Pre-Execution

1. **Resolve the feature.** Run `.specify/scripts/bash/check-prerequisites.sh --json --paths-only` from the repo root; parse `REPO_ROOT`, `BRANCH`, `FEATURE_DIR` (absolute paths — use them absolute in every subsequent command this session).

2. **Precondition: `categorization.md` must exist.** If `$FEATURE_DIR/categorization.md` is missing, STOP: "no categorization.md — run /speckit-categorize first." Write nothing.

3. **Don't silently clobber an already-signed gate.** If `$FEATURE_DIR/agents/assignment.md` already exists, read its `## Workforce Gate` table's `decision` cell. `assemble.py` always re-renders the **entire** file fresh from `assignment.template.md` on every invocation — it has no "patch an existing file" mode — copying the template's `[PENDING ...]` bracket markers through unchanged. A naive re-run after a human has already signed would therefore silently destroy the recorded decision.
   - `decision` is `` `rejected` `` → proceed. This *is* the reassignment path (`artifact-layout.md` §8 W3): a fresh roster proposal is exactly what should happen next.
   - `decision` is `` `approved` `` or `` `approved-with-notes` `` → **STOP**: "`agents/assignment.md` already carries a signed Workforce Gate (`<decision>`, reviewer `<reviewer>`) — re-running `/speckit-agent-assign` would silently overwrite it. If this is a deliberate re-assign, preserve the signed roster first (e.g. `git show`/a copy); this command will not do it silently." Do not proceed.
   - `decision` is still a `[PENDING ...]` marker, or the file doesn't exist yet → proceed normally; nothing signed is at risk.

4. **S14 freshness check — the load-bearing precondition this command exists to add.** `assemble.py` itself only *stamps* the `tasks.md` SHA `categorization.md` recorded; it deliberately does **not** compare it against the live `tasks.md` (its own module docstring, "Scope note (S14)": *"this script extracts and stamps that value for visibility but does NOT compare it against the current tasks.md -- that freshness check is /speckit-agent-assign's job"*). That comparison happens here, before `assemble.py` ever runs.

   a. **Read the recorded SHA.** `categorization.md`'s header carries the line `> **Source binding (S14):** derived from \`tasks.md @ <sha>\` (<N> tasks).` (written by `/speckit-categorize`, `categorizer-prompt.md` §4). Extract `<sha>`. If the line is missing, or `<sha>` doesn't parse as a short hex commit id, treat it the same as a mismatch below — never assume freshness you can't confirm.

   b. **Compute the current SHA.** `git log -1 --format=%h -- "$FEATURE_DIR/tasks.md"` — the identical command `categorizer-prompt.md` §4 itself uses, so the two sides are always comparing like-for-like.

   c. **Check for uncommitted drift too.** `git status --short "$FEATURE_DIR/tasks.md"`. Non-empty output means `tasks.md` carries local changes not yet committed — even if (b)'s SHA still matches, the working tree no longer matches what was categorized.

   d. **Compare.** Recorded SHA == current SHA **and** no local changes → fresh; proceed to Step 1, and name the confirmed SHA in the Completion Report. Otherwise (mismatch, an unparseable recorded SHA, or local drift) → **HARD-WARN and STOP**, before running `assemble.py`:
      > `tasks.md` has moved since `categorization.md` was derived (categorized @ `<recorded-sha-or-"unparseable">`, `tasks.md` now @ `<current-sha>`[, plus uncommitted local changes]) — re-run `/speckit-categorize` before `/speckit-agent-assign`. Assembling against a stale classification is exactly what S14 exists to prevent.

      Write nothing; do not proceed to Step 1.

## 1. Run `assemble.py` (zero-AI, deterministic)

Invoke the installed script — `.specify/extensions/workforce/scripts/assemble.py` (fall back to the repo source `extensions/workforce/extension/scripts/assemble.py` only if the extension isn't installed in this repo yet, the same fallback convention `/speckit-council-triage` uses for `chairman-prompt.md`):

```
python3 <assemble.py path> "$FEATURE_DIR/categorization.md" \
  --library-dir "$REPO_ROOT/.claude" \
  --output "$FEATURE_DIR/agents/assignment.md"
```

This first invocation never passes `--built-skill` — nothing has been built yet at this point in the run. If `GAP_TASKS` (below) comes back non-empty and `## 2. Gap handoff` goes on to persist one or more skills, that section re-invokes this exact command a second time, passing one `--built-skill <id>` per persisted skill (S15) — see `## 2. Gap handoff` step (d); that second invocation is never issued here.

**Exit code contract**, straight from `assemble.py`'s own CLI docstring:

| Exit | Meaning | Action |
|---|---|---|
| `0` | Roster written. | Continue to Step 2. Parse stdout (below). |
| `2` | runtime_consumed guard violated (FR-014/SC-006) — a `runtime_consumed: true` task assembled onto a non-Sonnet base (the re-homed D48 guard, D65 §2.4). Nothing written. | Hard error. Report the stderr line verbatim (it names the task/base). Stop — this is a library defect, not something to route around. |
| `3` | Malformed input or a library invariant violation (duplicate id, non-unique `(type, specialization)` lane, missing `agt_generic` fallback, missing `skl_refactor_discipline` when required, template render failure — or a missing `.claude/agents`/`.claude/skills` dir entirely). Nothing written. | Report the stderr line verbatim. If it names a missing agents/skills dir, point at `extensions/workforce/install.sh` — the seed library may never have been installed. Stop. |
| `4` | A library entry's frontmatter failed to parse (`frontmatter.py`'s `FrontmatterError`). Nothing written. | Report the stderr line verbatim (it names the offending file). Stop. |

On any non-zero exit, `agents/assignment.md` is untouched (assemble.py's own contract: "nothing was written") — there is nothing to commit; skip straight to the Completion Report with the failure.

**On exit `0`, parse stdout** (assemble.py's fixed output shape, `main()`):
- `assemble.py: wrote <path> (<R> roster row(s) over <T> task(s))` — row/task counts for the report.
- `GAP_TASKS: <comma-separated task ids, or nothing>` — the ∅-match list. `GAP_TASKS: ` with nothing after the colon means gap-free.
- `GAP_CLUSTERS: <space-separated `[id,id]` groups, or nothing>` — the **gap-batching** (D66): assemble.py's own connected-components clustering of the gap tasks by shared tag. Each bracketed group is one shared-tag cluster → **exactly one** skill-builder dispatch (`## 2. Gap handoff`); the same clusters are recorded in the roster's `**Gap clusters …**` notes. `GAP_CLUSTERS: ` with nothing after the colon means gap-free. This is the dispatch list — do not re-derive clusters by hand.
- `GRANT_TRIPWIRE: <total-ordered elevated grants, or `none`>` — the **D67 tripwire**: the roster-wide elevated-grant union. Anything other than `none` forces the workforce gate to a human regardless of `gates.workforce.mode` (`## 3. Gate resolution`). Already written into the roster's `**Grant tripwire (D67)**` notice too.
- `assemble.py: empty lane (FR-016) on: <ids>` — present only if a task fell to `agt_generic` on an unmatched `(type, specialization)` lane. Informational, not an error.
- `assemble.py: <n> skill(s) dropped by the cap (FR-011/SC-004)` — present only if the 3-skill injection cap trimmed a candidate; already logged in the roster's own notes (`{{DROPPED_SKILL_NOTES}}`).
- `LIBRARY_SNAPSHOT_HASH: <hash>` — the S18 content-hash of the base+skill library at this run's start; already stamped into `agents/assignment.md`'s own header too.

`assemble.py` has now written the complete `### Roster approved` table and the `## Workforce Gate`'s `[PENDING ...]` markers into `agents/assignment.md` **itself** (S08). Nothing in this command hand-edits that table, ever — the closest this command comes to touching the file is Step 3 below, and even then only the five bracket-marked gate fields, never a roster row.

## 2. Gap handoff (skill-builder → validate → persist → re-run)

Runs only when Step 1's `GAP_TASKS` is **non-empty**. If it was empty, skip straight to Step 3 — no session is dispatched, no `traces.jsonl` record is appended, and Step 1's roster is already final (SC-005's gap-free, byte-identical claim holds exactly as it did before T025).

Otherwise this section implements `commands.md`'s remaining behavior steps 2–3 in full: for each gap, dispatch a Sonnet `skill-builder` holding its declared `web_search` grant (D60) → validate (`validate-skill.py`: S1–S3 plus the S04 tag-intersection) → persist a pass to `.claude/skills/` (FR-008) → re-run `assemble.py` once more so the final roster carries every `built` mark FR-022 requires. Resolve `skill-builder-prompt.md` and `validate-skill.py` the same installed-vs-source way Step 1 already resolves `assemble.py`'s own path (`frontmatter.py` is `validate-skill.py`'s sibling — resolving the directory carries it along, the same note Pre-Execution step 3 makes for the categorizer's own validator).

**a. Read the gap clusters — one dispatch per cluster, never per task (FR-006/SC-007/S24, D66).**

**Do not re-derive the clustering by hand — `assemble.py` already computed it** (D66 verdict 11 moved the gap-batching out of this command's prose and into the assembler's deterministic output). Parse Step 1's `GAP_CLUSTERS:` stdout line: each space-separated bracketed group — e.g. `[T005,T012] [T020]` — is one **shared-tag cluster**, the connected components of the gap tasks' tag graph (an edge wherever two gap tasks' tag lists intersect). Two gap tasks sharing one novel tag are already in the same bracket and get **exactly one** `skill-builder` dispatch between them, never one each (`skill-builder-prompt.md`'s own words: "a shared tag across several gapped tasks is precisely the case where one well-scoped module should cover all of them"); a gap task sharing no tag with any other is its own single-member bracket. The clusters arrive already ordered by their lowest member task id (assemble.py's `_task_id_sort_key`) and are also recorded in the roster's `**Gap clusters …**` notes for the human at the gate. For each cluster, look up its members' `(type, specialization, tags)` rows in `$FEATURE_DIR/categorization.md` to render the builder prompt's slots (below).

**b. Per cluster, serially — never in parallel (collision-safety, S07).**

Process clusters one at a time, start to finish (dispatch → read the return → validate → persist-or-reject → trace), before starting the next. This is load-bearing: a builder's own Step-1 self-check (`skill-builder-prompt.md` — Glob `.claude/skills/*/SKILL.md` before naming) and `validate-skill.py`'s id-collision check (`_find_id_collision`, globbing that same live `library_dir`) only see what's *actually on disk* at the moment they run. Serial processing means cluster 2's builder — and its own validator pass — sees cluster 1's skill if cluster 1 persisted, closing the one collision hole a per-cluster self-check can't see alone (two clusters independently picking the same name in the same run). Parallel dispatch would silently reopen that hole.

For each cluster, in order:

  i. **Stage.** `mktemp -d` for a fresh scratch directory — outside the repo, so nothing lands in the feature tree even transiently (this command's only artifact in `specs/<feature>/` stays `agents/assignment.md`, per `commands.md`'s own header). This dispatch's `{{output_path}}` is `<scratch-dir>/SKILL.md`.

  ii. **Render.** Substitute `skill-builder-prompt.md`'s five slots verbatim: `{{feature}}` → the spec id; `{{task_ids}}` → this cluster's task ids, comma-joined, ascending; `{{task_type}}`/`{{task_specialization}}` → the cluster's lowest-id task's own values (note plainly in the Completion Report if other members disagree — the module selects by tags, not this pair, so a divergence is informational, never a blocker); `{{task_tags}}` → the union of every member's tags, comma-joined; `{{output_path}}` → (i)'s literal scratch path.

  iii. **Dispatch.** One Sonnet subagent via the `Agent` tool, the rendered text as the literal `prompt` — `subagent_type: general-purpose`, the same generic file-writing/tool-using rationale `/speckit-categorize` and `/speckit-council` already apply to their own Sonnet dispatches. No extra tool-grant wiring is needed or possible beyond that: `general-purpose` already carries `WebSearch`, and D60/A-2's "the skill-builder role holds `web_search`" is realized entirely by the rendered prompt telling the session so (`skill-builder-prompt.md` Step 5) — the audit boundary is the trace record (c) and the roster, never a Claude-Code permission scope. No `isolation` is needed either — each cluster's scratch dir is already unique (`mktemp -d`), so there is no file-collision risk between this dispatch and any other. Barrier: wait for the return.

  iv. **Read the one-line return** — `skill-builder-prompt.md`'s own contract has exactly three shapes:
      - `Wrote <path> (...) — ...; searched: <yes|no>.` — a draft exists at the scratch path. Note `searched:` (it drives (c)'s `elevated_grants`). Continue to (v).
      - `Collision on <id|name> — hard-failed, forwarding for resolution (S07).` — **no file was written** (the builder's own Step 1 runs before it writes anything). This cluster's task(s) stay gapped. Report the collision verbatim. Skip to (c)'s trace, then the next cluster.
      - `Collision on <id|name> — renamed to <new-name> (S07).` — a draft **was** written, under the renamed identity. Continue to (v), noting the rename plainly.
      - Anything else, or no return at all (a broken one-line contract, a crash, a timeout): mirror `/speckit-categorize` Step 1's own edge case — never fabricate a status, never retry silently. Check whether `<scratch-dir>/SKILL.md` actually exists regardless of what came back — the file, not the reply, is authoritative. If it exists, continue to (v) anyway; if not, this cluster's task(s) stay gapped, note the broken contract/dispatch failure in one line, and still append a best-effort trace ((c), `outcome: "failed"`) before moving on.

  v. **Validate** (S1–S3, S04, FR-007):
     ```
     python3 <validate-skill.py path> "<scratch-dir>/SKILL.md" "<lead task's tags>" "$REPO_ROOT/.claude/skills"
     ```
     `<lead task's tags>` = the cluster's lowest-id task's own tag list (the "triggering task's tags" `validate-skill.py`'s CLI names). `library_dir` is the **real, live** `.claude/skills`, not the scratch dir — this independently re-checks the id-collision the builder already self-checked. Exit `0` → continue to (vi). Non-zero → **rejected, not persisted** (FR-007): report every `REJECTED:` / `  - ` stderr line verbatim, never summarized away. This cluster's task(s) stay gapped; no retry this run (mirrors `/speckit-categorize`'s own "a FAIL means stop and report... a human decides" posture). Go to (c), then the next cluster.

  vi. **Persist** (FR-008) — the *only* edit this command ever makes to a skill-builder's own content:
      - Compute `body_sha256` of the draft's body (everything after the closing `---` fence) by importing the **shared** `frontmatter.py` (S21 — `split_frontmatter` + `body_sha256`); never hand-roll a second hash (`skill-builder-prompt.md`'s own words: "the persistence step computes it from what you wrote").
      - Edit the draft's `body_sha256: null` line to that hash — the one byte this command changes; every other line, including a S07 rename, stays exactly as authored.
      - Read the draft's own top-level `name:` field (kebab-case) — the target directory, matching every seed skill's own convention (`.claude/skills/orchestration/SKILL.md` ↔ `name: orchestration`); never re-derive a slug from `id:` or from the task.
      - **One more live-collision guard, immediately before the write** (closing the residual same-run race (b)'s serial ordering already narrows to near-zero): if `$REPO_ROOT/.claude/skills/<name>/` already exists, treat it exactly like a builder-reported collision — hard-fail this cluster, report it, never silently overwrite. Otherwise `mkdir -p` it and write the hash-patched file to `$REPO_ROOT/.claude/skills/<name>/SKILL.md`, with `origin: generated` and `provenance.source_feature` exactly as the draft carried them (already re-validated by (v)) — never `origin: promoted`; promotion is a separate, manual action this command never performs (FR-009).
      - Record the persisted skill's `specseyal.id` into this run's growing `BUILT_SKILL_IDS` list — (d) below passes every id in it to the re-run's `--built-skill`. Remove the scratch directory.

**c. Trace — one `agent-creator` record per dispatch attempted, appended immediately (never batched across clusters — the same serial-append discipline `/speckit-council` and `/speckit-categorize` hold for their own dispatches).**

One record per *cluster* (matching (a)'s dedup: three gapped tasks sharing one tag still produce one dispatch and one trace, never three). A cluster whose builder hard-failed a collision or whose draft was rejected still had a real dispatch happen — it still gets exactly one trace, `outcome: "failed"`.

| Field | Value |
|---|---|
| `schema_version` | `"1.0"` |
| `trace_id` | fresh, unique |
| `parent_trace_id` | `null` — this command's own invocation is main-thread, not itself a traced role (same convention as `/speckit-categorize` Step 4 and council's top-level fragments) |
| `feature` | the spec id |
| `phase` | `"agent-assign"` |
| `role` | `"agent-creator"` (`trace-schema.md` §2) |
| `agent_id` | `null` (non-null iff `role == "implementer"` — a skill-builder dispatch never is, trace-schema.md §7 rule 4) |
| `skills` | `[]` (the builder is a fixed-role session, not an assembly — trace-schema.md §7 rule 5) |
| `elevated_grants` | `["web_search"]` iff (iv)'s return read `searched: yes`; `[]` otherwise, including on every hard-fail/rejected/dispatch-failure outcome — the dispatch's own declared grant (D60), recorded per D43 |
| `model` | `"claude-sonnet-5"` — exact id, never the alias `sonnet` (`workforce-config.yml`'s `model: sonnet` resolves to this) |
| `effort` | `"medium"` — the same Sonnet-mechanical-role precedent `/speckit-categorize`'s own trace uses |
| `started_at`/`ended_at`/`duration_ms` | this dispatch's actual wall-clock span |
| `tokens`/`capture_method` | transcript-based attribution (D47); fall back honestly to `capture_method: "unavailable"` / `tokens: null` when unavailable — never guessed |
| `outcome` | `"success"` iff (vi) persisted; `"failed"` on a hard-fail collision, a `validate-skill.py` rejection, a no-file broken-contract return, or a dispatch failure |
| `artifact` | the persisted repo-relative path, `.claude/skills/<name>/SKILL.md`, on success (outside `specs/<feature>/`, same as the file itself — D24/S07); `null` on every failed outcome |
| `cost_usd` | `null` (D28) |

**d. The mandatory re-run — once, after every cluster has been attempted, never per-cluster (S15).**

If `BUILT_SKILL_IDS` (accumulated across (b.vi)) is **non-empty**, re-invoke `assemble.py` exactly one more time, now passing one `--built-skill <id>` per persisted skill:

```
python3 <assemble.py path> "$FEATURE_DIR/categorization.md" \
  --library-dir "$REPO_ROOT/.claude" \
  --output "$FEATURE_DIR/agents/assignment.md" \
  --built-skill <id-1> [--built-skill <id-2> ...]
```

Handle its exit code exactly per Step 1's own 0/2/3/4 table — no second table here. On `0`: this write **supersedes** Step 1's roster and stdout numbers entirely — its `GAP_TASKS` / empty-lane / dropped-skill / `LIBRARY_SNAPSHOT_HASH` lines are what Step 3 and the Completion Report use from here on. Any task a cluster didn't actually close (an imperfect grouping, tags that didn't fully overlap the built skill) simply reappears in this second `GAP_TASKS` — `assemble.py` recomputes tag-intersection mechanically per task against the now-grown library, so under-coverage is caught here honestly, with no extra bookkeeping required of this section. S15 guarantees every task that was **not** in Step 1's `GAP_TASKS` renders byte-identically in this rewrite; this command relies on that guarantee rather than re-verifying it (that's `test_assemble.sh`'s/T026's job). On non-zero: report the failure exactly as Step 1 would; `agents/assignment.md` is left exactly as Step 1 wrote it (assemble.py's own "nothing written on a non-zero exit" contract applies here too); skills already persisted in (b.vi) remain on disk regardless — they independently passed (v) — but this run stops here, before Step 3; a human resolves it and a later `/speckit-agent-assign` run picks the roster back up.

If `BUILT_SKILL_IDS` is empty (every cluster hard-failed a collision or was rejected — nothing persisted), skip the re-run: nothing grew the library, so Step 1's roster and gap list are already final.

**No retry within a single run.** Whether a cluster hard-fails a collision or its module is rejected by (v), this section attempts it exactly once and moves on — the same "stop and report, let a human decide" posture `/speckit-categorize` holds for its own validator FAIL. A task still gapped after this one pass stays gapped, surfaced plainly; a fresh `/speckit-agent-assign` run (after a human or a library fix) gets a fresh attempt, since `categorization.md` is unchanged and `assemble.py` rediscovers the same gap deterministically.

## 3. Gate resolution (`gates.workforce.mode`)

Read `$FEATURE_DIR/profile.yaml`. If absent, unparseable, or `gates.workforce.mode` unset: mode is `human` (`profile-schema.md` P1 — a missing/broken profile is always the safest posture, never the fastest one). Otherwise read `gates.workforce.mode` literally.

- **`human`** (default) → do nothing further. `assemble.py` already left every gate field a `[PENDING ...]` marker; it stays that way, pending `/speckit-workforce-approve` (T017).

- **`auto`, no gap remains open after `## 2. Gap handoff`, AND the grant tripwire is clear** (Step 1's `GRANT_TRIPWIRE: none`; and `GAP_TASKS` was empty to begin with, **or** Step 2 dispatched the builder and its re-run's `GAP_TASKS` came back empty) → **this command writes the gate decision itself**, standing in for `/speckit-workforce-approve`'s own eventual write (FR-020). Unlike the council gate, workforce's `auto` is valid **standalone** — `profile-schema.md` P4: *"`gates.workforce.mode: auto` alone is valid with `full_auto: false`. The workforce gate is an economic guard … Only the correctness guard [council] is protected."* So this branch is **not** gated on `full_auto` the way `/speckit-council-triage` gates its own auto-write on the council handshake — read `gates.workforce.mode` alone. (The standalone-P4 reading is now ratified — D67 verdict 12, resolving I-19 — with the grant-tripwire carve-out below.)

  Edit `agents/assignment.md` in place, replacing exactly the five `[PENDING ...]` bracket markers `assignment.template.md` defines (never touch the `### Roster approved` table above them):
  ```markdown
  ## Workforce Gate — <ISO-8601 UTC timestamp>

  | Field | Value |
  |---|---|
  | reviewer | auto |
  | decision | `approved` |
  | reviewed | `categorization.md`, `assignment.md` (this roster) |
  ```
  and, naming plainly which of the two cases actually happened (never blur them — one is SC-005's byte-identical claim, the other isn't):
  ```markdown
  **Notes:** Auto-approved under `gates.workforce.mode: auto` — gap-free roster (zero `built` marks, SC-005).

  **Overrides:** none.
  ```
  or
  ```markdown
  **Notes:** Auto-approved under `gates.workforce.mode: auto` — <N> gap(s) closed this run by the skill-builder (`## 2. Gap handoff`: <M> skill(s) built, `skl_…@…` listed). Not a byte-identical/SC-005 run (LLM-authored content this run) — the re-run's `GAP_TASKS` came back empty.

  **Overrides:** none.
  ```
  (Same section, same position — only the bracket text changes; the heading line, table shape, and everything from `### Roster approved` down stay exactly as `assemble.py` wrote them.)

  **Known gap, not silently glossed over.** `commands.md`'s "Signer-agnostic (FR-010/W4)" clause requires the *same* `after_workforce_approve` gate-write to fire here that `/speckit-workforce-approve` triggers in human mode — binding `tasks.md` + `assignment.md@sha` into `gates.yml` via `on-gate-approve.sh workforce` (`git/extension.yml`). If that hook isn't reachable in this repo (git-ext not installed, or not yet reinstalled with the workforce gate wired), an auto-approval written by this step does **not** produce a `gates.yml` binding; say so plainly in the Completion Report rather than fabricating one.

- **`auto`, but the grant tripwire is ENGAGED** (Step 1's `GRANT_TRIPWIRE:` names any elevated grant — equivalently the roster's `**Grant tripwire (D67): ENGAGED**` notice) → **do not auto-approve, even with every gap closed.** D67 verdict 12: any elevated grant in the roster forces the workforce gate to a human **regardless of `gates.workforce.mode`** — approving a grant-bearing roster is approving network/tool access (A-2/D41), the one thing `auto` must not wave through unseen. Leave every gate field `[PENDING …]`; report in the Completion Report that the tripwire held the gate for a human despite `auto`, naming the grant(s). A human then runs `/speckit-workforce-approve`, which honors the same tripwire (it presents the roster and collects a decision rather than no-op'ing under `auto`).

- **`auto`, but at least one gap is still open after `## 2. Gap handoff`** (a hard-fail collision, a rejected module, or a cluster Step 2 simply didn't close) → **do not auto-approve.** Mirrors `/speckit-council-triage` never auto-approving a residual `blocking` item: an auto-approved roster with unresolved gaps would silently skip the exact review a newly-grown library deserves at the gate. Leave every gate field `[PENDING ...]`, and list plainly in the Completion Report which task(s) remain gapped and why (collision / rejected / not attempted) — a human decides how to proceed.

## 4. Commit — the `after_agent-assign` hook

Only when Step 1 exited `0` (something was actually written). `workforce/extension.yml` registers `after_agent-assign → speckit.git.commit` (phase `agents`, `optional: false`); v1 has no separate HookExecutor — *"the invoking phase-skill runs the hook and honors its exit code"* (`workforce/extension.yml`'s own hooks-header note) — so this command fires it directly:

```
<git-ext commit.sh path> agents "assemble roster from categorization.md (<T> tasks, <R> row(s)<, gap-free | , <N> gap(s) closed via skill-builder (<M> built) | , <N> gap(s) still open>)"
```

Prefer the installed path `.specify/extensions/git/scripts/commit.sh`; fall back to the repo source `extensions/git/extension/scripts/commit.sh` only if git-ext isn't installed in this repo yet — and if neither is found, do not fail the phase over a missing packaging dependency: note in the Completion Report that the roster was written but not committed, and why.

`commit.sh agents <summary>` composes the phase-tagged message `agents(<spec-id>): <summary>` itself (its own FR-006 grammar), self-heals onto the feature branch first, stages `specs/<spec-id>/**` (which already covers `agents/assignment.md`), and no-ops (exit 0, no commit) if nothing in scope actually changed — e.g. a re-run that reproduced a byte-identical roster. It prints only the new commit SHA (or nothing, on no-op) to stdout; it is itself mechanical git with **no model call and no `traces.jsonl` write** (`commit.sh`'s own header).

## Observability — one `agent-creator` trace per gap dispatch, never per task

`commands.md`'s Trace row for `/speckit-agent-assign` reads "one `agent-creator` record per skill-builder session (none on a gap-free run — R2/★★)." This command now implements that exactly: `assemble.py` itself is zero-AI (no trace — `commands.md`'s own header rule) and the gate-resolution/commit steps are mechanical (no session, the same no-session pattern the council gate follows) — so the *only* source of `traces.jsonl` records anywhere in this command is `## 2. Gap handoff`'s per-cluster dispatch loop (its own step c). A **gap-free** run (Step 1's `GAP_TASKS` empty) dispatches nothing and appends **zero** records, exactly as before T025. A **gap** run appends exactly one record per cluster dispatched — one per shared-tag group, never one per gapped task (the same SC-007/FR-006 dedup that governs the dispatch itself) — regardless of whether that cluster's dispatch ultimately persisted a skill, was rejected, hard-failed a collision, or never returned; every attempted dispatch leaves exactly one trace, `outcome: "success"` or `"failed"` accordingly.

## Completion Report

Report, concisely:
- Feature/spec-id.
- S14 freshness: the confirmed SHA, or the STOP reason if it stopped there.
- `assemble.py` (Step 1) outcome: exit code; on `0`, task/row counts, `GAP_TASKS` (or "gap-free"), empty-lane ids (if any), dropped-skill count (if any), `LIBRARY_SNAPSHOT_HASH`; on non-zero, the stderr line and which exit path (and stop — Step 2 never runs).
- Gap handoff (`## 2. Gap handoff`, only if Step 1 found gaps): cluster count and membership (which task ids grouped together, SC-007); per cluster, its outcome (persisted `skl_…@…`, rejected — reason, hard-failed collision, or dispatch failure) and whether it searched; the re-run's own exit code and its (possibly revised) `GAP_TASKS`/`LIBRARY_SNAPSHOT_HASH`; if skipped (gap-free at Step 1), say so in one line.
- Gate outcome: pending (`human`) | auto-approved this run (`auto`, no gap remains open **and grant tripwire clear** — naming whether that's Step-1 gap-free/SC-005 or gaps closed this run, and flagging the `gates.yml` binding's reachability) | held pending despite `auto` (naming why: which task(s) are still gapped, **or the grant tripwire ENGAGED (D67) — naming the elevated grant(s)**).
- Commit: the SHA `commit.sh` returned, "no-op", or "not committed — git-ext not installed".
- Trace count: the number of `agent-creator` records appended this run (zero on a gap-free run, one per cluster dispatched otherwise) — explicit either way, never silently omitted.
- Next step, stated explicitly (`/speckit-workforce-approve`, or "resolve the still-open gap(s) and re-run /speckit-agent-assign", or "re-run /speckit-categorize" if it stopped at S14).

## Done When

- [ ] Feature resolved; `categorization.md` precondition checked (stopped cleanly if absent)
- [ ] Signed-gate guard checked — never silently overwrote an `approved`/`approved-with-notes` decision
- [ ] S14 freshness verified (recorded SHA vs. current `tasks.md` SHA, plus a dirty-tree check) — hard-warned and stopped before running `assemble.py` on any drift
- [ ] Step 1's `assemble.py` invoked with no `--built-skill`; its exit code handled per its own 0/2/3/4 contract; `agents/assignment.md` left untouched on any non-zero exit
- [ ] On success: `GAP_TASKS`, empty-lane, dropped-skill, and `LIBRARY_SNAPSHOT_HASH` stdout lines parsed and reported; the `### Roster approved` table never hand-edited
- [ ] If `GAP_TASKS` was non-empty: gap clusters **read from Step 1's `GAP_CLUSTERS` line** (assemble.py's own connected-components batching, D66 — not re-derived by hand) — one `skill-builder` dispatch per cluster, never per task (FR-006/SC-007/S24); clusters processed **serially**, never in parallel (collision-safety, S07)
- [ ] Each cluster's builder return parsed for its three shapes (wrote / hard-failed collision / renamed collision) or handled as a broken-contract/dispatch failure per the file-is-authoritative rule; every candidate validated via `validate-skill.py` (S1–S3, S04) before being persisted — a rejection is surfaced, never persisted (FR-007)
- [ ] Every persist: `body_sha256` computed via the shared `frontmatter.py` (never hand-rolled) and stamped as the *only* edit made to the builder's content; target directory taken from the draft's own `name:` field; a last-second live-collision check guards the write; `origin: generated`/`source_feature` kept, never `origin: promoted` (FR-009); the skill's id recorded for the re-run
- [ ] If any skill was persisted: `assemble.py` re-run exactly once more with one `--built-skill <id>` per persisted skill; its exit code handled per Step 1's own contract; its (superseding) `GAP_TASKS`/`LIBRARY_SNAPSHOT_HASH` carried forward; if nothing was persisted, the re-run is skipped
- [ ] Exactly one `agent-creator` trace appended per cluster **dispatched** (success or failure alike), `elevated_grants: ["web_search"]` iff that dispatch's return said `searched: yes` — zero traces on a Step-1 gap-free run
- [ ] Gate mode resolved (`profile.yaml` → `human` default); `human` left pending; `auto` + no gap remains open + **grant tripwire clear (`GRANT_TRIPWIRE: none`)** wrote the decision in place (P4, ratified standalone by D67, naming which case — Step-1 gap-free or gaps closed this run); `auto` + a gap still open **or** the grant tripwire ENGAGED (D67) held pending for a human
- [ ] `after_agent-assign` hook fired via `commit.sh agents …` on any successful write; skipped gracefully (and reported) if git-ext isn't installed
- [ ] Trace count reported explicitly in the Completion Report, zero or otherwise — never silently omitted
- [ ] Completion Report delivered with a concrete next step
