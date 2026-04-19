# Dependency Update Skill - PowerShell Script
# Checks for outdated dependencies and creates a PR with updates

param(
    [string]$BranchPrefix = "deps/update",
    [string]$PrTitle = "chore: update dependencies",
    [switch]$DryRun = $false
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Info { param([string]$msg) Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Success { param([string]$msg) Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Warn { param([string]$msg) Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Fail { param([string]$msg) Write-Host "[FAIL] $msg" -ForegroundColor Red }

# Verify required tools
foreach ($tool in @("python", "pip", "git")) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        Write-Fail "Required tool not found: $tool"
        exit 1
    }
}

Write-Info "Checking for outdated dependencies..."

# Get list of outdated packages
$outdatedJson = python -m pip list --outdated --format=json 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Fail "Failed to retrieve outdated packages."
    exit 1
}

$outdated = $outdatedJson | ConvertFrom-Json
if ($outdated.Count -eq 0) {
    Write-Success "All dependencies are up to date."
    exit 0
}

Write-Info "Found $($outdated.Count) outdated package(s):"
foreach ($pkg in $outdated) {
    Write-Host "  - $($pkg.name): $($pkg.version) -> $($pkg.latest_version)"
}

if ($DryRun) {
    Write-Warn "Dry-run mode enabled. No changes will be made."
    exit 0
}

# Create a new branch for the updates
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$branchName = "$BranchPrefix-$timestamp"

Write-Info "Creating branch: $branchName"
git checkout -b $branchName
if ($LASTEXITCODE -ne 0) {
    Write-Fail "Failed to create branch."
    exit 1
}

# Update each outdated package
foreach ($pkg in $outdated) {
    Write-Info "Updating $($pkg.name) from $($pkg.version) to $($pkg.latest_version)..."
    pip install --upgrade $pkg.name 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "Failed to update $($pkg.name), skipping."
    } else {
        Write-Success "Updated $($pkg.name)"
    }
}

# Regenerate requirements if applicable
if (Test-Path "requirements.txt") {
    Write-Info "Regenerating requirements.txt..."
    pip freeze | Out-File -Encoding utf8 requirements.txt
}

# Stage and commit changes
git add -A
$commitMsg = "chore: update $($outdated.Count) outdated dependencies"
git commit -m $commitMsg
if ($LASTEXITCODE -ne 0) {
    Write-Warn "Nothing to commit or commit failed."
    git checkout -
    exit 0
}

# Push branch
Write-Info "Pushing branch $branchName..."
git push origin $branchName
if ($LASTEXITCODE -ne 0) {
    Write-Fail "Failed to push branch."
    exit 1
}

# Create PR if gh CLI is available
if (Get-Command "gh" -ErrorAction SilentlyContinue) {
    Write-Info "Creating pull request..."
    $body = "Automated dependency update.`n`nUpdated packages:`n"
    foreach ($pkg in $outdated) {
        $body += "- $($pkg.name): $($pkg.version) -> $($pkg.latest_version)`n"
    }
    gh pr create --title $PrTitle --body $body --head $branchName
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Pull request created successfully."
    } else {
        Write-Warn "PR creation failed. Branch pushed: $branchName"
    }
} else {
    Write-Warn "'gh' CLI not found. Skipping PR creation. Branch pushed: $branchName"
}

Write-Success "Dependency update complete."
