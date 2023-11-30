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

resource aksCluster 'Microsoft.ContainerService/managedClusters@2023-03-02-preview' = {
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
    oidcIssuerProfile: {
      enabled: true
    }
  }
}

resource fluxExtension 'Microsoft.KubernetesConfiguration/extensions@2023-05-01' = {
  name: 'flux'
  scope: aksCluster
  properties: {
    autoUpgradeMinorVersion: true
    configurationProtectedSettings: {}
    configurationSettings: {
      'helm-controller.enabled': 'true'
      'image-automation-controller.enabled': 'false'
      'image-reflector-controller.enabled': 'false'
      'kustomize-controller.enabled': 'true'
      'notification-controller.enabled': 'true'
      'source-controller.enabled': 'true'
    }
    extensionType: 'microsoft.flux'
    releaseTrain: 'Stable'
    scope: {
      cluster: {
        releaseNamespace: 'flux-system'
      }
    }
  }
}

resource fluxConfig 'Microsoft.KubernetesConfiguration/fluxConfigurations@2023-05-01' = {
  name: 'flux-config'
  scope: aksCluster
  properties: {
    configurationProtectedSettings: {}
    gitRepository: {
      localAuthRef: 'flux-pat'
      repositoryRef: {
        branch: 'dev'
      }
      syncIntervalInSeconds: 300
      timeoutInSeconds: 300
      url: 'https://github.com/jacqinthebox/kubeflow-demo.git'
    }
    kustomizations: {
      infra: {
        dependsOn: []
        path: './gitops'
        prune: true
        syncIntervalInSeconds: 300
        timeoutInSeconds: 300
        retryIntervalInSeconds: 300
      }
    }
    namespace: 'cluster-config'
    scope: 'cluster'
    sourceKind: 'GitRepository'
    suspend: false
  }
}

output aksClusterId string = aksCluster.id
