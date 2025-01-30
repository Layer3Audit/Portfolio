taskkill /S wmprdxsh01 /F /IM AppShell.exe
taskkill /S wmprdxsh01 /F /IM ExpertAccountsPayable.exe
taskkill /S wmprdxsh01 /F /IM ExpertAssistant.exe
taskkill /S wmprdxsh01 /F /IM ExpertAssistantDetached.exe
taskkill /S wmprdxsh01 /F /IM ExpertBilling.exe
taskkill /S wmprdxsh01 /F /IM ExpertCollections.exe
taskkill /S wmprdxsh01 /F /IM ExpertDisbursements.exe
taskkill /S wmprdxsh01 /F /IM ExpertEntityManager.exe
taskkill /S wmprdxsh01 /F /IM ExpertExpenses.exe
taskkill /S wmprdxsh01 /F /IM ExpertLauncher.exe
taskkill /S wmprdxsh01 /F /IM ExpertMatterPlanning.exe
taskkill /S wmprdxsh01 /F /IM ExpertRates.exe
taskkill /S wmprdxsh01 /F /IM ExpertTime.exe

#Invoke-Command -ComputerName wmprdxsh01 { Start-Process -FilePath "C:\Windows\system32\taskkill.exe" -ArgumentList "/F", "/IM iexplore.exe", "/T"} -ErrorAction Stop