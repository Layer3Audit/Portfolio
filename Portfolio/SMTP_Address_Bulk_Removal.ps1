Clear
$TimeStamp = Get-Date -format 'HH.mm:ss | dd/MM/yyyy'
$LogFile = "$PSScriptRoot\SMTP_Address_Bulk_Removal.txt"

# Get Departments
$RootOU = "DC=contoso,DC=com,DC=au"
$CompanyOU = "OU=Company"

$DepartmentOU = @()
$DepartmentOU += "OU=" + "Accounts" + ",$CompanyOU" + ",$RootOU"
$DepartmentOU += "OU=" + "Admin" + ",$CompanyOU" + ",$RootOU"
$DepartmentOU += "OU=" + "HR" + ",$CompanyOU" + ",$RootOU"
$DepartmentOU += "OU=" + "IT" + ",$CompanyOU" + ",$RootOU"
$DepartmentOU += "OU=" + "Vendors" + ",$CompanyOU" + ",$RootOU"

$ErrorActionPreference = "Continue"
Start-Transcript -path $LogFile -Append

# Loop through each department
ForEach ($Department in $DepartmentOU) {

    $Users = Get-User -OrganizationalUnit "$Department"

    # Loop through each user
    foreach ($User in $Users) {

        # Check is user has a mailbox
        If ($User.RecipientTypeDetails -eq "RemoteUserMailbox") {
        # -and $User.RecipientType -eq "MailUser" -or $User.RecipientType -eq "UserMailbox") {
        $Mailboxes = Get-RemoteMailbox -identity $User.Name
        
            # Loop through each mailbox
            foreach ($Mailbox in $Mailboxes) {

                # Change @contoso.com to the domain that you want to remove
                Write-Host -ForegroundColor Green "User: $Mailbox | Department: $Department | Type: O365"
                $Mailbox.EmailAddresses | Where-Object { ($_ -clike "smtp*") -and ($_ -like "*@contoso.com.au") } | 
    
                    # Perform operation on each item
                    ForEach-Object {

                    # Remove the -WhatIf parameter after you tested and are sure to remove the secondary email addresses
                    Set-RemoteMailbox $Mailbox.Name -EmailAddresses @{remove = $_ } #-WhatIf
                    Write-Host "*** Removing $_ from $Mailbox Mailbox" -ForegroundColor Yellow
                    }
            }
        }

        ElseIf ($User.RecipientTypeDetails -eq "UserMailbox") {
        # -and $User.RecipientType -eq "MailUser" -or $User.RecipientType -eq "UserMailbox") {
        $Mailboxes = Get-Mailbox -identity $User.Name

            # Loop through each mailbox
            foreach ($Mailbox in $Mailboxes) {

                # Change @contoso.com to the domain that you want to remove
                Write-Host -ForegroundColor Cyan "User: $Mailbox | Department: $Department | Type: On-Prem"
                $Mailbox.EmailAddresses | Where-Object { ($_ -clike "smtp*") -and ($_ -like "*@contoso.com.au") } | 
    
                    # Perform operation on each item
                    ForEach-Object {

                    # Remove the -WhatIf parameter after you tested and are sure to remove the secondary email addresses
                    Set-Mailbox $Mailbox.Name -EmailAddresses @{remove = $_ } #-WhatIf
                    Write-Host "*** Removing $_ from $Mailbox Mailbox" -ForegroundColor Yellow
                    }
                }
        }

        # Warms user does not have a mailbox
        Else {
        Write-Host -ForegroundColor DarkRed "User:" $User.SamAccountName "| Department: $Department | Type: AD Only (No mail)"
        }
    
    }
}
""
$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-nul