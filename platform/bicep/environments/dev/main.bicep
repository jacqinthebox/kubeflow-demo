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


module keyVault '../../modules/keyvault/keyvault.bicep' = {
  name: 'keyVaultModule'
  params: {
    aksIdentity: aksCluster.outputs.aksIdentityPrincipalId
    location: location
    name: 'keyvault-${suffix}'
  }
}

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


module acr '../../modules/acr/acr.bicep' = {
  name: 'acrModule'
  params: {
    acrName: 'acr-${suffix}'
    location: location
    aksServicePrincipalId: aksCluster.outputs.aksKubeletIdentityObjectId
  }
}

