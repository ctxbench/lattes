set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

defaultVersion := "0.2.0"

pack version=defaultVersion:
    ./scripts/pack_dataset.sh {{ version }} datasets/lattes dist

verify version=defaultVersion:
    ./scripts/verify_dataset.sh {{ version }}

download version=defaultVersion:
    ./scripts/download_dataset.sh {{ version }}

unpack version=defaultVersion:
    ./scripts/unpack_dataset.sh {{ version }}

clean:
    rm -rf dist downloads
