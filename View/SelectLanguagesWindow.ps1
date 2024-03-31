
Function Global:Initialize-SelectLanguagesWindowUI{
    Function Global:Set-LanguageList{
        Try{
            $FilterText = $SelectLanguagesWindow.FindName("FilterTextBox").Text
            If ([String]::IsNullOrEmpty($FilterText)){
                $SelectLanguagesWindow.FindName("LanguagesList").DataContext | ForEach-Object{ $_.Visible = $True }
            }
            Else{
                $FilteredLanguagesList = $SelectLanguagesWindow.FindName("LanguagesList").DataContext | Where-Object { $_.CultureInfo.LCID -like "*$FilterText*" -or $_.CultureInfo.DisplayName -like "*$FilterText*" -or $_.CultureInfo.EnglishName -like "*$FilterText*" }
                $SelectLanguagesWindow.FindName("LanguagesList").DataContext | ForEach-Object{ 
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
    
    $SelectLanguagesWindow.FindName("FilterTextBox").Add_TextChanged({
        Set-LanguageList
    })
    $SelectLanguagesWindow.Add_ContentRendered({
        $SelectLanguagesWindow.Dispatcher.Invoke({
            $SelectLanguagesWindow.FindName("FilterTextBox").Focus()
        })
    })
    $SelectLanguagesWindow.FindName("SaveButton").Add_Click({
        $SelectLanguagesWindow.DialogResult = $True
        $SelectLanguagesWindow.Close()
    })

}