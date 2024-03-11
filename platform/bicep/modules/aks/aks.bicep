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

param blobCSIDriverEnabled bool = false
param fileCSIDriverEnabled bool = false
param diskCSIDriverEnabled bool = true
param snapshotControllerEnabled bool = true

param subnetId string
param disableLocalAccounts bool
param enablePodSecurityPolicy bool = false // is now deprecated
param enablePrivateCluster bool
param privateDNSZone string = ''

param identityType string = 'systemAssigned' // Choose 'systemAssigned' or 'userAssigned'
param userAssignedIdentityId string = '' // Resource ID of the user-assigned identity (required if identityType is 'userAssigned')

var isSystemAssigned = identityType == 'systemAssigned'
var isUserAssigned = identityType == 'userAssigned'


resource aksCluster 'Microsoft.ContainerService/managedClusters@2023-03-02-preview' = {
  name: 'aks-${suffix}'
  location: location
  identity: isSystemAssigned ? {
    type: 'SystemAssigned'
  } : isUserAssigned ? {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  } : null
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
        enableAutoScaling: true
        minCount: 1
        maxCount: 6
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
    oidcIssuerProfile: {
      enabled: true
    }
    storageProfile: {
      blobCSIDriver: {
        enabled: blobCSIDriverEnabled
      }
      diskCSIDriver: {
        enabled: diskCSIDriverEnabled
      }
      fileCSIDriver: {
        enabled: fileCSIDriverEnabled
      }
      snapshotController: {
        enabled: snapshotControllerEnabled
      }
    }
  }
}



output aksClusterId string = aksCluster.id
output aksClusterName string = aksCluster.name
output aksKubeletIdentityObjectId string = aksCluster.properties.identityProfile.kubeletidentity.objectId
output aksIdentityPrincipalId string = isSystemAssigned ? aksCluster.identity.principalId : ''
output aksIdentityType string = aksCluster.identity.type
