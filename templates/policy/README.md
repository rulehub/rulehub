Policy template usage

- Copy this folder structure to policies/<domain>/<policy_id>/
- Replace placeholders in files:
  - <domain> (e.g., fintech, betting, gdpr)
  - <policy_id> (folder-safe, snake_case)
  - <Policy Title>
  - description, standard, links
- Keep the allow/violation pattern with count(violation) == 0 for Rego v1 safety.
- Prefer generic input.controls["<domain>.<policy_id>"] for simple on/off checks; augment with concrete fields as needed while preserving tests.

Quick test scaffold

- policy_test.rego includes two minimal tests. Rename them to test_* to be discovered by opa test.
- Run tests:
  opa test --v0-compatible -v policies/<domain>/<policy_id>
