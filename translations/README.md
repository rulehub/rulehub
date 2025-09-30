# Policy Localization Scheme

This directory stores optional localized descriptions (and future fields) for policies.

Structure:

translations/
  <lang>/
    <policy_id>.yaml

Example policy YAML file fields:

- id: policy id (must match filename)
- description: localized human description
- rationale: (optional) localized rationale / background
- remediation: (optional) localized remediation guidance
- updated: ISO date of last translation update
- source_hash: optional hash (sha256) of canonical English metadata description to detect drift

Process:
1. Add base English metadata under `policies/**/metadata.yaml` (English is canonical).
2. For each target language create `translations/<lang>/<policy_id>.yaml` with overrides.
3. Only include keys that differ from the base; loader overlays on top of base metadata.
4. CI tool can detect missing translations and fallback to English.

Example loader pseudocode:
- Load base metadata index (English)
- For requested lang L (e.g. `Accept-Language`), attempt to open translation file per policy
- Merge mapping: description/rationale/remediation overwritten if present
- Provide `translation_lang` and `translation_fresh` flag if `source_hash` still matches

Missing translation detection script idea: `tools/check_missing_translations.py`.

Future extensions:
- Add pluralization keys
- Add tag/section titles localization

See `translations/en/example.placeholder.yaml` for example.
