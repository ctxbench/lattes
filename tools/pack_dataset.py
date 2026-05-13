#!/usr/bin/env python3

import argparse
import hashlib
import json
import tarfile
from pathlib import Path

DATASET_NAME = "ctxbench-lattes"
DATASET_ID = "ctxbench/lattes"
MANIFEST_SCHEMA_VERSION = 1
DESCRIPTOR_SCHEMA_VERSION = 1
DEFAULT_REPOSITORY = "ctxbench/lattes"


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def add_file(tar: tarfile.TarFile, src: Path, arcname: Path) -> None:
    info = tar.gettarinfo(str(src), arcname=str(arcname))
    info.uid = 0
    info.gid = 0
    info.uname = ""
    info.gname = ""
    info.mtime = 0

    with src.open("rb") as f:
        tar.addfile(info, f)


def add_tree(tar: tarfile.TarFile, root: Path, prefix: Path) -> None:
    files = sorted(p for p in root.rglob("*") if p.is_file())

    for src in files:
        rel = src.relative_to(root)
        add_file(tar, src, prefix / rel)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", default="0.3.0")
    parser.add_argument("--src", default="datasets/lattes")
    parser.add_argument("--out", default="dist")
    parser.add_argument("--repository", default=DEFAULT_REPOSITORY)
    parser.add_argument("--release-tag", default=None)
    args = parser.parse_args()

    src_dir = Path(args.src)
    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    questions = Path("questions/questions.json")
    question_instances = Path("questions/questions.instance.json")
    context_dir = src_dir / "context"

    required = [
        questions,
        question_instances,
        context_dir,
        Path("dataset-card.md"),
        Path("DATASET-TERMS.md"),
        Path("NOTICE.md"),
    ]

    for path in required:
        if not path.exists():
            raise SystemExit(f"Missing required path: {path}")

    release_tag = args.release_tag or f"v{args.version}-dataset"
    package_root = Path(f"{DATASET_NAME}-v{args.version}")
    archive = out_dir / f"{DATASET_NAME}-v{args.version}.tar.gz"
    checksum = out_dir / f"{DATASET_NAME}-v{args.version}.sha256"
    descriptor = out_dir / f"{DATASET_NAME}-v{args.version}.dataset.json"

    manifest = {
        "id": DATASET_ID,
        "datasetVersion": args.version,
        "manifestSchemaVersion": MANIFEST_SCHEMA_VERSION,
        "name": "CTXBench Lattes",
        "description": "Lattes benchmark dataset for CTXBench.",
        "domain": "academic curricula",
        "benchmark": "CTXBench",
        "layout": {
            "tasks": "questions.json",
            "taskInstances": "questions.instance.json",
            "contextRoot": "context/",
        },
        "formats": [
            "raw_html",
            "clean_html",
            "parsed_json",
            "blocks",
        ],
    }

    manifest_path = out_dir / "ctxbench.dataset.tmp.json"
    manifest_path.write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

    with tarfile.open(archive, "w:gz", format=tarfile.PAX_FORMAT) as tar:
        add_file(tar, manifest_path, package_root / "ctxbench.dataset.json")
        add_file(tar, Path("dataset-card.md"), package_root / "dataset-card.md")
        add_file(tar, Path("DATASET-TERMS.md"), package_root / "DATASET-TERMS.md")
        add_file(tar, Path("NOTICE.md"), package_root / "NOTICE.md")
        add_file(tar, questions, package_root / "questions.json")
        add_file(tar, question_instances, package_root / "questions.instance.json")
        add_tree(tar, context_dir, package_root / "context")

    manifest_path.unlink()

    digest = sha256_file(archive)
    checksum.write_text(f"{digest}  {archive.name}\n", encoding="utf-8")

    archive_url = (
        f"https://github.com/{args.repository}/releases/download/"
        f"{release_tag}/{archive.name}"
    )
    descriptor_payload = {
        "id": DATASET_ID,
        "datasetVersion": args.version,
        "descriptorSchemaVersion": DESCRIPTOR_SCHEMA_VERSION,
        "name": "CTXBench Lattes",
        "description": "Lattes benchmark dataset for CTXBench.",
        "releaseTag": release_tag,
        "archive": {
            "type": "tar.gz",
            "url": archive_url,
            "sha256": digest,
            "sizeBytes": archive.stat().st_size,
        },
    }
    descriptor.write_text(
        json.dumps(descriptor_payload, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

    print(f"Created {archive}")
    print(f"Created {checksum}")
    print(f"Created {descriptor}")


if __name__ == "__main__":
    main()
