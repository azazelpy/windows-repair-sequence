# ============================================================================
# Windows Repair Sequence - Automated Test Suite
# ============================================================================
# Script: test-repair-sequence.ps1
# Purpose: Validate repair scripts functionality
# Usage: .\test-repair-sequence.ps1 [-TestAll] [-TestAdmin] [-TestSyntax]
# ============================================================================

[CmdletBinding()]
param(
    [switch]$TestAll,
    [switch]$TestAdmin,
    [switch]$TestSyntax,
    [switch]$TestLogging,
    [switch]$Verbose
)

$TestResults = @{
    Passed = 0
    Failed = 0
    Skipped = 0
    Total = 0
}

$ScriptDir = $PSScriptRoot
$ParentDir = Split-Path -Parent $ScriptDir

# ============================================================================
# Test Helper Functions
# ============================================================================

function Write-TestHeader {
    param([string]$Text)
    Write-Host ""
    Write-Host "=" * 70 -ForegroundColor Cyan
    Write-Host "  TEST: $Text" -ForegroundColor Cyan
    Write-Host "=" * 70 -ForegroundColor Cyan
    Write-Host ""
}

function Invoke-Test {
    param(
        [string]$Name,
        [scriptblock]$Test,
        [string]$Description
    )
    
    $TestResults.Total++
    Write-Host "  [$($TestResults.Total)] $Name" -NoNewline
    
    try {
        $result = & $Test
        if ($result) {
            Write-Host " - PASSED ✓" -ForegroundColor Green
            $TestResults.Passed++
            return $true
        } else {
            Write-Host " - FAILED ✗" -ForegroundColor Red
            Write-Host "      Description: $Description" -ForegroundColor Yellow
            $TestResults.Failed++
            return $false
        }
    } catch {
        Write-Host " - FAILED ✗ (Exception: $_)" -ForegroundColor Red
        Write-Host "      Description: $Description" -ForegroundColor Yellow
        $TestResults.Failed++
        return $false
    }
}

function Invoke-Test-Skipped {
    param([string]$Name, [string]$Reason)
    $TestResults.Total++
    $TestResults.Skipped++
    Write-Host "  [$($TestResults.Total)] $Name - SKIPPED ($Reason)" -ForegroundColor Yellow
}

# ============================================================================
# Test: Administrator Privileges
# ============================================================================

function Test-AdministratorPrivileges {
    Write-TestHeader "Administrator Privileges"
    
    Invoke-Test "Admin Check Required" -Test {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } -Description "Script requires administrator privileges"
}

# ============================================================================
# Test: Syntax Validation
# ============================================================================

function Test-SyntaxValidation {
    Write-TestHeader "Syntax Validation"
    
    $ps1File = Join-Path -Path $ParentDir -ChildPath "windows_repair_sequence.ps1"
    $batFile = Join-Path -Path $ParentDir -ChildPath "windows_repair_sequence.bat"
    $optimizeFile = Join-Path -Path $ParentDir -ChildPath "windows-optimize.ps1"
    
    Invoke-Test "PowerShell Script Syntax" -Test {
        $errors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $ps1File -Raw), [ref]$errors)
        return $errors.Count -eq 0
    } -Description "PowerShell script has valid syntax"
    
    Invoke-Test "Optimization Script Syntax" -Test {
        $errors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $optimizeFile -Raw), [ref]$errors)
        return $errors.Count -eq 0
    } -Description "Optimization script has valid syntax"
    
    if (Test-Path $batFile) {
        Invoke-Test "Batch File Exists" -Test {
            return (Test-Path $batFile)
        } -Description "Batch file exists"
    } else {
        Invoke-Test-Skipped "Batch File Syntax" "File not found"
    }
}

# ============================================================================
# Test: File Structure
# ============================================================================

function Test-FileStructure {
    Write-TestHeader "File Structure"
    
    $requiredFiles = @(
        "windows_repair_sequence.ps1",
        "windows_repair_sequence.bat",
        "windows-optimize.ps1",
        "windows-optimize.bat",
        "README.md",
        "CHANGELOG.md"
    )
    
    foreach ($file in $requiredFiles) {
        $filePath = Join-Path -Path $ParentDir -ChildPath $file
        Invoke-Test "File: $file" -Test {
            return (Test-Path $filePath)
        } -Description "Required file exists"
    }
}

# ============================================================================
# Test: Logging System
# ============================================================================

function Test-LoggingSystem {
    Write-TestHeader "Logging System"
    
    $testLogFile = Join-Path -Path $ParentDir -ChildPath "test_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    
    Invoke-Test "Log File Creation" -Test {
        try {
            "Test log entry" | Out-File -FilePath $testLogFile -Encoding UTF8
            return (Test-Path $testLogFile)
        } catch {
            return $false
        }
    } -Description "Can create log file"
    
    Invoke-Test "Log File Write" -Test {
        $content = Get-Content $testLogFile -Raw
        return $content -match "Test log entry"
    } -Description "Can write to log file"
    
    Invoke-Test "Log File Cleanup" -Test {
        Remove-Item $testLogFile -Force
        return -not (Test-Path $testLogFile)
    } -Description "Can delete test log file"
}

# ============================================================================
# Test: Security Features
# ============================================================================

function Test-SecurityFeatures {
    Write-TestHeader "Security Features"
    
    $ps1File = Join-Path -Path $ParentDir -ChildPath "windows_repair_sequence.ps1"
    $content = Get-Content $ps1File -Raw
    
    Invoke-Test "Test-SafePath Function" -Test {
        return $content -match "function Test-SafePath"
    } -Description "Path traversal protection exists"
    
    Invoke-Test "Admin Check Present" -Test {
        return $content -match "Test-Administrator"
    } -Description "Administrator check implemented"
    
    Invoke-Test "Error Handling (try/catch)" -Test {
        return ($content -match "try {" -and $content -match "catch {")
    } -Description "Error handling with try/catch"
    
    Invoke-Test "SFC Process Check" -Test {
        return $content -match "Get-Process.*sfc"
    } -Description "SFC process conflict detection"
}

# ============================================================================
# Test: Input Validation
# ============================================================================

function Test-InputValidation {
    Write-TestHeader "Input Validation"
    
    $batFile = Join-Path -Path $ParentDir -ChildPath "windows_repair_sequence.bat"
    $ps1File = Join-Path -Path $ParentDir -ChildPath "windows_repair_sequence.ps1"
    
    Invoke-Test "Batch Input Validation" -Test {
        $content = Get-Content $batFile -Raw
        return ($content -match "if.*choice.*==.*\"\"" -and $content -match "delims=0123456789")
    } -Description "Batch script validates input"
    
    Invoke-Test "PowerShell Parameter Validation" -Test {
        $content = Get-Content $ps1File -Raw
        return $content -match "ValidateSet"
    } -Description "PowerShell validates parameters"
}

# ============================================================================
# Test: Documentation
# ============================================================================

function Test-Documentation {
    Write-TestHeader "Documentation"
    
    $readmeFile = Join-Path -Path $ParentDir -ChildPath "README.md"
    $changelogFile = Join-Path -Path $ParentDir -ChildPath "CHANGELOG.md"
    
    Invoke-Test "README.md Exists" -Test {
        return (Test-Path $readmeFile)
    } -Description "README documentation exists"
    
    Invoke-Test "README Has Usage Examples" -Test {
        $content = Get-Content $readmeFile -Raw
        return ($content -match "## 🚀 Quick Start" -or $content -match "Usage")
    } -Description "README includes usage examples"
    
    Invoke-Test "CHANGELOG.md Exists" -Test {
        return (Test-Path $changelogFile)
    } -Description "Changelog documentation exists"
    
    Invoke-Test "CHANGELOG Has Version 2" -Test {
        $content = Get-Content $changelogFile -Raw
        return $content -match "\[2\."
    } -Description "Changelog includes v2.0.0+"
}

# ============================================================================
# Test: Help System
# ============================================================================

function Test-HelpSystem {
    Write-TestHeader "Help System"
    
    $ps1File = Join-Path -Path $ParentDir -ChildPath "windows_repair_sequence.ps1"
    
    Invoke-Test "Comment-Based Help" -Test {
        $content = Get-Content $ps1File -Raw
        return ($content -match "<#" -and $content -match "\.SYNOPSIS" -and $content -match "\.DESCRIPTION")
    } -Description "PowerShell comment-based help exists"
    
    Invoke-Test "Help Sections" -Test {
        $content = Get-Content $ps1File -Raw
        return ($content -match "\.EXAMPLE" -and $content -match "\.PARAMETER")
    } -Description "Help includes examples and parameters"
}

# ============================================================================
# Main Test Runner
# ============================================================================

function Run-AllTests {
    Write-Host ""
    Write-Host "████████████████████████████████████████████████████████████" -ForegroundColor Cyan
    Write-Host "  WINDOWS REPAIR SEQUENCE - AUTOMATED TEST SUITE" -ForegroundColor Cyan
    Write-Host "  Version 2.1.0" -ForegroundColor Cyan
    Write-Host "████████████████████████████████████████████████████████████" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Test Directory: $ScriptDir"
    Write-Host "Target Directory: $ParentDir"
    Write-Host ""
    
    # Run test suites
    if ($TestAdmin) {
        Test-AdministratorPrivileges
    }
    
    if ($TestSyntax) {
        Test-SyntaxValidation
        Test-FileStructure
    }
    
    if ($TestLogging) {
        Test-LoggingSystem
    }
    
    # Always run these
    Test-SecurityFeatures
    Test-InputValidation
    Test-Documentation
    Test-HelpSystem
    
    # Show summary
    Write-Host ""
    Write-Host "=" * 70 -ForegroundColor Cyan
    Write-Host "  TEST SUMMARY" -ForegroundColor Cyan
    Write-Host "=" * 70 -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Total Tests:   $($TestResults.Total)"
    Write-Host "  Passed:        $($TestResults.Passed) ✓" -ForegroundColor Green
    Write-Host "  Failed:        $($TestResults.Failed) ✗" -ForegroundColor Red
    Write-Host "  Skipped:       $($TestResults.Skipped)" -ForegroundColor Yellow
    Write-Host ""
    
    $passRate = if ($TestResults.Total -gt 0) { [math]::Round($TestResults.Passed / $TestResults.Total * 100, 2) } else { 0 }
    Write-Host "  Pass Rate:     $passRate%" -ForegroundColor $(if ($passRate -ge 90) { "Green" } elseif ($passRate -ge 70) { "Yellow" } else { "Red" })
    Write-Host ""
    
    if ($TestResults.Failed -eq 0) {
        Write-Host "  STATUS: ALL TESTS PASSED ✓" -ForegroundColor Green
        Write-Host ""
        return 0
    } else {
        Write-Host "  STATUS: SOME TESTS FAILED ✗" -ForegroundColor Red
        Write-Host ""
        return 1
    }
}

# Execute tests
if ($TestAll) {
    Test-AdministratorPrivileges
    Test-SyntaxValidation
    Test-FileStructure
    Test-LoggingSystem
    Test-SecurityFeatures
    Test-InputValidation
    Test-Documentation
    Test-HelpSystem
} else {
    Run-AllTests
}

exit $LASTEXITCODE
