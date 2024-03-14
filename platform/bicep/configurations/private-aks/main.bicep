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

//https://learn.microsoft.com/en-us/azure/aks/concepts-identity
@description('Array of actions for the roleDefinition')
param aksIdentitySubscriptionActions array = [
  'Microsoft.ContainerService/managedClusters/*'
  'Microsoft.Network/loadBalancers/delete'
  'Microsoft.Network/loadBalancers/read'
  'Microsoft.Network/loadBalancers/write'
  'Microsoft.Network/publicIPAddresses/delete'
  'Microsoft.Network/publicIPAddresses/read'
  'Microsoft.Network/publicIPAddresses/write'
  'Microsoft.Network/publicIPAddresses/join/action'
  'Microsoft.Network/networkSecurityGroups/read'
  'Microsoft.Network/networkSecurityGroups/write'
  'Microsoft.Compute/disks/delete'
  'Microsoft.Compute/disks/read'
  'Microsoft.Compute/disks/write'
  'Microsoft.Compute/locations/DiskOperations/read'
  'Microsoft.Storage/storageAccounts/delete'
  'Microsoft.Storage/storageAccounts/listKeys/action'
  'Microsoft.Storage/storageAccounts/read'
  'Microsoft.Storage/storageAccounts/write'
  'Microsoft.Storage/operations/read'
  'Microsoft.Network/routeTables/read'
  'Microsoft.Network/routeTables/routes/delete'
  'Microsoft.Network/routeTables/routes/read'
  'Microsoft.Network/routeTables/routes/write'
  'Microsoft.Network/routeTables/write'
  'Microsoft.Compute/virtualMachines/read'
  'Microsoft.Compute/virtualMachines/write'
  'Microsoft.Compute/virtualMachineScaleSets/read'
  'Microsoft.Compute/virtualMachineScaleSets/virtualMachines/read'
  'Microsoft.Compute/virtualMachineScaleSets/virtualmachines/instanceView/read'
  'Microsoft.Network/networkInterfaces/write'
  'Microsoft.Compute/virtualMachineScaleSets/write'
  'Microsoft.Compute/virtualMachineScaleSets/delete'
  'Microsoft.Compute/virtualMachineScaleSets/virtualmachines/write'
  'Microsoft.Network/networkInterfaces/read'
  'Microsoft.Compute/virtualMachineScaleSets/virtualMachines/networkInterfaces/read'
  'Microsoft.Compute/virtualMachineScaleSets/virtualMachines/networkInterfaces/ipconfigurations/publicipaddresses/read'
  'Microsoft.Network/virtualNetworks/read'
  'Microsoft.Network/virtualNetworks/subnets/read'
  'Microsoft.Compute/snapshots/delete'
  'Microsoft.Compute/snapshots/read'
  'Microsoft.Compute/snapshots/write'
  'Microsoft.Compute/locations/vmSizes/read'
  'Microsoft.Compute/locations/operations/read'
  'Microsoft.Network/networkSecurityGroups/write'
  'Microsoft.Network/networkSecurityGroups/read'
  'Microsoft.Network/virtualNetworks/subnets/read'
  'Microsoft.Network/virtualNetworks/subnets/join/action'
  'Microsoft.Network/routeTables/routes/read'
  'Microsoft.Network/routeTables/routes/write'
  'Microsoft.Network/virtualNetworks/subnets/read'
  'Microsoft.Network/privatednszones/*'
]

@description('Friendly name of the role definition')
param aksIdentitySubscriptionRoleName string = 'Custom Role - AKS cluster identity permissions'

@description('Detailed description of the role definition')
param aksIdentitySubscriptionRoleDescription string = 'All roles needed for the AKS cluster identity'


@description('Array of actions for the roleDefinition')
param aksIdentityPrivateDNSActions array = [
  'Microsoft.Network/privatednszones/*'
]


@description('Friendly name of the role definition')
param aksIdentityPrivateDNSRoleName string = 'Custom Role - AKS cluster identity permissions'

@description('Detailed description of the role definition')
param aksIdentityPrivateDNSRoleDescription string = 'All roles needed for the AKS cluster identity'


param privatednsZoneId string = '/subscriptions/e267d216-a7aa-42e4-905a-f18316a144c4/resourceGroups/rg-hub-d-we-01/providers/Microsoft.Network/privateDnsZones/privatelink.westeurope.azmk8s.io'
param aksIdentitySubscriptionTargetScope string = subscription().id


param spokeNetworkname string = 'vnet-spoke-${suffix}'
param hubNetworkname string = 'vnet-hub-hub-d-we-01'
param miWorkload string = 'aks'


//let's create a custom role for the user assigned identity for the subscription
module aksIdentitySubscriptionCustomRole '../../modules/authorization/role-definitions/roleDefinition.bicep' = {
  name: 'aksIdentitySubscriptionCustomRoleModule'
  params: {
    targetScope: aksIdentitySubscriptionTargetScope
    actions: aksIdentitySubscriptionActions
    roleName: aksIdentitySubscriptionRoleName
    roleDescription: aksIdentitySubscriptionRoleDescription
  }
}

//let's create a custom role for the user assigned identity for the private dns zone
module aksIdentityPrivateDNSCustomRole '../../modules/authorization/role-definitions/roleDefinition.bicep' = {
  name: 'aksIdentityPrivateDNSCustomRoleModule'
  params: {
    targetScope: privatednsZoneId
    actions: aksIdentityPrivateDNSActions
    roleName: aksIdentityPrivateDNSRoleName
    roleDescription: aksIdentityPrivateDNSRoleDescription
  }
}


//let's create the identity
module userAssignedIdentity '../../modules/identity/managedIdentity.bicep' = {
  name: 'aksManagedIdentityModule'
  params: {
    workload: miWorkload
    location: location
    suffix: suffix
  }
}

//let's assign the role
module aksIdentitySubscriptionRoleAssignment '../../modules/authorization/role-assignments/subscription.bicep' = {
  name: 'aksIdentitySubscriptionRoleAssignmentModule'
  params: {
    principalId: userAssignedIdentity.outputs.userAssignedManagedIdentityId
    roleAssignmentDescription: aksIdentitySubscriptionRoleDescription
    roleDefinitionIdOrName:  aksIdentitySubscriptionRoleName 
  }
  scope: subscription()
}

module aksIdentityPrivateDnsRoleAssignment '../../modules/authorization/role-assignments/privateDns.bicep' = {
  name: 'aksIdentitySubscriptionRoleAssignmentModule'
  params: {
    principalId: userAssignedIdentity.outputs.userAssignedManagedIdentityId
    roleAssignmentDescription: aksIdentitySubscriptionRoleDescription
    roleDefinitionId: aksIdentityPrivateDNSCustomRole.outputs.roleDefinitionId
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
