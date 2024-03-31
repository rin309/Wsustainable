Function Global:Test-InternetConnections{
    $MainWindow.Dispatcher.Invoke({
        $MainWindow.FindName("InternetConnectionFailure").Visibility = [System.Windows.Visibility]::Collapsed
    })
    $TestResult = @()
    $TestResult += (Test-InternetConnection)
    If ($False -notin $TestResult){
        $MainWindow.Dispatcher.Invoke({
            Write-Verbose "Internet connection successfully established"
        })
    }
}

Function Global:Test-InternetConnection{
    Try{
        $INetworkListManager = [Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]"{DCB00C01-570F-4A9B-8D69-199FDBA5723B}"))
        If (-not @($INetworkListManager.GetNetworkConnections())[0].IsConnectedToInternet){
            Write-Warning "Internet connection failed"
            $MainWindow.FindName("InternetConnectionFailure").Visibility = [System.Windows.Visibility]::Visible
            Return $False
        }
    }
    Catch{
        $MainWindow.Dispatcher.Invoke({
            Write-Warning "Internet connection failed: $($_.Exception.Message)"
            $MainWindow.FindName("InternetConnectionFailure").Visibility = [System.Windows.Visibility]::Visible
        })
        Return $False
    }
}

