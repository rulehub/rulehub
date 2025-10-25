## RuleHub — Open Guardrails for ML & LLM Systems

[![CodeQL](https://github.com/rulehub/rulehub/actions/workflows/codeql.yml/badge.svg)](https://github.com/rulehub/rulehub/actions/workflows/codeql.yml)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/rulehub/rulehub/badge)](https://securityscorecards.dev/viewer/?uri=github.com/rulehub/rulehub)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> **Open-source guardrails and Policy-as-Code for ML & LLM systems — safety, compliance, and reproducibility in one framework.**

> **Developer-first Policy-as-Code framework** for securing and auditing **AI pipelines** —
> from classical ML training to LLM guardrails, with supply-chain integrity, compliance mapping,
> and reproducible evidence for trustworthy AI.

---

## Overview

**RuleHub** unifies safety, security, and compliance for AI systems.
It brings together policies (OPA / Kyverno), compliance mappings, tests, and signed bundles into a single reproducible workflow.

RuleHub connects:

- **Policy-as-Code:** encode safety and regulatory requirements as reusable policies.
- **MLSec module:** dataset, model, and training pipeline security.
- **LLMSec module:** prompt and output guardrails for LLM/RAG systems.
- **Compliance layer:** EU AI Act, NIST AI RMF, ISO 42001 mappings.
- **Observability:** Prometheus / OpenTelemetry metrics and evidence trails.

---

## What RuleHub does

| Problem                                   | How RuleHub helps                          |
| ----------------------------------------- | ------------------------------------------ |
| Fragmented AI security & compliance tools | Unified Policy-as-Code workflow            |
| Manual reviews & audits                   | Automated, testable policies with CI gates |
| Missing AI supply-chain visibility        | SBOM / AIBOM + cosign-signed artifacts     |
| No reproducible evidence trail            | Provenance and compliance exports          |
| Lack of developer-friendly guardrails     | Open, YAML-based policies and SDKs         |

<p align="center">
  <img src="docs/assets/value-loop.svg" alt="RuleHub value loop" width="760"/>
</p>

## Who it's for

- Security and Compliance teams needing fast, defensible audit evidence.
- Platform/DevOps teams standardizing cluster guardrails across tenants.
- Product teams in regulated spaces (fintech, health, gaming, education) where policy regressions are risky.

## Key features

- **Policy-as-Code** — Kyverno / OPA / Rego rules, tests, coverage reports.
- **AI Supply-Chain Security** — SBOM / AIBOM generation, cosign signatures, provenance.
- **ML & LLM Guardrails** — dataset integrity, prompt filtering, data-leak policies.
- **Compliance Automation** — EU AI Act / NIST RMF / ISO 42001 mappings.
- **Observability & Evidence** — OpenTelemetry metrics, Grafana dashboards.
- **Integration Ready** — Helm charts, Backstage plugin, CI/CD pipelines.

## Screenshots & examples

> Replace or augment with your own product shots as the project evolves.

- Example compliance map (YAML):

```yaml
id: CM-001
title: 'Network segmentation requirement'
controls: ['CIS-1.1']
owners: ['security@example.com']
policies:
  - kyverno/network-segmentation
```

- Example Kyverno snippet (illustrative):

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-immutable-tags
spec:
  rules:
    - name: block-latest-tag
      match:
        resources:
          kinds: [Pod]
      validate:
        message: "Images must not use the 'latest' tag."
        pattern:
          spec:
            containers:
              - image: '!*:latest'
```

- Example Gatekeeper/Rego snippet (illustrative):

```rego
package kubernetes.admission

deny[msg] {
  input.review.object.kind == "Pod"
  some c
  c := input.review.object.spec.containers[_]
  endswith(c.image, ":latest")
  msg := "Images must not use the 'latest' tag."
}
```

## 🏗 Architecture

```text
                 ┌───────────────────────────┐
                 │     RuleHub Core          │
                 │  Policy Engine + Tests    │
                 │  (OPA / Kyverno)          │
                 └────────────┬──────────────┘
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
   ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
   │  MLSec       │     │  LLMSec      │     │  Compliance  │
   │  Training &  │     │  Guardrails  │     │  Mappings    │
   │  Model rules │     │  for LLMs    │     │  (AI Act etc)│
   └──────────────┘     └──────────────┘     └──────────────┘
                              │
                 ┌────────────┴────────────┐
                 │ Observability & Reports │
                 │  (Grafana / OTel / CI)  │
                 └──────────────────────────┘
```

- Architecture (high-level):

  <img src="docs/assets/architecture-overview.svg" alt="Architecture" width="760"/>

---

## Minimal quick start

This is a tiny fast-path to see the repo structure and run a basic validation. For a full walkthrough, head to the docs.

1. Clone and enter the repository

```bash
git clone https://github.com/rulehub/rulehub.git
cd rulehub
```

1. Create a virtualenv and install dependencies

```bash
make setup-dev
make deps
```

1. Validate maps and metadata

```bash
make validate
```

Optional next steps:

- Run policy tests: `make test`
- Build docs locally: `make docs-serve`

## Learn more

- Getting started: docs/getting-started.md
- Architecture & policy model: docs/policy-architecture.md
- Metadata & compliance maps: docs/metadata.md and docs/compliance-maps.md
- Integrity, SBOM, signing: docs/security-integrity.md and docs/security-provenance.md
- Policy quality & coverage: docs/policy-test-quality.md and docs/coverage.md

## Backstage Plugin Index

The RuleHub Backstage Plugin consumes a published JSON index describing available policies and metadata.

- Canonical JSON: [plugin-index/index.json](https://rulehub.github.io/rulehub/plugin-index/index.json)
- HTML preview: [plugin-index/index.html](https://rulehub.github.io/rulehub/plugin-index/index.html)

Notes:

- The index is rebuilt and published on every push to `main` via GitHub Actions.
- The JSON is validated against `tools/schemas/plugin-index.schema.json` during CI; invalid schemas fail the workflow.

## Roadmap

| Milestone | Target                                                        | Artifacts                                                      |
| --------- | ------------------------------------------------------------- | -------------------------------------------------------------- |
| **M1**    | Core release + policy framework, Helm chart, Backstage plugin | `rulehub`, `rulehub-charts`, `rulehub-backstage-plugin`        |
| **M2**    | MLSec / LLMSec modules + AIBOM support                        | `rulehub-mlsec`, `rulehub-llmsec`                              |
| **M3**    | Cloud registry + telemetry agent + docs site                  | `rulehub-cloud`, `rulehub-observability-agent`, `rulehub-docs` |

## Repository Structure

| Repo                                                                                    | Purpose                             |
| --------------------------------------------------------------------------------------- | ----------------------------------- |
| [`rulehub/rulehub`](https://github.com/rulehub/rulehub)                                 | Core Policy-as-Code engine          |
| [`rulehub-charts`](https://github.com/rulehub/rulehub-charts)                           | Helm charts and release bundles     |
| [`rulehub-backstage-plugin`](https://github.com/rulehub/rulehub-backstage-plugin)       | Backstage UI plugin                 |

---

## Contributing

Contributions and issues are welcome. Please read [Contributing Guide](CONTRIBUTING.md) and [Code of Conduct](CODE_OF_CONDUCT.md) before opening PRs.

## License

License: MIT - see LICENSE.
