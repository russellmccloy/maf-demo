param serviceName string
param location string
param tags object = {}

@allowed([
  'basic'
  'free'
  'standard'
  'standard2'
  'standard3'
])
param sku string = 'basic'

resource searchService 'Microsoft.Search/searchServices@2023-11-01' = {
  name: serviceName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
    publicNetworkAccess: 'enabled'
    disableLocalAuth: false
  }
}

var adminKeys = searchService.listAdminKeys()

output serviceName string = searchService.name
output endpoint string = 'https://${searchService.name}.search.windows.net'
@secure()
output primaryKey string = adminKeys.primaryKey
