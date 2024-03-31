Function Global:Set-MainWindowSettings{
    Function Global:Get-WsusSqlServerName{
        If (Test-Path "HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup"){
            $ServerInstancePath = (Get-Item -Path "HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup").GetValue("SqlServerName")
            If ($ServerInstancePath -eq "MICROSOFT##WID"){
                $ServerInstancePath = "\\.\pipe\Microsoft##WID\tsql\query"
            }
            Return $ServerInstancePath
        }
    }
    Function Set-ValueWsusPool($ItemName, $DisplayName, $NewValue){
        Try{
            $BeforeValue = (Get-ItemProperty $CurrentConfig.Wsus.IisWsusPoolPath -Name $ItemName).Value
            Set-ItemProperty -Path (Get-ItemProperty $CurrentConfig.Wsus.IisWsusPoolPath).PsPath -Name ($ItemName) -Value ($NewValue)
            $AfterValue = (Get-ItemProperty $CurrentConfig.Wsus.IisWsusPoolPath -Name $ItemName).Value
            Write-Verbose "$DisplayName <$ItemName>: (Before: $BeforeValue, Request: $NewValue, After: $AfterValue)"
        }
        Catch{
            Write-Warning "[Set-ValueWsusPool] Failed to apply $DisplayName <$ItemName>: (Before: $BeforeValue, Request: $NewValue)`n$($_.Exception.Message)"
        }

    }
    Function Global:Get-SqlCmdPath{
        $Path = (Get-ChildItem "$($env:ProgramFiles)\Microsoft SQL Server\Client SDK\ODBC\" -Recurse -Filter "sqlcmd.exe" -File | Sort-Object FullName -Descending | Select-Object -First 1).FullName
        If ($Path -eq $Null){
            $Path = $DefaultConfig.MaintenanceSql.SqlCmdPath
        }
        Return $Path
    }
    Function Set-SqlMinimumMemorySize($MinimumMemorySize){
        $SqlQueryPath = (Join-Path $ProgramDataDirectory "Set-SqlMinimumMemorySize.sql")
        (Get-Content (Join-Path (Get-Module Wsustainable).ModuleBase "Assets\Set-SqlMinimumMemorySize.sql.txt") -Encoding UTF8).Replace("{Value}", $MinimumMemorySize) | Out-File $SqlQueryPath -Encoding UTF8
        If ($CurrentConfig.MaintenanceSql.SqlCmdMode -eq "psmodule"){
            Try{
                Invoke-Sqlcmd -ServerInstance (Get-WsusSqlServerName) -InputFile $SqlQueryPath -Encrypt Optional
            }
            Catch{
                Write-Warning "[Set-ValueWsusPool] Failed to apply SqlMinimumMemorySize by Invoke-Sqlcmd`n$($_.Exception.Message)"
            }
        }
        Else{
            Try{
                $ExitCode = (Start-Process (Get-SqlCmdPath) -ArgumentList "-S $(Get-WsusSqlServerName) -i ""$SqlQueryPath"" -Wait -NoNewWindow -PassThru").ExitCode
                If ($ExitCode -ne -102){
                    Write-Warning "[Set-ValueWsusPool] Failed to apply SqlMinimumMemorySize by SQLCMD.exe $(Get-SqlCmdPath)`nExitcode: $ExitCode"
                }
            }
            Catch{
                Write-Warning "[Set-ValueWsusPool] Failed to apply SqlMinimumMemorySize by SQLCMD.exe $(Get-SqlCmdPath)`n$($_.Exception.Message)"
            }
        }
    }
    Write-Verbose "Checking selected configuration..."

    # Options
    
    # ChooseProducts
    If ($Global:CurrentConfig.ChooseProducts."Windows 11".Configure){
        $Global:CurrentConfig.ChooseVersions."Windows 11" = $Windows11Products | Sort-Object Version -Unique | Select-Object Version, @{Name="arm64";Expression={$_.SelectedArm64}}, @{Name="x64";Expression={$_.SelectedX64}}
    }
    If ($Global:CurrentConfig.ChooseProducts."Windows 10".Configure){
        $Global:CurrentConfig.ChooseVersions."Windows 10" = $Windows10Products | Sort-Object Version -Unique | Select-Object Version, @{Name="arm64";Expression={$_.SelectedArm64}}, @{Name="x64";Expression={$_.SelectedX64}}, @{Name="x86";Expression={$_.SelectedX86}}
    }
    If ($Global:CurrentConfig.ChooseProducts."Visual Studio".Configure){
        $Global:CurrentConfig.ChooseVersions."Visual Studio" = $VisualStudioProducts | Sort-Object Version -Unique | Select-Object Version
    }
    #$Global:CurrentConfig.ChooseProducts."Microsoft Edge".x86 = $MainWindow.FindName("SynWindowsChooseMsEdgeX86CheckBox").IsChecked
    #$Global:CurrentConfig.ChooseProducts."Microsoft Edge".x64 = $MainWindow.FindName("SynWindowsChooseMsEdgeX64CheckBox").IsChecked
    #$Global:CurrentConfig.ChooseProducts."Microsoft Edge".arm64 = $MainWindow.FindName("SynWindowsChooseMsEdgeArm64CheckBox").IsChecked

    # ApproveRule
    #$Global:CurrentConfig.ApproveRule = ($MainWindow.FindName("ApproveRuleList").DataContext | Select-Object "FeatureUpdates", "QualityUpdates", "ApproveWaitDays", "TargetGroupName", "TargetGroupNameDisplayText", "ToStringWithoutTargetGroupName")
    #$MainWindow.FindName("ApproveRuleList").DataContext | ForEach-Object{
    #    Write-Verbose "-> $($_.TargetGroupName): [QualityUpdates:$($_.QualityUpdates)], [ApproveWaitDays:$($_.ApproveWaitDays)]"
    #}

    $CurrentConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath (Join-Path $ProgramDataDirectory "Config.json") -Encoding UTF8

    # Schedule
    If ($MainWindow.FindName("EditiingScheduleTriggersExpander").IsExpanded){
        Write-Verbose "EditiingScheduleTriggersCheckBox is checked."
        $Schedule = $MainWindow.FindName("ScheduleTab").DataContext

        $DaysOfWeek = 0
        $WeeksOfMonth = 0

        # Weekly
        If ($Schedule.Sunday){$DaysOfWeek += [MSFT_ScheduledTaskDaysOfWeek]::Sunday}
        If ($Schedule.Monday){$DaysOfWeek += [MSFT_ScheduledTaskDaysOfWeek]::Monday}
        If ($Schedule.Tuesday){$DaysOfWeek += [MSFT_ScheduledTaskDaysOfWeek]::Tuesday}
        If ($Schedule.Wednesday){$DaysOfWeek += [MSFT_ScheduledTaskDaysOfWeek]::Wednesday}
        If ($Schedule.Thursday){$DaysOfWeek += [MSFT_ScheduledTaskDaysOfWeek]::Thursday}
        If ($Schedule.Friday){$DaysOfWeek += [MSFT_ScheduledTaskDaysOfWeek]::Friday}
        If ($Schedule.Saturday){$DaysOfWeek += [MSFT_ScheduledTaskDaysOfWeek]::Saturday}
   
        If ($Schedule.First -and $Schedule.Second -and $Schedule.Third -and $Schedule.Fourth -and $Schedule.Last){
            $Schedule.First = $False
            $Schedule.Second = $False
            $Schedule.Third = $False
            $Schedule.Fourth = $False
            $Schedule.Last = $False

            $Schedule.LoadedWeeksOfMonth = $False
            Write-Verbose "-> switch to weekly mode."
        }
        ElseIf ($Schedule.First -or $Schedule.Second -or $Schedule.Third -or $Schedule.Fourth -or $Schedule.Last){
            # Monthly
            If ($Schedule.First){$WeeksOfMonth += [MSFT_ScheduledTaskWeeksOfMonth]::First}
            If ($Schedule.Second){$WeeksOfMonth += [MSFT_ScheduledTaskWeeksOfMonth]::Second}
            If ($Schedule.Third){$WeeksOfMonth += [MSFT_ScheduledTaskWeeksOfMonth]::Third}
            If ($Schedule.Fourth){$WeeksOfMonth += [MSFT_ScheduledTaskWeeksOfMonth]::Fourth}
            If ($Schedule.Last){$WeeksOfMonth += [MSFT_ScheduledTaskWeeksOfMonth]::Last}

            $Schedule.LoadedWeeksOfMonth = $True
            Write-Verbose ([String]::Format("-> switch to Montyhly mode. First:{0}, Second:{1}, Third:{2}, Fourth:{3}, Last:{4}", $Schedule.First, $Schedule.Second, $Schedule.Third, $Schedule.Fourth, $Schedule.Last))
        }
        Else {
            $Schedule.LoadedWeeksOfMonth = $False
            Write-Verbose "-> switch to weekly mode."
        }

        $ScheduleService = New-Object -ComObject Schedule.Service
        $ScheduleService.Connect()

        $ScheduleTask = $ScheduleService.NewTask(0)
        $ScheduleTask.RegistrationInfo.Description = "Optimize-WsusContents"
        $ScheduleTask.RegistrationInfo.Author = "Wsustainable"
        $ScheduleTask.Settings.Enabled = $True
        #$ScheduleTask.Settings.AllowDemandStart = $True
        $ScheduleTask.Settings.WakeToRun = $True

        $ScheduleTask.Principal.UserId = "System"
        $ScheduleTask.Principal.RunLevel = 1 #TASK_RUNLEVEL_HIGHEST

        $ScheduleTaskAction = $ScheduleTask.Actions.Create(0)
        $ScheduleTaskAction.Path = "%WinDir%\system32\WindowsPowerShell\v1.0\powershell.exe"
        $ScheduleTaskAction.Arguments = ("-ExecutionPolicy ByPass -Command ""Import-Module Wsustainable; Optimize-WsusContents -Config " + "'" + "$(Join-Path $ProgramDataDirectory "Config.json")'""")

        If ($Schedule.LoadedWeeksOfMonth){
            $ScheduleTaskTrigger = $ScheduleTask.Triggers.Create([MSFT_ScheduledTaskTrigger]::MonthlyDayOfWeek)
            $ScheduleTaskTrigger.DaysOfWeek = $DaysOfWeek
            $ScheduleTaskTrigger.MonthsOfYear = 4095
            $ScheduleTaskTrigger.WeeksOfMonth = $WeeksOfMonth
        }
        ElseIf ($Schedule.Sunday -and $Schedule.Monday -and $Schedule.Tuesday -and $Schedule.Wednesday -and $Schedule.Thursday -and $Schedule.Friday -and $Schedule.Saturday){
            $ScheduleTaskTrigger = $ScheduleTask.Triggers.Create([MSFT_ScheduledTaskTrigger]::Daily)
        }
        ElseIf ($Schedule.Sunday -or $Schedule.Monday -or $Schedule.Tuesday -or $Schedule.Wednesday -or $Schedule.Thursday -or $Schedule.Friday -or $Schedule.Saturday){
            $ScheduleTaskTrigger = $ScheduleTask.Triggers.Create([MSFT_ScheduledTaskTrigger]::Weekly)
            $ScheduleTaskTrigger.DaysOfWeek = $DaysOfWeek
        }
        Else{
            $ScheduleTaskTrigger = $ScheduleTask.Triggers.Create([MSFT_ScheduledTaskTrigger]::Daily)
        }
        
        $ScheduleTaskTrigger.StartBoundary = (Get-Date $MainWindow.FindName("WeeklyScheduleDateTimePicker").Value -Format s)
        Write-Verbose "-> Time: $($ScheduleTaskTrigger.StartBoundary)"
        #$ScheduleTaskTrigger.Enabled = $True

        $ScheduleService.GetFolder("\").RegisterTaskDefinition($CurrentConfig.ScheduledTask.Name, $ScheduleTask, [MSFT_TaskCreation]::CreateOrUpdate,"","",[MSFT_TaskLogonType]::LogonServiceAccount)

        If ($MainWindow.FindName("FistLaunchCheckBox").IsChecked){
            Start-ScheduledTask -TaskName $CurrentConfig.ScheduledTask.Name
        }
    }

    Set-SqlMinimumMemorySize -MinimumMemorySize $MainWindow.FindName("SqlMinimumMemoryTextBox").Value

    # Quata
    If ($MainWindow.FindName("ConfigureFileQuotaExpander").IsExpanded){
        $WsusContentDirectory = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup").ContentDir
        If (@(Get-FsrmQuota | Where-Object Path -like $WsusContentDirectory)[0] -eq $Null){
            New-FsrmQuota -Path $WsusContentDirectory -Size ([System.UInt64]($MainWindow.FindName("QuotaSizeTextBox").Value * 1073741824))
        }
        Else{
            Set-FsrmQuota -Path $WsusContentDirectory -Size ([System.UInt64]($MainWindow.FindName("QuotaSizeTextBox").Value * 1073741824))
        }
    }

    # IIS
    If (Test-IisWsusPoolPath){
        Write-Verbose "IIS Wsus pool:"
        Set-ValueWsusPool -ItemName "queueLength" -DisplayName $MainWindow.FindName("WsusQueueLengthLabel").Tag -NewValue ([System.Int64]$MainWindow.FindName("WsusQueueLengthTextBox").Value)
        Set-ValueWsusPool -ItemName "cpu.limit" -DisplayName $MainWindow.FindName("WsusCpuLimitLabel").Tag -NewValue ([System.Int64]$MainWindow.FindName("WsusCpuLimitTextBox").Value)
        Set-ValueWsusPool -ItemName "failure.rapidFailProtectionInterval" -DisplayName $MainWindow.FindName("WsusRapidFailProtectionIntervalLabel").Tag -NewValue (New-TimeSpan -Minutes $MainWindow.FindName("WsusRapidFailProtectionIntervalTextBox").Value).ToString()
        Set-ValueWsusPool -ItemName "failure.rapidFailProtectionMaxCrashes" -DisplayName $MainWindow.FindName("WsusRapidFailProtectionMaxCrashesLabel").Tag -NewValue ([System.Int64]$MainWindow.FindName("WsusRapidFailProtectionMaxCrashesTextBox").Value)
        Set-ValueWsusPool -ItemName "recycling.periodicRestart.privateMemory" -DisplayName $MainWindow.FindName("WsusPeriodicRestartPrivateMemoryLabel").Tag -NewValue ([System.Int64]$MainWindow.FindName("WsusPeriodicRestartPrivateMemoryTextBox").Value)
        Set-ValueWsusPool -ItemName "recycling.periodicRestart.memory" -DisplayName $MainWindow.FindName("WsusPeriodicRestartMemoryLabel").Tag -NewValue ([System.Int64]$MainWindow.FindName("WsusPeriodicRestartMemoryTextBox").Value)
    }


}
