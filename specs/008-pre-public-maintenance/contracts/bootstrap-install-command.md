# Contract — `bootstrap.sh` clone-free install command (US1 · I-32)

The CLI/behavioral contract for the root-level one-command installer. Fixes the **capability**, not a specific transport (spec Edge; transport defended at council).

## Invocation

```sh
# Documented, reviewable two-step form (the quickstart default):
curl -fsSLO <raw-repo-url>/<pinned-ref>/bootstrap.sh
sh bootstrap.sh <extension-name> [<target-repo-dir>] [--ref <pinned-ref>]
```

- `<extension-name>` — required; one of `git | graphify | council | workforce | testing | deck-render`.
- `<target-repo-dir>` — optional; defaults to `.` (current repo).
- `--ref <pinned-ref>` — optional; tag/commit to fetch. Defaults to the release ref documented in the quickstart.

## Behavior contract

| # | Guarantee | Maps to |
|---|-----------|---------|
| B1 | Acquires `extensions/<name>/` from the pinned ref **with no prior manual clone** of `specseyal` by the adopter | FR-001, SC-001 |
| B2 | After acquisition, delegates installation to that extension's **own existing `install.sh <target>`** — does not re-implement install logic | FR-003 (additive), D45 |
| B3 | Extension's skills land in `<target>/.claude/`, hooks register in `<target>/.specify/` (whatever that extension's `install.sh` already does) | Independent Test §US1 |
| B4 | **Idempotent** — a second run leaves the same consistent state, no duplication/breakage | FR-003, SC-003, Acceptance §US1-2 |
| B5 | **Additive** — never removes or alters the local in-checkout `install.sh .` route (still works offline/unchanged) | FR-003, SC-003, Edge (offline adopter) |
| B6 | Fetch mechanism: shallow blobless sparse `git clone` of the subtree at `--ref`, with a `codeload` tarball fallback; temp dir cleaned on exit | Research R1 |
| B7 | No third-party dependency beyond `git` + POSIX `sh` (+ `curl`/`tar` for the tarball fallback) | Assumptions |

## Exit codes

- `0` — extension acquired + installed (or idempotent re-install) successfully.
- non-zero — unknown extension name, fetch failure (bad ref/network), or the delegated `install.sh` failed; message names the cause; temp dir still cleaned.

## Documentation contract (FR-002 / SC-002)

The README quickstart's install path MUST be end-to-end runnable by a true outsider with **no undocumented acquisition step** — the `bootstrap.sh` fetch IS the previously-omitted "obtain the files" step. The reviewable two-step form is the documented default; any `curl | sh` convenience line is secondary, never the sole instruction (Edge: security posture).

## Out of scope (this contract)

- Checksum/signature pinning infrastructure (research R1 alternative — deferred; the `--ref` pin leaves room for it).
- The visibility flip itself (D73 — a separate manual step after 008).
