$File = "C:\temp\meta\output\example1.ps1"
[System.Collections.ArrayList]$Colors = (Get-Help -Name Write-Host -Parameter ForegroundColor | Out-String -Stream | Select-String -Pattern '- ' | Out-String).Split('-').Split().Where{$PSItem -notlike $null}

Remove-Item $File -ErrorAction SilentlyContinue

Write-Output "Write-Output 'Let the puppy killing commence'" | Add-Content -Path $File
Write-Output 'pause' | Add-Content -Path $File

foreach ($Num in 1..1000) {
    $string = 'Write-Host -ForegroundColor {0} -BackgroundColor {1} {2}' -f ($Colors | Get-Random),($Colors | Get-Random),$Num
    Write-Output $string | Add-Content -Path $File
}

#Now lets run the new example
Set-Location C:\temp\meta\output
.\example1.ps1