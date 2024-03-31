﻿Enum UpdateFindMode{
    Unknown
    Full
    H1
    H2
    H3
    H4
    H5
}


Function Global:Get-DeclineRules($Config){
    $DeclineRules = @()

    #
    # Windows 11
    #
    If ($Config.ChooseProducts.'Windows 11'.Configure){
        ## Filter table
        $Filter = $Null
        #$Filter = Import-Csv "..\Wsustainable\DeclineFilters\Windows 11.csv" -Encoding UTF8
        $Filter = Import-Csv (Join-Path (Get-Module Wsustainable).ModuleBase "\DeclineFilters\Windows 11.csv") -Encoding UTF8

        ## Quality Updates
        $Config.ChooseVersions.'Windows 11' | ForEach-Object {
            $ChooseVersion = $_
            $Filter | Where-Object { 
                $_.Version -eq $ChooseVersion.Version -and # version
                (-not $ChooseVersion.($_.Architecture)) -and ($True -in $Config.ChooseVersions.'Windows 11'.($_.Architecture)) -and # architecture
                $_.Type -ne "All" -and # type
                ($_.RegexMode -ne "Windows 11 FU Exclude Languages") # filtertype
            } | ForEach-Object {
                $DeclineRules += $_
            }
        }
        ## Volume
        If (-not $Config.ChooseProducts.'Windows 11'.BusinessUpgrade){
            $Config.ChooseVersions.'Windows 11' | ForEach-Object {
                $ChooseVersion = $_
                $Filter | Where-Object {
                    $_.Type -eq "BusinessUpgrade" -and ($True -in $Config.ChooseVersions.'Windows 11'.($_.Architecture)) -and # architecture
                    ($_.RegexMode -ne "Windows 11 FU Exclude Languages") # filtertype
                } | ForEach-Object {
                    $DeclineRules += $_
                }
            }
        }
        ## Retail
        If (-not $Config.ChooseProducts.'Windows 11'.ConsumerUpgrade){
            $Config.ChooseVersions.'Windows 11' | ForEach-Object {
                $ChooseVersion = $_
                $Filter | Where-Object {
                    $_.Type -eq "ConsumerUpgrade" -and # type
                    ($_.RegexMode -ne "Windows 11 FU Exclude Languages") # filtertype
                } | ForEach-Object {
                    $DeclineRules += $_
                }
            }
        }
        ## Upgrades
        If ($Config.ChooseProducts.'Windows 11'.ExcludeLanguages -ne $Null){
            $Config.ChooseVersions.'Windows 11' | ForEach-Object {
                $ChooseVersion = $_
                $Filter | Where-Object {
                    $_.Version -eq $ChooseVersion.Version -and # version
                    ($ChooseVersion.($_.Architecture)) -and ($True -in $Config.ChooseVersions.'Windows 11'.($_.Architecture)) -and # architecture
                    ($_.Type -eq "BusinessUpgrade" -or $_.Type -eq "ConsumerUpgrade") -and # type
                    $_.RegexMode -eq "Windows 11 FU Exclude Languages" # filtertype
                } | ForEach-Object {
                    $DeclineRules += $_
                }
            }
        }
        # All
        $Filter | Where-Object { 
            ($True -notin $Config.ChooseVersions.'Windows 11'.($_.Architecture)) -and # architecture
            $_.Type -eq "All" -and # type
            ($_.RegexMode -ne "Windows 11 FU Exclude Languages") # filtertype
        } | ForEach-Object {
            $DeclineRules += $_
        }

    }

    #
    # Windows 10
    #
    If ($Config.ChooseProducts.'Windows 10'.Configure){
        #
    }


    #
    # Microsoft Edge
    #
    ## decline channel
    If ($Config.ChooseProducts.'Microsoft Edge'.Configure){
        ## Filter table
        $Filter = $Null
        #$Filter = Import-Csv "..\Wsustainable\DeclineFilters\Microsoft Edge.csv" -Encoding UTF8
        $Filter = Import-Csv (Join-Path (Get-Module Wsustainable).ModuleBase "\DeclineFilters\Microsoft Edge.csv") -Encoding UTF8

        ## decline channel
        $Config.ChooseVersions.'Microsoft Edge' | ForEach-Object {
            $ChooseVersion = $_
            $Filter | Where-Object { 
                    ($_.Architecture -eq "all") -and # architecture
                    (-not $Config.ChooseProducts.'Microsoft Edge'.($_.Type)) -and # type
                    (-not $_.RegexMode) # filtertype
                } | ForEach-Object {
                    $DeclineRules += $_
                }
        }
        ## decline architecture
        $Config.ChooseVersions.'Microsoft Edge' | ForEach-Object {
            $ChooseVersion = $_
            $Filter | Where-Object {
                    ($_.Architecture -ne "all") -and # exclude first choice
                    (-not $Config.ChooseProducts.'Microsoft Edge'.($_.Architecture)) -and # architecture
                    $Config.ChooseProducts.'Microsoft Edge'.($_.Type) -and # type
                    (-not $_.RegexMode) # filtertype
                } | ForEach-Object {
                    $DeclineRules += $_
                }
        }
        ## decline old version
        If ($Config.ChooseProducts.'Microsoft Edge'.DeclineOldVersion){
            $Config.ChooseVersions.'Microsoft Edge' | ForEach-Object {
                $ChooseVersion = $_
                $Filter | Where-Object { 
                    ($_.Architecture -ne "all") -and # exclude first choice
                    ($Config.ChooseProducts.'Microsoft Edge'.($_.Architecture)) -and # architecture
                    $Config.ChooseProducts.'Microsoft Edge'.($_.Type) -and # type
                    $_.RegexMode # filtertype
                } | ForEach-Object {
                    $DeclineRules += $_
                }
            }
        }
    }


    #
    # Malicious Software Removal Tool
    #
    If ($Config.ChooseProducts.'Malicious Software Removal Tool'.Configure){
        ## Filter table
        $Filter = $Null
        #$Filter = Import-Csv "..\Wsustainable\DeclineFilters\Malicious Software Removal Tool.csv" -Encoding UTF8
        $Filter = Import-Csv (Join-Path (Get-Module Wsustainable).ModuleBase "\DeclineFilters\Malicious Software Removal Tool.csv") -Encoding UTF8

        ## decline architecture
        $Config.ChooseVersions.'Malicious Software Removal Tool' | ForEach-Object {
            $ChooseVersion = $_
            $Filter | Where-Object {
                    (-not $Config.ChooseProducts.'Malicious Software Removal Tool'.($_.Architecture)) -and # architecture
                    (-not $_.RegexMode) # filtertype
                } | ForEach-Object {
                    $DeclineRules += $_
                }
        }
        ## decline old version
        If ($Config.ChooseProducts.'Malicious Software Removal Tool'.DeclineOldVersion){
            $Config.ChooseVersions.'Malicious Software Removal Tool' | ForEach-Object {
                $ChooseVersion = $_
                $Filter | Where-Object { 
                    ($Config.ChooseProducts.'Malicious Software Removal Tool'.($_.Architecture)) -and # architecture
                    $Config.ChooseProducts.'Malicious Software Removal Tool'.($_.Type) -and # type
                    $_.RegexMode # filtertype
                } | ForEach-Object {
                    $DeclineRules += $_
                }
            }
        }
    }


    #
    # Microsoft Defender Antivirus
    #
    If ($Config.ChooseProducts.'Microsoft Defender Antivirus'.Configure){
        ## Filter table
        $Filter = $Null
        #$Filter = Import-Csv "..\Wsustainable\DeclineFilters\Microsoft Defender Antivirus.csv" -Encoding UTF8
        $Filter = Import-Csv (Join-Path (Get-Module Wsustainable).ModuleBase "\DeclineFilters\Microsoft Defender Antivirus.csv") -Encoding UTF8

        ## decline old version
        If ($Config.ChooseProducts.'Microsoft Defender Antivirus'.DeclineOldVersion){
            $DeclineRules += $Filter
        }

    }


    #
    # Office
    #
    If ($Config.ChooseProducts.'Office'.Configure){
        ## Filter table
        $Filter = $Null
        #$Filter = Import-Csv "..\Wsustainable\DeclineFilters\Office.csv" -Encoding UTF8
        $Filter = Import-Csv (Join-Path (Get-Module Wsustainable).ModuleBase "\DeclineFilters\Office.csv") -Encoding UTF8

        ## decline architecture
        $Config.ChooseVersions.'Office' | ForEach-Object {
            $ChooseVersion = $_
            $Filter | Where-Object {
                    (-not $Config.ChooseProducts.'Office'.($_.Architecture)) # architecture
                } | ForEach-Object {
                    $DeclineRules += $_
                }
        }
    }


    #
    # Visual Studio
    #
    If ($Config.ChooseProducts.'Visual Studio'.Configure){
        #
    }


    #
    # TEMPLATE
    #
    If ($Config.ChooseProducts.'TEMPLATE'.Configure){
        #
    }


    $CurrentConfig.DeclineRules = ($DeclineRules | Sort-Object Product, Version, Architecture, Type) #-Unique)
    Return $CurrentConfig
}

Function Global:Set-RequiredConfigurationValues($Config){

    $UpdateServiceInstalledRoleServicesPath = "HKLM:\\SOFTWARE\Microsoft\Update Services\Server\Setup\Installed Role Services"
    If ([String]::IsNullOrEmpty($Config.MaintenanceSql.ServerInstancePath) -and (Test-Path $UpdateServiceInstalledRoleServicesPath)){
        #
    }

    If ([String]::IsNullOrEmpty($Config.MaintenanceSql.SqlCmdExeMode) -or -not $Config.MaintenanceSql.SqlCmdExeMode -in @("psmodule","exe")){
        Try{
            Import-Module SqlServer -ErrorAction Stop
            $Config.MaintenanceSql.SqlCmdExeMode = "psmodule"
        }
        Catch{
            $Config.MaintenanceSql.SqlCmdExeMode = "exe"
        }
        Write-Verbose "[Set-RequiredConfigurationValues] Config.MaintenanceSql.SqlCmdExeMode を $($Config.MaintenanceSql.SqlCmdExeMode) に変更しました"
    }

}
