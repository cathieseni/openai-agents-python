#!/bin/bash
# Dependency Update Skill
# Checks for outdated dependencies and creates a PR with updates

set -euo pipefail

echo "=== Dependency Update Skill ==="

# Configuration
BRANCH_NAME="chore/dependency-updates-$(date +%Y%m%d)"
PR_TITLE="chore: update dependencies"
COMMIT_MSG="chore: update outdated dependencies"

# Check required tools
command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 is required"; exit 1; }
command -v pip >/dev/null 2>&1 || { echo "ERROR: pip is required"; exit 1; }
command -v git >/dev/null 2>&1 || { echo "ERROR: git is required"; exit 1; }

# Ensure we're in the repo root
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

echo "Working in: $REPO_ROOT"

# Check for pyproject.toml
if [ ! -f "pyproject.toml" ]; then
  echo "ERROR: pyproject.toml not found in repo root"
  exit 1
fi

# Install pip-tools if not available
if ! command -v pip-compile >/dev/null 2>&1; then
  echo "Installing pip-tools..."
  pip install pip-tools --quiet
fi

# Check for outdated packages
echo "Checking for outdated packages..."
OUTDATED=$(pip list --outdated --format=json 2>/dev/null || echo "[]")

if [ "$OUTDATED" = "[]" ]; then
  echo "All dependencies are up to date. Nothing to do."
  exit 0
fi

echo "Outdated packages found:"
echo "$OUTDATED" | python3 -c "
import json, sys
pkgs = json.load(sys.stdin)
for p in pkgs:
    print(f\"  {p['name']}: {p['version']} -> {p['latest_version']}\")
print(f'Total: {len(pkgs)} package(s) outdated')
"

# Create a new branch
echo "Creating branch: $BRANCH_NAME"
git checkout -b "$BRANCH_NAME" 2>/dev/null || git checkout "$BRANCH_NAME"

# Update dependencies using pip
echo "Updating dependencies..."
UPDATED_PACKAGES=$(echo "$OUTDATED" | python3 -c "
import json, sys
pkgs = json.load(sys.stdin)
print(' '.join([p['name'] for p in pkgs]))
")

if [ -n "$UPDATED_PACKAGES" ]; then
  # shellcheck disable=SC2086
  pip install --upgrade $UPDATED_PACKAGES --quiet
  echo "Packages updated successfully."
fi

# Re-generate lock files if they exist
if [ -f "requirements.txt" ]; then
  echo "Regenerating requirements.txt..."
  pip freeze > requirements.txt
fi

if [ -f "requirements-dev.txt" ]; then
  echo "Regenerating requirements-dev.txt..."
  pip freeze > requirements-dev.txt
fi

# Check if there are actual changes
if git diff --quiet && git diff --cached --quiet; then
  echo "No file changes detected after update. Exiting."
  git checkout -
  git branch -d "$BRANCH_NAME"
  exit 0
fi

# Stage and commit changes
echo "Committing changes..."
git add -A
git commit -m "$COMMIT_MSG"

# Push branch
echo "Pushing branch..."
git push origin "$BRANCH_NAME"

# Create PR if gh CLI is available
if command -v gh >/dev/null 2>&1; then
  echo "Creating pull request..."
  PR_BODY=$(echo "$OUTDATED" | python3 -c "
import json, sys
pkgs = json.load(sys.stdin)
lines = ['## Updated Dependencies', '']
lines.append('| Package | Old Version | New Version |')
lines.append('|---------|-------------|-------------|')
for p in pkgs:
    lines.append(f\"| {p['name']} | {p['version']} | {p['latest_version']} |\")
lines.append('')
lines.append('_Automated update via dependency-update skill._')
print('\\n'.join(lines))
")

  gh pr create \
    --title "$PR_TITLE" \
    --body "$PR_BODY" \
    --base main \
    --head "$BRANCH_NAME" \
    --label "dependencies" || echo "WARN: Could not create PR automatically."
else
  echo "gh CLI not found. Please create a PR manually from branch: $BRANCH_NAME"
fi

echo "=== Dependency update complete ==="
