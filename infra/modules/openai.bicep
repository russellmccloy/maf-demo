param accountName string
param location string
param tags object = {}

param deploymentName string = 'gpt-5.4'
param modelName string = 'gpt-5.4'
param modelVersion string = '1'

@allowed([
  'GlobalStandard'
  'Standard'
  'GlobalBatch'
])
param deploymentSkuName string = 'GlobalStandard'

@minValue(1)
param deploymentCapacity int = 1

resource openAiAccount 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: accountName
  location: location
  tags: tags
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: accountName
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
  }
}

resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  name: deploymentName
  parent: openAiAccount
  sku: {
    name: deploymentSkuName
    capacity: deploymentCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: modelName
      version: modelVersion
    }
    raiPolicyName: 'Microsoft.Default'
  }
}

var accountKeys = openAiAccount.listKeys()

output accountName string = openAiAccount.name
output deploymentName string = modelDeployment.name
output endpoint string = openAiAccount.properties.endpoint
@secure()
output primaryKey string = accountKeys.key1
