Set-Location $PSScriptRoot
Describe 'Remove Offline Agents' {
  BeforeEach {
    $bogusPAT = 'sdfkjsdf892349mfidf983294jkldf832894234sdsdgdfg'

    Mock Invoke-RestMethod {
      return @{
        "value" = @(
          @{
            "createdOn" = "2019-07-16T14:52:14.88Z"
            "autoProvision" = "True"
            "autoSize"      = "True"
            "targetSize"    = 1
            "agentCloudId"  = 1
            "createdBy" = @{ }
            "owner" = @{ }
            "id" = 4
            "scope" = "7f37b0e4-e4a5-4ae3-8471-e170c7edf166"
            "name" = "Hosted Windows 2019 with VS2019"
            "isHosted" = $true
            "poolType" = "automation"
            "size" = 1
            "isLegacy" = $true
           },
           @{
            "createdOn" = "2019-07-16T14:52:14.88Z"
            "autoProvision" = "True"
            "autoSize"      = "True"
            "targetSize"    = 1
            "agentCloudId"  = 1
            "createdBy" = @{ }
            "owner" = @{ }
            "id" = 5
            "scope" = "7f37b0e4-e4a5-4ae3-8471-e170c7edf166"
            "name" = "An-Agent-Pool"
            "isHosted" = $true
            "poolType" = "automation"
            "size" = 1
            "isLegacy" = $true
           }
        )
      }
    } -ParameterFilter { $Uri -eq "https://dev.azure.com/$($OrganizationName)/_apis/distributedtask/pools?api-version=$($ApiVersion)" }

    Mock Invoke-RestMethod {
      return @{
        "value" = @(
          @{
            "_links" = @{ }
            "maxParallelism" = 1
            "createdOn" = "2019-07-16T14:52:14.88Z"
            "authorization" = @{ }
            "id" = 70
            "name" = "bld-agt-c2355.reddog.microsoft.com"
            "version" = "2.160.1"
            "osDescription" = "Microsoft Windows 10.0.17763"
            "enabled" = $true
            "status" = "offline"
            "provisioningState" = "Provisioned"
            "accessPoint" = "CodexAccessMapping"
           },
           @{
            "_links" = @{ }
            "maxParallelism" = 1
            "createdOn" = "2019-07-16T14:52:14.88Z"
            "authorization" = @{ }
            "id" = 70
            "name" = "bld-agt-f7915.reddog.microsoft.com"
            "version" = "2.160.1"
            "osDescription" = "Microsoft Windows 10.0.17763"
            "enabled" = $true
            "status" = "online"
            "provisioningState" = "Provisioned"
            "accessPoint" = "CodexAccessMapping"
           }
        )
      }
    } -ParameterFilter { $Uri -eq "https://dev.azure.com/$($OrganizationName)/_apis/distributedtask/pools/$($PoolId)/agents?api-version=$($ApiVersion)" }
  }

  Mock Invoke-RestMethod {  } -ParameterFilter { $Method -eq 'Delete' }

  It 'runs' {
    {. .\Remove-OfflineAgents.ps1 -PAT $bogusPAT -OrganizationName 'Org-exists' -AgentPoolName 'An-Agent-Pool'} | Should Not Throw
    Assert-MockCalled Invoke-RestMethod -Exactly 3 -Scope It
  }

  It 'returns when no agent pool can be found' {
    $output = . .\Remove-OfflineAgents.ps1 -PAT $bogusPAT -OrganizationName 'Org-exists' -AgentPoolName 'It doesnt exist'
    ($output -match 'No Pools named It doesnt exist found in Organization Org-exists')
  }

  It 'returns when no agents can be found in a pool' {
    Mock Invoke-RestMethod {
      return @{
        "value" = @(
          @{
            "createdOn" = "2019-07-16T14:52:14.88Z"
            "autoProvision" = "True"
            "autoSize"      = "True"
            "targetSize"    = 1
            "agentCloudId"  = 1
            "createdBy" = @{ }
            "owner" = @{ }
            "id" = 44
            "scope" = "7f37b0e4-e4a5-4ae3-8471-e170c7edf166"
            "name" = "pool-without-agents"
            "isHosted" = $true
            "poolType" = "automation"
            "size" = 1
            "isLegacy" = $true
           }
        )
      }
    } -ParameterFilter { $Uri -eq "https://dev.azure.com/$($OrganizationName)/_apis/distributedtask/pools?api-version=$($ApiVersion)" }

    Mock Invoke-RestMethod {  } -ParameterFilter { $Uri -eq "https://dev.azure.com/$($OrganizationName)/_apis/distributedtask/pools/$($PoolId)/agents?api-version=$($ApiVersion)" }

    $output = . .\Remove-OfflineAgents.ps1 -PAT $bogusPAT -OrganizationName 'Org-exists' -AgentPoolName 'pool-without-agents'
    ($output -match 'No Agents found in pool-without-agents for Organization Org-exists')
  }

  It 'removes offline agents' {
    $output = . .\Remove-OfflineAgents.ps1 -PAT $bogusPAT -OrganizationName 'Org-exist' -AgentPoolName 'An-Agent-Pool'
    ($output -match 'Removing: bld-agt-c2355.reddog.microsoft.com From Pool: An-Agent-Poolin Organization: Org-exists')
    $AgentNames | Should -Match 'bld-agt-c2355.reddog.microsoft.com'
  }

  It 'doesnt remove online agents' {
    { . .\Remove-OfflineAgents.ps1 -PAT $bogusPAT -OrganizationName 'Org-exist' -AgentPoolName 'An-Agent-Pool' }
    $AgentNames | Should Not Match 'bld-agt-f7915.reddog.microsoft.com'
  }

  It 'throws if bad organization is given' {
    Mock Invoke-RestMethod { throw $_.Exception } -ParameterFilter { $Uri -eq "https://dev.azure.com/$($OrganizationName)/_apis/distributedtask/pools/$($PoolId)/agents?api-version=$($ApiVersion)" }
    { . .\Remove-OfflineAgents.ps1 -PAT $bogusPAT -OrganizationName 'Org-doesnt-exist' -AgentPoolName 'doesnt-matter' } | Should Throw
  }

}