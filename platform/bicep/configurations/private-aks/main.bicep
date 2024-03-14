param location string
param suffix string
param kubernetesVersion string
param vmSize string
param adminGroupObjectIDs array
param spokeAddressSpace string
param spokeSubnets array

param enablePrivateCluster bool
param disableLocalAccounts bool

param fluxGitBranch string
param fluxGitRepository string
param kustomizations object

param privatednsZoneId string = '/subscriptions/e267d216-a7aa-42e4-905a-f18316a144c4/resourceGroups/rg-hub-d-we-01/providers/Microsoft.Network/privateDnsZones/privatelink.westeurope.azmk8s.io'


param targetScope string 

@description('Array of actions for the roleDefinition')
param actions array = [
  'Microsoft.Resources/subscriptions/resourceGroups/read'
]

@description('Array of notActions for the roleDefinition')
param notActions array = []

@description('Friendly name of the role definition')
param roleName string = 'Custom Role - RG Reader'

@description('Detailed description of the role definition')



param spokeNetworkname string = 'vnet-spoke-${suffix}'

param hubNetworkname string = 'vnet-hub-hub-d-we-01'
param miWorkload string = 'aks'

module userAssignedIdentity '../../modules/identity/managedIdentity.bicep' = {
  name: 'mi'
  params: {
    workload: miWorkload
    location: location
    suffix: suffix
  }
}

//let's create a custom role for the user assigned identity

module customRole '../../modules/custom-roles/roleDefinition.bicep' = {
  name: 'customRoleModule'
  params: {
    targetScope: targetScope
    actions: actions
    roleName: 'Custom Role - AKS Managed Identity'
    roleDescription: 'Custom role for AKS managed identity'
  }
}




module spokeVirtualNetwork '../../modules/network/vnet.bicep' = {
  name: 'spokeNetworkModule'
  params: {
    vnetName: spokeNetworkname
    location: location
    addressSpace: spokeAddressSpace
    subnets: spokeSubnets
  }
}

var snKubeSubnetId = spokeVirtualNetwork.outputs.subnetIds[2] // Assuming sn-kube is the third subnet in the array

module keyVault '../../modules/keyvault/keyvault.bicep' = {
  name: 'keyVaultModule'
  params: {
    aksIdentity: userAssignedIdentity.outputs.guid
    location: location
    keyVaultName: 'kv-${suffix}'
  }
}

resource hubNetwork 'Microsoft.Network/virtualNetworks@2022-09-01' existing = {
  name: hubNetworkname
}

resource spokeNetwork 'Microsoft.Network/virtualNetworks@2022-09-01' existing = {
  name: spokeNetworkname
}

resource spokeToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: '${spokeNetworkname}-to-${hubNetworkname}'
  parent: spokeNetwork
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: false
    remoteVirtualNetwork: {
      id: spokeVirtualNetwork.outputs.vnetId
    }
  }
}

resource hubToSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: '${hubNetworkname}-to-${spokeNetworkname}'
  parent: hubNetwork
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: false
    remoteVirtualNetwork: {
      id: spokeVirtualNetwork.outputs.vnetId
    }
  }
}

resource hubRouteTable 'Microsoft.Network/routeTables@2023-09-01' = {
  name: '$(hubNetworkname)-routeTable'
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'RouteToSpokeVnet'
        properties: {
          addressPrefix: '10.200.0.0/16'
          nextHopType: 'VirtualNetworkPeering'
          nextHopIpAddress: hubToSpokePeering.properties.remoteVirtualNetwork.id
        }
      }
    ]
  }
}

resource spokeRouteTable 'Microsoft.Network/routeTables@2023-09-01' = {
  name: '$(spokeNetworkname)-routeTable'
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'RouteToHubVnet'
        properties: {
          addressPrefix: '10.20.0.0/16'
          nextHopType: 'VirtualNetworkPeering'
          nextHopIpAddress: spokeToHubPeering.properties.remoteVirtualNetwork.id
        }
      }
    ]
  }
}

module aksCluster '../../modules/aks/aks.bicep' = {
  name: 'aksModule'
  params: {
    location: location
    suffix: suffix
    kubernetesVersion: kubernetesVersion
    vmSize: vmSize
    adminGroupObjectIDs: adminGroupObjectIDs
    subnetId: snKubeSubnetId
    enablePrivateCluster: enablePrivateCluster
    disableLocalAccounts: disableLocalAccounts
    privateDNSZone: privatednsZoneName
    userAssignedIdentityId: userAssignedIdentity.outputs.guid
  }
}

module acr '../../modules/acr/acr.bicep' = {
  name: 'acrModule'
  params: {
    acrName: 'acr-${suffix}'
    location: location
    aksServicePrincipalId: aksCluster.outputs.aksKubeletIdentityObjectId
  }
}

module fluxExtension '../../modules/flux/fluxExtension.bicep' = {
  name: 'fluxExtensionModule'
  params: {
    aksClusterName: aksCluster.outputs.aksClusterName
  }
}

module fluxConfig '../../modules/flux/fluxConfigurations.bicep' = {
  name: 'fluxConfigModule'
  params: {
    aksClusterName: aksCluster.outputs.aksClusterName
    fluxGitRepository: fluxGitRepository
    kustomizations: kustomizations
    fluxGitBranch: fluxGitBranch
  }
}
