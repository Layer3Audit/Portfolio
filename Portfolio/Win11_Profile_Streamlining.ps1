$ErrorActionPreference = 'Stop'   # Make non-terminating errors become terminating for cmdlets/functions

Function Write-Step {
    Param([string]$Message)
    Write-Host "[STEP] $Message" -ForegroundColor Cyan
}

Function Write-ErrorStep {
    Param([string]$Message)
    Write-Warning "[ERROR] $Message"
}

Function Set-RegValueSafe {
    Param(
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$Type = "String"
    )

    # Ensure parent exists
    $parent = Split-Path $Path
    If (-not (Test-Path $parent)) {
        Try { New-Item $parent -Force | Out-Null }
        Catch { Write-ErrorStep $_.Exception.Message; return }
    }

    # Ensure exact path exists
    If (-not (Test-Path $Path)) {
        Try { New-Item $Path -Force | Out-Null }
        Catch { Write-ErrorStep $_.Exception.Message; return }
    }

    # Write the value
    Try {
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type
    }
    Catch {
        Write-ErrorStep $_.Exception.Message
    }
}

Function Invoke-AdminBlock {
    Param([ScriptBlock]$Code)

    # Create temp file for elevated script
    $temp = [System.IO.Path]::GetTempFileName() + ".ps1"
    
    Try {
        Set-Content -Path $temp -Value $Code -Encoding UTF8
    }
    Catch {
        Write-ErrorStep $_.Exception.Message
    }

    Write-Step "Launching elevated powershell"
    Try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "powershell.exe"
        $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$temp`""
        $psi.Verb = "runas"
        [System.Diagnostics.Process]::Start($psi) | Out-Null
    }
    Catch {
        Write-ErrorStep $_.Exception.Message
    }
}

# ===============================================================
# USER-CONTEXT COMMANDS
# ===============================================================

Write-Host -ForegroundColor Magenta "Running user-level section"

# ------------------------- START MENU --------------------------
Write-Step "Configuring start menu settings"
Set-RegValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Start" -Name "ShowRecentList" -Value 0 -Type "DWord"
Set-RegValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Start" -Name "ShowFrequentList" -Value 0 -Type "DWord"

Set-RegValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackDocs" -Value 0 -Type "DWord"
Set-RegValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_RecoPersonalizedSites" -Value 0 -Type "DWord"
Set-RegValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_IrisRecommendations" -Value 0 -Type "DWord"
Set-RegValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_AccountNotifications" -Value 0 -Type "DWord"

# --------------------------- THEMES ----------------------------
Write-Step "Configuring windows themes"
Set-RegValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -Type "DWord"
Set-RegValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 -Type "DWord"

# --------------------------- TASKBAR ---------------------------
Write-Step "Configuring taskbar settings"
Set-RegValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 1 -Type "DWord"

Write-Step "Configuring taskbar alignment"
Set-RegValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value 0 -Type "DWord"

Write-Step "Configuring accent color"
Set-RegValueSafe -Path "HKCU:\Control Panel\Desktop" -Name "AutoColorization" -Value 1 -Type "DWord"

# -------------------------- BACKGROUND -------------------------
Write-Step "Configuring solid background"
Set-RegValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers" -Name "BackgroundType" -Value 1 -Type "DWord"
Set-RegValueSafe -Path "HKCU:\Control Panel\Desktop" -Name "WallPaper" -Value '' -Type "String"

Write-Step "Configuring background color"
Set-RegValueSafe -Path "HKCU:\Control Panel\Colors" -Name "Background" -Value "0 99 177" -Type "String"

Write-Step "Configuring style rules"
Set-RegValueSafe -Path "HKCU:\Control Panel\Desktop" -Name "WallpaperStyle" -Value 0 -Type "String"
Set-RegValueSafe -Path "HKCU:\Control Panel\Desktop" -Name "Pattern" -Value 0 -Type "DWord"

# ----------------------- WINDOWS EXPLORER ----------------------
Write-Step "Configuring windows explorer"
Set-RegValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -Type "DWord"
Set-RegValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideDrivesWithNoMedia" -Value 0 -Type "DWord"
Set-RegValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type "DWord"
Set-RegValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideMergeConflicts" -Value 0 -Type "DWord"
Set-RegValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "SharingWizardOn" -Value 0 -Type "DWord"

# ---------------------------- OTHER ----------------------------
Write-Step "Configuring onedrive backup notifications"
Set-RegValueSafe -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\Microsoft.SkyDrive.Desktop" -Name "Enabled" -Value 0 -Type "DWord"

Write-Step "Configuring other windows notifications"
Set-RegValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" -Name "ScoobeSystemSettingEnabled" -Value 0 -Type "DWord"

Write-Step "Configuring widgets"
Set-RegValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0 -Type "DWord"

# ---------------------------- APPS -----------------------------
Write-Step "Cleaning built-in apps"
Try { Get-AppxPackage -Name Microsoft.MicrosoftSolitaire* | Remove-AppxPackage }
Catch { Write-ErrorStep $_.Exception.Message }

Try { Get-AppxPackage -Name Microsoft.GamingApp* | Remove-AppxPackage }
Catch { Write-ErrorStep $_.Exception.Message }

Try { Get-AppxPackage -Name Microsoft.Xbox.TCUI | Remove-AppxPackage }
Catch { Write-ErrorStep $_.Exception.Message }

# --------------------------- CLEANUP ---------------------------
Write-Step "Cleaning user desktop"
Try { $userDesktop = [Environment]::GetFolderPath("Desktop")
    Get-ChildItem -Path $userDesktop -File -Force | Where-Object { $_.Extension -in '.lnk', '.url' } |  Remove-Item -Force -ErrorAction Stop }
Catch { Write-ErrorStep $_.Exception.Message }

Write-Step "Cleaning user temp folder"
Try { Remove-Item "$env:LOCALAPPDATA\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue *> $null }
Catch { Write-ErrorStep $_.Exception.Message }

# ===============================================================
# ADMIN BLOCK (elevated)
# ===============================================================

$AdminCode = {

    Function Write-Step { param([string]$Message) Write-Host "[STEP] $Message" -ForegroundColor Cyan }
    Function Write-ErrorStep { param([string]$Message) Write-Warning "[ERROR] $Message" }
    Function Set-RegValueSafe {
        Param(
            [string]$Path,
            [string]$Name,
            [object]$Value,
            [string]$Type = "String"
        )

        $parent = Split-Path $Path
        If (-not (Test-Path $parent)) {
            Try { New-Item $parent -Force | Out-Null }
            Catch { Write-ErrorStep $_.Exception.Message; return }
        }

        If (-not (Test-Path $Path)) {
            Try { New-Item $Path -Force | Out-Null }
            Catch { Write-ErrorStep $_.Exception.Message; return }
        }

        Try {
            Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type
        }
        Catch {
            Write-ErrorStep $_.Exception.Message
        }
    }

    Clear-Host
    Write-Host -ForegroundColor Magenta "Running elevated section"

    # ------------------------- LOCAL ADMIN -------------------------
    Write-Step "Configuring local administrator account"
    Try { net user Administrator /active:yes *>$null }
    Catch { Write-ErrorStep $_.Exception.Message }

    Write-Step "Configuring local administrator password"
    Try {
        $AdminCred = Import-Clixml -Path "$PSScriptRoot\Local_Admin.xml"
        $PlainPassword = $AdminCred.GetNetworkCredential().Password
        net user Administrator $PlainPassword *>$null
    }
    Catch { Write-ErrorStep $_.Exception.Message }

    # -------------------------- TCP/IP -----------------------------
    Write-Step "Configuring tcp/ip settings"
    Try { Disable-NetAdapterBinding -Name "Ethernet*", "Wi-Fi*" -ComponentID ms_tcpip6 }
    Catch { Write-ErrorStep $_.Exception.Message }
    
    # ---------------------- NETWORK PROFILE ------------------------
    Write-Step "Configuring network profile"
    Try {Get-NetConnectionProfile | Where-Object { $_.InterfaceAlias -match "Ethernet|Wi-Fi" } |  Set-NetConnectionProfile -NetworkCategory Private }
    Catch { Write-ErrorStep $_.Exception.Message }
  
    # ---------------------------- WINRM ----------------------------
    Write-Step "Configuring windows remote management"
    Try { $rule = Get-NetFirewallRule -Name "WINRM-HTTP-In-TCP" -ErrorAction SilentlyContinue
        If ($rule.Enabled -ne 'True') {Enable-PSRemoting -Force *> $null } } 
    Catch { Write-ErrorStep $_.Exception.Message }
    
    # -------------------------- FIREWALL ---------------------------
    Write-Step "Configuring firewall for winrm"
    Try { $rule = Get-NetFirewallRule -Name "WINRM-HTTP-In-TCP" -ErrorAction SilentlyContinue | Where-Object { $_.Enabled -ne 'True' }
        If ($rule) { Set-NetFirewallRule -Name "WINRM-HTTP-In-TCP" -Enabled True -ErrorAction Stop } }
    Catch { Write-ErrorStep $_.Exception.Message }
    
    Write-Step "Configuring firewall for network discovery"
    Try { $rules = Get-NetFirewallRule -DisplayGroup "Network Discovery" -ErrorAction SilentlyContinue | Where-Object { $_.Enabled -ne 'True' }
        If ($rules) { $rules | Set-NetFirewallRule -Enabled True -ErrorAction Stop } }
    Catch { Write-ErrorStep $_.Exception.Message }

    Write-Step "Configuring firewall for file and printer sharing"
    Try { $rules = Get-NetFirewallRule -DisplayGroup "File and Printer Sharing" -ErrorAction SilentlyContinue | Where-Object { $_.Enabled -ne 'True' }
        If ($rules) { $rules | Set-NetFirewallRule -Enabled True -ErrorAction Stop } }
    Catch { Write-ErrorStep $_.Exception.Message }

    Write-Step "Configuring firewall for remote desktop"
    Try { $rules = Get-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue | Where-Object { $_.Enabled -ne 'True' }
        If ($rules) { $rules | Set-NetFirewallRule -Enabled True -ErrorAction Stop } }
    Catch { Write-ErrorStep $_.Exception.Message }   
    
    Write-Step "Configuring firewall for wmi"
    Try { $rules = Get-NetFirewallRule -DisplayGroup "Windows Management Instrumentation (WMI)" -ErrorAction SilentlyContinue | Where-Object { $_.Enabled -ne 'True' }
        if ($rules) { $rules | Set-NetFirewallRule -Enabled True -ErrorAction Stop } }
    Catch { Write-ErrorStep $_.Exception.Message }
 
    # ----------------------- POWER SETTINGS ------------------------
    Write-Step "Configuring display timeout (while plugged in)"
    Try { powercfg /change monitor-timeout-ac 120 *> $null }
    Catch { Write-ErrorStep $_.Exception.Message }

    Write-Step "Configuring sleep timeout (while plugged in)"
    Try { powercfg /change standby-timeout-ac 0 *> $null }
    Catch { Write-ErrorStep $_.Exception.Message }

    # ----------------------- REMOTE DESKTOP ------------------------
    Write-Step "Configuring remote desktop connection"
    Set-RegValueSafe -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Type "DWord"
    Set-RegValueSafe -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -Value 0 -Type "DWord"

    # ------------------------- OTHER -------------------------------
    Write-Step "Configuring control panel views"
    $CPKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel"
    If (-not (Test-Path $CPKey)) { New-Item $CPKey -Force | Out-Null }
    Set-RegValueSafe -Path $CPKey -Name "StartupPage" -Value 1 -Type "DWord"
    Set-RegValueSafe -Path $CPKey -Name "AllItemsIconView" -Value 1 -Type "DWord"

    Write-Step "Configuring general device health"
    Set-RegValueSafe -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceHealth" -Name "DisableBackupNotification" -Value 1 -Type "DWord"

    Write-Step "Configuring convertibility settings"
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\PriorityControl" -Name "ConvertibilityEnabled" -Value 0 -Type "DWord"

    Write-Step "Configuring account backup notifications"
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableAccountNotifications" -Value 1 -Type "DWord"

    # ---------------------------- UCPD -----------------------------
    Write-Step "Configuring ucpd service"
    Set-RegValueSafe -Path "HKLM:\SYSTEM\CurrentControlSet\Services\UCPD" -Name "Start" -Value 2 -Type "DWord"

    # ---------------------------- APPS -----------------------------
    Write-Step "Configuring microsoft edge"
    Get-Process msedge -ErrorAction SilentlyContinue | Stop-Process -Force
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "HideFirstRunExperience" -Value 1 -Type "DWord"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "PersonalizationReportingEnabled" -Value 0 -Type "DWord"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ShowHomeButton" -Value 1 -Type "DWord"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "HomepageLocation" "https://www.google.com.au" -Type "String"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "HomepageIsNewTabPage" -Value 0 -Type "DWord"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "NewTabPageLocation" -Value "https://www.google.com.au" -Type "String"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "RestoreOnStartupURLs" -Value "https://www.google.com.au" -Type "String"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ShowRecommendationsEnabled" -Value 0 -Type "DWord"

    # ------------------------- CLEANUP -----------------------------
    Write-Step "Cleaning public desktop"
    Try { $publicDesktop = "C:\Users\Public\Desktop"
    Get-ChildItem -Path $publicDesktop -File -Force | Where-Object { $_.Extension -in '.lnk', '.url' } | Remove-Item -Force -ErrorAction Stop }
    Catch { Write-ErrorStep $_.Exception.Message }
    
    Write-Step "Cleaning event Logs"
    Try { wevtutil el | ForEach-Object { wevtutil cl $_ } *> $null}
    Catch { Write-ErrorStep $_.Exception.Message }

    Write-Step "Cleaning windows temp folder"
    Try { Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue *> $null }
    Catch { Write-ErrorStep $_.Exception.Message }
    
    # --------------------- AUTO-EXIT WAIT LOOP ---------------------
    Write-Step "Waiting for user-level exit"
    while (-not (Test-Path "C:\Windows\Temp\AdminClose.flag")) {
        Start-Sleep -Milliseconds 250
    }
    Try { Remove-Item "C:\Windows\Temp\AdminClose.flag" -Force }
    Catch {}
    Exit
}

# ===============================================================
# EXECUTE ADMIN BLOCK
# ===============================================================
Invoke-AdminBlock $AdminCode

# Wait for user to continue and create the flag (user-context)
Read-Host "Press Enter to continue..."
Try { New-Item "C:\Windows\Temp\AdminClose.flag" -ItemType File -Force | Out-Null }
Catch { Write-ErrorStep $_.Exception.Message }
