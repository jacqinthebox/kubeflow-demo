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

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-07-01' = {
  name: 'vnet-${suffix}'
  location: location

  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.200.0.0/16' // Change this to your desired VNet address range
      ]
    }
    subnets: [
      {
        name: 'sn-mgm'
        properties: {
          addressPrefix: '10.200.0.0/24' // Subnet for AKS
        }
      }
      {
        name: 'sn-apps'
        properties: {
          addressPrefix: '10.200.1.0/24' // Subnet for AKS
        }
      }
      {
        name: 'sn-kube'
        properties: {
          addressPrefix: '10.200.32.0/19' // Subnet for AKS
        }
      }
    ]
  }
}

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
        vnetSubnetID: virtualNetwork.properties.subnets[0].id
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
        vnetSubnetID: virtualNetwork.properties.subnets[0].id
      }
    ]
    networkProfile: {
      networkPlugin: 'azure'
      loadBalancerSku: 'standard'
      networkPolicy: 'calico'
      serviceCidr: '10.0.32.0/20' // Adjust as needed
      dnsServiceIP: '10.0.32.10' // Adjust as needed
      dockerBridgeCidr: '172.17.0.1/16'
    }
    enableRBAC: true
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
