# Changelog Update Skill

Automatically maintains the project CHANGELOG.md by analyzing commits, pull requests, and code changes to generate accurate, human-readable changelog entries following the Keep a Changelog format.

## What This Skill Does

- Analyzes git commits since the last changelog entry
- Groups changes by type (Added, Changed, Deprecated, Removed, Fixed, Security)
- Generates a new version section in CHANGELOG.md
- Ensures entries are concise and user-facing (not implementation details)
- Links to relevant PRs and issues where available

## When to Use

- Before cutting a new release
- After merging a batch of PRs
- When the changelog is out of sync with recent changes
- As part of a release preparation workflow

## Inputs

| Input | Description | Required |
|-------|-------------|----------|
| `version` | The version number to use for the new entry (e.g. `1.2.0`) | Yes |
| `since_ref` | Git ref (tag/commit/branch) to compare from | No (defaults to last tag) |
| `dry_run` | If `true`, prints changes without modifying CHANGELOG.md | No (default: `false`) |

## Outputs

- Updated `CHANGELOG.md` with a new version section prepended
- Summary of changes grouped by category

## Behavior

### Change Classification

Commits are classified using conventional commit prefixes:

- `feat:` → Added
- `fix:` → Fixed
- `perf:` → Changed
- `refactor:` → Changed
- `deprecate:` → Deprecated
- `remove:` → Removed
- `security:` → Security
- `docs:`, `chore:`, `ci:`, `test:` → typically omitted unless significant

### Format

Follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) conventions and [Semantic Versioning](https://semver.org/).

## Example Output

```markdown
## [1.2.0] - 2024-11-15

### Added
- Support for streaming responses in the Agents API (#142)
- New `on_tool_call` lifecycle hook for agent runs (#138)

### Fixed
- Resolved race condition in parallel tool execution (#145)
- Fixed incorrect token counting for vision inputs (#141)

### Changed
- Improved error messages for invalid tool schemas (#139)
```

## Notes

- The skill will not overwrite an existing entry for the same version
- Merge commits and bot commits (e.g. Dependabot) are filtered out automatically
- If no meaningful changes are found, the skill exits with a warning rather than creating an empty section
