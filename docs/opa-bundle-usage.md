# Using the OPA Bundle in a Kubernetes Admission Controller

The RuleHub OPA bundle (`dist/opa-bundle.tar.gz`) packages all Rego policies for cluster or CI evaluation. You can consume it directly in an admission controller deployment (standalone OPA or OPA + kube-mgmt) or via an OCI registry.

## 1. Obtain & Verify

Option A (Release assets): download `opa-bundle.tar.gz` plus its `.sig`, `.pem`, and `opa-bundle.manifest.json`.

```bash
COSIGN_EXPERIMENTAL=1 cosign verify-blob \
  --signature dist/opa-bundle.tar.gz.sig \
  --certificate dist/opa-bundle.tar.gz.pem \
  dist/opa-bundle.tar.gz

python tools/verify_bundle.py \
  --manifest dist/opa-bundle.manifest.json \
  --bundle dist/opa-bundle.tar.gz \
  --policies-root policies \
  --bundle-sig dist/opa-bundle.tar.gz.sig \
  --bundle-cert dist/opa-bundle.tar.gz.pem
```

Option B (OCI):

```bash
oras pull ghcr.io/rulehub/rulehub-bundle:vX.Y.Z -o dist/
COSIGN_EXPERIMENTAL=1 cosign verify ghcr.io/rulehub/rulehub-bundle:vX.Y.Z
```

## 2. Deploy OPA

ConfigMap referencing bundle over HTTPS (release URL or internal proxy):

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: opa-config
  namespace: opa
data:
  config.yaml: |
    services:
      rulehub:
  url: https://github.com/rulehub/rulehub/releases/download/vX.Y.Z
    bundles:
      rulehub:
        service: rulehub
        resource: opa-bundle.tar.gz
        polling:
          min_delay_seconds: 60
          max_delay_seconds: 120
```

Deployment (excerpt):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: opa
  namespace: opa
spec:
  replicas: 2
  selector:
    matchLabels:
      app: opa
  template:
    metadata:
      labels:
        app: opa
    spec:
      serviceAccountName: opa
      volumes:
        - name: opa-config
          configMap:
            name: opa-config
      containers:
        - name: opa
          image: openpolicyagent/opa:latest
          args:
            [
              'run',
              '--server',
              '--config-file=/config/config.yaml',
              '--addr=0.0.0.0:8181',
              '--diagnostic-addr=0.0.0.0:8282',
            ]
          volumeMounts:
            - name: opa-config
              mountPath: /config
          readinessProbe:
            httpGet:
              path: /health?bundles
              port: 8181
          livenessProbe:
            httpGet:
              path: /health
              port: 8181
```

Admission webhooks call OPA with the AdmissionReview as input; deny reasons surface from `data.rulehub.<domain>.<policy>.deny` arrays.

## 3. Local Evaluation Example

```bash
opa eval -b dist/opa-bundle.tar.gz -i input.json \
  "data.rulehub.k8s.no_run_as_root.deny"
```

## 4. Security Practices

- Always verify cosign signature before promotion.
- Pin OCI by digest (tag@sha256) in production.
- Keep manifest + SBOM alongside the bundle for offline re-check.

More detail: `docs/opa-bundle-format.md`, `docs/security-integrity.md`, `docs/security-provenance.md`.
