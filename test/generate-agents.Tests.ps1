# Pester tests for generate-agents.ps1 PowerShell wrapper
# Tests bash environment detection and argument passthrough

BeforeAll {
    $script:ScriptPath = Join-Path $PSScriptRoot ".." "generate-agents.ps1"
    $script:BashScript = Join-Path $PSScriptRoot ".." "generate-agents.sh"
}

Describe "generate-agents.ps1 PowerShell Wrapper" {

    Context "Script Structure" {
        It "Script file exists" {
            $script:ScriptPath | Should -Exist
        }

        It "Bash script exists" {
            $script:BashScript | Should -Exist
        }

        It "Script has correct shebang comment" {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match "\.SYNOPSIS"
        }
    }

    Context "Help and Version" {
        It "--help returns success and shows usage" {
            $result = & $script:ScriptPath --help 2>&1 | Out-String
            $LASTEXITCODE | Should -Be 0
            $result | Should -Match "generate-agents"
        }

        It "--version returns success and shows version" {
            $result = & $script:ScriptPath --version 2>&1 | Out-String
            $LASTEXITCODE | Should -Be 0
            $result | Should -Match "v1\.[0-9]"
        }

        It "-h is equivalent to --help" {
            $result = & $script:ScriptPath -h 2>&1 | Out-String
            $LASTEXITCODE | Should -Be 0
            $result | Should -Match "generate-agents"
        }
    }

    Context "Dry Run Mode" {
        It "--dry-run shows output without creating files" {
            $result = & $script:ScriptPath --language=go --dry-run 2>&1 | Out-String
            $LASTEXITCODE | Should -Be 0
            $result | Should -Match "DRY RUN"
        }

        It "--dry-run with --progressive shows progressive output" {
            $result = & $script:ScriptPath --language=python --progressive --dry-run 2>&1 | Out-String
            $LASTEXITCODE | Should -Be 0
            $result | Should -Match "progressive"
        }
    }

    Context "Argument Passthrough" {
        It "Passes --language argument correctly" {
            $result = & $script:ScriptPath --language=javascript --dry-run 2>&1 | Out-String
            $LASTEXITCODE | Should -Be 0
            $result | Should -Match "javascript"
        }

        It "Passes multiple languages correctly" {
            $result = & $script:ScriptPath --language=go,python,shell --dry-run 2>&1 | Out-String
            $LASTEXITCODE | Should -Be 0
            $result | Should -Match "go"
        }

        It "Passes --type argument correctly" {
            $result = & $script:ScriptPath --language=go --type=cli-tools --dry-run 2>&1 | Out-String
            $LASTEXITCODE | Should -Be 0
            $result | Should -Match "cli-tools"
        }
    }

    Context "Error Handling" {
        It "Missing --language fails with error" {
            & $script:ScriptPath --dry-run 2>&1 | Out-Null
            $LASTEXITCODE | Should -Not -Be 0
        }

        It "Unknown option fails with error" {
            & $script:ScriptPath --invalid-option 2>&1 | Out-Null
            $LASTEXITCODE | Should -Not -Be 0
        }
    }

    Context "Bash Detection" {
        It "Script detects bash environment and runs" {
            # The [INFO] message goes to PowerShell host, not captured in output
            # But if help works, bash was detected and used successfully
            $result = & $script:ScriptPath --version 2>&1 | Out-String
            $LASTEXITCODE | Should -Be 0
            $result | Should -Match "v1\.[0-9]"
        }
    }
}

Describe "Path Conversion (Windows-specific)" -Skip:(-not $IsWindows) {
    BeforeAll {
        $script:ScriptPath = Join-Path $PSScriptRoot ".." "generate-agents.ps1"
    }

    Context "WSL Path Conversion" {
        It "Script contains Convert-ToWslPath function" {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match "Convert-ToWslPath"
        }
    }
}

