#/E :: copy subdirectories, including Empty ones.
#/NP :: No Progress - don't display percentage copied.
#/NDL :: No Directory List - don't log directory names
#/TEE :: output to console window, as well as the log file.
#/PURGE :: delete dest files/dirs that no longer exist in source.
#robocopy "D:\Container" "L:\DATA\Container" $parameters.split(' ') /LOG+:$logfile /XD $exclude

Write-Host  -ForegroundColor Green "Copying latest Aderant client files"
Write-Host "Press any key to continue..."
cmd /c pause | out-null
$parameters = '/E /NP /NDL /TEE /W:1 /R:1 /PURGE'
$logfile = "C:\Temp\AderantUpdate" + "_" + $(get-date -f ddMMyyyy_HHmm) + ".log"
robocopy "\\wmprdade03\Aderant\EX_EXPERTSHARE.PROD" "C:\AderantExpert\Installer\EX_EXPERTSHARE.PROD" $parameters.split(' ') /LOG+:$logfile
Write-Host "" `n

Write-Host  -ForegroundColor Green "Lauching Aderant.ExpertLauncherCO.exe"
Write-Host "Press any key to continue..."
cmd /c pause | out-null
Start-Process -NoNewWindow -FilePath "C:\AderantExpert\PROD\Aderant.ExpertLauncherInstaller\Aderant.ExpertLauncherCO.exe" -Wait
Write-Host "" `n

Write-Host  -ForegroundColor Green "Job Complete"
Write-Host "Press any key to continue..."
cmd /c pause | out-null