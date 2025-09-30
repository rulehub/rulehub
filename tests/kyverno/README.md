# Kyverno tests

Run locally (requires Kyverno CLI; in devcontainer it's preinstalled):

```
kyverno test tests/kyverno --v=0

# or via Make
make test-kyverno
```

The folders contain kyverno-test.yaml and sample Pods for validate policies:

- block-hostpath
- disallow-latest
- no-privileged
- require-resources

Note: Tests use the cli.kyverno.io/v1alpha1 Test schema (Kyverno CLI v1.15+).
