# Deployment Guide

This document outlines how to deploy maf-demo to Azure using Bicep templates and GitHub Actions.

## Prerequisites

- Azure subscription with access to `australiaeast` region
- Azure CLI (`az` command)
- Resource group `MAFDemo-rg` created in `australiaeast` (or permissions to create it)
- Appropriate Azure role assignments (Contributor or equivalent)

## Manual Deployment

### 1. Validate Bicep Templates

```bash
cd infra

# Validate the Bicep template
az bicep build --file main.bicep

# Preview what will be deployed (what-if)
az deployment group what-if \
  --name maf-demo-what-if \
  --resource-group MAFDemo-rg \
  --template-file main.bicep \
  --parameters environment=prod
```

### 2. Deploy Infrastructure

```bash
# Deploy resources to the resource group
az deployment group create \
  --name maf-demo-deployment \
  --resource-group MAFDemo-rg \
  --template-file main.bicep \
  --parameters environment=prod
```

### 3. Retrieve Outputs

```bash
# Get deployment outputs (endpoints, keys, etc.)
az deployment group show \
  --name maf-demo-deployment \
  --resource-group MAFDemo-rg \
  --query properties.outputs
```

### 4. Configure App Settings

Update App Service configuration with outputs:

```bash
# Example (adjust based on deployment outputs)
az webapp config appsettings set \
  --resource-group MAFDemo-rg \
  --name maf-demo-api \
  --settings \
    AzureOpenAI__Endpoint="https://..." \
    AzureOpenAI__Key="..." \
    CosmosDb__Endpoint="https://..." \
    CosmosDb__Key="..." \
    AzureSearch__Endpoint="https://..." \
    AzureSearch__Key="..."
```

### 5. Deploy Application

Build and deploy the ASP.NET Core app:

```bash
cd ../src/MafDemo.Api

# Publish
dotnet publish -c Release -o ./publish

# Deploy to App Service (adjust app name as needed)
az webapp deployment source config-zip \
  --resource-group MAFDemo-rg \
  --name maf-demo-api \
  --src publish.zip
```

## Automated Deployment via GitHub Actions

### 1. Configure GitHub Secrets

Add the following secrets to your repository (`Settings` → `Secrets and variables` → `Actions`):

- `AZURE_SUBSCRIPTION_ID` — Azure subscription ID
- `AZURE_RESOURCE_GROUP` — Resource group name (e.g., `MAFDemo-rg`)
- `AZURE_CREDENTIALS` — Service Principal credentials (JSON format)

#### Create Service Principal

```bash
az ad sp create-for-rbac \
  --name "maf-demo-github-actions" \
  --role Contributor \
  --scopes /subscriptions/{SUBSCRIPTION_ID}/resourceGroups/MAFDemo-rg \
  --json-auth
```

Copy the output as the `AZURE_CREDENTIALS` secret.

### 2. Review Workflow Files

Workflows are located in `.github/workflows/`:

- **`validate.yml`** — Validates Bicep templates (runs on PR)
- **`deploy-infra.yml`** — Deploys infrastructure (runs on merge to `main`)
- **`deploy-app.yml`** — Builds and deploys app (runs after infra on merge to `main`)

### 3. Trigger Workflows

Workflows run automatically on:
- **Pull requests** → Run validation
- **Merge to main** → Run full deployment (infra + app)

Manually trigger:

```bash
# Trigger workflow from CLI
gh workflow run deploy-infra.yml
```

## Rollback

### Rollback Infrastructure

```bash
az deployment group delete \
  --resource-group MAFDemo-rg \
  --name maf-demo-deployment
```

### Rollback Application

Revert to a previous deployment slot or re-deploy previous app version:

```bash
az webapp deployment slot swap \
  --resource-group MAFDemo-rg \
  --name maf-demo-api \
  --slot staging
```

## Monitoring and Validation

### Check Deployment Status

```bash
az deployment group list \
  --resource-group MAFDemo-rg \
  --query '[].{name:name, state:properties.provisioningState}'
```

### Verify Resources

```bash
# List all resources in the resource group
az resource list \
  --resource-group MAFDemo-rg \
  --output table
```

### Check App Logs

```bash
# Stream app logs
az webapp log tail \
  --resource-group MAFDemo-rg \
  --name maf-demo-api
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| gpt-5.4 deployment fails | Check region/subscription quota. gpt-5.4 GlobalStandard may not be available in all regions. |
| Cosmos DB creation fails | Verify free-tier eligibility in your subscription. |
| Azure AI Search quota exceeded | Check pricing tier and adjust SKU if needed. |
| App Service deployment fails | Check logs: `az webapp log tail` |
| Missing configuration | Ensure all required app settings are set before app start. |

## Costs

Be aware of potential costs:
- **Azure OpenAI** — Model inference usage (not free tier)
- **Azure AI Search** — Service charges (minimal for demo scale)
- **Cosmos DB** — Storage and RU consumption
- **App Service Plan** — Free tier available (F1) with limitations

See `docs/spec.md` section 10 for cost details.

## Next Steps

After deployment:
1. Access app at App Service URL
2. Follow verification checklist in [`docs/plans/maf-demo-build-plan.md`](docs/plans/maf-demo-build-plan.md#-verification-checklist)
3. Test chat, RAG, and tool invocation end-to-end
