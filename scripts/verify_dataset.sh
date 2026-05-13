#!/usr/bin/env bash
set -euo pipefail

DATASET_NAME="${DATASET_NAME:-ctxbench-lattes}"
EXPECTED_DATASET_ID="${EXPECTED_DATASET_ID:-ctxbench/lattes}"
EXPECTED_MANIFEST_SCHEMA_VERSION="${EXPECTED_MANIFEST_SCHEMA_VERSION:-1}"

usage() {
  cat <<EOF
Usage:
  $0 <version> [directory]
  $0 <archive-path>

Examples:
  $0 0.2.0 dist
  $0 0.2.0 downloads
  $0 dist/ctxbench-lattes-v0.2.0.tar.gz
  $0 downloads/ctxbench-lattes-v0.2.0.tar.gz

Environment variables:
  DATASET_NAME                       default: ctxbench-lattes
  EXPECTED_DATASET_ID                default: ctxbench/lattes
  EXPECTED_MANIFEST_SCHEMA_VERSION   default: 1
EOF
}

sha256_check() {
  local checksum_file="$1"

  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum -c "${checksum_file}"
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 -c "${checksum_file}"
  else
    echo "Neither sha256sum nor shasum was found." >&2
    exit 1
  fi
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

VERSION_OR_ARCHIVE="${1:-0.2.0}"
LOCATION="${2:-dist}"

if [[ -f "${VERSION_OR_ARCHIVE}" ]]; then
  ARCHIVE_PATH="${VERSION_OR_ARCHIVE}"
else
  VERSION="${VERSION_OR_ARCHIVE}"
  ARCHIVE_PATH="${LOCATION}/${DATASET_NAME}-v${VERSION}.tar.gz"
fi

ARCHIVE_DIR="$(cd "$(dirname "${ARCHIVE_PATH}")" && pwd)"
ARCHIVE_FILE="$(basename "${ARCHIVE_PATH}")"
CHECKSUM_FILE="${ARCHIVE_FILE%.tar.gz}.sha256"

if [[ ! -f "${ARCHIVE_DIR}/${ARCHIVE_FILE}" ]]; then
  echo "Dataset archive not found: ${ARCHIVE_DIR}/${ARCHIVE_FILE}" >&2
  exit 1
fi

if [[ ! -f "${ARCHIVE_DIR}/${CHECKSUM_FILE}" ]]; then
  echo "Checksum file not found: ${ARCHIVE_DIR}/${CHECKSUM_FILE}" >&2
  exit 1
fi

(
  cd "${ARCHIVE_DIR}"
  sha256_check "${CHECKSUM_FILE}"
)

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

tar -xzf "${ARCHIVE_DIR}/${ARCHIVE_FILE}" -C "${TMP_DIR}"

ROOT="$(find "${TMP_DIR}" -mindepth 1 -maxdepth 1 -type d | head -n 1)"

if [[ -z "${ROOT}" ]]; then
  echo "Could not find dataset root directory inside archive." >&2
  exit 1
fi

test -f "${ROOT}/ctxbench.dataset.json"
test -f "${ROOT}/questions.json"
test -f "${ROOT}/questions.instance.json"
test -d "${ROOT}/context"

python3 - "${ROOT}/ctxbench.dataset.json" "${EXPECTED_DATASET_ID}" "${EXPECTED_MANIFEST_SCHEMA_VERSION}" <<'PY'
import json
import sys
from pathlib import Path

manifest_path = Path(sys.argv[1])
expected_dataset_id = sys.argv[2]
expected_schema_version = int(sys.argv[3])

payload = json.loads(manifest_path.read_text(encoding="utf-8"))

if payload.get("id") != expected_dataset_id:
    raise SystemExit(
        f"Unexpected dataset id in {manifest_path}: {payload.get('id')!r}"
    )

dataset_version = payload.get("datasetVersion")
if not isinstance(dataset_version, str) or not dataset_version:
    raise SystemExit(f"Missing non-empty datasetVersion in {manifest_path}")

if payload.get("manifestSchemaVersion") != expected_schema_version:
    raise SystemExit(
        f"Unsupported manifestSchemaVersion in {manifest_path}: "
        f"{payload.get('manifestSchemaVersion')!r}"
    )

layout = payload.get("layout")
if not isinstance(layout, dict):
    raise SystemExit(f"Missing layout object in {manifest_path}")

for key in ("tasks", "taskInstances", "contextRoot"):
    if key not in layout:
        raise SystemExit(f"Missing layout.{key} in {manifest_path}")
PY

find "${ROOT}/context" -mindepth 1 -maxdepth 1 -type d | while read -r instance_dir; do
  test -f "${instance_dir}/clean.html"
  test -f "${instance_dir}/parsed.json"
  test -f "${instance_dir}/blocks.json"
done

echo "Dataset package is valid:"
echo "  archive:  ${ARCHIVE_DIR}/${ARCHIVE_FILE}"
echo "  checksum: ${ARCHIVE_DIR}/${CHECKSUM_FILE}"
echo "  manifest: ${ROOT}/ctxbench.dataset.json"
