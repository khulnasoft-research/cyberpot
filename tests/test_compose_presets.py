import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch


REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPT_PATH = REPO_ROOT / "scripts" / "select_compose_preset.py"


class ComposePresetTests(unittest.TestCase):
    def run_script(self, *args):
        return subprocess.run(
            [sys.executable, str(SCRIPT_PATH), *args],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
        )

    def run_script_with_preset_override(self, presets_dict, *args):
        import json
        presets_json = json.dumps({k: str(v) for k, v in presets_dict.items()})
        code = f"""
import sys, json
from pathlib import Path
sys.path.insert(0, {str(REPO_ROOT / 'scripts')!r})
import select_compose_preset
select_compose_preset.PRESETS = {{k: Path(v) for k, v in json.loads({presets_json!r}).items()}}
sys.argv = ['select_compose_preset.py', *{list(args)!r}]
sys.exit(select_compose_preset.main())
"""
        return subprocess.run(
            [sys.executable, "-c", code],
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
        missing_path = str(REPO_ROOT / "compose" / "nonexistent_standard.yml")
        presets = {"standard": missing_path}

        with tempfile.TemporaryDirectory() as tmpdir:
            output = Path(tmpdir) / "docker-compose.yml"
            result = self.run_script_with_preset_override(
                presets, "--preset", "standard", "--output", str(output)
            )

            self.assertEqual(result.returncode, 1)
            self.assertIn("Missing preset file", result.stderr)
            self.assertFalse(output.exists())


if __name__ == "__main__":
    unittest.main()
