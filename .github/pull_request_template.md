# Pull Request Template

Short summary of changes

- What changed and why
- Links to related issue(s) / discussion(s)

Checklist (initial triage)

- [ ] Tests added/updated (if applicable)
- [ ] Documentation updated (if applicable)
- [ ] Related tickets/discussions referenced

## Summary

- [ ] Purpose of this PR (fix/feature/docs/chore):
- [ ] Linked issue(s):

## Checklist

- [ ] Updated docs/README as needed
- [ ] Ran `make validate` and `make coverage`
- [ ] For K8s policy changes: verified addons/ YAML and metadata paths (external chart sync handled separately)
- [ ] For Python changes: `ruff check` passes
- [ ] For plugin changes: `npm run build` passes

## Screenshots / Notes (optional)
