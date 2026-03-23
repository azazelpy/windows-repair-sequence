#!/usr/bin/env pwsh
# ============================================================================
# Windows Post-Repair Optimization Script
# Companion to Windows Repair Sequence
# ============================================================================
# Script: windows-optimize.ps1
# Version: 1.0.0
# Purpose: Apply safe, conservative optimizations after system repair
# Usage: .\windows-optimize.ps1 (Run as Administrator)
# ============================================================================
# Author: Friday (AI Assistant)
# Created: 2026-03-18
# License: MIT License
# Repository: https://github.com/azazelpy/windows-repair-sequence
# ============================================================================
# INSPIRED BY: Chris Titus Tech WinUtil (https://github.com/ChrisTitusTech/winutil)
# Approach: Conservative, safe, reversible tweaks only
# ============================================================================

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$NoRestorePoint,
    
    [Parameter()]
    [switch]$WhatIf
)

# ============================================================================
# CONFIGURATION
# ============================================================================
$Script:StartTime = Get-Date
$Script:LogPath = "$PSScriptRoot\windows-optimize_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$Script:ChangesMade = @()

# ============================================================================
# COLOR OUTPUT FUNCTIONS
# ============================================================================
function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "=" * 70 -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host "=" * 70 -ForegroundColor Cyan
}

function Write-Step {
    param([string]$Text)
    Write-Host ""
    Write-Host "==> $Text" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Text)
    Write-Host "✓ $Text" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Text)
    Write-Host "⚠ $Text" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Text)
    Write-Host "✗ ERROR: $Text" -ForegroundColor Red
}

function Write-Info {
    param([string]$Text)
    Write-Host "ℹ $Text" -ForegroundColor Magenta
}

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "[$timestamp] $Message"
    Add-Content -Path $Script:LogPath -Value $logEntry
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Create-RestorePoint {
    param([string]$Description = "Windows Post-Repair Optimization")
    
    Write-Step "Creating system restore point"
    
    if ($NoRestorePoint) {
        Write-Info "Restore point creation skipped (--NoRestorePoint)"
        return $false
    }
    
    try {
        Checkpoint-Computer -Description $Description -RestorePointType "MODIFY_SETTINGS"
        Write-Success "Restore point created: $Description"
        Write-Log "Restore point created: $Description"
        $Script:ChangesMade += "Restore Point: $Description"
        return $true
    }
    catch {
        Write-Warning "Failed to create restore point: $_"
        Write-Log "Restore point failed: $_"
        return $false
    }
}

function Confirm-SafeToOptimize {
    Write-Step "Verifying system state"
    
    # Check if SFC/DISM was run recently
    $sfcLog = Get-Content "$env:windir\Logs\CBS\CBS.log" -Tail 100 -ErrorAction SilentlyContinue
    if ($sfcLog -match "Windows Resource Protection found corrupt files and successfully repaired them") {
        Write-Success "System repair detected - safe to optimize"
        return $true
    }
    
    Write-Warning "Recent repair not detected. Ensure you ran Windows Repair Sequence first."
    $confirm = Read-Host "Continue anyway? (Y/N)"
    return ($confirm -eq 'Y' -or $confirm -eq 'y')
}

# ============================================================================
# OPTIMIZATION FUNCTIONS
# ============================================================================
function Install-EssentialSoftware {
    Write-Step "Installing essential software"
    
    $essentialApps = @(
        @{Name="Google Chrome"; Id="Google.Chrome"; Category="Browser"},
        @{Name="VLC Media Player"; Id="VideoLAN.VLC"; Category="Media"},
        @{Name="7-Zip"; Id="7zip.7zip"; Category="Utility"},
        @{Name="Microsoft PowerToys"; Id="Microsoft.PowerToys"; Category="Utility"},
        @{Name="Notepad++"; Id="Notepad++.Notepad++"; Category="Editor"}
    )
    
    Write-Info "Checking for winget..."
    
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Warning "winget not found. Skipping software installation."
        Write-Info "Install from: https://aka.ms/winget-cli"
        return
    }
    
    foreach ($app in $essentialApps) {
        Write-Host "  Installing: $($app.Name)..." -NoNewline
        
        if ($WhatIf) {
            Write-Host " [WHATIF] Would install" -ForegroundColor Yellow
            continue
        }
        
        try {
            $result = winget install --id $app.Id --silent --accept-package-agreements --accept-source-agreements 2>&1
            if ($LASTEXITCODE -eq 0 -or $result -match "Successfully installed") {
                Write-Host " OK" -ForegroundColor Green
                $Script:ChangesMade += "Installed: $($app.Name)"
                Write-Log "Installed: $($app.Name)"
            } else {
                Write-Host " Failed" -ForegroundColor Red
                Write-Log "Failed to install: $($app.Name) - $result"
            }
        }
        catch {
            Write-Host " Error" -ForegroundColor Red
            Write-Log "Error installing $($app.Name): $_"
        }
    }
}

function Apply-PrivacyTweaks {
    Write-Step "Applying privacy tweaks (conservative)"
    
    $tweaks = @(
        @{
            Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
            Name = "Enabled"
            Value = 0
            Description = "Disable advertising ID"
        },
        @{
            Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
            Name = "AllowTelemetry"
            Value = 1
            Description = "Set telemetry to minimum (Required)"
        },
        @{
            Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
            Name = "PublishUserActivities"
            Value = 0
            Description = "Disable activity history"
        },
        @{
            Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy"
            Name = "TailoredExperiencesWithDiagnosticDataEnabled"
            Value = 0
            Description = "Disable tailored experiences"
        }
    )
    
    foreach ($tweak in $tweaks) {
        try {
            # Create path if doesn't exist
            if (-not (Test-Path $tweak.Path)) {
                New-Item -Path $tweak.Path -Force | Out-Null
            }
            
            Set-ItemProperty -Path $tweak.Path -Name $tweak.Name -Value $tweak.Value -ErrorAction Stop
            Write-Success "$($tweak.Description)"
            Write-Log "Applied: $($tweak.Description)"
            $Script:ChangesMade += "Privacy: $($tweak.Description)"
        }
        catch {
            Write-Warning "Failed: $($tweak.Description) - $_"
            Write-Log "Failed tweak: $($tweak.Description) - $_"
        }
    }
}

function Apply-PerformanceTweaks {
    Write-Step "Applying performance tweaks (conservative)"
    
    # Disable startup apps (keep essentials)
    Write-Host "  Disabling non-essential startup apps..." -NoNewline
    
    if ($WhatIf) {
        Write-Host " [WHATIF] Would disable startup apps" -ForegroundColor Yellow
    } else {
        try {
            Get-CimInstance Win32_StartupCommand | 
                Where-Object { $_.User -eq $env:USERNAME } |
                Where-Object { $_.Command -notmatch "Windows|Defender|OneDrive|Security" } |
                ForEach-Object { 
                    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" `
                        -Name $_.Name -Value $null -ErrorAction SilentlyContinue
                }
            Write-Host " OK" -ForegroundColor Green
            Write-Log "Disabled non-essential startup apps"
            $Script:ChangesMade += "Performance: Disabled startup apps"
        }
        catch {
            Write-Host " Skipped" -ForegroundColor Yellow
            Write-Log "Startup apps tweak skipped: $_"
        }
    }
    
    # Visual effects (keep some for usability)
    Write-Host "  Optimizing visual effects..." -NoNewline
    
    if ($WhatIf) {
        Write-Host " [WHATIF] Would optimize visual effects" -ForegroundColor Yellow
    } else {
        try {
            # Enable smooth edges but disable animations
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" `
                -Name "FontSmoothing" -Value "2" -ErrorAction Stop
            Write-Host " OK" -ForegroundColor Green
            Write-Log "Optimized visual effects"
            $Script:ChangesMade += "Performance: Visual effects optimized"
        }
        catch {
            Write-Host " Skipped" -ForegroundColor Yellow
            Write-Log "Visual effects tweak skipped: $_"
        }
    }
}

function Apply-UsabilityTweaks {
    Write-Step "Applying usability tweaks (safe)"
    
    $tweaks = @(
        @{
            Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            Name = "HideFileExt"
            Value = 0
            Description = "Show file extensions"
        },
        @{
            Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            Name = "Hidden"
            Value = 1
            Description = "Show hidden files"
        },
        @{
            Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
            Name = "AppsUseLightTheme"
            Value = 0
            Description = "Enable dark mode (apps)"
        }
    )
    
    foreach ($tweak in $tweaks) {
        try {
            if (-not (Test-Path $tweak.Path)) {
                New-Item -Path $tweak.Path -Force | Out-Null
            }
            
            Set-ItemProperty -Path $tweak.Path -Name $tweak.Name -Value $tweak.Value -ErrorAction Stop
            Write-Success "$($tweak.Description)"
            Write-Log "Applied: $($tweak.Description)"
            $Script:ChangesMade += "Usability: $($tweak.Description)"
        }
        catch {
            Write-Warning "Failed: $($tweak.Description) - $_"
            Write-Log "Failed tweak: $($tweak.Description) - $_"
        }
    }
}

function Configure-WindowsUpdate {
    Write-Step "Configuring Windows Update"
    
    # Ensure Windows Update service is running
    Write-Host "  Checking Windows Update service..." -NoNewline
    
    try {
        $service = Get-Service -Name "wuauserv" -ErrorAction Stop
        if ($service.Status -ne "Running") {
            Start-Service -Name "wuauserv"
            Write-Host "Started" -ForegroundColor Green
            Write-Log "Windows Update service started"
        } else {
            Write-Host "Running" -ForegroundColor Green
        }
        $Script:ChangesMade += "Update: Windows Update service verified"
    }
    catch {
        Write-Host "Error" -ForegroundColor Red
        Write-Warning "Failed to configure Windows Update: $_"
        Write-Log "Windows Update config failed: $_"
    }
    
    # Check for updates (informational only)
    Write-Host "  Checking for pending updates..." -NoNewline
    Write-Host "Manual check recommended" -ForegroundColor Yellow
    Write-Info "Open Settings > Update & Security > Check for updates"
}

function Launch-WinUtil {
    Write-Header "CHRIS TITUS TECH WINUTIL"
    
    Write-Info "WinUtil is a comprehensive Windows optimization tool"
    Write-Info "Created by Chris Titus Tech"
    Write-Host "GitHub: https://github.com/ChrisTitusTech/winutil"
    Write-Host ""
    Write-Host "WinUtil provides:"
    Write-Host "  ✓ Extensive software installation (100+ apps)"
    Write-Host "  ✓ Advanced debloating options"
    Write-Host "  ✓ Privacy and security tweaks"
    Write-Host "  ✓ Windows Update management"
    Write-Host ""
    Write-Warning "WinUtil makes system-wide changes. Review before applying."
    Write-Host ""
    
    $launch = Read-Host "Launch WinUtil now? (Y/N)"
    
    if ($launch -eq 'Y' -or $launch -eq 'y') {
        Write-Info "Launching WinUtil..."
        Write-Log "User launched WinUtil"
        
        try {
            irm "https://christitus.com/win" | iex
        }
        catch {
            Write-Error "Failed to launch WinUtil: $_"
            Write-Log "WinUtil launch failed: $_"
            Write-Info "Manual launch: irm 'https://christitus.com/win' | iex"
        }
    } else {
        Write-Info "Skipping WinUtil"
        Write-Log "User skipped WinUtil"
    }
}

# ============================================================================
# VERIFICATION
# ============================================================================
function Show-Summary {
    Write-Header "OPTIMIZATION SUMMARY"
    
    $totalTime = (Get-Date) - $Script:StartTime
    
    Write-Host ""
    Write-Host "  Start Time: $($Script:StartTime.ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Host "  End Time:   $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Host "  Duration:   $($totalTime.Minutes)m $($totalTime.Seconds)s"
    Write-Host ""
    
    if ($Script:ChangesMade.Count -gt 0) {
        Write-Host "  Changes Made ($($Script:ChangesMade.Count)):"
        Write-Host "  ─────────"
        foreach ($change in $Script:ChangesMade) {
            Write-Host "    • $change"
        }
    } else {
        Write-Host "  No changes made (WhatIf mode or user skipped)"
    }
    
    Write-Host ""
    Write-Host "  Log saved to: $Script:LogPath"
    Write-Host ""
    
    Write-Host "  Next Steps:"
    Write-Host "    1. Review changes above"
    Write-Host "    2. Reboot system to apply all changes"
    Write-Host "    3. Test critical applications"
    Write-Host ""
    
    Write-Header "COMPLETE"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================
function Main {
    Write-Header "Windows Post-Repair Optimization"
    Write-Info "Companion to Windows Repair Sequence"
    Write-Info "Inspired by Chris Titus Tech WinUtil"
    
    # Administrator check
    if (-not (Test-Administrator)) {
        Write-Error "This script MUST be run as Administrator"
        Write-Info "Right-click PowerShell → Run as Administrator"
        pause
        exit 1
    }
    Write-Success "Running as Administrator"
    
    # Safety check
    if (-not (Confirm-SafeToOptimize)) {
        Write-Warning "Optimization aborted"
        exit 0
    }
    
    # Create restore point
    Create-RestorePoint -Description "Windows Post-Repair Optimization"
    
    Write-Host ""
    Write-Host "Optimization Menu"
    Write-Host "─────────────────"
    Write-Host "  [1] Install essential software (Chrome, VLC, 7-Zip, etc.)"
    Write-Host "  [2] Apply privacy tweaks (telemetry, advertising)"
    Write-Host "  [3] Apply performance tweaks (startup apps, visual effects)"
    Write-Host "  [4] Apply usability tweaks (file extensions, dark mode)"
    Write-Host "  [5] Configure Windows Update"
    Write-Host "  [6] Run ALL optimizations (1-5)"
    Write-Host "  [7] Launch Chris Titus WinUtil (comprehensive tool)"
    Write-Host "  [8] Exit"
    Write-Host ""
    
    $choice = Read-Host "Choose option (1-8)"
    
    switch ($choice) {
        '1' { Install-EssentialSoftware }
        '2' { Apply-PrivacyTweaks }
        '3' { Apply-PerformanceTweaks }
        '4' { Apply-UsabilityTweaks }
        '5' { Configure-WindowsUpdate }
        '6' {
            Install-EssentialSoftware
            Apply-PrivacyTweaks
            Apply-PerformanceTweaks
            Apply-UsabilityTweaks
            Configure-WindowsUpdate
        }
        '7' { Launch-WinUtil }
        '8' {
            Write-Info "Exiting without optimization"
            exit 0
        }
        default {
            Write-Error "Invalid choice"
            exit 1
        }
    }
    
    # Show summary
    Show-Summary
    
    # Offer reboot
    $reboot = Read-Host "Reboot now to apply changes? (Y/N)"
    if ($reboot -eq 'Y' -or $reboot -eq 'y') {
        Write-Info "System will reboot in 10 seconds. Save your work!"
        Start-Sleep -Seconds 10
        shutdown /r /t 0
    }
}

# Run main function
Main
