---
name: "speckit-agent-assign"
description: "Run the deterministic assemble.py matcher over categorization.md and the .claude/agents / .claude/skills library: verify categorization.md's recorded tasks.md SHA is still fresh (S14 — hard-warn and route to /speckit-categorize on drift), assemble the roster into agents/assignment.md's ### Roster approved table (S08), and report the ∅-match gap list. This version implements only the static-assembly path — no skill-builder dispatch yet; that lands in T025's edit of this same command."
argument-hint: "None — behavior is fully determined by categorization.md, the on-disk library, and profile.yaml. Any text passed is ignored."
compatibility: "Requires specs/<feature>/categorization.md (written by /speckit-categorize) and a base+skill library at .claude/agents/ + .claude/skills/ (seeded by extensions/workforce/install.sh). The workforce extension must be installed (.specify/extensions/workforce/)."
metadata:
  author: narenkarthikbm
  source: "extensions/workforce/skills/speckit-agent-assign/SKILL.md — speckit-ext-workforce (specs/003-workforce), T016"
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

**Scope of this version.** This command currently implements only the **static assembly path** — `commands.md`'s behavior step 1 (run `assemble.py`, emit the roster + gap list) plus the gate/commit bookkeeping around it. It deliberately does **not** implement `commands.md`'s steps 2–3 (dispatch a Sonnet `skill-builder` per ∅-match gap, validate, persist, re-run gap-free) — that is task **T025**, which edits *this same file* at the marked `## 2. Gap handoff` section below. Until T025 lands, a run that reports a non-empty `GAP_TASKS` is not a failure — `tasks.md`'s own dependency notes call this "US2 … viable without the builder" — it is a valid, committable interim roster whose gap rows simply carry no skill match yet.

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

No `--built-skill` in this version — nothing has been built yet (T016 scope). T025's re-run (its own step 3, after the builder persists a skill) is what first passes that flag.

**Exit code contract**, straight from `assemble.py`'s own CLI docstring:

| Exit | Meaning | Action |
|---|---|---|
| `0` | Roster written. | Continue to Step 2. Parse stdout (below). |
| `2` | D48 guard violated (FR-014/SC-006) — a `prompt`-tagged task assembled onto a non-Sonnet base. Nothing written. | Hard error. Report the stderr line verbatim (it names the task/base). Stop — this is a library defect, not something to route around. |
| `3` | Malformed input or a library invariant violation (duplicate id, non-unique `(type, specialization)` lane, missing `agt_generic` fallback, missing `skl_refactor_discipline` when required, template render failure — or a missing `.claude/agents`/`.claude/skills` dir entirely). Nothing written. | Report the stderr line verbatim. If it names a missing agents/skills dir, point at `extensions/workforce/install.sh` — the seed library may never have been installed. Stop. |
| `4` | A library entry's frontmatter failed to parse (`frontmatter.py`'s `FrontmatterError`). Nothing written. | Report the stderr line verbatim (it names the offending file). Stop. |

On any non-zero exit, `agents/assignment.md` is untouched (assemble.py's own contract: "nothing was written") — there is nothing to commit; skip straight to the Completion Report with the failure.

**On exit `0`, parse stdout** (assemble.py's fixed output shape, `main()`):
- `assemble.py: wrote <path> (<R> roster row(s) over <T> task(s))` — row/task counts for the report.
- `GAP_TASKS: <comma-separated task ids, or nothing>` — the ∅-match list. `GAP_TASKS: ` with nothing after the colon means gap-free.
- `assemble.py: empty lane (FR-016) on: <ids>` — present only if a task fell to `agt_generic` on an unmatched `(type, specialization)` lane. Informational, not an error.
- `assemble.py: <n> skill(s) dropped by the cap (FR-011/SC-004)` — present only if the 3-skill injection cap trimmed a candidate; already logged in the roster's own notes (`{{DROPPED_SKILL_NOTES}}`).
- `LIBRARY_SNAPSHOT_HASH: <hash>` — the S18 content-hash of the base+skill library at this run's start; already stamped into `agents/assignment.md`'s own header too.

`assemble.py` has now written the complete `### Roster approved` table and the `## Workforce Gate`'s `[PENDING ...]` markers into `agents/assignment.md` **itself** (S08). Nothing in this command hand-edits that table, ever — the closest this command comes to touching the file is Step 3 below, and even then only the five bracket-marked gate fields, never a roster row.

## 2. Gap handoff (T025 — not yet implemented)

> **This section is the placeholder T025 edits.** `commands.md`'s full `/speckit-agent-assign` contract has two more steps after assembly: (2) for each `GAP_TASKS` id, dispatch a Sonnet `skill-builder` — holding its declared `web_search` grant (D60) — to author one additive-only `SKILL.md`, validate it (`validate-skill.py`: S1–S3 plus the S04 tag-intersection with the triggering task), and persist it to `.claude/skills/` with `origin: generated`, `source_feature: <spec-id>` — checking the live `.claude/skills/` listing and hard-failing/renaming on a name collision (S07); then (3) re-run `assemble.py`, now passing one `--built-skill <id>` per newly-persisted skill, producing the final gap-free roster (stable per S15 — only the gap rows may change; every already-matched row stays byte-identical).
>
> **Neither of those two steps is implemented by this version of the command.** T025 inserts that dispatch → validate → persist → re-run loop **here**, between Step 1 (assembly, above) and Step 3 (gate resolution, below) — nothing above or below this section should need to change shape to accommodate it.
>
> Until T025 lands: a non-empty `GAP_TASKS` from Step 1 is reported as-is (see Completion Report) and left alone. The affected rows already sit in `agents/assignment.md` exactly as `assemble.py` rendered them — a valid base assignment with an empty or partial skill list — never a fabricated skill, never a hand-written roster edit. `tasks.md`'s own dependency notes call this **"US2 … viable without the builder"**: a gap-bearing roster is a legitimate, committable interim state, not a failed run.

## 3. Gate resolution (`gates.workforce.mode`)

Read `$FEATURE_DIR/profile.yaml`. If absent, unparseable, or `gates.workforce.mode` unset: mode is `human` (`profile-schema.md` P1 — a missing/broken profile is always the safest posture, never the fastest one). Otherwise read `gates.workforce.mode` literally.

- **`human`** (default) → do nothing further. `assemble.py` already left every gate field a `[PENDING ...]` marker; it stays that way, pending `/speckit-workforce-approve` (T017).

- **`auto`, and `GAP_TASKS` was empty (Step 1)** → **this command writes the gate decision itself**, standing in for `/speckit-workforce-approve`'s own eventual write (FR-020). Unlike the council gate, workforce's `auto` is valid **standalone** — `profile-schema.md` P4: *"`gates.workforce.mode: auto` alone is valid with `full_auto: false`. The workforce gate is an economic guard … Only the correctness guard [council] is protected."* So this branch is **not** gated on `full_auto` the way `/speckit-council-triage` gates its own auto-write on the council handshake — read `gates.workforce.mode` alone.

  Edit `agents/assignment.md` in place, replacing exactly the five `[PENDING ...]` bracket markers `assignment.template.md` defines (never touch the `### Roster approved` table above them):
  ```markdown
  ## Workforce Gate — <ISO-8601 UTC timestamp>

  | Field | Value |
  |---|---|
  | reviewer | auto |
  | decision | `approved` |
  | reviewed | `categorization.md`, `assignment.md` (this roster) |
  ```
  and:
  ```markdown
  **Notes:** Auto-approved under `gates.workforce.mode: auto` — gap-free roster (zero `built` marks, SC-005).

  **Overrides:** none.
  ```
  (Same section, same position — only the bracket text changes; the heading line, table shape, and everything from `### Roster approved` down stay exactly as `assemble.py` wrote them.)

  **Known gap, not silently glossed over.** `commands.md`'s "Signer-agnostic (FR-010/W4)" clause requires the *same* `after_workforce_approve` gate-write to fire here that `/speckit-workforce-approve` triggers in human mode — binding `tasks.md` + `assignment.md@sha` into `gates.yml`. That hook's handler (`on-gate-approve.sh workforce`) and its registration in `git/extension.yml` are **T018/T019** — not yet built as of this command. An auto-approval written by this step therefore does **not** yet produce a `gates.yml` binding; say so plainly in the Completion Report rather than fabricating one. Once T018/T019 land, this step is where that hook additionally fires.

- **`auto`, but `GAP_TASKS` was non-empty** → **do not auto-approve.** Mirrors `/speckit-council-triage` never auto-approving a residual `blocking` item: an auto-approved roster with unresolved gaps would silently skip the exact mechanism (the skill-builder handoff) the gate is supposed to have reviewed. Leave every gate field `[PENDING ...]`, and note plainly in the Completion Report that the roster is interim (gap rows unresolved, T025 not yet wired) — a human decides how to proceed for now.

## 4. Commit — the `after_agent-assign` hook

Only when Step 1 exited `0` (something was actually written). `workforce/extension.yml` registers `after_agent-assign → speckit.git.commit` (phase `agents`, `optional: false`); v1 has no separate HookExecutor — *"the invoking phase-skill runs the hook and honors its exit code"* (`workforce/extension.yml`'s own hooks-header note) — so this command fires it directly:

```
<git-ext commit.sh path> agents "assemble roster from categorization.md (<T> tasks, <R> row(s)<, gap-free | , <N> gap(s) pending T025>)"
```

Prefer the installed path `.specify/extensions/git/scripts/commit.sh`; fall back to the repo source `extensions/git/extension/scripts/commit.sh` only if git-ext isn't installed in this repo yet — and if neither is found, do not fail the phase over a missing packaging dependency: note in the Completion Report that the roster was written but not committed, and why.

`commit.sh agents <summary>` composes the phase-tagged message `agents(<spec-id>): <summary>` itself (its own FR-006 grammar), self-heals onto the feature branch first, stages `specs/<spec-id>/**` (which already covers `agents/assignment.md`), and no-ops (exit 0, no commit) if nothing in scope actually changed — e.g. a re-run that reproduced a byte-identical roster. It prints only the new commit SHA (or nothing, on no-op) to stdout; it is itself mechanical git with **no model call and no `traces.jsonl` write** (`commit.sh`'s own header).

## Observability — no trace, for now

`commands.md`'s Trace row for `/speckit-agent-assign` reads "one `agent-creator` record per skill-builder session (none on a gap-free run — R2/★★)". As implemented by this command (pre-T025), there is no skill-builder dispatch **at all**, gap or no gap — so this run appends **zero** `traces.jsonl` records, every time. `assemble.py` is zero-AI (no trace — `commands.md`'s own header rule), and the gate-resolution/commit steps above are mechanical (no session, the same no-session pattern the council gate follows). Once T025 wires the skill-builder into `## 2. Gap handoff`, a *gap* run begins appending one `agent-creator` fragment per builder dispatch — a gap-free run still appends none, exactly as `commands.md` describes today.

## Completion Report

Report, concisely:
- Feature/spec-id.
- S14 freshness: the confirmed SHA, or the STOP reason if it stopped there.
- `assemble.py` outcome: exit code; on `0`, task/row counts, `GAP_TASKS` (or "gap-free"), empty-lane ids (if any), dropped-skill count (if any), `LIBRARY_SNAPSHOT_HASH`; on non-zero, the stderr line and which exit path.
- Gap handoff: gap-free, or the gap id list with an explicit "not yet resolved — T025" note.
- Gate outcome: pending (`human`) | auto-approved this run (`auto`, gap-free — flagging the missing `gates.yml` binding until T018/T019) | held pending despite `auto` (gaps unresolved).
- Commit: the SHA `commit.sh` returned, "no-op", or "not committed — git-ext not installed".
- An explicit line: zero `traces.jsonl` records written this run.
- Next step, stated explicitly (`/speckit-workforce-approve`, or "re-run once T025 resolves the gaps", or "re-run /speckit-categorize" if it stopped at S14).

## Done When

- [ ] Feature resolved; `categorization.md` precondition checked (stopped cleanly if absent)
- [ ] Signed-gate guard checked — never silently overwrote an `approved`/`approved-with-notes` decision
- [ ] S14 freshness verified (recorded SHA vs. current `tasks.md` SHA, plus a dirty-tree check) — hard-warned and stopped before running `assemble.py` on any drift
- [ ] `assemble.py` invoked with no `--built-skill` (this version's scope); its exit code handled per its own 0/2/3/4 contract; `agents/assignment.md` left untouched on any non-zero exit
- [ ] On success: `GAP_TASKS`, empty-lane, dropped-skill, and `LIBRARY_SNAPSHOT_HASH` stdout lines parsed and reported; the `### Roster approved` table never hand-edited
- [ ] `## 2. Gap handoff` left as a clearly-marked, structurally clean placeholder for T025 — no fabricated skill-builder dispatch
- [ ] Gate mode resolved (`profile.yaml` → `human` default); `human` left pending; `auto` + gap-free wrote the decision in place (P4, not gated on `full_auto`); `auto` + gaps held pending
- [ ] `after_agent-assign` hook fired via `commit.sh agents …` on any successful write; skipped gracefully (and reported) if git-ext isn't installed
- [ ] Zero `traces.jsonl` records written, and the Completion Report says so explicitly
- [ ] Completion Report delivered with a concrete next step
