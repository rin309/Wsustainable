Function Global:Test-ServerAllFunctions{
    $TestResult = @()
    $TestResult += (Test-WsusServer)
    $TestResult += (Test-IisWsusPoolPath)
    $TestResult += (Test-SqlServerInstancePath)
    Test-FileServerResourceManager
    If ($False -notin $TestResult){
        $MainWindow.Dispatcher.Invoke({
            Write-Verbose "All services connection successfully established"
            $MainWindow.FindName("AllConnectionSuccessfully").Visibility = [System.Windows.Visibility]::Visible
        })
    }
}

Function Global:Test-WsusServer{
    Try{
        Import-Module UpdateServices -ErrorAction Stop
    }
    Catch{
        $MainWindow.Dispatcher.Invoke({
            Write-Warning "Not found [UpdateServices] module: $($_.Exception.Message)"
            $MainWindow.FindName("WsusServerTextBox").Focus()
            $MainWindow.FindName("WsusServerConnectionFailure").Visibility = [System.Windows.Visibility]::Visible
        })
        Return $False
    }
    
    Try{
        Get-WsusServer -Name $CurrentConfig.Wsus.Server -PortNumber $CurrentConfig.Wsus.Port | Out-Null
        Write-Verbose "WSUS Server connected to $($CurrentConfig.Wsus.Server):$($CurrentConfig.Wsus.Port) successfully established"
        $MainWindow.Dispatcher.Invoke({
            $MainWindow.FindName("WsusServerConnectionFailure").Visibility = [System.Windows.Visibility]::Collapsed
        })
        Return $True
    }
    Catch{
        $MainWindow.Dispatcher.Invoke({
            Write-Warning "WSUS Server connected to $($CurrentConfig.Wsus.Server):$($CurrentConfig.Wsus.Port) failed: $($_.Exception.Message)"
            $MainWindow.FindName("WsusServerTextBox").Focus()
            $MainWindow.FindName("WsusServerConnectionFailure").Visibility = [System.Windows.Visibility]::Visible
        })
        Return $False
    }
}

Function Global:Test-FileServerResourceManager{
    Function Global:Convert-DisplayByteSize{
        Param ([Parameter(Mandatory,ValueFromPipeline)][Uint64]$ByteSize)
        $Buffer = New-Object Text.StringBuilder 100
        $ShlwapiStrFormatByteSize::StrFormatByteSize($ByteSize, $Buffer, $Buffer.Capacity) | Out-Null
        $Buffer.ToString()
    }
    Try{
        Import-Module FileServerResourceManager -ErrorAction Stop
    }
    Catch{
        $MainWindow.Dispatcher.Invoke({
            Write-Warning "Not found [FileServerResourceManager] module: $($_.Exception.Message)"
        })
        Return $False
    }
    Try{
        Import-Module Storage -ErrorAction Stop
    }
    Catch{
        $MainWindow.Dispatcher.Invoke({
            Write-Warning "Not found [Storage] module: $($_.Exception.Message)"
        })
        Return $False
    }
    
    Try{
        $WsusContentDirectory = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup").ContentDir
        If ($WsusContentDirectory -ne $Null){
            If (Test-Path $WsusContentDirectory){
                $MainWindow.Dispatcher.Invoke({
                    $MainWindow.FindName("FileQuotaContainer").Visibility = [System.Windows.Visibility]::Visible

                    $Script:ShlwapiStrFormatByteSize = Add-Type -PassThru -Name "ShlwapiStrFormatByteSize" -MemberDefinition "[DllImport(""Shlwapi.dll"", CharSet = CharSet.Auto)]
                    public static extern long StrFormatByteSize(long fileSize, System.Text.StringBuilder buffer, int bufferSize);"

                    $MainWindow.FindName("WsusContentFolderInformationListBoxItem").DataContext = ([String]::Format("現在 {0}", ((Get-ChildItem $WsusContentDirectory -Recurse | Measure-Object -Property Length -Sum).Sum | Convert-DisplayByteSize)))
                    $VolumeInformation = Get-Volume -FilePath $WsusContentDirectory
                    $MainWindow.FindName("WsusContentDriveInformationListBoxItem").DataContext = ([String]::Format("空き領域 {0} / {1}", ($VolumeInformation.SizeRemaining | Convert-DisplayByteSize), ($VolumeInformation.Size | Convert-DisplayByteSize)))

                    $MainWindow.FindName("QuotaSizeTextBox").Maximum = [int]($VolumeInformation.Size / 1073741824)
                    $MainWindow.FindName("QuotaSizeTextBox").Value = [int]($VolumeInformation.Size / 10737418240)
                    If (@(Get-FsrmQuota | Where-Object Path -like $WsusContentDirectory)[0] -ne $Null){
                        $MainWindow.FindName("ConfigureFileQuotaExpander").IsExpanded = $True
                        $MainWindow.FindName("QuotaSizeTextBox").Value = [int](@(Get-FsrmQuota -Path $WsusContentDirectory)[0].Size / 1073741824)
                    }
                })
            }
        }
        Write-Verbose "Initialize FileServerResourceManager and Storage module successfully established"
    }
    Catch{
        $MainWindow.Dispatcher.Invoke({
            Write-Warning "FileServerResourceManager failed: $($_.Exception.Message)"
        })
        Return $False
    }
}

Function Global:Test-IisWsusPoolPath{
    Try{
        Import-Module WebAdministration -ErrorAction Stop
    }
    Catch{
        $MainWindow.Dispatcher.Invoke({
            Write-Warning "Not found [WebAdministration] module: $($_.Exception.Message)"
            $MainWindow.FindName("IisConnectionFailure").Visibility = [System.Windows.Visibility]::Visible
            $MainWindow.FindName("WsusPoolApplicationContainer").Visibility = [System.Windows.Visibility]::Collapsed
        })
        Return $False
    }
    
    If (-not (Test-Path $CurrentConfig.Wsus.IisWsusPoolPath)){
        $MainWindow.Dispatcher.Invoke({
            Write-Warning "CurrentConfig.Wsus.IisWsusPoolPath ($($CurrentConfig.Wsus.IisWsusPoolPath)) が見つかりませんでした"
            $MainWindow.FindName("IisConnectionFailure").Visibility = [System.Windows.Visibility]::Visible
            $MainWindow.FindName("WsusPoolApplicationContainer").Visibility = [System.Windows.Visibility]::Collapsed
        })
        Return $False
    }
    Else{
        $MainWindow.Dispatcher.Invoke({
            $MainWindow.FindName("WsusPoolApplicationContainer").Visibility = [System.Windows.Visibility]::Visible

            $MainWindow.FindName("WsusQueueLengthLabel").DataContext = "現在: $(((Get-ItemProperty $CurrentConfig.Wsus.IisWsusPoolPath -Name "queueLength").Value).Tostring("#,#"))"
            $MainWindow.FindName("WsusCpuLimitLabel").DataContext = "現在: $((Get-ItemProperty $CurrentConfig.Wsus.IisWsusPoolPath -Name "cpu.limit").Value) %"
            $MainWindow.FindName("WsusRapidFailProtectionIntervalLabel").DataContext = "現在: $([TimeSpan]::Parse((Get-ItemProperty $CurrentConfig.Wsus.IisWsusPoolPath -Name "failure.rapidFailProtectionInterval").Value).TotalMinutes) 分"
            $MainWindow.FindName("WsusRapidFailProtectionMaxCrashesLabel").DataContext = "現在: $(((Get-ItemProperty $CurrentConfig.Wsus.IisWsusPoolPath -Name "failure.rapidFailProtectionMaxCrashes").Value).Tostring("#,#"))"
            $MainWindow.FindName("WsusPeriodicRestartPrivateMemoryLabel").DataContext = "現在: $(((Get-ItemProperty $CurrentConfig.Wsus.IisWsusPoolPath -Name "recycling.periodicRestart.privateMemory").Value).Tostring("#,#")) KB"
            $MainWindow.FindName("WsusPeriodicRestartMemoryLabel").DataContext = "現在: $(((Get-ItemProperty $CurrentConfig.Wsus.IisWsusPoolPath -Name "recycling.periodicRestart.memory").Value).Tostring("#,#")) KB"
        })
        Return $True
    }
}

Function Global:Get-WsusSqlServerName{
    If (Test-Path "HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup"){
        $ServerInstancePath = (Get-Item -Path "HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup").GetValue("SqlServerName")
        If ($ServerInstancePath -eq "MICROSOFT##WID"){
            $ServerInstancePath = "\\.\pipe\Microsoft##WID\tsql\query"
        }
        Return $ServerInstancePath
    }
}
Function Global:Get-SqlCmdPath{
    $Path = (Get-ChildItem "$($env:ProgramFiles)\Microsoft SQL Server\Client SDK\ODBC\" -Recurse -Filter "sqlcmd.exe" -File | Sort-Object FullName -Descending | Select-Object -First 1).FullName
    If ($Path -eq $Null){
        $Path = $DefaultConfig.MaintenanceSql.SqlCmdPath
    }
    Return $Path
}

Function Global:Test-SqlServerInstancePath{
    $SuccessfullyConnectedToSql = $False
    $WsusSqlServerName = Get-WsusSqlServerName
    
    $MainWindow.Dispatcher.Invoke({
        $MainWindow.FindName("ServerInstancePathTextBox").DataContext = $WsusSqlServerName
    })

    If ($CurrentConfig.MaintenanceSql.SqlCmdMode -eq "psmodule"){
        Try{
            Write-Verbose "[Invoke-Sqlcmd] SELECT @@VERSION: $((Invoke-Sqlcmd -ServerInstance $WsusSqlServerName -Query 'SELECT @@VERSION' -Encrypt Optional).Column1)"
            $SuccessfullyConnectedToSql = $True
        }
        Catch{}
    }
    Else{
        Try{
            If ((Start-Process (Get-SqlCmdPath) -ArgumentList "-S $WsusSqlServerName -q ""exit(SELECT @@VERSION)""" -Wait -NoNewWindow -PassThru).ExitCode -eq -102){
                $SuccessfullyConnectedToSql = $True
            }
        }
        Catch{
            $MainWindow.Dispatcher.Invoke({
                Write-Warning "Get-SqlCmdPath ($(Get-SqlCmdPath)) が見つかりませんでした。SQLCMD ($(Get-SqlCmdPath)) が実行できるか確認してください: $($_.Exception.Message)"
                $MainWindow.FindName("SqlConnectionFailure").Visibility = [System.Windows.Visibility]::Visible
                $MainWindow.FindName("SqlContainer").Visibility = [System.Windows.Visibility]::Collapsed
                $MainWindow.FindName("ScheduleSqlContainer").Visibility = [System.Windows.Visibility]::Collapsed
            })
            Return $False
        }
    }
 
    If(-not $SuccessfullyConnectedToSql){
        $MainWindow.Dispatcher.Invoke({
            Write-Warning "データベース ($WsusSqlServerName) が見つかりませんでした"
            $MainWindow.FindName("SqlConnectionFailure").Visibility = [System.Windows.Visibility]::Visible
            $MainWindow.FindName("SqlContainer").Visibility = [System.Windows.Visibility]::Collapsed
            $MainWindow.FindName("ScheduleSqlContainer").Visibility = [System.Windows.Visibility]::Collapsed
        })
        Return $False
    }
    $MainWindow.Dispatcher.Invoke({
        $MainWindow.FindName("SqlContainer").Visibility = [System.Windows.Visibility]::Visible
        $MainWindow.FindName("ScheduleSqlContainer").Visibility = [System.Windows.Visibility]::Visible
        #$MainWindow.FindName("SqlMinimumMemoryLabel").DataContext = "現在: $((Invoke-Sqlcmd -ServerInstance (Get-WsusSqlServerName) -InputFile (Join-Path (Get-Module Wsustainable).ModuleBase "Assets\Get-SqlMinimumMemorySize.sql") -Encrypt Optional).run_value) MB"
        $MainWindow.FindName("SqlMinimumMemoryLabel").DataContext = "現在: $((Invoke-Sqlcmd -ServerInstance (Get-WsusSqlServerName) -InputFile (Join-Path $PSScriptRoot "..\Assets\Get-SqlMinimumMemorySize.sql") -Encrypt Optional).run_value) MB"
    })
    Write-Verbose "データベース ($WsusSqlServerName) へ接続できました"
    Return $True
}
