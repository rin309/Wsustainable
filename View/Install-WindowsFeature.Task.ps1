Function Global:Show-InstallStatusUi{
    Class StatusItem{
        $Status
        $IsCompleted
    }
    $Global:StatusList = @()

    $MainWindow.Dispatcher.Invoke({
        $MainWindow.FindName("StatusList").DataContext = $Null
        $Global:StatusTitle = $MainWindow.FindName("StatusTitle").Text
        $MainWindow.FindName("StatusTitle").Text = "インストールしています"
        $MainWindow.FindName("IndicatorRoot").Visibility = [System.Windows.Visibility]::Visible
    })
    @($Arguments) | ForEach-Object{
        $Global:WindowsFeatureUIStatus = New-Object StatusItem
        $Global:WindowsFeatureUIStatus.Status = $_.DisplayName
        $Global:StatusList += $WindowsFeatureUIStatus
        $MainWindow.Dispatcher.Invoke({
            $MainWindow.FindName("StatusList").DataContext = $StatusList
        })

        If (-not [String]::IsNullOrEmpty($_.WindowsFeatureName)){
            Invoke-InstallWindowsFeature -Component $_
        }
        ElseIf (-not [String]::IsNullOrEmpty($_.WindowsCapabilityName)){
            Invoke-InstallWindowsCapability -Component $_
        }
        ElseIf (-not [String]::IsNullOrEmpty($_.PsModuleName)){
            Try{
                Write-Verbose "Install-Module: $($_.DisplayName) をインストールしています ($($_.PsModuleName))"
                Install-Module -Name $_.PsModuleName -Scope AllUsers -AcceptLicense -AllowClobber -Force | Out-Null
                Write-Verbose "Install-Module: $($_.DisplayName) のインストールを完了しました"
            }
            Catch{
                Write-Warning "[$($_.DisplayName)] インストールできませんでした: $($_.Exception.Message)"
            }
        }
        Else{
            Invoke-SilentInstall -Component $_
        }
    }
    
    #Step-MainTabControl
    $MainWindow.Dispatcher.Invoke({
        Try{
            $MainWindow.FindName("IndicatorRoot").Visibility = [System.Windows.Visibility]::Hidden
            $MainWindow.FindName("StatusTitle").Text = $StatusTitle
        }
        Catch{
            Write-Warning "$($_.Exception.Message)"
        }
    })
}

Function Global:Invoke-SilentInstall($Component){
    Write-Verbose "Invoke-SilentInstall: $($Component.DisplayName) をインストールしています"
    $TemporayPath = (New-TemporaryFile).FullName
    Try{
        $LocalInstallerPath = (Join-Path $ProgramDataDirectory $Component.FileName)
        If (-not (Test-Path $LocalInstallerPath -PathType Leaf)){
            Write-Verbose "[Invoke-SilentInstall] $($Component.DisplayName) のインストーラーをダウンロードします"
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $Component.DownloadUrl -OutFile $TemporayPath
            $LocalInstallerPath = (Join-Path (Split-Path $TemporayPath -Parent) $Component.FileName)
            Move-Item -Path $TemporayPath -Destination $LocalInstallerPath -Force
            $TemporayPath = $LocalInstallerPath
        }
        Else{
            Write-Verbose "[Invoke-SilentInstall] $($Component.DisplayName) のインストールにはダウンロード済みのファイルを使用します"
        }
        If ((Get-AuthenticodeSignature $LocalInstallerPath).Status -ne "Valid"){
            Write-Error "デジタル署名が無効のため実行をキャンセルしました。`n途中でダウンロードがキャンセルされた、ファイルが破損した可能性があります。"
        }
        If ($Component.SilentInstall -like "msi" -and $Component.AcceptEula -ne $Null){
            $Process = (Start-Process -FilePath msiexec -ArgumentList "-Package $LocalInstallerPath -Passive -NoRestart $($Component.AcceptEula)" -PassThru -Wait)
        }
        ElseIf ($Component.SilentInstall -like "msi"){
            $Process = (Start-Process -FilePath msiexec -ArgumentList "-Package $LocalInstallerPath -Passive -NoRestart" -PassThru -Wait)
        }
        Else{
            $Process = (Start-Process -FilePath $LocalInstallerPath -ArgumentList "-Install -Passive" -PassThru -Wait)
        }
        If ($Process.ExitCode -ne 0){
            Write-Warning "[Invoke-SilentInstall] $($Component.DisplayName) のインストールを実行しましたが完了しませんでした: $($Process.ExitCode)"
        }
    }
    Catch{
        Write-Warning "[Invoke-SilentInstall] $($Component.DisplayName) をインストールできませんでした: $($_.Exception.Message)"
    }
    Finally{
        Remove-Item $TemporayPath -Force -ErrorAction Ignore | Out-Null
    }
}

Function Global:Invoke-InstallWindowsFeature($Component){
    Try{
        Write-Verbose "Invoke-InstallWindowsFeature: $($Component.DisplayName) をインストールしています"
        Install-WindowsFeature $Component.WindowsFeatureName -IncludeManagementTools
        Write-Verbose "Invoke-InstallWindowsFeature: $($Component.DisplayName) のインストールを完了しました"
    }
    Catch{
        Write-Warning "Invoke-InstallWindowsFeature: $($Component.DisplayName) をインストールできませんでした: $($_.Exception.Message)"
    }
}

Function Global:Invoke-InstallWindowsCapability($Component){
    Try{
        Write-Verbose "[Invoke-InstallWindowsCapability] $($Component.DisplayName) をインストールしています"
        Add-WindowsCapability -Name $Component.WindowsCapabilityName -Online
        Write-Verbose "[Invoke-InstallWindowsCapability] $($Component.DisplayName) のインストールを完了しました"
    }
    Catch{
        Write-Warning "[Invoke-InstallWindowsCapability] $($Component.DisplayName) をインストールできませんでした: $($_.Exception.Message)"
    }
}
