Function Global:Get-ViewClass{
    $MenuCommandVb = Get-Content -Raw -Path (Resolve-Path (Join-Path $PSScriptRoot "..\TypeDefinition\MenuCommand.vb")).Path
    Add-Type -TypeDefinition $MenuCommandVb -Language VisualBasic -ReferencedAssemblies System,System.Core,System.Windows.Forms,PresentationFramework,PresentationCore,System.Linq,System.ObjectModel | Out-Null

    $LanguageItemVb = Get-Content -Raw -Path (Resolve-Path (Join-Path $PSScriptRoot "..\TypeDefinition\LanguageItem.vb")).Path
    Add-Type -TypeDefinition $LanguageItemVb -Language VisualBasic -ReferencedAssemblies WindowsBase,System,System.Core,System.Linq,System.ObjectModel | Out-Null

    $WindowsProductLifecycleItemVb = Get-Content -Raw -Path (Resolve-Path (Join-Path $PSScriptRoot "..\TypeDefinition\WindowsProductLifecycleItem.vb")).Path
    Add-Type -TypeDefinition $WindowsProductLifecycleItemVb -Language VisualBasic -ReferencedAssemblies WindowsBase,System,System.Core,System.Linq,System.ObjectModel | Out-Null

    $VisualStudioProductLifecycleItemVb = Get-Content -Raw -Path (Resolve-Path (Join-Path $PSScriptRoot "..\TypeDefinition\VisualStudioProductLifecycleItem.vb")).Path
    Add-Type -TypeDefinition $VisualStudioProductLifecycleItemVb -Language VisualBasic -ReferencedAssemblies WindowsBase,System,System.Core,System.Linq,System.ObjectModel | Out-Null

    $SchedukeTaskTriggerItemVb = Get-Content -Raw -Path (Resolve-Path (Join-Path $PSScriptRoot "..\TypeDefinition\SchedukeTaskTriggerItem.vb")).Path
    Add-Type -TypeDefinition $SchedukeTaskTriggerItemVb -Language VisualBasic -ReferencedAssemblies WindowsBase,System,System.Core,System.Linq,System.ObjectModel | Out-Null

    Write-Verbose "loaded assemblies:"
    $GetAssemblies = [System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object Location -eq "" | Select-Object FullName,@{Name="DefinedTypes";Expression={$a="";$_.DefinedTypes.SyncRoot.Name|%{$a+="$_, "};$a.Substring(0,$a.Length-2)}},@{Name="ExportedTypes";Expression={$a="";$_.ExportedTypes|%{$a+="$_,"};$a.Substring(0,$a.Length-2)}}
    $GetAssemblies | ForEach-Object{
        Write-Verbose "FullName: $($_.FullName)`nDefinedTypes: $($_.DefinedTypes)`nExportedTypes: $($_.ExportedTypes)"
    }
}

Function Global:Request-Job($Script, $DependentPs1File, $Arguments, $PSScriptRoot) {
    $Hash = [hashtable]::Synchronized(@{})
    $Hash.Host = $Host
    $Hash.Location = (Get-Location)
    $Hash.MainWindow = $MainWindow
    $Hash.ScheduledTaskName = $ScheduledTaskName
    $Hash.DetectiveInstalledComponents = $DetectiveInstalledComponents
    $Hash.CurrentConfig = $CurrentConfig
    $Hash.DependentPs1File = (Convert-Path $DependentPs1File)
    $Hash.Arguments = $Arguments
    $Hash.PSScriptRoot = $PSScriptRoot

    $Runspace = [RunspaceFactory]::CreateRunspace()
    $Runspace.ApartmentState = [System.Threading.ApartmentState]::STA
    $Runspace.ThreadOptions = [System.Management.Automation.Runspaces.PSThreadOptions]::ReuseThread
    $Runspace.Open()
    $Runspace.SessionStateProxy.SetVariable('Hash',$Hash)
    $Runspace.SessionStateProxy.SetVariable('Script',$Script)
    $Global:PowerShell = [PowerShell]::Create()

    $PowerShell.Runspace = $Runspace
    $PowerShell.AddScript({
        $Global:MainWindow = $Hash.MainWindow
        $Global:HostUi = $Hash.Host.Ui
        Set-Location $Hash.Location
        $Global:CurrentConfig = $Hash.CurrentConfig
        $Global:DependentPs1File = $Hash.DependentPs1File
        $Global:Arguments = $Hash.Arguments
        $Global:PSScriptRoot = $Hash.PSScriptRoot

        Invoke-Expression -Command 'Function Global:Write-Host($Text){$HostUi.WriteLine($Text)}' | Out-Null
        Invoke-Expression -Command 'Function Global:Write-Debug($Text){$HostUi.WriteDebugLine($Text)}' | Out-Null
        Invoke-Expression -Command 'Function Global:Write-Verbose($Text){$HostUi.WriteVerboseLine($Text)}' | Out-Null
        Invoke-Expression -Command 'Function Global:Write-Warning($Text){$HostUi.WriteWarningLine($Text)}' | Out-Null
        Invoke-Expression -Command 'Function Global:Write-Error($Text){$HostUi.WriteErrorLine($Text)}' | Out-Null

        Try{
            #. (Join-Path (Get-Module Wsustainable).ModuleBase "Scripts\LogManager.ps1") | Out-Null
            #. (Join-Path (Get-Module Wsustainable).ModuleBase "Scripts\Config.ps1") | Out-Null
            . (Resolve-Path (Join-Path $PSScriptRoot "..\Scripts\LogManager.ps1")).Path | Out-Null
            . (Resolve-Path (Join-Path $PSScriptRoot "..\Scripts\Config.ps1")).Path | Out-Null
            . $DependentPs1File | Out-Null
        }
        Catch{
            $HostUi.WriteErrorLine($PSItem.ToString())
            $HostUi.WriteErrorLine($PSItem.ScriptStackTrace)
        }

        Try{
            Initialize-Directories
            ##Start-Logging
            Invoke-Expression -Command "$Script" | Out-Null
        }
        Catch{
            $HostUi.WriteErrorLine($PSItem.ToString())
            $HostUi.WriteErrorLine($PSItem.ScriptStackTrace)
        }

    }) | Out-Null
    $PowerShell.BeginInvoke() | Out-Null
}

Function Global:Get-Xaml($Path){
    $XamlDocument = [System.Xml.Linq.XDocument]::Load($Path)
    # ResourceDictionaryのパスを指定
    $XamlDocument.Root.Descendants("{http://schemas.microsoft.com/winfx/2006/xaml/presentation}ResourceDictionary") | Where-Object HasAttributes | ForEach-Object{ If (Test-Path (Join-Path $PSScriptRoot "..\$($_.Attribute("Source").Value)")){$_.Attribute("Source").SetValue((Join-Path $PSScriptRoot "..\$($_.Attribute("Source").Value)"))} } 
    # 余分なAttributesの削除
    $XamlDocument.Root.Attributes() | Where-Object Name -like "{http://www.w3.org/2000/xmlns/}local" | ForEach-Object{ $_.Remove() }
    $XamlDocument.Root.Attributes() | Where-Object Name -like "{http://schemas.microsoft.com/winfx/2006/xaml}Class" | ForEach-Object{ $_.Remove() }
    $XamlDocument.Root.Attributes() | Where-Object Name -like "{http://schemas.openxmlformats.org/markup-compatibility/2006}Ignorable" | ForEach-Object{ $_.Remove() }
    $XamlDocument.Root.Attributes() | Where-Object Name -like "{http://schemas.microsoft.com/expression/blend/2008}*" | ForEach-Object{ $_.Remove() }
    ($XamlDocument.Root.DescendantNodes() | Where-Object HasAttributes).Attributes() | Where-Object Name -like "{http://schemas.microsoft.com/expression/blend/2008}*" | ForEach-Object{ $_.Remove() }
    Return [Windows.Markup.XamlReader]::Load($XamlDocument.CreateReader())
}

Function Global:Get-MainWindow(){
    $Global:MainWindow = Get-Xaml (Resolve-Path (Join-Path $PSScriptRoot "..\View\MainWindow.xaml")).Path

    Initialize-MainWindowUI
    Initialize-OptionTab
    Initialize-ServerTab
    Initialize-ServerConfigTab
    Initialize-SyncWindowsProductsTab
    Initialize-DeclineRuleTab
    Initialize-ApproveRuleOptionsTab
    Initialize-ScheduleTab
    Initialize-AboutTab

    $MainWindow.FindName("IndicatorRoot").Visibility = [System.Windows.Visibility]::Visible
    Request-Job -Script {Initialize-MainWindowUIJob} -DependentPs1File (Resolve-Path (Join-Path $PSScriptRoot "..\View\Initialize-MainWindowUIJob.Task.ps1")).Path -PSScriptRoot $PSScriptRoot | Out-Null
}

Function Global:Get-SelectLanguagesWindow(){
    $Global:SelectLanguagesWindow = Get-Xaml (Resolve-Path (Join-Path $PSScriptRoot "..\View\SelectLanguagesWindow.xaml")).Path

    Initialize-SelectLanguagesWindowUI
}