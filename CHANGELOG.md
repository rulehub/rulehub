# Changelog

This project follows Keep a Changelog and Semantic Versioning.

## [0.2.0](https://github.com/rulehub/rulehub/compare/v0.1.0...v0.2.0) (2025-10-19)


### Features

* Add Backstage plugin index (docs/schema) and enriched generator; add metadata backfill tool; refresh coverage; tests ([a50d519](https://github.com/rulehub/rulehub/commit/a50d519a2967e2356cfd1cad03d91446115d23d1))


### Bug Fixes

* **tools/analyze_links:** Parse hostname for vendor detection; address CodeQL alert ([2f45e53](https://github.com/rulehub/rulehub/commit/2f45e534a663d30abb1c46b313b0ee4993cef4d2))

## [0.1.0] - 2025-10-06

### Added

- Compliance maps and policy metadata schema with validation (`make validate`, `make validate-maps`).
- Kubernetes policies for Kyverno and Gatekeeper/OPA with tests (`make test-kyverno`, `make test-gatekeeper`, `make test`).
- Policy quality guardrails and coverage metrics (`make policy-test-coverage`, `make policy-test-threshold`).
- Deterministic OPA bundle build and integrity artifacts (`make opa-bundle`, `make opa-bundle-all`).
- Backstage Policy Catalog index generation (`dist/index.json`) for downstream consumption.
- Documentation site (MkDocs) covering architecture, integrity, coverage, and examples.
