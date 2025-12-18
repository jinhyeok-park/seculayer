$scriptPath = "C:\Users\SL-2024040801\Scripts\create_patch.ps1"
$content = Get-Content $scriptPath -Raw -Encoding UTF8
$utf8WithBom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($scriptPath, $content, $utf8WithBom)
Write-Host "File saved as UTF-8 BOM" -ForegroundColor Green
