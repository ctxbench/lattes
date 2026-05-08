#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-0.1.0}"
SRC_DIR="${2:-datasets/lattes}"
OUT_DIR="${3:-dist}"

python3 tools/pack_dataset.py \
  --version "${VERSION}" \
  --src "${SRC_DIR}" \
  --out "${OUT_DIR}"
