Write-Host "Taskkill ExpertAssistant"
Invoke-Command -ComputerName wmprdxsh01 { Start-Process -FilePath "C:\Windows\system32\taskkill.exe" -ArgumentList "/F", "/IM ExpertAssistantDetached.exe", "/T"}

Write-Host "Taskkill IE"
Invoke-Command -ComputerName wmprdxsh01 { Start-Process -FilePath "C:\Windows\system32\taskkill.exe" -ArgumentList "/F", "/IM iexplore.exe", "/T"}

Write-Host "Invoke-Command Aderant.ExpertLauncherCO.exe"
Invoke-Command -ComputerName wmprdxsh01 { Start-Process -FilePath "C:\AderantExpert\PROD\Aderant.ExpertLauncherInstaller\Aderant.ExpertLauncherCO.exe"}