import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]


class BuildImagesTests(unittest.TestCase):
    def run_builder(self, target: str, output_dir: Path) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [
                sys.executable,
                str(REPO_ROOT / "scripts" / "build_images.py"),
                "--target",
                target,
                "--output-dir",
                str(output_dir),
                "--dry-run",
            ],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
        )

    def test_iso_builder_creates_manifest_and_script(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            output_dir = Path(tmpdir) / "images"
            result = self.run_builder("iso", output_dir)

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue((output_dir / "iso" / "manifest.json").exists())
            self.assertTrue((output_dir / "iso" / "build.sh").exists())

    def test_vmware_builder_creates_packer_template(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            output_dir = Path(tmpdir) / "images"
            result = self.run_builder("vmware", output_dir)

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue((output_dir / "vmware" / "manifest.json").exists())
            self.assertTrue((output_dir / "vmware" / "packer-template.pkr.hcl").exists())

    def test_virtualbox_builder_creates_packer_template(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            output_dir = Path(tmpdir) / "images"
            result = self.run_builder("virtualbox", output_dir)

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue((output_dir / "virtualbox" / "manifest.json").exists())
            self.assertTrue((output_dir / "virtualbox" / "packer-template.pkr.hcl").exists())

    def test_iso_builder_script_runs_without_iso_tooling(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            output_dir = Path(tmpdir) / "images"
            result = self.run_builder("iso", output_dir)
            self.assertEqual(result.returncode, 0, result.stderr)

            script_path = output_dir / "iso" / "build.sh"
            temp_script = Path(tmpdir) / "build.sh"
            shutil.copy2(script_path, temp_script)
            os.chmod(temp_script, 0o755)

            run_result = subprocess.run(
                ["bash", str(temp_script)],
                cwd=tmpdir,
                capture_output=True,
                text=True,
            )

            self.assertEqual(run_result.returncode, 0, run_result.stderr)
            self.assertTrue((Path(tmpdir) / "output" / "cyberpot-live.iso").exists())


if __name__ == "__main__":
    unittest.main()
