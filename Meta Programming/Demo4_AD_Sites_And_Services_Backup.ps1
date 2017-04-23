Set-Location C:\temp\meta
$File4 = "C:\temp\meta\output\example4.ps1"

#$ADReplicationSites = Get-ADReplicationSite -Filter * #Only run this if on the VPN

[System.Collections.ArrayList]$arrayfile = @()
$arrayfile.Add('Write-Warning this will restore a backup of AD sites and services subnets') | Out-Null
$arrayfile.Add('') | Out-Null

foreach ($Site in $ADReplicationSites) {
    #Find all the subnets
    $temp = $Site.Name
    $ADReplicationSubnets = Get-ADReplicationSubnet -Filter {(Site -eq $temp)}

    $arrayfile.Add("#Building command to build the Site $($Site.Name)") | Out-Null #Add a comment to the file
    $arrayfile.Add("Set-ADReplicationSite -Identity $($Site.Name) -AutomaticInterSiteTopologyGenerationEnabled $true") | Out-Null

    foreach ($Subnet in $ADReplicationSubnets) {
        #$arrayfile.Add("#Building command to build the subnet $($Subnet.Name)") | Out-Null #Add a comment to the file
        $arrayfile.Add("Set-ADReplicationSubnet -Site $($Site.Name) -Identity '$($Subnet.Name)'$(if ($Site.Location) {" -Location '$($Site.Location)'"}) -ErrorAction SilentlyContinue") | Out-Null #Add location if it exists via a subexpression
    }

    $arrayfile.Add('') | Out-Null
    Remove-Variable ADReplicationSubnets -ErrorAction SilentlyContinue
}

$arrayfile.Add("Write-Output 'End of the restore script'") | Out-Null
$arrayfile | Out-File .\output\example4.ps1