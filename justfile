set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

defaultVersion := "0.3.0"

pack version=defaultVersion:
    ./scripts/pack_dataset.sh {{ version }} datasets/lattes dist

verify version=defaultVersion:
    ./scripts/verify_dataset.sh {{ version }} dist

download version=defaultVersion:
    ./scripts/download_dataset.sh {{ version }}

descriptor version=defaultVersion:
    jq . dist/ctxbench-lattes-v{{ version }}.dataset.json

release-draft version=defaultVersion:
    gh release create v{{ version }}-dataset \
      dist/ctxbench-lattes-v{{ version }}.dataset.json \
      dist/ctxbench-lattes-v{{ version }}.tar.gz \
      dist/ctxbench-lattes-v{{ version }}.sha256 \
      --repo ctxbench/lattes \
      --title "CTXBench Lattes Dataset v{{ version }}" \
      --notes-file release-notes-v{{ version }}-dataset.md \
      --draft

clean:
    rm -rf dist downloads
