$File = "C:\temp\meta\output\example1.ps1"
#$Colors = @('Black','DarkBlue','DarkGreen','DarkCyan','DarkRed','DarkMagenta','DarkYellow','Gray','DarkGray','Blue','Green','Cyan','Red','Magenta','Yellow','White')
[System.Collections.ArrayList]$Colors = (Get-Help -Name Write-Host -Parameter ForegroundColor | Out-String -Stream | Select-String -Pattern '- ' | Out-String).Split('-').Split().Where{$PSItem -notlike $null}

Remove-Item $File -ErrorAction SilentlyContinue

Write-Output "Write-Output 'Let the puppy killing commence'" | Add-Content -Path $File
Write-Output "#Well it was fun while it lasted - https://twitter.com/jsnover/status/727902887183966208?lang=en"
Write-Output 'pause' | Add-Content -Path $File

foreach ($Num in 1..1000) {
    $string = 'Write-Host -ForegroundColor {0} -BackgroundColor {1} {2}' -f ($Colors | Get-Random),($Colors | Get-Random),$Num
    Write-Output $string | Add-Content -Path $File
}

#Now lets run the new example
Set-Location C:\temp\meta\output
.\example1.ps1
