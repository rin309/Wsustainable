Get-ChildItem -Path (Join-Path $PSScriptRoot "Scripts\*.ps1") | ForEach-Object { . $_}
Import-LocalizedData -BindingVariable OptimizeWsusContentsMessageTable -BaseDirectory (Join-Path $PSScriptRoot "Resources") -FileName "Optimize-WsusContents.psd1"
