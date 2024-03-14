param suffix string
param workload string
param location string = resourceGroup().location

resource mi 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'mi-${workload}-${suffix}'
  location: location
}

output userAssignedManagedIdentityId string = mi.id
output userAssignedManagedIdentityName string = mi.name
output guid string = mi.properties.principalId
