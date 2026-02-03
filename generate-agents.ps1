<#
.SYNOPSIS
    PowerShell wrapper for generate-agents.sh (Windows)

.DESCRIPTION
    Automatically detects and uses WSL or Git Bash to run generate-agents.sh.
    This script exists because generate-agents.sh is a bash script that cannot
    run natively in PowerShell.

.PARAMETER Arguments
    All arguments are passed directly to generate-agents.sh

.EXAMPLE
    .\generate-agents.ps1 --help

.EXAMPLE
    .\generate-agents.ps1 --language=python --type=cli-tools --path=./my-project

.EXAMPLE
    .\generate-agents.ps1 --upgrade --path=./my-project

.NOTES
    Requires one of:
    - WSL (Windows Subsystem for Linux) - recommended
    - Git Bash (comes with Git for Windows)
#>

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BashScript = Join-Path $ScriptDir "generate-agents.sh"

# Convert Windows path to WSL path
function Convert-ToWslPath {
    param([string]$WindowsPath)
    $WindowsPath = (Resolve-Path $WindowsPath -ErrorAction SilentlyContinue).Path
    if (-not $WindowsPath) { return $null }
    # C:\Users\foo -> /mnt/c/Users/foo
    $drive = $WindowsPath.Substring(0, 1).ToLower()
    $rest = $WindowsPath.Substring(2).Replace('\', '/')
    return "/mnt/$drive$rest"
}

# Check for WSL (skip on GitHub Actions where it's unreliable)
$wslAvailable = $false
if (-not $env:GITHUB_ACTIONS) {
    try {
        $wslCheck = wsl --status 2>&1
        if ($LASTEXITCODE -eq 0 -or $wslCheck -match "Default Distribution") {
            $wslAvailable = $true
        }
    } catch {
        $wslAvailable = $false
    }
}

# Check for Git Bash
$gitBashPath = $null
$gitBashLocations = @(
    "$env:ProgramFiles\Git\bin\bash.exe",
    "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
    "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
)
foreach ($path in $gitBashLocations) {
    if (Test-Path $path) {
        $gitBashPath = $path
        break
    }
}

# Check for native bash (macOS/Linux with PowerShell installed)
$nativeBash = $null
if (Test-Path "/bin/bash") {
    $nativeBash = "/bin/bash"
} elseif (Test-Path "/usr/bin/bash") {
    $nativeBash = "/usr/bin/bash"
}

# Run with native bash (macOS/Linux)
if ($nativeBash) {
    Write-Host "[INFO] Running via native bash..." -ForegroundColor Cyan
    & $nativeBash $BashScript $Arguments
    exit $LASTEXITCODE
}

# Run with WSL (Windows preferred)
if ($wslAvailable) {
    $wslScriptPath = Convert-ToWslPath $BashScript
    if (-not $wslScriptPath) {
        Write-Error "Failed to convert script path for WSL"
        exit 1
    }

    # Convert --path argument if present
    $convertedArgs = @()
    for ($i = 0; $i -lt $Arguments.Count; $i++) {
        $arg = $Arguments[$i]
        if ($arg -match "^--path=(.+)$") {
            $pathValue = $Matches[1]
            $wslPath = Convert-ToWslPath $pathValue
            if ($wslPath) {
                $convertedArgs += "--path=$wslPath"
            } else {
                $convertedArgs += $arg
            }
        } else {
            $convertedArgs += $arg
        }
    }

    Write-Host "[INFO] Running via WSL..." -ForegroundColor Cyan
    wsl bash $wslScriptPath $convertedArgs
    exit $LASTEXITCODE
}

# Run with Git Bash (fallback)
if ($gitBashPath) {
    Write-Host "[INFO] Running via Git Bash..." -ForegroundColor Cyan
    # Quote each argument to preserve commas and special characters
    $quotedArgs = $Arguments | ForEach-Object { "'$($_ -replace "'", "'\''")'" }
    $argString = $quotedArgs -join ' '
    & $gitBashPath -c "cd '$ScriptDir' && ./generate-agents.sh $argString"
    exit $LASTEXITCODE
}

# Neither available
Write-Host ""
Write-Host "ERROR: No bash environment found." -ForegroundColor Red
Write-Host ""
Write-Host "generate-agents.sh requires bash. Install one of:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. WSL (recommended):" -ForegroundColor White
Write-Host "     wsl --install" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Git for Windows (includes Git Bash):" -ForegroundColor White
Write-Host "     https://git-scm.com/download/win" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. MSYS2:" -ForegroundColor White
Write-Host "     https://www.msys2.org/" -ForegroundColor Gray
Write-Host ""
exit 1

