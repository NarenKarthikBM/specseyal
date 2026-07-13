# arm1-success

Golden fixture for arm 1's **SC-001 success branch** (T005, 005-graphify-context).
`input/repo/` is a small, self-contained repo slice whose topology is deliberately clean
and literal — no comments, no conditionals, no variable indirection — so it exercises all
three modeled `augment.sh` edge kinds unambiguously, each at `EXTRACTED` confidence:
`extension/extension.yml`'s `hooks.before_thing` names the `speckit.widget.hello` command
(`registers_hook`); `install.sh` does a literal `rm -rf` + `cp -R "extension"
".specify/extensions/widget"` (`installs`); and `extension/scripts/entry.sh` sources its
sibling `extension/scripts/helper.sh` via a bare `. ./helper.sh` (`invokes`).
`expected.txt` pins the exact, sorted `--emit` projection `augment.sh` (T008, not yet
implemented) must reproduce byte-for-byte. Until `augment.sh` exists, `cmd.sh` is expected
to fail in `test/run.sh` with an "augment.sh not found" / non-zero-exit reason — that is
the intended TDD red, not a malformed fixture.
