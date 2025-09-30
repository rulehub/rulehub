# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project adheres to Semantic Versioning.

## [Unreleased]

### Added

- OPA bundle build (`make opa-bundle`) and publish to OCI via ORAS (`make oras-publish`).
- Backstage Policy Catalog plugin: JSON index generation (`dist/index.json`). The plugin package is maintained in a separate repository.
- Metadata validation and coverage artifacts (`make validate`, `make coverage`).
- Kyverno and Gatekeeper tests (`make test-kyverno`, `make test-gatekeeper`).
- Helm chart for policy sets (`charts/policy-sets`), package and push to OCI.

## [0.1.0] - 2025-08-16

### Added

- Initial release with:
  - Compliance maps and metadata schema.
  - Kubernetes policies (Kyverno and Gatekeeper) and Helm chart packaging.
  - OPA bundle build support.
  - Backstage plugin (policy catalog) JSON index generation; plugin package lives in a separate repo.
  - Validation, coverage, and sample tests.
