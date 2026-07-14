targetScope = 'resourceGroup'

@description('Deployment environment name.')
param environment string = 'prod'

@description('Primary Azure region for the deployment.')
param location string = resourceGroup().location

@description('Name prefix used for resources.')
param prefix string = 'mafdemo'

@description('Tags applied to all resources.')
param tags object = {
  environment: environment
  project: 'maf-demo'
  managedBy: 'bicep'
}

@description('Azure OpenAI model deployment name used by the app.')
param openAiDeploymentName string = 'gpt-5.4'

@description('Azure OpenAI model name for the deployment.')
param openAiModelName string = 'gpt-5.4'

@description('Azure OpenAI model version for the deployment.')
param openAiModelVersion string = '2026-03-05'

@description('Azure OpenAI deployment SKU name.')
@allowed([
  'GlobalStandard'
  'Standard'
  'GlobalBatch'
])
param openAiDeploymentSkuName string = 'GlobalStandard'

@description('Azure OpenAI deployment capacity units.')
@minValue(1)
param openAiDeploymentCapacity int = 1

@description('Azure AI Search SKU name.')
@allowed([
  'basic'
  'free'
  'standard'
  'standard2'
  'standard3'
])
param searchSku string = 'basic'

@description('App Service plan SKU name.')
param appServicePlanSkuName string = 'F1'

@description('Cosmos DB database name.')
param cosmosDatabaseName string = 'maf-demo-db'

@description('Cosmos DB sessions container name.')
param sessionsContainerName string = 'sessions'

@description('Cosmos DB messages container name.')
param messagesContainerName string = 'messages'

@description('Cosmos DB documents container name.')
param documentsContainerName string = 'documents'

@description('Azure AI Search index name used by the app.')
param searchIndexName string = 'rag-documents'

var safePrefix = toLower(replace(prefix, '-', ''))
var uniqueSuffix = toLower(take(uniqueString(subscription().subscriptionId, resourceGroup().id, environment), 8))

var appServicePlanName = '${prefix}-${environment}-plan'
var webAppName = toLower('${prefix}-${environment}-api-${uniqueSuffix}')
var cosmosAccountName = take('${safePrefix}${environment}${uniqueSuffix}cosmos', 44)
var searchServiceName = toLower('${prefix}-${environment}-search-${uniqueSuffix}')
var openAiAccountName = toLower('${prefix}-${environment}-aoai-${uniqueSuffix}')

module cosmos 'modules/cosmosdb.bicep' = {
  name: 'cosmos-deploy-${uniqueSuffix}'
  params: {
    accountName: cosmosAccountName
    location: location
    tags: tags
    databaseName: cosmosDatabaseName
    sessionsContainerName: sessionsContainerName
    messagesContainerName: messagesContainerName
    documentsContainerName: documentsContainerName
  }
}

module search 'modules/search.bicep' = {
  name: 'search-deploy-${uniqueSuffix}'
  params: {
    serviceName: searchServiceName
    location: location
    tags: tags
    sku: searchSku
  }
}

module openai 'modules/openai.bicep' = {
  name: 'openai-deploy-${uniqueSuffix}'
  params: {
    accountName: openAiAccountName
    location: location
    tags: tags
    deploymentName: openAiDeploymentName
    modelName: openAiModelName
    modelVersion: openAiModelVersion
    deploymentSkuName: openAiDeploymentSkuName
    deploymentCapacity: openAiDeploymentCapacity
  }
}

module app 'modules/appservice.bicep' = {
  name: 'app-deploy-${uniqueSuffix}'
  params: {
    location: location
    tags: tags
    appServicePlanName: appServicePlanName
    appServicePlanSkuName: appServicePlanSkuName
    webAppName: webAppName
    azureOpenAiEndpoint: openai.outputs.endpoint
    azureOpenAiKey: openai.outputs.primaryKey
    azureOpenAiDeploymentName: openAiDeploymentName
    cosmosEndpoint: cosmos.outputs.endpoint
    cosmosKey: cosmos.outputs.primaryKey
    cosmosDatabaseName: cosmosDatabaseName
    sessionsContainerName: sessionsContainerName
    messagesContainerName: messagesContainerName
    documentsContainerName: documentsContainerName
    searchEndpoint: search.outputs.endpoint
    searchKey: search.outputs.primaryKey
    searchIndexName: searchIndexName
  }
}

output appServiceName string = app.outputs.webAppName
output appServiceUrl string = app.outputs.defaultHostName
output cosmosEndpoint string = cosmos.outputs.endpoint
output searchEndpoint string = search.outputs.endpoint
output openAiEndpoint string = openai.outputs.endpoint
