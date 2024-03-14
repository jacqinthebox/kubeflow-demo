targetScope = 'subscription'

@description('Required. You can provide either the display name of the role definition, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
param roleDefinitionIdOrName string

@description('Required. The Principal or Object ID of the Security Principal (User, Group, Service Principal, Managed Identity).')
param principalId string

@description('Required. The description of the role assignment.')
param roleAssignmentDescription string

@description('Optional. Subscription ID of the subscription to assign the RBAC role to. If not provided, will use the current scope for deployment. Default: subscription().subscriptionId')
param subscriptionId string = subscription().subscriptionId

@description('Optional. ID of the delegated managed identity resource. Default: \'\'')
param delegatedManagedIdentityResourceId string = ''

@description('Optional. The conditions on the role assignment. This limits the resources it can be assigned to. Default: \'\'')
param condition string = ''

@description('Optional. Version of the condition. Currently accepted value is "2.0". Default: \'2.0\'')
@allowed([
  '2.0'
])
param conditionVersion string = '2.0'

@description('Optional. The principal type of the assigned principal ID. Default: \'\'')
@allowed([
  'ServicePrincipal'
  'Group'
  'User'
  'ForeignGroup'
  'Device'
  ''
])
param principalType string = ''

var builtInRoleNames = {
  'Network Contributor': '/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7'
}

var roleDefinitionId = (contains(builtInRoleNames, roleDefinitionIdOrName) ? builtInRoleNames[roleDefinitionIdOrName] : roleDefinitionIdOrName)


resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscriptionId, roleDefinitionId, principalId)
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: principalId
    description: !empty(roleAssignmentDescription) ? roleAssignmentDescription : null
    principalType: !empty(principalType) ? any(principalType) : null
    delegatedManagedIdentityResourceId: !empty(delegatedManagedIdentityResourceId) ? delegatedManagedIdentityResourceId : null
    conditionVersion: !empty(conditionVersion) && !empty(condition) ? conditionVersion : null
    condition: !empty(condition) ? condition : null
  }
}


output name string = roleAssignment.name
output id string = roleAssignment.id
output scope string = subscription().id
