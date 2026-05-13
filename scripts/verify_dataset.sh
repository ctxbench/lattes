#!/usr/bin/env bash
set -euo pipefail

DATASET_NAME="${DATASET_NAME:-ctxbench-lattes}"
EXPECTED_DATASET_ID="${EXPECTED_DATASET_ID:-ctxbench/lattes}"
EXPECTED_MANIFEST_SCHEMA_VERSION="${EXPECTED_MANIFEST_SCHEMA_VERSION:-1}"
EXPECTED_DESCRIPTOR_SCHEMA_VERSION="${EXPECTED_DESCRIPTOR_SCHEMA_VERSION:-1}"

usage() {
  cat <<EOF
Usage:
  $0 <version> [directory]
  $0 <archive-path>

Examples:
  $0 0.3.0 dist
  $0 0.3.0 downloads
  $0 dist/ctxbench-lattes-v0.3.0.tar.gz
  $0 downloads/ctxbench-lattes-v0.3.0.tar.gz

Environment variables:
  DATASET_NAME                         default: ctxbench-lattes
  EXPECTED_DATASET_ID                  default: ctxbench/lattes
  EXPECTED_MANIFEST_SCHEMA_VERSION     default: 1
  EXPECTED_DESCRIPTOR_SCHEMA_VERSION   default: 1
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

VERSION_OR_ARCHIVE="${1:-0.3.0}"
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
DESCRIPTOR_FILE="${ARCHIVE_FILE%.tar.gz}.dataset.json"

if [[ "${ARCHIVE_FILE}" == "${DATASET_NAME}-v"*".tar.gz" ]]; then
  VERSION="${ARCHIVE_FILE#${DATASET_NAME}-v}"
  VERSION="${VERSION%.tar.gz}"
else
  VERSION="${VERSION_OR_ARCHIVE}"
fi

if [[ ! -f "${ARCHIVE_DIR}/${ARCHIVE_FILE}" ]]; then
  echo "Dataset archive not found: ${ARCHIVE_DIR}/${ARCHIVE_FILE}" >&2
  exit 1
fi

if [[ ! -f "${ARCHIVE_DIR}/${CHECKSUM_FILE}" ]]; then
  echo "Checksum file not found: ${ARCHIVE_DIR}/${CHECKSUM_FILE}" >&2
  exit 1
fi

if [[ ! -f "${ARCHIVE_DIR}/${DESCRIPTOR_FILE}" ]]; then
  echo "Descriptor file not found: ${ARCHIVE_DIR}/${DESCRIPTOR_FILE}" >&2
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

python3 - \
  "${ROOT}/ctxbench.dataset.json" \
  "${ARCHIVE_DIR}/${DESCRIPTOR_FILE}" \
  "${ARCHIVE_DIR}/${CHECKSUM_FILE}" \
  "${EXPECTED_DATASET_ID}" \
  "${VERSION}" \
  "${EXPECTED_MANIFEST_SCHEMA_VERSION}" \
  "${EXPECTED_DESCRIPTOR_SCHEMA_VERSION}" \
  "${ARCHIVE_FILE}" <<'PY'
import json
import re
import sys
from pathlib import Path

manifest_path = Path(sys.argv[1])
descriptor_path = Path(sys.argv[2])
checksum_path = Path(sys.argv[3])
expected_dataset_id = sys.argv[4]
expected_version = sys.argv[5]
expected_manifest_schema_version = int(sys.argv[6])
expected_descriptor_schema_version = int(sys.argv[7])
archive_file = sys.argv[8]

manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
descriptor = json.loads(descriptor_path.read_text(encoding="utf-8"))
checksum_text = checksum_path.read_text(encoding="utf-8")

match = re.search(r"\b([0-9a-fA-F]{64})\b", checksum_text)
if match is None:
    raise SystemExit(f"Unable to parse SHA-256 from {checksum_path}")
checksum = match.group(1).lower()

if manifest.get("id") != expected_dataset_id:
    raise SystemExit(f"Unexpected dataset id in {manifest_path}: {manifest.get('id')!r}")

if manifest.get("datasetVersion") != expected_version:
    raise SystemExit(
        f"Unexpected datasetVersion in {manifest_path}: {manifest.get('datasetVersion')!r}; "
        f"expected {expected_version!r}"
    )

if manifest.get("manifestSchemaVersion") != expected_manifest_schema_version:
    raise SystemExit(
        f"Unsupported manifestSchemaVersion in {manifest_path}: "
        f"{manifest.get('manifestSchemaVersion')!r}"
    )

layout = manifest.get("layout")
if not isinstance(layout, dict):
    raise SystemExit(f"Missing layout object in {manifest_path}")

for key in ("tasks", "taskInstances", "contextRoot"):
    if key not in layout:
        raise SystemExit(f"Missing layout.{key} in {manifest_path}")

if descriptor.get("id") != expected_dataset_id:
    raise SystemExit(f"Unexpected descriptor id in {descriptor_path}: {descriptor.get('id')!r}")

if descriptor.get("datasetVersion") != expected_version:
    raise SystemExit(
        f"Unexpected descriptor datasetVersion in {descriptor_path}: "
        f"{descriptor.get('datasetVersion')!r}; expected {expected_version!r}"
    )

if descriptor.get("descriptorSchemaVersion") != expected_descriptor_schema_version:
    raise SystemExit(
        f"Unsupported descriptorSchemaVersion in {descriptor_path}: "
        f"{descriptor.get('descriptorSchemaVersion')!r}"
    )

archive = descriptor.get("archive")
if not isinstance(archive, dict):
    raise SystemExit(f"Descriptor field 'archive' must be an object in {descriptor_path}")

for key in ("type", "url", "sha256"):
    value = archive.get(key)
    if not isinstance(value, str) or not value:
        raise SystemExit(f"Descriptor archive.{key} must be a non-empty string")

if archive["type"] != "tar.gz":
    raise SystemExit(f"Unexpected descriptor archive.type: {archive['type']!r}")

if archive["sha256"].lower().removeprefix("sha256:") != checksum:
    raise SystemExit(
        f"Descriptor archive.sha256 does not match checksum file: "
        f"{archive['sha256']!r} != {checksum!r}"
    )

if not archive["url"].endswith("/" + archive_file):
    raise SystemExit(
        f"Descriptor archive.url does not end with expected archive file {archive_file!r}: "
        f"{archive['url']!r}"
    )

if descriptor.get("id") != manifest.get("id"):
    raise SystemExit("Descriptor id does not match internal ctxbench.dataset.json id")

if descriptor.get("datasetVersion") != manifest.get("datasetVersion"):
    raise SystemExit("Descriptor datasetVersion does not match internal ctxbench.dataset.json datasetVersion")
PY

find "${ROOT}/context" -mindepth 1 -maxdepth 1 -type d | while read -r instance_dir; do
  test -f "${instance_dir}/clean.html"
  test -f "${instance_dir}/parsed.json"
  test -f "${instance_dir}/blocks.json"
done

echo "Dataset package is valid:"
echo "  archive:    ${ARCHIVE_DIR}/${ARCHIVE_FILE}"
echo "  checksum:   ${ARCHIVE_DIR}/${CHECKSUM_FILE}"
echo "  descriptor: ${ARCHIVE_DIR}/${DESCRIPTOR_FILE}"
echo "  manifest:   ${ROOT}/ctxbench.dataset.json"
