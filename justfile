set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

version := "0.1.0"

pack:
    ./scripts/pack_dataset.sh {{version}} datasets/lattes dist

verify:
    ./scripts/verify_dataset.sh {{version}}

download:
    ./scripts/download_dataset.sh {{version}}

unpack:
    ./scripts/unpack_dataset.sh {{version}}

clean:
    rm -rf dist downloads
