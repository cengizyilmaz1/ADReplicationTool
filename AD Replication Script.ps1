<#
=============================================================================================
Name = Cengiz YILMAZ
Date = 11.03.2023
www.cengizyilmaz.net
www.cozumpark.com/author/cengizyilmaz
============================================================================================
#>

# DC Servers
$servers = Get-ADDomainController -Filter *
 
# Folder Create
$reportFolder = "C:\ADReport"
If (!(Test-Path $reportFolder)) {
    New-Item $reportFolder -ItemType Directory
}
 
# HTML
$reportTitle = "<h2>Active Directory Report</h2>"
$reportTableHead = "<tr><th>Hostname</th><th>Site Name</th><th>FSMO Owner</th><th>Replication Time</th><th>Replication Test</th><th>Replication Server</th></tr>"
$reportTableBody = ""
 
# DC Servers Info
foreach ($server in $servers) {
 
    # FSMO
    $fsmoRoles = (Get-ADDomain).InfrastructureMaster, (Get-ADDomain).PDCEmulator, (Get-ADDomain).RIDMaster, (Get-ADDomain).SchemaMaster
    $isFsmoRoleOwner = If ($fsmoRoles -contains $server.HostName) { "True" } Else { "False" }
 
    # Replication Test
    $replicationResult = (Get-ADReplicationPartnerMetadata -Target $server.HostName -ErrorAction SilentlyContinue).LastReplicationSuccess
    If ($replicationResult) {
        If ($replicationResult.GetType().IsArray) {
            $replicationResult = [DateTime]$replicationResult[0]
        } Else {
            $replicationResult = [DateTime]$replicationResult
        }
    }
 
    $replicationStatus = If ($replicationResult) { "Pass" } Else { "Fail" }
    $replicationTimeSpan = If ($replicationResult) { ((Get-Date) - $replicationResult).TotalSeconds.ToString() + " Second " } Else { "" }
 
    # Replication To Servers
    $replicaServers = (Get-ADReplicationPartnerMetadata -Target $server.HostName -ErrorAction SilentlyContinue).Partner | Sort-Object
 
    # Table Create
    $tableRow = "<tr><td>$($server.HostName)</td><td>$((Get-ADReplicationSite -Identity $server.Site).Name)</td><td style='color: green'>$($isFsmoRoleOwner)</td><td>$($replicationTimeSpan)</td><td>$($replicationStatus)</td><td>$($replicaServers -join ', ')</td></tr>"
    $reportTableBody += $tableRow
}
 
# HTML Report Create
$reportHtml = "<html><head><style>table { border-collapse: collapse; font-family: Arial; } th, td { padding: 8px; text-align: left; border-bottom: 1px solid #ddd; } th { background-color: #4CAF50; color: white; } tr:nth-child(even) { background-color: #f2f2f2; } </style></head><body>" + $reportTitle + "<table>" + $reportTableHead + $reportTableBody + "</table></body></html>"
 
# HTML Report Save
$dateString = Get-Date -Format "yyyyMMdd-HHmmss"
 
$reportFilePath = "$($reportFolder)\ADReport_$($dateString).html"
 
Set-Content -Path $reportFilePath -Value $reportHtml
 
# HTML Report Location
Write-Host "Report was created: $reportFilePath" -ForegroundColor Red
