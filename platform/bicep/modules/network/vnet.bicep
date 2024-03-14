param location string
param vnetName string
param addressSpace string
param subnets array

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-07-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressSpace
      ]
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        privateEndpointNetworkPolicies: 'Enabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
      }
    }]
  }
}

// Outputs to be used by other modules or resources
output vnetId string = virtualNetwork.id
output subnetIds array = [for subnet in subnets: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnet.name)]
output vnetName string = virtualNetwork.name
