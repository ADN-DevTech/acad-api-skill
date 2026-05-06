<#
.SYNOPSIS
    Smoke-test all install-only paths (no AI calls). Restores working directory after each script.

.EXAMPLE
    $env:ACAD_HOME = 'D:\ACAD\AutoCAD 2027'
    .\tests\run-smoke.ps1
#>
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$repo = Split-Path $here -Parent
Set-Location $repo

if (-not $env:ACAD_HOME) {
    $env:ACAD_HOME = "C:\Program Files\Autodesk\AutoCAD 2027"
    Write-Host "[INFO] ACAD_HOME not set; using $env:ACAD_HOME for smoke test (install only)." -ForegroundColor DarkGray
}

Write-Host "`n=== test-claude.ps1 -SkipAI -NonInteractive ===`n" -ForegroundColor Cyan
& "$here\test-claude.ps1" -SkipAI -NonInteractive

Write-Host "`n=== test-composer.ps1 -SkipAI -NonInteractive ===`n" -ForegroundColor Cyan
& "$here\test-composer.ps1" -SkipAI -NonInteractive

Write-Host "`n=== test-ollama.ps1 -SkipAI -NonInteractive ===`n" -ForegroundColor Cyan
& "$here\test-ollama.ps1" -SkipAI -NonInteractive

Write-Host "`nSmoke tests finished. Repo cwd: $(Get-Location)" -ForegroundColor Green
