# arm1-messy

Golden fixture for arm 1's **S10 "modeled-but-wrong is a regression" / no-wrong-edge
branch** (T007, 005-graphify-context), sibling to `arm1-success` (T005) and
`arm1-fallback` (T006). `input/repo/` packs three real-`.sh`-shaped constructs that a
naive pattern match would happily (and wrongly) turn into confident edges, plus one
clean control proving the pass doesn't just go quiet once messiness shows up.
`scripts/setup.sh`'s `# . ./old.sh` is a commented-out, INACTIVE source — never
executed, so there is no relationship to label at all, confidently or otherwise: **no
edge**. `install.sh`'s `cp "legacy-gadget.yml" ".specify/extensions/gadget/config.yml"`
sits inside `if [ -f "legacy-gadget.marker" ]`; both operands are literal, real,
already-tracked-or-well-named paths (unlike the third construct below), so the ONLY
thing standing between this and a confident `installs` fact is the runtime condition
this pass cannot evaluate from the repo alone: **`asserted`/`ASSERTED`**, never a
confident EXTRACTED edge, never silently dropped either (FR-004's "never a silent
gap... never dropped"). `scripts/setup.sh`'s `"$PLUGIN_DIR/script.sh"`, where
`PLUGIN_DIR` comes from the unbound `GADGET_PLUGIN_DIR`, has no literal target at all
for the pass to resolve — same FR-004 reasoning as the conditional cp (a real,
invocation-shaped statement, just not a resolvable one): **`asserted`/`ASSERTED`**,
naming the dequoted expression itself (`$PLUGIN_DIR/script.sh`) as the edge's `to`
rather than going silent. Immediately below it, the same file's
`. "$SCRIPT_DIR/helper.sh"` is the clean control: `SCRIPT_DIR` is the standard
self-locating idiom (always this script's own directory, regardless of caller) — a
literal, resolvable target, unlike `PLUGIN_DIR` one line above — so it mints a
confident **`invokes`/`EXTRACTED`** edge to `scripts/helper.sh`, proving the two messy
constructs above it don't make the pass go quiet on the rest of the same file. See
`expected.txt` for the exact tab-separated bytes (4 nodes, 3 edges — no `installs`
edge is asserted as EXTRACTED anywhere in this fixture; a clean, unconditional one is
`arm1-success`'s job, not this one's). Until `augment.sh` (T008, not yet implemented)
exists, `cmd.sh` is expected to fail in `test/run.sh` with an "augment.sh not found" /
non-zero-exit reason — that is the intended TDD red, not a malformed fixture.
