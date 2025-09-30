# Getting Started

This guide shows how to install dependencies, generate coverage, run tests, and optionally publish artifacts.

## Requirements

- Optional: Helm 3.10+ and kubectl (chart now lives in external repo)
- Kyverno and/or Gatekeeper pre‑installed in the cluster (enable only what you need)
- Python 3.11+ and pip (for coverage and index generation)
- Node.js 18+ (for building the Backstage plugin, if used)
- OPA 1.7+ (to run Rego v1 tests) — optional
- ORAS CLI — optional (to publish the OPA bundle to an OCI registry)

## Steps

1. Install dependencies

```bash
make setup-dev
make deps
```

2. Validate metadata/maps and generate coverage

```bash
make validate
make validate-maps  # validate compliance maps schema
make coverage
```

Open `docs/coverage.md` or `dist/coverage.html`.

3. Run Rego tests (Rego v1 syntax)

```bash
opa test policies -v
```

4. (Optional) Build and publish an OPA bundle to OCI

```bash
make opa-bundle
make oras-publish IMAGE=ghcr.io/rulehub/rulehub-bundle TAG=0.1.0
```

### Optional: Local developer checks (parity with CI)

- Tools unit tests (pytest):

```bash
make test-tools
```

<!-- Helm smoke test removed: chart now external -->

## Repository structure (short)

- `addons/**` — Kyverno & Gatekeeper policy YAML (authoring source)
- (Helm chart moved to external repo: rulehub/rulehub-charts)
- `policies/**` — Rego policies (compliance/metadata/tests)
- `compliance/maps/*.yml` — compliance maps for regions/regulations
- `tools/**` — generators, validators (sync helpers removed)
- `docs/**` — documentation and reports

See also: `docs/k8s-policies.md`, `docs/policy-architecture.md`, `docs/README.md`.
