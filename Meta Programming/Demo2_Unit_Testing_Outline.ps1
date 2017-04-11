Set-Location C:\temp\meta
$File2 = "C:\temp\meta\output\example2.ps1"
Remove-Item $File2 -ErrorAction SilentlyContinue
$ModuleToBuildTests = 'AWSPowerShell'

$arrayfile = @()
$arrayfile += 'Describe "Unit testing outline" {'

$ModuleCmdlets = Get-Command -Verb Get -Module $ModuleToBuildTests | Select-Object -ExpandProperty Name

foreach ($Cmdlet in $ModuleCmdlets) {
    $arrayfile += '     It "Testing {0} in the module of {1}"' -f $Cmdlet,$ModuleToBuildTests
    $arrayfile += '          ({0}) | Should Be' -f $Cmdlet
    $arrayfile += '     }'
    if (!($Cmdlet -eq $ModuleCmdlets[-1])) {
        $arrayfile += ''
    }
}

$arrayfile += '}'

$File | Add-Content -Path $File2

#Our code should look like this
<#
Describe "Do Something" { 
    It "accepts pipeline input" { 
        (1,2,3 | Do-Something).Count | Should Be 3 
    } 
  
    It "adds correctly" { 
        $result = Do-Something -Value1 1 -Value2 2 
        $result | Should Be 3 
        $result.Count | Should Be 1 
    } 
}
#>