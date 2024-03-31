#
# Enum
#
## Win32
enum Win32OperatingSystemProductType{
    WorkStation = 1
    DomainController = 2
    Server = 3
}
## ScheduledTask
[Flags()]Enum MSFT_ScheduledTaskDaysOfWeek{
    Sunday = 1
    Monday = 2
    Tuesday = 4
    Wednesday = 8
    Thursday = 16
    Friday = 32
    Saturday = 64
}
[Flags()]Enum MSFT_ScheduledTaskWeeksOfMonth{
    First = 1
    Second = 2
    Third = 4
    Fourth = 8
}
[Flags()]Enum MSFT_ScheduledTaskTrigger{
    Event = 0
    Time = 1
    Daily = 2
    Weekly = 3
    Monthly = 4
    MonthlyDayOfWeek = 5
    Idle = 6
    Registration = 7
    Boot = 8
    Logon = 9
    SessionStateChange = 11
    CustomTrigger01 = 12
}
[Flags()]Enum MSFT_TaskCreation{
    ValidateOnly = 1
    Create = 2
    Update = 4
    CreateOrUpdate = 6
    Disable = 8
    DontAddPrincipalAce = 16
    IgnoreRegistrationTriggers = 32
}
[Flags()]Enum MSFT_TaskLogonType{
    LogonNone = 0
    LogonPassword = 1
    LogonS4u = 2
    LogonInteractiveToken = 3
    LogonGroup = 4
    LogonServiceAccount = 5
    LogonInteractiveTokenOrPassword = 6
}
[Flags()]Enum MSFT_TaskMonthlyTriggerMonthsOfYear{
    January = 1
    February = 2
    March = 4
    April = 8
    May = 16
    June = 32
    July = 64
    August = 128
    September = 256
    October = 512
    November = 1024
    December = 2048
}


Function Global:Show-WsustainableSettingsView{
    Param(
        [String]$ConfigPath,
        [Switch]$Verbose,
        [Switch]$Debug
    )

    # Load config
    If ([String]::IsNullOrWhiteSpace($ConfigPath)){
        $TestConfigPathResult = $False
    }
    Else{
        $TestConfigPathResult = (Test-Path $ConfigPath  -PathType Leaf)
    }
    If ($TestConfigPathResult){
        $Global:CurrentConfig = Get-Content $ConfigPath -Encoding UTF8 | ConvertFrom-Json
    }Else{
        $ConfigPath = (Join-Path (Get-Module Wsustainable).ModuleBase "Assets\DefaultConfig.json")
        If (Test-Path $ConfigPath){
            $Global:CurrentConfig = Get-Content $ConfigPath -Encoding UTF8 | ConvertFrom-Json
        }
        Else{
            Write-Error ([System.IO.FileNotFoundException]::new("Not found default config. Check Assets\DefaultConfig.json in Wsustainable module directory.")) -ErrorAction Stop
        }
    }

    # Logging
    . (Join-Path (Get-Module Wsustainable).ModuleBase "Scripts\LogManager.ps1")
    Initialize-Directories
    Start-Logging

    # Load assemblies
    Add-Type -AssemblyName System,System.Core,System.Windows.Forms,PresentationFramework,PresentationCore,WindowsBase,WindowsFormsIntegration,System.Xml.Linq,System.Dynamic | Out-Null
    [Windows.Forms.Application]::EnableVisualStyles()
    [System.Environment]::CurrentDirectory = (Get-Location)
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Get-ChildItem -Path (Resolve-Path (Join-Path $PSScriptRoot "..\View\*.ps1")).Path | ForEach-Object { . $_}

    # Initialize module
    Get-ViewClass
    Get-MainWindow

    # Show window
    $DialogResult = ($MainWindow.ShowDialog())
    If ($DialogResult -eq $False){
        Write-Verbose "[MainWindow] Canceled"
    }
    Else{
        Write-Verbose "[MainWindow] $($DialogResult)"
        $MainWindow.Close()
    }
    
    Stop-Logging
}
Export-ModuleMember -Function Show-WsustainableSettingsView
