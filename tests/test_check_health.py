import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]


class CheckHealthTests(unittest.TestCase):
    def test_check_health_reports_services(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            output_path = Path(tmpdir) / "docker-compose.yml"
            output_path.write_text((REPO_ROOT / "docker-compose.yml").read_text(encoding="utf-8"), encoding="utf-8")

            result = subprocess.run(
                [sys.executable, str(REPO_ROOT / "scripts" / "check_health.py"), "--compose-file", str(output_path)],
                cwd=REPO_ROOT,
                capture_output=True,
                text=True,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("Compose file is valid", result.stdout)

    def test_make_health_uses_default_compose_file(self):
        result = subprocess.run(
            ["make", "health"],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
        )

        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertIn("Compose file is valid", result.stdout)


if __name__ == "__main__":
    unittest.main()
