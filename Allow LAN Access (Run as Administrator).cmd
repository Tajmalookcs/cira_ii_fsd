@echo off
setlocal enabledelayedexpansion
REM ============================================================
REM  Commissioner (Appeals-II), Inland Revenue
REM
REM  Opens the Windows Firewall so other PCs can reach the
REM  Appeals Management System on this machine - over the office
REM  LAN cable, or over this PC's Mobile Hotspot.
REM
REM  RIGHT-CLICK this file and choose "Run as administrator".
REM  Run it ONCE, on the machine that hosts the system.
REM  Do NOT run it on the staff PCs.
REM ============================================================

set PORT=8020
set RULENAME=Appeals System (CIR A-II) - port %PORT%

echo.
echo  ============================================================
echo   Appeals System - allow access from other PCs
echo  ============================================================
echo.

net session >nul 2>&1
if errorlevel 1 (
    echo   ERROR: This window is not running as Administrator.
    echo.
    echo   Close it, then RIGHT-CLICK this file and choose
    echo   "Run as administrator".
    echo.
    pause
    exit /b 1
)

echo   Removing any previous rule with the same name...
netsh advfirewall firewall delete rule name="%RULENAME%" >nul 2>&1

echo   Adding firewall rule for TCP port %PORT%...
REM All three profiles are included on purpose. Windows often classifies an
REM office LAN as "Public", and a Domain/Private-only rule is then ignored.
netsh advfirewall firewall add rule ^
    name="%RULENAME%" ^
    dir=in ^
    action=allow ^
    protocol=TCP ^
    localport=%PORT% ^
    profile=domain,private,public ^
    description="Allows office PCs to reach the CIR (Appeals-II) Appeals Management System." >nul

if errorlevel 1 (
    echo.
    echo   FAILED to add the firewall rule.
    echo.
    pause
    exit /b 1
)

echo   Done - rule active for Domain, Private and Public networks.
echo.
echo  ------------------------------------------------------------
echo   Addresses other machines can use:
echo  ------------------------------------------------------------
echo.

for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    set IP=%%a
    set IP=!IP: =!
    echo !IP! | findstr /b "169.254." >nul
    if errorlevel 1 (
        echo !IP! | findstr /b "192.168.137." >nul
        if errorlevel 1 (
            echo      http://!IP!:%PORT%/          ^<-- office LAN cable
        ) else (
            echo      http://!IP!:%PORT%/          ^<-- Mobile Hotspot
        )
    )
)

echo.
echo  ------------------------------------------------------------
echo   Ignore any 169.254.x.x address - that means the adapter is
echo   not actually connected to a network.
echo.
echo   To use the Mobile Hotspot: turn it on in
echo     Settings ^> Network ^& Internet ^> Mobile hotspot
echo   then connect the other PC to that Wi-Fi name, and browse
echo   to the 192.168.137.1 address above.
echo  ------------------------------------------------------------
echo.
pause
