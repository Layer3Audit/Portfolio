# --- CONFIGURATION ---
$UserDir = "D:\Users\User"

# --- DIR EXCLUSIONS (Exact List) ---
$ExcludeXD = @(
    "$UserDir\.asdm",
    "$UserDir\.ms-ad",
    "$UserDir\.vscode"
)

# --- FILE EXCLUSIONS & LOGGING ---
$ExcludeXF = @('UsrClass.*','WebCacheLock.*','ntuser.*')
$LogFile = "$PSScriptRoot\Backup_Robocopy_USB_$(get-date -f ddMMyyyy_HHmm).txt"
$Param = ("/E", "/NP", "/NDL", "/TEE", "/W:1", "/R:1", "/PURGE", "/LOG+:$LogFile")

# --- INITIALIZE TOTALS ---
$Script:TotalSourceBytes = 0
$Script:TotalCopyBytes   = 0
$Script:FolderReports    = @() 

# --- MODE SELECTION ---
Write-Host "Insert drive labelled 'USB BACKUP' and make sure it's mapped to H:"
$RunMode = Read-Host "Press 'e' to [e]stimate total backup size or press 'ENTER' to start backup"

# --- DRIVE CHECKS ---
Write-Host "`nChecking USB H: drive"
If (Test-Path -Path "H:") { 
    Write-Host "H: drive already mapped" 
}
Else { 
    Write-Host "H: drive not present, exiting"
    Read-Host "Press ENTER to continue..."
    Exit
}

Write-Host "`nChecking Plex server V: drive"
If (Test-Path -Path "V:\Plex Server") { Write-Host "V: drive already mapped" } Else { 
    Write-Host "Attemting to map V: drive"
    net use V: \\192.168.100.1\d$
}

Write-Host "`nChecking NAS X: drive"
If (Test-Path -Path "X:\Music") { Write-Host "X: drive already mapped" } Else {
    Write-Host "Attempting to map X: drive"
    net use X: \\nas.contoso.com.au\Media
}

# --- FUNCTION ---
Function RC {
    Param(
        [Parameter(Mandatory=$true)][string]$Source,
        [Parameter(Mandatory=$true)][string]$Destination,
        [switch]$UseXD, 
        [switch]$UseXF
    )
    
    $CurrentParams = $Param
    If ($UseXD) { 
        $CurrentParams += "/XD"; $CurrentParams += $ExcludeXD 
    }
    If ($UseXF) { 
        $CurrentParams += "/XF"; $CurrentParams += $ExcludeXF 
    }

    # BACKUP ESTIMATE
    If ($RunMode -eq "e") {
        $CurrentParams += "/L", "/NFL", "/BYTES"     
        $JobOutput = Robocopy $Source $Destination $CurrentParams
        $JobOutput | Write-Host

        # Scrape numbers
        $ByteLine = $JobOutput | Where-Object { $_ -match "^\s*Bytes :" }
        If ($ByteLine -match "Bytes :\s+(\d+)\s+(\d+)") {
            $SrcBytes = $matches[1]
            $CpyBytes = $matches[2]

            $Script:TotalSourceBytes += $SrcBytes
            $Script:TotalCopyBytes   += $CpyBytes

            $FolderGB = [math]::Round($SrcBytes / 1GB, 2)
            $Script:FolderReports += [PSCustomObject]@{
                Source = $Source
                Dest   = $Destination
                Size   = $FolderGB
            }
        }
    }
    Else {
        # REAL BACKUP
        Robocopy $Source $Destination $CurrentParams
    }
}

If ($RunMode -eq "e") {
    Write-Host "`nEstimating total backup size (process running in background)..." -ForegroundColor Cyan
    }
Else {
    Write-Host "`nRunning backup..." -ForegroundColor Cyan
}

# --- JOBS ---
RC "D:\Users" "H:\Users"
RC "D:\Temp" "H:\Temp" -UseXD
RC "D:\GAMING" "H:\GAMING" -UseXD
RC "D:\PERSONAL" "H:\PERSONAL" -UseXD
RC "D:\SHARED" "H:\SHARED" -UseXD
RC "D:\SYSTEM" "H:\SYSTEM" -UseXD
RC "D:\WORK" "H:\WORK" -UseXD
RC "V:\Plex Server" "V:\Plex Server"

# --- CLEANUP & SUMMARY ---
Write-Host "Disconnecting V: drive"
net use V: /delete /yes

If ($RunMode -eq "e") {
    $TotalGB = [math]::Round($Script:TotalSourceBytes / 1GB, 2)
    $CopyGB  = [math]::Round($Script:TotalCopyBytes / 1GB, 2)
    
    # --- RIGHT ALIGNMENT LOGIC (ENDS AT COL 79) ---
    $ReportText = "------------------------------------------------------------------------------`n"
    $ReportText +=                        "DETAILED SIZE BREAKDOWN`n"
    $ReportText += "------------------------------------------------------------------------------`n"
    
    Foreach ($Item in $Script:FolderReports) {
        $SizeStr = "$($Item.Size) GB"
        $PathStr = """$($Item.Source)"" ""$($Item.Dest)"""
        
        # Calculate padding so the string ends at certain line
        $SpaceAvailable = 78 - $PathStr.Length
        
        # Safety: Ensure at least one space if path is very long
        If ($SpaceAvailable -lt ($SizeStr.Length + 1)) { $SpaceAvailable = $SizeStr.Length + 1 }

        # PadLeft fills the "Size" string with spaces until it fits the available slot
        $ReportText += $PathStr + $SizeStr.PadLeft($SpaceAvailable) + "`n"
    }

    $ReportText += "------------------------------------------------------------------------------`n"
    
    # Totals Alignment
    $TotalStr = "$TotalGB GB"
    $Label    = "Total data size (Size of all source folders):"
    $Space    = 78 - $Label.Length
    $ReportText += $Label + $TotalStr.PadLeft($Space) + "`n"
    
    $CopyStr  = "$CopyGB GB"
    $Label    = "Data to transfer (Data to be copied to the USB):"
    $Space    = 78 - $Label.Length
    $ReportText += $Label + $CopyStr.PadLeft($Space) + "`n"
    
    $ReportText += "------------------------------------------------------------------------------`n"

    # Output to Screen
    Write-Host $ReportText -ForegroundColor Yellow

    # Log File Summary
    Add-Content -Path $LogFile -Value $ReportText
} 
Else {
    Write-Host "`nUSB Backup Complete" -ForegroundColor Green
}

Read-Host "Press ENTER to continue..."