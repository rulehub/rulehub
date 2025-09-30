---
title: Editorial Documentation Review Checklist
---

Purpose: provide a consistent, lightweight manual review pass before merging or releasing documentation changes.
Use this list as a gate in PRs touching files under `docs/`, top-level Markdown, or policy metadata notes.

> Tip: Mark each item PASS / FAIL (and fix) in the PR review comment. Automatable items should migrate into
> tooling (lint, tests, guards) over time.

## Quick Summary (10 Core Checks)
1. Grammar & Clarity OK
2. Terminology Consistent (canonical terms)
3. Heading Style & Hierarchy Valid
4. Links Valid / Secure (https) & Descriptive
5. Make Target Names Accurate & Current
6. Includes Verification / Repro Steps (where procedural)
7. Code / Command Blocks Tested or Example‑Tagged
8. Consistent Formatting (lists, tables, admonitions)
9. Security / Integrity Notes Present (when referencing artifacts)
10. No Stale References (removed files, old versions, placeholder titles)

## Detailed Checklist (Table)

| Category | Check | How to Verify | Fail Criteria | Notes / Aids |
|----------|-------|---------------|---------------|--------------|
| Grammar & Style | Concise; no typos | Read aloud / tool | Run‑ons; untranslated text | Active voice; <=25 words |
| Terminology | Canonical names used | Search variants | Mixed casing / synonyms | Add terms to cspell |
| Heading Hierarchy | Single H1; no jumps | Inspect TOC | Skipped levels / duplicate | Action nouns |
| Titles & Slugs | Title matches nav entry | Compare nav | Duplicate / mismatch | Use front‑matter override |
| Links | External links are https | Grep `http://` | Insecure / "here" text | Prefer relative internal links |
| Link Freshness | Internal targets exist | Click locally | 404 / removed | Avoid deep GitHub blob URLs |
| Make Targets | Referenced targets exist | Grep Makefile | Typos / obsolete | Backticks around targets |
| Verification Steps | Cmds + expected output | Scan fenced blocks | Missing reproducible steps | Tag `# example-test` |
| Integrity / Security | Mention verification steps | Search keywords | No verify/hash guidance | Link integrity doc |
| Code & Examples | Shell blocks safe (no destructive ops) | Review blocks | Unsafe commands | Add caution comments |
| Example Testability | Runnable examples tagged | Look for tag | Eligible block untagged | Exclude network heavy examples |
| Formatting Consistency | Uniform list markers / fences | Visual scan | Mixed markers / fence styles | Use ```bash |
| Admonitions | Use Material admonitions | Look for `!!!` | Plain NOTE text | Convert gradually |
| Placeholders | No `<Policy Title>` or TBD | Search repo | Placeholder remains | Replace or remove |
| Localization | Non‑English only where intentional | Grep Cyrillic | Untranslated stray text | Provide English primary |
| Accessibility | Images alt text; table headers | Inspect | Missing alt/header | Add concise alt text |
| Length & Focus | Not overly long without sections | Check lines | Huge monolith | Split page |
| Metadata Alignment | Claims match actual features | Cross‑check scripts | Outdated claims | Future: mark Planned |
| Version References | Use vX.Y.Z placeholders | Scan examples | Stale fixed version | Update during release |
| Release Guidance | Link audit & integrity steps present | Skim release docs | Missing step | Insert before publish |
| Risk Statements | External download risk noted | Scan for downloads | Missing risk note | Reference supply chain verify |

## Review Flow (Suggested)
1. Run automated guardrails: `make guardrails docs-lint link-audit`.
2. Open `mkdocs.yml`; confirm any new file is added intentionally (or intentionally excluded).
3. Apply Quick Summary checks (10 items). Fix blocking issues immediately.
4. Perform Detailed Checklist pass; record FAIL items in PR review comment.
5. For any FAIL that is automatable, open a follow-up issue to codify (reduce manual burden).
6. Re-run `make docs-build` to ensure site builds successfully and search index updates.

## PASS / FAIL Template (Copy into PR Review)
```
Editorial Review Summary
Date: <YYYY-MM-DD>
Reviewer: <name>

Quick Core Checks: [ ] Grammar [ ] Terminology [ ] Headings [ ] Links [ ] Targets [ ] Verification Steps [ ] Examples [ ] Formatting [ ] Integrity Notes [ ] No Stale Refs

Detailed Fails (category -> issue -> action):
- <Category>: <Issue> -> <Action>

Automation Opportunities:
- <Proposed lint or guardrail>

Overall Status: PASS / FAIL (needs fixes)
```

## Future Automation Candidates
- Heading level jump detection (markdownlint rule customization).
- Internal link existence checker (relative path resolution) integrated into `docs-lint`.
- Placeholder / TBD scanner integrated into guardrails.
- Example harness index (`docs/examples.index`) to selectively execute code snippets.
- Accessibility scan (alt text & heading uniqueness) script.

---
Maintained: update when new guardrails or doc conventions are introduced.
