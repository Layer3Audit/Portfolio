# Parameters
$Targets = @(
    @{ Name = "192.168.50.1"; Description = "Domain Controller" },
    @{ Name = "10.10.101.1"; Description = "Web Proxy Server" },
    @{ Name = "172.18.40.1"; Description = "Mitel Server Manager" },
    #@{ Name = "10.10.44.1"; Description = "Server 4" },
    @{ Name = "8.8.8.8"; Description = "Google DNS" }
)

$LatencyThreshold = 1500
$LogFile = $PSScriptRoot + "\Site_Latency_Monitor.txt"
$InterfaceAlias = "Ethernet*"

# Setup
if (!(Test-Path (Split-Path $LogFile))) {
    New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null
}

Write-Host "Monitoring latency... Press Ctrl + C to stop." -ForegroundColor Cyan
Write-Host "Logging will start once latency exceeds ${LatencyThreshold} ms." -ForegroundColor Yellow

# Detect Source IP from interface
$SourceIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias $InterfaceAlias -ErrorAction SilentlyContinue |
              Where-Object { $_.IPAddress -notmatch '169\.254' } |
              Select-Object -First 1 -ExpandProperty IPAddress)

if (-not $SourceIP) {
    Write-Host "Warning: No matching IPv4 address found on interface alias '$InterfaceAlias'." -ForegroundColor Yellow
    $SourceIP = "Unknown"
}

# Write header once
if (-not (Test-Path $LogFile)) {
    ("Time".PadRight(20) +
     "Source IP".PadRight(18) +
     "Destination IP".PadRight(18) +
     "Description".PadRight(35) +
     "Status".PadRight(10) +
     "Latency (ms)") | Out-File -FilePath $LogFile -Encoding utf8
    ("─" * 115) | Out-File -FilePath $LogFile -Append -Encoding utf8
}

# Main loop
while ($true) {
    $results = foreach ($t in $Targets) {
        $ping = Test-Connection -ComputerName $t.Name -Count 1 -ErrorAction SilentlyContinue

        if ($ping) {
            [PSCustomObject]@{
                Time           = (Get-Date).ToString("yy/MM/dd HH:mm:ss")
                SourceIP       = $SourceIP
                DestinationIP  = $t.Name
                Description    = $t.Description
                Status         = "Online"
                LatencyMs      = [math]::Round($ping.ResponseTime, 1)
            }
        } else {
            [PSCustomObject]@{
                Time           = (Get-Date).ToString("yy/MM/dd HH:mm:ss")
                SourceIP       = $SourceIP
                DestinationIP  = $t.Name
                Description    = $t.Description
                Status         = "Offline"
                LatencyMs      = $null
            }
        }
    }

    Clear-Host
    $results | Format-Table Time, SourceIP, DestinationIP, Description, Status, LatencyMs -AutoSize

    # Detect high latency
    $alert = $results | Where-Object { $_.LatencyMs -gt $LatencyThreshold }

    if ($alert) {
        foreach ($r in $results) {
            $timeStr   = $r.Time
            $destStr   = $r.DestinationIP
            $descStr   = $r.Description
            $statusStr = $r.Status
            $latStr    = if ($r.LatencyMs -ne $null) { "$($r.LatencyMs) ms" } else { "-" }

            ($timeStr.PadRight(20) +
             $SourceIP.PadRight(18) +
             $destStr.PadRight(18) +
             $descStr.PadRight(35) +
             $statusStr.PadRight(10) +
             $latStr) |
                Out-File -FilePath $LogFile -Append -Encoding utf8
        }
        Write-Host "`nWarning: High latency detected — logging data to $LogFile" -ForegroundColor Yellow
    }

    Start-Sleep -Seconds 2
}
