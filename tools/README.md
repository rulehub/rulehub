# Tools

This folder contains repository helper scripts used by maintainers.

Guidelines:

- Prefer idempotent operations: scripts should avoid rewriting files when the
  resulting content is identical. Many tools in this folder follow that rule.
- Use `--apply` to perform writes; the default behavior should be a dry-run.
- One-off or emergency fixers (e.g. `fix_kyverno_messages.py` or
  `strip_code_fences.py`) are allowed but should be documented here and
  considered for moving into `tools/oneoff/` later.

If you add or modify tools, update this README with a short description.

"Small, safe, reversible" is the operating principle for these scripts.
