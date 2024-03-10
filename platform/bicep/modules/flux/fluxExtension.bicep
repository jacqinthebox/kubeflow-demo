@description('The kubernetes name the flux extension must be installed on')
param aksClusterName string

resource aksCluster 'Microsoft.ContainerService/managedClusters@2021-08-01' existing = {
  name: aksClusterName
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
