@minLength(1)
param privateLinkServiceId string
param location string = resourceGroup().location
resource privateLinkEndpoint 'Microsoft.Network/' = {
  name: 'myPrivateLinkEndpoint'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        privateLinkServiceId: privateLinkServiceId
        groupId: 'myGroup'
      }
    ]
  }
}
