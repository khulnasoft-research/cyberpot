import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]


class ComposePresetTests(unittest.TestCase):
    def run_script(self, *args):
        return subprocess.run(
            [sys.executable, str(REPO_ROOT / "scripts" / "select_compose_preset.py"), *args],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
        )

    def test_standard_preset_writes_compose_file(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            output = Path(tmpdir) / "docker-compose.yml"
            result = self.run_script("--preset", "standard", "--output", str(output))

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue(output.exists())
            self.assertIn("CyberPot: STANDARD", output.read_text(encoding="utf-8"))

    def test_unknown_preset_fails(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            output = Path(tmpdir) / "docker-compose.yml"
            result = self.run_script("--preset", "unknown", "--output", str(output))

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Unsupported preset", result.stderr)


if __name__ == "__main__":
    unittest.main()
