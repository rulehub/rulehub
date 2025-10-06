# Gatekeeper & Kyverno: guide

This project uses a flat layout (no nested folders). Domain and geo are encoded in the file name and labels.

## Where policies live

- Kyverno: `addons/kyverno/policies/*.yaml`
- Gatekeeper templates: `addons/k8s-gatekeeper/templates/*.yaml`
- Gatekeeper constraints: `addons/k8s-gatekeeper/constraints/*.yaml`

Helm chart mirrors are maintained externally (repository: `rulehub/rulehub-charts`).

## File naming

Pattern: `<domain>.<geo>.<policy-slug>.yaml`

Rules (short):

| Segment     | Format     | Allowed values / notes                                  | Example        |
| ----------- | ---------- | ------------------------------------------------------- | -------------- |
| domain      | lowercase  | k8s, fintech, aml, gdpr, pci, rg, ... (see `policies/`) | k8s            |
| geo         | lowercase  | us, eu, uk, au, in, global                              | eu             |
| policy-slug | kebab-case | short rule identifier                                   | no-run-as-root |

Conventions:

- Only ASCII letters, digits and `-` for `policy-slug`; dots separate filename segments.
- One file = one logical policy (Kyverno/ConstraintTemplate/Constraint may embed multiple underlying rules but they constitute one RuleHub policy).
- Engine is not encoded in the filename - it is inferred from file location (see "Where policies live") and duplicated in labels.

Examples:

- `fintech.eu.psd2-sca.yaml`
- `rg.us.uigea-payment-blocks.yaml`
- `k8s.global.no-run-as-root.yaml`

## Labels (required / recommended)

Add labels under `metadata.labels` for filtering and cataloging. Key labels and value rules:

| Label key           | Required    | Value format    | Source                                           | Example                                                                |
| ------------------- | ----------- | --------------- | ------------------------------------------------ | ---------------------------------------------------------------------- | ------- | -------- | ------------------------------------------------------------------ | ---- |
| rulehub.io/engine   | yes         | kyverno         | gatekeeper                                       | From file location (`addons/kyverno/**` or `addons/k8s-gatekeeper/**`) | kyverno |
| rulehub.io/domain   | yes         | lowercase       | First filename segment                           | k8s                                                                    |
| rulehub.io/geo      | yes         | lowercase       | Second filename segment                          | global                                                                 |
| rulehub.io/id       | yes         | snake_case      | `policy-slug` from filename -> convert `-` to `_` | no_run_as_root                                                         |
| rulehub.io/severity | recommended | info            | low                                              | medium                                                                 | high    | critical | If known; for Kyverno may correlate with `validationFailureAction` | high |
| rulehub.io/owner    | optional    | free text       | Owning team                                      | platform-security                                                      |
| rulehub.io/tags     | optional    | comma-separated | Thematic tags                                    | security,run-as-non-root                                               |

Note:

- `rulehub.io/id` aligns with `id` in `policies/**/metadata.yaml` (see `docs/metadata.md`): snake_case inside the identifier; kebab-case in filename.
- File location determines the engine and resource kind:
  - Kyverno: `addons/kyverno/policies/*.yaml` -> `rulehub.io/engine=kyverno`
  - Gatekeeper ConstraintTemplate: `addons/k8s-gatekeeper/templates/*.yaml` -> `rulehub.io/engine=gatekeeper`
  - Gatekeeper Constraint: `addons/k8s-gatekeeper/constraints/*.yaml` -> `rulehub.io/engine=gatekeeper`

### Label examples

Kyverno (`addons/kyverno/policies/k8s.global.no-run-as-root.yaml`):

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: no-run-as-root
  labels:
    rulehub.io/engine: kyverno
    rulehub.io/domain: k8s
    rulehub.io/geo: global
    rulehub.io/id: no_run_as_root
    rulehub.io/severity: high
```

Gatekeeper ConstraintTemplate (`addons/k8s-gatekeeper/templates/k8s.global.no-run-as-root.yaml`):

```yaml
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: k8srunasnonroot
  labels:
    rulehub.io/engine: gatekeeper
    rulehub.io/domain: k8s
    rulehub.io/geo: global
    rulehub.io/id: no_run_as_root
```

Gatekeeper Constraint (`addons/k8s-gatekeeper/constraints/k8s.global.no-run-as-root.yaml`):

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRunAsNonRoot
metadata:
  name: disallow-root-users
  labels:
    rulehub.io/engine: gatekeeper
    rulehub.io/domain: k8s
    rulehub.io/geo: global
    rulehub.io/id: no_run_as_root
```

## Sync / packaging

Author in `addons/**`; external automation ingests these sources for chart packaging.

## Install the chart

Refer to `rulehub/rulehub-charts` README for installation and configuration (enabling/disabling policy sets, values.yaml options).

## Testing and validation

- Rego (OPA v1):

```bash
opa test policies -v
```

- Metadata validation and coverage:

```bash
make validate && make coverage
```
