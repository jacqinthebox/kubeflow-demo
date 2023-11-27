param location string
param suffix string
param kubernetesVersion string
param vmSize string
param adminGroupObjectIDs array
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

var snKubeSubnetId = virtualNetwork.outputs.subnetIds[2] // Assuming sn-kube is the third subnet in the array

/*
module privateDns '../../modules/privateDns/privateDns.bicep' = {
  name: 'privateDnsModule'
  params: {
    virtualNetworkId: virtualNetwork.outputs.vnetId
  }
}
*/

module aksCluster '../../modules/aks/aks.bicep' = {
  name: 'aksModule'
  params: {
    location: location
    suffix: suffix
    kubernetesVersion: kubernetesVersion
    vmSize: vmSize
    adminGroupObjectIDs: adminGroupObjectIDs
    subnetId: snKubeSubnetId
  }
}

output aksClusterId string = aksCluster.outputs.aksClusterId
