
Function Global:Initialize-SelectLanguagesWindowUI{
    Function Global:Set-LanguageList{
        Try{
            $FilterText = $Global:SelectLanguagesWindow.FindName("FilterTextBox").Text
            If ([String]::IsNullOrEmpty($FilterText)){
                $Global:SelectLanguagesWindow.FindName("LanguagesList").DataContext | ForEach-Object{ $_.Visible = $True }
            }
            Else{
                $FilteredLanguagesList = $Global:SelectLanguagesWindow.FindName("LanguagesList").DataContext | Where-Object { $_.CultureInfo.Name -like "*$FilterText*" -or $_.CultureInfo.LCID -like "*$FilterText*" -or $_.CultureInfo.DisplayName -like "*$FilterText*" -or $_.CultureInfo.EnglishName -like "*$FilterText*" }
                $Global:SelectLanguagesWindow.FindName("LanguagesList").DataContext | ForEach-Object{ 
                    If ( $_.CultureInfo -in @($FilteredLanguagesList.CultureInfo) ){
                        $_.Visible = $True
                    }
                    Else{
                        $_.Visible = $False
                    }
                }
            }
        }
        Catch{}
    }
    
    $Global:SelectLanguagesWindow.FindName("FilterTextBox").Add_TextChanged({
        Set-LanguageList
    })
    $Global:SelectLanguagesWindow.Add_ContentRendered({
        $Global:SelectLanguagesWindow.Dispatcher.Invoke({
            $Global:SelectLanguagesWindow.FindName("FilterTextBox").Focus()
        })
    })
    $Global:SelectLanguagesWindow.FindName("SaveButton").Add_Click({
        $Global:SelectLanguagesWindow.DialogResult = $True
        $Global:SelectLanguagesWindow.Close()
    })
}