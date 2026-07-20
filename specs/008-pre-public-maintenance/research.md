# Phase 0 Research — 008 Pre-Public Maintenance

Two genuine design unknowns the spec deferred to planning (both council-defensible). The four latent-defect hardenings carry **no open unknowns** — their sites and fixes are graph-confirmed (`graphify-context.md`) and their acceptance is fully pinned by the spec; they are summarized at the end for completeness, not researched.

---

## R1 — I-32 clone-free install: fetch transport & security posture

**Question**: How does a single documented command acquire and install an extension into a target repo **without a prior manual clone** (FR-001/FR-002), while staying **additive** to the existing local `install.sh` (FR-003/D45) and not devolving into an opaque `curl | bash` (Edge: "safe fetch mechanism … is a planning/council concern")?

**Decision**: A **new root-level `bootstrap.sh` that fetches only `extensions/<name>/` from a pinned repo ref into a temp dir, then delegates to that extension's own existing `install.sh <target>`.** The bootstrap is a small, **reviewable script** obtained over HTTPS (not piped blind into a shell as the only path); the documented quickstart shows the two-step reviewable form (`curl -fsSLO <raw-url>/bootstrap.sh && sh bootstrap.sh <ext> <target>`), with the pipe form mentioned only as a convenience, never as the sole instruction. Fetch mechanism: a shallow, blobless, sparse `git clone` of just the extension subtree (`git clone --depth 1 --filter=blob:none --sparse <repo> && git sparse-checkout set extensions/<name>`) against a **pinned ref** (tag/commit), with a fallback to a `codeload` tarball of the pinned ref when `git` sparse-checkout is unavailable. `bootstrap.sh` acquires; the extension's `install.sh` installs — the acquisition/installation split the spec names (I-32).

**Rationale**:
- **Maximally additive (FR-003/D45)** — it *wraps* the existing per-extension `install.sh`, so the offline/in-checkout local `cp -R` route is untouched and the single installer logic is not forked. One installer, two front doors.
- **Closes exactly the I-32 gap** — the "obtain-the-files-first" step `007`'s quickstart silently omitted becomes the documented `bootstrap.sh` step (FR-002/SC-002).
- **Idempotent for free (FR-003/SC-003)** — idempotency is delegated to the already-idempotent `install.sh`; `bootstrap.sh` adds only a temp-dir fetch (cleaned up on exit), which re-runs safely.
- **Reviewable, pinned posture** — a named, downloadable script + pinned ref answers the Edge's security concern without over-scoping into checksum-signing infrastructure the pre-public repo doesn't yet have. The transport is the thing the council defends.
- **Zero new dependencies** — `git` (already required to use the repo) + POSIX `sh`; the tarball fallback uses `curl`/`tar` only.

**Alternatives considered**:
- **`curl | bash` one-liner (opaque pipe-to-shell)** — rejected as the *primary/only* path: it is the exact blind-pipe posture the Edge flags. Kept only as an optional convenience line, never the documented default.
- **Full GitHub-release tarball + checksum/signature pinning** — rejected for *now*: strongest supply-chain posture but needs release-artifact + checksum-publishing infrastructure the pre-public repo lacks; over-scopes a maintenance sweep. The pinned-ref design leaves room to add checksums later without changing the command shape.
- **Fork/duplicate the install logic into `bootstrap.sh`** — rejected: violates additivity/DRY, creates a second installer to keep in sync (the very divergence class I-23 is fixing elsewhere).
- **A network-fetch path that *replaces* the local `install.sh`** — rejected: FR-003/D45 require the local route to survive unchanged for the offline adopter (Edge: offline/no-network adopter).

**Open for council**: the exact reviewable-vs-convenience wording of the documented command and whether to pin to a tag vs a commit at the visibility flip.

---

## R2 — I-11 conformance checker: composition, ownership & coverage scope

**Question**: How does the checker validate a `specs/NNN-feature/` dir against `docs/contracts/` **without duplicating** the three existing per-artifact validators (FR-008), where does it live, and does it validate historical features or only new ones (Edge: carve-outs; historical scope)?

**Decision**: A **new pure-stdlib `check-conformance.py`** in `extensions/workforce/extension/scripts/` (beside the validators it composes) that takes a feature dir and:
1. **Delegates** to the three existing validators for their artifacts — shells out to the installed `validate-profile.py` (profile.yaml), `validate-categorization.py` (categorization.md), `validate-skill.py` (any generated skill) — surfacing their verdicts, never re-checking their rules (FR-008, composition-not-duplication).
2. **Covers the remaining contracts directly** — `artifact-layout.md` (required-file presence + layout paths), `decision-record.md`, `completion-report.md`, `testing-doc.md`, `trace-schema.md` (each `traces.jsonl` line), `agent-library-schema.md` (`agents/assignment.md`) — frontmatter/required-section/record-format checks read *from the contracts' own stated rules*, **not** from the M0 council fixture (FR-005, a rewrite of the deferred `R1-S04`, not its revival).
3. **Honors documented carve-outs** — a feature that invokes a D50 meta-feature rule-5 carve-out is validated *with* the carve-out (e.g. a documented missing/absent artifact), not flagged as drift (FR-006, Edge).
4. Emits a **deterministic** verdict to stdout naming each nonconformance by artifact + rule, exits non-zero on any failure, runs as **one CI-invocable command with no third-party deps** (FR-007/SC-005), and embeds a `_self_test()` (the `validate-profile.py` shape).

**Scope**: the checker validates **whatever feature dir it is pointed at** (arg-driven), and **MUST pass `specs/000-sample`** (FR-006/SC-004) — the pinned CI target that finally makes artifact-layout §7 real. It is *capable* of validating historical features but is **not required to pass all of them** (several predate contracts or carry carve-outs); CI pins `specs/000-sample` as the golden, and the both-branch fixture set (below) is the correctness proof.

**Ownership rationale**: hosting it in **workforce** places it beside the three validators it delegates to, and the delegation is a **runtime shell-out to their installed copies** — reading their *verdicts* (data), not importing their *source* — which the D57 cross-extension-seam rule already sanctions (the same rule that lets graphify's `implement-parallel` read workforce's `assignment.md` artifact without depending on workforce source). The contracts it enforces are repo-level `docs/contracts/` **data**, read at runtime, not owned by any extension.

**Alternatives considered**:
- **A repo-level `tools/` or `scripts/` home** — rejected: the repo has no such directory and the layout convention is `extensions/*/`; creating a new top-level home for one script over-scopes. Noted as the fallback if the council prefers strict extension-ownership purity over co-location.
- **Reviving the M0 fixture-coupled verifier (`R1-S04`)** — explicitly rejected by FR-005: the checker is derived from the contracts, not the throwaway fixture.
- **Re-implementing profile/categorization/skill checks inside it** — rejected by FR-008: duplication invites the manifest-vs-block divergence class I-23 fights; delegation keeps one source of truth per artifact.
- **A hard requirement to pass every historical feature dir** — rejected: pre-contract features and carve-out features would force either false failures or per-feature exceptions; pinning `specs/000-sample` + a both-branch fixture set is the deterministic, maintainable correctness bar.

**Both-branch fixtures (FR-009/SC-004)**: under `specs/008-pre-public-maintenance/fixtures/` — one conformant feature dir (passes) and one injected-violation dir per contract class (missing required section, malformed frontmatter, wrong layout path, malformed trace line), each expected to FAIL naming its cause. Committed, deterministic, run from `extensions/workforce/test/run.sh`.

**Open for council**: the precise set of remaining contracts checked directly vs delegated, and the workforce-home-vs-repo-`tools/` ownership call.

---

## Hardening items (no open unknowns — graph-confirmed, spec-pinned)

- **I-23 (git-ext manual fallback)** — `print_manual_block()` in `extensions/git/install.sh` (L159–188) lists commit hooks only through `after_implement`; it **omits** the `after_complete`/`after_testing` commit seams that `extension.yml` registers (L76/L81). Fix: add both rows; **generalize** the existing per-hook grep in `extensions/git/test/run.sh` (L164 greps one hook) into a guard that asserts *every* `extension.yml` hook appears in the manual block (FR-011 — fails on any future divergence, not just the two known-missing ones).
- **I-26 (augment inline-comment strip)** — `parse_hook_commands()` (`augment_merge.py` L120) captures `(.+?)\s*$`, so a `command: … # comment` line carries the ` # comment` into the minted node id (the exact shape lives at `extension.yml` L87/L92). Fix: strip a whitespace-preceded trailing `#…` before `dequote()`; fixture exercises `#x`, `  #  x`, tab-separated variants (SC-007/Edge).
- **I-29 (council apparatus provenance)** — council-triage writes provenance in `decision-record.md` §5 Metadata ("Deck reviewed"/"Plan reviewed" @ sha); `speckit-council` writes `suggestions.md` provenance. Fix: add a third line recording `git rev-parse HEAD -- extensions/council/`, and **note a dirty `extensions/council/` working tree** when present (Edge) so the sha's completeness is honest.
- **I-31 (implement-parallel trace guard)** — `speckit-implement-parallel/SKILL.md` populates the trace `artifact` "the ordinary way." Fix: add the rule that a task whose sole output is gitignored/untracked writes `artifact: null` (probe tracked-state via `git`), generalizing `006`'s SC-005 as a root-cause guard (FR-014/SC-009).

All four are additive, gate-semantics-neutral (FR-015), and each lands with a both-branch fixture per the repo's golden-fixture discipline.
