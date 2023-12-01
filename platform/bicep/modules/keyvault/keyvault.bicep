@description('The location to use for the deployment. defaults to Resource Groups location.')
param location string = resourceGroup().location

@description('Used to name all resources')
param name string

@description('Enable support for private links')
param privateLinks bool = false

@description('If soft delete protection is enabled')
param keyVaultSoftDelete bool = true

@description('If purge protection is enabled')
param keyVaultPurgeProtection bool = false

@description('Add IP to KV firewall allow-list')
param keyVaultIPAllowlist array = []

param sku string = 'standard'
param family string = 'A'

var kvIPRules = [for kvIp in keyVaultIPAllowlist: {
  value: kvIp
}]


var nameWithoutHyphens = replace(name, '-', '')

resource kv 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: nameWithoutHyphens
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: family
      name: sku
    }
    // publicNetworkAccess:  whether the vault will accept traffic from public internet. If set to 'disabled' all traffic except private endpoint traffic and that that originates from trusted services will be blocked.
    publicNetworkAccess: privateLinks && empty(keyVaultIPAllowlist) ? 'disabled' : 'enabled'

    networkAcls: privateLinks && !empty(keyVaultIPAllowlist) ? {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: kvIPRules
      virtualNetworkRules: []
    } : {}

    enableRbacAuthorization: true
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enableSoftDelete: keyVaultSoftDelete
    enablePurgeProtection: keyVaultPurgeProtection ? true : json('null')
  }
}

output keyVaultName string = kv.name
output keyVaultId string = kv.id
