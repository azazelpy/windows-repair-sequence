@echo off
:: ============================================================================
:: The Ultimate Windows Repair Sequence: Mastering the CMD Triage
:: Version: 1.0.0
:: ============================================================================
:: A professional 5-step triage sequence to diagnose and repair Windows system
:: corruption using built-in SFC and DISM utilities.
::
:: Efficiency is about having the right tools for the job. These built-in
:: Windows utilities are often more powerful than expensive third-party software.
::
:: ESSENTIAL TOOLKIT FOR EVERY IT TECHNICIAN
:: A clean install is the absolute last resort. Before you wipe a drive,
:: execute this powerful 5-step triage sequence.
:: ============================================================================
::
:: AUTHOR:     Friday (AI Assistant)
:: CREATED:    2026-03-17
:: LICENSE:    MIT License
:: REPO:       https://github.com/roberto/windows-repair-sequence
:: VERSION:    1.0.0
:: REQUIREMENTS: Windows Administrator privileges
:: ============================================================================
::
:: SEQUENCE OVERVIEW:
:: ┌─────────────────────────────────────────────────────────────────────────┐
:: │  Step 1: sfc /scannow          → Initial Scan & Diagnosis              │
:: │  Step 2: DISM /RestoreHealth   → Full Health Repair (Windows Update)   │
:: │  Step 3: DISM /CheckHealth     → Fast Health Check (verification)      │
:: │  Step 4: sfc /scannow          → Final Check (Gold Standard)           │
:: │  Step 5: shutdown /r /t 0      → System Reboot                         │
:: └─────────────────────────────────────────────────────────────────────────┘
::
:: What separates a quick fix from a professional repair?
:: Mastering this flow, including the critical 'final check' that many techs skip.
:: ============================================================================

setlocal EnableDelayedExpansion

:: ============================================================================
:: CONFIGURATION
:: ============================================================================
set "LOG_FILE=%~dp0windows_repair_%DATE:~-4%%DATE:~3,2%%DATE:~0,2%_%TIME:~0,2%%TIME:~3,2%.log"
set "LOG_FILE=%LOG_FILE: =0%"
set "LOG_FILE=%LOG_FILE::=%"

:: Colors
set "GREEN=[92m"
set "YELLOW=[93m"
set "RED=[91m"
set "BLUE=[94m"
set "WHITE=[97m"
set "RESET=[0m"

:: ============================================================================
:: HEADER
:: ============================================================================
:header
cls
echo.
echo ============================================================================
echo   THE ULTIMATE WINDOWS REPAIR SEQUENCE
echo   Mastering the CMD Triage
echo ============================================================================
echo.
echo   A professional 5-step triage sequence to diagnose and repair
echo   Windows system corruption using built-in SFC and DISM utilities.
echo.
echo   ^> A clean install is the ABSOLUTE LAST RESORT.
echo   ^> This sequence pulls fresh files directly from Windows Update.
echo.
echo ============================================================================
echo.

:: ============================================================================
:: ADMIN CHECK
:: ============================================================================
:admin_check
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo %RED%[ERROR]%RESET% This script MUST be run as Administrator!
    echo.
    echo Right-click this script and select "Run as Administrator"
    echo.
    pause
    exit /b 1
)

echo %GREEN%[OK]%RESET% Administrator privileges confirmed.
echo.
timeout /t 2 /nobreak >nul

:: ============================================================================
:: MAIN MENU
:: ============================================================================
:main_menu
echo.
echo ============================================================================
echo   REPAIR OPTIONS
echo ============================================================================
echo.
echo   [1] Run Full 5-Step Repair Sequence (RECOMMENDED)
echo   [2] Run Step 1 Only: SFC Initial Scan
echo   [3] Run Step 2 Only: DISM RestoreHealth
echo   [4] Run Step 3 Only: DISM CheckHealth
echo   [5] Run Step 4 Only: SFC Final Check
echo   [6] Run Step 5 Only: System Reboot
echo   [7] View Repair Log
echo   [8] Exit
echo.
echo ============================================================================
echo.
set /p "choice=Enter your choice (1-8): "

if "%choice%"=="1" goto full_sequence
if "%choice%"=="2" goto step1_sfc_initial
if "%choice%"=="3" goto step2_dism_restore
if "%choice%"=="4" goto step3_dism_check
if "%choice%"=="5" goto step4_sfc_final
if "%choice%"=="6" goto step5_reboot
if "%choice%"=="7" goto view_log
if "%choice%"=="8" goto exit_script

echo %RED%Invalid choice. Please try again.%RESET%
timeout /t 2 /nobreak >nul
goto main_menu

:: ============================================================================
:: FULL 5-STEP SEQUENCE
:: ============================================================================
:full_sequence
cls
echo.
echo ============================================================================
echo   FULL 5-STEP REPAIR SEQUENCE
echo ============================================================================
echo.
echo   This will execute all 5 steps in the precise logical order.
echo   Estimated time: 15-45 minutes (depending on system corruption)
echo.
echo   ^> Step 1: SFC Initial Scan
echo   ^> Step 2: DISM RestoreHealth
echo   ^> Step 3: DISM CheckHealth
echo   ^> Step 4: SFC Final Check (Gold Standard - DO NOT SKIP)
echo   ^> Step 5: System Reboot
echo.
echo ============================================================================
echo.

set /p "confirm=Proceed with full sequence? (Y/N): "
if /i not "!confirm!"=="Y" (
    echo Sequence cancelled.
    timeout /t 2 /nobreak >nul
    goto main_menu
)

echo.
echo %GREEN%Starting full repair sequence...%RESET%
echo.
echo Log file: %LOG_FILE%
echo.
timeout /t 3 /nobreak >nul

:: Log start
echo ============================================================================ >> "%LOG_FILE%"
echo WINDOWS REPAIR SEQUENCE - STARTED: %DATE% %TIME% >> "%LOG_FILE%"
echo ============================================================================ >> "%LOG_FILE%"

:: STEP 1
echo.
echo ============================================================================
echo   STEP 1 of 5: SFC Initial Scan ^& Diagnosis
echo ============================================================================
echo %BLUE%Scanning all protected system files...%RESET%
echo.
echo This is your FIRST LINE OF DEFENSE to identify the extent of system damage.
echo SFC will replace corrupted files with a cached copy.
echo.
call :step1_sfc_initial
if !errorLevel! neq 0 (
    echo %YELLOW%[WARNING]%RESET% SFC initial scan found issues. Proceeding to DISM repair...
) >> "%LOG_FILE%" 2>&1

echo.
echo Step 1 complete. Press any key to continue to Step 2...
pause >nul

:: STEP 2
cls
echo.
echo ============================================================================
echo   STEP 2 of 5: DISM Full Health Repair
echo ============================================================================
echo %BLUE%Running the "heavy lifter"...%RESET%
echo.
echo DISM will connect directly to Windows Update to download fresh,
echo healthy replacement files to fix the local image.
echo.
call :step2_dism_restore >> "%LOG_FILE%" 2>&1

echo.
echo Step 2 complete. Press any key to continue to Step 3...
pause >nul

:: STEP 3
cls
echo.
echo ============================================================================
echo   STEP 3 of 5: DISM Fast Health Check
echo ============================================================================
echo %BLUE%Running instantaneous diagnostic...%RESET%
echo.
echo This checks if the Windows image has been flagged as corrupt.
echo Used to verify system status without a deep scan.
echo.
call :step3_dism_check >> "%LOG_FILE%" 2>&1

echo.
echo Step 3 complete. Press any key to continue to Step 4...
pause >nul

:: STEP 4 (GOLD STANDARD - MANY SKIP THIS)
cls
echo.
echo ============================================================================
echo   STEP 4 of 5: SFC Final Check (GOLD STANDARD)
echo ============================================================================
echo %GREEN%CRITICAL STEP - MANY TECHS SKIP THIS!%RESET%
echo.
echo Now that DISM has repaired the base image, running SFC again ensures
echo that ALL installed system files are validated against the NEW, healthy source.
echo.
echo %YELLOW%This is what separates a quick fix from a PROFESSIONAL REPAIR.%RESET%
echo.
call :step4_sfc_final >> "%LOG_FILE%" 2>&1

echo.
echo Step 4 complete. Press any key to continue to Step 5...
pause >nul

:: STEP 5
cls
echo.
echo ============================================================================
echo   STEP 5 of 5: System Reboot
echo ============================================================================
echo %BLUE%Preparing system restart...%RESET%
echo.
echo An immediate restart will finalize all changes and clear system memory,
echo ensuring the repairs take FULL effect.
echo.
echo %GREEN%All repairs will be applied after reboot.%RESET%
echo.
call :step5_reboot

goto exit_script

:: ============================================================================
:: STEP FUNCTIONS
:: ============================================================================

:step1_sfc_initial
echo. >> "%LOG_FILE%"
echo [STEP 1] SFC Initial Scan - %DATE% %TIME% >> "%LOG_FILE%"
echo ------------------------------------------- >> "%LOG_FILE%"
echo.
echo %WHITE%Running: sfc /scannow%RESET%
echo.
sfc /scannow
set "SFC_RESULT=%errorLevel%"
echo.
if %SFC_RESULT% equ 0 (
    echo %GREEN%[RESULT]%RESET% No integrity violations found.
    echo [RESULT] No integrity violations found. >> "%LOG_FILE%"
) else if %SFC_RESULT% equ 1 (
    echo %GREEN%[RESULT]%RESET% Protected files repaired successfully.
    echo [RESULT] Protected files repaired successfully. >> "%LOG_FILE%"
) else if %SFC_RESULT% equ 2 (
    echo %YELLOW%[RESULT]%RESET% Some corrupted files could not be repaired. Proceed to DISM.
    echo [RESULT] Some corrupted files could not be repaired. >> "%LOG_FILE%"
) else (
    echo %RED%[RESULT]%RESET% SFC encountered an error (code: %SFC_RESULT%). Proceed to DISM.
    echo [RESULT] SFC error code: %SFC_RESULT% >> "%LOG_FILE%"
)
echo. >> "%LOG_FILE%"
exit /b %SFC_RESULT%

:step2_dism_restore
echo. >> "%LOG_FILE%"
echo [STEP 2] DISM RestoreHealth - %DATE% %TIME% >> "%LOG_FILE%"
echo ------------------------------------------- >> "%LOG_FILE%"
echo.
echo %WHITE%Running: DISM /Online /Cleanup-Image /RestoreHealth%RESET%
echo.
echo This may take 10-30 minutes. Please wait...
echo.
DISM /Online /Cleanup-Image /RestoreHealth
set "DISM_RESULT=%errorLevel%"
echo.
if %DISM_RESULT% equ 0 (
    echo %GREEN%[RESULT]%RESET% DISM repair completed successfully.
    echo [RESULT] DISM repair completed successfully. >> "%LOG_FILE%"
) else (
    echo %RED%[RESULT]%RESET% DISM encountered an error (code: %DISM_RESULT%).
    echo [RESULT] DISM error code: %DISM_RESULT% >> "%LOG_FILE%"
)
echo. >> "%LOG_FILE%"
exit /b %DISM_RESULT%

:step3_dism_check
echo. >> "%LOG_FILE%"
echo [STEP 3] DISM CheckHealth - %DATE% %TIME% >> "%LOG_FILE%"
echo ------------------------------------------- >> "%LOG_FILE%"
echo.
echo %WHITE%Running: DISM /Online /Cleanup-Image /CheckHealth%RESET%
echo.
DISM /Online /Cleanup-Image /CheckHealth
set "CHECK_RESULT=%errorLevel%"
echo.
if %CHECK_RESULT% equ 0 (
    echo %GREEN%[RESULT]%RESET% Windows image health verified. No corruption detected.
    echo [RESULT] Windows image health verified. >> "%LOG_FILE%"
) else (
    echo %RED%[RESULT]%RESET% Windows image flagged as corrupt (code: %CHECK_RESULT%).
    echo [RESULT] Windows image corrupt. >> "%LOG_FILE%"
)
echo. >> "%LOG_FILE%"
exit /b %CHECK_RESULT%

:step4_sfc_final
echo. >> "%LOG_FILE%"
echo [STEP 4] SFC Final Check (Gold Standard) - %DATE% %TIME% >> "%LOG_FILE%"
echo ------------------------------------------- >> "%LOG_FILE%"
echo.
echo %WHITE%Running: sfc /scannow (FINAL VERIFICATION)%RESET%
echo.
echo %GREEN%This is the PROFESSIONAL step that validates ALL repairs.%RESET%
echo.
sfc /scannow
set "SFC_FINAL=%errorLevel%"
echo.
if %SFC_FINAL% equ 0 (
    echo %GREEN%[RESULT]%RESET% All system files verified. Repairs successful!
    echo [RESULT] All system files verified. Repairs successful! >> "%LOG_FILE%"
) else if %SFC_FINAL% equ 1 (
    echo %GREEN%[RESULT]%RESET% Final repairs applied successfully.
    echo [RESULT] Final repairs applied. >> "%LOG_FILE%"
) else (
    echo %RED%[RESULT]%RESET% Issues remain after DISM repair (code: %SFC_FINAL%).
    echo [RESULT] Issues remain after DISM. >> "%LOG_FILE%"
)
echo. >> "%LOG_FILE%"
exit /b %SFC_FINAL%

:step5_reboot
echo. >> "%LOG_FILE%"
echo [STEP 5] System Reboot - %DATE% %TIME% >> "%LOG_FILE%"
echo ------------------------------------------- >> "%LOG_FILE%"
echo.
echo %WHITE%Running: shutdown /r /t 0%RESET%
echo.
echo [RESULT] System reboot initiated. >> "%LOG_FILE%"
echo.
echo %GREEN%System will restart in 5 seconds. Save your work!%RESET%
echo.
timeout /t 5 /nobreak
shutdown /r /t 0
exit /b 0

:: ============================================================================
:: UTILITY FUNCTIONS
:: ============================================================================

:view_log
cls
echo.
echo ============================================================================
echo   REPAIR LOGS
echo ============================================================================
echo.
if exist "%LOG_FILE%" (
    echo Latest log: %LOG_FILE%
    echo.
    echo --- LOG CONTENTS ---
    type "%LOG_FILE%"
    echo --- END OF LOG ---
) else (
    echo No log file found.
    echo.
    echo Run a repair sequence first to generate logs.
)
echo.
echo ============================================================================
echo.
pause
goto main_menu

:exit_script
cls
echo.
echo ============================================================================
echo   WINDOWS REPAIR SEQUENCE - COMPLETE
echo ============================================================================
echo.
echo %GREEN%Thank you for using The Ultimate Windows Repair Sequence.%RESET%
echo.
echo Remember:
echo   ^> A clean install is the ABSOLUTE LAST RESORT.
echo   ^> This sequence repairs corruption using Windows Update files.
echo   ^> The Step 4 "Final Check" is what separates pros from amateurs.
echo.
echo Log saved to: %LOG_FILE%
echo.
echo ============================================================================
echo.
echo %GREEN%System ready. Good luck!%RESET%
echo.
timeout /t 3 /nobreak >nul
exit /b 0

:: ============================================================================
:: END OF SCRIPT
:: ============================================================================
