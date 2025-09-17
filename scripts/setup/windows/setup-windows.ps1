#Requires -Version 5.1
# Windows Development Environment Setup Script
# Comprehensive setup for CS students - Windows 11 with WSL2

param(
    [switch]$SkipWSLInstall,
    [switch]$SkipWindowsTools
)

# Check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Logging functions
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check Windows version
function Test-WindowsVersion {
    $osInfo = Get-ComputerInfo
    # Use OS build number for reliable comparison (2004 == build 19041)
    $build = 0
    try { $build = [int]$osInfo.OsBuildNumber } catch { $build = 0 }

    if ($build -lt 19041) {
        Write-Error "Windows 10 build 19041 (version 2004) or Windows 11 required for WSL2. Current build: $build"
        exit 1
    }

    Write-Success "Windows build $build detected"
}

# Enable WSL2 feature
function Enable-WSL2 {
    if ($SkipWSLInstall) {
        Write-Info "Skipping WSL2 installation"
        return
    }

    Write-Info "Enabling WSL2 feature..."

    # Enable WSL feature
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

    # Enable Virtual Machine Platform
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

    # Set WSL2 as default version
    wsl --set-default-version 2

    Write-Success "WSL2 enabled"
}

# Install Ubuntu WSL2
function Install-UbuntuWSL {
    if ($SkipWSLInstall) {
        Write-Info "Skipping Ubuntu WSL installation"
        return
    }

    Write-Info "Installing Ubuntu WSL2..."

    # Install Ubuntu from Microsoft Store
    try {
        # Check if Ubuntu is already installed
        $ubuntuInstalled = wsl -l -q | Where-Object { $_ -match "Ubuntu" }
        if ($ubuntuInstalled) {
            Write-Success "Ubuntu WSL already installed"
            return
        }

        # Install Ubuntu 22.04 LTS
        wsl --install -d Ubuntu-22.04

        Write-Success "Ubuntu WSL2 installed"
        Write-Info "Please complete the Ubuntu setup (username/password) when prompted"
    }
    catch {
        Write-Warning "Ubuntu installation failed. You can install it manually from Microsoft Store"
    }
}

# Install Windows development tools
function Install-WindowsTools {
    if ($SkipWindowsTools) {
        Write-Info "Skipping Windows tools installation"
        return
    }

    Write-Info "Installing Windows development tools..."

    # Install Chocolatey if not present
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Info "Installing Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        # Try to import Chocolatey profile to enable refreshenv in current session
        if ($env:ChocolateyInstall) {
            $chocoProfile = Join-Path $env:ChocolateyInstall 'helpers\chocolateyProfile.psm1'
            if (Test-Path $chocoProfile) {
                Import-Module $chocoProfile -ErrorAction SilentlyContinue
            }
        }
        if (Get-Command refreshenv -ErrorAction SilentlyContinue) {
            refreshenv
        } else {
            Write-Info "Chocolatey installed. Open a new terminal to refresh PATH or run: `Import-Module $env:ChocolateyInstall\\helpers\\chocolateyProfile.psm1; refreshenv`"
        }
    }

    # Install development tools via Chocolatey
    $tools = @(
        "git",
        "vscode",
        "eclipse",
        "python",
        "nodejs",
        "openjdk",
        "maven",
        "gradle",
        "docker-desktop",
        "postman",
        "gitkraken",
        "microsoft-windows-terminal",
        "powershell"
    )

    foreach ($tool in $tools) {
        Write-Info "Installing $tool..."
        try {
            choco install $tool -y
            Write-Success "$tool installed"
        }
        catch {
            if ($tool -eq "eclipse") {
                Write-Info "Trying Eclipse fallback package 'eclipse-java'..."
                try {
                    choco install eclipse-java -y
                    Write-Success "eclipse-java installed"
                }
                catch {
                    Write-Warning "Failed to install eclipse and eclipse-java"
                }
            } else {
                Write-Warning "Failed to install $tool"
            }
        }
    }

    Write-Success "Windows tools installation completed"
}

# Configure Windows Terminal
function Configure-WindowsTerminal {
    Write-Info "Configuring Windows Terminal..."

    $terminalSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

    if (Test-Path $terminalSettingsPath) {
        Write-Info "Windows Terminal settings file found"
        # Could add custom configuration here
    } else {
        Write-Info "Windows Terminal settings file not found (may not be installed yet)"
    }
}

# Install Windows Subsystem for Android (optional)
function Install-WSAA {
    Write-Info "Installing Windows Subsystem for Android (optional)..."

    try {
        # Check if Amazon Appstore is available (required for WSA)
        $amazonAppstore = Get-AppxPackage -Name "*Amazon*" -ErrorAction SilentlyContinue
        if ($amazonAppstore) {
            Write-Info "Amazon Appstore found, installing WSA..."
            # WSA installation would go here
            Write-Success "Windows Subsystem for Android ready for installation"
        } else {
            Write-Info "Amazon Appstore not found, skipping WSA"
        }
    }
    catch {
        Write-Info "Windows Subsystem for Android not available on this system"
    }
}

# Create development directory structure
function New-DevDirectories {
    Write-Info "Creating development directory structure..."

    $devPaths = @(
        "$env:USERPROFILE\dev",
        "$env:USERPROFILE\dev\current",
        "$env:USERPROFILE\dev\archive",
        "$env:USERPROFILE\dev\tools",
        "$env:USERPROFILE\dev\backups",
        "$env:USERPROFILE\dev\current\python",
        "$env:USERPROFILE\dev\current\nodejs",
        "$env:USERPROFILE\dev\current\java",
        "$env:USERPROFILE\dev\current\cpp",
        "$env:USERPROFILE\dev\current\web",
        "$env:USERPROFILE\dev\current\mobile"
    )

    foreach ($path in $devPaths) {
        if (!(Test-Path $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
    }

    Write-Success "Development directories created"
}

# Configure environment variables
function Set-DevEnvironment {
    Write-Info "Configuring environment variables..."

    # Add common development paths to PATH if not already there
    $devPaths = @(
        "$env:USERPROFILE\bin",
        "$env:USERPROFILE\.pyenv\bin",
        "$env:USERPROFILE\AppData\Roaming\npm"
    )

    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $pathArray = $currentPath -split ";"

    foreach ($devPath in $devPaths) {
        if ($pathArray -notcontains $devPath -and (Test-Path $devPath)) {
            $pathArray += $devPath
        }
    }

    $newPath = $pathArray -join ";"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    # Also update current session PATH if refreshenv wasn't available
    foreach ($devPath in $devPaths) {
        if ((Test-Path $devPath) -and ($env:PATH -notlike "*${devPath}*")) {
            $env:PATH = "$env:PATH;$devPath"
        }
    }

    Write-Success "Environment variables configured"
}

# Verify installation
function Test-Installation {
    Write-Info "Verifying installation..."

    $errors = 0

    # Check WSL
    try {
        $wslVersion = wsl -l -v 2>$null
        if ($wslVersion) {
            Write-Success "WSL: installed"
        } else {
            Write-Error "WSL: NOT FOUND"
            $errors++
        }
    }
    catch {
        Write-Error "WSL: NOT FOUND"
        $errors++
    }

    # Check Windows tools
    $windowsTools = @("git", "code", "python", "node", "java", "mvn", "gradle")
    foreach ($tool in $windowsTools) {
        try {
            $null = Get-Command $tool -ErrorAction Stop
            Write-Success "${tool}: found"
        }
        catch {
            Write-Error "${tool}: NOT FOUND"
            $errors++
        }
    }

    if ($errors -eq 0) {
        Write-Success "All tools verified successfully!"
    } else {
        Write-Warning "$errors tools failed verification. You may need to restart PowerShell or check the installation logs."
    }
}

# Main installation function
function Install-DevEnvironment {
    Write-Host "Setting up Windows Development Environment" -ForegroundColor Blue
    Write-Host "===============================================" -ForegroundColor Blue

    # Check prerequisites
    if (!(Test-Administrator)) {
        Write-Error "This script must be run as Administrator"
        exit 1
    }

    Test-WindowsVersion

    # Install components
    Enable-WSL2
    Install-UbuntuWSL
    Install-WindowsTools
    Configure-WindowsTerminal
    Install-WSAA
    New-DevDirectories
    Set-DevEnvironment
    Test-Installation

    Write-Host ""
    Write-Host "Windows development environment setup complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Restart your computer to complete WSL2 installation"
    Write-Host "2. Launch Ubuntu from Start Menu and complete setup"
    Write-Host "3. Run the WSL setup script: wsl bash ~/dev-scripts/setup/windows/setup-wsl.sh"
    Write-Host "4. Install VS Code extensions for your languages"
    Write-Host "5. Use the quickstart scripts to create new projects"
    Write-Host ""
    Write-Host "Happy coding!" -ForegroundColor Blue
}

# Run main function
Install-DevEnvironment
