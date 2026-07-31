# Version 0.10
# Converted Backup, Prune and Restore logic to functions
# Streamlined CreateShortcut function
# Added version number and colors + incorrect key feedback to menu

param ([string]$GameName)

$ScriptPath = $MyInvocation.MyCommand.Path
$FirstLineInScript = Get-Content -Path $ScriptPath -TotalCount 1
$Script:FileCreation = $False
$Script:LastRunState = $Null
$Script:FullSaveGamePath = "I:\_SAVEGAMES\"+$Script:GameName+"\CreateSaveGame"
$Script:ArgumentsFile = $Script:FullSaveGamePath+"\CreateSaveGame.txt"

If ($FirstLineInScript -match '#\s*Version\s*(.+)') {
    $ScriptVersion = $Matches[1]
}

If (-Not (Test-Path -Path $Script:ArgumentsFile)) {
    Write-Warning "Argument file not found at: $Script:ArgumentsFile"
    Pause
    Exit
}

Function GameVariables {
    $Script:ArgumentsContent         = Get-Content -Path $Script:ArgumentsFile -ErrorAction SilentlyContinue
    $Script:ExitGameAtBackup         = $Script:ArgumentsContent[0].Substring(30)
    $Script:ExitGameAtRestore        = $Script:ArgumentsContent[1].Substring(30)
    $Script:KeepBackupFilesCount     = $Script:ArgumentsContent[2].Substring(30)
    $Script:GameTitle                = $Script:ArgumentsContent[3].Substring(30)
    $Script:GameSteamID              = $Script:ArgumentsContent[4].Substring(30)
    $Script:GameExecutable           = $Script:ArgumentsContent[5].Substring(30)
    $Script:GameProcessName          = $Script:ArgumentsContent[6].Substring(30)
    $Script:GameArguments            = $Script:ArgumentsContent[7].Substring(30)
    $Script:SaveGameSourceRoot       = $Script:ArgumentsContent[8].Substring(30)
    $Script:SaveGameDestinationRoot  = $Script:ArgumentsContent[9].Substring(30)
    $Script:SaveGameFolder           = $Script:ArgumentsContent[10].Substring(30)
    $Script:EnableDebugMenu          = $Script:ArgumentsContent[11].Substring(30)
    $Script:BackupFilesCreated       = (Get-ChildItem $Script:SaveGameDestinationRoot -Exclude $Script:SaveGameFolder -ErrorAction SilentlyContinue | Where-Object { $_.PsIsContainer }).Count
    $Script:SaveGameSource           = $Script:SaveGameSourceRoot+"\"+$Script:SaveGameFolder
    $Script:SaveGameDestination      = $Script:SaveGameDestinationRoot+"\"+$Script:SaveGameFolder
    $Script:ShortcutTarOrg           = $Script:SaveGameSourceRoot
    $Script:ShortcutLnkOrg           = $Script:SaveGameDestinationRoot+"\_SaveGames Original.lnk"
    $Script:ShortcutTarBak           = $Script:SaveGameDestinationRoot
    $Script:ShortcutLnkBak           = $Script:SaveGameSourceRoot+"\_SaveGames Backup.lnk"
}

Function CreateSaveGameFolder {
    If (!(Test-Path $Script:SaveGameDestinationRoot)) {
        Write-Host -ForegroundColor Yellow "Creating save game folder: $Script:SaveGameDestinationRoot "
        
        Try {
            New-Item -Path $Script:SaveGameDestinationRoot -ItemType Directory -ErrorAction Stop | Out-Null
            $Script:FileCreation = $True
        } 
        Catch {
            Write-Warning "Error during [save folder creation]: $_"
            Pause
            Exit
        }
    }
}

Function CreateShortcut ($ShortcutTarget, $ShortcutLnk) {
    If (-Not (Test-Path $ShortcutLnk)) {
        Try {
            Write-Host -ForegroundColor Yellow "Creating folder shortcuts: $ShortcutLnk"
            $WshShell = New-Object -comObject WScript.Shell
            $Shortcut = $WshShell.CreateShortcut($ShortcutLnk)
            $Shortcut.TargetPath = $ShortcutTarget
            $Shortcut.Save()
            $Script:FileCreation = $True
        } 
        Catch {
            Write-Warning "Error during [shortcut creation]: $_"
            Pause
            Exit
        }
    }
}

Function BackupFiles {
    Write-Host "`nPreparing to create save game backup"
        If ($Script:ExitGameAtBackup -eq $True) {
            GameProcess -Shutdown -Steam
        }
        Else {
            Write-Host "Exit game before backup is set to false"
        }


    Write-Host -ForegroundColor Cyan "`nBacking up game files"
        If (-not (Test-Path -Path $Script:SaveGameDestination)) {
            Try {
                New-Item -Path $Script:SaveGameDestination -ItemType Directory -ErrorAction Stop | Out-Null
            }
            Catch {
                Write-Warning "Error during [save game folder creation]: $_"
                Pause
            }
        }
    
        Try {
            $BackupGameItems = Copy-Item $Script:SaveGameSource\* $Script:SaveGameDestination -Recurse -Force -PassThru -ErrorAction Stop
            $Folders = $BackupGameItems | Where-Object { $_.PSIsContainer }
            $Files = $BackupGameItems | Where-Object { -not $_.PSIsContainer }
            
            If ($Folders.Count -gt 0) {
                ForEach ($Folder in $Folders) {
                    Write-Host "Copied folder: $($Folder.FullName)"
                }
            } 
            ElseIf ($Files.Count -gt 0) {
                ForEach ($File in $Files) {
                    Write-Host "Copied file: $($File.FullName)"
                }
            }
            Else {
                Write-Host "No items copied"
            }
        }
        Catch {
            Write-Warning "Error during [save game folder copy]: $_"
            Pause
        }
        Start-Sleep -Seconds 2
        
    Write-Host -ForegroundColor Cyan "`nBacking up game files (with date stamp)"
        $Script:SaveGameDestinationDate = $Script:SaveGameDestination+"_"+$((Get-Date).ToString('yyMMdd_HHmmss'))
        Try {
            New-Item -Path $Script:SaveGameDestinationDate -ItemType Directory -ErrorAction Stop | Out-Null
        }
        Catch {
            Write-Warning "Error during [save game folder creation]: $_"
            Pause
        }

        Try {
            $BackupGameItemsDate = Copy-Item $Script:SaveGameSource\* $Script:SaveGameDestinationDate -Recurse -Force -PassThru -ErrorAction Stop
            $Folders = $BackupGameItemsDate | Where-Object { $_.PSIsContainer }
            $Files = $BackupGameItemsDate | Where-Object { -not $_.PSIsContainer }
            
            If ($Folders.Count -gt 0) {
                ForEach ($Folder in $Folders) {
                    Write-Host "Copied folder: $($Folder.FullName)"
                }
            } 
            ElseIf ($Files.Count -gt 0) {
                ForEach ($File in $Files) {
                    Write-Host "Copied file: $($File.FullName)"
                }
            }
            Else {
                Write-Host "No items copied"
            }

        }
        Catch {
            Write-Warning "Error during [save game folder copy]: $_"
            Pause
        }
        Start-Sleep -Seconds 1
}

Function PruneFiles {
    Write-Host -ForegroundColor Cyan "`nPruning game backup folders (keeping $Script:KeepBackupFilesCount latest)"
        Try {
            $FoldersToDelete = Get-ChildItem $Script:SaveGameDestinationRoot -Exclude $Script:SaveGameFolder |
            Where-Object { $_.PsIsContainer } |
            Sort-Object CreationTime -Descending |
            Select-Object -Skip $Script:KeepBackupFilesCount
        
            If ($FoldersToDelete) {
                Foreach ($Folder in $FoldersToDelete) {
                    Write-Host "Deleting folder: $($folder.FullName)"
                    Remove-Item $($folder.FullName) -Recurse -Force -ErrorAction Stop
                }
            } 
            Else {
                Write-Host "No folders to prune"
            }
        }
        Catch {
            Write-Warning "Error during [save game folder deletion]: $_"
            Pause
        }
        Start-Sleep -Seconds 1

        $Script:BackupFilesCreated = (Get-ChildItem $Script:SaveGameDestinationRoot -Exclude $Script:SaveGameFolder | Where-Object {$_.PsIsContainer}).Count
        If (($Script:ExitGameAtBackup -eq $True) -and ($Script:LastRunState -eq $True)) {
            GameLaunch
        }
        Start-Sleep -Seconds 2
}

Function RestoreFiles {
    Write-Host "`nPreparing to restore save game backup"
        If ($Script:ExitGameAtRestore -eq $True) {
            GameProcess -Shutdown -Steam
        }
        Else {
            Write-Host "Exit game before restore set to false"
        }

        If (-not (Test-Path -Path $Script:SaveGameSource)) {
            Write-Host -ForegroundColor Red "`nCannot find save game folder"
            Pause
        }
        Else {
            Write-Host -ForegroundColor Cyan "`nRestoring game files"
                Try {
                    $RestoreGameItems = Copy-Item $Script:SaveGameDestination\* $Script:SaveGameSource -Recurse -Force -PassThru -ErrorAction Stop
                    $Folders = $RestoreGameItems | Where-Object { $_.PSIsContainer }
                    $Files = $RestoreGameItems | Where-Object { -not $_.PSIsContainer }

                    If ($Folders.Count -gt 0) {
                        ForEach ($Folder in $Folders) {
                            Write-Host "Copied folder: $($Folder.FullName)"
                        }
                    } 
                    ElseIf ($Files.Count -gt 0) {
                        ForEach ($File in $Files) {
                            Write-Host "Copied file: $($File.FullName)"
                        }
                    }
                    Else {
                        Write-Host "No items copied"
                    }
                    Start-Sleep -Seconds 2
                }
                Catch {
                    Write-Warning "Error during [save game folder copy]: $_"
                    Pause
                }
        }

        If (($Script:ExitGameAtRestore -eq $True) -and ($Script:LastRunState -eq $True)) {
            GameLaunch
        }
}

Function GameProcess ([switch]$Shutdown,[switch]$Steam) {
    If (Get-Process $Script:GameProcessName -ErrorAction SilentlyContinue) {
        Write-Host "`nGame is running"
        $Script:LastRunState = $True
        Start-Sleep -Seconds 1

        If ($Shutdown.IsPresent) {
            Write-Host "Attempting to shut down game process"
            $GameProcess = Get-Process $Script:GameProcessName
            $GameProcess.CloseMainWindow() | Out-Null
            Start-Sleep -Seconds 1
        }

        If ($Steam.IsPresent) {
            $Counter = $Null
            Do {
                $SteamAppRunningValue = Get-ItemProperty -Path 'HKCU:\SOFTWARE\valve\Steam' -Name RunningAppId -ErrorAction SilentlyContinue
                $Counter++
                Write-Host "Waiting $Counter seconds for Steam AppId registry value to reset (or for 1 minute timeout)" -NoNewline "`r"
                Start-Sleep -Seconds 1
            }
            Until (($Counter -eq 60) -or ($SteamAppRunningValue.RunningAppId -eq 0)) ; ""
        }
    }
    Else {
        Write-Host "`nGame not running"
        $Script:LastRunState = $False
        Start-Sleep -Seconds 1
    }
}

Function GameLaunch {
    If (Get-Process $Script:GameProcessName -ErrorAction SilentlyContinue) {
        Write-Host "`nGame is running"
        Start-Sleep -Seconds 1
    }
    Else {
        If ($Script:GameSteamID) {
            Write-Host "`nLaunching game via SteamID $Script:GameSteamID"
            If (-Not ($Script:GameArguments)) {
                Try {
                    Start-Process steam://rungameid/$Script:GameSteamID -Wait -ErrorAction Stop
                    Start-Sleep -Seconds 1
                } 
                Catch {
                    Write-Warning "Error during [Steam launch process]: $_"
                    Pause
                }
            }
            Else{
                Write-Host "With parameters: steam://rungameid/$Script:GameSteamID//$Script:GameArguments"
                Try {
                    Start-Process steam://rungameid/$Script:GameSteamID//$Script:GameArguments -Wait -ErrorAction Stop
                    Start-Sleep -Seconds 5
                } 
                Catch {
                    Write-Warning "Error during [Steam launch process]: $_"
                    Pause
                }
            }
        }

        ElseIf ($Script:GameExecutable) {
            $GameDirectory = Split-Path -Path $Script:GameExecutable -Parent
            Set-Location $GameDirectory
            Write-Host "`nLaunching game executable, from:" $GameDirectory
            If (-Not ($Script:GameArguments)) {
                Try {
                    Start-Process $Script:GameExecutable -ErrorAction Stop  #-Wait
                    Start-Sleep -Seconds 1
                }
                Catch {
                    Write-Warning "Error during [executable] launch process]: $_"
                    Pause
                }
            }
            Else {
                Write-Host "With parameters: $Script:GameExecutable $Script:GameArguments"
                Try {
                    Start-Process $Script:GameExecutable -ArgumentList $Script:GameArguments -ErrorAction Stop #-Wait
                    Start-Sleep -Seconds 5
                } 
                Catch {
                    Write-Warning "Error during [executable] launch process]: $_"
                    Pause
                }
            }
        }
        
        Else {
            Write-Host "`nNo valid executable or SteamID defined"
            Start-Sleep -Seconds 1
        }
    }
}

Function DebugMenu {
    Write-Host "`n========================================"
    Write-Host "Debug menu variables:"
    Write-Host "ExitGameAtBackup:            " $Script:ExitGameAtBackup
    Write-Host "ExitGameAtRestore:           " $Script:ExitGameAtRestore
    Write-Host "KeepBackupFilesCount:        " $Script:KeepBackupFilesCount
    Write-Host "BackupFilesCreated           " $Script:BackupFilesCreated
    Write-Host "GameTitle:                   " $Script:GameTitle
    Write-Host "GameSteamID:                 " $Script:GameSteamID
    Write-Host "GameExecutable:              " $Script:GameExecutable
    Write-Host "GameProcessName:             " $Script:GameProcessName
    Write-Host "GameArguments:               " $Script:GameArguments
    Write-Host "SaveGameSourceRoot:          " $Script:SaveGameSourceRoot
    Write-Host "SaveGameDestinationRoot:     " $Script:SaveGameDestinationRoot
    Write-Host "SaveGameFolder:              " $Script:SaveGameFolder
}

Function RunMenu {
    param ([string]$MenuTitle = $Script:GameTitle)

    If ($Script:EnableDebugMenu -ne $True) {Clear-Host}
    Write-Host -ForegroundColor Cyan "Backup menu $ScriptVersion for:" $MenuTitle
    Write-Host "========================================"
    Write-Host "Press " -NoNewline ; Write-Host "+" -NoNewline -ForegroundColor DarkMagenta; Write-Host " to create save game backup"
    Write-Host "Press " -NoNewline ; Write-Host "-" -NoNewline -ForegroundColor DarkMagenta; Write-Host " to restore save game backup"
    Write-Host "Press " -NoNewline ; Write-Host "*" -NoNewline -ForegroundColor DarkMagenta; Write-Host " to open save game folder"
    Write-Host "Press " -NoNewline ; Write-Host "1" -NoNewline -ForegroundColor DarkMagenta; Write-Host " to open config file"
    Write-Host "Press " -NoNewline ; Write-Host "3" -NoNewline -ForegroundColor DarkMagenta; Write-Host " to reload config file data"
    Write-Host "Press " -NoNewline ; Write-Host "0" -NoNewline -ForegroundColor DarkMagenta; Write-Host " to launch game"
    Write-Host "Press " -NoNewline ; Write-Host "." -NoNewline -ForegroundColor DarkMagenta; Write-Host " to shut down game"
    Write-Host "Press " -NoNewline ; Write-Host "/" -NoNewline -ForegroundColor DarkMagenta; Write-Host " to quit menu"
    Write-Host "========================================"
    Write-Host "Exit game at backup status:  " $Script:ExitGameAtBackup
    Write-Host "Exit game at restore status: " $Script:ExitGameAtRestore
    Write-Host "Game backup files to keep:   " $Script:KeepBackupFilesCount
    Write-Host "Game backup files in total:  " $Script:BackupFilesCreated
    Write-Host "Debug menu enabled:          " $Script:EnableDebugMenu
    If ($Script:EnableDebugMenu -eq $True) {DebugMenu}
}

GameVariables -GameName $GameName
CreateSaveGameFolder
CreateShortcut $Script:ShortcutTarOrg $Script:ShortcutLnkOrg
CreateShortcut $Script:ShortcutTarBak $Script:ShortcutLnkBak

If ($Script:FileCreation) {
    Write-Host -ForegroundColor Cyan "Prerequisite files created, double check their paths`n"
    Pause
}

Do {
    RunMenu
    $Selection = Read-Host "`nPlease make a selection"
    Switch ($Selection) {

    '+' {
        BackupFiles
        PruneFiles
        }
    
    '-' {
        RestoreFiles
        }

    '*' {
        Start-Process $Script:SaveGameSourceRoot
        }

    '1' {
        Start-Process $Script:ArgumentsFile
        }

    '3' {
        Write-Host -ForegroundColor Cyan "Reloading game variables"
        GameVariables
        Start-Sleep -Seconds 2
        }

    '0' {
        GameLaunch
        }
    
    '.' {
        GameProcess -Shutdown
        }

    '/' {
        Write-Host -ForegroundColor Yellow "Exiting menu..."
        Start-Sleep -Seconds 1
        Break
        }

    Default
        {
        Write-Host -ForegroundColor Red "Invalid selection, try again"
        Start-Sleep -Seconds 1
        }

    }
    If ($Script:EnableDebugMenu -eq $True) {""; Pause; ""}
    
}
Until ($Selection -eq '/')