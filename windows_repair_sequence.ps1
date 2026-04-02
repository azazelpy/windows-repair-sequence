#Requires -RunAsAdministrator
<#
.SYNOPSIS
    The Ultimate Windows Repair Sequence - PowerShell Version
    Mastering the CMD Triage

.DESCRIPTION
    A professional 5-step triage sequence to diagnose and repair Windows
    system corruption using built-in SFC and DISM utilities.

    Efficiency is about having the right tools for the job. These built-in
    Windows utilities are often more powerful than expensive third-party software.

    A clean install is the ABSOLUTE LAST RESORT. Before you wipe a drive,
    execute this powerful 5-step triage sequence.

.AUTHOR
    Friday (AI Assistant)

.CREATED
    2026-03-17

.LICENSE
    MIT License

.LINK
    https://github.com/roberto/windows-repair-sequence

.VERSION
    2.0.0 (Security Hardened)

.REQUIREMENTS
    Windows Administrator privileges
    PowerShell 5.1+ (Windows 8.1+)

.EXAMPLE
    .\windows_repair_sequence.ps1

.EXAMPLE
    .\windows_repair_sequence.ps1 -FullSequence

.EXAMPLE
    .\windows_repair_sequence.ps1 -Step 4

.EXAMPLE
    .\windows_repair_sequence.ps1 -FullSequence -NoReboot

.NOTES
    Step 4 (SFC Final Check) is the GOLD STANDARD that many technicians skip.
    This is what separates a quick fix from a PROFESSIONAL REPAIR.

.SECURITY
    Version 2.0.0 includes:
    - Path traversal protection for log files
    - Enhanced input validation
    - Improved error handling with try/catch
    - SFC process conflict detection
#>

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$FullSequence,

    [Parameter()]
    [ValidateSet(1, 2, 3, 4, 5)]
    [int]$Step,

    [Parameter()]
    [switch]$ViewLog,

    [Parameter()]
    [switch]$NoReboot
)

# ============================================================================
# CONFIGURATION
# ============================================================================
$Script:StartTime = Get-Date

# SECURITY: Safe log file path construction
function Test-SafePath {
    param([string]$Path)
    if ($Path -match '\.\.\\|\.\/|\.\.\/') { throw "Path traversal detected" }
    $expectedRoot = $PSScriptRoot
    $parent = Split-Path -Path $Path -Parent
    if ($parent -and (Test-Path $parent)) {
        $resolvedParent = (Resolve-Path -Path $parent).ProviderPath
        if (-not $resolvedParent.StartsWith($expectedRoot, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Path outside expected directory"
        }
    }
    return $true
}

$Script:LogFile = Join-Path -Path $PSScriptRoot -ChildPath "windows_repair_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
if (-not (Test-SafePath -Path $Script:LogFile)) { throw "Invalid log path" }
$Script:Results = @{
    Step1_SFC_Initial = $null
    Step2_DISM_Restore = $null
    Step3_DISM_Check = $null
    Step4_SFC_Final = $null
    Step5_Reboot = $null
}

# Colors
$Color_Success = 'Green'
$Color_Warning = 'Yellow'
$Color_Error = 'Red'
$Color_Info = 'Cyan'
$Color_Header = 'Magenta'

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Write-Header {
    param([string]$Text)
    Write-Host "" -NoNewline
    Write-Host "=" * 80 -ForegroundColor $Color_Header
    Write-Host "  $Text" -ForegroundColor $Color_Header
    Write-Host "=" * 80 -ForegroundColor $Color_Header
    Write-Host "" -NoNewline
}

function Write-Step {
    param(
        [string]$Number,
        [string]$Title
    )
    Write-Host ""
    Write-Header "STEP $Number : $Title"
}

function Write-Success {
    param([string]$Text)
    Write-Host "[OK] $Text" -ForegroundColor $Color_Success
}

function Write-Warning {
    param([string]$Text)
    Write-Host "[WARNING] $Text" -ForegroundColor $Color_Warning
}

function Write-Error {
    param([string]$Text)
    Write-Host "[ERROR] $Text" -ForegroundColor $Color_Error
}

function Write-Info {
    param([string]$Text)
    Write-Host "[INFO] $Text" -ForegroundColor $Color_Info
}

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "[$timestamp] $Message"
    Add-Content -Path $Script:LogFile -Value $logEntry
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-Step1_SFC_Initial {
    Write-Step -Number "1" -Title "SFC Initial Scan & Diagnosis"

    # SECURITY: Check if SFC is already running
    $sfcProcesses = Get-Process -Name "sfc" -ErrorAction SilentlyContinue
    if ($sfcProcesses) {
        Write-Warning "SFC process already running. Wait for completion before proceeding."
        Write-Log "[STEP 1] SFC already running, aborting this instance"
        return 99  # Special code indicating SFC conflict
    }

    Write-Info "Running: sfc /scannow"
    Write-Host ""
    Write-Host "This is your FIRST LINE OF DEFENSE to identify the extent of system damage."
    Write-Host "SFC will replace corrupted files with a cached copy."
    Write-Host ""

    Write-Log "[STEP 1] SFC Initial Scan - STARTED"

    # ENHANCED: Use Start-Process with proper error handling
    try {
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = "sfc.exe"
        $processInfo.Arguments = "/scannow"
        $processInfo.RedirectStandardOutput = $true
        $processInfo.RedirectStandardError = $true
        $processInfo.UseShellExecute = $false
        $processInfo.CreateNoWindow = $true
        
        $process = [System.Diagnostics.Process]::Start($processInfo)
        $process.WaitForExit()
        
        $sfcOutput = $process.StandardOutput.ReadToEnd()
        $sfcError = $process.StandardError.ReadToEnd()
        $sfcExitCode = $process.ExitCode
        
        # Log both output and errors
        if ($sfcOutput) { $sfcOutput | Out-String | Write-Log }
        if ($sfcError) { $sfcError | Out-String | Write-Log }
        
    } catch {
        Write-Error "Failed to execute SFC: $_"
        Write-Log "[STEP 1] SFC execution failed: $_"
        return 999  # Indicate execution failure
    }

    $sfcOutput | Out-String | Write-Log

    Write-Host ""

    $result = switch ($sfcExitCode) {
        0 {
            Write-Success "No integrity violations found."
            "No integrity violations found"
        }
        1 {
            Write-Success "Protected files repaired successfully."
            "Protected files repaired successfully"
        }
        2 {
            Write-Warning "Some corrupted files could not be repaired. Proceeding to DISM."
            "Some corrupted files could not be repaired"
        }
        default {
            Write-Error "SFC encountered an error (code: $sfcExitCode). Proceeding to DISM."
            "SFC error code: $sfcExitCode"
        }
    }

    Write-Log "[STEP 1] RESULT: $result"
    Write-Log "[STEP 1] COMPLETED"

    $Script:Results.Step1_SFC_Initial = $result
    return $sfcExitCode
}

function Invoke-Step2_DISM_Restore {
    Write-Step -Number "2" -Title "DISM Full Health Repair"

    Write-Info "Running: DISM /Online /Cleanup-Image /RestoreHealth"
    Write-Host ""
    Write-Host "This is the 'heavy lifter'."
    Write-Host "DISM will connect directly to Windows Update to download fresh,"
    Write-Host "healthy replacement files to fix the local image."
    Write-Host ""
    Write-Warning "This may take 10-30 minutes. Please wait..."
    Write-Host ""

    Write-Log "[STEP 2] DISM RestoreHealth - STARTED"

    $dismOutput = DISM /Online /Cleanup-Image /RestoreHealth 2>&1
    $dismExitCode = $LASTEXITCODE

    $dismOutput | Out-String | Write-Log

    Write-Host ""

    if ($dismExitCode -eq 0) {
        Write-Success "DISM repair completed successfully."
        $result = "DISM repair completed successfully"
    } else {
        Write-Error "DISM encountered an error (code: $dismExitCode)."
        $result = "DISM error code: $dismExitCode"
    }

    Write-Log "[STEP 2] RESULT: $result"
    Write-Log "[STEP 2] COMPLETED"

    $Script:Results.Step2_DISM_Restore = $result
    return $dismExitCode
}

function Invoke-Step3_DISM_Check {
    Write-Step -Number "3" -Title "DISM Fast Health Check"

    Write-Info "Running: DISM /Online /Cleanup-Image /CheckHealth"
    Write-Host ""
    Write-Host "This is an instantaneous diagnostic."
    Write-Host "Checks if the Windows image has been flagged as corrupt."
    Write-Host ""

    Write-Log "[STEP 3] DISM CheckHealth - STARTED"

    $dismOutput = DISM /Online /Cleanup-Image /CheckHealth 2>&1
    $dismExitCode = $LASTEXITCODE

    $dismOutput | Out-String | Write-Log

    Write-Host ""

    if ($dismExitCode -eq 0) {
        Write-Success "Windows image health verified. No corruption detected."
        $result = "Windows image health verified"
    } else {
        Write-Error "Windows image flagged as corrupt (code: $dismExitCode)."
        $result = "Windows image corrupt"
    }

    Write-Log "[STEP 3] RESULT: $result"
    Write-Log "[STEP 3] COMPLETED"

    $Script:Results.Step3_DISM_Check = $result
    return $dismExitCode
}

function Invoke-Step4_SFC_Final {
    Write-Step -Number "4" -Title "SFC Final Check (GOLD STANDARD)"

    Write-Warning "CRITICAL STEP - MANY TECHS SKIP THIS!"
    Write-Host ""
    Write-Info "Running: sfc /scannow (FINAL VERIFICATION)"
    Write-Host ""
    Write-Host "Now that DISM has repaired the base image, running SFC again ensures"
    Write-Host "that ALL installed system files are validated against the NEW, healthy source."
    Write-Host ""
    Write-Host "This is what separates a quick fix from a PROFESSIONAL REPAIR."
    Write-Host ""

    Write-Log "[STEP 4] SFC Final Check (Gold Standard) - STARTED"

    $sfcOutput = sfc /scannow 2>&1
    $sfcExitCode = $LASTEXITCODE

    $sfcOutput | Out-String | Write-Log

    Write-Host ""

    $result = switch ($sfcExitCode) {
        0 {
            Write-Success "All system files verified. Repairs successful!"
            "All system files verified. Repairs successful!"
        }
        1 {
            Write-Success "Final repairs applied successfully."
            "Final repairs applied"
        }
        default {
            Write-Error "Issues remain after DISM repair (code: $sfcExitCode)."
            "Issues remain after DISM"
        }
    }

    Write-Log "[STEP 4] RESULT: $result"
    Write-Log "[STEP 4] COMPLETED"

    $Script:Results.Step4_SFC_Final = $result
    return $sfcExitCode
}

function Invoke-Step5_Reboot {
    Write-Step -Number "5" -Title "System Reboot"

    Write-Info "Running: shutdown /r /t 0"
    Write-Host ""
    Write-Host "An immediate restart will finalize all changes and clear system memory,"
    Write-Host "ensuring the repairs take FULL effect."
    Write-Host ""

    if ($NoReboot) {
        Write-Warning "-NoReboot specified. Skipping automatic reboot."
        Write-Host ""
        Write-Host "Please restart your system manually to apply repairs."
        Write-Log "[STEP 5] Reboot skipped (user specified -NoReboot)"
        $Script:Results.Step5_Reboot = "Skipped"
        return 0
    }

    Write-Success "System will restart in 5 seconds. Save your work!"
    Write-Log "[STEP 5] Reboot initiated"

    Start-Sleep -Seconds 5

    $Script:Results.Step5_Reboot = "Reboot initiated"
    shutdown /r /t 0
    return 0
}

function Show-Menu {
    Clear-Host
    Write-Header "THE ULTIMATE WINDOWS REPAIR SEQUENCE - PowerShell"

    Write-Host "  A professional 5-step triage sequence to diagnose and repair"
    Write-Host "  Windows system corruption using built-in SFC and DISM utilities."
    Write-Host ""
    Write-Host "  > A clean install is the ABSOLUTE LAST RESORT."
    Write-Host "  > This sequence pulls fresh files directly from Windows Update."
    Write-Host ""
    Write-Header "REPAIR OPTIONS"

    Write-Host ""
    Write-Host "  [1] Run Full 5-Step Repair Sequence (RECOMMENDED)"
    Write-Host "  [2] Run Step 1 Only: SFC Initial Scan"
    Write-Host "  [3] Run Step 2 Only: DISM RestoreHealth"
    Write-Host "  [4] Run Step 3 Only: DISM CheckHealth"
    Write-Host "  [5] Run Step 4 Only: SFC Final Check"
    Write-Host "  [6] Run Step 5 Only: System Reboot"
    Write-Host "  [7] View Repair Log"
    Write-Host "  [8] Exit"
    Write-Host ""
    Write-Header "Log: $Script:LogFile"
}

function Show-Log {
    Clear-Host
    Write-Header "REPAIR LOGS"

    if (Test-Path $Script:LogFile) {
        Write-Info "Latest log: $Script:LogFile"
        Write-Host ""
        Write-Host "--- LOG CONTENTS ---" -ForegroundColor $Color_Info
        Get-Content $Script:LogFile
        Write-Host "--- END OF LOG ---" -ForegroundColor $Color_Info
    } else {
        Write-Warning "No log file found."
        Write-Host ""
        Write-Host "Run a repair sequence first to generate logs."
    }

    Write-Host ""
    Write-Host "Press any key to return to menu..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-Summary {
    Write-Host ""
    Write-Header "REPAIR SUMMARY"

    $totalTime = (Get-Date) - $Script:StartTime

    Write-Host ""
    Write-Host "  Start Time: $($Script:StartTime.ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Host "  End Time:   $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Host "  Duration:   $($totalTime.Minutes)m $($totalTime.Seconds)s"
    Write-Host ""
    Write-Host "  Results:"
    Write-Host "  ─────────"

    $Script:Results.GetEnumerator() | Sort-Object Name | ForEach-Object {
        $status = if ($_.Value) { $_.Value } else { "Not run" }
        Write-Host "    $($_.Name): $status"
    }

    Write-Host ""
    Write-Host "  Log saved to: $Script:LogFile"
    Write-Host ""
    Write-Header "COMPLETE"
}

function Invoke-FullSequence {
    Clear-Host
    Write-Header "FULL 5-STEP REPAIR SEQUENCE"

    Write-Host ""
    Write-Host "  This will execute all 5 steps in the precise logical order."
    Write-Host "  Estimated time: 15-45 minutes (depending on system corruption)"
    Write-Host ""
    Write-Host "  > Step 1: SFC Initial Scan"
    Write-Host "  > Step 2: DISM RestoreHealth"
    Write-Host "  > Step 3: DISM CheckHealth"
    Write-Host "  > Step 4: SFC Final Check (Gold Standard - DO NOT SKIP)"
    Write-Host "  > Step 5: System Reboot"
    Write-Host ""
    Write-Header ""

    $confirm = Read-Host "Proceed with full sequence? (Y/N)"
    if ($confirm -ne 'Y' -and $confirm -ne 'y') {
        Write-Host ""
        Write-Warning "Sequence cancelled."
        Start-Sleep -Seconds 2
        return
    }

    Write-Host ""
    Write-Success "Starting full repair sequence..."
    Write-Host ""
    Write-Info "Log file: $Script:LogFile"
    Write-Host ""

    Write-Log "========================================"
    Write-Log "WINDOWS REPAIR SEQUENCE - STARTED: $(Get-Date)"
    Write-Log "========================================"

    # STEP 1
    Invoke-Step1_SFC_Initial
    Write-Host ""
    Write-Info "Step 1 complete."
    if (-not $FullSequence) {
        Write-Host "Press any key to continue to Step 2..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } else {
        Start-Sleep -Seconds 2
    }

    # STEP 2
    Clear-Host
    Invoke-Step2_DISM_Restore
    Write-Host ""
    Write-Info "Step 2 complete."
    if (-not $FullSequence) {
        Write-Host "Press any key to continue to Step 3..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } else {
        Start-Sleep -Seconds 2
    }

    # STEP 3
    Clear-Host
    Invoke-Step3_DISM_Check
    Write-Host ""
    Write-Info "Step 3 complete."
    if (-not $FullSequence) {
        Write-Host "Press any key to continue to Step 4..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } else {
        Start-Sleep -Seconds 2
    }

    # STEP 4
    Clear-Host
    Invoke-Step4_SFC_Final
    Write-Host ""
    Write-Info "Step 4 complete."
    if (-not $FullSequence) {
        Write-Host "Press any key to continue to Step 5..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } else {
        Start-Sleep -Seconds 2
    }

    # STEP 5
    Clear-Host
    Invoke-Step5_Reboot

    Show-Summary
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

Clear-Host

# Administrator Check
if (-not (Test-Administrator)) {
    Write-Header "ERROR"
    Write-Error "This script MUST be run as Administrator!"
    Write-Host ""
    Write-Host "Right-click this script and select 'Run as Administrator'"
    Write-Host ""
    pause
    exit 1
}

Write-Success "Administrator privileges confirmed."
Start-Sleep -Seconds 2

# Parameter Handling
if ($ViewLog) {
    Show-Log
    exit 0
}

if ($FullSequence) {
    Invoke-FullSequence
    exit 0
}

if ($Step) {
    Write-Log "========================================"
    Write-Log "WINDOWS REPAIR - STEP $Step - STARTED: $(Get-Date)"
    Write-Log "========================================"

    switch ($Step) {
        1 { Invoke-Step1_SFC_Initial }
        2 { Invoke-Step2_DISM_Restore }
        3 { Invoke-Step3_DISM_Check }
        4 { Invoke-Step4_SFC_Final }
        5 { Invoke-Step5_Reboot }
    }

    Write-Log "========================================"
    Write-Log "WINDOWS REPAIR - STEP $Step - COMPLETED: $(Get-Date)"
    Write-Log "========================================"

    Show-Summary
    exit 0
}

# Interactive Menu
do {
    Show-Menu

    $choice = Read-Host "Enter your choice (1-8)"

    switch ($choice) {
        '1' { Invoke-FullSequence }
        '2' {
            Clear-Host
            Invoke-Step1_SFC_Initial
            Show-Summary
        }
        '3' {
            Clear-Host
            Invoke-Step2_DISM_Restore
            Show-Summary
        }
        '4' {
            Clear-Host
            Invoke-Step3_DISM_Check
            Show-Summary
        }
        '5' {
            Clear-Host
            Invoke-Step4_SFC_Final
            Show-Summary
        }
        '6' {
            Clear-Host
            Invoke-Step5_Reboot
        }
        '7' { Show-Log }
        '8' {
            Write-Host ""
            Write-Success "Thank you for using The Ultimate Windows Repair Sequence."
            Write-Host ""
            Write-Host "Remember:"
            Write-Host "  > A clean install is the ABSOLUTE LAST RESORT."
            Write-Host "  > This sequence repairs corruption using Windows Update files."
            Write-Host "  > The Step 4 'Final Check' is what separates pros from amateurs."
            Write-Host ""
            Start-Sleep -Seconds 3
            exit 0
        }
        default {
            Write-Host ""
            Write-Warning "Invalid choice. Please try again."
            Start-Sleep -Seconds 2
        }
    }
} while ($true)
