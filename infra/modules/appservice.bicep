param location string
param tags object = {}

param appServicePlanName string
param appServicePlanSkuName string = 'F1'
param webAppName string

@secure()
param azureOpenAiKey string
param azureOpenAiEndpoint string
param azureOpenAiDeploymentName string

@secure()
param cosmosKey string
param cosmosEndpoint string
param cosmosDatabaseName string
param sessionsContainerName string
param messagesContainerName string
param documentsContainerName string

@secure()
param searchKey string
param searchEndpoint string
param searchIndexName string

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: appServicePlanSkuName
    tier: appServicePlanSkuName == 'F1' ? 'Free' : 'Basic'
    size: appServicePlanSkuName
    capacity: 1
  }
  kind: 'app'
  properties: {
    reserved: false
  }
}

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  tags: tags
  kind: 'app'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    clientAffinityEnabled: false
    siteConfig: {
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      alwaysOn: appServicePlanSkuName != 'F1'
      http20Enabled: true
    }
  }
}

resource webAppSettings 'Microsoft.Web/sites/config@2023-12-01' = {
  name: 'appsettings'
  parent: webApp
  properties: {
    ASPNETCORE_ENVIRONMENT: 'Production'
    WEBSITES_ENABLE_APP_SERVICE_STORAGE: 'false'
    AzureOpenAI__Endpoint: azureOpenAiEndpoint
    AzureOpenAI__Key: azureOpenAiKey
    AzureOpenAI__ModelDeploymentName: azureOpenAiDeploymentName
    CosmosDb__Endpoint: cosmosEndpoint
    CosmosDb__Key: cosmosKey
    CosmosDb__DatabaseName: cosmosDatabaseName
    CosmosDb__SessionsContainerName: sessionsContainerName
    CosmosDb__MessagesContainerName: messagesContainerName
    CosmosDb__DocumentsContainerName: documentsContainerName
    AzureSearch__Endpoint: searchEndpoint
    AzureSearch__Key: searchKey
    AzureSearch__IndexName: searchIndexName
  }
}

output webAppName string = webApp.name
output defaultHostName string = 'https://${webApp.properties.defaultHostName}'
output appServicePlanId string = appServicePlan.id
