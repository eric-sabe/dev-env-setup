#Requires -Version 5.1
# Windows Development Environment Setup Script
# Comprehensive setup for CS students - Windows 11 with WSL2
# Automatically detects and handles Parallels Desktop on Apple Silicon
#
# Usage:
#   .\setup-windows.cmd                    # Recommended: Use CMD wrapper (handles execution policy)
#   .\setup-windows.ps1                    # Direct PowerShell execution
#   .\setup-windows.ps1 -SkipWSLInstall    # Skip WSL2 installation
#   .\setup-windows.ps1 -SkipWindowsTools  # Skip Windows tools installation
#   .\setup-windows.ps1 -Uninstall         # Remove everything installed by this script
#
# Notes:
#   - When running on Parallels Desktop with Apple Silicon, WSL2 installation
#     will be automatically skipped due to compatibility limitations
#   - All Windows-native development tools will still be installed and work normally

param(
    [switch]$SkipWSLInstall,
    [switch]$SkipWindowsTools,
    [switch]$Uninstall
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

# Timing functions
function Start-Timer {
    param([string]$Operation)
    $global:StepStartTime = Get-Date
    Write-Info "Starting: $Operation"
}

function Stop-Timer {
    param([string]$Operation)
    if ($global:StepStartTime) {
        $elapsed = (Get-Date) - $global:StepStartTime
        $seconds = [math]::Round($elapsed.TotalSeconds, 1)
        Write-Success "Completed: $Operation (${seconds}s)"
        $global:StepStartTime = $null
    } else {
        Write-Success "Completed: $Operation"
    }
}

function Write-TimedInfo {
    param([string]$Message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] [INFO] $Message" -ForegroundColor Blue
}

function Write-TimedSuccess {
    param([string]$Message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] [OK] $Message" -ForegroundColor Green
}

# Run command with timeout to prevent hanging
function Invoke-CommandWithTimeout {
    param(
        [string]$Command,
        [int]$TimeoutMinutes = 10,
        [string]$Description = "Command"
    )
    
    try {
        Write-Info "Running: $Description (timeout: ${TimeoutMinutes}m)"
        
        # Use Start-Process with timeout
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = "powershell.exe"
        $processInfo.Arguments = "-Command `"$Command`""
        $processInfo.UseShellExecute = $false
        $processInfo.RedirectStandardOutput = $true
        $processInfo.RedirectStandardError = $true
        $processInfo.CreateNoWindow = $true
        
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $processInfo
        $process.Start() | Out-Null
        
        # Wait for completion with timeout
        $timeoutMs = $TimeoutMinutes * 60 * 1000
        if ($process.WaitForExit($timeoutMs)) {
            $stdout = $process.StandardOutput.ReadToEnd()
            $stderr = $process.StandardError.ReadToEnd()
            $exitCode = $process.ExitCode
            
            return @{
                Success = ($exitCode -eq 0)
                ExitCode = $exitCode
                Output = $stdout
                Error = $stderr
            }
        } else {
            $process.Kill()
            Write-Warning "$Description timed out after $TimeoutMinutes minutes"
            return @{
                Success = $false
                ExitCode = -1
                Output = ""
                Error = "Command timed out"
            }
        }
    }
    catch {
        Write-Warning "Error running $Description`: $($_.Exception.Message)"
        return @{
            Success = $false
            ExitCode = -1
            Output = ""
            Error = $_.Exception.Message
        }
    }
    finally {
        if ($process -and !$process.HasExited) {
            $process.Kill()
        }
    }
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

# Check if running on Parallels Desktop with Apple Silicon
function Test-ParallelsAppleSilicon {
    try {
        $isParallels = $false
        $isARM = $false
        
        # === PARALLELS DETECTION ===
        
        # 1. Check system manufacturer and model (most reliable)
        $computerSystem = Get-WmiObject -Class Win32_ComputerSystem -ErrorAction SilentlyContinue
        if ($computerSystem) {
            $manufacturer = $computerSystem.Manufacturer
            $model = $computerSystem.Model
            
            # Parallels sets specific manufacturer/model strings
            $parallelsManufacturers = @(
                "Parallels Software International Inc.",
                "Parallels",
                "Parallels International GmbH"
            )
            
            $parallelsModels = @(
                "Parallels Virtual Platform",
                "Parallels ARM Virtual Machine",
                "Parallels Virtual Machine"
            )
            
            if ($parallelsManufacturers -contains $manufacturer -or $parallelsModels -contains $model) {
                $isParallels = $true
                Write-Info "Parallels detected via manufacturer/model: $manufacturer / $model"
            }
        }
        
        # 2. Check BIOS information
        if (-not $isParallels) {
            $bios = Get-WmiObject -Class Win32_BIOS -ErrorAction SilentlyContinue
            if ($bios -and ($bios.Manufacturer -like "*Parallels*" -or $bios.Version -like "*Parallels*")) {
                $isParallels = $true
                Write-Info "Parallels detected via BIOS: $($bios.Manufacturer) / $($bios.Version)"
            }
        }
        
        # 3. Check for Parallels registry keys
        if (-not $isParallels) {
            $parallelsRegKeys = @(
                "HKLM:\SOFTWARE\Parallels",
                "HKLM:\SYSTEM\CurrentControlSet\Services\prl_fs",
                "HKLM:\SYSTEM\CurrentControlSet\Services\prl_tg",
                "HKLM:\SYSTEM\CurrentControlSet\Services\prl_eth"
            )
            
            foreach ($key in $parallelsRegKeys) {
                if (Test-Path $key -ErrorAction SilentlyContinue) {
                    $isParallels = $true
                    Write-Info "Parallels detected via registry key: $key"
                    break
                }
            }
        }
        
        # 4. Check for Parallels files and drivers
        if (-not $isParallels) {
            $parallelsFiles = @(
                "C:\Windows\System32\drivers\prl_fs.sys",
                "C:\Windows\System32\drivers\prl_tg.sys",
                "C:\Windows\System32\drivers\prl_eth.sys",
                "C:\Program Files\Parallels\Parallels Tools",
                "C:\Windows\System32\prlvmagt.exe"
            )
            
            foreach ($file in $parallelsFiles) {
                if (Test-Path $file -ErrorAction SilentlyContinue) {
                    $isParallels = $true
                    Write-Info "Parallels detected via file: $file"
                    break
                }
            }
        }
        
        # 5. Check for Parallels services
        if (-not $isParallels) {
            $parallelsServices = @("prl_tools", "prl_cc", "prl_tg", "prl_fs")
            foreach ($serviceName in $parallelsServices) {
                if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
                    $isParallels = $true
                    Write-Info "Parallels detected via service: $serviceName"
                    break
                }
            }
        }
        
        # 6. Check PCI devices for Parallels hardware
        if (-not $isParallels) {
            $pciDevices = Get-WmiObject -Class Win32_PnPEntity -ErrorAction SilentlyContinue | Where-Object { 
                $_.HardwareID -like "*PRL*" -or $_.DeviceID -like "*PRL*" -or $_.Name -like "*Parallels*" 
            }
            if ($pciDevices.Count -gt 0) {
                $isParallels = $true
                Write-Info "Parallels detected via PCI device: $($pciDevices[0].Name)"
            }
        }
        
        # === ARM DETECTION ===
        
        # 1. Check processor architecture via WMI
        $processor = Get-WmiObject -Class Win32_Processor -ErrorAction SilentlyContinue
        if ($processor) {
            # Architecture 12 = ARM64, also check processor name
            if ($processor.Architecture -eq 12 -or $processor.Name -like "*ARM*" -or $processor.Name -like "*Apple*") {
                $isARM = $true
                Write-Info "ARM detected via processor: $($processor.Name) (Architecture: $($processor.Architecture))"
            }
        }
        
        # 2. Check environment variables
        if (-not $isARM) {
            if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64" -or $env:PROCESSOR_ARCHITEW6432 -eq "ARM64") {
                $isARM = $true
                Write-Info "ARM detected via environment: $($env:PROCESSOR_ARCHITECTURE)"
            }
        }
        
        # 3. Check via .NET runtime
        if (-not $isARM) {
            try {
                $runtimeArch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
                if ($runtimeArch -eq "Arm64") {
                    $isARM = $true
                    Write-Info "ARM detected via .NET runtime: $runtimeArch"
                }
            } catch {
                # .NET method not available, skip
            }
        }
        
        # Final result
        $result = $isParallels -and $isARM
        
        if ($result) {
            Write-Warning "CONFIRMED: Running on Parallels Desktop with Apple Silicon (ARM64)"
            Write-Info "WSL2 has known compatibility issues in this environment"
        } elseif ($isParallels -and -not $isARM) {
            Write-Info "Parallels Desktop detected but not on ARM architecture"
        } elseif (-not $isParallels -and $isARM) {
            Write-Info "ARM architecture detected but not in Parallels Desktop"
        } else {
            Write-Info "Native Windows environment detected"
        }
        
        return $result
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

    Start-Timer "WSL2 feature enablement"

    # Check if WSL is already enabled
    $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
    $vmFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform

    $needsRestart = $false

    if ($wslFeature.State -ne "Enabled") {
        Write-TimedInfo "Enabling Windows Subsystem for Linux..."
        dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
        $needsRestart = $true
    }

    if ($vmFeature.State -ne "Enabled") {
        Write-TimedInfo "Enabling Virtual Machine Platform..."
        dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
        $needsRestart = $true
    }

    # Configure nested virtualization settings automatically (before restart)
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

        if ($content -notmatch '(?m)^\[wsl2\]') {
            # No [wsl2] section yet - create one with the setting ON
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
                $content = $content -replace '(\[wsl2\][^\[]*)', ('$1' + "`r`n" + 'nestedVirtualization=true')
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

    if ($needsRestart) {
        Write-Warning "A restart is required to complete WSL installation."
        Write-Warning "AUTOMATIC RESTART in 10 seconds - Save any open work!"
        Write-Info "After restart, run this script again to complete the setup."
        Write-Host "Press Ctrl+C to cancel restart..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        Write-Host "Restarting computer now..." -ForegroundColor Red
        Restart-Computer -Force
        return
    }

    # Set WSL2 as default version (only if WSL is already working)
    try {
        wsl --set-default-version 2
        Write-Success "WSL2 set as default version"
    } catch {
        Write-Info "WSL not ready yet. Will set default version after restart."
    }

    Stop-Timer "WSL2 feature enablement"
}

# Install Ubuntu WSL2
function Install-UbuntuWSL {
    if ($SkipWSLInstall) {
        Write-Info "Skipping Ubuntu WSL installation"
        return
    }

    Start-Timer "Ubuntu WSL2 installation"

    # Check if WSL is working and VM Platform is ready
    try {
        # Test if WSL is functional
        $wslStatus = wsl --status 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "WSL is not ready yet. Please restart your computer and run this script again."
            Write-Info "This is normal after the first reboot - WSL features need time to fully initialize."
            return
        }
    } catch {
        Write-Warning "WSL is not ready. Please restart your computer and run this script again."
        return
    }

    # Check if Virtual Machine Platform is actually ready
    try {
        # Try to query hypervisor - this will fail if VM Platform isn't ready
        $hypervisorRunning = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty HypervisorPresent
        if (-not $hypervisorRunning) {
            Write-Warning "Virtual Machine Platform is enabled but not fully active yet."
            Write-Warning "AUTOMATIC RESTART required for virtualization to be ready."
            Write-Info "After restart, run this script again to complete Ubuntu installation."
            Write-Warning "AUTOMATIC RESTART in 10 seconds - Save any open work!"
            Write-Host "Press Ctrl+C to cancel restart..." -ForegroundColor Yellow
            Start-Sleep -Seconds 10
            Write-Host "Restarting computer now..." -ForegroundColor Red
            Restart-Computer -Force
            return
        }
    } catch {
        Write-Info "Could not verify hypervisor status, proceeding with installation..."
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
        Write-Info "Attempting to install Ubuntu (this may take 5-10 minutes)..."
        Write-Info "Progress will be shown below. Please wait without pressing any keys."
        
        # Method 1: Use modern wsl --install with Ubuntu (latest approach)
        try {
            # First try with just "Ubuntu" which gets the latest version
            Write-Info "Installing Ubuntu distribution via WSL..."
            $wslOutput = wsl --install -d Ubuntu --no-launch 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Ubuntu WSL2 installed via wsl --install"
            } else {
                # Check if the output contains the virtualization error
                if ($wslOutput -match "0x80370102|WslRegisterDistribution failed") {
                    Write-Warning "Virtualization error detected (0x80370102) - Virtual Machine Platform needs another restart."
                    Write-Host ""
                    Write-Host "WARNING: The Virtual Machine Platform is enabled but not fully activated yet." -ForegroundColor Yellow
                    Write-Host "This is common after the first restart following WSL2 feature installation." -ForegroundColor Yellow
                    Write-Host ""
                    Write-Host "Solution: Restart your computer to fully activate virtualization." -ForegroundColor Cyan
                    Write-Host "After restart, run this script again to complete Ubuntu installation." -ForegroundColor Cyan
                    Write-Host ""
                    Write-Warning "Skipping Ubuntu installation - restart required"
                    return
                } else {
                    # Try fallback to Ubuntu-22.04 if Ubuntu didn't work
                    Write-Info "Trying with Ubuntu-22.04 distribution (this may take 5-10 minutes)..."
                    $wslOutput2 = wsl --install -d Ubuntu-22.04 --no-launch 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-Success "Ubuntu WSL2 installed via wsl --install (Ubuntu-22.04)"
                    } else {
                        throw "wsl --install failed for both Ubuntu and Ubuntu-22.04. Output: $wslOutput2"
                    }
                }
            }
        } catch {
            $errorMsg = $_.Exception.Message
            Write-Warning "wsl --install failed: $errorMsg"
            
            # Check for specific virtualization error in the exception message
            if ($errorMsg -match "0x80370102|WslRegisterDistribution failed") {
                Write-Warning "Virtualization error detected - Virtual Machine Platform needs another restart to fully activate."
                Write-Warning "AUTOMATIC RESTART required for virtualization to be ready."
                Write-Info "After restart, run this script again to complete the setup."
                Write-Warning "AUTOMATIC RESTART in 10 seconds - Save any open work!"
                Write-Host "Press Ctrl+C to cancel restart..." -ForegroundColor Yellow
                Start-Sleep -Seconds 10
                Write-Host "Restarting computer now..." -ForegroundColor Red
                Restart-Computer -Force
                return
            }
            
            # Method 2: Try Microsoft Store approach (more modern than AppX)
            Write-Info "Trying Microsoft Store installation method..."
            
            try {
                # Try using winget to install Ubuntu from Microsoft Store
                if (Get-Command winget -ErrorAction SilentlyContinue) {
                    Write-Info "Installing Ubuntu via Windows Package Manager (winget)..."
                    $wingetResult = winget install Canonical.Ubuntu 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-Success "Ubuntu installed via winget"
                    } else {
                        throw "winget installation failed: $wingetResult"
                    }
                } else {
                    # Fallback: Try to launch Microsoft Store Ubuntu page
                    Write-Info "Opening Microsoft Store to install Ubuntu..."
                    Write-Info "Please install 'Ubuntu 22.04 LTS' from the Microsoft Store that opens"
                    
                    # Open Microsoft Store to Ubuntu page
                    Start-Process "ms-windows-store://pdp/?ProductId=9PN20MSR04DW"
                    
                    Write-Host ""
                    Write-Host "Microsoft Store should now be opening with Ubuntu..." -ForegroundColor Yellow
                    Write-Host "Please follow these steps:" -ForegroundColor Yellow
                    Write-Host "1. Click 'Install' in the Microsoft Store" -ForegroundColor Yellow
                    Write-Host "2. Wait for the download and installation to complete" -ForegroundColor Yellow
                    Write-Host "3. Click 'Open' or launch Ubuntu from Start Menu" -ForegroundColor Yellow
                    Write-Host "4. Complete the Ubuntu setup (username/password)" -ForegroundColor Yellow
                    Write-Host ""
                    Write-Host "Waiting for Ubuntu installation to complete..." -ForegroundColor Cyan
                    Write-Host "This script will automatically continue checking every 30 seconds" -ForegroundColor Cyan
                    Write-Host ""
                    
                    # Wait for Ubuntu to be installed
                    $maxWaitMinutes = 10
                    $waitCount = 0
                    $maxWaitCount = $maxWaitMinutes * 2  # Check every 30 seconds
                    
                    do {
                        Start-Sleep -Seconds 30
                        $waitCount++
                        Write-Host "Checking for Ubuntu installation... ($waitCount/$maxWaitCount)" -ForegroundColor Gray
                        
                        # Check if Ubuntu is available
                        $ubuntuTest = wsl -l 2>&1 | Where-Object { $_ -match "Ubuntu" }
                        if ($ubuntuTest) {
                            Write-Success "Ubuntu installation detected!"
                            break
                        }
                        
                        if ($waitCount -ge $maxWaitCount) {
                            Write-Warning "Timeout waiting for Ubuntu installation after $maxWaitMinutes minutes"
                            Write-Host "You can install Ubuntu manually later or re-run the script" -ForegroundColor Yellow
                            return
                        }
                    } while ($true)
                    
                    Write-Success "Ubuntu installation completed via Microsoft Store"
                }
                
                # Test if the distribution can actually start
                Write-Info "Testing Ubuntu installation..."
                $testResult = wsl -d Ubuntu-22.04 --exec echo "test" 2>&1
                if ($LASTEXITCODE -ne 0 -and $testResult -match "0x80370102") {
                    Write-Warning "Ubuntu installed but cannot start due to virtualization error (0x80370102)"
                    Write-Host ""
                    Write-Warning "Virtual Machine Platform needs one more restart to fully activate." -ForegroundColor Red
                    Write-Warning "AUTOMATIC RESTART in 10 seconds - Save any open work!"
                    Write-Host "Press Ctrl+C to cancel restart..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 10
                    Write-Info "Restarting to activate Virtual Machine Platform..."
                    Restart-Computer -Force
                    return
                }
            } catch {
                Write-Warning "Alternative installation method also failed: $($_.Exception.Message)"
                Write-Info "Ubuntu installation requires Virtual Machine Platform to be fully active."
                Write-Info "Please restart your computer and try again."
                return
            }
        }

        Write-Info "Please complete the Ubuntu setup (username/password) when prompted"
        Write-Info "You can start Ubuntu by running: wsl"
        Stop-Timer "Ubuntu WSL2 installation"
    }
    catch {
        if ($_.Exception.Message -match "0x80370102") {
            Write-Warning "Virtualization error detected. Virtual Machine Platform needs to be fully activated."
            Write-Info "Please restart your computer again and run this script to complete the installation."
        } else {
            Write-Warning "Ubuntu installation failed: $($_.Exception.Message)"
            Write-Info "You can install Ubuntu manually from Microsoft Store"
            Write-Info "Search for 'Ubuntu 22.04 LTS' in Microsoft Store"
        }
    }
}

# Install Windows development tools
function Install-WindowsTools {
    if ($SkipWindowsTools) {
        Write-Info "Skipping Windows tools installation"
        return
    }

    Start-Timer "Windows development tools installation"

    # Install Chocolatey if not present or corrupted
    $chocoWorking = $false
    try {
        # Test if Chocolatey is working properly
        $chocoTest = choco --version 2>$null
        if ($LASTEXITCODE -eq 0 -and $chocoTest) {
            $chocoWorking = $true
            Write-TimedSuccess "Chocolatey is already installed and working"
        }
    } catch {
        $chocoWorking = $false
    }
    
    if (-not $chocoWorking) {
        Start-Timer "Chocolatey installation"
        # Check for corrupted installation
        $chocoFolderExists = Test-Path "$env:ProgramData\chocolatey"
        if ($chocoFolderExists) {
            Write-Warning "Found existing Chocolatey installation that is not working properly"
            Write-Info "Cleaning up corrupted Chocolatey installation..."
            
            # Remove corrupted installation
            try {
                Get-Process | Where-Object { $_.ProcessName -like "*choco*" } | Stop-Process -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
                
                $corruptedPath = "$env:ProgramData\chocolatey"
                Get-ChildItem -Path $corruptedPath -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
                    $_.Attributes = "Normal"
                }
                Remove-Item -Path $corruptedPath -Recurse -Force -ErrorAction Stop
                Write-Success "Removed corrupted Chocolatey installation"
            } catch {
                Write-Warning "Could not fully remove corrupted installation: $($_.Exception.Message)"
                Write-Info "You may need to manually delete $env:ProgramData\chocolatey before continuing"
                return
            }
        }
        
        Write-Info "Installing Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        
        try {
            # Use Invoke-WebRequest and Invoke-Expression separately to avoid variable conflicts
            Write-Info "Downloading Chocolatey installation script..."
            $chocoInstallScript = (New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')
            
            Write-Info "Running Chocolatey installation..."
            # Execute in a separate scope to avoid variable conflicts
            & {
                Invoke-Expression $chocoInstallScript
            }
            
            # Verify installation succeeded
            Start-Sleep -Seconds 3
            $chocoVerifyTest = choco --version 2>$null
            if ($LASTEXITCODE -eq 0 -and $chocoVerifyTest) {
                Write-TimedSuccess "Chocolatey installed successfully"
                Stop-Timer "Chocolatey installation"
                
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
                    Write-Info "Please restart PowerShell or run: Import-Module `$env:ChocolateyInstall\\helpers\\chocolateyProfile.psm1; refreshenv"
                }
            } else {
                throw "Chocolatey installation verification failed"
            }
        } catch {
            Write-Error "Failed to install Chocolatey: $($_.Exception.Message)"
            Write-Info "Please install Chocolatey manually from https://chocolatey.org/install"
            return
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
        @{name="visualstudiocode"; fallback=$null; description="Visual Studio Code editor"},
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
                Write-Info "Installing $description (this may take several minutes)..."
                $result = choco install $toolName -y --limit-output --no-progress --acceptlicense --force --timeout 600
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
                    Write-Info "Trying fallback package '$fallback' (this may take several minutes)..."
                    try {
                        $result = choco install $fallback -y --limit-output --no-progress --acceptlicense --force --timeout 600
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
    Stop-Timer "Windows development tools installation"
    
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
    Write-Host "Uninstalling Windows Development Environment" -ForegroundColor Red
    Write-Host "===============================================" -ForegroundColor Red

    # Check prerequisites
    if (!(Test-Administrator)) {
        Write-Error "This script must be run as Administrator to uninstall"
        exit 1
    }

    Write-Warning "This will remove all development tools and configurations installed by this script."
    Write-Host ""
    Write-Host "The following will be removed:" -ForegroundColor Yellow
    Write-Host "- Chocolatey package manager" -ForegroundColor Yellow
    Write-Host "- All development tools (Git, VS Code, Python, Node.js, Java, etc.)" -ForegroundColor Yellow
    Write-Host "- WSL2/Ubuntu subsystem" -ForegroundColor Yellow
    Write-Host "- Development directories and configurations (optional)" -ForegroundColor Yellow
    Write-Host "- Environment variable modifications" -ForegroundColor Yellow
    Write-Host ""
    
    # Auto-confirm for non-interactive operation
    Write-Warning "Proceeding with automated uninstallation..."
    Write-Host ""
    Write-Host "Starting uninstallation..." -ForegroundColor Red

    # Remove Chocolatey packages (skip critical system tools)
    Write-Info "Removing Chocolatey packages..."
    
    # Enhanced package list with alternatives for better detection
    $tools = @(
        @{name="visualstudiocode"; alternatives=@("vscode")},
        @{name="eclipse"; alternatives=@("eclipse-java")},
        @{name="python"; alternatives=@("python3")},
        @{name="nodejs"; alternatives=@("node", "nodejs.install")},
        @{name="openjdk"; alternatives=@("temurin", "adoptopenjdk")},
        @{name="maven"; alternatives=@()},
        @{name="gradle"; alternatives=@()},
        @{name="docker-desktop"; alternatives=@("docker")},
        @{name="postman"; alternatives=@()},
        @{name="gitkraken"; alternatives=@("git-kraken")},
        @{name="microsoft-windows-terminal"; alternatives=@("microsoft-terminal", "windows-terminal")},
        @{name="powershell-core"; alternatives=@("powershell")}
    )

    # Note: We skip 'git' as it might be used by other applications
    Write-Warning "Note: Keeping Git installed as it may be used by other applications"
    Write-Info "To remove Git manually: choco uninstall git -y"

    # First, let's see what packages are actually installed
    Write-Info "Checking currently installed Chocolatey packages..."
    try {
        $installedPackages = choco list --local-only --limit-output 2>$null
        if ($installedPackages) {
            Write-Host "Found these packages:" -ForegroundColor Cyan
            $installedPackages | ForEach-Object { 
                $packageInfo = $_ -split '\|'
                if ($packageInfo.Count -ge 1) {
                    Write-Host "  - $($packageInfo[0])" -ForegroundColor Gray
                }
            }
            Write-Host ""
        }
    } catch {
        Write-Warning "Could not list installed packages: $_"
    }

    $removedCount = 0
    $failedCount = 0

    foreach ($tool in $tools) {
        $toolName = $tool.name
        $alternatives = $tool.alternatives
        $removed = $false
        
        # Try main package name first
        try {
            Write-Info "Attempting to remove $toolName..."
            $result = choco uninstall $toolName -y --limit-output --force --remove-dependencies 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Removed $toolName"
                $removedCount++
                $removed = $true
            }
        }
        catch {
            # Continue to try alternatives
        }
        
        # Try alternatives if main package failed
        if (-not $removed -and $alternatives.Count -gt 0) {
            foreach ($alt in $alternatives) {
                try {
                    Write-Info "Trying alternative package name: $alt"
                    $result = choco uninstall $alt -y --limit-output --force --remove-dependencies 2>$null
                    if ($LASTEXITCODE -eq 0) {
                        Write-Success "Removed $alt"
                        $removedCount++
                        $removed = $true
                        break
                    }
                }
                catch {
                    # Continue to next alternative
                }
            }
        }
        
        if (-not $removed) {
            Write-Info "$toolName not installed or already removed"
        }
    }

    # Special comprehensive search for VSCode and Node.js (common problem packages)
    Write-Info "Performing comprehensive search for VSCode and Node.js packages..."
    try {
        $installedPackages = choco list --local-only --limit-output 2>$null
        if ($installedPackages) {
            # Search for any package containing "code", "vscode", "visual", "node", "nodejs"
            $vscodePatterns = @("code", "vscode", "visual")
            $nodePatterns = @("node", "nodejs")
            
            foreach ($package in $installedPackages) {
                $packageName = ($package -split '\|')[0].ToLower()
                
                # Check for VSCode variants
                foreach ($pattern in $vscodePatterns) {
                    if ($packageName.Contains($pattern)) {
                        Write-Warning "Found potential VSCode package: $packageName"
                        try {
                            $result = choco uninstall $packageName -y --limit-output --force --remove-dependencies 2>$null
                            if ($LASTEXITCODE -eq 0) {
                                Write-Success "Removed VSCode package: $packageName"
                                $removedCount++
                            } else {
                                Write-Warning "Could not remove $packageName"
                            }
                        } catch {
                            Write-Warning "Error removing $packageName`: $_"
                        }
                        break
                    }
                }
                
                # Check for Node.js variants  
                foreach ($pattern in $nodePatterns) {
                    if ($packageName.Contains($pattern)) {
                        Write-Warning "Found potential Node.js package: $packageName"
                        try {
                            $result = choco uninstall $packageName -y --limit-output --force --remove-dependencies 2>$null
                            if ($LASTEXITCODE -eq 0) {
                                Write-Success "Removed Node.js package: $packageName"
                                $removedCount++
                            } else {
                                Write-Warning "Could not remove $packageName"
                            }
                        } catch {
                            Write-Warning "Error removing $packageName`: $_"
                        }
                        break
                    }
                }
            }
        }
    } catch {
        Write-Warning "Could not perform comprehensive package search: $_"
    }

    # Remove Chocolatey itself (comprehensive cleanup)
    Write-Info "Removing Chocolatey completely..."
    try {
        # Stop any running Chocolatey processes
        Get-Process | Where-Object { $_.ProcessName -like "*choco*" } | Stop-Process -Force -ErrorAction SilentlyContinue
        
        # Remove Chocolatey directories
        $chocoLocations = @(
            "$env:ChocolateyInstall",
            "$env:ProgramData\chocolatey",
            "$env:ALLUSERSPROFILE\chocolatey",
            "$env:SystemDrive\ProgramData\chocolatey"
        )
        
        $removedCount = 0
        foreach ($location in $chocoLocations) {
            if ($location -and (Test-Path $location)) {
                try {
                    # Take ownership and remove read-only attributes
                    Get-ChildItem -Path $location -Recurse -Force | ForEach-Object {
                        $_.Attributes = "Normal"
                    }
                    Remove-Item -Path $location -Recurse -Force -ErrorAction Stop
                    Write-Success "Removed Chocolatey from: $location"
                    $removedCount++
                } catch {
                    Write-Warning "Could not fully remove $location`: $($_.Exception.Message)"
                }
            }
        }
        
        # Remove Chocolatey from environment variables
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
        if ($currentPath) {
            $chocoPathPatterns = @(
                "$env:ChocolateyInstall\bin",
                "$env:ProgramData\chocolatey\bin",
                "$env:ALLUSERSPROFILE\chocolatey\bin"
            )
            
            foreach ($pattern in $chocoPathPatterns) {
                if ($pattern) {
                    $currentPath = $currentPath -replace [regex]::Escape($pattern + ";"), ""
                    $currentPath = $currentPath -replace [regex]::Escape($pattern), ""
                }
            }
            [Environment]::SetEnvironmentVariable("Path", $currentPath, "Machine")
        }
        
        # Remove ChocolateyInstall environment variable
        [Environment]::SetEnvironmentVariable("ChocolateyInstall", $null, "Machine")
        [Environment]::SetEnvironmentVariable("ChocolateyInstall", $null, "User")
        
        if ($removedCount -gt 0) {
            Write-Success "Chocolatey completely removed from $removedCount location(s)"
        } else {
            Write-Info "No Chocolatey installation found to remove"
        }
    }
    catch {
        Write-Warning "Could not remove Chocolatey completely: $($_.Exception.Message)"
        Write-Info "You may need to manually delete C:\ProgramData\chocolatey if it still exists"
    }

    # Remove WSL2 and Ubuntu
    Write-Info "Checking WSL2 and Ubuntu distributions..."
    try {
        # Check if WSL is available before trying to remove
        if (Get-Command wsl -ErrorAction SilentlyContinue) {
            # List all installed WSL distributions
            $wslList = wsl --list --verbose 2>$null
            if ($wslList) {
                Write-Info "Current WSL distributions:"
                $wslList | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
                
                # Check if any Ubuntu distributions exist
                $ubuntuDistros = @("Ubuntu", "Ubuntu-22.04", "Ubuntu-20.04", "Ubuntu-18.04", "ubuntu")
                $foundUbuntu = @()
                
                foreach ($distro in $ubuntuDistros) {
                    $checkResult = wsl --list --quiet 2>$null | Where-Object { $_ -eq $distro }
                    if ($checkResult) {
                        $foundUbuntu += $distro
                    }
                }
                
                if ($foundUbuntu.Count -gt 0) {
                    Write-Host ""
                    Write-Warning "Found Ubuntu WSL distribution(s): $($foundUbuntu -join ', ')"
                    Write-Host "WARNING: Automatic removal will DELETE ALL DATA inside Ubuntu distributions!" -ForegroundColor Red
                    Write-Host "This includes:" -ForegroundColor Yellow
                    Write-Host "- Your home directory and all files" -ForegroundColor Yellow
                    Write-Host "- Installed packages and configurations" -ForegroundColor Yellow
                    Write-Host "- Any development projects stored in WSL" -ForegroundColor Yellow
                    Write-Host ""
                    Write-Host "If you have important data, press Ctrl+C now to cancel!" -ForegroundColor Cyan
                    Write-Host "Proceeding with Ubuntu distribution removal in 5 seconds..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 5
                    
                    Write-Info "Removing Ubuntu distributions..."
                    $removedDistros = @()
                    
                    foreach ($distro in $foundUbuntu) {
                        $result = wsl --unregister $distro 2>&1
                            if ($LASTEXITCODE -eq 0) {
                                $removedDistros += $distro
                                Write-Success "Removed WSL distribution: $distro"
                            } else {
                                Write-Warning "Could not remove $distro`: $result"
                            }
                        }
                        
                        if ($removedDistros.Count -gt 0) {
                            Write-Success "Successfully removed $($removedDistros.Count) Ubuntu distribution(s): $($removedDistros -join ', ')"
                        }
                } else {
                    Write-Info "No Ubuntu distributions found to remove"
                }
                
                # Show remaining distributions
                $remainingList = wsl --list --verbose 2>$null
                if ($remainingList -and ($remainingList | Measure-Object).Count -gt 1) {
                    Write-Info "Remaining WSL distributions:"
                    $remainingList | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
                }
            } else {
                Write-Info "No WSL distributions found"
            }
        } else {
            Write-Info "WSL command not available (may not be installed)"
        }

        # Disable WSL features
        Write-Info "Disabling WSL features..."
        $dismResult1 = dism.exe /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart 2>&1
        $dismResult2 = dism.exe /online /disable-feature /featurename:VirtualMachinePlatform /norestart 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Disabled WSL2 features"
        } else {
            Write-Warning "Could not disable WSL features (may not be enabled): $dismResult1 $dismResult2"
        }
    }
    catch {
        Write-Warning "Error during WSL2/Ubuntu removal: $($_.Exception.Message)"
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

    # Remove development directories (automatic cleanup)
    Write-Host ""
    Write-Info "Checking for development directories to remove..."
    $devDirs = @(
        "$env:USERPROFILE\dev",
        "$env:USERPROFILE\projects",
        "$env:USERPROFILE\workspace",
        "$env:USERPROFILE\development"
    )

    $foundDirs = @()
    foreach ($dir in $devDirs) {
        if (Test-Path $dir) {
            $foundDirs += $dir
        }
    }

    if ($foundDirs.Count -gt 0) {
        Write-Warning "Found development directories to remove:"
        foreach ($dir in $foundDirs) {
            Write-Host "  - $dir" -ForegroundColor Yellow
        }
        Write-Host ""
        Write-Warning "These directories will be AUTOMATICALLY REMOVED in 5 seconds!"
        Write-Host "Press Ctrl+C to cancel if you have important files..." -ForegroundColor Cyan
        Start-Sleep -Seconds 5
        
        Write-Info "Removing development directories..."
        foreach ($dir in $foundDirs) {
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
    } else {
        Write-Info "No development directories found to remove"
    }

    # Final summary
    Write-Host ""
    Write-Host "Uninstallation Complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host "Packages removed: $removedCount" -ForegroundColor Green
    Write-Host "Failed removals: $failedCount" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Note: Some files may remain if they were in use during uninstallation." -ForegroundColor Yellow
    Write-Host "You may need to restart your computer for all changes to take effect." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To reinstall, run: .\setup-windows.cmd" -ForegroundColor Blue
}

# Main installation function
function Install-DevEnvironment {
    $scriptStartTime = Get-Date
    Write-Host "Setting up Windows Development Environment" -ForegroundColor Blue
    Write-Host "==========================================" -ForegroundColor Blue

    # Check prerequisites
    if (!(Test-Administrator)) {
        Write-Error "This script must be run as Administrator"
        exit 1
    }

    Test-WindowsVersion

    # Check for Parallels on Apple Silicon and set SkipWSLInstall accordingly
    Write-Host ""
    Write-Host "System Detection:" -ForegroundColor Cyan
    Write-Host "=================" -ForegroundColor Cyan
    
    $script:isParallelsAppleSilicon = Test-ParallelsAppleSilicon
    
    if ($script:isParallelsAppleSilicon) {
        $script:SkipWSLInstall = $true
        Write-Host ""
        Write-Warning "PARALLELS ON APPLE SILICON DETECTED!"
        Write-Warning "Automatically skipping WSL installation due to compatibility limitations"
        Write-Host ""
    } else {
        Write-Host "Proceeding with full Windows development environment installation" -ForegroundColor Green
        Write-Host ""
    }

    # Install all components
    Start-Timer "Complete development environment setup"
    
    # Enable WSL2 first (may require restart)
    Enable-WSL2
    
    # Check if we just enabled WSL features and need a restart
    if (Test-PendingReboot) {
        Write-Warning "Windows features were just enabled and require a restart to activate."
        Write-Info "After restart, run this script again to complete Ubuntu and tools installation."
        Write-Host ""
        Write-Host "Next steps after restart:" -ForegroundColor Yellow
        Write-Host "1. Run this script again as Administrator: .\setup-windows.cmd" -ForegroundColor Yellow
        Write-Host "2. Complete Ubuntu setup when prompted" -ForegroundColor Yellow
        Write-Host "3. Install VS Code extensions for your languages" -ForegroundColor Yellow
        return
    }
    
    # Continue with the rest of the installation
    Install-UbuntuWSL
    Install-WindowsTools
    Configure-WindowsTerminal
    Install-WSAA
    New-DevDirectories
    Set-DevEnvironment
    Test-Installation

    Write-Host ""
    Stop-Timer "Complete development environment setup"
    
    # Calculate total time
    $totalElapsed = (Get-Date) - $scriptStartTime
    $totalMinutes = [math]::Round($totalElapsed.TotalMinutes, 1)
    Write-Host ""
    Write-Host "Total setup time: ${totalMinutes} minutes" -ForegroundColor Cyan

    # Next steps
    Write-Host ""
    Write-Host "Windows Development Environment Setup Complete" -ForegroundColor Green
    Write-Host ""
    
    if ($script:SkipWSLInstall) {
        if ($script:isParallelsAppleSilicon) {
            Write-Host "Next steps (Parallels on Apple Silicon):" -ForegroundColor Yellow
            Write-Host "1. Use Windows-native development tools and IDEs" -ForegroundColor Yellow
            Write-Host "2. Install VS Code extensions for your languages" -ForegroundColor Yellow
            Write-Host "3. Use PowerShell for command-line operations" -ForegroundColor Yellow
            Write-Host "4. Use the quickstart scripts to create new projects" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Note: WSL2 and Ubuntu were skipped due to compatibility limitations with Parallels on Apple Silicon" -ForegroundColor Cyan
        } else {
            Write-Host "Next steps (WSL installation skipped):" -ForegroundColor Yellow
            Write-Host "1. Install VS Code extensions for your languages" -ForegroundColor Yellow
            Write-Host "2. Use the quickstart scripts to create new projects" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "1. Launch Ubuntu from Start Menu and complete setup" -ForegroundColor Yellow
        Write-Host "2. Run the WSL setup script: wsl bash ~/dev-scripts/setup/windows/setup-wsl.sh" -ForegroundColor Yellow
        Write-Host "3. Install VS Code extensions for your languages" -ForegroundColor Yellow
        Write-Host "4. Use the quickstart scripts to create new projects" -ForegroundColor Yellow
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
