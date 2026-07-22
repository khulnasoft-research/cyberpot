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

    def test_sensor_preset_writes_compose_file(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            output = Path(tmpdir) / "docker-compose.yml"
            result = self.run_script("--preset", "sensor", "--output", str(output))

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue(output.exists())
            self.assertIn("CyberPot: SENSOR", output.read_text(encoding="utf-8"))

    def test_missing_preset_file_fails(self):
        preset_name = "standard"
        preset_file = REPO_ROOT / "compose" / f"{preset_name}.yml"
        backup_file = REPO_ROOT / "compose" / f"{preset_name}.yml.bak"

        if not preset_file.exists():
            self.skipTest(f"Preset file for {preset_name!r} not found at {preset_file}")

        preset_file.rename(backup_file)
        try:
            with tempfile.TemporaryDirectory() as tmpdir:
                output = Path(tmpdir) / "docker-compose.yml"
                result = self.run_script("--preset", preset_name, "--output", str(output))

                self.assertEqual(result.returncode, 1)
                self.assertIn("Missing preset file", result.stderr)
                self.assertFalse(output.exists())
        finally:
            backup_file.rename(preset_file)


if __name__ == "__main__":
    unittest.main()
