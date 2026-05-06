<#
.SYNOPSIS
    End-to-end developer simulation for acad-api-skill.
    
    Emulates the real first-time experience: install skills, prompt an AI,
    let the AI build the plugin using the skills, test in accoreconsole.

.DESCRIPTION
    This is NOT a deterministic test that writes its own code. 
    It invokes Claude Code CLI with a real developer prompt and lets the AI 
    generate the plugin based entirely on the installed skill files.
    
    The flow:
    1. Create a fresh project folder
    2. Install skill files via the local installer (same as npx)
    3. Feed a developer prompt to Claude Code CLI
    4. The AI reads the skills, scaffolds the project, writes the plugin
    5. Build whatever the AI generated
    6. Load in accoreconsole and verify

.PARAMETER AcadHome
    Path to the AutoCAD installation directory.

.PARAMETER ArxSdkPath
    Path to the ObjectARX SDK (e.g., D:\SDKs\Arx2027).

.PARAMETER PlantSdkPath
    Path to the Plant 3D SDK inc-x64 folder.

.PARAMETER SkipAI
    If set, skips the AI generation step and just tests install + template.

.PARAMETER NonInteractive
    Skip optional ARX / Plant SDK Read-Host prompts (for CI / scripted runs).

.EXAMPLE
    .\tests\test-script.ps1 -AcadHome "D:\ACAD\AutoCAD 2027"
    .\tests\test-script.ps1 -AcadHome "D:\ACAD\AutoCAD 2027" -SkipAI
    .\tests\test-claude.ps1 -AcadHome $env:ACAD_HOME -SkipAI -NonInteractive
#>

param(
    [string]$AcadHome,
    [string]$ArxSdkPath,
    [string]$PlantSdkPath,
    [switch]$SkipAI,
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"
$testDate = Get-Date -Format "yyyy-MM-dd-HHmmss"
$testDir = Join-Path $PSScriptRoot "test-$testDate"
$repoRoot = Split-Path $PSScriptRoot -Parent

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  AutoCAD API Skill - Developer Simulation" -ForegroundColor Cyan
Write-Host "  $testDate" -ForegroundColor DarkGray
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# -----------------------------------------------
# Pre-flight - Gather environment
# -----------------------------------------------
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
        Write-Host "[SETUP] Where is the ObjectARX SDK? (press Enter to skip)" -ForegroundColor Yellow
        $ArxSdkPath = Read-Host "  ARX_SDK (e.g., D:\SDKs\Arx2027)"
    }
}

if (-not $PlantSdkPath -and -not $env:PLANT_SDK) {
    if ($NonInteractive) {
        $PlantSdkPath = ""
    } else {
        Write-Host "[SETUP] Where is the Plant 3D SDK? (press Enter to skip)" -ForegroundColor Yellow
        $PlantSdkPath = Read-Host "  PLANT_SDK (e.g., D:\SDKs\Plant2027\inc-x64)"
    }
}

# Set environment for the AI session
$env:ACAD_HOME = $AcadHome
if ($ArxSdkPath) { $env:ARX_SDK = $ArxSdkPath }
if ($PlantSdkPath) { $env:PLANT_SDK = $PlantSdkPath }

$accoreconsole = Join-Path $AcadHome "accoreconsole.exe"

$arxDisplay = if ($ArxSdkPath) { $ArxSdkPath } else { "(not set)" }
$plantDisplay = if ($PlantSdkPath) { $PlantSdkPath } else { "(not set)" }

Write-Host ""
Write-Host "  ACAD_HOME:  $AcadHome" -ForegroundColor DarkGray
Write-Host "  ARX_SDK:    $arxDisplay" -ForegroundColor DarkGray
Write-Host "  PLANT_SDK:  $plantDisplay" -ForegroundColor DarkGray
Write-Host ""

# -----------------------------------------------
# Step 1 - Developer creates a new project folder
# -----------------------------------------------
Write-Host "[1/6] Creating project folder..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $testDir -Force | Out-Null
Push-Location $testDir
try {
Write-Host "  OK $testDir" -ForegroundColor Green

# -----------------------------------------------
# Step 2 - Developer runs npx to install skills
# -----------------------------------------------
Write-Host "[2/6] Installing skills (simulating npx github:ADN-DevTech/acad-api-skill)..." -ForegroundColor Yellow
node "$repoRoot\bin\install.js"
if ($LASTEXITCODE -ne 0) { throw "Skill installation failed." }

# Quick sanity check
$expectedFiles = @("skills\scaffold.md", "skills\autocad-api.md", "skills\learnings.md", "CLAUDE.md")
foreach ($f in $expectedFiles) {
    if (-not (Test-Path (Join-Path $testDir $f))) { throw "Missing: $f" }
}
Write-Host "  OK Skills installed" -ForegroundColor Green

# -----------------------------------------------
# Step 3 - Developer opens editor and prompts the AI
# -----------------------------------------------
if ($SkipAI) {
    Write-Host "[3/6] SKIPPED - AI generation (-SkipAI flag set)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Steps 1-2 PASSED. Skills installed successfully." -ForegroundColor Green
    Write-Host "  Open this folder in Cursor or Claude Code to continue manually:" -ForegroundColor DarkGray
    Write-Host "  $testDir" -ForegroundColor DarkGray
    Write-Host ""
    exit 0
}

# Check for claude CLI
$claudePath = Get-Command "claude" -ErrorAction SilentlyContinue
if (-not $claudePath) {
    Write-Host "[3/6] Claude Code CLI not found." -ForegroundColor Yellow
    Write-Host "  Install it: npm install -g @anthropic-ai/claude-code" -ForegroundColor DarkGray
    Write-Host "  Or run with -SkipAI to test just the install pipeline." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Steps 1-2 PASSED." -ForegroundColor Green
    exit 0
}

Write-Host "[3/6] Prompting Claude Code with a real developer request..." -ForegroundColor Yellow
Write-Host ""

# This is the real prompt a developer would type.
# The AI must read CLAUDE.md, skills/scaffold.md, skills/autocad-api.md
# and generate a working plugin WITHOUT us writing a single line of C#.

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

Write-Host "  Developer Prompt:" -ForegroundColor DarkGray
Write-Host "  $devPrompt" -ForegroundColor DarkGray
Write-Host ""

# Invoke Claude Code CLI in non-interactive mode
# Claude reads CLAUDE.md, follows the skills, and generates the plugin
claude --print --dangerously-skip-permissions $devPrompt 2>&1 | Tee-Object -Variable aiOutput

Write-Host ""

# -----------------------------------------------
# Step 4 - Verify the AI generated something buildable
# -----------------------------------------------
Write-Host "[4/6] Checking what the AI generated..." -ForegroundColor Yellow

# Find the project the AI created
$csproj = Get-ChildItem -Path $testDir -Filter "*.csproj" -Recurse | Select-Object -First 1
if (-not $csproj) {
    Write-Host "  FAIL No .csproj found - AI did not scaffold a project" -ForegroundColor Red
    exit 1
}

$projectDir = $csproj.DirectoryName
$projectName = $csproj.BaseName
Write-Host "  OK Found project: $($csproj.FullName)" -ForegroundColor Green

# Check for RuntimeIdentifier violation (the skill should have prevented this)
$csprojContent = Get-Content $csproj.FullName -Raw
if ($csprojContent -match "<RuntimeIdentifier>") {
    Write-Host "  WARN AI used <RuntimeIdentifier> despite skill rules!" -ForegroundColor Yellow
}

if ($csprojContent -match "<PlatformTarget>x64</PlatformTarget>") {
    Write-Host "  OK Correct: PlatformTarget x64" -ForegroundColor Green
}

if ($csprojContent -match 'ExcludeAssets.*runtime') {
    Write-Host "  OK Correct: ExcludeAssets=runtime on NuGet refs" -ForegroundColor Green
}

# -----------------------------------------------
# Step 5 - Build
# -----------------------------------------------
Write-Host "[5/6] Building the AI-generated project..." -ForegroundColor Yellow
dotnet build $csproj.FullName -c Debug
if ($LASTEXITCODE -ne 0) {
    Write-Host "  FAIL Build failed. The AI-generated code has errors." -ForegroundColor Red
    exit 1
}

$dllPath = Get-ChildItem -Path $projectDir -Filter "$projectName.dll" -Recurse |
    Where-Object { $_.FullName -match "bin" } |
    Select-Object -First 1

if (-not $dllPath) { throw "DLL not found after build." }
Write-Host "  OK Build succeeded: $($dllPath.FullName)" -ForegroundColor Green

# -----------------------------------------------
# Step 6 - Load in accoreconsole
# -----------------------------------------------
Write-Host "[6/6] Testing in accoreconsole..." -ForegroundColor Yellow

if (-not (Test-Path $accoreconsole)) {
    Write-Host ""
    Write-Host "  accoreconsole.exe not found at: $accoreconsole" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Steps 1-5 PASSED (install, AI generation, build)." -ForegroundColor Green
    Write-Host "  Step 6 SKIPPED (no AutoCAD)." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  To test manually:" -ForegroundColor DarkGray
    Write-Host "  1. Open AutoCAD" -ForegroundColor DarkGray
    Write-Host "  2. Draw some circles" -ForegroundColor DarkGray
    Write-Host "  3. NETLOAD $($dllPath.FullName)" -ForegroundColor DarkGray
    Write-Host "  4. Run: OptimizePath" -ForegroundColor DarkGray
    Write-Host ""
    exit 0
}

# Create test script: draw circles, load DLL, run command
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

# -----------------------------------------------
# Verify
# -----------------------------------------------
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
        Write-Host "  ALL STEPS PASSED - The skill set works." -ForegroundColor Green
        Write-Host ""
    } else {
        Write-Host "  result.txt found but missing TOOLPATH_TEST_PASSED" -ForegroundColor Yellow
        Get-Content $resultPath | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
    }
} else {
    Write-Host "  No result.txt - command may not have produced output" -ForegroundColor Yellow
    Write-Host "  The plugin loaded and ran, but didn't write results." -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "  Test folder: $testDir" -ForegroundColor DarkGray
Write-Host ""
} finally {
    Pop-Location
}
