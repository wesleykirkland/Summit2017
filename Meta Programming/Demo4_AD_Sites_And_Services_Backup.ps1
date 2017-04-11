Set-Location C:\temp\meta
$File4 = "C:\temp\meta\output\example4.ps1"

#$ADReplicationSites = Get-ADReplicationSite -Filter * #Only run this if on the VPN

$arrayfile = @()
$arrayfile += 'Write-Warning this will restore a backup of AD sites and services subnets'
$arrayfile += ''

foreach ($Site in $ADReplicationSites) {
    #Find all the subnets
    $temp = $Site.Name
    $ADReplicationSubnets = Get-ADReplicationSubnet -Filter {(Site -eq $temp)}

    $arrayfile += "#Building command to build the Site $($Site.Name)" #Add a comment to the file
    $arrayfile += "Set-ADReplicationSite -Identity $($Site.Name) -AutomaticInterSiteTopologyGenerationEnabled $true"

    foreach ($Subnet in $ADReplicationSubnets) {
        #$arrayfile += "#Building command to build the subnet $($Subnet.Name)" #Add a comment to the file
        $arrayfile += "Set-ADReplicationSubnet -Site $($Site.Name) -Identity '$($Subnet.Name)'$(if ($Site.Location) {" -Location '$($Site.Location)'"}) -ErrorAction SilentlyContinue" #Add location if it exists via a subexpression
    }

    $arrayfile += ''
    Remove-Variable ADReplicationSubnets -ErrorAction SilentlyContinue
}

$arrayfile += "Write-Output 'End of the restore script'"
$arrayfile | Out-File .\output\example4.ps1