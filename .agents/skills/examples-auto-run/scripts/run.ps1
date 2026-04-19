# Examples Auto-Run Script for Windows PowerShell
# Automatically discovers and runs all examples in the repository,
# capturing output and reporting success/failure for each.

param(
    [string]$ExamplesDir = "examples",
    [int]$TimeoutSeconds = 30,
    [switch]$StopOnFailure,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$script:PassCount = 0
$script:FailCount = 0
$script:SkipCount = 0
$script:Results = @()

function Write-Header {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Write-Result {
    param([string]$Status, [string]$File, [string]$Detail = "")
    switch ($Status) {
        "PASS" { Write-Host "  [PASS] $File" -ForegroundColor Green }
        "FAIL" { Write-Host "  [FAIL] $File - $Detail" -ForegroundColor Red }
        "SKIP" { Write-Host "  [SKIP] $File - $Detail" -ForegroundColor Yellow }
    }
}

function Test-PythonAvailable {
    try {
        $null = python --version 2>&1
        return $true
    } catch {
        return $false
    }
}

function Get-ExampleFiles {
    param([string]$Dir)
    if (-not (Test-Path $Dir)) {
        Write-Host "Examples directory '$Dir' not found." -ForegroundColor Yellow
        return @()
    }
    return Get-ChildItem -Path $Dir -Filter "*.py" -Recurse | Sort-Object FullName
}

function Should-SkipExample {
    param([string]$FilePath)
    $content = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
    if ($content -match "# skip-auto-run" -or $content -match "# requires-interaction") {
        return $true
    }
    # Skip files that require API keys not set
    if ($content -match "OPENAI_API_KEY" -and -not $env:OPENAI_API_KEY) {
        return $true
    }
    return $false
}

function Invoke-Example {
    param([string]$FilePath)

    if (Should-SkipExample -FilePath $FilePath) {
        $script:SkipCount++
        $script:Results += [PSCustomObject]@{ Status="SKIP"; File=$FilePath; Detail="Marked for skip or missing env vars" }
        Write-Result "SKIP" $FilePath "marked for skip or missing env vars"
        return
    }

    try {
        $proc = Start-Process -FilePath python -ArgumentList $FilePath \
            -NoNewWindow -PassThru -RedirectStandardOutput "$env:TEMP\example_out.txt" \
            -RedirectStandardError "$env:TEMP\example_err.txt"

        $finished = $proc.WaitForExit($TimeoutSeconds * 1000)

        if (-not $finished) {
            $proc.Kill()
            $script:FailCount++
            $script:Results += [PSCustomObject]@{ Status="FAIL"; File=$FilePath; Detail="Timed out after ${TimeoutSeconds}s" }
            Write-Result "FAIL" $FilePath "timed out after ${TimeoutSeconds}s"
            return
        }

        if ($proc.ExitCode -eq 0) {
            $script:PassCount++
            $script:Results += [PSCustomObject]@{ Status="PASS"; File=$FilePath; Detail="" }
            Write-Result "PASS" $FilePath
            if ($Verbose) {
                Get-Content "$env:TEMP\example_out.txt" | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
            }
        } else {
            $errOutput = Get-Content "$env:TEMP\example_err.txt" -Raw -ErrorAction SilentlyContinue
            $detail = if ($errOutput) { $errOutput.Trim() -replace "`n", " " } else { "exit code $($proc.ExitCode)" }
            $script:FailCount++
            $script:Results += [PSCustomObject]@{ Status="FAIL"; File=$FilePath; Detail=$detail }
            Write-Result "FAIL" $FilePath $detail
        }
    } catch {
        $script:FailCount++
        $script:Results += [PSCustomObject]@{ Status="FAIL"; File=$FilePath; Detail=$_.Exception.Message }
        Write-Result "FAIL" $FilePath $_.Exception.Message
    }

    if ($StopOnFailure -and $script:FailCount -gt 0) {
        Write-Host "`nStopping on first failure as requested." -ForegroundColor Red
        exit 1
    }
}

# --- Main ---
Write-Header "Examples Auto-Run"

if (-not (Test-PythonAvailable)) {
    Write-Host "Python is not available. Please install Python and try again." -ForegroundColor Red
    exit 1
}

$examples = Get-ExampleFiles -Dir $ExamplesDir

if ($examples.Count -eq 0) {
    Write-Host "No example files found in '$ExamplesDir'." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($examples.Count) example file(s) in '$ExamplesDir'.`n"

foreach ($example in $examples) {
    Invoke-Example -FilePath $example.FullName
}

Write-Header "Summary"
Write-Host "  Passed : $script:PassCount" -ForegroundColor Green
Write-Host "  Failed : $script:FailCount" -ForegroundColor Red
Write-Host "  Skipped: $script:SkipCount" -ForegroundColor Yellow

if ($script:FailCount -gt 0) {
    exit 1
}
exit 0
