<#
.SYNOPSIS
    End-to-end developer simulation using Cursor Agent (Composer / headless CLI).

.DESCRIPTION
    Same flow as test-claude.ps1, but invokes **cursor-agent** with --print, which is
    the non-interactive Cursor Agent used from the shell (Composer-class agent in the
    Cursor stack).

    1. Fresh project folder under tests/test-<timestamp>/
    2. Install skills via bin/install.js (same as npx)
    3. Prompt Cursor Agent with a real ToolpathOptimizer task (reads CLAUDE.md + skills)
    4. Build generated .csproj
    5. Optional accoreconsole verification when ACAD_HOME is valid

.PARAMETER AcadHome
    Path to the AutoCAD installation directory.

.PARAMETER Model
    Optional model slug for cursor-agent (--model), e.g. gpt-5, sonnet-4.

.PARAMETER SkipAI
    Install skills only (steps 1-2); skip Cursor Agent.

.PARAMETER NonInteractive
    Skip optional ARX / Plant SDK Read-Host prompts (for CI / scripted runs).

.PARAMETER AgentPath
    Override path to cursor-agent if not on PATH (e.g. full path to cursor-agent.ps1).

.EXAMPLE
    .\tests\test-composer.ps1 -AcadHome "D:\ACAD\AutoCAD 2027"
    .\tests\test-composer.ps1 -AcadHome "$env:ACAD_HOME" -Model "sonnet-4"
    .\tests\test-composer.ps1 -SkipAI
    .\tests\test-composer.ps1 -AcadHome $env:ACAD_HOME -SkipAI -NonInteractive
#>

param(
    [string]$AcadHome,
    [string]$ArxSdkPath,
    [string]$PlantSdkPath,
    [string]$Model,
    [string]$AgentPath,
    [switch]$SkipAI,
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"
$testDate = Get-Date -Format "yyyy-MM-dd-HHmmss"
$testDir = Join-Path $PSScriptRoot "test-$testDate-composer"
$repoRoot = Split-Path $PSScriptRoot -Parent

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  AutoCAD API Skill — Cursor Agent (CLI)" -ForegroundColor Cyan
Write-Host "  $testDate" -ForegroundColor DarkGray
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

if (-not $AcadHome) {
    if ($env:ACAD_HOME) {
        $AcadHome = $env:ACAD_HOME
    } elseif ($NonInteractive) {
        $AcadHome = "C:\Program Files\Autodesk\AutoCAD 2027"
        Write-Host "[INFO] NonInteractive: ACAD_HOME = $AcadHome" -ForegroundColor DarkGray
    } else {
        Write-Host "[SETUP] Where is AutoCAD installed?" -ForegroundColor Yellow
        $AcadHome = Read-Host "  ACAD_HOME (e.g., D:\ACAD\AutoCAD 2027)"
    }
}

if (-not $ArxSdkPath -and -not $env:ARX_SDK) {
    if ($NonInteractive) {
        $ArxSdkPath = ""
    } else {
        Write-Host "[SETUP] ObjectARX SDK (Enter to skip)" -ForegroundColor Yellow
        $ArxSdkPath = Read-Host "  ARX_SDK"
    }
}

if (-not $PlantSdkPath -and -not $env:PLANT_SDK) {
    if ($NonInteractive) {
        $PlantSdkPath = ""
    } else {
        Write-Host "[SETUP] Plant 3D SDK (Enter to skip)" -ForegroundColor Yellow
        $PlantSdkPath = Read-Host "  PLANT_SDK"
    }
}

$env:ACAD_HOME = $AcadHome
if ($ArxSdkPath) { $env:ARX_SDK = $ArxSdkPath }
if ($PlantSdkPath) { $env:PLANT_SDK = $PlantSdkPath }

$accoreconsole = Join-Path $AcadHome "accoreconsole.exe"

Write-Host ""
Write-Host "  ACAD_HOME:  $AcadHome" -ForegroundColor DarkGray
Write-Host ""

Write-Host "[1/6] Creating project folder..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $testDir -Force | Out-Null
Push-Location $testDir
try {
Write-Host "  OK $testDir" -ForegroundColor Green

Write-Host "[2/6] Installing skills (local install.js)..." -ForegroundColor Yellow
node "$repoRoot\bin\install.js"
if ($LASTEXITCODE -ne 0) { throw "Skill installation failed." }

$expectedFiles = @("skills\scaffold.md", "skills\autocad-api.md", "skills\learnings.md", "CLAUDE.md")
foreach ($f in $expectedFiles) {
    if (-not (Test-Path (Join-Path $testDir $f))) { throw "Missing: $f" }
}
Write-Host "  OK Skills installed" -ForegroundColor Green

if ($SkipAI) {
    Write-Host "[3/6] SKIPPED - AI generation (-SkipAI)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Steps 1-2 PASSED. Open this folder in Cursor and run Agent, or re-run without -SkipAI." -ForegroundColor Green
    Write-Host "  $testDir" -ForegroundColor DarkGray
    Write-Host ""
    exit 0
}

$agentCmd = $null
if ($AgentPath) {
    if (Test-Path $AgentPath) { $agentCmd = $AgentPath }
} else {
    $agentCmd = Get-Command "cursor-agent" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
}

if (-not $agentCmd) {
    Write-Host "[3/6] cursor-agent not found on PATH." -ForegroundColor Yellow
    Write-Host "  Install/update: Cursor Agent CLI (see Cursor docs) or pass -AgentPath." -ForegroundColor DarkGray
    Write-Host "  Or run with -SkipAI to test only the install pipeline." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Steps 1-2 PASSED." -ForegroundColor Green
    exit 0
}

Write-Host "[3/6] Prompting Cursor Agent (--print, workspace=$testDir)..." -ForegroundColor Yellow
Write-Host ""

$devPrompt = "Create an AutoCAD desktop plugin called ToolpathOptimizer. " +
    "Problem: I have hundreds of metal bracket outlines (circles) on a steel sheet DWG. " +
    "I need to find the most efficient travel path for a CNC laser head to cut all " +
    "brackets while minimizing idle movement (Traveling Salesman Problem). " +
    "Requirements: " +
    "Use dotnet new acad to scaffold the project. " +
    "Implement a nearest-neighbor TSP heuristic. " +
    "The command should collect all Circle entities from model space, " +
    "compute the optimized visit order starting from the circle nearest to origin, " +
    "draw a red polyline showing the optimized toolpath, " +
    "print the naive vs optimized travel distance and percentage saved, " +
    "and write results to result.txt in the working directory with the first line being TOOLPATH_TEST_PASSED. " +
    "Build the project after writing the code. " +
    "Do NOT use RuntimeIdentifier in the csproj. " +
    "AutoCAD is installed at: $AcadHome"

Write-Host "  Developer Prompt (summary): ToolpathOptimizer / TSP / dotnet new acad / OptimizePath" -ForegroundColor DarkGray
Write-Host ""

$agentArgs = @(
    "--print",
    "--trust",
    "--yolo",
    "--workspace",
    $testDir
)
if ($Model) {
    $agentArgs += @("--model", $Model)
}
$agentArgs += $devPrompt

$logFile = Join-Path $testDir "_cursor_agent.log"
try {
    & $agentCmd @agentArgs 2>&1 | Tee-Object -FilePath $logFile
} catch {
    Write-Host "[FAIL] cursor-agent threw: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

Write-Host "[4/6] Checking what the agent generated..." -ForegroundColor Yellow
$csproj = Get-ChildItem -Path $testDir -Filter "*.csproj" -Recurse | Select-Object -First 1
if (-not $csproj) {
    Write-Host "  FAIL No .csproj found — see $logFile" -ForegroundColor Red
    exit 1
}

$projectDir = $csproj.DirectoryName
$projectName = $csproj.BaseName
Write-Host "  OK Found project: $($csproj.FullName)" -ForegroundColor Green

$csprojContent = Get-Content $csproj.FullName -Raw
if ($csprojContent -match "<RuntimeIdentifier>") {
    Write-Host "  WARN Model used <RuntimeIdentifier> despite skill rules!" -ForegroundColor Yellow
}
if ($csprojContent -match "<PlatformTarget>x64</PlatformTarget>") {
    Write-Host "  OK Correct: PlatformTarget x64" -ForegroundColor Green
}
if ($csprojContent -match 'ExcludeAssets.*runtime') {
    Write-Host "  OK Correct: ExcludeAssets=runtime on NuGet refs" -ForegroundColor Green
}

Write-Host "[5/6] Building..." -ForegroundColor Yellow
dotnet build $csproj.FullName -c Debug
if ($LASTEXITCODE -ne 0) {
    Write-Host "  FAIL Build failed." -ForegroundColor Red
    exit 1
}

$dllPath = Get-ChildItem -Path $projectDir -Filter "$projectName.dll" -Recurse |
    Where-Object { $_.FullName -match "bin" } |
    Select-Object -First 1
if (-not $dllPath) { throw "DLL not found after build." }
Write-Host "  OK $($dllPath.FullName)" -ForegroundColor Green

Write-Host "[6/6] accoreconsole..." -ForegroundColor Yellow
if (-not (Test-Path $accoreconsole)) {
    Write-Host "  SKIPPED — accoreconsole not at $accoreconsole" -ForegroundColor Yellow
    Write-Host "  Steps 1-5 PASSED. Test folder: $testDir" -ForegroundColor Green
    exit 0
}

$dllFullPath = $dllPath.FullName
$scrLines = @(
    "SECURELOAD",
    "0",
    "(progn (setq seed 42) (repeat 50 (command ""CIRCLE"" (list (* (rem (setq seed (rem (* seed 1103515245) 2147483648)) 1000) 0.5) (* (rem (setq seed (rem (* seed 1103515245) 2147483648)) 800) 0.5) 0) (+ 5 (rem seed 10)))) (princ))",
    "NETLOAD",
    "$dllFullPath",
    "OptimizePath",
    "QUIT",
    "Y"
)
$scrPath = Join-Path $testDir "test.scr"
$scrLines | Out-File -FilePath $scrPath -Encoding ASCII
& $accoreconsole /i "" /s $scrPath

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Results" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$resultPath = Join-Path $testDir "result.txt"
if (-not (Test-Path $resultPath)) {
    $resultFile = Get-ChildItem -Path $testDir -Filter "result.txt" -Recurse | Select-Object -First 1
    if ($resultFile) { $resultPath = $resultFile.FullName }
}

if ((Test-Path $resultPath)) {
    $result = Get-Content $resultPath -Raw
    if ($result -match "TOOLPATH_TEST_PASSED") {
        Write-Host ""
        Get-Content $resultPath | ForEach-Object { Write-Host "  $_" -ForegroundColor Green }
        Write-Host ""
        Write-Host "  ALL STEPS PASSED" -ForegroundColor Green
    } else {
        Write-Host "  result.txt missing TOOLPATH_TEST_PASSED" -ForegroundColor Yellow
    }
} else {
    Write-Host "  No result.txt" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  Test folder: $testDir" -ForegroundColor DarkGray
Write-Host ""
} finally {
    Pop-Location
}
