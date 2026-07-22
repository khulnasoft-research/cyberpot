import subprocess
import sys
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]


class ValidateRepoTests(unittest.TestCase):
    def test_validation_script_runs_successfully(self):
        script = REPO_ROOT / "scripts" / "validate_repo.py"
        result = subprocess.run(
            [sys.executable, str(script)],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
        )

        self.assertEqual(
            result.returncode,
            0,
            msg=f"Validation script failed:\nSTDOUT:\n{result.stdout}\nSTDERR:\n{result.stderr}",
        )

    def test_validation_script_checks_compose_files(self):
        script = REPO_ROOT / "scripts" / "validate_repo.py"
        result = subprocess.run(
            [sys.executable, str(script)],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
        )

        self.assertIn("compose files", result.stdout)


if __name__ == "__main__":
    unittest.main()
