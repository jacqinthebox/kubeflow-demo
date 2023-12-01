param virtualNetworkId string
//param location string = resourceGroup().location

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: 'privatelink.westeurope.azmk8s.io'
  location: 'global'
}

resource privateDnsZoneVirtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateDnsZone
  name: 'link-to-vnet'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: virtualNetworkId
    }
    registrationEnabled: false
  }
}

output privateDnsZoneId string = privateDnsZone.id
output privateDnsZoneVirtualNetworkLinkId string = privateDnsZoneVirtualNetworkLink.id
output privateDnsZoneName string = privateDnsZone.name
