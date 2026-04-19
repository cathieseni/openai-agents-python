# PR Review Skill

Automatically reviews pull requests for code quality, correctness, and consistency with project standards.

## What This Skill Does

- Analyzes changed files in a pull request
- Checks for common issues: missing tests, missing docstrings, type hint coverage
- Verifies that new public APIs are documented
- Flags potential bugs or anti-patterns
- Posts a structured review summary as a PR comment

## Trigger

This skill runs automatically when:
- A pull request is opened or updated against `main`
- A reviewer requests an automated review via comment: `/review`

## Inputs

| Variable | Description |
|---|---|
| `PR_NUMBER` | The pull request number to review |
| `GITHUB_TOKEN` | Token with `pull_requests: write` permission |
| `REPO` | Repository in `owner/repo` format |

## Outputs

Posts a GitHub PR review comment with:
- Summary of changes
- Issues found (errors, warnings, suggestions)
- Checklist of automated checks passed/failed

## Checks Performed

### Code Quality
- [ ] All new functions/classes have docstrings
- [ ] Public methods include type hints
- [ ] No `print()` statements in library code (use logging)
- [ ] No hardcoded credentials or secrets

### Test Coverage
- [ ] New modules have corresponding test files
- [ ] New public functions have at least one test

### Documentation
- [ ] New public APIs appear in docs or have a docs update
- [ ] CHANGELOG or release notes updated if applicable

## Configuration

Place a `.agents/skills/pr-review/config.yaml` in your repo to customize behavior.

## Example Review Output

```
## Automated PR Review

### Summary
This PR adds 3 new files and modifies 2 existing files.

### Issues Found
- ⚠️  `src/agents/new_module.py:42` — Public function `run()` missing docstring
- 💡  `src/agents/new_module.py:10` — Consider adding type hints to parameters

### Checks
- ✅ No hardcoded secrets detected
- ✅ Test file found for new module
- ❌ No documentation update found for new public API
```
