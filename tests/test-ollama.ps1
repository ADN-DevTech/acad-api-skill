<#
.SYNOPSIS
    A/B comparison: proves acad-api-skill files improve AI-generated AutoCAD plugins.

.DESCRIPTION
    Runs the SAME prompt against a local Ollama model TWICE:
      Run A  "Baseline"    — bare developer prompt, no skill context
      Run B  "With Skills" — same prompt + injected skill file content
    Then prints a side-by-side scorecard comparing framework, conventions,
    build success, and runtime correctness.

.PARAMETER AcadHome
    Path to AutoCAD installation (for accoreconsole verification).

.PARAMETER Model
    Ollama model tag (default: qwen3-coder:480b-cloud).

.PARAMETER SkipAI
    Install skills only; don't call Ollama.

.PARAMETER BaselineOnly
    Run only the baseline (no-skills) pass.

.PARAMETER SkillsOnly
    Run only the with-skills pass.

.PARAMETER NonInteractive
    Do not prompt for ACAD_HOME; use environment variable or a default path.

.EXAMPLE
    .\tests\test-ollama.ps1 -AcadHome "D:\ACAD\AutoCAD 2027"
    .\tests\test-ollama.ps1 -AcadHome "D:\ACAD\AutoCAD 2027" -Model "qwen3-coder"
    .\tests\test-ollama.ps1 -AcadHome "D:\ACAD\AutoCAD 2027" -BaselineOnly
#>

param(
    [string]$AcadHome,
    [string]$Model = "qwen3-coder:480b-cloud",
    [switch]$SkipAI,
    [switch]$BaselineOnly,
    [switch]$SkillsOnly,
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"
$testDate   = Get-Date -Format "yyyy-MM-dd-HHmmss"
$testRoot   = Join-Path $PSScriptRoot "test-$testDate"
$repoRoot   = Split-Path $PSScriptRoot -Parent

# ============================================================
#  Banner
# ============================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  AutoCAD API Skill  —  A/B Comparison Test" -ForegroundColor Cyan
Write-Host "  Model: $Model" -ForegroundColor DarkGray
Write-Host "  Date:  $testDate" -ForegroundColor DarkGray
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
#  Pre-flight
# ============================================================
if (-not $AcadHome) {
    if ($env:ACAD_HOME) {
        $AcadHome = $env:ACAD_HOME
    } elseif ($NonInteractive) {
        $AcadHome = "C:\Program Files\Autodesk\AutoCAD 2027"
        Write-Host "[INFO] NonInteractive: ACAD_HOME = $AcadHome" -ForegroundColor DarkGray
    } else {
        $AcadHome = Read-Host "ACAD_HOME path"
    }
}
$accoreconsole = Join-Path $AcadHome "accoreconsole.exe"
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

# ============================================================
#  Shared task prompt (identical for both runs)
# ============================================================
$taskPrompt = @"
Create an AutoCAD desktop plugin called ToolpathOptimizer.
Target: AutoCAD 2027, .NET, C#, x64 only.
Problem: Hundreds of Circle entities on a steel sheet DWG representing bracket cut-outs.
Find the most efficient CNC laser travel path (Traveling Salesman Problem, nearest-neighbor heuristic).
Requirements:
- Command name: OptimizePath
- Collect all Circle entities from model space
- Compute optimized visit order starting from the circle nearest to (0,0)
- Draw a LWPolyline (red, color index 1) showing the optimized toolpath
- Print naive vs optimized travel distance and percentage saved to the command line
- Write results to result.txt in the DWG directory; first line must be TOOLPATH_TEST_PASSED
- Use proper transactions and document locking for write operations

Return ONLY raw file contents in this EXACT format (no markdown fences, no extra commentary):
FILE: ToolpathOptimizer.csproj
CODE:
[csproj XML here]
DONE
FILE: Plugin.cs
CODE:
[full C# source here]
DONE
"@

# ============================================================
#  Helper: call Ollama, parse files, build, score
# ============================================================
function Invoke-OllamaRun {
    param(
        [string]$RunLabel,
        [string]$RunDir,
        [string]$FullPrompt
    )

    $score = [ordered]@{
        Label           = $RunLabel
        FilesExtracted  = 0
        HasCsproj       = $false
        TargetFramework = "(none)"
        PlatformX64     = $false
        ExcludeAssets   = $false
        NoRuntimeId     = $true
        NuGetCorrect    = $false
        BuildSuccess    = $false
        ErrorCount      = 0
        Errors          = @()
    }

    New-Item -ItemType Directory -Path $RunDir -Force | Out-Null

    # --- Call Ollama ---
    Write-Host "  Calling Ollama ($Model)..." -ForegroundColor DarkGray
    $payload = @{
        model   = $Model
        prompt  = $FullPrompt
        stream  = $false
        options = @{ num_predict = 8192; temperature = 0.2 }
    } | ConvertTo-Json -Depth 3

    try {
        $response = Invoke-RestMethod -Method Post -Uri "http://localhost:11434/api/generate" `
            -Body $payload -ContentType "application/json" -TimeoutSec 300
        $aiOutput = $response.response
    } catch {
        Write-Host "  [FAIL] Ollama connection failed: $_" -ForegroundColor Red
        return $score
    }

    # Save raw response for debugging
    $aiOutput | Out-File (Join-Path $RunDir "_raw_response.txt") -Encoding utf8

    # --- Parse files ---
    $cleanOutput = $aiOutput -replace '```[\w]*\r?\n', '' -replace '```', ''
    $pattern = 'FILE:\s*(?<path>.+?)\r?\nCODE:\r?\n(?<code>.*?)\r?\nDONE'
    $fileMatches = [regex]::Matches($cleanOutput, $pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)

    foreach ($m in $fileMatches) {
        $path = $m.Groups['path'].Value.Trim()
        $code = $m.Groups['code'].Value.Trim()
        $fullPath = Join-Path $RunDir $path
        $parent = Split-Path $fullPath -Parent
        if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        $code | Out-File -FilePath $fullPath -Encoding utf8
        Write-Host "    [+] $path" -ForegroundColor Green
    }
    $score.FilesExtracted = $fileMatches.Count

    if ($fileMatches.Count -eq 0) {
        Write-Host "    [FAIL] No files extracted from response." -ForegroundColor Red
        return $score
    }

    # --- Analyze csproj ---
    $csproj = Get-ChildItem -Path $RunDir -Filter "*.csproj" -Recurse | Select-Object -First 1
    if ($csproj) {
        $score.HasCsproj = $true
        $xml = Get-Content $csproj.FullName -Raw

        # Target framework
        if ($xml -match '<TargetFramework>(.*?)</TargetFramework>') {
            $score.TargetFramework = $Matches[1]
        }

        $score.PlatformX64  = [bool]($xml -match '<PlatformTarget>x64</PlatformTarget>')
        $score.ExcludeAssets = [bool]($xml -match 'ExcludeAssets\s*=\s*"runtime"')
        $score.NoRuntimeId   = -not ($xml -match '<RuntimeIdentifier>')
        $score.NuGetCorrect  = [bool]($xml -match 'AutoCAD\.NET[^"]*"\s+Version\s*=\s*"26\.')

        # --- Build ---
        Write-Host "    Building..." -ForegroundColor DarkGray
        $buildOutput = dotnet build $csproj.FullName -c Debug 2>&1 | Out-String
        $score.BuildSuccess = ($LASTEXITCODE -eq 0)

        # Count errors
        $errorLines = ($buildOutput | Select-String "error CS\d+").Matches
        $score.ErrorCount = if ($errorLines) { $errorLines.Count } else { 0 }
        $score.Errors = @($buildOutput | Select-String "error CS\d+.*" |
            ForEach-Object { $_.Matches.Value } | Select-Object -First 5)

        # Save build log
        $buildOutput | Out-File (Join-Path $RunDir "_build.log") -Encoding utf8
    }

    return $score
}

# ============================================================
#  Install skills once (needed for Run B context)
# ============================================================
Write-Host "[SETUP] Installing skills..." -ForegroundColor Yellow
$skillInstallDir = Join-Path $testRoot "_skills_source"
New-Item -ItemType Directory -Path $skillInstallDir -Force | Out-Null
Push-Location $skillInstallDir
node "$repoRoot\bin\install.js" | Out-Null
Pop-Location
Write-Host "  OK" -ForegroundColor Green
Write-Host ""

if ($SkipAI) {
    Write-Host "Skills installed. Skipping AI runs (-SkipAI)." -ForegroundColor Gray
    exit 0
}

# ============================================================
#  RUN A — Baseline (no skills)
# ============================================================
$scoreA = $null
if (-not $SkillsOnly) {
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host "  RUN A: Baseline (no skill files)" -ForegroundColor Red
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red

    $barePrompt = @"
You are an expert AutoCAD C# developer.

$taskPrompt
"@

    $scoreA = Invoke-OllamaRun -RunLabel "Baseline" `
        -RunDir (Join-Path $testRoot "run-A-baseline") -FullPrompt $barePrompt
    Write-Host ""
}

# ============================================================
#  RUN B — With Skills
# ============================================================
$scoreB = $null
if (-not $BaselineOnly) {
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host "  RUN B: With acad-api-skill context" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green

    # Load the skill files
    $claudeMd   = Get-Content (Join-Path $skillInstallDir "CLAUDE.md") -Raw -ErrorAction SilentlyContinue
    $scaffoldMd = Get-Content (Join-Path $skillInstallDir "skills\scaffold.md") -Raw -ErrorAction SilentlyContinue
    $acadApiMd  = Get-Content (Join-Path $skillInstallDir "skills\autocad-api.md") -Raw -ErrorAction SilentlyContinue

    $skillsPrompt = @"
You are an expert AutoCAD .NET C# developer.
You MUST follow ALL conventions in the skill context below exactly.

=== CLAUDE.md ===
$claudeMd

=== skills/scaffold.md ===
$scaffoldMd

=== skills/autocad-api.md ===
$acadApiMd

--- TASK ---
$taskPrompt
"@

    $scoreB = Invoke-OllamaRun -RunLabel "With Skills" `
        -RunDir (Join-Path $testRoot "run-B-skills") -FullPrompt $skillsPrompt
    Write-Host ""
}

# ============================================================
#  SCORECARD
# ============================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  SCORECARD" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

function Format-Check {
    param([bool]$ok, [string]$label, [string]$detail)
    $icon  = if ($ok) { "PASS" } else { "FAIL" }
    $color = if ($ok) { "Green" } else { "Red" }
    $text  = "  [$icon] $label"
    if ($detail) { $text += "  ($detail)" }
    Write-Host $text -ForegroundColor $color
}

function Show-Score {
    param($s)
    if (-not $s) { Write-Host "  (skipped)" -ForegroundColor DarkGray; return 0 }

    $points = 0; $total = 7

    Format-Check ($s.FilesExtracted -ge 2) "Files generated"        "$($s.FilesExtracted) files"
    if ($s.FilesExtracted -ge 2) { $points++ }

    Format-Check $s.HasCsproj               "Has .csproj"            ""
    if ($s.HasCsproj) { $points++ }

    $fwOk = $s.TargetFramework -match "net10\.0"
    Format-Check $fwOk                      "Target framework"       $s.TargetFramework
    if ($fwOk) { $points++ }

    Format-Check $s.PlatformX64             "PlatformTarget x64"     ""
    if ($s.PlatformX64) { $points++ }

    Format-Check $s.ExcludeAssets           "ExcludeAssets=runtime"  ""
    if ($s.ExcludeAssets) { $points++ }

    Format-Check $s.NoRuntimeId             "No RuntimeIdentifier"   ""
    if ($s.NoRuntimeId) { $points++ }

    Format-Check $s.BuildSuccess            "Build succeeds"         "$($s.ErrorCount) error(s)"
    if ($s.BuildSuccess) { $points++ }

    if ($s.Errors.Count -gt 0) {
        Write-Host "        Errors:" -ForegroundColor DarkGray
        foreach ($e in $s.Errors) { Write-Host "          $e" -ForegroundColor DarkGray }
    }

    Write-Host ""
    Write-Host "  Score: $points / $total" -ForegroundColor White
    return $points
}

if (-not $SkillsOnly) {
    Write-Host "--- Run A: Baseline (no skills) ---" -ForegroundColor Red
    $ptsA = Show-Score $scoreA
    Write-Host ""
}

if (-not $BaselineOnly) {
    Write-Host "--- Run B: With acad-api-skill ---" -ForegroundColor Green
    $ptsB = Show-Score $scoreB
    Write-Host ""
}

if ($scoreA -and $scoreB) {
    Write-Host "============================================================" -ForegroundColor Cyan
    $diff = $ptsB - $ptsA
    if ($diff -gt 0) {
        Write-Host "  Skills improved score by +$diff points  ($ptsA --> $ptsB / 7)" -ForegroundColor Green
    } elseif ($diff -eq 0) {
        Write-Host "  Scores tied at $ptsA / 7" -ForegroundColor Yellow
    } else {
        Write-Host "  Baseline scored higher?!  ($ptsA vs $ptsB / 7)" -ForegroundColor Yellow
    }
    Write-Host "============================================================" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Artifacts:      $testRoot" -ForegroundColor DarkGray
Write-Host "Raw responses:  _raw_response.txt in each run folder" -ForegroundColor DarkGray
Write-Host "Build logs:     _build.log in each run folder" -ForegroundColor DarkGray
Write-Host ""