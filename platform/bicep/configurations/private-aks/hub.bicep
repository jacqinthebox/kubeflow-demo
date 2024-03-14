param location string = resourceGroup().location
param suffix string
param vmSize string
param hubAddressSpace string
param hubSubnets array
param privateDnsZoneName string = 'privatelink.westeurope.azmk8s.io'
param adminUsername string
param adminKey string
param authenticationType string
param sourceAddressPrefix string

module hubVirtualNetwork '../../modules/network/vnet.bicep' = {
  name: 'hubNetworkModule'
  params: {
    vnetName: 'vnet-hub-${suffix}'
    location: location
    addressSpace: hubAddressSpace
    subnets: hubSubnets
  }
}

module vm '../../modules/vm/vm.bicep' = {
  name: 'vmModule'
  params: {
    location: location
    suffix: suffix
    vmSize: vmSize
    subnetId: hubVirtualNetwork.outputs.subnetIds[0]
    adminKey: adminKey
    adminUsername: adminUsername
    authenticationType: authenticationType
    vmName: 'vm-${suffix}'
    sourceAddressPrefix: sourceAddressPrefix
  }
}

module dns '../../modules/privateDns/privateDns.bicep' = {
  name: 'dnsModule'
  params: {
    privateDnsZoneName: privateDnsZoneName
    virtualNetworkId: hubVirtualNetwork.outputs.vnetId
  }
}
