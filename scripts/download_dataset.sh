#!/usr/bin/env bash
set -euo pipefail

DATASET_NAME="${DATASET_NAME:-ctxbench-lattes}"
REPOSITORY="${REPOSITORY:-ctxbench/lattes}"

usage() {
  cat <<EOF
Usage:
  $0 [version] [output-dir] [release-tag]

Examples:
  $0
  $0 0.3.0
  $0 0.3.0 downloads
  $0 0.3.0 downloads v0.3.0-dataset

Environment variables:
  DATASET_NAME   default: ctxbench-lattes
  REPOSITORY     default: ctxbench/lattes
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

VERSION="${1:-0.3.0}"
OUT_DIR="${2:-downloads}"
TAG="${3:-v${VERSION}-dataset}"

ARCHIVE="${DATASET_NAME}-v${VERSION}.tar.gz"
CHECKSUM="${DATASET_NAME}-v${VERSION}.sha256"
DESCRIPTOR="${DATASET_NAME}-v${VERSION}.dataset.json"

BASE_URL="https://github.com/${REPOSITORY}/releases/download/${TAG}"

mkdir -p "${OUT_DIR}"

echo "Downloading CTXBench Lattes dataset"
echo "  repository: ${REPOSITORY}"
echo "  version:    ${VERSION}"
echo "  tag:        ${TAG}"
echo "  output:     ${OUT_DIR}"
echo

curl -fL \
  "${BASE_URL}/${DESCRIPTOR}" \
  -o "${OUT_DIR}/${DESCRIPTOR}"

curl -fL \
  "${BASE_URL}/${ARCHIVE}" \
  -o "${OUT_DIR}/${ARCHIVE}"

curl -fL \
  "${BASE_URL}/${CHECKSUM}" \
  -o "${OUT_DIR}/${CHECKSUM}"

echo
echo "Downloaded:"
echo "  ${OUT_DIR}/${DESCRIPTOR}"
echo "  ${OUT_DIR}/${ARCHIVE}"
echo "  ${OUT_DIR}/${CHECKSUM}"
echo
echo "Next step:"
echo "  ./scripts/verify_dataset.sh ${VERSION} ${OUT_DIR}"
echo
echo "CTXBench descriptor fetch:"
echo "  ctxbench dataset fetch --descriptor-file ${OUT_DIR}/${DESCRIPTOR}"
