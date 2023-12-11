@description('The location to use for the deployment. defaults to Resource Groups location.')
param location string = resourceGroup().location

@description('Used to name all resources')
@maxLength(24)
param keyVaultName string

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

param aksIdentity string



resource kv 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: keyVaultName
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
    enablePurgeProtection: keyVaultPurgeProtection ? true : null
  }
}


var keyVaultAssignmentName = guid(aksIdentity, '00482a5a-887f-4fb3-b363-3b7fe8e74483', resourceGroup().id)
resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2021-04-01-preview' = {
  name: keyVaultAssignmentName
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '00482a5a-887f-4fb3-b363-3b7fe8e74483')
    principalId: aksIdentity
  }
}


output keyVaultName string = kv.name
output keyVaultId string = kv.id
