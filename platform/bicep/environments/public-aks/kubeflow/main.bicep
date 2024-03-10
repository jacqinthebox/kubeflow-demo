param location string
param suffix string
param kubernetesVersion string
param vmSize string
param adminGroupObjectIDs array
param addressSpace string
param subnets array
param fluxGitRepository string
param kustomizations object

param enablePrivateCluster bool
param disableLocalAccounts bool

module virtualNetwork '../../../modules/network/vnet.bicep' = {
  name: 'networkModule'
  params: {
    vnetName: 'vnet-${suffix}'
    location: location
    addressSpace: addressSpace
    subnets: subnets
  }
}

var snKubeSubnetId = virtualNetwork.outputs.subnetIds[2] // Assuming sn-kube is the third subnet in the array

module keyVault '../../../modules/keyvault/keyvault.bicep' = {
  name: 'keyVaultModule'
  params: {
    aksIdentity: aksCluster.outputs.aksIdentityPrincipalId
    location: location
    keyVaultName: 'kv-${suffix}'
  }
}

module aksCluster '../../../modules/aks/aks.bicep' = {
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

module acr '../../../modules/acr/acr.bicep' = {
  name: 'acrModule'
  params: {
    acrName: 'acr-${suffix}'
    location: location
    aksServicePrincipalId: aksCluster.outputs.aksKubeletIdentityObjectId
  }
}

module fluxExtension '../../../modules/flux/fluxExtension.bicep' = {
  name: 'fluxExtensionModule'
  params: {
    aksClusterName: aksCluster.outputs.aksClusterId
  }
}

module fluxConfig '../../../modules/flux/fluxConfigurations.bicep' = {
  name: 'fluxConfigModule'
  params: {
    aksClusterName: aksCluster.outputs.aksClusterId
    fluxGitRepository: fluxGitRepository
    kustomizations: kustomizations
    }
}
