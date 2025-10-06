# Policy Test Quality

Gatekeeper policy tests must satisfy:

- 100% dual-direction (each policy has at least one failing deny assertion and one passing scenario)
- 0 multi-rule inadequacies (multi-rule policies have >= one deny assertion per deny rule)

Enforced in CI via `make policy-test-threshold` (see workflow `policy-tests`). Artifacts:

- `dist/policy-test-coverage.json` - machine-readable metrics
- `dist/policy-test-priorities.md` - human improvement summary

Local run:

```bash
make policy-test-coverage
make policy-test-threshold   # runs coverage then enforces thresholds
```

Environment overrides (integer): `REQUIRED_DUAL_PCT` (default 100), `ALLOW_MULTI_INADEQUATE` (default 0).

## Guardrails & Maintenance Pipeline

Additional automated quality gates now exist to keep tests meaningful and avoid regressions:

- `make guardrail-generic-only` - fails if a policy with evidence-based deny logic has only generic control-flag deny tests.
- `make policy-test-pairs` - ensures every `policy.rego` has a `policy_test.rego` and both are listed in metadata `path`.
- `make guardrail-metadata-paths` - forbids bare `path:` lines (requires `path: []` placeholder or concrete list).
- `make link-normalize-check` - asserts link formatting/idempotent normalization.

Aggregate guardrail run (invoked in `release-check`):

```bash
make guardrails
```

## Refactor & Repair Helpers

For large-scale policy evolution there is an end-to-end maintenance target:

```bash
# Dry run refactors + repairs + pruning + normalization
make policy-maintenance

# Apply rewriting/refactors (set APPLY=1)
make policy-maintenance APPLY=1
```

What it does (in order):

1. `refactor-policies` - convert disallowed `not input.foo` patterns to explicit
	`input.foo == false` and (when APPLY=1) regenerate standardized tests.
2. `repair-tests` - fixes corrupted or outdated test formats.
3. `prune-generic-tests` - removes redundant generic-only deny tests when
	evidence-specific ones exist.
4. `normalize-metadata-paths` - ensures empty placeholders are `path: []`.
5. `link-normalize` - (idempotent) link formatting & CELEX canonicalization.


Use these helpers to keep consistency after bulk additions or migrations.
