# CTXBench Lattes

CTXBench Lattes is a benchmark dataset instance for evaluating **context access and provisioning strategies** in Large Language Model (LLM)-based systems using Brazilian Lattes curricula.

This repository contains the Lattes-specific dataset metadata, benchmark questions, experiment configurations, utility scripts, and release documentation used with the CTXBench CLI.

The CTXBench CLI is maintained separately in:

https://github.com/ctxbench/ctxbench-cli

## Purpose

CTXBench Lattes is designed to support controlled experiments comparing how different context provisioning strategies affect LLM behavior when answering questions over semi-structured curriculum documents.

The benchmark focuses on dimensions such as:

- answer quality;
- token cost;
- execution time;
- tool usage;
- judge agreement;
- observability of model, tool, and evaluation behavior.

The dataset should be used to evaluate **methods, strategies, and systems**, not the individuals represented in the source curriculum pages.

## Repository role

This repository is the Lattes benchmark instance of CTXBench.

```text
ctxbench/
  ctxbench-cli      # CLI/framework for running CTXBench experiments
  lattes            # Lattes dataset instance, questions, configs, and releases
```

This repository stores:

- dataset documentation;
- dataset terms and notices;
- benchmark questions;
- instance-specific question parameters;
- experiment definitions;
- packaging, download, verification, and unpacking scripts;
- small example datasets, when available;
- release notes for dataset packages.

The complete dataset package is distributed as a GitHub Release asset, not committed directly to Git.

## Dataset package

The canonical dataset package is distributed as:

```text
ctxbench-lattes-v0.1.0.tar.gz
ctxbench-lattes-v0.1.0.sha256
```

The current dataset release tag is expected to be:

```text
v0.1.0-dataset
```

The package layout is:

```text
ctxbench-lattes-v0.1.0/
├── manifest.json
├── dataset-card.md
├── DATASET-TERMS.md
├── NOTICE.md
├── questions.json
├── questions.instance.json
└── context/
    ├── <instanceId>/
    │   ├── raw.html
    │   ├── clean.html
    │   ├── parsed.json
    │   └── blocks.json
    └── ...
```

## Dataset files

Each curriculum instance is stored under:

```text
context/<instanceId>/
```

The expected files are:

| File | Description |
|---|---|
| `raw.html` | Original collected HTML representation of the public Lattes curriculum page. |
| `clean.html` | Cleaned HTML representation used by inline context strategies. |
| `parsed.json` | Parsed JSON representation derived from the curriculum page. |
| `blocks.json` | Semantic context blocks used by tool-mediated strategies and evaluation. |

The question files are:

| File | Description |
|---|---|
| `questions.json` | Defines benchmark questions, tags, validation type, and expected context blocks. |
| `questions.instance.json` | Defines instance-specific parameters for the benchmark questions. |

## Suggested repository layout

```text
.
├── README.md
├── dataset-card.md
├── DATASET-TERMS.md
├── NOTICE.md
├── CITATION.cff
├── LICENSE
├── flake.nix
├── .envrc
├── justfile
├── questions/
│   ├── questions.json
│   └── questions.instance.json
├── experiments/
│   ├── experiment.baseline001.json
│   └── README.md
├── scripts/
│   ├── pack_dataset.sh
│   ├── verify_dataset.sh
│   ├── download_dataset.sh
│   └── unpack_dataset.sh
├── tools/
│   └── pack_dataset.py
├── datasets/
│   ├── README.md
│   └── lattes-mini/
├── downloads/
└── dist/
```

The directories `downloads/`, `dist/`, and the full `datasets/lattes/` directory are generated locally and should not be committed.

## Quick start

### 1. Clone the repository

```bash
git clone https://github.com/ctxbench/lattes
cd lattes
```

### 2. Download the dataset package

```bash
./scripts/download_dataset.sh 0.1.0
```

This downloads:

```text
downloads/
├── ctxbench-lattes-v0.1.0.tar.gz
└── ctxbench-lattes-v0.1.0.sha256
```

### 3. Verify the package

```bash
./scripts/verify_dataset.sh 0.1.0 downloads
```

The verification step checks the SHA-256 checksum and validates the expected dataset structure.

### 4. Unpack the dataset

```bash
./scripts/unpack_dataset.sh 0.1.0
```

The dataset will be unpacked into:

```text
datasets/lattes/
```

## Running experiments

After unpacking the dataset and installing the CTXBench CLI, a typical experiment workflow is:

```bash
ctxbench plan experiments/experiment.baseline001.json \
  --output experiments/baseline_001

ctxbench query experiments/baseline_001/queries.jsonl

ctxbench eval experiments/baseline_001/answers.jsonl

ctxbench export experiments/baseline_001/evals.jsonl \
  --to csv \
  --output experiments/baseline_001/results.csv

ctxbench status experiments/baseline_001
```

The main generated artifacts are:

| Artifact | Description |
|---|---|
| `manifest.json` | Execution manifest produced during planning. |
| `queries.jsonl` | Planned query executions. |
| `answers.jsonl` | Generated answers and query-phase metrics. |
| `evals.jsonl` | Aggregated evaluation results. |
| `judge_votes.jsonl` | Individual judge-level votes. |
| `results.csv` | Flattened analysis-ready export. |
| `traces/` | Detailed query and evaluation traces, when enabled. |

## Context provisioning strategies

CTXBench Lattes is intended to support comparison of multiple context access and provisioning strategies.

Typical strategies include:

| Strategy | Description |
|---|---|
| `inline` | Inserts the selected context artifact directly into the prompt. |
| `local_function` | Exposes local Python functions as model-callable tools while the benchmark controls the tool loop. |
| `local_mcp` | Exposes tools through a local MCP runtime while preserving local observability. |
| `mcp` | Uses a remote MCP server to expose curriculum context through a distributed architecture. |

For inline strategies, both HTML and JSON representations may be evaluated.

For tool-mediated strategies, the effective context representation is usually normalized to JSON or semantic blocks.

## Environment options

This repository is designed to work in two modes:

1. with Nix, for reproducible development environments;
2. without Nix, for broader accessibility.

### With Nix

If you use NixOS or Nix with flakes enabled:

```bash
nix develop
```

Then run:

```bash
./scripts/download_dataset.sh 0.1.0
./scripts/verify_dataset.sh 0.1.0 downloads
./scripts/unpack_dataset.sh 0.1.0
```

If the repository provides a `justfile`, you may also use:

```bash
just download
just verify
just unpack
```

### Without Nix

Install the required tools using your system package manager.

Minimum expected tools:

- `bash`;
- `python3`;
- `curl`;
- `tar`;
- `gzip`;
- `sha256sum` or `shasum`.

Then run the same scripts directly:

```bash
./scripts/download_dataset.sh 0.1.0
./scripts/verify_dataset.sh 0.1.0 downloads
./scripts/unpack_dataset.sh 0.1.0
```

The scripts are written for Bash and can be executed from Fish, Zsh, or other interactive shells because they use a Bash shebang.

Example from Fish:

```fish
./scripts/download_dataset.sh 0.1.0
```

## Packaging a new dataset version

To create a local dataset package from an expanded dataset directory:

```bash
./scripts/pack_dataset.sh 0.1.0 datasets/lattes dist
```

This should create:

```text
dist/
├── ctxbench-lattes-v0.1.0.tar.gz
└── ctxbench-lattes-v0.1.0.sha256
```

Verify the local package:

```bash
./scripts/verify_dataset.sh 0.1.0 dist
```

## Publishing a dataset release

Dataset archives should be published as GitHub Release assets in this repository.

The dataset archive should not be committed directly to Git.

Recommended release convention:

```text
Release tag:   v0.1.0-dataset
Release title: CTXBench Lattes Dataset v0.1.0
Assets:
  ctxbench-lattes-v0.1.0.tar.gz
  ctxbench-lattes-v0.1.0.sha256
```

Example using GitHub CLI:

```bash
gh release create v0.1.0-dataset \
  dist/ctxbench-lattes-v0.1.0.tar.gz \
  dist/ctxbench-lattes-v0.1.0.sha256 \
  --repo ctxbench/lattes \
  --title "CTXBench Lattes Dataset v0.1.0" \
  --notes-file release-notes-v0.1.0-dataset.md \
  --draft
```

After reviewing the draft release in GitHub, publish it through the GitHub interface.

## Versioning policy

Dataset packages are versioned.

A published dataset version should be treated as immutable.

Create a new version when changing:

- curriculum-derived artifacts;
- question definitions;
- instance mappings;
- context block structure;
- dataset layout;
- preprocessing logic that affects the released artifacts.

Suggested version pattern:

```text
vMAJOR.MINOR.PATCH-dataset
```

Examples:

```text
v0.1.0-dataset
v0.2.0-dataset
v1.0.0-dataset
```

## Release artifacts versus experiment artifacts

Dataset releases and experiment artifacts should be kept separate.

### Dataset release

Contains benchmark inputs:

```text
questions.json
questions.instance.json
context/*/raw.html
context/*/clean.html
context/*/parsed.json
context/*/blocks.json
manifest.json
dataset-card.md
DATASET-TERMS.md
NOTICE.md
```

### Experiment artifact release

Contains benchmark outputs:

```text
manifest.json
queries.jsonl
answers.jsonl
evals.jsonl
judge_votes.jsonl
results.csv
traces/
notebooks/
```

A possible release tag for experiment artifacts is:

```text
v0.1.0-baseline001-artifacts
```

## License and terms

This repository contains different types of materials.

- Source code and utility scripts are licensed under the repository software license.
- Benchmark questions, configurations, documentation, and metadata are licensed under CC BY 4.0 unless otherwise stated.
- Lattes curriculum-derived artifacts are provided for academic research, benchmarking, and reproducibility under the terms described in `DATASET-TERMS.md`.

See also:

- `DATASET-TERMS.md`;
- `NOTICE.md`;
- `CITATION.cff`.

## Responsible use

The dataset includes artifacts derived from public Lattes curriculum pages.

Public availability does not remove the need for responsible use.

Do not use this dataset to:

- make decisions about individuals;
- rank, score, or profile researchers;
- infer sensitive personal attributes;
- contact, monitor, or target individuals;
- imply endorsement by curriculum authors, CNPq, the Lattes Platform, universities, employers, or funding agencies.

Users are responsible for ensuring that their use complies with applicable laws, platform terms, institutional policies, and research ethics requirements.

## Citation

If you use CTXBench Lattes, cite the dataset and the associated CTXBench research artifact.

Citation metadata is provided in:

```text
CITATION.cff
```

## Related repositories

- CTXBench CLI: https://github.com/ctxbench/ctxbench-cli
- CTXBench Lattes: https://github.com/ctxbench/lattes
