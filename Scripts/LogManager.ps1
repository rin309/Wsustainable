
Function Global:Initialize-Directories{
    $Global:ProgramDataDirectory = "$env:ProgramData\Wsustainable\0.2"
    New-Item -Path $ProgramDataDirectory -ItemType Directory -Force | Out-Null
    New-Item -Path (Join-Path $ProgramDataDirectory "Installers") -ItemType Directory -Force | Out-Null
    New-Item -Path (Join-Path $ProgramDataDirectory "Logs") -ItemType Directory -Force | Out-Null
}

Function Global:Start-Logging{
	$Global:LastVerbosePreference = $VerbosePreference
	$Global:LastDebugPreference = $DebugPreference
    If ($Verbose -or $CurrentConfig.Log.Verbose){
        $Global:VerbosePreference = 'Continue'
    }
    If ($Debug -or $CurrentConfig.Log.Debug){
        $Global:DebugPreference = 'Continue'
    }

	If ($CurrentConfig.Log.IsLogging){
        $StartTime = (Get-Date –F s).Replace(':','')
		If ([String]::IsNullOrEmpty($LogDirectory)){
			$Global:LogDirectory = Join-Path $ProgramDataDirectory "Logs\$StartTime"
		}
		New-Item $LogDirectory -ItemType Directory -Force | Out-Null
        Start-Transcript (Join-Path $LogDirectory "Transcript.log")

    	$CurrentConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath (Join-Path $LogDirectory "Config.json") -Encoding UTF8

		$LogsDirectoryChildItems = (Get-ChildItem (Join-Path $ProgramDataDirectory "Logs") -Directory -Filter "20*")
		If ($LogsDirectoryChildItems.Length -gt $CurrentConfig.Log.MaximumCount){
			ForEach ($LogsDirectoryChildItem in $LogsDirectoryChildItems){
				#西暦上2桁"20"から始まるディレクトリを検索
                If ((Get-ChildItem (Join-Path $ProgramDataDirectory "Logs") -Directory -Filter "20*").Length -le $CurrentConfig.Log.MaximumCount){
					break
				}
                $LogsDirectoryChildItem | Remove-Item -Recurse -Force
			}
		}
	}
}

Function Global:Stop-Logging{
	Try{
		Stop-Transcript
		$Global:VerbosePreference = $LastVerbosePreference
		$Global:DebugPreference = $LastDebugPreference
	}
	Catch{}
}
