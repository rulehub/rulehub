# Changelog

This project follows Keep a Changelog and Semantic Versioning.

## [0.1.0] - 2025-10-06

### Added

- Compliance maps and policy metadata schema with validation (`make validate`, `make validate-maps`).
- Kubernetes policies for Kyverno and Gatekeeper/OPA with tests (`make test-kyverno`, `make test-gatekeeper`, `make test`).
- Policy quality guardrails and coverage metrics (`make policy-test-coverage`, `make policy-test-threshold`).
- Deterministic OPA bundle build and integrity artifacts (`make opa-bundle`, `make opa-bundle-all`).
- Backstage Policy Catalog index generation (`dist/index.json`) for downstream consumption.
- Documentation site (MkDocs) covering architecture, integrity, coverage, and examples.
