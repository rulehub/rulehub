# Compliance Maps

This guide describes the purpose, structure, and maintenance rules for compliance map files that link regulation sections to specific policies in the catalog.

- Location: `compliance/maps/*.yml` (one file per regulation/domain)
- Template: `templates/compliance-map.yml.tmpl`
- Validation schema: `tools/schemas/compliance-map.schema.json`
- Validation command: `make validate-maps` or `python3 tools/validate_compliance_maps.py`

## File structure and example

Minimal structure:

```yaml
regulation: PCI DSS           # regulation / domain name
version: '4.0'                # version (string or number)
sections:                     # section key -> object with title and policy list
  '3.4':
    title: Protect stored cardholder data
    policies:
      - pci.storage_encryption
      - pci.ebs_encryption
  '4.2':
    title: Use strong cryptography for transmission
    policies:
      - pci.https_only
```

More examples:

- `compliance/maps/gdpr.yml` — article style keys: `"Art.5(1)(c)"`
- `compliance/maps/pci.yml` — numeric sections: `'3.4'`, `'8.2'`
- `compliance/maps/fintech_us.yml` — textual keys: `"State MTL"`

## Naming: sections and policies

### Section keys (`sections`)

- Key = stable identifier for the regulation section (number, article, marker) (e.g., `"3.4"`, `"Art.5(1)(c)"`, `"State MTL"`).
- If the key contains dots, parentheses, or starts with a number, quote it to prevent YAML auto-conversion.
- Use the canonical citation form from the source regulation; avoid retroactive reformatting (breaks references/diffs).
- `title` = concise human-readable section name (nullable but recommended).

Recommended key styles:

- Articles: `"Art.6"`, `"Art.5(1)(c)"`
- Numeric: `'3.4'`, `'12.10'` (quote to keep precision, avoid float)
- Text groups: `"Workload Security"`, `"State MTL"`

### Policy identifiers (`policies[]`)

Schema-enforced format: `^[a-z0-9_]+\.[a-z0-9_]+$`

- lowercase letters, digits, underscores only
- dot separates namespace and short id

Identifier must match `id` in `policies/**/metadata.yaml`.
Examples: `gdpr.data_minimization`, `pci.storage_encryption`, `fintech.us_mtl_license`.

Deriving id from folder structure (when `metadata.yaml` omits `id`):

- `policies/<namespace>/<short_id>/metadata.yaml` → `<namespace>.<short_id>`

## Validation & tooling

Baseline validation:

- `make validate-maps` or `python3 tools/validate_compliance_maps.py`
- Ensures JSON schema compliance, at least one policy per section, no unknown policy ids.

Duplicate detection/fix within a single map:

- Check: `python3 tools/fix_compliance_map_dupes.py --check`
- Auto-fix: `python3 tools/fix_compliance_map_dupes.py --fix`
- Rule: a policy id must appear at most once (even across different sections). First occurrence kept, later ones removed.

Also run `make validate` which additionally validates policy metadata and file paths.

## Common mistakes & avoidance

1. Unknown policy id

  Cause: id absent from `policies/**/metadata.yaml`.
  Fix: verify spelling/case/underscores; add or correct metadata.

1. Duplicate policy id

  Symptom: validator warning or `--check` output.
  Fix: remove duplicates manually or run `--fix`.

1. Empty or missing `policies` array

  Symptom: warning or schema error.
  Fix: add at least one policy id (placeholder TODO discouraged).

1. Invalid policy id format

  Symptom: schema error.
  Fix: lowercase; replace dashes/spaces with underscores.

1. Unquoted section keys

  Symptom: YAML converts `'3.4'` to float.
  Fix: quote keys with dots/parentheses/leading digits.

1. Inconsistent `regulation` / `version`

  Symptom: divergent naming/versioning styles.
  Recommendation: use canonical regulation name (e.g., `PCI DSS`, `GDPR`); quote versions (`'4.0'`, `'2016/679'`).

1. YAML syntax errors (indentation, duplicate keys)

  Fix: lint before commit; avoid mixing tabs/spaces.

## Maintenance recommendations

- Keep section keys stable for referential changes (reports, catalogs, dashboards).
- Provide meaningful `title` values for readability.
- Consolidate small homogeneous requirements instead of duplicating the same policy across many sections.
- Reuse cross-cutting policies via shared domains (e.g., k8s-baseline) and reference them from individual maps.

## Useful repo references

- Template: `templates/compliance-map.yml.tmpl`
- Schema: `tools/schemas/compliance-map.schema.json`
- Validator: `tools/validate_compliance_maps.py`
- Duplicate remover: `tools/fix_compliance_map_dupes.py`
- Coverage reports: `docs/coverage.md` (Markdown), `dist/coverage.html` (Mermaid/HTML)
