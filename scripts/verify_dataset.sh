#!/usr/bin/env bash
set -euo pipefail

DATASET_NAME="${DATASET_NAME:-ctxbench-lattes}"

usage() {
  cat <<EOF
Usage:
  $0 <version> [directory]
  $0 <archive-path>

Examples:
  $0 0.1.0 dist
  $0 0.1.0 downloads
  $0 dist/ctxbench-lattes-v0.1.0.tar.gz
  $0 downloads/ctxbench-lattes-v0.1.0.tar.gz
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

VERSION_OR_ARCHIVE="${1:-0.1.0}"
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

test -f "${ROOT}/manifest.json"
test -f "${ROOT}/questions.json"
test -f "${ROOT}/questions.instance.json"
test -d "${ROOT}/context"

find "${ROOT}/context" -mindepth 1 -maxdepth 1 -type d | while read -r instance_dir; do
  test -f "${instance_dir}/clean.html"
  test -f "${instance_dir}/parsed.json"
  test -f "${instance_dir}/blocks.json"
done

echo "Dataset package is valid:"
echo "  archive:  ${ARCHIVE_DIR}/${ARCHIVE_FILE}"
echo "  checksum: ${ARCHIVE_DIR}/${CHECKSUM_FILE}"
