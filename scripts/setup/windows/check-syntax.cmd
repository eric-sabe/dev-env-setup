@echo off
REM PowerShell Syntax Checker
echo Checking PowerShell syntax for setup-windows.ps1...
echo.

powershell -Command "try { $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content '%~dp0setup-windows.ps1' -Raw), [ref]$null); Write-Host 'Syntax check: PASSED' -ForegroundColor Green } catch { Write-Host 'Syntax check: FAILED' -ForegroundColor Red; Write-Host $_.Exception.Message -ForegroundColor Red; exit 1 }"

echo.
echo Press any key to continue...
pause >nul