<#
.SYNOPSIS
Removes offline build agents in Azure DevOps fromthe Organization and Agent pool specified

.PARAMETER PAT
Required. The personal access token for Azure DevOps

.PARAMETER OrganizationName
Required. The Azure DevOps organization name

.PARAMETER AgentPoolName
Required. The Azure DevOps agent pool name

.EXAMPLE
.\Remove-OfflineAgents.ps1 -PAT 'sdfkjsdf892349mfidf983294jkldf832894234sdsdgdfg' -OrganizationName 'My-Super-Cool-DevOps-Org' -AgentPoolName 'My-Super-Sweet-Agent-Pool'
#>
param(
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$PAT,

  [Parameter(Mandatory = $true)]
  [string]$OrganizationName,

  [Parameter(Mandatory = $true)]
  [string]$AgentPoolName,

  [Parameter(Mandatory = $false)]
  [string]$ApiVersion = '5.1'
)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$EncodedPAT = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(":$PAT"))
$PoolsUrl = "https://dev.azure.com/$($OrganizationName)/_apis/distributedtask/pools?api-version=$($ApiVersion)"
try {
  $Pools = (Invoke-RestMethod -Uri $PoolsUrl -Method 'Get' -Headers @{Authorization = "Basic $EncodedPAT"}).value
} catch {
  throw $_.Exception
}

If ($Pools) {
  $PoolId = ($Pools | Where-Object { $_.Name -eq $AgentPoolName }).id
  $AgentsUrl = "https://dev.azure.com/$($OrganizationName)/_apis/distributedtask/pools/$($PoolId)/agents?api-version=$($ApiVersion)"
  $Agents = (Invoke-RestMethod -Uri $AgentsUrl -Method 'Get' -Headers @{Authorization = "Basic $EncodedPAT"}).value
  if ($Agents) {
    $AgentNames = ($Agents | Where-Object { $_.status -eq 'Offline'}).Name
    Write-Output "Printing all offline agents for informational purposes"
    foreach ($AgentName in $AgentNames) {
        Write-Output "Removing: $($AgentName) From Pool: $($AgentPoolName) in Organization: $($OrganizationName)"
    
    $OfflineAgents = ($Agents | Where-Object { $_.status -eq 'Offline'}).id
    foreach ($OfflineAgent in $OfflineAgents) {
        Write-Output "Removing: $($OfflineAgent) ID From Pool: $($AgentPoolName) in Organization: $($OrganizationName)"
        $OfflineAgentsUrl = "https://dev.azure.com/$($OrganizationName)/_apis/distributedtask/pools/$($PoolId)/agents/$($OfflineAgent)?api-version=$($ApiVersion)"
        Invoke-RestMethod -Uri $OfflineAgentsUrl -Method 'Delete' -Headers @{Authorization = "Basic $EncodedPAT"}
      }
    }
  } else {
    Write-Output "No Agents found in $($AgentPoolName) for Organization $($OrganizationName)"
  }
} else {
  Write-Output "No Pools named $($AgentPoolName) found in Organization $($OrganizationName)"
}
