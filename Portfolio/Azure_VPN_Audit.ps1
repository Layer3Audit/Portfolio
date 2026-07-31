$ScriptFolder = $PSScriptRoot
$LogFile = $ScriptFolder + "\Azure_VPN_Audit.txt"

# Start transcription
Start-Transcript -Path $LogFile

# Azure Connection
Try {
    Write-Host "Checking Azure connection" -ForegroundColor Cyan
    $azureContext = Get-AzContext -ErrorAction SilentlyContinue
    
    If (-not $azureContext) {
        Write-Host -ForegroundColor Yellow "No active session detected. Initiating login" 
        Connect-AzAccount -ErrorAction Stop | Out-Null
    }
    Else {
        Write-Host -ForegroundColor Green "Existing session detected for profile: $($azureContext.Account)"
    }
}
Catch {
    Write-Warning $error[0]
    Pause
    Exit
}

# Define Variables
$resourceGroup = "resourceGroupName"
$vpnConnectionName = "vpnConnectionName"
$vpnGatewayName = "vpnGatewayName"
$localGatewayName = "localGatewayName"

# Get VPN Connection Details
$vpnConnection = Get-AzVirtualNetworkGatewayConnection -ResourceGroupName $resourceGroup -Name $vpnConnectionName
$vpnGateway = Get-AzVirtualNetworkGateway -ResourceGroupName $resourceGroup -Name $vpnGatewayName
$localGateway = Get-AzLocalNetworkGateway -ResourceGroupName $resourceGroup -Name $localGatewayName

# Display VPN Connection Details
Write-Host "`nVPN Connection Details" -ForegroundColor Cyan
Write-Host "------------------------"
Write-Host "Name: " -ForegroundColor Yellow -NoNewline; Write-Host $vpnConnection.Name
Write-Host "Connection Status: " -ForegroundColor Yellow -NoNewline; Write-Host $vpnConnection.ConnectionStatus
Write-Host "Connection Type: " -ForegroundColor Yellow -NoNewline; Write-Host $vpnConnection.ConnectionType
Write-Host "Egress Data (Bytes): " -ForegroundColor Yellow -NoNewline; Write-Host $vpnConnection.EgressBytesTransferred
Write-Host "Ingress Data (Bytes): " -ForegroundColor Yellow -NoNewline; Write-Host $vpnConnection.IngressBytesTransferred
Write-Host "BGP Enabled: " -ForegroundColor Yellow -NoNewline; Write-Host $vpnConnection.EnableBgp
Write-Host "Provisioning State: " -ForegroundColor Yellow -NoNewline; Write-Host $vpnConnection.ProvisioningState

# Display VPN Gateway Details
Write-Host "`nVPN Gateway Details" -ForegroundColor Cyan
Write-Host "-------------------"
Write-Host "Name: " -ForegroundColor Yellow -NoNewline; Write-Host $vpnGateway.Name
Write-Host "Gateway Type: " -ForegroundColor Yellow -NoNewline; Write-Host $vpnGateway.GatewayType
Write-Host "VPN Type: " -ForegroundColor Yellow -NoNewline; Write-Host $vpnGateway.VpnType
Write-Host "BGP Enabled: " -ForegroundColor Yellow -NoNewline; Write-Host $vpnGateway.EnableBgp
Write-Host "Active-Active Mode: " -ForegroundColor Yellow -NoNewline; Write-Host $vpnGateway.ActiveActive
Write-Host "SKU: " -ForegroundColor Yellow -NoNewline; Write-Host $vpnGateway.Sku.Name

# Display VPN Gateway Address Spaces
Write-Host "`nVPN Gateway Address Spaces" -ForegroundColor Cyan
Write-Host "----------------------------"
If ($vpnGateway.VpnClientConfiguration.VpnClientAddressPool.AddressPrefixes) {
    $vpnGateway.VpnClientConfiguration.VpnClientAddressPool.AddressPrefixes | ForEach-Object {
        Write-Host "Address Space: " -ForegroundColor Yellow -NoNewline; Write-Host $_
    }
} 
Else {
    Write-Host "No VPN Client Address Spaces Found." -ForegroundColor Red
}

# Display Local Network Gateway Details
Write-Host "`nLocal Network Gateway Details" -ForegroundColor Cyan
Write-Host "----------------------------"
Write-Host "Name: " -ForegroundColor Yellow -NoNewline; Write-Host $localGateway.Name
Write-Host "Gateway IP Address: " -ForegroundColor Yellow -NoNewline; Write-Host $localGateway.GatewayIpAddress

# Display Local Network Gateway Address Spaces
Write-Host "`nLocal Network Gateway Address Spaces" -ForegroundColor Cyan
Write-Host "---------------------------------"
If ($localGateway.AddressSpaceText) {
    Write-Host "Address Space: " -ForegroundColor Yellow -NoNewline; Write-Host $localGateway.AddressSpaceText
} 
Else {
    Write-Host "No Local Network Address Spaces Found." -ForegroundColor Red
}

# Display Virtual Network Gateway Address Spaces
Write-Host "`nVirtual Network Gateway Address Spaces" -ForegroundColor Cyan
Write-Host "-------------------------------------"
If ($vpnGateway.IpConfigurations) {
    ForEach ($ipConfig in $vpnGateway.IpConfigurations) {
        # Extract and display the Subnet Name
        $subnetId = $ipConfig.Subnet.Id
        $subnetName = $subnetId -split '/subnets/' | Select-Object -Last 1
        Write-Host "Subnet Name: " -ForegroundColor Yellow -NoNewline; Write-Host $subnetName
        
        # Extract the Public IP Address ID and parse it to get the Resource Group and Name
        $publicIpId = $ipConfig.PublicIpAddress.Id
        $publicIpIdParts = $publicIpId -split "/"
        $publicIpName = $publicIpIdParts[-1]
        $publicIpResourceGroup = $publicIpIdParts[4]  # The resource group is at the 5th position in the path
        
        # Get the Public IP Address
        $publicIp = Get-AzPublicIpAddress -ResourceGroupName $publicIpResourceGroup -Name $publicIpName
        Write-Host "Public IP Address: " -ForegroundColor Yellow -NoNewline; Write-Host $publicIp.IPAddress
    }
} 
Else {
    Write-Host "No Virtual Network Address Spaces Found." -ForegroundColor Red
}

# Stop transcription
""
Stop-Transcript
Pause