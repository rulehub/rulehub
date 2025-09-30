# Gatekeeper tests

Two ways to check locally:

1. With OPA unit tests (fast, no cluster):

- Install opa: https://www.openpolicyagent.org/docs/latest/#running-opa
- Run from repo root:

```
opa test tests/gatekeeper/policies tests/gatekeeper/tests -v
```

Or via Make (devcontainer already has opa installed):

```
make test-gatekeeper
```

2. With Gatekeeper dry-run (requires a cluster with Gatekeeper):

- Apply templates from `addons/k8s-gatekeeper/templates/` and constraints from `addons/k8s-gatekeeper/constraints/`.
- Then try manifests under `tests/gatekeeper/manifests/`:

```
kubectl apply --dry-run=server -f tests/gatekeeper/manifests/pod-hostnetwork.yaml
kubectl apply --dry-run=server -f tests/gatekeeper/manifests/pod-ok.yaml
```

The first should be denied; the second should pass.
