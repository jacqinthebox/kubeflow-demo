param acrName string
param location string = resourceGroup().location
param sku string = 'Basic'
param aksServicePrincipalId string


resource acr 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: replace(acrName, '-', '')
  location: location
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: true
  }
}

output acrResourceId string = acr.id

resource acrRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(acr.id, aksServicePrincipalId)
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull role
    principalId: aksServicePrincipalId
  }
}



output acrLoginServer string = acr.properties.loginServer
