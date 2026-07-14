param accountName string
param location string
param tags object = {}

param databaseName string = 'maf-demo-db'
param sessionsContainerName string = 'sessions'
param messagesContainerName string = 'messages'
param documentsContainerName string = 'documents'

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2023-11-15' = {
  name: accountName
  location: location
  tags: tags
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    enableFreeTier: true
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
  }
}

resource sqlDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-11-15' = {
  name: databaseName
  parent: cosmosAccount
  properties: {
    resource: {
      id: databaseName
    }
  }
}

resource sessionsContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-11-15' = {
  name: sessionsContainerName
  parent: sqlDatabase
  properties: {
    resource: {
      id: sessionsContainerName
      partitionKey: {
        paths: [
          '/sessionId'
        ]
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [
          {
            path: '/*'
          }
        ]
      }
    }
  }
}

resource messagesContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-11-15' = {
  name: messagesContainerName
  parent: sqlDatabase
  properties: {
    resource: {
      id: messagesContainerName
      partitionKey: {
        paths: [
          '/sessionId'
        ]
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [
          {
            path: '/*'
          }
        ]
      }
    }
  }
}

resource documentsContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-11-15' = {
  name: documentsContainerName
  parent: sqlDatabase
  properties: {
    resource: {
      id: documentsContainerName
      partitionKey: {
        paths: [
          '/id'
        ]
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [
          {
            path: '/*'
          }
        ]
      }
    }
  }
}

var keyList = cosmosAccount.listKeys()

output accountName string = cosmosAccount.name
output endpoint string = cosmosAccount.properties.documentEndpoint
@secure()
output primaryKey string = keyList.primaryMasterKey
