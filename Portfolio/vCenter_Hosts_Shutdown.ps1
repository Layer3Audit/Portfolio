Clear-Host
#Import-Module VMware.PowerCLI

# Other Parameters
$ErrorActionPreference = "Stop"
$ScriptFolder = $PSScriptRoot
$LogFile = $ScriptFolder + "\vCenter_Hosts_Shutdown.txt"

# ESXi & vCenter parameters
$esxiHost1 = "esx1.contoso.com.au"
$esxiHost2 = "esx2.contoso.com.au"
$vCenter = "vcsa1.contoso.com.au"

# Secure Credentials
$vCenterCredPath = $PSScriptRoot + "\vCenter_Admin.xml"
$esxiCredPath = $PSScriptRoot + "\ESXi_Root.xml"

# Credentials Import
try { $vcCredential   = Import-Clixml -Path $vCenterCredPath }
catch { Write-Warning $error[0]}

try { $esxiCredential = Import-Clixml -Path $esxiCredPath }
catch { Write-Warning $error[0] }

# Suppress certificate warnings
try { Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null }
catch { Write-Warning $error[0]}

# Start transcription
Start-Transcript -Path $LogFile

# Connecting to vCenter Server
Write-Host "`nConnecting to vCenter Server"
try {
    $vCenterConnection = Connect-VIServer -Server $vCenter -Credential $vcCredential -ErrorAction Stop

    # Initialize timeout tracking
    $globalStartTime = Get-Date
    $globalTimeout = 90  # Total timeout

    # Gracefully shutting down or powering off VMs
    Write-Host "`nGracefully shutting down or powering off VMs`n"
    $vmList = Get-VM | Where-Object {$_.PowerState -eq "PoweredOn" -and $_.Name -notlike "vCLS*" -and $_.Name -ne "VMware vCenter Server"}  

    $vmList | ForEach-Object {
        if ($_.ExtensionData.Guest.ToolsStatus -eq "toolsRunning" -or $_.ExtensionData.Guest.ToolsStatus -eq "toolsOK") {
            Write-Host "Attempting graceful shutdown of $($_.Name)..."
            Shutdown-VMGuest -VM $_ -Confirm:$false
        }
        else {
            Write-Host "VMware Tools is not running on $($_.Name), powering off"
            Stop-VM -VM $_ -Confirm:$false 
        }
    }

    # Wait for VMs to shut down or forcefully power them off
    foreach ($vm in $vmList) {
        if ($vm.PowerState -eq "PoweredOn") {
            Write-Host "Waiting for $($vm.Name) to shut down..."
            
            while ($vm.PowerState -eq "PoweredOn") {
                Start-Sleep -Seconds 1
                $vm = Get-VM -Name $vm.Name  # Refresh the VM object
                
                # Check if the total timeout has been reached
                $elapsedTime = (Get-Date) - $globalStartTime
                if ($elapsedTime.TotalSeconds -ge $globalTimeout) {
                    Write-Host "Global timeout reached, powering off remaining VMs."
                    if ($vm.PowerState -eq "PoweredOn") {
                        Stop-VM -VM $vm -Confirm:$false | Out-Null
                        break
                    }
                }
            }
        }
    }

    # Shutting down host
    Write-Host "`nShutting down host:" $esxiHost2
    if (Test-Connection -ComputerName $esxiHost2 -Count 1 -Quiet) {
        Stop-VMHost -VMHost $esxiHost2 -RunAsync -Force -Confirm:$false
    }
    else {
        Write-Host "Host is not responding, ignoring"
    }

    # Disconnect from vCenter Server
    Write-Host "`nDisconnecting from vCenter Server"
    if (Test-Connection -ComputerName $vCenter -Count 1 -Quiet) {
        Disconnect-VIServer -Server $vCenter -Confirm:$false
    } 
    else {
        Write-Host "vCenter Server not responding, ignoring"
    }
}
catch {
    Write-Warning $error[0]
}

# Connecting to host
Write-Host "`nConnecting to host:" $esxiHost1 "`n"
try {
    $HostConnection = Connect-VIServer -Server $esxiHost1 -Credential $esxiCredential -ErrorAction Stop

    # Shutting down the vCenter Server
    Write-Host "`nShutting down the vCenter Server"
    $vCenterVM = Get-VM -Name "VMware vCenter Server"
    if ($vCenterVM.PowerState -eq "PoweredOn") {
        Write-Host "Waiting for server to shut down..."
        Shutdown-VMGuest -VM $vCenterVM -Confirm:$false
        $startTime = Get-Date
        $timeout = 30  # Timeout in seconds

        # Wait for the VM to power off
        while ($vCenterVM.PowerState -eq "PoweredOn") {
        Start-Sleep -Seconds 1
        $vCenterVM = Get-VM -Name $vCenterVM.Name  # Refresh the VM object

            # Check if the timeout has been reached
            $elapsedTime = (Get-Date) - $startTime
            if ($elapsedTime.TotalSeconds -ge $timeout) {
            Write-Host "Timeout reached, powering off $($vCenterVM.Name)."
            Stop-VM -VM $vCenterVM -Confirm:$false | Out-Null
            break
            }
        }
    }

    # Shut down the host
    Write-Host "`nShutting down host:" $esxiHost1
        if (Test-Connection -ComputerName $esxiHost1 -Count 1 -Quiet) {
            Stop-VMHost -VMHost $esxiHost1 -RunAsync -Force -Confirm:$False
        } 
        else {
            Write-Host "Host not responding, ignoring"
        }
}
catch {
    Write-Warning $error[0]
}

# Stop transcription
""
Stop-Transcript