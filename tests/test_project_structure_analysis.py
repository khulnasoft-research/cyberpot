import subprocess
import sys
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]


class ProjectStructureAnalysisTests(unittest.TestCase):
    def test_structure_analysis_script_runs_successfully(self):
        script = REPO_ROOT / "scripts" / "analyze_project_structure.py"
        result = subprocess.run(
            [sys.executable, str(script)],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
        )

        self.assertEqual(
            result.returncode,
            0,
            msg=f"Structure analysis script failed:\nSTDOUT:\n{result.stdout}\nSTDERR:\n{result.stderr}",
        )

    def test_structure_analysis_reports_expected_categories(self):
        script = REPO_ROOT / "scripts" / "analyze_project_structure.py"
        result = subprocess.run(
            [sys.executable, str(script)],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
        )

        output = result.stdout.lower()
        for category in ("compose", "docker", "installer", "scripts", "tests"):
            self.assertIn(category, output)


if __name__ == "__main__":
    unittest.main()
