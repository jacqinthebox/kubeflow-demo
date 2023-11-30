param location string
param suffix string
param addressSpace string
param subnets array
param kubernetesVersion string
param vmSize string
param adminGroupObjectIDs array


module virtualNetwork '../../modules/network/vnet.bicep' = {
  name: 'networkModule'
  params: {
    vnetName: 'vnet-${suffix}'
    location: location
    addressSpace: addressSpace
    subnets: subnets
  }
}

module identity '../../modules/identity/identity.bicep' = {
  name: 'identityModule'
  params: {
    name: 'mi-${suffix}'
    location: location
  }
}

module privateDns '../../modules/privateDns/privateDns.bicep' = {
  name: 'privateDnsModule'
  params: {
    virtualNetworkId: virtualNetwork.outputs.vnetId
  }
}

var roleAssignmentName = guid(identity.name, 'b12aa53e-6015-4669-85d0-8515ebb3ae7f', resourceGroup().id)
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2021-04-01-preview' = {
  name: roleAssignmentName
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'b12aa53e-6015-4669-85d0-8515ebb3ae7f')
    principalId: identity.outputs.principalId
  }
}


var snKubeSubnetId = virtualNetwork.outputs.subnetIds[2] // Assuming sn-kube is the third subnet in the array

module aksCluster '../../modules/aks/aks.bicep' = {
  name: 'aksModule'
  params: {
    location: location
    suffix: suffix
    kubernetesVersion: kubernetesVersion
    vmSize: vmSize
    adminGroupObjectIDs: adminGroupObjectIDs
    subnetId: snKubeSubnetId
  }
}

output aksClusterId string = aksCluster.outputs.aksClusterId
