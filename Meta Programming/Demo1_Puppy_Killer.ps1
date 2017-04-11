$File = "C:\temp\meta\output\example1.ps1"
$Colors=@('Black','Blue','Cyan','DarkBlue','DarkCyan','DarkGray','DarkGreen','DarkMagenta','DarkRed')

Remove-Item $File -ErrorAction SilentlyContinue

Write-Output "Write-Output 'Let the puppy killing commence'" | Add-Content -Path $File
Write-Output 'pause' | Add-Content -Path $File

foreach ($Num in 1..500) {
    $string = 'Write-Host -ForegroundColor {0} {1}' -f ($Colors | Get-Random),$Num
    Write-Output $string | Add-Content -Path $File
}

#Now lets run the new example
Set-Location C:\temp\meta\output
.\example1.ps1