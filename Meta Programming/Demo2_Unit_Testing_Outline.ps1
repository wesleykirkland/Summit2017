Set-Location C:\temp\meta
$File2 = "C:\temp\meta\output\example2.ps1"
Remove-Item $File2 -ErrorAction SilentlyContinue
$ModuleToBuildTests = 'AWSPowerShell'

[System.Collections.ArrayList]$arrayfile = @()
$arrayfile.Add('Describe "Unit testing outline" {') | Out-Null

$ModuleCmdlets = Get-Command -Verb Get -Module $ModuleToBuildTests | Select-Object -ExpandProperty Name

foreach ($Cmdlet in $ModuleCmdlets) {
    $arrayfile.Add(('     It "Testing {0} in the module of {1}"' -f $Cmdlet,$ModuleToBuildTests)) | Out-Null
    $arrayfile.Add(('          ({0}) | Should Be' -f $Cmdlet)) | Out-Null
    $arrayfile.Add('     }') | Out-Null
    
    if (!($Cmdlet -eq $ModuleCmdlets[-1])) {
        $arrayfile += ''
    }
}

$arrayfile.Add('}') | Out-Null

$arrayfile | Add-Content -Path $File2

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