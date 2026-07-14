# Deployment Guide

This document explains how to deploy maf-demo infrastructure to Azure using the Bicep templates in infra and optional GitHub Actions workflows.

## Current Scope

- Infrastructure deployment is ready now.
- Application runtime deployment from src is pending because the src directory is not yet present in this repo snapshot.

## Prerequisites

- Azure subscription with access to australiaeast
- Azure CLI (az)
- Permissions to create resources in resource group MAFDemo-rg
- Optional: GitHub repository secrets for workflow-based deployment

Recommended defaults from plan/spec:
- Subscription: 52afa81a-5223-421c-8240-097df590b9fe
- Resource group: MAFDemo-rg
- Region: australiaeast

## Manual Infrastructure Deployment

### 1. Ensure resource group exists

```bash
az group create \
  --name MAFDemo-rg \
  --location australiaeast
```

### 2. Validate templates

```bash
az bicep build --file infra/main.bicep
```

### 3. Preview deployment

```bash
az deployment group what-if \
  --name maf-demo-what-if \
  --subscription 52afa81a-5223-421c-8240-097df590b9fe \
  --resource-group MAFDemo-rg \
  --template-file infra/main.bicep \
  --parameters @infra/main.parameters.json
```

### 4. Deploy infrastructure

```bash
az deployment group create \
  --name maf-demo-deployment \
  --subscription 52afa81a-5223-421c-8240-097df590b9fe \
  --resource-group MAFDemo-rg \
  --template-file infra/main.bicep \
  --parameters @infra/main.parameters.json
```

### 5. Review outputs

```bash
az deployment group show \
  --name maf-demo-deployment \
  --subscription 52afa81a-5223-421c-8240-097df590b9fe \
  --resource-group MAFDemo-rg \
  --query properties.outputs
```

Outputs include app service name/url plus service endpoints.

## App Configuration Notes

The infra template already sets these required app settings on the Web App:

- AzureOpenAI__Endpoint
- AzureOpenAI__Key
- AzureOpenAI__ModelDeploymentName
- CosmosDb__Endpoint
- CosmosDb__Key
- CosmosDb__DatabaseName
- CosmosDb__SessionsContainerName
- CosmosDb__MessagesContainerName
- CosmosDb__DocumentsContainerName
- AzureSearch__Endpoint
- AzureSearch__Key
- AzureSearch__IndexName

If you need to override values manually:

```bash
az webapp config appsettings set \
  --subscription 52afa81a-5223-421c-8240-097df590b9fe \
  --resource-group MAFDemo-rg \
  --name <app-service-name> \
  --settings \
    AzureOpenAI__Endpoint="https://<resource>.openai.azure.com/" \
    AzureOpenAI__Key="<key>" \
    AzureOpenAI__ModelDeploymentName="gpt-5.4"
```

## Application Deployment Status

Application deployment commands are intentionally not included here yet because src/MafDemo.Api is not present.

When runtime code is added, deployment should use:

1. dotnet publish to create app artifacts
2. zip artifact creation
3. az webapp deployment source config-zip against the deployed app service name

## GitHub Actions

Workflows currently in this repo:

- .github/workflows/validate.yml
- .github/workflows/deploy-infra.yml
- .github/workflows/deploy-app.yml

Required secrets:

- AZURE_SUBSCRIPTION_ID
- AZURE_RESOURCE_GROUP
- AZURE_CREDENTIALS

Create service principal:

```bash
az ad sp create-for-rbac \
  --name "maf-demo-github-actions" \
  --role Contributor \
  --scopes /subscriptions/52afa81a-5223-421c-8240-097df590b9fe/resourceGroups/MAFDemo-rg \
  --json-auth
```

## Rollback and Cleanup

Delete deployment history record only:

```bash
az deployment group delete \
  --name maf-demo-deployment \
  --subscription 52afa81a-5223-421c-8240-097df590b9fe \
  --resource-group MAFDemo-rg
```

Delete all deployed resources (destructive):

```bash
az group delete \
  --name MAFDemo-rg \
  --subscription 52afa81a-5223-421c-8240-097df590b9fe \
  --yes \
  --no-wait
```

## Validation and Troubleshooting

Check resource inventory:

```bash
az resource list \
  --subscription 52afa81a-5223-421c-8240-097df590b9fe \
  --resource-group MAFDemo-rg \
  --output table
```

Check app logs:

```bash
az webapp log tail \
  --subscription 52afa81a-5223-421c-8240-097df590b9fe \
  --resource-group MAFDemo-rg \
  --name <app-service-name>
```

Common issues:

| Issue | Suggested action |
|-------|------------------|
| gpt-5.4 deployment fails | Check region availability/quota for GlobalStandard in australiaeast. |
| Cosmos DB free tier conflict | Free tier is subscription-limited; disable free tier or use another subscription. |
| Search SKU quota issue | Change searchSku in infra/main.parameters.json. |
| App fails on startup | Confirm required settings are present, especially AzureOpenAI__ModelDeploymentName. |

## Costs

Potential charges:

- Azure OpenAI inference (not free tier)
- Azure AI Search service tier
- Cosmos DB storage and throughput
- App Service plan

See docs/spec.md section 10 for cost constraints.
