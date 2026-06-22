# Troubleshooting

## `install.sh` says "No .specify/ in target"

The target repo hasn't been initialized with spec-kit. Install the
[`specify` CLI](https://github.com/github/spec-kit) and run `specify init` in that repo first, then
re-run `./install.sh`.

## Installer printed a "Merge this into .specify/extensions.yml by hand" block

It couldn't find a Python with **PyYAML** and there was no `uv` to borrow one. Everything else
installed fine — only the hook registration was skipped. Fix it either way:

- Paste the printed block into `.specify/extensions.yml` (merge under the existing `installed:`,
  `settings:`, and `hooks:` keys — don't create duplicate top-level keys), **or**
- Make PyYAML reachable and re-run `./install.sh`:
  ```bash
  pip install pyyaml        # or: uv tool install ... ; or rely on uv being on PATH
  ```

The installer searches graphify's interpreter, spec-kit's interpreter, system `python3`, then
`uv run --with pyyaml` — so installing `uv` alone is usually enough.

## A graph-aware command says the graph is missing

`speckit-graphify-context` (and the commands that call it) require `graphify-out/graph.json`. Build it:

```text
/graphify
```

For cross-repo features, also build at the stack root and set `graph.merged` in
`.specify/extensions/graphify/graphify-config.yml`.

## `graphify: command not found`

Install the graph builder:

```bash
pip install graphifyy
```

You also need the **`/graphify` skill** in Claude Code to build the graph with rich extraction; the
companion skills query the `graphify` CLI directly.

## The context looks stale after a big refactor

`graphify-context.md` is a snapshot. Regenerate the graph and the context:

```text
/graphify --update
/speckit-graphify-context
```

## I re-ran `specify init` — did I lose the integration?

No. The extension lives in `.specify/extensions/graphify/` and the skills in `.claude/skills/` —
spec-kit doesn't own those, so a re-init leaves them intact. If a re-init reset `extensions.yml`
itself, just re-run `./install.sh` to re-register the hooks (it's idempotent).

## Comments disappeared from `extensions.yml`

The YAML merge uses PyYAML, which doesn't preserve comments. `extensions.yml` is a machine-managed
file, so this is expected and harmless — all data (yours and ours) is preserved.

## Removing everything

```bash
./uninstall.sh /path/to/your/project
```

Removes the extension, the three skills, and the graphify hook entries; leaves stock spec-kit untouched.
