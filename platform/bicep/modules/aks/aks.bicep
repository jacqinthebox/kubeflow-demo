@description('Specifies the location.')
param location string

@description('Specifies the suffix.')
param suffix string

@description('Specifies the kube version.')
param kubernetesVersion string

@description('Specifies the vm size.')
param vmSize string

@description('Specifies the aad admim group id.')
param adminGroupObjectIDs array

param subnetId string
param disableLocalAccounts bool = true
param enablePodSecurityPolicy bool = false
param enablePrivateCluster bool = false


param privateDNSZone string = ''

resource aksCluster 'Microsoft.ContainerService/managedClusters@2021-03-01' = {
  name: 'aks-${suffix}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    dnsPrefix: 'aks-${suffix}'
    nodeResourceGroup: 'rg-aks-nodes-${suffix}'
    enableRBAC: true
    disableLocalAccounts: disableLocalAccounts
    enablePodSecurityPolicy: enablePodSecurityPolicy
    apiServerAccessProfile: {
      enablePrivateCluster: enablePrivateCluster
      privateDNSZone: privateDNSZone
    }
    agentPoolProfiles: [
      {
        name: 'defaultpool'
        count: 1
        vmSize: vmSize
        osDiskSizeGB: 30
        maxPods: 110
        type: 'VirtualMachineScaleSets'
        mode: 'System'
        osType: 'Linux'
        vnetSubnetID: subnetId
      }
      {
        name: 'apppool'
        count: 1
        vmSize: vmSize
        osDiskSizeGB: 30
        maxPods: 110
        type: 'VirtualMachineScaleSets'
        mode: 'User'
        osType: 'Linux'
        vnetSubnetID: subnetId
      }
    ]
    networkProfile: {
      networkPlugin: 'azure'
      loadBalancerSku: 'standard'
      networkPolicy: 'calico'
      serviceCidr: '10.0.32.0/20' 
      dnsServiceIP: '10.0.32.10'
      dockerBridgeCidr: '172.17.0.1/16'
    }
    aadProfile: {
      adminGroupObjectIDs: adminGroupObjectIDs
      enableAzureRBAC: true
      managed: true
    }
    addonProfiles: {
      azureKeyvaultSecretsProvider: {
        enabled: true
      }
    }
  }
}

output aksClusterId string = aksCluster.id
