#Requires -Version 5.1
# Windows Development Environment Setup Script
# Comprehensive setup for CS students - Windows 11 with WSL2

param(
    [switch]$SkipWSLInstall,
    [switch]$SkipWindowsTools
)

# Import required modules
Import-Module DISM -ErrorAction SilentlyContinue

# Check for pending reboot
function Test-PendingReboot {
    $pendingReboot = $false
    
    # Check Windows Update reboot flag
    if (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction SilentlyContinue) {
        $pendingReboot = $true
    }
    
    # Check Component Based Servicing reboot flag
    if (Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -ErrorAction SilentlyContinue) {
        $pendingReboot = $true
    }
    
    # Check for pending file rename operations
    if (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name "PendingFileRenameOperations" -ErrorAction SilentlyContinue) {
        $pendingReboot = $true
    }
    
    return $pendingReboot
}

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

    # Check if WSL is already enabled
    $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
    $vmFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform

    $needsRestart = $false

    if ($wslFeature.State -ne "Enabled") {
        Write-Info "Enabling Windows Subsystem for Linux..."
        dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
        $needsRestart = $true
    }

    if ($vmFeature.State -ne "Enabled") {
        Write-Info "Enabling Virtual Machine Platform..."
        dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
        $needsRestart = $true
    }

    if ($needsRestart) {
        Write-Warning "A restart is required to complete WSL installation."
        Write-Info "After restart, run this script again to complete the setup."
        $restart = Read-Host "Would you like to restart now? (y/N)"
        if ($restart -eq "y" -or $restart -eq "Y") {
            Restart-Computer -Force
        }
        return
    }

    # Set WSL2 as default version (only if WSL is already working)
    try {
        wsl --set-default-version 2
        Write-Success "WSL2 set as default version"
    } catch {
        Write-Info "WSL not ready yet. Will set default version after restart."
    }

    Write-Success "WSL2 features enabled"
}

# Install Ubuntu WSL2
function Install-UbuntuWSL {
    if ($SkipWSLInstall) {
        Write-Info "Skipping Ubuntu WSL installation"
        return
    }

    Write-Info "Installing Ubuntu WSL2..."

    # Check if WSL is working
    try {
        $wslStatus = wsl --status 2>$null
    } catch {
        Write-Warning "WSL is not ready. Please restart your computer and run this script again."
        return
    }

    # Install Ubuntu from Microsoft Store
    try {
        # Check if Ubuntu is already installed
        $ubuntuInstalled = wsl -l -q 2>$null | Where-Object { $_ -match "Ubuntu" }
        if ($ubuntuInstalled) {
            Write-Success "Ubuntu WSL already installed"
            return
        }

        # Try different Ubuntu installation methods
        Write-Info "Attempting to install Ubuntu..."
        
        # Method 1: Use wsl --install
        try {
            wsl --install -d Ubuntu-22.04
            Write-Success "Ubuntu WSL2 installed via wsl --install"
        } catch {
            # Method 2: Manual download and install
            Write-Info "Trying alternative Ubuntu installation method..."
            $ubuntuUrl = "https://aka.ms/wslubuntu2204"
            $ubuntuPath = "$env:TEMP\Ubuntu2204.appx"
            
            Write-Info "Downloading Ubuntu 22.04..."
            Invoke-WebRequest -Uri $ubuntuUrl -OutFile $ubuntuPath
            
            Write-Info "Installing Ubuntu 22.04..."
            Add-AppxPackage -Path $ubuntuPath
            
            Remove-Item $ubuntuPath -ErrorAction SilentlyContinue
            Write-Success "Ubuntu WSL2 installed via manual download"
        }

        Write-Info "Please complete the Ubuntu setup (username/password) when prompted"
        Write-Info "You can start Ubuntu by running: wsl"
    }
    catch {
        Write-Warning "Ubuntu installation failed. You can install it manually from Microsoft Store"
        Write-Info "Search for 'Ubuntu 22.04 LTS' in Microsoft Store"
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
            Write-Info "Chocolatey installed. Open a new terminal to refresh PATH or run: Import-Module `$env:ChocolateyInstall\\helpers\\chocolateyProfile.psm1; refreshenv"
        }
    }

    # Check for pending reboot before installing tools
    if (Test-PendingReboot) {
        Write-Warning "A system reboot is pending. Some installations may fail."
        Write-Info "Consider restarting your computer and running this script again for best results."
    }

    # Install development tools via Chocolatey
    $tools = @(
        @{name="git"; fallback=$null; description="Git version control"},
        @{name="vscode"; fallback=$null; description="Visual Studio Code editor"},
        @{name="eclipse"; fallback="eclipse-java"; description="Eclipse IDE"},
        @{name="python"; fallback=$null; description="Python programming language"},
        @{name="nodejs"; fallback=$null; description="Node.js runtime"},
        @{name="openjdk"; fallback="temurin"; description="OpenJDK Java"},
        @{name="maven"; fallback=$null; description="Maven build tool"},
        @{name="gradle"; fallback=$null; description="Gradle build tool"},
        @{name="docker-desktop"; fallback=$null; description="Docker Desktop"},
        @{name="postman"; fallback=$null; description="Postman API testing"},
        @{name="gitkraken"; fallback=$null; description="GitKraken Git GUI"},
        @{name="microsoft-windows-terminal"; fallback="microsoft-terminal"; description="Windows Terminal"},
        @{name="powershell"; fallback="powershell-core"; description="PowerShell Core"}
    )

    $successCount = 0
    $failCount = 0

    foreach ($tool in $tools) {
        $toolName = $tool.name
        $fallback = $tool.fallback
        $description = $tool.description

        Write-Info "Checking $description..."

        # Check if tool is already installed
        $alreadyInstalled = $false
        try {
            $null = Get-Command $toolName -ErrorAction Stop
            Write-Success "$description already installed"
            $alreadyInstalled = $true
            $successCount++
        }
        catch {
            # Tool not found, proceed with installation
        }

        if (!$alreadyInstalled) {
            Write-Info "Installing $description..."
            $installed = $false

            # Try main package first
            try {
                $result = choco install $toolName -y --limit-output
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "$description installed successfully"
                    $installed = $true
                    $successCount++
                } else {
                    throw "Chocolatey exit code: $LASTEXITCODE"
                }
            }
            catch {
                Write-Warning "Failed to install $toolName"
                $failCount++

                # Try fallback if available
                if ($fallback) {
                    Write-Info "Trying fallback package '$fallback'..."
                    try {
                        $result = choco install $fallback -y --limit-output
                        if ($LASTEXITCODE -eq 0) {
                            Write-Success "$fallback installed successfully"
                            $installed = $true
                            $successCount++
                        } else {
                            throw "Chocolatey exit code: $LASTEXITCODE"
                        }
                    }
                    catch {
                        Write-Warning "Failed to install both $toolName and $fallback"
                    }
                }
            }
        }

        if (!$installed -and !$alreadyInstalled) {
            Write-Info "You can install $toolName manually later using: choco install $toolName"
        }
    }

    Write-Host ""
    Write-Success "Windows tools installation completed: $successCount successful, $failCount failed"
    if ($failCount -gt 0) {
        Write-Warning "Some tools failed to install. This may be due to pending system reboot."
        Write-Info "After restarting your computer, you can retry failed installations with:"
        Write-Info "choco install <package-name> -y"
    }
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
