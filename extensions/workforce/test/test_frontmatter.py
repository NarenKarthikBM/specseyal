#!/usr/bin/env python3
"""Independent unit tests for `frontmatter.py` (T005 / S21).

`extension/scripts/frontmatter.py` is the one shared `specseyal:` frontmatter
parser imported by BOTH `assemble.py` and `validate-skill.py`. A silent
divergence in its behavior would poison both consumers identically -- so
unlike most of this feature's glue, it earns real, independent tests rather
than a smoke check.

Covers the module's public surface end to end:

  - `split_frontmatter`  -- fence splitting: valid docs and every malformed
                             shape the function's own docstring calls out.
  - `body_sha256`        -- cross-checked on REAL seed fixtures against both
                             (a) the file's own recorded `central.body_sha256`
                             and (b) an independent shell call to the exact
                             reference command in agent-library-schema.md S2:
                                 sed '1,/^---$/d; 1,/^---$/d' <file> | shasum -a 256
  - `parse_frontmatter`  -- base shape (agent-library-schema.md S1.1) and
                             skill shape (skill-module.md S1), via the real
                             `agt_ai_agents.md` and `orchestration/SKILL.md`
                             seed entries -- not hand-transcribed copies, so a
                             failure here means the parser disagrees with
                             what is actually on disk.
  - `parse_entry`        -- the file-reading composition of the three.
  - Determinism, and the scalar/key edge cases the module's docstrings
    document explicitly (colon-in-value, empty-value-as-None, generic
    unknown keys).

Run directly:  python3 test_frontmatter.py
Or:            python3 -m unittest test_frontmatter -v
"""

from __future__ import annotations

import hashlib
import shlex
import shutil
import subprocess
import sys
import unittest
from pathlib import Path

# ---------------------------------------------------------------------------
# Import the module under test. `scripts/` is added to `sys.path`, computed
# relative to THIS file (not the cwd), so the suite runs the same whether
# invoked as `python3 test_frontmatter.py`, `python3 -m unittest ...`, or
# from a completely different working directory.
# ---------------------------------------------------------------------------

_TEST_DIR = Path(__file__).resolve().parent
_WORKFORCE_DIR = _TEST_DIR.parent
_SCRIPTS_DIR = _WORKFORCE_DIR / "extension" / "scripts"
sys.path.insert(0, str(_SCRIPTS_DIR))

from frontmatter import (  # noqa: E402
    FrontmatterError,
    body_sha256,
    parse_entry,
    parse_frontmatter,
    split_frontmatter,
)

# ---------------------------------------------------------------------------
# Fixtures: real library entries (also computed relative to this file), so
# a test failure means the parser actually disagrees with what ships in the
# repo -- not that a hand-copied fixture string was mistyped.
# ---------------------------------------------------------------------------

BASE_FIXTURE = _WORKFORCE_DIR / "seed" / "agents" / "agt_ai_agents.md"
SKILL_FIXTURE = _WORKFORCE_DIR / "seed" / "skills" / "orchestration" / "SKILL.md"


def _shell_reference_body_sha256(path: Path) -> str:
    """The agent-library-schema.md S2 reference definition, executed for
    real via a subprocess -- independent of `split_frontmatter` AND
    `body_sha256`, so agreement with it is a genuine cross-check rather than
    the module grading its own homework.

        sed '1,/^---$/d; 1,/^---$/d' <file> | shasum -a 256
    """
    cmd = f"sed '1,/^---$/d; 1,/^---$/d' {shlex.quote(str(path))} | shasum -a 256"
    completed = subprocess.run(
        cmd, shell=True, check=True, capture_output=True, text=True
    )
    # shasum prints "<hex>  -" when reading a pipe; the hex digest is the
    # first whitespace-separated field.
    return completed.stdout.split()[0]


# ---------------------------------------------------------------------------
# 1. split_frontmatter
# ---------------------------------------------------------------------------


class SplitFrontmatterTests(unittest.TestCase):
    def test_valid_two_fence_doc_splits_correctly(self):
        content = "---\nname: foo\ndescription: bar\n---\nbody line 1\nbody line 2\n"
        fm, body = split_frontmatter(content)
        self.assertEqual(fm, "name: foo\ndescription: bar\n")
        self.assertEqual(body, "body line 1\nbody line 2\n")

    def test_body_is_verbatim_including_blank_lines_and_trailing_whitespace(self):
        content = "---\nname: foo\n---\n\nline with a  trailing space \n\nlast\n"
        _, body = split_frontmatter(content)
        self.assertEqual(body, "\nline with a  trailing space \n\nlast\n")

    def test_no_fence_at_all_raises(self):
        with self.assertRaises(FrontmatterError):
            split_frontmatter("just a plain markdown file\nwith no frontmatter\n")

    def test_missing_opening_fence_raises(self):
        # Does not start with '---' at all.
        with self.assertRaises(FrontmatterError):
            split_frontmatter("name: foo\n---\n---\nbody\n")

    def test_opening_line_starts_with_dashes_but_is_not_a_lone_fence_raises(self):
        # Starts with '---' as a substring, but the first LINE isn't exactly '---'.
        with self.assertRaises(FrontmatterError):
            split_frontmatter("---not-a-fence\nname: foo\n---\nbody\n")

    def test_only_opening_fence_no_body_raises(self):
        with self.assertRaises(FrontmatterError):
            split_frontmatter("---")

    def test_opening_fence_with_no_closing_fence_raises(self):
        with self.assertRaises(FrontmatterError):
            split_frontmatter("---\nname: foo\ndescription: bar\n")


# ---------------------------------------------------------------------------
# 2. body_sha256 -- the S2 invariant, cross-checked against real files
# ---------------------------------------------------------------------------


class BodySha256Tests(unittest.TestCase):
    def test_matches_hashlib_directly_on_a_synthetic_body(self):
        body = "line one\nline two\n"
        self.assertEqual(
            body_sha256(body), hashlib.sha256(body.encode("utf-8")).hexdigest()
        )

    def test_empty_body(self):
        self.assertEqual(body_sha256(""), hashlib.sha256(b"").hexdigest())

    @unittest.skipUnless(shutil.which("shasum"), "shasum not on PATH")
    def test_matches_recorded_and_shell_reference_for_real_base_fixture(self):
        self._assert_matches_recorded_and_shell_reference(BASE_FIXTURE)

    @unittest.skipUnless(shutil.which("shasum"), "shasum not on PATH")
    def test_matches_recorded_and_shell_reference_for_real_skill_fixture(self):
        self._assert_matches_recorded_and_shell_reference(SKILL_FIXTURE)

    def _assert_matches_recorded_and_shell_reference(self, path: Path) -> None:
        content = path.read_text(encoding="utf-8")
        frontmatter_text, body_text = split_frontmatter(content)
        parsed = parse_frontmatter(frontmatter_text)
        computed = body_sha256(body_text)

        recorded = parsed["specseyal"]["central"]["body_sha256"]
        self.assertEqual(
            computed,
            recorded,
            f"body_sha256({path.name}) != the file's own recorded "
            "specseyal.central.body_sha256 -- body edited without recomputing the hash.",
        )

        reference = _shell_reference_body_sha256(path)
        self.assertEqual(
            computed,
            reference,
            f"body_sha256({path.name}) != independent `sed | shasum -a 256` "
            "reference (agent-library-schema.md S2).",
        )

        # Transitively implied by the two checks above, but spelled out
        # because it is the exact invariant S2 exists to protect.
        self.assertEqual(recorded, reference)


# ---------------------------------------------------------------------------
# 3. parse_frontmatter -- base shape (agent-library-schema.md S1.1)
# ---------------------------------------------------------------------------


class ParseFrontmatterBaseShapeTests(unittest.TestCase):
    """Via the real `agt_ai_agents.md` seed base -- not a hand-copied fixture."""

    @classmethod
    def setUpClass(cls):
        content = BASE_FIXTURE.read_text(encoding="utf-8")
        fm_text, _ = split_frontmatter(content)
        cls.parsed = parse_frontmatter(fm_text)

    def test_top_level_scalars(self):
        self.assertEqual(self.parsed["name"], "ai-agents")
        self.assertEqual(self.parsed["model"], "sonnet")

    def test_core_toolset_parses_with_trailing_comment_stripped(self):
        self.assertEqual(self.parsed["tools"], "Read, Write, Edit, Bash, Glob, Grep")

    def test_taxonomy_type_parses_as_a_list(self):
        taxonomy = self.parsed["specseyal"]["taxonomy"]
        self.assertIsInstance(taxonomy["type"], list)
        self.assertEqual(
            taxonomy["type"], ["scaffold", "service", "endpoint", "test", "docs"]
        )
        self.assertEqual(taxonomy["specialization"], "ai-agents")

    def test_nested_maps_parse_as_dicts(self):
        specseyal = self.parsed["specseyal"]
        self.assertIsInstance(specseyal["provenance"], dict)
        self.assertEqual(
            specseyal["provenance"], {"created": "2026-07-11", "created_by": "human"}
        )
        self.assertIsInstance(specseyal["central"], dict)
        self.assertIsInstance(specseyal["central"]["synced"], bool)
        self.assertFalse(specseyal["central"]["synced"])
        self.assertIsNone(specseyal["central"]["remote_id"])

    def test_kind_and_id(self):
        self.assertEqual(self.parsed["specseyal"]["kind"], "base")
        self.assertEqual(self.parsed["specseyal"]["id"], "agt_ai_agents")


# ---------------------------------------------------------------------------
# 4. parse_frontmatter -- skill shape (skill-module.md S1)
# ---------------------------------------------------------------------------


class ParseFrontmatterSkillShapeTests(unittest.TestCase):
    """Via the real `orchestration/SKILL.md` seed skill."""

    @classmethod
    def setUpClass(cls):
        content = SKILL_FIXTURE.read_text(encoding="utf-8")
        fm_text, _ = split_frontmatter(content)
        cls.parsed = parse_frontmatter(fm_text)

    def test_model_is_detectably_absent(self):
        # validate-skill.py rule 1 (skill-module.md S6) depends on exactly
        # this shape of check: `"model" not in parsed`.
        self.assertNotIn("model", self.parsed)

    def test_taxonomy_tags_parses_as_a_list(self):
        tags = self.parsed["specseyal"]["taxonomy"]["tags"]
        self.assertIsInstance(tags, list)
        self.assertEqual(tags, ["orchestration", "subagent", "dispatch", "parallel"])

    def test_grants_is_an_empty_list_not_none(self):
        grants = self.parsed["specseyal"]["grants"]
        self.assertIsInstance(grants, list)
        self.assertEqual(grants, [])

    def test_stats_and_provenance_blocks_parse_as_dicts(self):
        specseyal = self.parsed["specseyal"]
        self.assertEqual(
            specseyal["stats"],
            {"assignments": 0, "success_rate": None, "last_used": None},
        )
        self.assertEqual(specseyal["provenance"]["created_by"], "human")
        self.assertIsNone(specseyal["provenance"]["source_feature"])

    def test_kind_and_id(self):
        self.assertEqual(self.parsed["specseyal"]["kind"], "skill")
        self.assertEqual(self.parsed["specseyal"]["id"], "skl_orchestration")


# ---------------------------------------------------------------------------
# 5. Determinism
# ---------------------------------------------------------------------------


class DeterminismTests(unittest.TestCase):
    def test_parsing_same_synthetic_input_twice_yields_equal_dicts(self):
        fm_text = (
            "name: skl-example\n"
            "description: A skill.\n"
            "\n"
            "specseyal:\n"
            "  kind: skill\n"
            "  taxonomy:\n"
            "    tags: [a, b, c]\n"
            "  grants: []\n"
        )
        first = parse_frontmatter(fm_text)
        second = parse_frontmatter(fm_text)
        self.assertEqual(first, second)
        self.assertIsNot(first, second)  # equal by value, not the same object

    def test_real_fixtures_parse_deterministically(self):
        for path in (BASE_FIXTURE, SKILL_FIXTURE):
            with self.subTest(path=path.name):
                fm_text, _ = split_frontmatter(path.read_text(encoding="utf-8"))
                self.assertEqual(parse_frontmatter(fm_text), parse_frontmatter(fm_text))


# ---------------------------------------------------------------------------
# 6. Scalar / key edge cases the module's own docstrings document
# ---------------------------------------------------------------------------


class ScalarAndKeyEdgeCaseTests(unittest.TestCase):
    def test_value_containing_a_colon_splits_at_the_keys_own_colon_space(self):
        # _split_key_value splits on the first ': ' (colon-space), not the
        # first bare colon -- so a value with its own colon still parses whole.
        fm_text = "name: foo\ndescription: Handles X: Y\n"
        parsed = parse_frontmatter(fm_text)
        self.assertEqual(parsed["description"], "Handles X: Y")

    def test_empty_value_parses_as_none(self):
        # A `key:` with nothing after it, and nothing more-indented following,
        # is a bare null -- not a nested block.
        fm_text = "name: foo\nremote_id:\nsynced: false\n"
        parsed = parse_frontmatter(fm_text)
        self.assertIsNone(parsed["remote_id"])
        self.assertFalse(parsed["synced"])

    def test_null_and_tilde_spellings_also_parse_as_none(self):
        fm_text = "a: ~\nb: null\nc: NULL\n"
        parsed = parse_frontmatter(fm_text)
        self.assertIsNone(parsed["a"])
        self.assertIsNone(parsed["b"])
        self.assertIsNone(parsed["c"])

    def test_unknown_key_parses_generically(self):
        # No hardcoded key allowlist: any 'key: value' or dotted key parses.
        fm_text = "some_random_key: some_value\nanother.dotted.key: 42\n"
        parsed = parse_frontmatter(fm_text)
        self.assertEqual(parsed["some_random_key"], "some_value")
        self.assertEqual(parsed["another.dotted.key"], 42)


# ---------------------------------------------------------------------------
# 7. parse_entry -- the file-reading composition of the three primitives
# ---------------------------------------------------------------------------


class ParseEntryTests(unittest.TestCase):
    def test_parse_entry_on_real_base_fixture(self):
        entry = parse_entry(BASE_FIXTURE)
        self.assertEqual(set(entry), {"frontmatter", "body", "body_sha256"})
        self.assertEqual(entry["frontmatter"]["specseyal"]["kind"], "base")
        self.assertEqual(
            entry["body_sha256"],
            entry["frontmatter"]["specseyal"]["central"]["body_sha256"],
        )

    def test_parse_entry_on_real_skill_fixture(self):
        entry = parse_entry(SKILL_FIXTURE)
        self.assertEqual(entry["frontmatter"]["specseyal"]["kind"], "skill")
        self.assertNotIn("model", entry["frontmatter"])
        self.assertEqual(
            entry["body_sha256"],
            entry["frontmatter"]["specseyal"]["central"]["body_sha256"],
        )

    def test_parse_entry_accepts_a_str_path_too(self):
        entry = parse_entry(str(BASE_FIXTURE))
        self.assertEqual(entry["frontmatter"]["name"], "ai-agents")


# ---------------------------------------------------------------------------
# 8. FrontmatterError shape
# ---------------------------------------------------------------------------


class FrontmatterErrorTests(unittest.TestCase):
    def test_is_a_value_error_subclass(self):
        self.assertTrue(issubclass(FrontmatterError, ValueError))


if __name__ == "__main__":
    unittest.main(verbosity=2)
