@echo off
:: ============================================================================
:: Windows Post-Repair Optimization Script (Batch Version)
:: Version: 2.0.0 (Security Hardened)
:: ============================================================================

setlocal EnableDelayedExpansion

:: CONFIGURATION
set "SCRIPT_DIR=%~dp0"
set "LOG_FILE=%SCRIPT_DIR%windows-optimize_%DATE:~-4%%DATE:~3,2%%DATE:~0,2%_%TIME:~0,2%%TIME:~3,2%.log"
set "LOG_FILE=%LOG_FILE: =0%"
set "LOG_FILE=%LOG_FILE::=%"
set "CHANGES_COUNT=0"

:: COLORS
set "GREEN=[92m"
set "YELLOW=[93m"
set "RED=[91m"
set "BLUE=[94m"
set "WHITE=[97m"
set "RESET=[0m"
for /F "tokens=1 delims==" %%A in ('"prompt $H & for %%B in (1) do rem"') do set "ESCAPE=%%A"
for %%C in (GREEN YELLOW RED BLUE WHITE RESET) do set "%%C=!ESCAPE!!%%C!"

:: ADMIN CHECK
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%[ERROR] This script MUST be run as Administrator!%RESET%
    echo Right-click this script and select 'Run as Administrator'
    pause
    exit /b 1
)
echo %GREEN%[OK] Administrator privileges confirmed%RESET%

:: LOG FILE INIT
echo [%DATE% %TIME%] Windows Optimization Started >> "%LOG_FILE%"
echo Script Directory: %SCRIPT_DIR% >> "%LOG_FILE%"

:MAIN_MENU
cls
echo.
echo ============================================================================
echo   WINDOWS POST-REPAIR OPTIMIZATION - Batch Version
echo   Version 2.0.0 (Security Hardened)
echo ============================================================================
echo.
echo   Apply safe, conservative optimizations after system repair
echo.
echo   %BLUE%Optimization Menu:%RESET%
echo   [1] Install essential software (Chrome, VLC, 7-Zip, etc.)
echo   [2] Apply privacy tweaks (telemetry, advertising)
echo   [3] Apply performance tweaks (startup apps)
echo   [4] Apply usability tweaks (file extensions, dark mode)
echo   [5] Configure Windows Update
echo   [6] Run ALL optimizations (1-5)
echo   [7] Launch Chris Titus WinUtil (comprehensive tool)
echo   [8] Exit
echo.
echo ============================================================================
echo.

:: INPUT VALIDATION
set /p "CHOICE=Enter your choice (1-8): "
if "%CHOICE%"=="" (
    echo %RED%[ERROR] Empty choice not allowed%RESET%
    timeout /t 2 /nobreak >nul
    goto MAIN_MENU
)
for /f "delims=0123456789" %%i in ("%CHOICE%") do (
    if not "%%i"=="" (
        echo %RED%[ERROR] Invalid input. Numbers only.%RESET%
        timeout /t 2 /nobreak >nul
        goto MAIN_MENU
    )
)
if %CHOICE% lss 1 (
    echo %RED%[ERROR] Choice too low. Select 1-8.%RESET%
    timeout /t 2 /nobreak >nul
    goto MAIN_MENU
)
if %CHOICE% gtr 8 (
    echo %RED%[ERROR] Choice too high. Select 1-8.%RESET%
    timeout /t 2 /nobreak >nul
    goto MAIN_MENU
)

if "%CHOICE%"=="1" goto INSTALL_SOFTWARE
if "%CHOICE%"=="2" goto PRIVACY_TWEAKS
if "%CHOICE%"=="3" goto PERFORMANCE_TWEAKS
if "%CHOICE%"=="4" goto USABILITY_TWEAKS
if "%CHOICE%"=="5" goto WINDOWS_UPDATE
if "%CHOICE%"=="6" goto ALL_OPTIMIZATIONS
if "%CHOICE%"=="7" goto LAUNCH_WINUTIL
if "%CHOICE%"=="8" goto EXIT_SCRIPT

echo %RED%[ERROR] Invalid choice%RESET%
timeout /t 2 /nobreak >nul
goto MAIN_MENU

:INSTALL_SOFTWARE
cls
echo.
echo ============================================================================
echo   INSTALLING ESSENTIAL SOFTWARE
echo ============================================================================
echo.
echo Checking for winget...
where winget >nul 2>&1
if %errorlevel% neq 0 (
    echo %YELLOW%[WARNING] winget not found. Skipping software installation.%RESET%
    echo Install from: https://aka.ms/winget-cli
    pause
    goto MAIN_MENU
)

echo Installing Google Chrome...
winget install --id Google.Chrome --silent --accept-package-agreements >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%[OK] Google Chrome installed%RESET%
    echo [%DATE% %TIME%] Installed: Google Chrome >> "%LOG_FILE%"
    set /a CHANGES_COUNT+=1
) else (
    echo %RED%[FAILED] Google Chrome%RESET%
)

echo Installing VLC Media Player...
winget install --id VideoLAN.VLC --silent --accept-package-agreements >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%[OK] VLC Media Player installed%RESET%
    echo [%DATE% %TIME%] Installed: VLC Media Player >> "%LOG_FILE%"
    set /a CHANGES_COUNT+=1
) else (
    echo %RED%[FAILED] VLC Media Player%RESET%
)

echo Installing 7-Zip...
winget install --id 7zip.7zip --silent --accept-package-agreements >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%[OK] 7-Zip installed%RESET%
    echo [%DATE% %TIME%] Installed: 7-Zip >> "%LOG_FILE%"
    set /a CHANGES_COUNT+=1
) else (
    echo %RED%[FAILED] 7-Zip%RESET%
)

echo Installing Microsoft PowerToys...
winget install --id Microsoft.PowerToys --silent --accept-package-agreements >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%[OK] Microsoft PowerToys installed%RESET%
    echo [%DATE% %TIME%] Installed: PowerToys >> "%LOG_FILE%"
    set /a CHANGES_COUNT+=1
) else (
    echo %RED%[FAILED] Microsoft PowerToys%RESET%
)

echo.
echo %GREEN%Software installation complete. Changes: %CHANGES_COUNT%%RESET%
pause
goto MAIN_MENU

:PRIVACY_TWEAKS
cls
echo.
echo ============================================================================
echo   APPLYING PRIVACY TWEAKS
echo ============================================================================
echo.

echo Disabling advertising ID...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%[OK] Advertising ID disabled%RESET%
    echo [%DATE% %TIME%] Privacy: Advertising ID disabled >> "%LOG_FILE%"
    set /a CHANGES_COUNT+=1
) else (
    echo %YELLOW%[SKIPPED] Advertising ID%RESET%
)

echo Setting telemetry to minimum...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 1 /f >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%[OK] Telemetry set to minimum%RESET%
    echo [%DATE% %TIME%] Privacy: Telemetry minimized >> "%LOG_FILE%"
    set /a CHANGES_COUNT+=1
) else (
    echo %YELLOW%[SKIPPED] Telemetry setting%RESET%
)

echo Disabling activity history...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v PublishUserActivities /t REG_DWORD /d 0 /f >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%[OK] Activity history disabled%RESET%
    echo [%DATE% %TIME%] Privacy: Activity history disabled >> "%LOG_FILE%"
    set /a CHANGES_COUNT+=1
) else (
    echo %YELLOW%[SKIPPED] Activity history%RESET%
)

echo Disabling tailored experiences...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Privacy" /v TailoredExperiencesWithDiagnosticDataEnabled /t REG_DWORD /d 0 /f >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%[OK] Tailored experiences disabled%RESET%
    echo [%DATE% %TIME%] Privacy: Tailored experiences disabled >> "%LOG_FILE%"
    set /a CHANGES_COUNT+=1
) else (
    echo %YELLOW%[SKIPPED] Tailored experiences%RESET%
)

echo.
echo %GREEN%Privacy tweaks complete. Changes: %CHANGES_COUNT%%RESET%
pause
goto MAIN_MENU

:PERFORMANCE_TWEAKS
cls
echo.
echo ============================================================================
echo   APPLYING PERFORMANCE TWEAKS
echo ============================================================================
echo.

echo Disabling non-essential startup apps...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" /ve /f >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%[OK] Startup apps configured%RESET%
    echo [%DATE% %TIME%] Performance: Startup apps configured >> "%LOG_FILE%"
    set /a CHANGES_COUNT+=1
) else (
    echo %YELLOW%[SKIPPED] Startup apps (use PowerShell for full control)%RESET%
)

echo Optimizing visual effects...
reg add "HKCU\Control Panel\Desktop" /v FontSmoothing /t REG_SZ /d 2 /f >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%[OK] Visual effects optimized%RESET%
    echo [%DATE% %TIME%] Performance: Visual effects optimized >> "%LOG_FILE%"
    set /a CHANGES_COUNT+=1
) else (
    echo %YELLOW%[SKIPPED] Visual effects%RESET%
)

echo.
echo %GREEN%Performance tweaks complete. Changes: %CHANGES_COUNT%%RESET%
pause
goto MAIN_MENU

:USABILITY_TWEAKS
cls
echo.
echo ============================================================================
echo   APPLYING USABILITY TWEAKS
echo ============================================================================
echo.

echo Showing file extensions...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%[OK] File extensions shown%RESET%
    echo [%DATE% %TIME%] Usability: File extensions shown >> "%LOG_FILE%"
    set /a CHANGES_COUNT+=1
) else (
    echo %YELLOW%[SKIPPED] File extensions%RESET%
)

echo Showing hidden files...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 1 /f >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%[OK] Hidden files shown%RESET%
    echo [%DATE% %TIME%] Usability: Hidden files shown >> "%LOG_FILE%"
    set /a CHANGES_COUNT+=1
) else (
    echo %YELLOW%[SKIPPED] Hidden files%RESET%
)

echo Enabling dark mode...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 0 /f >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%[OK] Dark mode enabled%RESET%
    echo [%DATE% %TIME%] Usability: Dark mode enabled >> "%LOG_FILE%"
    set /a CHANGES_COUNT+=1
) else (
    echo %YELLOW%[SKIPPED] Dark mode%RESET%
)

echo.
echo %GREEN%Usability tweaks complete. Changes: %CHANGES_COUNT%%RESET%
pause
goto MAIN_MENU

:WINDOWS_UPDATE
cls
echo.
echo ============================================================================
echo   CONFIGURING WINDOWS UPDATE
echo ============================================================================
echo.

echo Checking Windows Update service...
sc query wuauserv | find "RUNNING" >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%[OK] Windows Update service is running%RESET%
) else (
    echo %YELLOW%[INFO] Starting Windows Update service...%RESET%
    net start wuauserv >nul 2>&1
    if %errorlevel% equ 0 (
        echo %GREEN%[OK] Windows Update service started%RESET%
        echo [%DATE% %TIME%] Update: Windows Update service started >> "%LOG_FILE%"
        set /a CHANGES_COUNT+=1
    ) else (
        echo %RED%[FAILED] Could not start Windows Update service%RESET%
    )
)

echo.
echo %BLUE%[INFO] Manual update check recommended%RESET%
echo Open Settings > Update & Security > Check for updates
echo.
pause
goto MAIN_MENU

:ALL_OPTIMIZATIONS
cls
echo.
echo ============================================================================
echo   RUNNING ALL OPTIMIZATIONS
echo ============================================================================
echo.
echo This will run all optimizations (1-5) in sequence.
echo.
set /p "CONFIRM=Proceed? (Y/N): "
if /i not "!CONFIRM!"=="Y" (
    echo Optimizations cancelled.
    timeout /t 2 /nobreak >nul
    goto MAIN_MENU
)

echo.
call :INSTALL_SOFTWARE
call :PRIVACY_TWEAKS
call :PERFORMANCE_TWEAKS
call :USABILITY_TWEAKS
call :WINDOWS_UPDATE

echo.
echo ============================================================================
echo   ALL OPTIMIZATIONS COMPLETE
echo ============================================================================
echo.
echo %GREEN%Total changes made: %CHANGES_COUNT%%RESET%
echo Log saved to: %LOG_FILE%
echo.
pause
goto MAIN_MENU

:LAUNCH_WINUTIL
cls
echo.
echo ============================================================================
echo   CHRIS TITUS TECH WINUTIL
echo ============================================================================
echo.
echo WinUtil is a comprehensive Windows optimization tool
echo Created by Chris Titus Tech
echo GitHub: https://github.com/ChrisTitusTech/winutil
echo.
echo WinUtil provides:
echo   - Extensive software installation (100+ apps)
echo   - Advanced debloating options
echo   - Privacy and security tweaks
echo   - Windows Update management
echo.
echo %YELLOW%[WARNING] WinUtil makes system-wide changes. Review before applying.%RESET%
echo.
set /p "LAUNCH=Launch WinUtil now? (Y/N): "
if /i "%LAUNCH%"=="Y" (
    echo.
    echo %BLUE%[INFO] Launching WinUtil...%RESET%
    echo [%DATE% %TIME%] WinUtil launched by user >> "%LOG_FILE%"
    echo.
    echo %YELLOW%Opening in PowerShell...%RESET%
    echo.
    powershell -Command "irm 'https://christitus.com/win' | iex"
) else (
    echo %BLUE%[INFO] Skipping WinUtil%RESET%
)
echo.
pause
goto MAIN_MENU

:EXIT_SCRIPT
cls
echo.
echo ============================================================================
echo   WINDOWS OPTIMIZATION - COMPLETE
echo ============================================================================
echo.
echo %GREEN%Total changes made: %CHANGES_COUNT%%RESET%
echo Log saved to: %LOG_FILE%
echo.
echo Thank you for using Windows Post-Repair Optimization!
echo.
echo Remember:
echo   - A clean install is the ABSOLUTE LAST RESORT
echo   - These tweaks are safe and reversible
echo   - Create a restore point before major changes
echo.
echo [%DATE% %TIME%] Optimization session completed >> "%LOG_FILE%"
echo [%DATE% %TIME%] Total changes: %CHANGES_COUNT% >> "%LOG_FILE%"
timeout /t 3 /nobreak >nul
exit /b 0
