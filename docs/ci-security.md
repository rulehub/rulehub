# CI & Security

## CI security checks

This repo runs the following workflows:

- Trivy IaC scan: .github/workflows/trivy.yml
- Checkov scan: .github/workflows/checkov.yml
- Secret scanning (TruffleHog): .github/workflows/secrets-scan.yml
- (Removed) internal policy drift check - handled in external Helm chart repo.

How to read results in GitHub:

1. Open the Security tab > Code scanning alerts. You will see tools named "Trivy" and "Checkov". Click an alert to view impacted file, line, and remediation guidance. Use filters (severity, branch, tool) to focus.
2. On a pull request, a short summary comment is posted by Trivy/Checkov. For full details, follow the Security tab link above; PR Checks also show the SARIF upload step.
3. Secret scanning: TruffleHog reports inline in the job logs and will fail the job if verified or likely secrets are found. Click the "Secret Scanning" job in the PR Checks to see matched detectors and locations. Rotate any exposed credentials and force-push a fix if needed.
4. Helm chart policy drift (if any) is validated in the `rulehub-charts` repository CI.

Tips for Trivy/Checkov SARIF views:

- Use "Filter" to narrow by severity (error/warning/note) and by tool.
- Each alert links to the exact file/line; open the "Rule" to see remediation guidance.
- You can suppress false positives at the code level using the tool's ignore annotations where applicable, but prefer fixing misconfigurations.

YAML linting: Helm templates are no longer present in this repository.

## Local execution of GitHub Actions (act)

You can dry‑run or fully execute most workflows locally using the `act` tool. This is useful for quick iteration on workflow YAML before pushing.

Install (macOS):

```bash
brew install act
```

Recommended runtime image mapping (add to `~/.actrc`):

```text
-P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-22.04
```

List jobs that would run for an event:

```bash
act -l
```

Run a workflow (simulate push):

```bash
act push -W .github/workflows/python-tests.yml
```

Run a single job from matrix (example Python 3.11):

```bash
act push -j tests --matrix python-version=3.11 -W .github/workflows/python-tests.yml
```

Skip supply‑chain (OIDC/signing) steps in `opa-bundle-publish` (OIDC not available locally):

```bash
act push -W .github/workflows/opa-bundle-publish.yml -s SKIP_SUPPLYCHAIN=1
```

Provide secrets:

```bash
echo "GH_TOKEN=ghp_xxx" > .secrets
act -s GH_TOKEN=ghp_xxx ...
```

Notes / limitations:

- OIDC (id-token) and keyless cosign signing can't be reproduced; gate those steps with `SKIP_SUPPLYCHAIN` (already supported).
- `GITHUB_TOKEN` permissions differ; don't rely on fine‑grained permission simulation locally.
- Only Linux runner images are emulated.

When to still push a branch / PR:

- Validating GitHub security permissions, id‑token usage, release publishing, Pages deploy.
- Scorecard / codeql workflows (they rely on GitHub backend context).

Quick workflow editing loop:

1. Edit YAML.
2. `act -l` to confirm selection.
3. Run targeted job with `-W` and `-j`.
4. Commit once green locally.

If act becomes slow, prune unused Docker layers occasionally:

```bash
docker system prune -f
```

### Link checking (hard vs soft failures)

The `link-check` workflow retries up to 3 times and classifies final failures:

- Hard failures (non-429 and non-5xx HTTP codes, DNS errors) fail the job.
- Soft failures (HTTP 429 or 5xx) are tolerated after retries but reported in the job summary and artifact (`lychee.json`).

Rationale: transient rate limits and upstream outages shouldn't block unrelated PRs, while genuine 404/410 issues must be fixed promptly.

Local reproduction:

```bash
make link-check-json   # creates lychee.json and classifies
```

Review the uploaded artifact on failed or partially soft-failed runs for details.

### Metadata strict mode locally

The metadata validation workflow runs in strict mode (failing on empty path arrays) automatically for pull requests.
To opt into strict mode for local `act` runs or manual dispatches, export `STRICT_METADATA=1`:

```bash
STRICT_METADATA=1 act push -W .github/workflows/metadata-validate.yml -j validate
```

You can also define a repository or organization variable `STRICT_METADATA=1` to enforce strict mode on all events.
