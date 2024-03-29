param location string
param suffix string
param kubernetesVersion string
param vmSize string
param adminGroupObjectIDs array
param addressSpace string
param subnets array
param fluxGitRepository string
param enablePrivateCluster bool
param disableLocalAccounts bool

param adminUsername string
param adminKey string
param authenticationType string
param sourceAddressPrefix string

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
    keyVaultName: 'kv-${suffix}'
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
    fluxGitRepository: fluxGitRepository
    enablePrivateCluster: enablePrivateCluster
    disableLocalAccounts: disableLocalAccounts
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

module vm '../../modules/vm/vm.bicep' = {
  name: 'vmModule'
  params: {
    location: location
    suffix: suffix
    vmSize: vmSize
    subnetId: virtualNetwork.outputs.subnetIds[0]
    adminKey: adminKey
    adminUsername: adminUsername
    authenticationType: authenticationType
    vmName: 'vm-${suffix}'
    sourceAddressPrefix: sourceAddressPrefix
  }
}
