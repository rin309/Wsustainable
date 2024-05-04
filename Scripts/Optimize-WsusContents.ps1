#Requires -Version 5.0

<#
 .Synopsis
   Cleanup wsus contents

 .Description
   The task schedule automatically deletes the old version.

 .Parameter ConfigPath
   Set ODT config path
   Create from 'Show-WsustainableSettingsView'

 .Parameter FistLaunch
   FistLaunch mode

 .Parameter Verbose
   Display verbose message

 .Example
   # Simply command sample
   Optimize-WsusContents -ConfigFileName 'C:\ProgramData\Wsustainable\0.1\Config.json'

#>

Function Optimize-WsusContents{
    Param(
        [Parameter(Mandatory)][String]$ConfigPath,
        [Switch]$FistLaunch
    )
    Function Global:Get-SqlCmdPath{
        $Path = (Get-ChildItem "$($env:ProgramFiles)\Microsoft SQL Server\Client SDK\ODBC\" -Recurse -Filter "sqlcmd.exe" -File | Sort-Object FullName -Descending | Select-Object -First 1).FullName
        If ($Path -eq $Null){
            $Path = $DefaultConfig.MaintenanceSql.SqlCmdPath
        }
        Return $Path
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
    Function Deny-WsusFilteredUpdates($DeclineRule, $UpdateScope, $RetryCount, $Month, $FindMode){
        $Global:UpdatesResult = @()
        Get-WsusFilteredUpdates $DeclineRule $UpdateScope $RetryCount $Month $FindMode

        If (-not [String]::IsNullOrEmpty($DeclineRule.Mode)){
            Write-Verbose "[Deny-WsusFilteredUpdates] Mode: $($DeclineRule.Mode)"
            switch ($DeclineRule.Mode){
                "Wildcard" {
                    $Updates = @($UpdatesResult | Where-Object Title -like $DeclineRule.Filter)
                    Write-Verbose "$(Get-Date -Format F): [Wildcard] Updates.Count: $($Updates.Count) / UpdatesResult.Count: $($UpdatesResult.Count)"
                    Write-Verbose "$(Get-Date -Format F): [Wildcard] Filter: $($DeclineRule.Filter)"
                    $DeclineUpdateCount = 0
                    $ActionDetails = ""

                    $Updates | ForEach-Object{
                        $Update = $_
                        $Update.Decline() | Out-Null
                        $DeclineUpdateCount++
                        
                        If ($CurrentConfig.Log.IsLogging){
                            If ($CurrentConfig.Log.Verbose){
                                $Update | Select-Object Title, @{Name="ProductTitles";Expression={($_.GetUpdateCategories().Title -Join "`n")}}, @{Name="ProductIds";Expression={($_.GetUpdateCategories().Id -Join "`n")}}, CreationDate, LegacyName, @{Name="Id.RevisionNumber";Expression={($_.Id.RevisionNumber -Join "`n")}}, @{Name="Id.UpdateId";Expression={($_.Id.UpdateId -Join "`n")}}, @{Name="KnowledgebaseArticles";Expression={($_.KnowledgebaseArticles -Join "`n")}}, @{Name="SecurityBulletins";Expression={($_.SecurityBulletins -Join "`n")}}, UpdateClassificationTitle, @{Name="UpdateClassificationId";Expression={($_.GetUpdateClassification().Id -Join "`n")}}, @{Name="ProductFamilyTitles";Expression={($_.ProductFamilyTitles -Join "`n")}}, UpdateType, @{Name="Action";Expression={$ActionDetails}} | Export-Csv -Path (Join-Path $LogDirectory "$LogFileName.csv") -Encoding UTF8 -NoTypeInformation -Append | Out-Null
                            }
                            Else{
                                $Update | Select-Object Title, LegacyName, UpdateClassificationTitle, @{Name="UpdateClassificationId";Expression={($_.GetUpdateClassification().Id -Join "`n")}} | Export-Csv -Path (Join-Path $LogDirectory "$LogFileName.csv") -Encoding UTF8 -NoTypeInformation -Append | Out-Null
                            }
                        }
                    }
                    Write-Verbose "$(Get-Date -Format F): [Wildcard] Denied: $DeclineUpdateCount"
                }
                "Windows 11 FU Exclude Languages" {
                    $Updates = @($UpdatesResult | Where-Object {$_.Title -match $DeclineRule.Filter} | Select-Object @{Name="Item";Expression={$_}}, @{Name="Language";Expression={$_.Title -match $DeclineRule.Filter | Out-Null; Return $Matches["Language"]}} | Where-Object Language -ne $Null)
                    Write-Verbose "$(Get-Date -Format F): [Windows 11 FU Exclude Languages] Updates.Count: $($Updates.Count) / UpdatesResult.Count: $($UpdatesResult.Count)"
                    Write-Verbose "$(Get-Date -Format F): [Windows 11 FU Exclude Languages] Filter: $($DeclineRule.Filter)"
                    Write-Verbose "$(Get-Date -Format F): [Windows 11 FU Exclude Languages] Exclude Languages:$($CurrentConfig.ChooseProducts.'Windows 11'.ExcludeLanguages)"
                    $DeclineUpdateCount = 0
                    $ActionDetails = ""

                    $Languages = ($CurrentConfig.ChooseProducts.'Windows 11'.ExcludeLanguages -split ",")
                    $Updates | Where-Object Language -notin $Languages | ForEach-Object{
                        $Update = $_.Item
                        $ActionDetails = "$($Update.Language) -notin $($CurrentConfig.ChooseProducts.'Windows 11'.ExcludeLanguages)"
                        $Update.Decline() | Out-Null
                        $DeclineUpdateCount++
                        
                        If ($CurrentConfig.Log.IsLogging){
                            If ($CurrentConfig.Log.Verbose){
                                $Update | Select-Object Title, @{Name="ProductTitles";Expression={($_.GetUpdateCategories().Title -Join "`n")}}, @{Name="ProductIds";Expression={($_.GetUpdateCategories().Id -Join "`n")}}, CreationDate, LegacyName, @{Name="Id.RevisionNumber";Expression={($_.Id.RevisionNumber -Join "`n")}}, @{Name="Id.UpdateId";Expression={($_.Id.UpdateId -Join "`n")}}, @{Name="KnowledgebaseArticles";Expression={($_.KnowledgebaseArticles -Join "`n")}}, @{Name="SecurityBulletins";Expression={($_.SecurityBulletins -Join "`n")}}, UpdateClassificationTitle, @{Name="UpdateClassificationId";Expression={($_.GetUpdateClassification().Id -Join "`n")}}, @{Name="ProductFamilyTitles";Expression={($_.ProductFamilyTitles -Join "`n")}}, UpdateType, @{Name="Action";Expression={$ActionDetails}} | Export-Csv -Path (Join-Path $LogDirectory "$LogFileName.csv") -Encoding UTF8 -NoTypeInformation -Append | Out-Null
                            }
                            Else{
                                $Update | Select-Object Title, LegacyName, UpdateClassificationTitle, @{Name="UpdateClassificationId";Expression={($_.GetUpdateClassification().Id -Join "`n")}} | Export-Csv -Path (Join-Path $LogDirectory "$LogFileName.csv") -Encoding UTF8 -NoTypeInformation -Append | Out-Null
                            }
                    }
                    }
                    Write-Verbose "$(Get-Date -Format F): [Windows 11 FU Exclude Languages] Denied: $DeclineUpdateCount"
                }
                "Windows 10 FU Exclude Languages" {
                    $Updates = @($UpdatesResult | Where-Object {$_.Title -match $DeclineRule.Filter} | Select-Object @{Name="Item";Expression={$_}}, @{Name="Language";Expression={$_.Title -match $DeclineRule.Filter | Out-Null; Return $Matches["Language"]}} | Where-Object Language -ne $Null)
                    Write-Verbose "$(Get-Date -Format F): [Windows 10 FU Exclude Languages] Updates.Count: $($Updates.Count) / UpdatesResult.Count: $($UpdatesResult.Count)"
                    Write-Verbose "$(Get-Date -Format F): [Windows 10 FU Exclude Languages] Filter: $($DeclineRule.Filter)"
                    Write-Verbose "$(Get-Date -Format F): [Windows 10 FU Exclude Languages] Exclude Languages:$($CurrentConfig.ChooseProducts.'Windows 10'.ExcludeLanguages)"
                    $DeclineUpdateCount = 0
                    $ActionDetails = ""

                    $Languages = ($CurrentConfig.ChooseProducts.'Windows 10'.ExcludeLanguages -split ",")
                    $Updates | Where-Object Language -notin $Languages | ForEach-Object{
                        $Update = $_.Item
                        $ActionDetails = "$($Update.Language) -notin $($CurrentConfig.ChooseProducts.'Windows 10'.ExcludeLanguages)"
                        $Update.Decline() | Out-Null
                        $DeclineUpdateCount++
                        
                        If ($CurrentConfig.Log.IsLogging){
                            If ($CurrentConfig.Log.Verbose){
                                $Update | Select-Object Title, @{Name="ProductTitles";Expression={($_.GetUpdateCategories().Title -Join "`n")}}, @{Name="ProductIds";Expression={($_.GetUpdateCategories().Id -Join "`n")}}, CreationDate, LegacyName, @{Name="Id.RevisionNumber";Expression={($_.Id.RevisionNumber -Join "`n")}}, @{Name="Id.UpdateId";Expression={($_.Id.UpdateId -Join "`n")}}, @{Name="KnowledgebaseArticles";Expression={($_.KnowledgebaseArticles -Join "`n")}}, @{Name="SecurityBulletins";Expression={($_.SecurityBulletins -Join "`n")}}, UpdateClassificationTitle, @{Name="UpdateClassificationId";Expression={($_.GetUpdateClassification().Id -Join "`n")}}, @{Name="ProductFamilyTitles";Expression={($_.ProductFamilyTitles -Join "`n")}}, UpdateType, @{Name="Action";Expression={$ActionDetails}} | Export-Csv -Path (Join-Path $LogDirectory "$LogFileName.csv") -Encoding UTF8 -NoTypeInformation -Append | Out-Null
                            }
                            Else{
                                $Update | Select-Object Title, LegacyName, UpdateClassificationTitle, @{Name="UpdateClassificationId";Expression={($_.GetUpdateClassification().Id -Join "`n")}} | Export-Csv -Path (Join-Path $LogDirectory "$LogFileName.csv") -Encoding UTF8 -NoTypeInformation -Append | Out-Null
                            }
                        }
                    }
                    Write-Verbose "$(Get-Date -Format F): [Windows 10 FU Exclude Languages] Denied: $DeclineUpdateCount"
                }
                "Decline Old Version" {
                    $Updates = @($UpdatesResult | Where-Object {$_.Title -match $DeclineRule.Filter} | Select-Object @{Name="Item";Expression={$_}}, @{Name="Version";Expression={$_.Title -match $DeclineRule.Filter | Out-Null; Return $Matches["Version"]}} | Where-Object Version -ne $Null)
                    $LatestVersion = @($Updates | Sort-Object {[Version]$_.Version} -Descending)[0].Version
                    Write-Verbose "$(Get-Date -Format F): [Decline Old Version] Updates.Count: $($Updates.Count) / UpdatesResult.Count: $($UpdatesResult.Count)"
                    Write-Verbose "$(Get-Date -Format F): [Decline Old Version] Filter: $($DeclineRule.Filter)"
                    Write-Verbose "$(Get-Date -Format F): [Decline Old Version] LatestVersion: $LatestVersion"
                    $DeclineUpdateCount = 0
                    $ActionDetails = ""

                    $Updates | Where-Object Version -ne $LatestVersion | ForEach-Object{
                        $Update = $_.Item
                        $ActionDetails = "$($Update.Version) < $LatestVersion"
                        $Update.Decline() | Out-Null
                        $DeclineUpdateCount++
                        
                        If ($CurrentConfig.Log.IsLogging){
                            If ($CurrentConfig.Log.Verbose){
                                $Update | Select-Object Title, @{Name="ProductTitles";Expression={($_.GetUpdateCategories().Title -Join "`n")}}, @{Name="ProductIds";Expression={($_.GetUpdateCategories().Id -Join "`n")}}, CreationDate, LegacyName, @{Name="Id.RevisionNumber";Expression={($_.Id.RevisionNumber -Join "`n")}}, @{Name="Id.UpdateId";Expression={($_.Id.UpdateId -Join "`n")}}, @{Name="KnowledgebaseArticles";Expression={($_.KnowledgebaseArticles -Join "`n")}}, @{Name="SecurityBulletins";Expression={($_.SecurityBulletins -Join "`n")}}, UpdateClassificationTitle, @{Name="UpdateClassificationId";Expression={($_.GetUpdateClassification().Id -Join "`n")}}, @{Name="ProductFamilyTitles";Expression={($_.ProductFamilyTitles -Join "`n")}}, UpdateType, @{Name="Action";Expression={$ActionDetails}} | Export-Csv -Path (Join-Path $LogDirectory "$LogFileName.csv") -Encoding UTF8 -NoTypeInformation -Append | Out-Null
                            }
                            Else{
                                $Update | Select-Object Title, LegacyName, UpdateClassificationTitle, @{Name="UpdateClassificationId";Expression={($_.GetUpdateClassification().Id -Join "`n")}} | Export-Csv -Path (Join-Path $LogDirectory "$LogFileName.csv") -Encoding UTF8 -NoTypeInformation -Append | Out-Null
                            }
                        }
                    }
                    Write-Verbose "$(Get-Date -Format F): [Decline Old Version] Denied: $DeclineUpdateCount"
                }
                "Decline Superseded" {
                    $Updates = @($UpdatesResult | Where-Object {$_.Title -match $DeclineRule.Filter -and $_.IsSuperseded} | Select-Object @{Name="Item";Expression={$_}})
                    Write-Verbose "$(Get-Date -Format F): [Decline Superseded] Updates.Count: $($Updates.Count) / UpdatesResult.Count: $($UpdatesResult.Count)"
                    Write-Verbose "$(Get-Date -Format F): [Decline Superseded] Filter: $($DeclineRule.Filter)"
                    $DeclineUpdateCount = 0
                    $ActionDetails = ""

                    $Updates | ForEach-Object{
                        $Update = $_.Item
                        $Update.Decline() | Out-Null
                        $DeclineUpdateCount++
                        
                        If ($CurrentConfig.Log.IsLogging){
                            If ($CurrentConfig.Log.Verbose){
                                $Update | Select-Object Title, @{Name="ProductTitles";Expression={($_.GetUpdateCategories().Title -Join "`n")}}, @{Name="ProductIds";Expression={($_.GetUpdateCategories().Id -Join "`n")}}, CreationDate, LegacyName, @{Name="Id.RevisionNumber";Expression={($_.Id.RevisionNumber -Join "`n")}}, @{Name="Id.UpdateId";Expression={($_.Id.UpdateId -Join "`n")}}, @{Name="KnowledgebaseArticles";Expression={($_.KnowledgebaseArticles -Join "`n")}}, @{Name="SecurityBulletins";Expression={($_.SecurityBulletins -Join "`n")}}, UpdateClassificationTitle, @{Name="UpdateClassificationId";Expression={($_.GetUpdateClassification().Id -Join "`n")}}, @{Name="ProductFamilyTitles";Expression={($_.ProductFamilyTitles -Join "`n")}}, UpdateType, @{Name="Action";Expression={$ActionDetails}} | Export-Csv -Path (Join-Path $LogDirectory "$LogFileName.csv") -Encoding UTF8 -NoTypeInformation -Append | Out-Null
                            }
                            Else{
                                $Update | Select-Object Title, LegacyName, UpdateClassificationTitle, @{Name="UpdateClassificationId";Expression={($_.GetUpdateClassification().Id -Join "`n")}} | Export-Csv -Path (Join-Path $LogDirectory "$LogFileName.csv") -Encoding UTF8 -NoTypeInformation -Append | Out-Null
                            }
                        }
                    }
                    Write-Verbose "$(Get-Date -Format F): [Decline Superseded] Denied: $DeclineUpdateCount"
                }
                default {
                    Write-Warning "[Deny-WsusFilteredUpdates] Not supported Mode: $($DeclineRule.Mode)"
                }
            }
        }
    }
    Function Get-WsusFilteredUpdates($DeclineRule, $UpdateScope, $RetryCount, $Month, $FindMode){
        $DeclineUpdateCount = 0

        If ($RetryCount -gt $CurrentConfig.UpdatesFindMode.MaximumRetry){
            Write-Verbose "$(Get-Date -Format F): [Get-WsusFilteredUpdates] skiped"
            Return
        }

        If (($CurrentConfig.UpdatesFindMode | Get-Member -Name 'ForceHalfModePerMonthLength').Count -eq 1){
            If ($Month -ne $Null){
                $UpdateScope.FromCreationDate = $Month
                $UpdateScope.ToCreationDate = $Month.AddMonths(1).AddSeconds(-1)
            }

            $UpdateCount = $WsusServer.GetUpdateCount($UpdateScope)

            If ($UpdateCount -eq 0){
                Switch ($FindMode){
                    ([UpdateFindMode]::H1){
                        Write-Verbose "$(Get-Date -Format F): [Get-WsusFilteredUpdates] Not found. $LogFileName updates $($Month.ToString("y")) (1/5)"
                    }
                    ([UpdateFindMode]::H2){
                        Write-Verbose "$(Get-Date -Format F): [Get-WsusFilteredUpdates] Not found. $LogFileName updates $($Month.ToString("y")) (2/5)"
                    }
                    ([UpdateFindMode]::H3){
                        Write-Verbose "$(Get-Date -Format F): [Get-WsusFilteredUpdates] Not found. $LogFileName updates $($Month.ToString("y")) (3/5)"
                    }
                    ([UpdateFindMode]::H4){
                        Write-Verbose "$(Get-Date -Format F): [Get-WsusFilteredUpdates] Not found. $LogFileName updates $($Month.ToString("y")) (4/5)"
                    }
                    ([UpdateFindMode]::H5){
                        Write-Verbose "$(Get-Date -Format F): [Get-WsusFilteredUpdates] Not found. $LogFileName updates $($Month.ToString("y")) (5/5)"
                    }
                    ([UpdateFindMode]::Full){
                        Write-Verbose "$(Get-Date -Format F): [Get-WsusFilteredUpdates] Not found. $LogFileName updates $($Month.ToString("y"))"
                    }
                    Default{
                        Write-Verbose "$(Get-Date -Format F): [Get-WsusFilteredUpdates] Not found. $LogFileName"
                    }
                }
                Return
            }
            ElseIf (($FindMode -eq $Null) -and ($UpdateCount -ge $CurrentConfig.UpdatesFindMode.ForceHalfModePerMonthLength)){
                Write-Verbose "$(Get-Date -Format F): [Get-WsusFilteredUpdates] Switch to split mode. $LogFileName updates count: $UpdateCount"
                ForEach($Month in $Months){
                    Get-WsusFilteredUpdates $DeclineRule $UpdateScope $RetryCount $Month ([UpdateFindMode]::Full)
                }
                Return
            }
            ElseIf (($Month -ne $Null) -and ($FindMode -eq ([UpdateFindMode]::Full)) -and ($UpdateCount -ge $CurrentConfig.UpdatesFindMode.ForceHalfModePerMonthLength)){
                Write-Verbose "$(Get-Date -Format F): [Get-WsusFilteredUpdates] Switch to split mode. $LogFileName updates count: $UpdateCount date: $($Month.ToString("y"))"
                Get-WsusFilteredUpdates $DeclineRule $UpdateScope $RetryCount $Month ([UpdateFindMode]::H1)
                Return
            }
        }

        Switch ($FindMode){
            ([UpdateFindMode]::H1){
                $UpdateScope.FromCreationDate = $Month
                $UpdateScope.ToCreationDate = $Month.AddDays(8).AddSeconds(-1)
                Write-Verbose "$(Get-Date -Format F): [Get-WsusFilteredUpdates] $LogFileName updates $($Month.ToString("y")) (1/5) Found: $($WsusServer.GetUpdateCount($UpdateScope))"
            }
            ([UpdateFindMode]::H2){
                $UpdateScope.FromCreationDate = $Month.AddDays(7)
                $UpdateScope.ToCreationDate = $Month.AddDays(15).AddSeconds(-1)
                Write-Verbose "$(Get-Date -Format F): [Get-WsusFilteredUpdates] $LogFileName updates $($Month.ToString("y")) (2/5) Found: $($WsusServer.GetUpdateCount($UpdateScope))"
            }
            ([UpdateFindMode]::H3){
                $UpdateScope.FromCreationDate = $Month.AddDays(14)
                $UpdateScope.ToCreationDate = $Month.AddDays(22).AddSeconds(-1)
                Write-Verbose "$(Get-Date -Format F): [Get-WsusFilteredUpdates] $LogFileName updates $($Month.ToString("y")) (3/5) Found: $($WsusServer.GetUpdateCount($UpdateScope))"
            }
            ([UpdateFindMode]::H4){
                $UpdateScope.FromCreationDate = $Month.AddDays(21)
                $UpdateScope.ToCreationDate = $Month.AddDays(28).AddSeconds(-1)
                Write-Verbose "$(Get-Date -Format F): [Get-WsusFilteredUpdates] $LogFileName updates $($Month.ToString("y")) (4/5) Found: $($WsusServer.GetUpdateCount($UpdateScope))"
            }
            ([UpdateFindMode]::H5){
                $UpdateScope.FromCreationDate = $Month.AddDays(28)
                $UpdateScope.ToCreationDate = $Month.AddMonths(1).AddSeconds(-1)
                Write-Verbose "$(Get-Date -Format F): [Get-WsusFilteredUpdates] $LogFileName updates $($Month.ToString("y")) (5/5) Found: $($WsusServer.GetUpdateCount($UpdateScope))"
            }
            ([UpdateFindMode]::Full){
                Write-Verbose "$(Get-Date -Format F): [Get-WsusFilteredUpdates] $LogFileName updates $($Month.ToString("y")) Found: $UpdateCount"
            }
            Default{
                Write-Verbose "$(Get-Date -Format F): [Get-WsusFilteredUpdates] $LogFileName updates Found: $UpdateCount"
            }
        }

        Try {
            $Updates = $WsusServer.GetUpdates($UpdateScope)

            If ([String]::IsNullOrEmpty($DeclineRule.Mode)){
                Write-Verbose "[Deny-WsusFilteredUpdates] Find TextIncludes (NotMode)"
                $Updates = $Updates | ForEach-Object {
                    $ActionDetails = ""
                    $Update = $_
                    $DeclineUpdateCount++
                    $Update.Decline()
                    If ($CurrentConfig.Log.IsLogging){
                        If ($CurrentConfig.Log.Verbose){
                            $Update | Select-Object Title, @{Name="ProductTitles";Expression={($_.GetUpdateCategories().Title -Join "`n")}}, @{Name="ProductIds";Expression={($_.GetUpdateCategories().Id -Join "`n")}}, CreationDate, LegacyName, @{Name="Id.RevisionNumber";Expression={($_.Id.RevisionNumber -Join "`n")}}, @{Name="Id.UpdateId";Expression={($_.Id.UpdateId -Join "`n")}}, @{Name="KnowledgebaseArticles";Expression={($_.KnowledgebaseArticles -Join "`n")}}, @{Name="SecurityBulletins";Expression={($_.SecurityBulletins -Join "`n")}}, UpdateClassificationTitle, @{Name="UpdateClassificationId";Expression={($_.GetUpdateClassification().Id -Join "`n")}}, @{Name="ProductFamilyTitles";Expression={($_.ProductFamilyTitles -Join "`n")}}, UpdateType, @{Name="Action";Expression={$ActionDetails}} | Export-Csv -Path (Join-Path $LogDirectory "$LogFileName.csv") -Encoding UTF8 -NoTypeInformation -Append | Out-Null
                        }
                        Else{
                            $Update | Select-Object Title, LegacyName, UpdateClassificationTitle, @{Name="UpdateClassificationId";Expression={($_.GetUpdateClassification().Id -Join "`n")}}, @{Name="Action";Expression={$ActionDetails}} | Export-Csv -Path (Join-Path $LogDirectory "$LogFileName.csv") -Encoding UTF8 -NoTypeInformation -Append | Out-Null
                        }
                    }
                }
            }
            $Global:UpdatesResult += $Updates
        }
        Catch{
            Write-Warning "$(Get-Date -Format F): [Get-WsusFilteredUpdates] $LogFileName updatesを取得できなかったため再試行します`n$($_.Exception)"

            $RetryCount++
            Get-WsusFilteredUpdates $DeclineRule $UpdateScope $RetryCount $Month $FindMode
        }

        Switch ($FindMode){
            ([UpdateFindMode]::H1){
                Write-Verbose "$(Get-Date -Format F): [Get-WsusFilteredUpdates] $LogFileName updates $($Month.ToString("y")) (1/5) Target: $DeclineUpdateCount"
                Get-WsusFilteredUpdates $DeclineRule $UpdateScope $RetryCount $Month ([UpdateFindMode]::H2)
            }
            ([UpdateFindMode]::H2){
                Write-Verbose "$(Get-Date -Format F): [Get-WsusFilteredUpdates] $LogFileName updates $($Month.ToString("y")) (2/5) Target: $DeclineUpdateCount"
                Get-WsusFilteredUpdates $DeclineRule $UpdateScope $RetryCount $Month ([UpdateFindMode]::H3)
            }
            ([UpdateFindMode]::H3){
                Write-Verbose "$(Get-Date -Format F): [Get-WsusFilteredUpdates] $LogFileName updates $($Month.ToString("y")) (3/5) Target: $DeclineUpdateCount"
                Get-WsusFilteredUpdates $DeclineRule $UpdateScope $RetryCount $Month ([UpdateFindMode]::H4)
            }
            ([UpdateFindMode]::H4){
                Write-Verbose "$(Get-Date -Format F): [Get-WsusFilteredUpdates] $LogFileName updates $($Month.ToString("y")) (4/5) Target: $DeclineUpdateCount"
                Get-WsusFilteredUpdates $DeclineRule $UpdateScope $RetryCount $Month ([UpdateFindMode]::H5)
            }
            ([UpdateFindMode]::H5){
                Write-Verbose "$(Get-Date -Format F): [Get-WsusFilteredUpdates] $LogFileName updates $($Month.ToString("y")) (5/5) Target: $DeclineUpdateCount"
            }
            ([UpdateFindMode]::Full){
                Write-Verbose "$(Get-Date -Format F): [Get-WsusFilteredUpdates] $LogFileName updates $($Month.ToString("y")) Target: $DeclineUpdateCount"
            }
            Default{
                Write-Verbose "$(Get-Date -Format F): [Get-WsusFilteredUpdates] $LogFileName updates Target: $DeclineUpdateCount"
            }
        }
        Return

    }
    Function Start-WsusServerSynchronization($WsusServer, $TimeOut){
        If ($TimeOut -eq $Null){
            $TimeOut = (Get-Date).AddMinutes(120)
        }
        Switch ($WsusServer.GetSubscription().GetSynchronizationStatus()){
            ([Microsoft.UpdateServices.Administration.SynchronizationStatus]::NotProcessing){
                If (-not $RunningStartWsusServerSynchronization){
                    $Global:RunningStartWsusServerSynchronization = $True
                    Write-Verbose "$(Get-Date -Format F): [Start-WsusServerSynchronization] Starting now..."
                    $WsusServer.GetSubscription().StartSynchronization()
                    Start-Sleep -Seconds 10
                    Start-WsusServerSynchronization -WsusServer $WsusServer -TimeOut $TimeOut
                }
                Else{
                    Write-Verbose "$(Get-Date -Format F): [Start-WsusServerSynchronization] Not processing."
                }
            }
            ([Microsoft.UpdateServices.Administration.SynchronizationStatus]::Running){
                $Global:RunningStartWsusServerSynchronization = $True
                If ((Get-Date) -ge $TimeOut){
                    Write-Error "$(Get-Date -Format F): [Start-WsusServerSynchronization] Timed out."
                }
                Else{
                    Write-Verbose "$(Get-Date -Format F): [Start-WsusServerSynchronization] Running now... $($WsusServer.GetSubscription().GetSynchronizationProgress().ProcessedItems) / $($WsusServer.GetSubscription().GetSynchronizationProgress().TotalItems)"
                    Start-Sleep -Seconds 10
                    Start-WsusServerSynchronization -WsusServer $WsusServer -TimeOut $TimeOut
                }
            }
            ([Microsoft.UpdateServices.Administration.SynchronizationStatus]::Stopping){
                If ((Get-Date) -ge $TimeOut){
                    Write-Error "$(Get-Date -Format F): [Start-WsusServerSynchronization] Timed out."
                }
                Else{
                    Write-Verbose "$(Get-Date -Format F): [Start-WsusServerSynchronization] Stopping now..."
                    Start-Sleep -Seconds 10
                    Start-WsusServerSynchronization -WsusServer $WsusServer -TimeOut $TimeOut
                }
            }
        }
        $Global:RunningStartWsusServerSynchronization = $False
    }
    Function Stop-WsusServerSynchronization($WsusServer, $TimeOut){
        If ($TimeOut -eq $Null){
            $TimeOut = (Get-Date).AddMinutes(10)
        }
        Switch ($WsusServer.GetSubscription().GetSynchronizationStatus()){
            ([Microsoft.UpdateServices.Administration.SynchronizationStatus]::NotProcessing){
                Write-Verbose "$(Get-Date -Format F): [Stop-WsusServerSynchronization] Already stopped."
            }
            ([Microsoft.UpdateServices.Administration.SynchronizationStatus]::Running){
                Write-Verbose "$(Get-Date -Format F): [Stop-WsusServerSynchronization] Stopping now..."
                $WsusServer.GetSubscription().StopSynchronization()
                Start-Sleep -Seconds 5
                Stop-WsusServerSynchronization -WsusServer $WsusServer -TimeOut $TimeOut
            }
            ([Microsoft.UpdateServices.Administration.SynchronizationStatus]::Stopping){
                If ((Get-Date) -ge $TimeOut){
                    Write-Error "$(Get-Date -Format F): [Stop-WsusServerSynchronization] Timed out."
                }
                Else{
                    Write-Verbose "$(Get-Date -Format F): [Stop-WsusServerSynchronization] Stopping now..."
                    Start-Sleep -Seconds 10
                    Stop-WsusServerSynchronization -WsusServer $WsusServer -TimeOut $TimeOut
                }
            }
        }
    }

    # Load config
    If ([String]::IsNullOrWhiteSpace($ConfigPath)){
        $TestConfigPathResult = $False
    }
    Else{
        $TestConfigPathResult = (Test-Path $ConfigPath -PathType Leaf)
    }
    If ($TestConfigPathResult){
        $Global:CurrentConfig = Get-Content $ConfigPath -Encoding UTF8 | ConvertFrom-Json
    }Else{
        Write-Error ([System.IO.FileNotFoundException]::new("Not found config. Check access to $ConfigPath")) -ErrorAction Stop
    }

    # Logging
    . (Join-Path (Get-Module Wsustainable).ModuleBase "Scripts\LogManager.ps1")
    Initialize-Directories
    Start-Logging

    # Initialize config
    $Global:CurrentConfig = Get-DeclineRules -Config $CurrentConfig
    If ($Verbose -or $CurrentConfig.Log.Verbose){
        $CurrentConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath (Join-Path $LogDirectory "InternalConfig.json") -Encoding UTF8
    }
    If (@($CurrentConfig.DeclineRules).Count -eq 0){
        Write-Warning "Not found decline rules"
    }

    # Load assemblies
    Import-Module UpdateServices
    If (@(Get-Module –Name UpdateServices).Count -eq 0){
        Write-Error "このスクリプトの動作に必要な UpdateServices が見つかりませんでした"
    }

    # Connect to WSUS server
    $WsusServer = Get-WsusServer -Name $CurrentConfig.Wsus.Server -PortNumber $CurrentConfig.Wsus.Port
    If ($WsusServer -eq $Null){
        Write-Error "WSUS サーバーに接続できませんでした" -ErrorAction Stop
        Break
    }
    If ($CurrentConfig.Wsus.PreferredCulture -ne $Null){
        $WsusServer.PreferredCulture = $CurrentConfig.Wsus.PreferredCulture
    }
    If ($CurrentConfig.Wsus.InvokeWsusSynchronization){
        Start-WsusServerSynchronization -WsusServer $WsusServer
    }
    Stop-WsusServerSynchronization -WsusServer $WsusServer

    $ApprovedStates = [Microsoft.UpdateServices.Administration.ApprovedStates]::unknown
    If ($FistLaunch){
        @($CurrentConfig.FistLaunch.ApprovedStates) | ForEach-Object {
            $ApprovedStates = $ApprovedStates -bor [Microsoft.UpdateServices.Administration.ApprovedStates]::$_
        }
    }
    Else{
        @($CurrentConfig.UpdatesFindMode.ApprovedStates) | ForEach-Object {
            $ApprovedStates = $ApprovedStates -bor [Microsoft.UpdateServices.Administration.ApprovedStates]::$_
        }
    }
    Write-Verbose "$(Get-Date -Format F): ApprovedStates is $ApprovedStates"
    If ($ApprovedStates -eq [Microsoft.UpdateServices.Administration.ApprovedStates]::unknown){
        Write-Verbose "$(Get-Date -Format F): ApprovedStates is NotApproved"
        $ApprovedStates = [Microsoft.UpdateServices.Administration.ApprovedStates]::NotApproved
    }


    $CurrentDate = [datetime]$CurrentConfig.UpdatesFindMode.MinimumDate
    $Months = @()
    Do{
        $Months += $CurrentDate
        $CurrentDate = $CurrentDate.AddMonths(1)
    }
    While($CurrentDate -lt (Get-Date -Day 1))

    $UpdateClassification = $WsusServer.GetUpdateClassifications()

    @($CurrentConfig.DeclineRules) | ForEach-Object {
        $DeclineRule = $_
        Write-Verbose "`n[DeclineRule] Mode: $($_.Mode), Product: $($_.Product), Version: $($_.Version), Type: $($_.Type), Architecture: $($_.Architecture)`n"
        # generate logfilename
        $Global:LogFileName = "$($_.Product)-$($_.Version)-$($_.Architecture)-$($_.Type)-$($_.Mode)"
        [System.IO.Path]::GetInvalidFileNameChars() | ForEach-Object {$Global:LogFileName = $LogFileName.Replace("$_","")}

        $UpdateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
        Try{
            $UpdateScope.ApprovedStates = $ApprovedStates

            @($DeclineRule.TargetProductId -split "`n") | ForEach-Object {
                $Category = $WsusServer.GetUpdateCategory($_)
                If ($Category -ne $Null){
                    $TargetProductTitle = $Category.Title
                    Write-Verbose "[DeclineRule] TargetProductTitle: $TargetProductTitle, TargetProductId: $_"
                    $UpdateScope.Categories.Add($Category) | Out-Null
                }Else{
                    Write-Warning "[DeclineRule] Not found TargetProductId: $_"
                }
            }
            @($DeclineRule.TargetClassifications -split "`n") | ForEach-Object {
                $UpdateClassification | Where-Object Id -eq $_ | ForEach-Object {
                    $UpdateScope.Classifications.Add($_) | Out-Null
                    Write-Verbose "[DeclineRule] TargetClassifications: $($_.Title), TargetProductId: $($_.Id)"
                }
            }
            Try{
                If (-not $_.Mode -and $CurrentConfig.ChooseProducts.($_.Product).FilterType -eq "Title"){
                    Write-Verbose "[DeclineRule] Set to TextIncludes: $($_.Filter)"
                    $UpdateScope.TextIncludes = $_.Filter
                }
                $Script:LatestDeclineUpdate = $Null
                Deny-WsusFilteredUpdates -DeclineRule $DeclineRule -UpdateScope $UpdateScope -RetryCount 0
            }
            Catch{
                Write-Error "$(Get-Date -Format F): $LogFileName `n$($_.Exception)"
            }
        }
        Catch{
            Write-Error "$(Get-Date -Format F): UpdateScope error $LogFileName `n$($_.Exception)"
        }
    }

    If ($CurrentConfig.DeclineOptions.CleanupWizard.CompressUpdates){
        #CleanupWizard: 不要な更新および更新のリビジョン
        Write-Verbose "[CleanupWizard] CompressUpdates: $($WsusServer | Invoke-WsusServerCleanup -CompressUpdates)"
    }
    If ($CurrentConfig.DeclineOptions.CleanupWizard.CleanupObsoleteUpdates){
        #CleanupWizard: 期限の切れた更新
        Write-Verbose "[CleanupWizard] CleanupObsoleteUpdates: $($WsusServer | Invoke-WsusServerCleanup -CleanupObsoleteUpdates)"
    }
    If ($CurrentConfig.DeclineOptions.CleanupWizard.CleanupObsoleteComputers){
        #CleanupWizard: サーバーにアクセスしていないコンピューター
        Write-Verbose "[CleanupWizard] CleanupObsoleteComputers: $($WsusServer | Invoke-WsusServerCleanup -CleanupObsoleteComputers)"
    }
    If ($CurrentConfig.DeclineOptions.CleanupWizard.CleanupUnneededContentFiles){
        #CleanupWizard: 不要な更新ファイル
        Write-Verbose "[CleanupWizard] CleanupUnneededContentFiles: $($WsusServer | Invoke-WsusServerCleanup -CleanupUnneededContentFiles)"
    }
    If ($CurrentConfig.DeclineOptions.CleanupWizard.DeclineExpiredUpdates){
        #CleanupWizard: 期限の切れた更新
        Write-Verbose "[CleanupWizard] DeclineExpiredUpdates: $($WsusServer | Invoke-WsusServerCleanup -DeclineExpiredUpdates)"
    }
    If ($CurrentConfig.DeclineOptions.CleanupWizard.DeclineSupersededUpdates){
        #CleanupWizard: 置き換えられた更新
        Write-Verbose "[CleanupWizard] DeclineSupersededUpdates: $($WsusServer | Invoke-WsusServerCleanup -DeclineSupersededUpdates)"
    }
    If ($CurrentConfig.DeclineOptions.ForceDeclineSupersededUpdates){
        #置き換えられた更新 (強制)
        $UpdateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
        $UpdateScope.ApprovedStates = [Microsoft.UpdateServices.Administration.ApprovedStates]::NotApproved
        $ActionDetails = ""
        $WsusServer.GetUpdates($UpdateScope) | Where-Object IsSuperseded | ForEach-Object {
            Try{
                $_.Decline()
                If ($CurrentConfig.Log.IsLogging){
                    If ($CurrentConfig.Log.Verbose){
                        $Update | Select-Object Title, @{Name="ProductTitles";Expression={($_.GetUpdateCategories().Title -Join "`n")}}, @{Name="ProductIds";Expression={($_.GetUpdateCategories().Id -Join "`n")}}, CreationDate, LegacyName, @{Name="Id.RevisionNumber";Expression={($_.Id.RevisionNumber -Join "`n")}}, @{Name="Id.UpdateId";Expression={($_.Id.UpdateId -Join "`n")}}, @{Name="KnowledgebaseArticles";Expression={($_.KnowledgebaseArticles -Join "`n")}}, @{Name="SecurityBulletins";Expression={($_.SecurityBulletins -Join "`n")}}, UpdateClassificationTitle, @{Name="UpdateClassificationId";Expression={($_.GetUpdateClassification().Id -Join "`n")}}, @{Name="ProductFamilyTitles";Expression={($_.ProductFamilyTitles -Join "`n")}}, UpdateType, @{Name="Action";Expression={$ActionDetails}} | Export-Csv -Path (Join-Path $LogDirectory "ForceDeclineSupersededUpdates.csv") -Encoding UTF8 -NoTypeInformation -Append | Out-Null
                    }
                    Else{
                        If ($IsMatch){
                            $Update | Select-Object Title, LegacyName, UpdateClassificationTitle, @{Name="UpdateClassificationId";Expression={($_.GetUpdateClassification().Id -Join "`n")}}, @{Name="Action";Expression={$ActionDetails}} | Export-Csv -Path (Join-Path $LogDirectory "DeclineSupersededUpdates.csv") -Encoding UTF8 -NoTypeInformation -Append | Out-Null
                        }
                    }
                }
            }
            Catch{
                Write-Error "$(Get-Date -Format F): 更新プログラムを取得できませんでした`n$($_.Exception)"
            }
        }
    }

    If ($CurrentConfig.MaintenanceSql.SqlCmdMode -eq "psmodule"){
        If ($CurrentConfig.MaintenanceSql.UpdateStatisticsAndDbccDbReIndex){
            Write-Verbose "[psmodule] UpdateStatisticsAndDbccDbReIndex: $(Invoke-Sqlcmd -ServerInstance (Get-WsusSqlServerName) -InputFile (Join-Path $PSScriptRoot '..\Assets\UpdateStatisticsAndDbccDbReIndex.sql') -Encrypt Optional)"
        }
        If ($CurrentConfig.MaintenanceSql.WsusDBMaintenance){
            Write-Verbose "[psmodule] WsusDBMaintenance: $(Invoke-Sqlcmd -ServerInstance (Get-WsusSqlServerName) -InputFile (Join-Path $PSScriptRoot '..\Assets\WsusDBMaintenance.sql') -Encrypt Optional)"
        }
    }
    Else{
        If ($CurrentConfig.MaintenanceSql.UpdateStatisticsAndDbccDbReIndex){
            Write-Verbose "[$($CurrentConfig.MaintenanceSql.SqlCmdMode)] UpdateStatisticsAndDbccDbReIndex: $((Start-Process (Get-SqlCmdPath) -ArgumentList "-S $(Get-WsusSqlServerName) -i ""$(Join-Path $PSScriptRoot '..\Assets\UpdateStatisticsAndDbccDbReIndex.sql')"" -Wait -NoNewWindow -PassThru").ExitCode)"
        }
        If ($CurrentConfig.MaintenanceSql.WsusDBMaintenance){
            Write-Verbose "[$($CurrentConfig.MaintenanceSql.SqlCmdMode)] WsusDBMaintenance: $((Start-Process (Get-SqlCmdPath) -ArgumentList "-S $(Get-WsusSqlServerName) -i ""$(Join-Path $PSScriptRoot '..\Assets\WsusDBMaintenance.sql')"" -Wait -NoNewWindow -PassThru").ExitCode)"
        }
    }

    If ($CurrentConfig.Log.IsLogging){
        If ($CurrentConfig.Log.Verbose){
            $UpdateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
            $UpdateScope.ApprovedStates = [Microsoft.UpdateServices.Administration.ApprovedStates]::NotApproved
            $ActionDetails = ""
            Try{
                $WsusServer.GetUpdates($UpdateScope) | Select-Object Title, @{Name="ProductTitles";Expression={($_.GetUpdateCategories().Title -Join "`n")}}, @{Name="ProductIds";Expression={($_.GetUpdateCategories().Id -Join "`n")}}, CreationDate, LegacyName, @{Name="Id.RevisionNumber";Expression={($_.Id.RevisionNumber -Join "`n")}}, @{Name="Id.UpdateId";Expression={($_.Id.UpdateId -Join "`n")}}, @{Name="KnowledgebaseArticles";Expression={($_.KnowledgebaseArticles -Join "`n")}}, @{Name="SecurityBulletins";Expression={($_.SecurityBulletins -Join "`n")}}, UpdateClassificationTitle, @{Name="UpdateClassificationId";Expression={($_.GetUpdateClassification().Id -Join "`n")}}, @{Name="ProductFamilyTitles";Expression={($_.ProductFamilyTitles -Join "`n")}}, UpdateType, @{Name="Action";Expression={$ActionDetails}} | Export-Csv -Path (Join-Path $LogDirectory "NotApproved.csv") -Encoding UTF8 -NoTypeInformation -Append | Out-Null
            }
            Catch{
                Write-Error "$(Get-Date -Format F): [NotApproved] 更新プログラムを取得できませんでした`n$($_.Exception)"
            }

            $UpdateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
            $UpdateScope.ApprovedStates = [Microsoft.UpdateServices.Administration.ApprovedStates]::HasStaleUpdateApprovals
            $ActionDetails = ""
            Try{
                $WsusServer.GetUpdates($UpdateScope) | Select-Object Title, @{Name="ProductTitles";Expression={($_.GetUpdateCategories().Title -Join "`n")}}, @{Name="ProductIds";Expression={($_.GetUpdateCategories().Id -Join "`n")}}, CreationDate, LegacyName, @{Name="Id.RevisionNumber";Expression={($_.Id.RevisionNumber -Join "`n")}}, @{Name="Id.UpdateId";Expression={($_.Id.UpdateId -Join "`n")}}, @{Name="KnowledgebaseArticles";Expression={($_.KnowledgebaseArticles -Join "`n")}}, @{Name="SecurityBulletins";Expression={($_.SecurityBulletins -Join "`n")}}, UpdateClassificationTitle, @{Name="UpdateClassificationId";Expression={($_.GetUpdateClassification().Id -Join "`n")}}, @{Name="ProductFamilyTitles";Expression={($_.ProductFamilyTitles -Join "`n")}}, UpdateType, @{Name="Action";Expression={$ActionDetails}} | Export-Csv -Path (Join-Path $LogDirectory "HasStaleUpdateApprovals.csv") -Encoding UTF8 -NoTypeInformation -Append | Out-Null
            }
            Catch{
                Write-Error "$(Get-Date -Format F): [HasStaleUpdateApprovals] 更新プログラムを取得できませんでした`n$($_.Exception)"
            }

            $UpdateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
            $UpdateScope.ApprovedStates = [Microsoft.UpdateServices.Administration.ApprovedStates]::LatestRevisionApproved
            $ActionDetails = ""
            Try{
                $WsusServer.GetUpdates($UpdateScope) | Select-Object Title, @{Name="ProductTitles";Expression={($_.GetUpdateCategories().Title -Join "`n")}}, @{Name="ProductIds";Expression={($_.GetUpdateCategories().Id -Join "`n")}}, CreationDate, LegacyName, @{Name="Id.RevisionNumber";Expression={($_.Id.RevisionNumber -Join "`n")}}, @{Name="Id.UpdateId";Expression={($_.Id.UpdateId -Join "`n")}}, @{Name="KnowledgebaseArticles";Expression={($_.KnowledgebaseArticles -Join "`n")}}, @{Name="SecurityBulletins";Expression={($_.SecurityBulletins -Join "`n")}}, UpdateClassificationTitle, @{Name="UpdateClassificationId";Expression={($_.GetUpdateClassification().Id -Join "`n")}}, @{Name="ProductFamilyTitles";Expression={($_.ProductFamilyTitles -Join "`n")}}, UpdateType, @{Name="Action";Expression={$ActionDetails}} | Export-Csv -Path (Join-Path $LogDirectory "HasStaleUpdateApprovals.csv") -Encoding UTF8 -NoTypeInformation -Append | Out-Null
            }
            Catch{
                Write-Error "$(Get-Date -Format F): [LatestRevisionApproved] 更新プログラムを取得できませんでした`n$($_.Exception)"
            }
        }
    }
    Stop-Logging
}
Export-ModuleMember -Function Optimize-WsusContents