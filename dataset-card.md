# Dataset Card: CTXBench Lattes

## Summary

CTXBench Lattes is a benchmark dataset instance for evaluating context access and provisioning strategies in Large Language Model (LLM)-based systems.

The dataset is based on public Brazilian Lattes curriculum pages and provides multiple context representations for each curriculum instance. It is designed to support controlled experiments comparing how different context provisioning strategies affect answer quality, token cost, execution time, tool usage, judge agreement, and observability.

CTXBench Lattes is part of the CTXBench project, whose goal is to benchmark architectural strategies for making external context available to LLMs.

## Intended Use

This dataset is intended for academic research and reproducibility studies involving LLM-based question answering over semi-structured documents.

Typical uses include:

- evaluating context access and provisioning strategies;
- comparing inline context, local tool/function access, local MCP access, and remote MCP access;
- measuring answer correctness and completeness;
- analyzing token cost and execution time;
- studying tool usage behavior;
- evaluating judge agreement in LLM-as-judge workflows;
- reproducing experiments reported in CTXBench-related research artifacts.

The dataset is not intended for profiling, ranking, evaluating, or making decisions about the individuals represented in the original curricula.

## Dataset Structure

The canonical dataset package is distributed as a versioned `.tar.gz` archive.

Expected layout:

```text
ctxbench-lattes-vX.Y.Z/
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

Each curriculum instance is identified by an `instanceId`.

For each instance, the dataset may contain the following files:

| File | Description |
|---|---|
| `raw.html` | Original HTML representation collected from the public Lattes curriculum page. |
| `clean.html` | Cleaned HTML representation used by inline strategies. |
| `parsed.json` | Parsed JSON representation derived from the curriculum page. |
| `blocks.json` | Semantic context blocks used by tool-mediated strategies and evaluation. |

The question files are:

| File | Description |
|---|---|
| `questions.json` | Defines benchmark questions, tags, validation type, and expected context blocks. |
| `questions.instance.json` | Defines instance-specific parameters for the questions. |

## Context Representations

CTXBench Lattes provides multiple representations of the same underlying curriculum information.

The main representations are:

- raw HTML;
- cleaned HTML;
- parsed JSON;
- semantic context blocks.

These representations are used to evaluate whether different forms of context organization affect LLM behavior.

For example, inline strategies may provide the cleaned HTML or parsed JSON directly in the prompt, while tool-mediated strategies may expose selected context blocks through functions or MCP tools.

## Benchmark Questions

The benchmark questions cover different types of information needs, including:

- factual questions;
- quantitative questions;
- temporal questions;
- inferential questions;
- cross-block questions;
- weak-data questions;
- ranking or matching questions.

The questions are designed to exercise different parts of a curriculum, such as education, research areas, publications, projects, supervision, technical production, academic activities, and professional experience.

## Collection and Preprocessing

The dataset was constructed from public Lattes curriculum pages.

The processing pipeline may include:

1. collecting the public curriculum HTML;
2. preserving the raw HTML representation;
3. cleaning or minimizing the HTML for prompt-based use;
4. parsing the curriculum into JSON;
5. organizing relevant content into semantic blocks;
6. defining benchmark questions and instance-specific parameters;
7. packaging the dataset with a manifest and checksums.

The dataset maintainers do not claim ownership over the original curriculum content. The benchmark-specific organization, questions, configuration files, scripts, and metadata were created for research and reproducibility purposes.

## Evaluation Use

CTXBench Lattes is designed to be used with the CTXBench CLI.

A typical workflow is:

```bash
ctxbench plan experiments/experiment.baseline001.json \
  --output experiments/baseline_001

ctxbench query experiments/baseline_001/queries.jsonl

ctxbench eval experiments/baseline_001/answers.jsonl

ctxbench export experiments/baseline_001/evals.jsonl \
  --to csv \
  --output experiments/baseline_001/results.csv
```

The main generated artifacts are:

| Artifact | Description |
|---|---|
| `queries.jsonl` | Planned query executions. |
| `answers.jsonl` | Model answers and query-phase metrics. |
| `evals.jsonl` | Aggregated evaluation results. |
| `judge_votes.jsonl` | Individual judge-level votes. |
| `results.csv` | Flattened analysis-ready export. |
| `traces/` | Query and evaluation traces, when enabled. |

## Known Limitations

The dataset has several limitations:

- The source documents are semi-structured and may contain inconsistencies.
- The parsed JSON representation may not perfectly preserve all information from the original HTML.
- Some curriculum sections may be incomplete, outdated, or unevenly structured.
- Some questions may depend on information that is ambiguous or weakly represented in the curriculum.
- LLM-as-judge evaluation may introduce model-specific biases or disagreement.
- The dataset is not representative of all academic profiles or all document types.
- The dataset should not be used to evaluate individuals.

## Ethical Considerations

The dataset is derived from public curriculum information. However, public availability does not remove the need for responsible use.

Users should:

- use the dataset only for research, benchmarking, and reproducibility;
- avoid using the dataset for decisions about individuals;
- avoid attempting to infer sensitive personal attributes;
- respect applicable laws, institutional policies, and platform terms;
- cite the dataset and CTXBench when using it in research outputs.

## License and Terms

This repository contains different types of material with different terms:

- source code and utility scripts are licensed under the repository software license;
- benchmark questions, configurations, metadata, and documentation are licensed under CC BY 4.0 unless otherwise stated;
- curriculum-derived artifacts are provided under the terms described in `DATASET-TERMS.md`.

See:

- `DATASET-TERMS.md`
- `NOTICE.md`
- `CITATION.cff`

## Citation

If you use CTXBench Lattes, please cite the dataset and the associated CTXBench research artifact.

See `CITATION.cff` for citation metadata.
