---
name: extension-tree-scaffold
description: Scaffolding a new pipeline extension's directory tree and top-level README in this
  monorepo's `extensions/<name>/` layout. Injected when a task's tags include extension, scaffold,
  monorepo, tree, or readme. Adds monorepo-consistency and documentation-completeness checks on top
  of general scaffold work.

specseyal:
  schema_version: "1.0"
  kind: skill
  id: skl_extension_tree_scaffold
  version: 1.0.0
  origin: generated

  taxonomy:
    tags: [extension, scaffold, monorepo, tree, readme, layout-convention, pipeline-extension]

  grants: []

  provenance:
    created: 2026-07-15
    created_by: skill-builder
    source_feature: 006-deck-render
    promoted_at: null
    stale_risk: false

  stats:
    assignments: 0
    success_rate: null
    last_used: null

  central:
    synced: false
    remote_id: null
    body_sha256: 57196d4f65cb605b909c320e4648790068e709e3839a17651afc65fa6b6886fd
---

This task scaffolds a new extension's directory tree and/or its top-level README in this repo's
`extensions/` monorepo layout. In addition to your base instructions:

1. **Survey every existing sibling before creating anything.** List every `extensions/*/README.md`
   and `extensions/*/extension/extension.yml` already on disk and match your new tree's shape to the
   convention they establish (top-level `install.sh` / `uninstall.sh` / `README.md`; an
   `extension/{commands,scripts}` pair; one `skills/<skill-name>/SKILL.md` directory per skill the
   extension provides; a `test/` directory with its own fixtures). Do not invent a new shape when a
   sibling extension already establishes one for the same purpose.
2. **Every directory the task's own file list names must exist and be git-trackable** before you
   report the scaffold done — an empty directory `mkdir` created is invisible to git, so give it a
   placeholder or its first real file rather than leaving it silently absent from the tracked tree.
3. **The README you author must state, without requiring the reader to open another file:** what
   command(s) and/or skill(s) the extension installs, whether it declares any hooks — and if it
   declares zero, say so explicitly rather than leaving hook-having ambiguous — and the exact install
   command a person would run.
4. **Name the specific requirement, not just a paraphrase of it.** If the task's own instructions
   point at a named requirement or behavioral seam the README must describe (a zero-hook seam, an
   optional or lazily-imported dependency, a closed enum's single source of truth), the README text
   must name that requirement or the exact constrained behavior concretely enough that a reviewer
   checking the README against the requirement can confirm it is covered — not gesture at it in
   generic prose.
5. **Place every new file exactly where the task's own path list says.** Never relocate a script,
   command, or skill file to a sibling extension's path pattern by copy-paste convenience when the
   task specifies a different location.
6. **Verify the tree before declaring the scaffold complete.** Run a directory listing of what you
   created and diff it against the task's stated directory list — an incomplete tree reported as done
   is a worse outcome than a slower, verified one.
