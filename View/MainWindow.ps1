# 使用する変数を増やしたら、1-XamlLoader.ps1内のRequest-Jobをメンテナンスし忘れない
Function Global:Initialize-MainWindowUI{
    If (!([String]::IsNullOrEmpty($CurrentConfig.Config.AdminName))){
        If (!$CurrentConfig.WizardView.ShowOptionTab){$MainWindow.Dispatcher.Invoke({$MainWindow.FindName("OptionTab").Visibility = [System.Windows.Visibility]::Collapsed})}
        If (!$CurrentConfig.WizardView.ShowServerTab){$MainWindow.Dispatcher.Invoke({$MainWindow.FindName("ServerTab").Visibility = [System.Windows.Visibility]::Collapsed})}
        If (!$CurrentConfig.WizardView.ShowSyncWindowsProductsTab){$MainWindow.Dispatcher.Invoke({$MainWindow.FindName("SyncWindowsProductsTab").Visibility = [System.Windows.Visibility]::Collapsed})}
        If (!$CurrentConfig.WizardView.ShowDeclineRuleTab){$MainWindow.Dispatcher.Invoke({$MainWindow.FindName("DeclineRuleTab").Visibility = [System.Windows.Visibility]::Collapsed})}
        If (!$CurrentConfig.WizardView.ShowApproveRuleOptionsTab){$MainWindow.Dispatcher.Invoke({$MainWindow.FindName("ApproveRuleOptionsTab").Visibility = [System.Windows.Visibility]::Collapsed})}
        If (!$CurrentConfig.WizardView.ShowScheduleTab){$MainWindow.Dispatcher.Invoke({$MainWindow.FindName("ScheduleTab").Visibility = [System.Windows.Visibility]::Collapsed})}
        If (!$CurrentConfig.WizardView.ShowAboutTab){$MainWindow.Dispatcher.Invoke({$MainWindow.FindName("AboutTab").Visibility = [System.Windows.Visibility]::Collapsed})}
    }

    $Global:StatusList = @()
    If (!$CurrentConfig.WizardView.DetectiveInstalledComponents -or !$CurrentConfig.WizardView.ShowOptionTab){
        $MainWindow.FindName("ComponentsListContainer").Visibility = [System.Windows.Visibility]::Collapsed
    }

    $MainWindow.FindName("MainTabControl").Add_SizeChanged({
        $MainWindow.FindName("MainTabControl").OverridesDefaultStyle = $MainWindow.FindName("MainTabControl").ActualWidth -le 800
    })

    $MainWindow.FindName("MainTabControl").Add_SelectionChanged({
        Set-MaintabControlNavigationButtons
    })

    $MainWindow.FindName("NavigationBarInstallButton").Add_Click({
        Function Invoke-NavigationBarInstallButtonClick(){
            $INetworkListManager = [Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]"{DCB00C01-570F-4A9B-8D69-199FDBA5723B}"))
            If (-not @($INetworkListManager.GetNetworkConnections())[0].IsConnectedToInternet -and @($MainWindow.FindName("ComponentsListView").DataContext | Where-Object {-not $_.Installed -and $_.IsSelected -and $_.RequiredConnectedToInternet}).Count -eq 0){
                Write-Warning "not connected to internet"
                If ([System.Windows.Forms.MessageBox]::Show("インターネットに接続できることを確認してください。","", [System.Windows.Forms.MessageBoxButtons]::AbortRetryIgnore, [System.Windows.Forms.MessageBoxIcon]::Question, [System.Windows.Forms.MessageBoxDefaultButton]::Button2) -ne [System.Windows.Forms.DialogResult]::Abort){
                    Invoke-NavigationBarInstallButtonClick
                    Break
                }
            }
            # Componetns
            If ($MainWindow.FindName("ComponentsListView").IsEnabled){
                Request-Job -Script {Show-InstallStatusUi} -DependentPs1File (Join-Path $PSScriptRoot "Install-WindowsFeature.Task.ps1") -Arguments ($MainWindow.FindName("ComponentsListView").DataContext | Where-Object {-not $_.Installed -and $_.IsSelected}) -PSScriptRoot $PSScriptRoot | Out-Null
            }
        }
        Invoke-NavigationBarInstallButtonClick
    })
    $MainWindow.FindName("NavigationBarBackButton").Add_Click({
        $NavigateTabs = @($MainWindow.FindName("MainTabControl").Items | Where-Object {($_.Visibility -eq [System.Windows.Visibility]::Visible) -and ($_ -ne $MainWindow.FindName("AboutTab"))})
        $MainWindow.FindName("MainTabControl").SelectedItem = $NavigateTabs[$NavigateTabs.IndexOf($MainWindow.FindName("MainTabControl").SelectedItem) - 1]
    })
    $MainWindow.FindName("NavigationBarFowardButton").Add_Click({
        Step-MainTabControl
    })
    $MainWindow.FindName("NavigationBarCompleteButton").Add_Click({
        $MainWindow.WindowState = [System.Windows.WindowState]::Minimized
        Set-MainWindowSettings
        $MainWindow.DialogResult = $True
    })

    $Global:DefaultStatusTitle = $MainWindow.FindName("StatusTitle").Text

    # EULA
    If ($CurrentConfig.Config.AgreeEula -eq $false){
        $MainWindow.FindName("EulaRoot").Visibility = [System.Windows.Visibility]::Visible
        $MainWindow.FindName("AgreeButton").Add_Click({
            $MainWindow.FindName("EulaRoot").Visibility = [System.Windows.Visibility]::Collapsed
            $CurrentConfig.Config.AgreeEula = $true
        })
        $MainWindow.FindName("ExitButton").Add_Click({
            $MainWindow.Close()
        })
    }

}

Function Global:Set-MaintabControlNavigationButtons{
    $NavigateTabs = @($MainWindow.FindName("MainTabControl").Items | Where-Object {($_.Visibility -eq [System.Windows.Visibility]::Visible) -and ($_ -ne $MainWindow.FindName("AboutTab"))})
    Switch ($MainWindow.FindName("MainTabControl").SelectedItem){
        $NavigateTabs[0]{
            $MainWindow.FindName("NavigationBarInstallButton").Visibility = [System.Windows.Visibility]::Collapsed
            $MainWindow.FindName("NavigationBarBackButton").Visibility = [System.Windows.Visibility]::Collapsed
            $MainWindow.FindName("NavigationBarFowardButton").Visibility = [System.Windows.Visibility]::Visible
            $MainWindow.FindName("NavigationBarCompleteButton").Visibility = [System.Windows.Visibility]::Collapsed
            $MainWindow.FindName("NavigationBar").Visibility = [System.Windows.Visibility]::Visible
        }
        $NavigateTabs[($NavigateTabs.Count -1)]{
            $MainWindow.FindName("NavigationBarBackButton").Visibility = [System.Windows.Visibility]::Visible
            $MainWindow.FindName("NavigationBarFowardButton").Visibility = [System.Windows.Visibility]::Collapsed
            $MainWindow.FindName("NavigationBarCompleteButton").Visibility = [System.Windows.Visibility]::Visible
            $MainWindow.FindName("NavigationBar").Visibility = [System.Windows.Visibility]::Visible
        }
        $MainWindow.FindName("OptionTab"){
            If (@($MainWindow.FindName("ComponentsListView").DataContext | Where-Object {-not $_.Installed -and $_.IsSelected}).Count -ne 0){
                $MainWindow.FindName("NavigationBarInstallButton").Visibility = [System.Windows.Visibility]::Visible
                $MainWindow.FindName("NavigationBarFowardButton").Visibility = [System.Windows.Visibility]::Collapsed
            }Else{
                $MainWindow.FindName("NavigationBarInstallButton").Visibility = [System.Windows.Visibility]::Collapsed
                $MainWindow.FindName("NavigationBarFowardButton").Visibility = [System.Windows.Visibility]::Visible
            }
            $MainWindow.FindName("NavigationBarBackButton").Visibility = [System.Windows.Visibility]::Collapsed
            $MainWindow.FindName("NavigationBarCompleteButton").Visibility = [System.Windows.Visibility]::Collapsed
            $MainWindow.FindName("NavigationBar").Visibility = [System.Windows.Visibility]::Visible
        }
        $MainWindow.FindName("AboutTab"){
            $MainWindow.FindName("NavigationBar").Visibility = [System.Windows.Visibility]::Collapsed
        }
        Default{
            $MainWindow.FindName("NavigationBarInstallButton").Visibility = [System.Windows.Visibility]::Collapsed
            $MainWindow.FindName("NavigationBarBackButton").Visibility = [System.Windows.Visibility]::Visible
            $MainWindow.FindName("NavigationBarFowardButton").Visibility = [System.Windows.Visibility]::Visible
            $MainWindow.FindName("NavigationBarCompleteButton").Visibility = [System.Windows.Visibility]::Collapsed
            $MainWindow.FindName("NavigationBar").Visibility = [System.Windows.Visibility]::Visible
        }
    }
}
Function Global:Step-MainTabControl{
    $NavigateTabs = @($MainWindow.FindName("MainTabControl").Items | Where-Object {($_.Visibility -eq [System.Windows.Visibility]::Visible) -and ($_ -ne $MainWindow.FindName("AboutTab"))})
    $MainWindow.FindName("MainTabControl").SelectedItem = $NavigateTabs[$NavigateTabs.IndexOf($MainWindow.FindName("MainTabControl").SelectedItem) + 1]
}


#
# OptionTab
#
Function Global:Initialize-OptionTab{
    $MainWindow.FindName("ComponentsListView").Add_DataContextChanged{
        Set-MaintabControlNavigationButtons
        $MainWindow.FindName("ComponentsListView").DataContext | ForEach-Object {
            $_.DetailsButton.Add_Click({param($sender)
                $MainWindow.Dispatcher.Invoke({
                    Try{
                        Start-Process $sender.DetailsUrl
                    }
                    Catch{
                    }
                })
            })
            $_.OptionComponentCheckBox.Add_Check({param($sender)
                $MainWindow.Dispatcher.Invoke({
                    Try{
                        Set-MaintabControlNavigationButtons
                    }
                    Catch{
                    }
                })
            })
        }
    }
    # 別のスレッドから発火されたイベントを処理する
    $MainWindow.FindName("IndicatorRoot").Add_IsVisibleChanged({param($sender, $e)
        If ($MainWindow.FindName("IndicatorRoot").Visibility -eq [System.Windows.Visibility]::Hidden){
            #Step-MainTabControl
            $MainWindow.FindName("IndicatorRoot").Visibility = [System.Windows.Visibility]::Visible
            Request-Job -Script {Initialize-MainWindowUIJob} -DependentPs1File (Resolve-Path (Join-Path (Get-Module Wsustainable).ModuleBase "View\Initialize-MainWindowUIJob.Task.ps1")).Path -PSScriptRoot $PSScriptRoot | Out-Null
            #Set-MaintabControlNavigationButtons
        }
    })
}

#
# ServerTab
#
Function Global:Initialize-ServerTab{
    $MainWindow.FindName("WsusServerTextBox").DataContext = $CurrentConfig.Wsus
    $MainWindow.FindName("WsusServerPortTextBox").Text = $CurrentConfig.Wsus.Port
    $MainWindow.FindName("WsusServerUseSslCheckBox").DataContext = $CurrentConfig.Wsus

    $MainWindow.FindName("TestConnectionWsusServerButton").Add_Click({
        $MainWindow.FindName("WsusServerTextBox").Focus()
        $MainWindow.FindName("TestConnectionWsusServerButton").IsEnabled = $False
        Initialize-TestResultMessages
        
        Request-Job -Script {Test-ServerAllFunctions} -DependentPs1File (Join-Path $PSScriptRoot "Test-ServerAllFunctions.Task.ps1") -PSScriptRoot $PSScriptRoot | Out-Null
    })

    $MainWindow.FindName("WsusServerTextBox").Add_TextChanged({
        Initialize-TestResultMessages
        $MainWindow.FindName("TestConnectionWsusServerButton").IsEnabled = $True
    })
    $MainWindow.FindName("WsusServerPortTextBox").Add_TextChanged({
        Initialize-TestResultMessages
        $MainWindow.FindName("TestConnectionWsusServerButton").IsEnabled = $True
        $CurrentConfig.Wsus.Port = $MainWindow.FindName("WsusServerPortTextBox").Text
    })
    $MainWindow.FindName("WsusServerUseSslCheckBox").Add_Checked({
        If ($MainWindow.FindName("WsusServerPortTextBox").Text -eq 8530){
            $MainWindow.FindName("WsusServerPortTextBox").Text = 8531
        }
    })
    $MainWindow.FindName("WsusServerUseSslCheckBox").Add_UnChecked({
        If ($MainWindow.FindName("WsusServerPortTextBox").Text -eq 8531){
            $MainWindow.FindName("WsusServerPortTextBox").Text = 8530
        }
    })
}
Function Global:Initialize-TestResultMessages{
    $MainWindow.FindName("AllConnectionSuccessfully").Visibility = [System.Windows.Visibility]::Collapsed
    $MainWindow.FindName("WsusServerConnectionFailure").Visibility = [System.Windows.Visibility]::Collapsed
    $MainWindow.FindName("WsusPoolApplicationContainer").Visibility = [System.Windows.Visibility]::Collapsed
    $MainWindow.FindName("SqlConnectionFailure").Visibility = [System.Windows.Visibility]::Collapsed
    $MainWindow.FindName("IisConnectionFailure").Visibility = [System.Windows.Visibility]::Collapsed
}

#
# ServerConfigTab
#
Function Global:Get-FsResourceManagerInstalledStatus{
    $Status = $False

    Return $Status
}

Function Global:Initialize-ServerConfigTab{
    $MainWindow.FindName("IisWsusPoolTextBox").DataContext = $CurrentConfig.Wsus
    $MainWindow.FindName("ServerInstancePathTextBox").DataContext = $CurrentConfig.MaintenanceSql
}

#
# SyncWindowsProductsTab
#
Function Global:Initialize-SyncWindowsProductsTab{
    Function Script:Invoke-SyncWindowsShowLtscOnlyToggleButtonChecked($sender, $e){
        If ($IgnoreSyncWindowsShowLtscOnlyToggleButtonCheckEvent){
            Return
        }
        $MainWindow.FindName("SyncWindowsShowLtscOnlyToggleButton").IsEnabled = $False
        $MessageText = "LTSCのみの選択に切り替えると、この画面で行った選択が解除されます。"
        If ([System.Windows.Forms.MessageBox]::Show("$MessageText`n続行してもよろしいですか?","", [System.Windows.Forms.MessageBoxButtons]::YesNo , [System.Windows.Forms.MessageBoxIcon]::Question) -ne [System.Windows.Forms.DialogResult]::Yes){
            $Script:IgnoreSyncWindowsShowLtscOnlyToggleButtonCheckEvent = $True
            $LastCheckedSyncWindowsCheckBox.IsChecked = $True
            $MainWindow.FindName("SyncWindowsShowLtscOnlyToggleButton").IsEnabled = $True
            $Script:IgnoreSyncWindowsShowLtscOnlyToggleButtonCheckEvent = $False
        }
        Else{
            $LastCheckedSyncWindowsCheckBox.Focus()
            Get-LifecycleItems
            Set-WindowsProductsFiltersCheckBox
        }
    }
    Function Script:Invoke-SyncWindowsShowLtscOnlyToggleButtonUnChecked($sender, $e){
        If ($IgnoreSyncWindowsShowLtscOnlyToggleButtonCheckEvent){
            Return
        }
        $MessageText = "Pro・Enterprise・Educationの選択に切り替えると、この画面で行った選択が解除されます。"
        If ([System.Windows.Forms.MessageBox]::Show("$MessageText`n続行してもよろしいですか?","", [System.Windows.Forms.MessageBoxButtons]::YesNo , [System.Windows.Forms.MessageBoxIcon]::Question) -ne [System.Windows.Forms.DialogResult]::Yes){
            $Script:IgnoreSyncWindowsShowLtscOnlyToggleButtonCheckEvent = $True
            $MainWindow.FindName("SyncWindowsShowLtscOnlyToggleButton").IsChecked = $True
            $Script:IgnoreSyncWindowsShowLtscOnlyToggleButtonCheckEvent = $False
        }
        Else{
            Get-LifecycleItems
            Set-WindowsProductsFiltersCheckBox
        }
    }
    Function Script:Set-WindowsProductsFiltersCheckBox{
        $FilteredWindows10Products = $Windows10Products | Sort-Object Version -Descending
        $FilteredWindows11Products = $Windows11Products | Sort-Object Version -Descending
        $FilteredVisualStudioProducts = $VisualStudioProducts | Sort-Object Title -Descending

        If (-not $MainWindow.FindName("SyncWindowsShowEndOfSupportProductsCheckBox").IsChecked){
            $FilteredWindows10Products = $FilteredWindows10Products | Where-Object {(Get-Date) -le $_.EndDate}
            $FilteredWindows11Products = $FilteredWindows11Products | Where-Object {(Get-Date) -le $_.EndDate}
            $FilteredVisualStudioProducts = $FilteredVisualStudioProducts | Where-Object {(Get-Date) -le $_.EndDate}
        }
        If ($MainWindow.FindName("SyncWindowsShowEnterpriseWithoutLtscOnlyRadioButton").IsChecked){
            $FilteredWindows10Products = $FilteredWindows10Products | Where-Object IsEnterpriseWithoutLtsc
            $FilteredWindows11Products = $FilteredWindows11Products | Where-Object IsEnterpriseWithoutLtsc
            $FilteredVisualStudioProducts = $FilteredVisualStudioProducts | Where-Object {-not $_.IsLtsc}
            $MainWindow.FindName("SyncWindowsShowLtscOnlyToggleButton").IsEnabled = $True
        }
        ElseIf ($MainWindow.FindName("SyncWindowsShowLtscOnlyToggleButton").IsChecked){
            $FilteredWindows10Products = $FilteredWindows10Products | Where-Object IsLtsc
            $FilteredWindows11Products = $FilteredWindows11Products | Where-Object IsLtsc
            $FilteredVisualStudioProducts = $FilteredVisualStudioProducts | Where-Object IsLtsc
        }
        Else{
            $FilteredWindows10Products = $FilteredWindows10Products | Where-Object IsPro
            $FilteredWindows11Products = $FilteredWindows11Products | Where-Object IsPro
            $FilteredVisualStudioProducts = $FilteredVisualStudioProducts | Where-Object {-not $_.IsLtsc}
            $MainWindow.FindName("SyncWindowsShowLtscOnlyToggleButton").IsEnabled = $True
        }

        If ($MainWindow.FindName("SyncWindowsShowArchitectureCheckBox").IsChecked){
            $MainWindow.FindName("SyncWindowsProductsWindows11Lists").ItemTemplate = $MainWindow.FindResource("SyncWindowFeatureUpdateArchitectureChooser")
            $MainWindow.FindName("SyncWindowsProductsWindows10Lists").ItemTemplate = $MainWindow.FindResource("SyncWindowFeatureUpdateArchitectureChooser")

            $MainWindow.FindName("SyncEdgeConfigureArchitectureContainer").Visibility = [System.Windows.Visibility]::Visible
            $MainWindow.FindName("SyncMrtConfigureArchitectureContainer").Visibility = [System.Windows.Visibility]::Visible
            $MainWindow.FindName("SyncOfficeExpander").Visibility = [System.Windows.Visibility]::Visible
        }
        Else{
            $MainWindow.FindName("SyncWindowsProductsWindows11Lists").ItemTemplate = $MainWindow.FindResource("SyncWindowFeatureUpdateChooser")
            $MainWindow.FindName("SyncWindowsProductsWindows10Lists").ItemTemplate = $MainWindow.FindResource("SyncWindowFeatureUpdateChooser")
            
            $MainWindow.FindName("SyncEdgeConfigureArchitectureContainer").Visibility = [System.Windows.Visibility]::Collapsed
            $MainWindow.FindName("SyncMrtConfigureArchitectureContainer").Visibility = [System.Windows.Visibility]::Collapsed
            $MainWindow.FindName("SyncOfficeExpander").Visibility = [System.Windows.Visibility]::Collapsed
        }

        If ($FilteredWindows10Products.Count -eq 0){
            $MainWindow.FindName("SyncWindows10Expander").Visibility = [System.Windows.Visibility]::Collapsed
        }
        Else{
            $MainWindow.FindName("SyncWindows10Expander").Visibility = [System.Windows.Visibility]::Visible
        }
        If ($FilteredWindows11Products.Count -eq 0){
            $MainWindow.FindName("SyncWindows11Expander").Visibility = [System.Windows.Visibility]::Collapsed
        }
        Else{
            $MainWindow.FindName("SyncWindows11Expander").Visibility = [System.Windows.Visibility]::Visible
        }
        If ($FilteredVisualStudioProducts.Count -eq 0){
            $MainWindow.FindName("SyncVisualStudioExpander").Visibility = [System.Windows.Visibility]::Collapsed
        }
        Else{
            $MainWindow.FindName("SyncVisualStudioExpander").Visibility = [System.Windows.Visibility]::Visible
        }

        $Windows10ProductsCollection = New-Object -TypeName "System.Collections.ObjectModel.ObservableCollection``1[[WindowsProductLifecycleItem]]"
        $FilteredWindows10Products | ForEach-Object{$Windows10ProductsCollection.Add($_)}
        $MainWindow.FindName("SyncWindowsProductsWindows10Lists").DataContext = $Windows10ProductsCollection
        $Windows11ProductsCollection = New-Object -TypeName "System.Collections.ObjectModel.ObservableCollection``1[[WindowsProductLifecycleItem]]"
        $FilteredWindows11Products | ForEach-Object{$Windows11ProductsCollection.Add($_)}
        $MainWindow.FindName("SyncWindowsProductsWindows11Lists").DataContext = $Windows11ProductsCollection
        $VisualStudioProductsCollection = New-Object -TypeName "System.Collections.ObjectModel.ObservableCollection``1[[VisualStudioLifecycleItem]]"
        $FilteredVisualStudioProducts | ForEach-Object{$VisualStudioProductsCollection.Add($_)}
        $MainWindow.FindName("SyncVisualStudioLists").DataContext = $VisualStudioProductsCollection
    }
    Function Script:Get-LifecycleItem($Source, [LifecycleProductType]$Parent){
        Enum LifecycleProductType{
            Windows10
            Windows11
            VisualStudio
        }
        If ($Parent -eq [LifecycleProductType]::VisualStudio){
            $Item = (New-Object -TypeName VisualStudioLifecycleItem)
        }
        Else{
            $Item = (New-Object -TypeName WindowsProductLifecycleItem)
            $Item.Add_SelectionChanged({param($sender, $e)
                Sync-WindowsProductLifecycleItem -sender $sender -e $e
            })
        }

        $Item.Title = $Source.Title
        $Item.Version = $Source.Version
        $Item.EndDate = $Source.EndDate
        $Item.NeededProducts = $Source.NeededProducts
        $Item.IsLtsc = $Source.IsLtsc
        If ($Parent -ne [LifecycleProductType]::VisualStudio){
            $Item.IsPro = $Source.IsPro
            $Item.IsEnterpriseWithoutLtsc = $Source.IsEnterpriseWithoutLtsc
            $Item.VisibleX86 = $Source.VisibleX86
            $Item.VisibleX64 = $Source.VisibleX64
            $Item.VisibleArm64 = $Source.VisibleArm64
        }

        If ($Source.IsLtsc -like "true"){$Item.IsLtsc = $True}Else{$Item.IsLtsc = $False}
        If ($Parent -ne [LifecycleProductType]::VisualStudio){
            If ($Source.IsPro -like "true"){$Item.IsPro = $True}Else{$Item.IsPro = $False}
            If ($Source.IsEnterpriseWithoutLtsc -like "true"){$Item.IsEnterpriseWithoutLtsc = $True}Else{$Item.IsEnterpriseWithoutLtsc = $False}
            If ($Source.VisibleX86 -like "true"){$Item.VisibleX86 = $True}Else{$Item.VisibleX86 = $False}
            If ($Source.VisibleX64 -like "true"){$Item.VisibleX64 = $True}Else{$Item.VisibleX64 = $False}
            If ($Source.VisibleArm64 -like "true"){$Item.VisibleArm64 = $True}Else{$Item.VisibleArm64 = $False}
        }

        $Item | Add-Member -MemberType NoteProperty -Name Parent -Value $Parent

        Return $Item
    }
    Function Script:Get-LifecycleItems{
        If (Test-Path (Join-Path (Get-Module Wsustainable).ModuleBase "Assets\Lifecycle--Windows 11.csv")){
            $Global:Windows11Products = (Import-Csv (Join-Path (Get-Module Wsustainable).ModuleBase "Assets\Lifecycle--Windows 11.csv") -Encoding UTF8) | ForEach-Object {(Get-LifecycleItem -Source $_ -Parent Windows11)}
        }Else{
            $MainWindow.FindName("SyncWindows11Expander").IsEnabled = $False
        }
        If (Test-Path (Join-Path (Get-Module Wsustainable).ModuleBase "Assets\Lifecycle--Windows 10.csv")){
            $Global:Windows10Products = (Import-Csv (Join-Path (Get-Module Wsustainable).ModuleBase "Assets\Lifecycle--Windows 10.csv") -Encoding UTF8) | ForEach-Object {(Get-LifecycleItem -Source $_ -Parent Windows10)}
        }Else{
            $MainWindow.FindName("SyncWindows10Expander").IsEnabled = $False
        }
        If (Test-Path (Join-Path (Get-Module Wsustainable).ModuleBase "Assets\Lifecycle--Visual Studio.csv")){
            $Global:VisualStudioProducts = (Import-Csv (Join-Path (Get-Module Wsustainable).ModuleBase "Assets\Lifecycle--Visual Studio.csv") -Encoding UTF8) | ForEach-Object {(Get-LifecycleItem -Source $_ -Parent VisualStudio)}
        }Else{
            $MainWindow.FindName("SyncVisualStudioExpander").IsEnabled = $False
        }
    }
    Function Script:Get-LanguageItems{
        # Windows 11
        If (Test-Path (Join-Path (Get-Module Wsustainable).ModuleBase "Assets\FeatureUpdateLanguages--Windows 11.csv")){
            $Global:Windows11FeatureUpdateLanguages = New-Object -TypeName "System.Collections.ObjectModel.ObservableCollection``1[[LanguageItem]]"
            (Import-Csv (Join-Path (Get-Module Wsustainable).ModuleBase "Assets\FeatureUpdateLanguages--Windows 11.csv") -Encoding UTF8).Name | ForEach-Object {
                $Item = (New-Object -TypeName LanguageItem)
                $Item.CultureInfo = [System.Globalization.CultureInfo]::new($_, $false)
                $Item.Selected = ($_ -in ($CurrentConfig.ChooseProducts."Windows 11".ExcludeLanguages -split ","))
                $Windows11FeatureUpdateLanguages.Add($Item)
            }
        }Else{
            $MainWindow.FindName("SyncWindows11LanguagesEditButton").IsEnabled = $False
        }
        # Windows 10
        If (Test-Path (Join-Path (Get-Module Wsustainable).ModuleBase "Assets\FeatureUpdateLanguages--Windows 10.csv")){
            $Global:Windows10FeatureUpdateLanguages = New-Object -TypeName "System.Collections.ObjectModel.ObservableCollection``1[[LanguageItem]]"
            (Import-Csv (Join-Path (Get-Module Wsustainable).ModuleBase "Assets\FeatureUpdateLanguages--Windows 10.csv") -Encoding UTF8).Name | ForEach-Object {
                $Item = (New-Object -TypeName LanguageItem)
                $Item.CultureInfo = [System.Globalization.CultureInfo]::new($_, $false)
                $Item.Selected = ($_ -in ($CurrentConfig.ChooseProducts."Windows 10".ExcludeLanguages -split ","))
                $Windows10FeatureUpdateLanguages.Add($Item)
            }
        }Else{
            $MainWindow.FindName("SyncWindows10LanguagesEditButton").IsEnabled = $False
        }
    }

    $Script:IgnoreSyncWindowsShowLtscOnlyToggleButtonCheckEvent = $False
    Get-LifecycleItems
    Get-LanguageItems
    Set-WindowsProductsFiltersCheckBox


    #
    # Common
    #
    $MainWindow.FindName("SyncWindowsShowEndOfSupportProductsCheckBox").Add_Checked({Set-WindowsProductsFiltersCheckBox})
    $MainWindow.FindName("SyncWindowsShowEndOfSupportProductsCheckBox").Add_UnChecked({Set-WindowsProductsFiltersCheckBox})
    $MainWindow.FindName("SyncWindowsShowArchitectureCheckBox").Add_Checked({Set-WindowsProductsFiltersCheckBox})
    $MainWindow.FindName("SyncWindowsShowArchitectureCheckBox").Add_UnChecked({Set-WindowsProductsFiltersCheckBox})


    #
    # Windows
    #
    $MainWindow.FindName("SyncWindowsShowProOnlyRadioButton").Add_Checked({param($sender, $e)$Global:LastCheckedSyncWindowsCheckBox = $sender;Set-WindowsProductsFiltersCheckBox})
    $MainWindow.FindName("SyncWindowsShowEnterpriseWithoutLtscOnlyRadioButton").Add_Checked({param($sender, $e)$Global:LastCheckedSyncWindowsCheckBox = $sender;Set-WindowsProductsFiltersCheckBox})
    $MainWindow.FindName("SyncWindowsShowLtscOnlyToggleButton").Add_Checked({param($sender, $e)Invoke-SyncWindowsShowLtscOnlyToggleButtonChecked -sender $sender -e $e})
    $MainWindow.FindName("SyncWindowsShowLtscOnlyToggleButton").Add_UnChecked({param($sender, $e)Invoke-SyncWindowsShowLtscOnlyToggleButtonUnChecked -sender $sender -e $e})
    
    $MainWindow.FindName("SyncWindowsShowProOnlyRadioButton").IsChecked = $True
    $Global:LastCheckedSyncWindowsCheckBox = $MainWindow.FindName("SyncWindowsShowProOnlyRadioButton")

    # Windows 11
    $MainWindow.FindName("SyncWindows11Container").DataContext = $CurrentConfig.ChooseProducts."Windows 11"
    $MainWindow.FindName("SyncWindows11LanguagesEditButton").Add_Click({param($sender,$e)
        Try{
            Get-SelectLanguagesWindow
            $Windows11FeatureUpdateLanguages | ForEach-Object{ $_.Visible = $True }
            $Global:SelectLanguagesWindow.FindName("LanguagesList").DataContext = $Windows11FeatureUpdateLanguages
            If ($Global:SelectLanguagesWindow.ShowDialog()){
                $Global:CurrentConfig.ChooseProducts."Windows 11".ExcludeLanguages = (($Windows11FeatureUpdateLanguages | Where-Object Selected).CultureInfo.Name -join ",")
                $MainWindow.FindName("SyncWindows11Container").DataContext = $CurrentConfig.ChooseProducts."Windows 11"
            }
        }
        Catch{}
    })

    # Windows 10
    $MainWindow.FindName("SyncWindows10Container").DataContext = $CurrentConfig.ChooseProducts."Windows 10"
    $MainWindow.FindName("SyncWindows10LanguagesEditButton").Add_Click({param($sender,$e)
        Try{
            Get-SelectLanguagesWindow
            $Global:SelectLanguagesWindow.FindName("LanguagesList").DataContext = $Null
            $Windows10FeatureUpdateLanguages | ForEach-Object{ $_.Visible = $True }
            $Global:SelectLanguagesWindow.FindName("LanguagesList").DataContext = $Windows10FeatureUpdateLanguages
            If ($Global:SelectLanguagesWindow.ShowDialog()){
                $Global:CurrentConfig.ChooseProducts."Windows 10".ExcludeLanguages = (($Windows10FeatureUpdateLanguages | Where-Object Selected).CultureInfo.Name -join ",")
                $MainWindow.FindName("SyncWindows10Container").DataContext = $CurrentConfig.ChooseProducts."Windows 10"
            }
        }
        Catch{}
    })


    #
    # Microsoft Edge (Chromium)
    #
    $MainWindow.FindName("SyncEdgeContainer").DataContext = $CurrentConfig.ChooseProducts."Microsoft Edge"

    #
    # MRT
    #
    $MainWindow.FindName("SyncMrtContainer").DataContext = $CurrentConfig.ChooseProducts."Malicious Software Removal Tool"


    #
    # Defender
    #
    $MainWindow.FindName("SyncDefenderAntivirusContainer").DataContext = $CurrentConfig.ChooseProducts."Microsoft Defender Antivirus"


    #
    # Office
    #
    $MainWindow.FindName("SyncOfficeContainer").DataContext = $CurrentConfig.ChooseProducts."Office"


    #
    # Visual Studio
    #
    $MainWindow.FindName("SyncVisualStudioContainer").DataContext = $CurrentConfig.ChooseProducts."Visual Studio"


    # Link
    $MainWindow.FindName("FindLifecycleProductsHyperlink").Add_Click({ param($sender,$e) Try{ Start-Process $sender.NavigateUri } Catch{} })
}

function Global:Sync-WindowsProductLifecycleItem($sender, $e){
    Function Compare-SelectedFlag($Selected, $Visible){
        If (-not $Visible){
            Return $True
        }
        Return $Selected
    }   
    # 編集中の項目はキャンセル
    If ($sender.SelectionChangedCancelRequest){
        Return
    }

    Switch ($sender.Parent){
        Windows10{
            $CurrentProducts = $Windows10Products
        }
        Windows11{
            $CurrentProducts = $Windows11Products
        }
    }

    # チェックされた項目を確認
    $EnabledName = $e.Trigger -replace "Selected", "Enabled"

    # バージョンが同一の項目を同期にする
    $CurrentProducts | Where-Object {($_.Version -eq $sender.Version) -and ($_.Title -ne $sender.Title) -and ($_.Selected -ne $sender.$($e.Trigger))} | ForEach-Object {
        $_.SelectionChangedCancelRequest = $True
        $_.$($e.Trigger) = $sender.$($e.Trigger)
        $_.$($EnabledName) = $True

        $_.SelectionChangedCancelRequest = $False
    }

    # 選択したバージョン前後の項目の選択状態を修正する
    $CurrentProducts | ForEach-Object{
        $_.SelectionChangedCancelRequest = $True
        If ($_.Version -gt $sender.Version){
            # LTSCバージョンの選択は自由にする
            If (-not $_.IsLtsc){
                $_.$($EnabledName) = $False
                If ($e.Trigger -eq [WindowsProductLifecycleItem+SelectionChangedEventArgs+Reason]::Selected){
                    $_.EnabledX86 = $False
                    $_.EnabledX64 = $False
                    $_.EnabledArm64 = $False
                }
                Else{
                    $_.Enabled = $False
                }
            }
            $_.$($e.Trigger) = $True
        }
        ElseIf ($_.Version -lt $sender.Version){
            $_.$($EnabledName) = $True
            $_.$($e.Trigger) = $False
        }
        
        $_.SelectionChangedCancelRequest = $False
    }

    # 選択が外れたとき、選択したバージョンの次のバージョンを有効状態にする
    $CurrentProducts | Select-Object Version | Where-Object Version -gt $sender.Version | Get-Unique | Select-Object -First 1 | ForEach-Object {
        If (-not $sender.$($e.Trigger)){
            $NextVersion = $_.Version
            $CurrentProducts | Where-Object {$_.Version -eq $NextVersion} | ForEach-Object {
                $_.$($EnabledName) = $True
            }
        }
    }

    If ($e.Trigger -eq [WindowsProductLifecycleItem+SelectionChangedEventArgs+Reason]::Selected){
        $CurrentProducts | ForEach-Object {
            $_.SelectionChangedCancelRequest = $True
            $_.SelectedX86 = $_.Selected
            $_.SelectedX64 = $_.Selected
            $_.SelectedArm64 = $_.Selected
            $_.EnabledX86 = $_.Enabled
            $_.EnabledX64 = $_.Enabled
            $_.EnabledArm64 = $_.Enabled
            $_.SelectionChangedCancelRequest = $False
        }
    }
    Else{
        $CurrentProducts | ForEach-Object {
            If ((Compare-SelectedFlag $_.SelectedX86 $_.VisibleX86) -and (Compare-SelectedFlag $_.SelectedX64 $_.VisibleX64) -and (Compare-SelectedFlag $_.SelectedArm64 $_.VisibleArm64)){
                $_.SelectionChangedCancelRequest = $True
                $_.Selected = $True
                $_.SelectionChangedCancelRequest = $False
            }
            ElseIf (-not (Compare-SelectedFlag $_.SelectedX86 $_.VisibleX86) -and -not (Compare-SelectedFlag $_.SelectedX64 $_.VisibleX64) -and -not (Compare-SelectedFlag $_.SelectedArm64 $_.VisibleArm64)){
                $_.SelectionChangedCancelRequest = $True
                $_.Selected = $False
                $_.SelectionChangedCancelRequest = $False
            }
            Else{
                $_.SelectionChangedCancelRequest = $True
                $_.Selected = $Null
                $_.SelectionChangedCancelRequest = $False
            }
        }
    }

    $sender.$($EnabledName) = $True
}

#
# DeclineRuleTab
#
Function Global:Initialize-DeclineRuleTab{
    # 全般
    $MainWindow.FindName("UseWsusCleanupWizardWithCompressUpdateCheckBox").DataContext = $CurrentConfig.DeclineOptions.CleanupWizard
    $MainWindow.FindName("UseWsusCleanupWizardWithCompressUpdateCheckBox").Add_Checked{$CurrentConfig.DeclineOptions.CleanupWizard.CleanupObsoleteUpdates = $True}
    $MainWindow.FindName("UseWsusCleanupWizardWithCompressUpdateCheckBox").Add_UnChecked{$CurrentConfig.DeclineOptions.CleanupWizard.CleanupObsoleteUpdates = $False}
    If ($CurrentConfig.DeclineOptions.CleanupWizard.CleanupObsoleteUpdates -and $CurrentConfig.DeclineOptions.CleanupWizard.DeclineExpiredUpdates -and $CurrentConfig.DeclineOptions.CleanupWizard.DeclineSupersededUpdates){ $UseWsusCleanupWizardOthersCheckBoxState = $True }
    ElseIf (-not $CurrentConfig.DeclineOptions.CleanupWizard.CleanupObsoleteUpdates -and -not $CurrentConfig.DeclineOptions.CleanupWizard.DeclineExpiredUpdates -and -not $CurrentConfig.DeclineOptions.CleanupWizard.DeclineSupersededUpdates){ $UseWsusCleanupWizardOthersCheckBoxState = $False }
    Else{ $UseWsusCleanupWizardOthersCheckBoxState = $Null }
    $MainWindow.FindName("UseWsusCleanupWizardOthersCheckBox").IsChecked = $UseWsusCleanupWizardOthersCheckBoxState
    $MainWindow.FindName("UseWsusCleanupWizardOthersCheckBox").Add_Checked{
        $CurrentConfig.DeclineOptions.CleanupWizard.CleanupObsoleteUpdates = $True
        $CurrentConfig.DeclineOptions.CleanupWizard.DeclineExpiredUpdates = $True
        $CurrentConfig.DeclineOptions.CleanupWizard.DeclineSupersededUpdates = $True
    }
    $MainWindow.FindName("UseWsusCleanupWizardOthersCheckBox").Add_UnChecked{
        $CurrentConfig.DeclineOptions.CleanupWizard.CleanupObsoleteUpdates = $False
        $CurrentConfig.DeclineOptions.CleanupWizard.DeclineExpiredUpdates = $False
        $CurrentConfig.DeclineOptions.CleanupWizard.DeclineSupersededUpdates = $False
    }
}

#
# ApproveRuleOptionsTab
#
Function Global:Initialize-ApproveRuleOptionsTab{
    $Global:ApproveNeededUpdatesRule = New-Object -TypeName "System.Collections.ObjectModel.ObservableCollection``1[[ApproveNeededUpdatesRuleItem]]"
    $MainWindow.FindName("ApproveRuleList").DataContext = $Global:ApproveNeededUpdatesRule

    $MainWindow.FindName("ApproveRuleAddButton").Add_Click({
        $Item = (New-Object -TypeName ApproveNeededUpdatesRuleItem)

        $Item.RemoveItemButton_Click.Add_Click({
            $Global:ApproveNeededUpdatesRule.Remove($MainWindow.FindName("ApproveRuleList").SelectedItem)
        })
        $Global:ApproveNeededUpdatesRule.Add($Item)
    })
}

#
# ScheduleTab
#
Function Global:Initialize-ScheduleTab{
    $MainWindow.FindName("EditiingScheduleTriggersExpander").Header = ($MainWindow.FindName("EditiingScheduleTriggersExpander").Header -f $CurrentConfig.ScheduledTask.Name)

    Set-ScheduleTriggersCheckBox
    $MainWindow.FindName("EditiingScheduleTriggersExpander").Add_Expanded({Set-ScheduleTriggersCheckBox})
    $MainWindow.FindName("EditiingScheduleTriggersExpander").Add_Collapsed({Set-ScheduleTriggersCheckBox})
    $MainWindow.FindName("WeeklyScheduleSundayCheckBox").Add_Checked({Set-ScheduleTriggersCheckBox})
    $MainWindow.FindName("WeeklyScheduleSundayCheckBox").Add_UnChecked({Set-ScheduleTriggersCheckBox})
    $MainWindow.FindName("WeeklyScheduleMondayCheckBox").Add_Checked({Set-ScheduleTriggersCheckBox})
    $MainWindow.FindName("WeeklyScheduleMondayCheckBox").Add_UnChecked({Set-ScheduleTriggersCheckBox})
    $MainWindow.FindName("WeeklyScheduleTuesdayCheckBox").Add_Checked({Set-ScheduleTriggersCheckBox})
    $MainWindow.FindName("WeeklyScheduleTuesdayCheckBox").Add_UnChecked({Set-ScheduleTriggersCheckBox})
    $MainWindow.FindName("WeeklyScheduleWednesdayCheckBox").Add_Checked({Set-ScheduleTriggersCheckBox})
    $MainWindow.FindName("WeeklyScheduleWednesdayCheckBox").Add_UnChecked({Set-ScheduleTriggersCheckBox})
    $MainWindow.FindName("WeeklyScheduleThursdayCheckBox").Add_Checked({Set-ScheduleTriggersCheckBox})
    $MainWindow.FindName("WeeklyScheduleThursdayCheckBox").Add_UnChecked({Set-ScheduleTriggersCheckBox})
    $MainWindow.FindName("WeeklyScheduleFridayCheckBox").Add_Checked({Set-ScheduleTriggersCheckBox})
    $MainWindow.FindName("WeeklyScheduleFridayCheckBox").Add_UnChecked({Set-ScheduleTriggersCheckBox})
    $MainWindow.FindName("WeeklyScheduleSaturdayCheckBox").Add_Checked({Set-ScheduleTriggersCheckBox})
    $MainWindow.FindName("WeeklyScheduleSaturdayCheckBox").Add_UnChecked({Set-ScheduleTriggersCheckBox})
    $MainWindow.FindName("MonthlyScheduleFirstCheckBox").Add_Checked({Set-ScheduleTriggersCheckBox})
    $MainWindow.FindName("MonthlyScheduleFirstCheckBox").Add_UnChecked({Set-ScheduleTriggersCheckBox})
    $MainWindow.FindName("MonthlyScheduleSecondCheckBox").Add_Checked({Set-ScheduleTriggersCheckBox})
    $MainWindow.FindName("MonthlyScheduleSecondCheckBox").Add_UnChecked({Set-ScheduleTriggersCheckBox})
    $MainWindow.FindName("MonthlyScheduleThirdCheckBox").Add_Checked({Set-ScheduleTriggersCheckBox})
    $MainWindow.FindName("MonthlyScheduleThirdCheckBox").Add_UnChecked({Set-ScheduleTriggersCheckBox})
    $MainWindow.FindName("MonthlyScheduleFourthCheckBox").Add_Checked({Set-ScheduleTriggersCheckBox})
    $MainWindow.FindName("MonthlyScheduleFourthCheckBox").Add_UnChecked({Set-ScheduleTriggersCheckBox})
    $MainWindow.FindName("MonthlyScheduleLastCheckBox").Add_Checked({Set-ScheduleTriggersCheckBox})
    $MainWindow.FindName("MonthlyScheduleLastCheckBox").Add_UnChecked({Set-ScheduleTriggersCheckBox})

    $MainWindow.FindName("InvokeWsusSynchronizationCheckBox").Add_Checked({Set-WeeklyScheduleDateTimePicker})
    $MainWindow.FindName("InvokeWsusSynchronizationCheckBox").Add_UnChecked({Set-WeeklyScheduleDateTimePicker})

    $MainWindow.FindName("InvokeWsusSynchronizationCheckBox").DataContext = $CurrentConfig.Wsus
    Set-WeeklyScheduleDateTimePicker
}
Function Global:Set-WeeklyScheduleDateTimePicker{
    If ($MainWindow.FindName("InvokeWsusSynchronizationCheckBox").IsChecked){
        $WsusServer = Get-WsusServer -Name $CurrentConfig.Wsus.Server -PortNumber $CurrentConfig.Wsus.Port
        $Time = $WsusServer.GetSubscription().SynchronizeAutomaticallyTimeOfDay.Add([System.TimeZoneInfo]::Local.BaseUtcOffset)
        $MainWindow.FindName("WeeklyScheduleDateTimePicker").Value = (Get-Date "2001/1/1 0:00:00") + $Time
    }
    Else{
        $WsusServer = Get-WsusServer -Name $CurrentConfig.Wsus.Server -PortNumber $CurrentConfig.Wsus.Port
        $Time = $WsusServer.GetSubscription().SynchronizeAutomaticallyTimeOfDay.Add([System.TimeZoneInfo]::Local.BaseUtcOffset)
        $MainWindow.FindName("WeeklyScheduleDateTimePicker").Value = (Get-Date "2001/1/1 0:00:00") + $Time + (New-TimeSpan -Hours 1)
    }
}
Function Global:Set-ScheduleTriggersCheckBox{
    If ($MainWindow.FindName("EditiingScheduleTriggersExpander").IsExpanded){
        $MainWindow.FindName("WeeklyScheduleContainer").IsEnabled = $True
        $MainWindow.FindName("MonthlyScheduleContainer").IsEnabled = $True
    }
    Else{
        $MainWindow.FindName("NavigationBarCompleteButton").IsEnabled = $True
        $MainWindow.FindName("WeeklyScheduleContainer").IsEnabled = $False
        $MainWindow.FindName("MonthlyScheduleContainer").IsEnabled = $False
        Return
    }
    
    If ($MainWindow.FindName("MonthlyScheduleFirstCheckBox").IsChecked -or
        $MainWindow.FindName("MonthlyScheduleSecondCheckBox").IsChecked -or $MainWindow.FindName("MonthlyScheduleThirdCheckBox").IsChecked -or
        $MainWindow.FindName("MonthlyScheduleFourthCheckBox").IsChecked -or $MainWindow.FindName("MonthlyScheduleLastCheckBox").IsChecked){
        $MainWindow.FindName("NavigationBarCompleteButton").IsEnabled = $True
    }

    If ($MainWindow.FindName("WeeklyScheduleSundayCheckBox").IsChecked -or 
        $MainWindow.FindName("WeeklyScheduleMondayCheckBox").IsChecked -or $MainWindow.FindName("WeeklyScheduleTuesdayCheckBox").IsChecked -or 
        $MainWindow.FindName("WeeklyScheduleWednesdayCheckBox").IsChecked -or $MainWindow.FindName("WeeklyScheduleThursdayCheckBox").IsChecked -or 
        $MainWindow.FindName("WeeklyScheduleFridayCheckBox").IsChecked -or $MainWindow.FindName("WeeklyScheduleSaturdayCheckBox").IsChecked){
        $MainWindow.FindName("NavigationBarCompleteButton").IsEnabled = $True
    }
    Else{
        $MainWindow.FindName("NavigationBarCompleteButton").IsEnabled = $False
    }
}

#
# AboutTab
#
Function Global:Initialize-AboutTab{
    $MainWindow.FindName("AboutGitHubHyperlink").Add_Click({param($sender,$e)
        Try{
            Start-Process $sender.NavigateUri
        }
        Catch{}
    })
}
