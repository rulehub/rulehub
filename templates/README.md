Templates overview

- Policy (OPA/Rego) template: templates/policy/\*

  - metadata.yaml.tmpl - RuleHub metadata for coverage/catalogs
  - policy.rego.tmpl - Rego v1-safe allow/violation pattern
  - policy_test.rego.tmpl - two minimal tests

- Gatekeeper templates: templates/gatekeeper/\*

  - constrainttemplate.yaml.tmpl - define <Kind> and Rego logic
  - constraint.yaml.tmpl - instantiate <Kind> with params and match

- Kyverno template: templates/kyverno/policy.yaml.tmpl

  - ClusterPolicy scaffold; set validationFailureAction and rule match/pattern

- Compliance map template: templates/compliance-map.yml.tmpl
  - Structure for mapping regulation sections to policy IDs

Conventions

- Annotate Gatekeeper/Kyverno manifests with rulehub.id: <domain>.<policy_id>
- Keep IDs consistent with metadata.yaml:id in policies/\*
- (Helm chart synchronization now handled externally in `rulehub/rulehub-charts`).
