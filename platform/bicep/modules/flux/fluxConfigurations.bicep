@description('The kubernetes name the flux extension must be installed on')
param aksClusterName string

@description('The git repository url where the flux configuration is stored')
param fluxGitRepository string

@description('An object with an array of kustomizations. See the example below for the structure.')
param kustomizations object = {
  infra: {
    dependsOn: []
    path: './gitops/infrastructure'
    prune: true
    syncIntervalInSeconds: 300
    timeoutInSeconds: 180
  }
  apps: {
    dependsOn: []
    path: './gitops/apps'
    prune: true
    syncIntervalInSeconds: 300
    timeoutInSeconds: 180
  }
}


resource aksCluster 'Microsoft.ContainerService/managedClusters@2021-08-01' existing = {
  name: aksClusterName
}

resource fluxConfig 'Microsoft.KubernetesConfiguration/fluxConfigurations@2023-05-01' = {
  name: 'flux-config'
  scope: aksCluster
  properties: {
    configurationProtectedSettings: {}
    gitRepository: {
      //      localAuthRef: 'flux-pat'
      repositoryRef: {
        branch: 'main'
      }
      syncIntervalInSeconds: 300
      timeoutInSeconds: 300
      url: fluxGitRepository
    }
    kustomizations: kustomizations
    namespace: 'cluster-config'
    scope: 'cluster'
    sourceKind: 'GitRepository'
    suspend: false
  }
}
