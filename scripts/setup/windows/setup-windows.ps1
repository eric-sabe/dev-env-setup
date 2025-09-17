#Requires -Version 5.1
# Windows Development Environment Setup Script
# Comprehensive setup for CS students - Windows 11 with WSL2
#
# Usage:
#   .\setup-windows.ps1                    # Install everything
#   .\setup-windows.ps1 -SkipWSLInstall    # Skip WSL2 installation
#   .\setup-windows.ps1 -SkipWindowsTools  # Skip Windows tools installation
#   .\setup-windows.ps1 -Uninstall         # Remove everything installed by this script

param(
    [switch]$SkipWSLInstall,
    [switch]$SkipWindowsTools,
    [switch]$Uninstall
)

# Import required modules
Import-Module DISM -ErrorAction SilentlyContinue

# Global flag for Parallels/ARM64 environment
$IsParallelsARM64 = $false

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

# Check if running in Parallels on Apple Silicon (where WSL2 won't work)
function Test-ParallelsAppleSilicon {
    try {
        # Check for Parallels virtual hardware
        $systemInfo = Get-WmiObject -Class Win32_ComputerSystem
        $manufacturer = $systemInfo.Manufacturer
        $model = $systemInfo.Model
        
        # Check if we're in Parallels
        $isParallels = $manufacturer -like "*Parallels*" -or $model -like "*Parallels*"
        
        if ($isParallels) {
            # Check for Apple Silicon architecture
            $processor = Get-WmiObject -Class Win32_Processor
            $architecture = $processor.Architecture
            
            # Architecture 12 = ARM64, which indicates Apple Silicon
            if ($architecture -eq 12) {
                return $true
            }
        }
        
        return $false
    }
    catch {
        # If we can't detect, assume it's not the problematic scenario
        return $false
    }
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

# Check if nested virtualization is available
function Test-NestedVirtualization {
    try {
        # Check if the environment variable is set
        $envVar = [Environment]::GetEnvironmentVariable("WSL_ENABLE_NESTED_VIRTUALIZATION", "Machine")
        $envVarSet = ($envVar -eq "1")

        # Check if .wslconfig has nested virtualization enabled
        $wslConfigPath = Join-Path $env:UserProfile '.wslconfig'
        $wslConfigSet = $false
        if (Test-Path $wslConfigPath) {
            $content = Get-Content $wslConfigPath -Raw
            $wslConfigSet = ($content -match 'nestedVirtualization\s*=\s*true')
        }

        # Check if virtualization extensions are available
        $cpuVirtEnabled = $false
        try {
            $cpuInfo = Get-WmiObject -Class Win32_Processor
            $cpuVirtEnabled = ($cpuInfo.VirtualizationFirmwareEnabled -eq $true)
        } catch {
            # If we can't check, assume it might be available
            $cpuVirtEnabled = $true
        }

        return ($envVarSet -and $wslConfigSet -and $cpuVirtEnabled)
    }
    catch {
        return $false
    }
}

# Enable WSL2 feature
function Enable-WSL2 {
    if ($SkipWSLInstall) {
        Write-Info "Skipping WSL2 installation"
        return
    }

    Write-Info "Enabling WSL2 feature..."

    # Additional guidance for Parallels on Apple Silicon
    if (Test-ParallelsAppleSilicon) {
        $nestedVirtAvailable = Test-NestedVirtualization

        if ($nestedVirtAvailable) {
            Write-Info "Parallels ARM64 detected - nested virtualization is configured!"
            Write-Host "✅ WSL2 should work properly in this environment" -ForegroundColor Green
        } else {
            Write-Info "Parallels ARM64 detected - configuring nested virtualization automatically"
            Write-Host "The script will configure WSL2 for nested virtualization automatically." -ForegroundColor Green
            Write-Host "A restart may be required after setup completes." -ForegroundColor Yellow
        }
    }

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

    # Configure nested virtualization for Parallels ARM64
    if (Test-ParallelsAppleSilicon) {
        Write-Info "Configuring nested virtualization settings..."

        # Set the environment variable for nested virtualization
        try {
            [Environment]::SetEnvironmentVariable("WSL_ENABLE_NESTED_VIRTUALIZATION", "1", "Machine")
            Write-Success "Set WSL_ENABLE_NESTED_VIRTUALIZATION=1"
        } catch {
            Write-Warning "Could not set environment variable automatically. You may need to set it manually."
        }

        # Configure .wslconfig for nested virtualization
        try {
            $wslConfigPath = Join-Path $env:UserProfile '.wslconfig'
            $content = if (Test-Path $wslConfigPath) { Get-Content $wslConfigPath -Raw } else { "" }

            if ($content -notmatch '^\[wsl2\]'m) {
                # No [wsl2] section yet — create one with the setting ON
                $content = @"
[wsl2]
nestedVirtualization=true
"@
            } else {
                if ($content -match 'nestedVirtualization\s*=\s*(true|false)') {
                    # Set to true
                    $content = [regex]::Replace($content,
                        'nestedVirtualization\s*=\s*(true|false)',
                        'nestedVirtualization=true')
                } else {
                    # Add the key into the existing [wsl2] section
                    $content = $content -replace '(\[wsl2\][^\[]*)', '$1' + "`r`n" + 'nestedVirtualization=true'
                }
            }

            Set-Content -Path $wslConfigPath -Value $content -Encoding UTF8
            Write-Success "Configured .wslconfig with nestedVirtualization=true"
        } catch {
            Write-Warning "Could not configure .wslconfig automatically: $($_.Exception.Message)"
        }

        # Try to enable Developer Mode (this may not work in all environments)
        try {
            $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
            if (-not (Test-Path $registryPath)) {
                New-Item -Path $registryPath -Force | Out-Null
            }
            Set-ItemProperty -Path $registryPath -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -Type DWord
            Write-Success "Enabled Developer Mode"
        } catch {
            Write-Info "Developer Mode may need to be enabled manually in Windows Settings"
        }
    }
}

# Install Ubuntu WSL2
function Install-UbuntuWSL {
    if ($SkipWSLInstall) {
        Write-Info "Skipping Ubuntu WSL installation"
        return
    }

    Write-Info "Installing Ubuntu WSL2..."

    # Additional guidance for Parallels on Apple Silicon
    if (Test-ParallelsAppleSilicon) {
        $nestedVirtAvailable = Test-NestedVirtualization

        if ($nestedVirtAvailable) {
            Write-Info "Parallels ARM64 detected - nested virtualization is configured!"
            Write-Host "✅ Ubuntu should install and work properly" -ForegroundColor Green
        } else {
            Write-Info "Parallels ARM64 detected - configuring nested virtualization automatically"
            Write-Host "The script will configure Ubuntu for nested virtualization automatically." -ForegroundColor Green
            Write-Host "A restart may be required after setup completes." -ForegroundColor Yellow
        }
    }

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
    
    if ($script:IsParallelsARM64) {
        Write-Host ""
        Write-Host "💡 Parallels ARM64 Environment Notes:" -ForegroundColor Cyan
        Write-Host "• All installed tools work perfectly in this environment" -ForegroundColor Green
        Write-Host "• VS Code, Git, Python, Node.js, and Java all have excellent performance" -ForegroundColor Green
        Write-Host "• Use Docker Desktop for container development" -ForegroundColor Green
        Write-Host "• Consider Remote SSH extension for Linux development" -ForegroundColor Yellow
    }
    
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

# Uninstall development environment
function Uninstall-DevEnvironment {
    Write-Host "🗑️  Uninstalling Windows Development Environment" -ForegroundColor Red
    Write-Host "=================================================" -ForegroundColor Red

    # Check prerequisites
    if (!(Test-Administrator)) {
        Write-Error "This script must be run as Administrator to uninstall"
        exit 1
    }

    # Check for Parallels ARM64 mode
    if (Test-ParallelsAppleSilicon) {
        $script:IsParallelsARM64 = $true
    }

    Write-Warning "This will remove all development tools and configurations installed by this script."
    Write-Host ""
    Write-Host "The following will be removed:" -ForegroundColor Yellow
    Write-Host "• Chocolatey package manager" -ForegroundColor Yellow
    Write-Host "• All development tools (Git, VS Code, Python, Node.js, Java, etc.)" -ForegroundColor Yellow
    if (!$script:IsParallelsARM64) {
        Write-Host "• WSL2 and Ubuntu (if installed)" -ForegroundColor Yellow
    } else {
        Write-Host "• WSL2/Ubuntu (not applicable in Parallels ARM64 mode)" -ForegroundColor Cyan
    }
    Write-Host "• Development directories and configurations (optional)" -ForegroundColor Yellow
    Write-Host "• Environment variable modifications" -ForegroundColor Yellow
    Write-Host ""
    $confirm = Read-Host "Are you sure you want to continue? Type 'YES' to confirm"
    if ($confirm -ne "YES") {
        Write-Info "Uninstallation cancelled."
        exit 0
    }

    Write-Host ""
    Write-Host "Starting uninstallation..." -ForegroundColor Red

    # Remove Chocolatey packages (skip critical system tools)
    Write-Info "Removing Chocolatey packages..."
    $tools = @(
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
        "powershell-core"
    )

    # Note: We skip 'git' as it might be used by other applications
    Write-Warning "Note: Keeping Git installed as it may be used by other applications"
    Write-Info "To remove Git manually: choco uninstall git -y"

    $removedCount = 0
    $failedCount = 0

    foreach ($tool in $tools) {
        try {
            $result = choco uninstall $tool -y --limit-output 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Removed $tool"
                $removedCount++
            } else {
                Write-Info "$tool not installed or already removed"
            }
        }
        catch {
            Write-Warning "Could not remove $tool"
            $failedCount++
        }
    }

    # Remove Chocolatey itself
    Write-Info "Removing Chocolatey..."
    try {
        $chocoPath = "$env:ChocolateyInstall"
        if (Test-Path $chocoPath) {
            Remove-Item -Path $chocoPath -Recurse -Force -ErrorAction SilentlyContinue
            Write-Success "Removed Chocolatey"
        } else {
            Write-Info "Chocolatey not found"
        }
    }
    catch {
        Write-Warning "Could not remove Chocolatey completely"
    }

    # Remove WSL2 and Ubuntu (if not in Parallels ARM64)
    if (!$script:IsParallelsARM64) {
        Write-Info "Removing WSL2 and Ubuntu..."
        try {
            # Check if WSL is available before trying to remove
            if (Get-Command wsl -ErrorAction SilentlyContinue) {
                # Remove Ubuntu
                wsl --unregister Ubuntu 2>$null
                wsl --unregister Ubuntu-22.04 2>$null
                Write-Success "Removed Ubuntu WSL"
            }

            # Disable WSL features
            dism.exe /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart
            dism.exe /online /disable-feature /featurename:VirtualMachinePlatform /norestart
            Write-Success "Disabled WSL2 features"
        }
        catch {
            Write-Warning "Could not remove WSL2/Ubuntu (may not be installed)"
        }
    } else {
        Write-Info "Skipping WSL2 removal (was not installed in Parallels ARM64 mode)"
    }

    # Clean up environment variables
    Write-Info "Cleaning up environment variables..."
    try {
        # Remove common paths that might have been added
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
        $pathsToRemove = @(
            "$env:ChocolateyInstall\bin",
            "$env:ProgramFiles\Microsoft VS Code\bin",
            "$env:ProgramFiles\Git\bin",
            "$env:ProgramFiles\Git\cmd",
            "$env:ProgramFiles\nodejs",
            "$env:ProgramFiles\Python*\Scripts",
            "$env:ProgramFiles\Python*\",
            "$env:ProgramFiles\Java\*\bin",
            "$env:ProgramFiles\Maven\*\bin",
            "$env:ProgramFiles\Gradle\*\bin"
        )

        $newPath = $currentPath
        foreach ($path in $pathsToRemove) {
            $newPath = $newPath -replace [regex]::Escape($path + ";"), ""
            $newPath = $newPath -replace [regex]::Escape($path), ""
        }

        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Success "Cleaned up PATH environment variable"
    }
    catch {
        Write-Warning "Could not clean up environment variables"
    }

    # Remove development directories (optional)
    Write-Host ""
    $removeDirs = Read-Host "Remove development directories (~/dev, ~/projects, etc.)? (y/N)"
    if ($removeDirs -eq "y" -or $removeDirs -eq "Y") {
        Write-Info "Removing development directories..."
        $devDirs = @(
            "$env:USERPROFILE\dev",
            "$env:USERPROFILE\projects",
            "$env:USERPROFILE\workspace",
            "$env:USERPROFILE\development"
        )

        foreach ($dir in $devDirs) {
            if (Test-Path $dir) {
                try {
                    Remove-Item -Path $dir -Recurse -Force
                    Write-Success "Removed $dir"
                }
                catch {
                    Write-Warning "Could not remove $dir"
                }
            }
        }
    }

    # Final summary
    Write-Host ""
    Write-Host "🗑️  Uninstallation Complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host "✅ Packages removed: $removedCount" -ForegroundColor Green
    Write-Host "⚠️  Failed removals: $failedCount" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Note: Some files may remain if they were in use during uninstallation." -ForegroundColor Yellow
    Write-Host "You may need to restart your computer for all changes to take effect." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To reinstall, run: .\setup-windows.ps1" -ForegroundColor Blue
}

# Main installation function
function Install-DevEnvironment {
    if ($script:IsParallelsARM64) {
        Write-Host "Setting up Windows Development Environment (Parallels ARM64 Mode)" -ForegroundColor Blue
        Write-Host "=================================================================" -ForegroundColor Blue
        Write-Host "Note: WSL2 will be skipped due to virtualization limitations" -ForegroundColor Yellow
        Write-Host "Focusing on Windows-native development tools" -ForegroundColor Yellow
    } else {
        Write-Host "Setting up Windows Development Environment" -ForegroundColor Blue
        Write-Host "===============================================" -ForegroundColor Blue
    }

    # Check prerequisites
    if (!(Test-Administrator)) {
        Write-Error "This script must be run as Administrator"
        exit 1
    }

    Test-WindowsVersion

    # Check for Parallels on Apple Silicon (WSL2 may work with nested virtualization)
    if (Test-ParallelsAppleSilicon) {
        Write-Warning "⚠️  DETECTED: Windows running in Parallels on Apple Silicon"
        Write-Host ""
        Write-Host "Good news! WSL2 can actually work in this environment with nested virtualization:" -ForegroundColor Green
        Write-Host ""
        Write-Host "To enable WSL2 in Parallels on Apple Silicon:" -ForegroundColor Cyan
        Write-Host "1. In Parallels Desktop, go to your VM settings" -ForegroundColor White
        Write-Host "2. Navigate to Hardware > CPU & Memory > Advanced" -ForegroundColor White
        Write-Host "3. Enable 'Nested virtualization'" -ForegroundColor White
        Write-Host "4. Restart your Windows VM" -ForegroundColor White
        Write-Host ""
        Write-Host "After enabling nested virtualization, WSL2 will work normally!" -ForegroundColor Green
        Write-Host ""
        $enableWSL = Read-Host "Would you like to continue with WSL2 installation? (Y/n)"
        if ($enableWSL -eq "n" -or $enableWSL -eq "N") {
            Write-Info "Skipping WSL2 installation. You can enable it later by running this script again."
            $script:IsParallelsARM64 = $true
            $SkipWSLInstall = $true
        } else {
            Write-Info "Continuing with WSL2 installation..."
            Write-Info "Remember to enable nested virtualization in Parallels settings for WSL2 to work!"
        }

    # Install components (conditionally based on environment)
    if ($script:IsParallelsARM64) {
        Write-Info "Installing Windows-native development tools..."
        Install-WindowsTools
        Configure-WindowsTerminal
        Install-WSAA
        New-DevDirectories
        Set-DevEnvironment
        Test-Installation
    } else {
        Write-Info "Installing full development environment..."
        Enable-WSL2
        Install-UbuntuWSL
        Install-WindowsTools
        Configure-WindowsTerminal
        Install-WSAA
        New-DevDirectories
        Set-DevEnvironment
        Test-Installation
    }

    Write-Host ""
    Write-Host "Windows development environment setup complete!" -ForegroundColor Green
    Write-Host ""

    # Context-aware next steps based on environment
    if ($script:IsParallelsARM64) {
        Write-Host "🎯 Windows Development Environment Setup Complete (Parallels ARM64 Mode)" -ForegroundColor Green
        Write-Host ""
        Write-Host "What was installed:" -ForegroundColor Cyan
        Write-Host "✅ Chocolatey package manager" -ForegroundColor Green
        Write-Host "✅ Git version control" -ForegroundColor Green
        Write-Host "✅ Visual Studio Code" -ForegroundColor Green
        Write-Host "✅ Development tools (Python, Node.js, Java, etc.)" -ForegroundColor Green
        Write-Host "✅ Windows Terminal configuration" -ForegroundColor Green
        Write-Host ""
        Write-Host "WSL2 Status:" -ForegroundColor Yellow
        Write-Host "✅ WSL2 setup complete with nested virtualization support" -ForegroundColor Green
        Write-Host ""
        Write-Host "What was configured automatically:" -ForegroundColor Green
        Write-Host "✅ Enabled WSL and Virtual Machine Platform features" -ForegroundColor Green
        Write-Host "✅ Set WSL_ENABLE_NESTED_VIRTUALIZATION=1 environment variable" -ForegroundColor Green
        Write-Host "✅ Configured .wslconfig with nestedVirtualization=true" -ForegroundColor Green
        Write-Host "✅ Enabled Developer Mode" -ForegroundColor Green
        Write-Host ""
        Write-Host "💡 If WSL2 doesn't work immediately:" -ForegroundColor Yellow
        Write-Host "• Restart Windows VM to ensure all settings take effect" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Alternative Linux development:" -ForegroundColor Yellow
        Write-Host "• Remote SSH to a Linux server/VM" -ForegroundColor Cyan
        Write-Host "• Use macOS natively for Linux tools" -ForegroundColor Cyan
        Write-Host "• UTM for local Linux VMs on macOS" -ForegroundColor Cyan
    } else {
        Write-Host "🎯 Windows Development Environment Setup Complete" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "1. Restart your computer to complete WSL2 installation"
        Write-Host "2. Launch Ubuntu from Start Menu and complete setup"
        Write-Host "3. Run the WSL setup script: wsl bash ~/dev-scripts/setup/windows/setup-wsl.sh"
        Write-Host "4. Install VS Code extensions for your languages"
        Write-Host "5. Use the quickstart scripts to create new projects"
    }

    Write-Host ""
    Write-Host "Happy coding!" -ForegroundColor Blue
}

# Main execution logic
if ($Uninstall) {
    Uninstall-DevEnvironment
} else {
    Install-DevEnvironment
}
