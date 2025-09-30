# Policy metadata schema

This repository stores metadata for policies in `policies/<standard>/<id>/metadata.yaml`.

Required fields:

- id: `<namespace>.<id>` (e.g. `pci.storage_encryption`, `k8s.no_privileged`)
- name: human-readable policy name
- standard: either a string (e.g. `pci`) with a separate `version`, or an object `{ name, version }` (e.g. `{ name: "PCI DSS", version: "4.0" }`)
- version: version of the standard/domain (required for flat form; omitted if using nested `standard`)
- path: string or list of strings with relative paths to actual policy files
- geo: geographic scoping (now mandatory)

Optional fields:

- description: short description
- framework: kyverno | gatekeeper | k8s | other
- severity: info | low | medium | high | critical
- tags: string array
- owner: team or owner identifier
- links: array of URLs

Geo block (required):

- regions: [string] (>=1)
- countries: [string] (>=1; may include "*" for global applicability)
- subregions: [string] (optional)
- scope: string (summary of applicability, e.g. Global, EU, Multi-region)


Validation:

- JSON Schema: `tools/schemas/policy-metadata.schema.json`
- Local: pre-commit hook `metadata validate` checks schema and that paths exist
- CI: workflow `metadata-validate.yml` runs the same checks on PRs/pushes
- Uniqueness & referential integrity:
  - IDs must be unique across the repository; the validator fails on duplicates.
  - Compliance maps (`compliance/maps/*.yml`) must only reference known policy IDs in their `sections.*.policies` lists; unknown IDs cause the maps validator to fail.

Conventions:

- IDs use lowercase and underscores, `<namespace>.<short_id>`
- `path` should reference files under `addons/**` (Helm chart mirrors are now maintained externally)
- For Kyverno policies, severity is inferred from `spec.validationFailureAction` if not set
- For Gatekeeper, severity defaults to medium; if corresponding `constraints/` exist, treated as high

## Referencing policy files in `path`

- Use one or more concrete, existing file paths (no globs). The validator checks `os.path.exists` for each entry.
- Typical locations by framework:
  - Kyverno: `addons/kyverno/policies/<policy>.yaml`
  - Gatekeeper templates: `addons/k8s-gatekeeper/templates/<policy>.yaml`
  - Gatekeeper constraints: `addons/k8s-gatekeeper/constraints/<policy>.yaml`
  - Other/custom domains: define a clear convention under `addons/<domain>/<area>/<policy>.yaml`.

Examples

Flat standard/version form:

```yaml
id: pci.storage_encryption
name: Storage Encryption
standard: pci
version: "4.0"
path:
  - addons/kyverno/policies/storage-encryption.yaml
```

Nested standard with geo:

```yaml
id: fintech.pci_mfa_required
name: PCI DSS — MFA Required
standard:
  name: PCI DSS
  version: "4.0"
geo:
  regions: [Global]
  countries: ["*"]
  scope: Global
path: [] # placeholder until implementation exists
```

Example (single authoritative source path):

```yaml
path:
  - addons/kyverno/policies/no-privileged.yaml
```

## Empty `path` placeholders and strict mode

- While a policy is only planned and has no implementation files, keep `path: []` as a placeholder. This yields a warning in the validator.
- To enforce fail-fast on empty paths, enable strict mode:
  - Environment variable: `STRICT_EMPTY_PATHS=1`
  - Make target: `make validate-strict`

Notes:

- Do not set future/globbed paths (e.g., `addons/**`) — they will fail validation until real files exist and globs are not expanded by the validator.
- Prefer adding only the `addons/**` source path; external chart repo handles mirroring.

## Severity and tags conventions (adjust after implementation)

Until a concrete implementation exists, non-framework policies may use:

- `framework: other`
- `severity: medium`
- `tags: ["pci"|"gdpr"|"amld"]`
- `owner: compliance`

When adding a real policy, adjust `severity` and extend `tags` by topic. Examples:

- Encryption at rest (e.g., storage/volume encryption): `high` or `critical`; tags: `encryption`, `data-at-rest`, `storage`
- Encryption in transit / HTTPS-only: `high`; tags: `tls`, `https`, `network`
- IAM password policy / strong auth: `high`; tags: `iam`, `auth`, `password-policy`
- Logging & monitoring: `medium`–`high`; tags: `logging`, `monitoring`, `audit`
- GDPR data retention: `high`; tags: `privacy`, `retention`, `storage-limitation`
- GDPR data minimization: `medium`–`high`; tags: `privacy`, `data-minimization`
- AML sanctions/PEP screening, EDD: `high`; tags: `sanctions`, `pep`, `screening`, `edd`
