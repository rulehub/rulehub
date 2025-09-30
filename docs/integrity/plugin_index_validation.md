# Backstage Plugin Index Validation

This document describes the `plugin_index_validate.py` tool which validates the Backstage plugin index (`dist/index.json`) against the repository JSON Schema (`tools/schemas/plugin-index.schema.json`).

## Purpose

The Backstage Policy Catalog plugin consumes a canonical index at `dist/index.json`. This tool ensures the generated index adheres to the expected schema and produces a small integrity report suitable for CI or human review.

## Location

- Tool: `tools/plugin_index_validate.py`
- Schema: `tools/schemas/plugin-index.schema.json`
- Index (generated): `dist/index.json`
- Reports (generated): `dist/integrity/plugin_index_validation.md` and `dist/integrity/plugin_index_validation.json`

## Acceptance

- When the index is valid the tool exits 0 and prints "Schema valid". The markdown report contains the single line `Schema valid`.
- When invalid the tool exits 2, prints a short list of JSON Pointer locations and error messages, and writes a markdown report enumerating errors. The JSON file includes the error objects with `pointer`, `message`, and `instance` fields.

## Usage

From repository root:

```bash
python3 tools/plugin_index_validate.py
```

Optional flags:

- `--schema` — path to JSON Schema (default: `tools/schemas/plugin-index.schema.json`)
- `--index` — path to index JSON (default: `dist/index.json`)
- `--out-md` — path to markdown report (default: `dist/integrity/plugin_index_validation.md`)
- `--out-json` — path to JSON errors output (default: `dist/integrity/plugin_index_validation.json`)
- `--no-json` — skip writing the JSON errors file

Example (custom paths):

```bash
python3 tools/plugin_index_validate.py --index dist/index.json --schema tools/schemas/plugin-index.schema.json
```

## CI integration

The repository already contains a lightweight schema validation step in `.github/workflows/coverage.yml` which imports `jsonschema` and runs validation inline. The `plugin_index_validate.py` tool produces the same validation results plus a human-friendly markdown artifact under `dist/integrity` suitable for upload as a CI artifact.

To add the tool to CI, call it after `make catalog`/index generation and upload `dist/integrity/plugin_index_validation.md` as an artifact.

## Troubleshooting

- If you see `Missing file: dist/index.json` ensure the catalog/index generation step ran (`make catalog` or `python3 tools/coverage_map.py`).
- If `jsonschema` is not installed, install it in your environment (`pip install jsonschema`) or let CI install requirements.

## Notes

- The tool uses Draft-07 validation to match the schema's `$schema` declaration.
- Reports use JSON Pointer-like paths (e.g., `/packages/3/id`) to help locate errors inside the index.
