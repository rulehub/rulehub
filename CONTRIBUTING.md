# Contributing Guide

Thank you for helping improve RuleHub! This guide lists concise rules and conventions that speed up reviews and
improve quality. The canonical brand is "RuleHub" (single word, capital R and H); avoid variants like "Rule Hub"
except in technical lowercase identifiers (`rulehub` in package paths, image names, labels).

## Quick Start

1. Fork the repository and create a branch: feature/..., fix/... or docs/...

1. Install tooling:

- Python & virtual env: `make setup-dev`
- Runtime dependencies: `make deps`
- Install pre-commit hooks: `make pre-commit-install`

1. Run local checks:

- YAML lint: `make lint-yaml`
- Python lint (tools): `make lint-py`
- Python format (optional): `make format-py`
- Kyverno tests: `make test-kyverno`
- Gatekeeper/OPA tests: `make test-gatekeeper`
- Full test suite: `make test`

- Full local verification (lint + tests + coverage + links): `make verify-all`
- Docs/style: markdownlint, Vale, cspell (run automatically via pre-commit)
- Rego style & deny[] rule usage scan: `make opa-quick-check` and `make deny-usage-scan`

## What You Can Improve

- Policies in `policies/` and `addons/` (Gatekeeper / Kyverno)
- Documentation in `docs/`
- Tooling in `tools/` (Python utilities)

## Style & Requirements

- YAML: follow existing templates, naming, and metadata schema. Run `make validate`.
  - Every policy metadata now requires a `geo` block with at least one region & country and a `scope` summary.
- Python: follow Ruff guidance; remove unused code.
- Commits: use clear messages. Conventional style prefixes like feat:, fix:, docs:, chore: are encouraged.
  - Breaking changes: add `!` after type (e.g. `feat!:`) or a `BREAKING CHANGE:` footer.
- Pull Requests: short problem statement, list of changes, link to issue (if any), brief test plan.

## Testing

- Kyverno: test cases in `tests/kyverno/`.
- Gatekeeper: test cases in `tests/gatekeeper/`.
- Ensure `make test` passes before opening a PR.
- Run `pre-commit run --all-files` before pushing to catch docs/style issues.

## Review Process

- All changes go via PR and at least one review.
- A maintainer may request changes or propose alternatives.
- After approval: prefer squash merge (unless multiple commits add clarity).

## Tooling Summary

| Area              | Enforcement                                          |
| ----------------- | ---------------------------------------------------- |
| Rego formatting   | `opa fmt` (pre-commit)                               |
| deny[] rule usage | `make deny-usage-scan` (CI + hook)                   |
| Docs build        | GitHub Action `docs-build` (`mkdocs build --strict`) |
| Links             | Scheduled + PR link checker (`lychee`)               |
| Markdown style    | markdownlint (pre-commit)                            |
| Language style    | Vale (pre-commit)                                    |
| Spelling          | cspell (pre-commit)                                  |
| Python            | Ruff (lint/format), mypy                             |
| Compliance maps   | Schema + duplicate check hooks                       |
| References idx    | Auto-generation hook (`refs-index`)                  |

If a hook fails, fix the underlying issue instead of skipping it.

### CI image tag resolution (one place)

RuleHub GitHub Actions workflows run inside container images published from
`rulehub-ci-images` (ci-base, ci-policy, ci-charts, ci-frontend). To avoid
editing many YAML files when bumping the immutable tag, tag resolution is
centralized via a composite action:

- `.github/actions/resolve-ci-image/action.yml`
  - Inputs: `ci_image_tag` (optional), `kind` (`base|policy|charts|frontend`)
  - Resolution order: `inputs.ci_image_tag` → repository/org variable `CI_IMAGE_TAG` →
    pinned fallback inside the action
  - Outputs: `image` (e.g., `ghcr.io/<owner>/ci-base:<tag>`), `tag`

How to change the CI image tag:

1. Preferred: set repo/org variable `CI_IMAGE_TAG` to the new immutable tag
   (e.g., YYYY.MM.DD-<sha> or vX.Y.Z). No workflow edits needed.
2. Fallback pin: update the single default in
   `.github/actions/resolve-ci-image/action.yml` if you need a hardcoded safe
   default.

Integrity & immutability rules:

- Tags must be immutable (either semantic `vX.Y.Z` or time-based `YYYY.MM.DD-<shortsha>`).
- Do not push different image contents under an existing tag.
- All CI images embedding third-party CLIs (OPA, Kyverno, etc.) MUST verify
  SHA256 during build. Checksums live under `rulehub-ci-images/ci-checksums/`
  and are added in the same PR as a version bump.

Local act usage:

- Under `act` you may override by passing `CI_IMAGE_TAG=dev-local` and mapping
  the local dev image to latest (e.g.
  `-P ghcr.io/rulehub/ci-policy:latest=ghcr.io/rulehub/ci-policy:dev-local`)
  to speed iteration.
- The guard workflow allows `dev-local` only when `ACT` environment flag is set.

Local performance threshold (`maxSeconds` warnings in act): if you see warnings
like `observed 23s > maxSeconds=9s`, update your local act runner config (not
stored in this repo) to reflect current baseline or re-run with an adjusted
`--max-seconds` flag.

A growing set of workflows already use this action (e.g.,
`policy-tests.yml`, `opa-bundle-publish.yml`, `link-audit.yml`). When adding
new workflows, depend on the resolver instead of hardcoding tags.

Reusable workflow (recommended):

- Use `./.github/workflows/resolve-ci-image.yml` via `workflow_call` to both
  guard tags and resolve the image in one place. It exposes `image` and `tag`
  outputs. For multi-image workflows (e.g., base + policy), invoke it twice
  with different `kind` values.
- If existing jobs already reference `needs.resolve.outputs.image`, add a tiny
  passthrough job to re-expose the reusable workflow outputs under your
  preferred job name to minimize churn.

Example shape (simplified):

```yaml
jobs:
  guard:
    uses: ./.github/workflows/resolve-ci-image.yml
    with:
      ci_image_tag: ${{ inputs.ci_image_tag }}
      kind: base

  resolve:
    needs: guard
    runs-on: ubuntu-latest
    outputs:
      image: ${{ steps.out.outputs.image }}
    steps:
      - id: out
        run: |
          echo "image=${{ needs.guard.outputs.image }}" >> "$GITHUB_OUTPUT"

  run-something:
    needs: [resolve]
    container:
      image: ${{ needs.resolve.outputs.image }}
```

This keeps a single guard/resolve implementation while preserving existing
`needs.resolve.outputs.*` references.

### Updating documentation tool versions

Site build dependencies are pinned in `requirements-docs.txt` for reproducibility. To update:

1. Bump versions deliberately (e.g. `mkdocs==1.6.1`, `mkdocs-material==9.5.x`).
2. Run `pip install -r requirements-docs.txt` and `mkdocs build --strict` locally.
3. Review visual changes via `mkdocs serve`.
4. Commit the version bump and open a PR referencing any notable upstream changes.

### Python dependency locking

We maintain two lock files generated by pip-tools with hashes for supply chain integrity:

| Source file            | Lock file               | Command         |
| ---------------------- | ----------------------- | --------------- |
| `requirements.txt`     | `requirements.lock`     | `make lock`     |
| `requirements-dev.txt` | `requirements-dev.lock` | `make lock-dev` |

Rules:

1. Always run `make lock lock-dev` after editing either source requirements file.
2. Commit updated `*.lock` files in the same PR as the `*.txt` changes.
3. CI workflow `python-lock-verify` will fail if locks are stale.
4. A weekly scheduled workflow opens an automated PR refreshing the locks;
   review for major version jumps before merging.
5. Consumers installing locally / CI prefer the lock files when present to ensure reproducible, hash-verified installs.

Security note: Lock files include hashes (`--generate-hashes`) so pip will
verify downloaded packages. If a supply chain alert requires pinning a
specific version, update the source `.txt`, regenerate, and merge promptly.

### Canonical CI scripts (preferred helpers)

Use these scripts from workflows to keep logic consistent and DRY:

- Docs build: `.github/scripts/mkdocs-build.sh`
- GHCR probe: `.github/scripts/ghcr-probe.sh`
- Python env (venv): `.github/scripts/python-venv-install.sh`
- Ensure+run with minimal deps: `.github/scripts/python-ensure-and-run.sh`
- OPA bundle + integrity: `.github/scripts/build-opa-bundle.sh`,
  `generate-manifest.sh`, `generate-refs-index.sh`, `generate-sboms.sh`,
  `compute-digests.sh`, `sign-artifacts.sh`, `attest-artifacts.sh`,
  `verify-signatures.sh`, `verify-integrity.sh`

Deprecated/removed helpers (do not use): `docs-build.sh`, `probe-image-pull.sh`,
`resolve-ci-image.sh`, `install-opa.sh`.

## Releases

- See `RELEASE_CHECKLIST.md` and `README.md` for process and artifacts (OPA bundle, indexes, etc.).

## Reporting Security Issues

- Do not disclose vulnerabilities in Issues. Use the private channel defined in `SECURITY.md`.

Thank you for your contribution.
