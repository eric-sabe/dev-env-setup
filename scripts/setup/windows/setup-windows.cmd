@echo off
REM Windows Development Environment Setup Wrapper
REM This script handles PowerShell execution policy and runs the main setup script

echo Windows Development Environment Setup
echo ====================================
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: This script must be run as Administrator
    echo.
    echo Right-click on Command Prompt or PowerShell and select "Run as administrator"
    echo Then navigate to this directory and run: setup-windows.cmd
    echo.
    pause
    exit /b 1
)

echo Setting PowerShell execution policy...
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force"

if %errorlevel% neq 0 (
    echo ERROR: Failed to set PowerShell execution policy
    pause
    exit /b 1
)

echo.
echo Running Windows setup script...
echo.
echo NOTE: This installation is fully automated.
echo Please do NOT press any keys unless specifically prompted.
echo Some installations may appear to pause - this is normal.
echo.

REM Pass all arguments to the PowerShell script
powershell -File "%~dp0setup-windows.ps1" %*

echo.
echo Setup complete. Press any key to exit...
pause >nul