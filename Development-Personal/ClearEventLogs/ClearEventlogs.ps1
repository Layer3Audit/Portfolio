### Start Elevate to Admin Process ###
Param(
    [Parameter(Mandatory=$false)]
    [Switch]$shouldAssumeToBeElevated,

    [Parameter(Mandatory=$false)]
    [String]$workingDirOverride
)

# If parameter is not set, we are propably in non-admin execution. We set it to the current working directory so that
#  the working directory of the elevated execution of this script is the current working directory
If(-Not($PSBoundParameters.ContainsKey('workingDirOverride')))
{
    $workingDirOverride = (Get-Location).Path
}

Function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

# If we are in a non-admin execution. Execute this script as admin
If ((Test-Admin) -eq $false)  {
    If ($shouldAssumeToBeElevated) {
        Write-Host -ForegroundColor red "Elevate to admin did not work"
        Start-Sleep -Seconds 5
        
    } Else {
        #                                                         vvvvv add `-noexit` here for better debugging vvvvv 
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -file "{0}" -shouldAssumeToBeElevated -workingDirOverride "{1}"' -f ($myinvocation.MyCommand.Definition, "$workingDirOverride"))
        Write-Host -ForegroundColor green "Elevate to admin worked"
    }
    Exit
}

Set-Location "$workingDirOverride"
### End Elevate to Admin Process ###
Write-Host -ForegroundColor Magenta "*** Session running in admin context ***"


Write-Host -ForegroundColor Cyan "`nClearing Event Logs`n"

wevtutil el | Foreach-Object {Write-Host "Clearing $_"; wevtutil cl "$_"}

Write-Host -ForegroundColor Cyan "`nClearing Event Logs Complete"
Read-host "`nPress ENTER to continue..."