#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${ROOT_DIR}/workdir"
OUTPUT_DIR="${ROOT_DIR}/output"

mkdir -p "${WORK_DIR}" "${OUTPUT_DIR}"

echo '[1/4] Checking prerequisites...'
command -v xorriso >/dev/null 2>&1 || { echo 'xorriso is required'; exit 1; }
command -v mkisofs >/dev/null 2>&1 || { echo 'mkisofs is required'; exit 1; }

echo '[2/4] Preparing ISO workspace...'
cat > "${WORK_DIR}/README.txt" <<'EOF'
CyberPot ISO build workspace
============================
This directory is prepared by scripts/build_images.py for future ISO automation.
EOF

echo '[3/4] Creating placeholder ISO artifact...'
mkdir -p "${OUTPUT_DIR}/iso-root"
cp "${WORK_DIR}/README.txt" "${OUTPUT_DIR}/iso-root/README.txt"
mkisofs -o "${OUTPUT_DIR}/cyberpot-live.iso" -volid CYBERPOT-LIVE "${OUTPUT_DIR}/iso-root" >/dev/null 2>&1

echo '[4/4] ISO artifact ready at ${OUTPUT_DIR}/cyberpot-live.iso'
