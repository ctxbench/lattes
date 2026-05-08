#!/usr/bin/env python3

import argparse
import hashlib
import json
import tarfile
from pathlib import Path

DATASET_NAME = "ctxbench-lattes"


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
    parser.add_argument("--version", default="0.1.0")
    parser.add_argument("--src", default="datasets/lattes")
    parser.add_argument("--out", default="dist")
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

    package_root = Path(f"{DATASET_NAME}-v{args.version}")
    archive = out_dir / f"{DATASET_NAME}-v{args.version}.tar.gz"
    checksum = out_dir / f"{DATASET_NAME}-v{args.version}.sha256"

    manifest = {
        "dataset": DATASET_NAME,
        "version": args.version,
        "benchmark": "CTXBench",
        "layout": {
            "questions": "questions.json",
            "instances": "questions.instance.json",
            "contextRoot": "context/"
        },
        "formats": [
            "raw_html",
            "clean_html",
            "parsed_json",
            "blocks"
        ]
    }

    manifest_path = out_dir / "manifest.tmp.json"
    manifest_path.write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

    with tarfile.open(archive, "w:gz", format=tarfile.PAX_FORMAT) as tar:
        add_file(tar, manifest_path, package_root / "manifest.json")
        add_file(tar, Path("dataset-card.md"), package_root / "dataset-card.md")
        add_file(tar, Path("DATASET-TERMS.md"), package_root / "DATASET-TERMS.md")
        add_file(tar, Path("NOTICE.md"), package_root / "NOTICE.md")
        add_file(tar, questions, package_root / "questions.json")
        add_file(tar, question_instances, package_root / "questions.instance.json")
        add_tree(tar, context_dir, package_root / "context")

    manifest_path.unlink()

    digest = sha256_file(archive)
    checksum.write_text(f"{digest}  {archive.name}\n", encoding="utf-8")

    print(f"Created {archive}")
    print(f"Created {checksum}")


if __name__ == "__main__":
    main()
