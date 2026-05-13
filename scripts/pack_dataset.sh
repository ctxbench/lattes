#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-0.3.0}"
SRC_DIR="${2:-datasets/lattes}"
OUT_DIR="${3:-dist}"
REPOSITORY="${4:-ctxbench/lattes}"
RELEASE_TAG="${5:-v${VERSION}-dataset}"

python3 tools/pack_dataset.py \
  --version "${VERSION}" \
  --src "${SRC_DIR}" \
  --out "${OUT_DIR}" \
  --repository "${REPOSITORY}" \
  --release-tag "${RELEASE_TAG}"
