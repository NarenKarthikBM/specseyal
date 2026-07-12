# speckit-ext-workforce

The M3 **workforce pair** as **one** pipeline extension — the packaging echo of the one-feature ruling (round-1 council S10). It exposes **three** commands and ships a **seed library** (curated base specialists + composable skill modules):

| Command | Role | Writes |
|---|---|---|
| `/speckit-categorize` | Sonnet `categorizer` + a code validator | `categorization.md` (taxonomy v1; `general` cap `max(1, ⌊0.2n⌋)` enforced in code) |
| `/speckit-agent-assign` | deterministic `assemble.py` + (on a ∅-match) a Sonnet `skill-builder` | `agents/assignment.md` — the roster + `## Workforce Gate` |
| `/speckit-workforce-approve` | mechanical gate signature (mirrors `/speckit-council-approve`) | the `## Workforce Gate` decision fields; fires `after_workforce_approve` |

## The split that makes it work

**Categorization = inference (Sonnet) · assembly = code · skill-building = inference (Sonnet).** That split is what lets one artifact (`categorization.md`, a non-reproducible LLM product) feed a **byte-reproducible** roster: `assemble.py` implements `agent-library-schema.md` §3 verbatim, total-orders every set before serialization, writes the roster table itself, and stamps a library-snapshot hash — so a gap-free run is reproducible *by mechanism*, not by prose (SC-005).

## Layout

```
extensions/workforce/
├── install.sh · uninstall.sh          # copy source → .specify/extensions/workforce/ + .claude/skills/; seed the library additively (outside the rm -rf payload)
├── extension/
│   ├── extension.yml                   # registers 3 commands + after_categorize/after_agent-assign fire-points (after_workforce_approve is emitted by workforce-approve but registered+handled in git-ext's own extension.yml, S02)
│   ├── workforce-config.yml            # general_cap · assembly_cap · model · seed manifest · skill_builder.web_search
│   ├── commands/                       # speckit.categorize · speckit.agent-assign · speckit.workforce-approve
│   ├── scripts/                        # frontmatter.py (shared) · assemble.py · validate-categorization.py · validate-skill.py
│   └── templates/                      # categorizer-prompt · skill-builder-prompt · assignment.template · skill-module.template
├── seed/agents/agt_*.md                # 7 curated base specialists (all model: sonnet)
├── seed/skills/*/SKILL.md              # 5 seed skill modules (all grants: [])
├── skills/                             # the Claude Code skill wrappers for the 3 commands
└── test/run.sh                         # install → reinstall-survival → deterministic-assembly golden → validators → per-SC tests
```

## Install

```bash
bash extensions/git/install.sh .        # git BEFORE workforce (the gate-write handler + verify-gate must exist first)
bash extensions/workforce/install.sh .
```

Built by feature `003-workforce` (dogfood). See `specs/003-workforce/` for the spec, plan, council record, and tasks.

License: MIT.
