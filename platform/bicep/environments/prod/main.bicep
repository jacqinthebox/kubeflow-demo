param location string
param suffix string
param addressSpace string
param subnets array


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

var nameWithoutHyphens = replace('kv-${suffix}', '-', '')
module keyVault '../../modules/keyvault/keyvault.bicep' = {
  name: 'keyVaultModule'
  params: {
    name: length(nameWithoutHyphens) > 20 ? substring(nameWithoutHyphens, 0, 20) : nameWithoutHyphens 
    location: location
  }
}


var dnsRoleAssignmentName = guid(identity.name, 'b12aa53e-6015-4669-85d0-8515ebb3ae7f', resourceGroup().id)
resource dnsRoleAssignment 'Microsoft.Authorization/roleAssignments@2021-04-01-preview' = {
  name: dnsRoleAssignmentName
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'b12aa53e-6015-4669-85d0-8515ebb3ae7f')
    principalId: identity.outputs.principalId
  }
}

var keyVaultAssignmentName = guid(identity.name, '00482a5a-887f-4fb3-b363-3b7fe8e74483', resourceGroup().id)
resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2021-04-01-preview' = {
  name: keyVaultAssignmentName
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '00482a5a-887f-4fb3-b363-3b7fe8e74483')
    principalId: identity.outputs.principalId
  }
}
