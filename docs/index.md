# RuleHub Documentation

Welcome to the RuleHub documentation. This site aggregates compliance maps, policy bundles, and supporting metadata for multiple domains (FinTech, RegTech, Kubernetes, etc.).

## Quick Start

See [Getting Started](getting-started.md) for local environment setup, validation commands, and how to generate coverage reports.

## What You Will Find Here

- High‑level architecture and metadata model
- Compliance coverage maps and how they are produced
- Framework‑specific guidance (Gatekeeper / Kyverno)
- Security, provenance, and release process notes
- Reference source material attribution

## Repository Structure Snapshot

```text
policies/          # Policy sources (by domain / framework)
compliance/maps/   # YAML compliance coverage maps
addons/            # Distribution-ready policy sets / bundles
tools/             # Validation, coverage, export utilities
docs/              # This documentation content (MkDocs source)
```

## Next Steps

- Read the [Policy Architecture](policy-architecture.md) overview.
- Explore the [Metadata](metadata.md) schema expectations.
- Generate coverage: `make coverage`.

## Contributing

Contribution guidelines are in the root `CONTRIBUTING.md`. Please review before opening a PR.

## Roadmap

Early focus is completeness and provenance of policy references, followed by automated publishing (OPA bundle, OCI distribution, SBOMs, and signatures). See the project TODO for tracked items.
