# Dependency Update Skill

This skill automates the process of checking for outdated dependencies and creating pull requests to update them.

## Overview

The dependency update skill will:
1. Scan the project for dependency files (`pyproject.toml`, `requirements.txt`, etc.)
2. Check for outdated packages using `pip list --outdated`
3. Evaluate whether updates are safe (major/minor/patch classification)
4. Run the test suite to verify updates don't break anything
5. Create a PR with the dependency updates and a summary of changes

## Trigger

This skill can be triggered:
- On a schedule (e.g., weekly)
- Manually via workflow dispatch
- When a security advisory is published for a dependency

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `update_type` | Type of updates to apply: `patch`, `minor`, or `major` | No | `minor` |
| `packages` | Comma-separated list of specific packages to update (empty = all) | No | `` |
| `dry_run` | If true, report outdated deps but don't create a PR | No | `false` |
| `skip_tests` | If true, skip running tests after updating | No | `false` |

## Outputs

- A pull request with updated dependency files
- A comment summarizing:
  - Packages updated
  - Version changes (old → new)
  - Test results
  - Any packages skipped due to breaking changes

## Configuration

Place a `.agents/skills/dependency-update/config.yaml` in your repo to customize behavior:

```yaml
exclude_packages:
  - some-package  # never update this
update_type: minor
auto_merge: true  # auto-merge if tests pass
```

## Notes

- Major version updates are flagged for manual review even if `update_type` is `major`
- The skill respects version pinning in `pyproject.toml` (e.g., `>=1.0,<2.0`)
- Security updates bypass the `update_type` filter and are always applied
