<!-- Skeleton placeholder (T001). Finalized by T004. -->
# speckit-ext-git — Per-Feature Git Lifecycle

A Spec Kit pipeline extension that automates the per-feature git lifecycle M0/M1 ran by
hand: **branch birth** (named from the spec ID), **phase-tagged commits** at every phase
boundary, **gate↔SHA binding** with stale-approval hard-blocking, and **completion cleanup**
that preserves the phase trail. **Mechanical git only — zero AI** (no model calls, no
`traces.jsonl` records). Per D25.

Packaged like `extensions/graphify/` (a hook-registering installer): payload under
`.specify/extensions/git/`, hooks merged into `.specify/extensions.yml`, the one human
command (`/speckit-git-cleanup`) installed to `.claude/skills/`.

## Layout

```
extensions/git/
├── install.sh / uninstall.sh          # idempotent; merges/deregisters hooks in extensions.yml
├── extension/
│   ├── extension.yml                   # id: git — declares hooks + primitives
│   ├── git-config.yml                  # base branch, merge policy, tag anchor, grammar
│   ├── commands/                        # provenance stubs (dots→hyphens on install)
│   └── scripts/                         # branch / commit / sha / gates / verify-gate / cleanup (POSIX sh)
├── skills/speckit-git-cleanup/          # the one human command
└── test/run.sh                          # unit + reinstall-survival regression
```

*Full install/uninstall/usage documentation: T004.*
