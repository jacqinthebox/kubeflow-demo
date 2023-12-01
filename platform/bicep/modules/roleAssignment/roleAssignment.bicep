param roleAssignmentName string
param roleDefinitionId string
param principalId string
param keyVaultName string

resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' existing = {
  name: keyVaultName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2021-04-01-preview' = {
  name: roleAssignmentName
  scope: keyVault
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: principalId
    principalType: 'ServicePrincipal'
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


