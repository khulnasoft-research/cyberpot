import importlib.util
import shutil
import subprocess
import sys
import tempfile
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

    def test_validation_script_fails_when_required_paths_missing(self):
        script_src = REPO_ROOT / "scripts" / "validate_repo.py"

        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_path = Path(tmpdir)
            scripts_dir = tmp_path / "scripts"
            scripts_dir.mkdir(parents=True)
            script_dst = scripts_dir / "validate_repo.py"
            shutil.copy(script_src, script_dst)

            result = subprocess.run(
                [sys.executable, str(script_dst)],
                cwd=tmp_path,
                capture_output=True,
                text=True,
            )

        self.assertNotEqual(
            result.returncode,
            0,
            msg=f"Validation script unexpectedly succeeded in incomplete repo:\n"
                f"STDOUT:\n{result.stdout}\nSTDERR:\n{result.stderr}",
        )
        self.assertIn("Missing required file or directory", result.stderr)
        self.assertIn("README.md", result.stderr)

    def test_validate_compose_files_raises_runtimeerror_when_yaml_missing(self):
        script_path = REPO_ROOT / "scripts" / "validate_repo.py"
        spec = importlib.util.spec_from_file_location(
            "validate_repo_for_tests", script_path
        )
        module = importlib.util.module_from_spec(spec)
        assert spec.loader is not None
        spec.loader.exec_module(module)

        original_yaml = getattr(module, "yaml", None)
        try:
            module.yaml = None
            with self.assertRaises(RuntimeError):
                module.validate_compose_files()
        finally:
            module.yaml = original_yaml

    def test_validation_script_reports_yaml_error_for_invalid_compose_file(self):
        script_src = REPO_ROOT / "scripts" / "validate_repo.py"

        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_path = Path(tmpdir)
            scripts_dir = tmp_path / "scripts"
            scripts_dir.mkdir(parents=True)
            script_dst = scripts_dir / "validate_repo.py"
            shutil.copy(script_src, script_dst)

            (tmp_path / "README.md").write_text(
                "# Temporary test repo\n",
                encoding="utf-8",
            )
            (tmp_path / "docker-compose.yml").write_text(
                "# placeholder\n",
                encoding="utf-8",
            )
            for d in ("compose", "docker", "installer", "tests"):
                (tmp_path / d).mkdir(parents=True, exist_ok=True)

            compose_dir = tmp_path / "compose"
            invalid_compose = compose_dir / "docker-compose.yml"
            invalid_compose.write_text(
                "this: : : not valid: yaml: [",
                encoding="utf-8",
            )

            result = subprocess.run(
                [sys.executable, str(script_dst)],
                cwd=tmp_path,
                capture_output=True,
                text=True,
            )

        self.assertNotEqual(
            result.returncode,
            0,
            msg=f"Validation script unexpectedly succeeded with invalid YAML:\n"
                f"STDOUT:\n{result.stdout}\nSTDERR:\n{result.stderr}",
        )
        self.assertIn("mapping values are not allowed here", result.stderr)


if __name__ == "__main__":
    unittest.main()
