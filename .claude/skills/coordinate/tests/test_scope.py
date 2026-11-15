"""Exercise the scope reader from outside the checkout, like a fresh session."""

import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(".claude/skills/coordinate/scripts/scope.py")
ROOT = Path(__file__).resolve().parents[4]


class ScopeReaderTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.workdir = Path(temp.name)
        self.root = self.workdir / "checkout"
        self.script = self.root / SCRIPT
        self.script.parent.mkdir(parents=True)
        shutil.copyfile(ROOT / SCRIPT, self.script)
        self.scope = self.root / "docs/scope"
        self.scope.mkdir(parents=True)
        (self.scope / "index.md").write_text(
            "| 04 | [Salam Rust](04-salam.md) | Awal | in-progress |\n"
            "| 01 | [Kontrak Rust](01-kontrak.md) | Awal | planned |\n",
            encoding="utf-8",
        )
        (self.scope / "04-salam.md").write_text(
            "# 4. Salam Rust · in-progress\n"
            "* [x] Desain\n* [ ] Build\n    - [ ] Milestone\n"
            "```md\n- [ ] Contoh sintaks\n```\n",
            encoding="utf-8",
        )
        (self.scope / "01-kontrak.md").write_text(
            "# 1. Kontrak Rust · planned · needs a decision\n- [ ] Desain\n",
            encoding="utf-8",
        )

    def invoke(self, *args):
        return subprocess.run(
            [sys.executable, str(self.script), *args], cwd=self.workdir,
            capture_output=True, text=True,
        )

    def test_inventory_uses_index_order_and_counts_only_open_tasks(self):
        result = self.invoke()
        self.assertEqual(result.returncode, 0, result.stderr)
        first, second, total = result.stdout.splitlines()
        self.assertIn("04\tSalam Rust\tin-progress\t2 terbuka", first)
        self.assertIn("01\tKontrak Rust\tplanned\t1 terbuka", second)
        self.assertIn("2 fitur, 3 langkah terbuka", total)

    def test_selectors_resolve_to_the_same_repo_relative_path(self):
        path = "docs/scope/04-salam.md"
        selectors = ["04", "F04", "fitur 4", "Scope 04 · Salam Rust",
                     "salam rust", "04-salam.md", path, str(self.root / path)]
        for selector in selectors:
            with self.subTest(selector=selector):
                result = self.invoke(selector)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout.strip(), path)

    def test_rejects_ambiguous_missing_and_mismatched_selectors(self):
        for selector in ["rust", "F99", "04 · Kontrak Rust", "docs/scope/index.md"]:
            with self.subTest(selector=selector):
                result = self.invoke(selector)
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse(result.stdout)
                self.assertIn(selector, result.stderr)

    def test_reports_status_drift(self):
        page = self.scope / "04-salam.md"
        page.write_text("# 4. Salam Rust · done\n", encoding="utf-8")
        result = self.invoke("F04")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(page.name, result.stderr)


if __name__ == "__main__":
    unittest.main()
