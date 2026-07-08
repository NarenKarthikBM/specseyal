# M0 Kickoff — Claude Code Handoff Package

> The bridge between this brainstorm and the first Claude Code session. Complete Part 1 by hand, then paste Part 2 into Claude Code.

---

## Part 1 — Pre-flight checklist (human, ~15 minutes)

**1. Repo.** The name is decided (D30): **SpecSeyal**. Create the GitHub repo `specseyal`, **private**, with the MIT license file from creation (D27). **Visibility (D29): private until checkpoint α** — flip to public when the full CLI pipeline demonstrably runs (end of M4). Graphify migration is confirmed (D26); the old repo gets archived at α, not before.

**2. Billing hygiene (D28).** On the build machine:
- `echo $ANTHROPIC_API_KEY` → must be empty. If set, remove it from shell startup files.
- In Claude Code, run `/status` → confirm subscription auth, not API.
- Claim the Agent SDK monthly credit in your Claude plan settings. Not needed until M6, but claim once and forget.

**3. Seed the repo.** Clone it, then:
- Drop `CLAUDE.md` at the root (already stamped with SpecSeyal).
- Create `docs/` and copy in the four docs (00, 05, 10, 90) — the founding record.
- Create empty `extensions/`, `platform/`, `specs/` directories.
- Commit: `chore: founding docs and scaffolding seed`.

**4. Graphify migration source.** Have the `speckit-graphifyy` repo URL handy — the M0 session migrates it in (D26 default). Don't archive the old repo until migration is verified.

---

## Part 2 — The M0 kickoff prompt (paste verbatim into Claude Code, in the new repo)

```
Read CLAUDE.md, then docs/00-VISION-AND-ARCHITECTURE.md and docs/05-IMPLEMENTATION-PLAN.md
in full. We are executing Milestone 0 (Contracts & scaffolding) exactly as specified in
docs/05. Work in this order:

1. MIGRATION: Clone https://github.com/NarenKarthikBM/speckit-graphifyy and migrate the
   graphify extension into extensions/graphify/, preserving its commands, templates, and
   git history if practical (subtree/filter-repo), plain copy if not. Verify the extension
   still installs and runs. Do not modify its behavior in M0.

2. CONTRACTS: Author the six M0 deliverables under docs/contracts/, one file each:
   a. artifact-layout.md — the specs/NNN-feature/ directory convention, including the
      council/ subtree from docs/10 §3
   b. decision-record.md — format spec, per docs/10 (append-per-round, rejection
      requires logged reasoning)
   c. profile-schema.md + a profile.yaml example — gates council|workforce, each
      human|auto, full-auto explicit (D8/D9)
   d. agent-library-schema.md — entry format: stable id, version, taxonomy keys, model,
      prompt (D17 — central-sync-ready)
   e. trace-schema.md — session id, role, model, tokens, duration (D19-ready)
   f. taxonomy-v0.md — fixed core enums (type × specialization, D16) as a DRAFT for my
      review; propose 6-10 types and 8-12 specializations grounded in what graphify's
      task model actually produces
3. SAMPLE: Commit one sample feature folder under specs/000-sample/ exercising every
   contract (empty-but-valid artifacts).
4. LOG: Append D-rows to docs/90 for any decision you had to make, and add a session-log
   entry for this M0 session.
5. Stop and present the taxonomy draft and any decisions you made for my review. Do NOT
   begin Milestone 1.

Constraints: no ANTHROPIC_API_KEY anywhere; no council implementation; no platform code;
main thread model policy per CLAUDE.md.
```

---

## Part 3 — M0 exit criteria (from docs/05)

- [x] graphify migrated and verified working in `extensions/graphify/` — `git subtree`, history preserved (D31)
- [x] Six contract docs exist and are internally consistent with docs/00 and docs/10
- [x] `specs/000-sample/` committed and valid against the contracts — 240 checks, all passing
- [ ] **Taxonomy v0 reviewed and blessed by Babu** — the one open item. `docs/contracts/taxonomy-v0.md` §7 has 6 questions.
- [x] docs/90 updated (decisions D31–D39 + I-11 + session log)
- [x] Old repo archival **scheduled for checkpoint α** (when the new repo goes public) — archiving during the private phase would remove graphify's only public home

**M0 done → M1 begins, and from there the pipeline builds itself.**

> **Status 2026-07-09:** five of six criteria met. M1 is blocked on the taxonomy blessing, because
> `agent-library-schema.md` §6.5 treats the taxonomy as a closed enum. M1 itself does not consume it —
> M3 does — so a conditional start is possible if Babu prefers. That is his call, not the session's.
