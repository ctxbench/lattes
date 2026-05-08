#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-0.1.0}"
DATASET_NAME="ctxbench-lattes"
ARCHIVE="dist/${DATASET_NAME}-v${VERSION}.tar.gz"
CHECKSUM="dist/${DATASET_NAME}-v${VERSION}.sha256"

sha256sum -c "${CHECKSUM}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

tar -xzf "${ARCHIVE}" -C "${TMP_DIR}"

ROOT="${TMP_DIR}/${DATASET_NAME}-v${VERSION}"

test -f "${ROOT}/manifest.json"
test -f "${ROOT}/questions.json"
test -f "${ROOT}/questions.instance.json"
test -d "${ROOT}/context"

find "${ROOT}/context" -mindepth 1 -maxdepth 1 -type d | while read -r instance_dir; do
  test -f "${instance_dir}/clean.html"
  test -f "${instance_dir}/parsed.json"
  test -f "${instance_dir}/blocks.json"
done

echo "Dataset package is valid."
