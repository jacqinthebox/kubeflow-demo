
param principalId string
param rg string
param zoneName string = 'privatelink.westeurope.azmk8s.io'




resource privateDnsZoneContributorAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid('unique-name-for-assignment') // Use a unique name for the assignment
  scope: privateDnsZone
  properties: {
    principalId: principalId
    roleDefinitionId: '/subscriptions/e267d216-a7aa-42e4-905a-f18316a144c4/providers/Microsoft.Authorization/roleDefinitions/7d7b8f2a-7d3d-4b6c-8e6f-3d0d276d6d5d' // Contributor role
  }
}



module privateDnsZoneContributorAssignment 'main.bicep' = {
  name: 'privateDnsZoneContributorAssignment'
  params: {
    principalId: principalId
    rg: rg
  }
}
```
