# Policy-as-Code Architecture (OPA Bundles, OCI, Gatekeeper, Kyverno)

This document specifies how to add, package, publish, and use RuleHub policies as OPA bundles in OCI registries, in Kubernetes (Gatekeeper, Kyverno), and in CI pipelines.

## End-to-end Flow (author → test → bundle → publish → consume)

Figure (text alternative for the following mermaid diagram, for screen readers): The lifecycle proceeds linearly: Author policy (create Rego, metadata, and tests) -> Validate (format, schema) -> Unit tests (opa / kyverno / gatekeeper) -> Build OPA bundle (tar artifact) -> Publish to OCI registry -> Two parallel consumption paths: (a) CI pipelines (conftest / opa eval) and (b) Kubernetes admission controllers (Gatekeeper / Kyverno). This describes how authored policies become consumable artifacts.

```mermaid
flowchart LR
  A[Author policy\n- Rego module(s)\n- metadata.yaml\n- tests] --> B[Validate\n- opa fmt/regal\n- metadata schema]
  B --> C[Unit tests\n- opa test\n- kyverno test\n- conftest (if applicable)]
  C --> D[Build OPA bundle\n- opa build -b policies\n- dist/opa-bundle.tar.gz]
  D --> E[Publish to OCI\n- ORAS push to GHCR\n- mediaType: application/vnd.opa.bundle.layer.v1+tar]
  E --> F[Consume in CI\n- conftest / opa eval\n- IaC checks]
  E --> G[Consume in K8s\n- Gatekeeper (ConstraintTemplate/Constraint)\n- Kyverno (Policy/ClusterPolicy)\n- Optional: OPA sidecar loads bundle]
```

## Repository structure and naming

- Policies live under `policies/<domain>/<policy_id>/`
  - `policy.rego` — Rego module(s)
  - `policy_test.rego` — unit tests for rules
  - `metadata.yaml` — id, title, description, references to standards (PCI/GDPR/etc.), coverage, paths
- Metadata schema under `tools/schemas/policy-metadata.schema.json` (already present)
- K8s integration examples under `addons/`:
  - Gatekeeper ConstraintTemplates and Constraints: `addons/k8s-gatekeeper/{templates,constraints}/*.yaml`
  - Kyverno policies: `addons/kyverno/policies/*.yaml`
- Helm chart for policy sets: external repository (`rulehub/rulehub-charts`)
- Docs: `docs/` (this page, coverage, metadata docs)
- CI workflows: `.github/workflows/**`

Naming conventions:

- Rego package: `package rulehub.<domain>.<policy_id>`
- Policy ID: `<domain>.<slug>`; do not mix kebab/underscore inside the same identifier. Prefer dot-separated package path and snake_case rule names if needed.
- Versioning:
  - Record standard versions (e.g., PCI DSS 4.0) in `metadata.yaml` under `references`.
  - OPA bundle tag: semantic version or a short SHA label. OCI reference example: `oci://ghcr.io/<org>/rulehub-bundle:<tag>`

### Minimal file scaffolds

`policies/<domain>/<policy_id>/policy.rego`

- Contract:
  - Input: depends on use case (e.g., Kubernetes object for admission, or IaC document for CI)
  - Output: decision rules with boolean/objects

Example skeleton:

```rego
package rulehub.k8s.no_run_as_root

default deny := false

deny[msg] {
  input.kind == "Pod"
  some c
  c := input.spec.containers[_]
  not c.securityContext.runAsNonRoot
  msg := "Containers must set securityContext.runAsNonRoot=true"
}
```

`policies/<domain>/<policy_id>/policy_test.rego`

```rego
package rulehub.k8s.no_run_as_root

import data.rulehub.k8s.no_run_as_root as pol

# happy path
test_all_containers_run_as_non_root {
  input := {
    "kind": "Pod",
    "spec": {"containers": [{"securityContext": {"runAsNonRoot": true}}]}
  }
  not pol.deny[_]
}

# violation
test_violation_when_missing_flag {
  input := {
    "kind": "Pod",
    "spec": {"containers": [{"name": "c1"}]}
  }
  count(pol.deny) == 1
}
```

`policies/<domain>/<policy_id>/metadata.yaml` (fields per existing schema; example):

```yaml
id: k8s.no_run_as_root
name: 'K8s: Disallow root user'
version: 1.0.0
owner: platform-security
path:
  - policies/k8s/no_run_as_root/policy.rego
  - policies/k8s/no_run_as_root/policy_test.rego
references:
  - standard: Kubernetes
    section: SecurityContext
  - standard: GDPR
    section: Art. 5(1)(f)
  - standard: PCI DSS
    version: '4.0'
    section: 2.2
```

## Contributor path: Add a policy (step-by-step)

- Create a directory: `policies/<domain>/<policy_id>/`
- Add `policy.rego` following Styra Rego Style Guide (packages, rule naming, comments)
- Add `policy_test.rego` with unit tests (`opa test`)
- Add `metadata.yaml` valid per `tools/schemas/policy-metadata.schema.json`
- Run local checks:
  - Format: `opa fmt -w policies/<domain>/<policy_id>/policy.rego`
  - Validate metadata: `make validate`
  - Unit tests: `opa test -v policies`
- If applicable, add K8s examples in `addons/`; external chart repo manages packaging.
- Update compliance maps in `compliance/maps/*.yml` if this policy contributes to coverage
- Submit PR; CI runs validate → test → bundle (if Rego present) → optionally publish on main

## Consumer path: Use a policy

In CI (IaC validation):

- Pull the bundle from OCI and evaluate against files using Conftest or OPA:

  - Conftest example:

    - Fetch bundle artifact (e.g., using `oras pull` to `dist/opa-bundle.tar.gz`)
    - Run: `conftest test -p dist/opa-bundle.tar.gz path/to/manifests/`

  - OPA example:
    - `opa eval -b dist/opa-bundle.tar.gz -i input.json "data.rulehub.k8s.no_run_as_root.deny"`

In Kubernetes:

- Gatekeeper
  - Apply ConstraintTemplate with embedded Rego, then create Constraint targeting resources
  - Example ConstraintTemplate (excerpt):

```yaml
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: k8srunasnonroot
spec:
  crd:
    spec:
      names:
        kind: K8sRunAsNonRoot
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srunasnonroot
        violation[{"msg": msg}] {
          some c
          c := input.review.object.spec.containers[_]
          not c.securityContext.runAsNonRoot
          msg := "Containers must set securityContext.runAsNonRoot=true"
        }
```

- Example Constraint:

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRunAsNonRoot
metadata:
  name: disallow-root-users
spec:
  match:
    kinds:
      - apiGroups: ['']
        kinds: ['Pod']
```

- Kyverno

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-root-users
spec:
  validationFailureAction: enforce
  rules:
    - name: disallow-root
      match:
        any:
          - resources:
              kinds: [Pod]
      validate:
        message: 'Containers must set securityContext.runAsNonRoot=true'
        pattern:
          spec:
            containers:
              - securityContext:
                  runAsNonRoot: true
```

Optional runtime OPA: configure OPA sidecar to pull bundles from OCI registry as a bundle source (see OPA docs) and evaluate decisions through its API.

## Make/CI steps (validate → test → bundle → publish)

Make targets (see repo `Makefile`):

- `make validate` — validate metadata against JSON Schema
- `make test` — run Kyverno and Gatekeeper tests
- `make opa-bundle` — build `dist/opa-bundle.tar.gz` from `policies/` (if `.rego` files exist)
- `make oras-publish IMAGE=ghcr.io/<org>/rulehub-bundle TAG=<tag>` — publish the bundle to OCI with correct mediaType

GitHub Actions workflow `.github/workflows/opa-bundle-publish.yml` publishes on pushes to `main` and releases.

## Rego Style Guide (Repository Conventions)

This repository locks in a subset of the Styra / community style plus additional safety constraints aligned with Rego v1 parsing rules enforced by our current OPA version.

Goals:

- Deterministic parsing across OPA minor upgrades
- Readable, uniform violation structure
- Early surfacing of logic errors (parse/type) before bundle build

### Mandatory Patterns

1. Atomic deny rules

Prefer multiple small `deny["<id>"]` or `deny[msg]` (fixed message form) rules over one large rule with boolean chains.

2. Control (allow) rule

Pattern for policies using an `allow` decision:

```rego
package rulehub.<domain>.<policy_id>

deny["<short_reason>"] { <atomic condition 1> }
deny["<other_reason>"] { <atomic condition 2> }

# Allow when nothing denied
allow if count(deny) == 0
```

Alternative boolean default (`default allow := true` then set `allow := false`) is discouraged for consistency.

3. Formatting

All Rego sources must pass `opa fmt` (pre-commit `opa-fmt`, CI quick check).

4. Package naming

`package rulehub.<domain>.<policy_id>` (lowercase, dotted). No hyphens inside segments.

5. Tests colocated

`policy_test.rego` MUST use same package (and may alias: `import data.rulehub.<domain>.<policy_id> as pol`).

### Prohibited constructs (auto-scanned)

The quick check (`make opa-quick-check` and workflow `opa-quick-check.yml`) fails on these textual patterns:

- `(not` — Parenthesized negation grouping inside composite boolean expressions.
- `and not` — Inline conjunction + negation; expand to separate rule or explicit equality lines.
- `not (` — Leading `not` applied to grouped expression containing `and` / `or`.
- `not in {` — Negated membership; rewrite as chained inequalities or explicit whitelist set.

Rationale: Older / stricter Rego parser modes and future optimizations reject or mis-handle certain parenthesized negations; splitting conditions keeps each violation predicate simple and avoids hidden precedence errors.

### Rewrite examples (`violation[...]` → `deny[...]`)

Anti-pattern:

```rego
violation[msg] { (not input.enabled) or (not input.flag); msg := "..." } # example
```

Preferred:

```rego
deny["feature_disabled"] { input.enabled == false }
deny["flag_missing"] { input.flag == false }
```

Anti-pattern:

```rego
deny { input.a and not input.b }
```

Preferred:

```rego
deny["b_missing_when_a"] { input.a == true; input.b == false }
```

Anti-pattern:

```rego
violation { not (input.x and input.y) }
```

Preferred: separate violations (one per missing predicate) or explicit positive checks then count(violation)==0 for allow.

Anti-pattern:

```rego
input.status not in {"A","B"}
```

Preferred:

```rego
input.status != "A"
input.status != "B"
```

or

```rego
allowed := {"A","B"}
not allowed[input.status]
```

### Test style

Each test case should:

- Create a self-contained `input := {...}` object (no reliance on global state)
- Assert absence/presence of denies explicitly (`not pol.deny[_]` or `count(pol.deny) == N`)
- Cover at least one happy path and one failing path per policy

### Deny rule normalization patterns

1. Split disjunctions (OR) across separate `deny[...]` rules.
2. Convert `A and not B` into a single deny block listing both atomic lines (`A == true` and `B == false`).
3. Replace negated group `not (A and B and C)` with multiple atomic deny rules (one per missing/false predicate) unless semantic meaning differs.
4. Replace `X not in { ... }` with either explicit inequalities or a positive membership check plus `not` on the set (`allowed[X]` pattern) — but avoid negative set membership in a single expression.

### Tooling enforcement

| Check                   | Mechanism                             | Invocation                |
| ----------------------- | ------------------------------------- | ------------------------- |
| Formatting              | `opa fmt -l` via pre-commit `opa-fmt` | `pre-commit run opa-fmt`  |
| Forbidden patterns      | grep scan (see Makefile)              | `make opa-quick-check`    |
| Parse/type errors       | `opa check policies`                  | `make opa-quick-check`    |
| deny[] rule usage scan | `tools/deny_usage_scan.py`  | (add to CI before bundle) |
| Unit tests              | `opa test` / `make test-gatekeeper`   | CI & local                |

Violations of style should be fixed in-place rather than waived.

## Quality checklists

Rego

- Formatted (`opa fmt`), optional `regal` lint
- Clear package names: `rulehub.<domain>.<policy_id>`
- Tests cover happy path and violations; no magic constants without context

Metadata

- Valid per schema; `path` includes all relevant files
- References to standards include version/section where possible

Bundle

- Built via `opa build -b policies -o dist/opa-bundle.tar.gz`
- Contents verified with `tar tzf dist/opa-bundle.tar.gz`
- Media type used for OCI: `application/vnd.opa.bundle.layer.v1+tar`

Publication

- ORAS push uses semantic or SHA tags
- Artifact annotated with repository and commit information

Kubernetes

- Gatekeeper: provide `ConstraintTemplate` and `Constraint` examples with parameter schema where needed (use `deny[msg]`; avoid `violation[...]`)
- Kyverno: `validationFailureAction` set appropriately; include test fixtures if applicable

## References (primary sources)

- OPA Bundles & distribution
  - [OPA Bundles](https://www.openpolicyagent.org/docs/latest/management-bundles/)
  - [ORAS CLI](https://oras.land/) (ORAS CLI)
- Rego Style Guide
  - [Styra Rego Style Guide](https://www.styra.com/opa-rego-style-guide/)
- Gatekeeper
  - [Gatekeeper](https://open-policy-agent.github.io/gatekeeper/website/)
- Kyverno
  - [Kyverno](https://kyverno.io/docs/)
- Conftest
  - [Conftest](https://www.conftest.dev/)
