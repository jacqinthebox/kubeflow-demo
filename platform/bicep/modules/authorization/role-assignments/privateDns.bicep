param privateDnsZoneName string = 'privatelink.westeurope.azmk8s.io'
@description('Required. You need to provide the fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
param roleDefinitionId string
param roleAssignmentDescription string
param principalType string = 'ServicePrincipal'
param condition string = ''

@description('Required. An array of Principal or Object ID of the Security Principal (User, Group, Service Principal, Managed Identity).')
param principalId string


//////////////////////////////////////////////////////////////////////////////////////////////
// Existing resources

resource existingPrivateDnsZone 'Microsoft.ContainerRegistry/registries@2022-12-01' existing = {
  name: privateDnsZoneName
}

//////////////////////////////////////////////////////////////////////////////////////////////
// Deployment resources

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(existingPrivateDnsZone.id, principalId, roleDefinitionId)
  scope: existingPrivateDnsZone
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: principalId
    description: roleAssignmentDescription
    principalType: !empty(principalType) ? any(principalType) : null
    condition: !empty(condition) ? condition : null
  }
}


