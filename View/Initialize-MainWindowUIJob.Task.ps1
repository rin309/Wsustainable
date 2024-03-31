Function Global:Initialize-MainWindowUIJob{
    Class StatusItem{
        $Status
        $IsCompleted
    }

    $Global:StatusList = @()
    If (!$CurrentConfig.WizardView.DetectiveInstalledComponents -or !$CurrentConfig.WizardView.ShowOptionTab){
    }
    Else{
        $Global:ComponentsListViewUIStatus = New-Object StatusItem
        $Global:ComponentsListViewUIStatus.Status = "インストール済みコンポーネント"
        $Global:StatusList += $ComponentsListViewUIStatus
        $MainWindow.Dispatcher.Invoke({$MainWindow.FindName("StatusList").DataContext = $StatusList})
        Initialize-ComponentsListViewUI
    }
    
    $Global:TaskListListViewUIStatus = New-Object StatusItem
    $Global:TaskListListViewUIStatus.Status = "タスク"
    $Global:StatusList += $TaskListListViewUIStatus
    $MainWindow.Dispatcher.Invoke({$MainWindow.FindName("StatusList").DataContext = $StatusList})
    Initialize-ScheduleTaskUI

    $MainWindow.Dispatcher.Invoke({
        $MainWindow.FindName("IndicatorRoot").Visibility = [System.Windows.Visibility]::Collapsed
    })
}

Function Global:Initialize-ComponentsListViewUI{
    
    Get-InstalledComponents

    $MainWindow.Dispatcher.Invoke({
        $MainWindow.FindName("ComponentsListView").DataContext = $ComponentsList
        If (@($ComponentsList).Count -gt 0){
            $MainWindow.FindName("ComponentsListContainer").Visibility = [System.Windows.Visibility]::Visible
            If ($CurrentConfig.MaintenanceSql.SqlCmdExeMode -eq "exe"){
                #$MainWindow.FindName("SqlCmdContainer").Visibility = [System.Windows.Visibility]::Visible
            }
        }
    })
}

Function Global:Initialize-WsusProductUI{
    (Get-WsusProduct -TitleIncludes "Microsoft" | Where-Object {$_.Product.Id -eq "56309036-4c77-4dd9-951a-99ee9c246a94"}).Product.GetSubcategories() | Where-Object Type -eq ProductFamily
    (Get-WsusProduct -TitleIncludes "Windows" | Where-Object {$_.Product.Id -eq "6964aab4-c5b5-43bd-a17d-ffb4346a8e1d"}).Product.GetSubcategories()
    (Get-WsusProduct -TitleIncludes "Office" | Where-Object {$_.Product.Id -eq "477b856e-65c4-4473-b621-a8b230bb70d9"}).Product.GetSubcategories()
}

Function Global:Initialize-ScheduleTaskUI{
    Try{
        $Item = New-Object SchedukeTaskTriggerItem

        #Write-Verbose "タスク $($CurrentConfig.ScheduledTask.Name) の調査中..."

        $ScheduleService = New-Object -ComObject Schedule.Service
        $ScheduleService.Connect()
        $ScheduleTask = $ScheduleService.GetFolder("\").GetTasks(0) | Where-Object Name -Like "$($CurrentConfig.ScheduledTask.Name)*"
        If ($ScheduleTask -ne $null){
            Write-Verbose "Found task: $($CurrentConfig.ScheduledTask.Name)"
            If ($ScheduleTask.Definition.Triggers.Count -eq 0){
                Write-Verbose "-> Not found trigger in $($CurrentConfig.ScheduledTask.Name)"
            }
            Else{
                If ($ScheduleTask.Definition.Triggers.Count -ne 1){
                    Write-Verbose "-> Found multiple triggers. Loaded first trigger only."
                }
                #$ScheduleTask.Definition.Triggers | ForEach-Object {
                Try{
                    $ScheduledTaskTrigger = $ScheduleTask.Definition.Triggers[1]
                    Write-Verbose "-> Trigger type: $(([MSFT_ScheduledTaskTrigger]$ScheduledTaskTrigger.Type).ToString())"

                    Switch([MSFT_ScheduledTaskTrigger]$ScheduledTaskTrigger.Type){
                        ([MSFT_ScheduledTaskTrigger]::Daily) {
                            Write-Verbose "-> [Daily]"

                            $Item.Sunday = $True
                            $Item.Monday = $True
                            $Item.Tuesday = $True
                            $Item.Wednesday = $True
                            $Item.Thursday = $True
                            $Item.Friday = $True
                            $Item.Saturday = $True

                            $Item.StartBoundary = $ScheduledTaskTrigger.StartBoundary

                            $Item.LoadedDaysOfWeek = $True
                        }
                        ([MSFT_ScheduledTaskTrigger]::Weekly) {
                            $ScheduleTaskDaysOfWeek = ([MSFT_ScheduledTaskDaysOfWeek]$ScheduledTaskTrigger.DaysOfWeek)

                            $Item.Sunday = $ScheduleTaskDaysOfWeek.HasFlag([MSFT_ScheduledTaskDaysOfWeek]::Sunday)
                            $Item.Monday = $ScheduleTaskDaysOfWeek.HasFlag([MSFT_ScheduledTaskDaysOfWeek]::Monday)
                            $Item.Tuesday = $ScheduleTaskDaysOfWeek.HasFlag([MSFT_ScheduledTaskDaysOfWeek]::Tuesday)
                            $Item.Wednesday = $ScheduleTaskDaysOfWeek.HasFlag([MSFT_ScheduledTaskDaysOfWeek]::Wednesday)
                            $Item.Thursday = $ScheduleTaskDaysOfWeek.HasFlag([MSFT_ScheduledTaskDaysOfWeek]::Thursday)
                            $Item.Friday = $ScheduleTaskDaysOfWeek.HasFlag([MSFT_ScheduledTaskDaysOfWeek]::Friday)
                            $Item.Saturday = $ScheduleTaskDaysOfWeek.HasFlag([MSFT_ScheduledTaskDaysOfWeek]::Saturday)

                            $Item.StartBoundary = $ScheduledTaskTrigger.StartBoundary

                            $Item.LoadedDaysOfWeek = $True
                        }
                        ([MSFT_ScheduledTaskTrigger]::MonthlyDayOfWeek) {
                            $ScheduleTaskWeeksOfMonth = ([MSFT_ScheduledTaskWeeksOfMonth]$ScheduledTaskTrigger.WeeksOfMonth)

                            $Item.First = $ScheduleTaskWeeksOfMonth.HasFlag([MSFT_ScheduledTaskWeeksOfMonth]::First)
                            $Item.Second = $ScheduleTaskWeeksOfMonth.HasFlag([MSFT_ScheduledTaskWeeksOfMonth]::Second)
                            $Item.Third = $ScheduleTaskWeeksOfMonth.HasFlag([MSFT_ScheduledTaskWeeksOfMonth]::Third)
                            $Item.Fourth = $ScheduleTaskWeeksOfMonth.HasFlag([MSFT_ScheduledTaskWeeksOfMonth]::Fourth)
                            $Item.Last = $ScheduledTaskTrigger.RunOnLastWeekOfMonth
                            

                            $ScheduleTaskDaysOfWeek = ([MSFT_ScheduledTaskDaysOfWeek]$ScheduledTaskTrigger.DaysOfWeek)

                            $Item.Sunday = $ScheduleTaskDaysOfWeek.HasFlag([MSFT_ScheduledTaskDaysOfWeek]::Sunday)
                            $Item.Monday = $ScheduleTaskDaysOfWeek.HasFlag([MSFT_ScheduledTaskDaysOfWeek]::Monday)
                            $Item.Tuesday = $ScheduleTaskDaysOfWeek.HasFlag([MSFT_ScheduledTaskDaysOfWeek]::Tuesday)
                            $Item.Wednesday = $ScheduleTaskDaysOfWeek.HasFlag([MSFT_ScheduledTaskDaysOfWeek]::Wednesday)
                            $Item.Thursday = $ScheduleTaskDaysOfWeek.HasFlag([MSFT_ScheduledTaskDaysOfWeek]::Thursday)
                            $Item.Friday = $ScheduleTaskDaysOfWeek.HasFlag([MSFT_ScheduledTaskDaysOfWeek]::Friday)
                            $Item.Saturday = $ScheduleTaskDaysOfWeek.HasFlag([MSFT_ScheduledTaskDaysOfWeek]::Saturday)

                            $Item.StartBoundary = $ScheduledTaskTrigger.StartBoundary

                            $Item.LoadedDaysOfWeek = $True
                            $Item.LoadedWeeksOfMonth = $True
                        }
                        Default{
                            Write-Warning "-> Not supported trigger type: $(([MSFT_ScheduledTaskTrigger]$ScheduledTaskTrigger.Type).ToString()) "
                        }
                    }
                }
                Catch{
                    Write-Error "Loading task trigger error: $($_.Exception.Message)"
                }
                #}


            }
        }
        Else{
            Write-Verbose "Not found task: $($CurrentConfig.ScheduledTask.Name)"
        }

        Try{
            If ($ScheduledTaskTrigger.DaysOfWeek -ne $Null){
                Write-Verbose "-> $(([MSFT_ScheduledTaskDaysOfWeek]$ScheduledTaskTrigger.DaysOfWeek).ToString())"
            }
            If ($ScheduledTaskTrigger.WeeksOfMonth -ne $Null){
                Write-Verbose "-> $(([MSFT_ScheduledTaskWeeksOfMonth]$ScheduledTaskTrigger.WeeksOfMonth).ToString())"
            }
            Write-Verbose "-> StartBoundary: $($Item.StartBoundary), LoadedDaysOfWeek: $($Item.LoadedDaysOfWeek), LoadedWeeksOfMonth: $($Item.LoadedWeeksOfMonth)"
        }
        Catch{
            Write-Verbose "Loading task trigger error: $($CurrentConfig.ScheduledTask.Name)"
        }

        $MainWindow.Dispatcher.Invoke({
            $MainWindow.FindName("ScheduleTab").DataContext = $Item
            $MainWindow.FindName("EditiingScheduleTriggersExpander").DataContext = $Item
            $MainWindow.FindName("EditiingScheduleTriggersExpander").IsExpanded = $True
            #$MainWindow.FindName("MonthlyScheduleCheckBox").DataContext = $Item

            $MainWindow.FindName("WeeklyScheduleSundayCheckBox").DataContext = $Item
            $MainWindow.FindName("WeeklyScheduleMondayCheckBox").DataContext = $Item
            $MainWindow.FindName("WeeklyScheduleTuesdayCheckBox").DataContext = $Item
            $MainWindow.FindName("WeeklyScheduleWednesdayCheckBox").DataContext = $Item
            $MainWindow.FindName("WeeklyScheduleThursdayCheckBox").DataContext = $Item
            $MainWindow.FindName("WeeklyScheduleFridayCheckBox").DataContext = $Item
            $MainWindow.FindName("WeeklyScheduleSaturdayCheckBox").DataContext = $Item
            
            $MainWindow.FindName("MonthlyScheduleFirstCheckBox").DataContext = $Item
            $MainWindow.FindName("MonthlyScheduleSecondCheckBox").DataContext = $Item
            $MainWindow.FindName("MonthlyScheduleThirdCheckBox").DataContext = $Item
            $MainWindow.FindName("MonthlyScheduleFourthCheckBox").DataContext = $Item
            $MainWindow.FindName("MonthlyScheduleLastCheckBox").DataContext = $Item

            $MainWindow.FindName("WeeklyScheduleDateTimePicker").Value = $Item.StartBoundary
            
            
        })
        #Write-Verbose "タスク $($CurrentConfig.ScheduledTask.Name) の調査が終わりました"
    }
    Catch{
        Write-Error "Loading task error: $($_.Exception.Message)"
    }
}

Function Global:Get-InstalledComponents{
    Write-Verbose "`n`nChecking installed components..."
    $UninstallRootKeyPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"
    $UninstallWOW6432NodeRootKeyPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\"
    $MsiexecPath = "$env:SystemRoot\System32\msiexec.exe"
    $OptionComponents = Get-Content (Join-Path $PSScriptRoot "..\Assets\OptionComponents.json") -Encoding UTF8 | ConvertFrom-Json

    $Win32Products = Get-WmiObject Win32_Product
    #$Global:ComponentsListViewUIStatus.Status = "確認しました"

    Write-Verbose "Installed components:`n"

    $Global:ComponentsList = @()

    If ([Win32OperatingSystemProductType](Get-WmiObject Win32_OperatingSystem).ProductType -eq [Win32OperatingSystemProductType]::WorkStation){
        $OptionComponentsList = $OptionComponents.Components | Where-Object TargetOperatingSystemProductType -ne "Server"
    }
    ElseIf ([Win32OperatingSystemProductType](Get-WmiObject Win32_OperatingSystem).ProductType -ne [Win32OperatingSystemProductType]::WorkStation){
        $OptionComponentsList = $OptionComponents.Components | Where-Object TargetOperatingSystemProductType -ne "Client"
    }

    $OptionComponentsList  | ForEach-Object {
        $Item = New-Object OptionComponentsItem
        $Item.DisplayName = $_.DisplayName
        $Item.Reason = $_.Reason
        $Item.FileName = $_.FileName
        $Item.AcceptEula = $_.AcceptEula
        $Item.DownloadUrl = $_.DownloadUrl
        $Item.DetailsUrl = $_.DetailsUrl
        $Item.SilentInstall = $_.SilentInstall
        $Item.PsModuleName = $_.PsModuleName
        $Item.WindowsFeatureName = $_.WindowsFeatureName
        $Item.WindowsCapabilityName = $_.WindowsCapabilityName
        $Item.TargetOperatingSystemProductType = $_.TargetOperatingSystemProductType
        $Item.RequiredConnectedToInternet = $_.RequiredConnectedToInternet
        $Item.Installed = $False
        $Item.IsSelected = $False
        $Item.IsEnabled = $True
        $Item.Status = "未インストール"

        If (-not [String]::IsNullOrEmpty($Item.WindowsFeatureName)){
            Try{
                $Item.Installed = (Get-WindowsFeature $Item.WindowsFeatureName).Installed
                If ($Item.Installed){
                    $Item.Installed = $True
                    $Item.IsSelected = $True
                    $Item.IsEnabled = $False
                    $Item.Status = "インストール済み"
                    Write-Verbose "インストール済み: $($Item.DisplayName) [WindowsFeature]"
                }
                Else{
                    Write-Verbose "未インストール: $($Item.DisplayName) [WindowsFeature]"
                }
            }
            Catch{
                $Item.Installed = $False
                $Item.IsSelected = $False
                $Item.IsEnabled = $False
                $Item.Status = "インストール不可: $($_.Exception.Message)"
                Write-Verbose "インストール不可: $($Item.DisplayName) ($($_.Exception.Message))"
            }
        }
        ElseIf (-not [String]::IsNullOrEmpty($Item.WindowsCapabilityName)){
            Try{
                $Item.Installed = (Get-WindowsCapability -Online -Name $Item.WindowsCapabilityName).State -ne "NotPresent"
                If ($Item.Installed){
                    $Item.Installed = $True
                    $Item.IsSelected = $True
                    $Item.IsEnabled = $False
                    $Item.Status = "インストール済み"
                    Write-Verbose "インストール済み: $($Item.DisplayName) [WindowsCapability]"
                }
                Else{
                    Write-Verbose "未インストール: $($Item.DisplayName) [WindowsCapability]"
                }
            }
            Catch{
                $Item.Installed = $False
                $Item.IsSelected = $False
                $Item.IsEnabled = $False
                $Item.Status = "インストール不可: $($_.Exception.Message)"
                Write-Verbose "インストール不可: $($Item.DisplayName) ($($_.Exception.Message))"
            }
        }
        ElseIf (-not [String]::IsNullOrEmpty($Item.PsModuleName)){
            Try{
                $Item.Installed = @(Get-Module -Name $Item.PsModuleName -ListAvailable).Count -ne 0
                If ($Item.Installed){
                    $Item.Installed = $True
                    $Item.IsSelected = $True
                    $Item.IsEnabled = $False
                    $Item.Status = "インストール済み"
                    Write-Verbose "インストール済み: $($Item.DisplayName) [PsModule]"
                }
                Else{
                    Write-Verbose "未インストール: $($Item.DisplayName) [PsModule]"
                }
            }
            Catch{
                $Item.Installed = $False
                $Item.IsSelected = $False
                $Item.IsEnabled = $False
                $Item.Status = "インストール不可: $($_.Exception.Message)"
                Write-Verbose "インストール不可: $($Item.DisplayName) ($($_.Exception.Message))"
            }
        }
        Else{
            :GetOptionComponents
            ForEach($CheckCurrentVersionItem in $_.CheckCurrentVersion){
                $IdentifyingNumber = $CheckCurrentVersionItem.IdentifyingNumber
                $DisplayVersionText = $CheckCurrentVersionItem.DisplayVersion
                $DisplayName = $CheckCurrentVersionItem.DisplayName
                $KeyIsWOW6432Node = $CheckCurrentVersionItem.KeyIsWOW6432Node

                $UninstallKeyPath = ($UninstallRootKeyPath + $IdentifyingNumber)
                If ($KeyIsWOW6432Node){
                    $UninstallKeyPath = ($UninstallWOW6432NodeRootKeyPath + $IdentifyingNumber)
                }
                If (Test-Path -Path $UninstallKeyPath){
                    $Item.Installed = $True
                    $Item.IsSelected = $True
                    $Item.IsEnabled = $False
                    $Item.Status = "インストール済み: $DisplayName ($DisplayVersionText)"
                    Write-Verbose "`Installed: $DisplayName ($DisplayVersionText)"
                    Break GetOptionComponents
                }
                Else{
                    #IdentifyingNumber is not found
                    Write-Verbose "`n未インストール: $DisplayName"
                    $Win32ProductsName = $CheckCurrentVersionItem.Win32ProductsName
                    If ($Win32ProductsName -eq $null){
                        $Win32ProductsName = $CheckCurrentVersionItem.DisplayName
                    }
                    $NearProducts = $Win32Products | Where-Object Name -Like "$($Win32ProductsName)*"
                    If ($NearProducts -ne $null){
                        $InstalledNameText = $NearProducts.Name
                        $InstalledVersionText = $NearProducts.Version
                        $Item.Installed = $True
                        $Item.IsSelected = $True
                        $Item.IsEnabled = $False
                        $Item.Status = "インストール済み: $InstalledNameText ($InstalledVersionText)"
                        Write-Verbose "-> Installed similar products: $InstalledNameText ($InstalledVersionText)"
                        Break GetOptionComponents
                    }
                    Else{
                        Write-Verbose "-> Not found similar products: $($Win32ProductsName)"
                    }
                }
            }
        }

        $Global:ComponentsList += $Item
    }
    Write-Verbose "`n`nComplete installed components"
}
