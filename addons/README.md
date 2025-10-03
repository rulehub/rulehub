# Addons

This directory contains optional Kubernetes policy framework assets derived from the core `policies/` metadata:

- `k8s-gatekeeper/` ConstraintTemplates and Constraints generated/maintained to map RuleHub policy IDs to Gatekeeper enforcement.
- `kyverno/` Kyverno ClusterPolicy / Policy objects implementing selected controls.

Status:

- All Gatekeeper templates use the `deny[msg]` pattern (no `violation[` usage anywhere).
- Kyverno policies are on apiVersion `kyverno.io/v1`.

Conventions:

- File naming: `<domain>-<policy_id>-constrainttemplate.yaml` for Gatekeeper templates; `<domain>-<policy_id>-policy.yaml` for Kyverno.
Regeneration / Sync (planned): automation will verify that every published `policies/<domain>/<policy>/metadata.yaml` with a Kubernetes implementation has a corresponding addon artifact.
