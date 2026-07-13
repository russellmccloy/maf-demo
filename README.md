# maf-demo

A minimal, demo-friendly **standalone ASP.NET Core application** that showcases core Microsoft Agent Framework (MAF) patterns inspired by Blueprints.

## 🎯 What This Is

A reference implementation demonstrating:
- **MAF runtime composition** — BuildAgentCore-style agent pipeline
- **Azure OpenAI Responses API** — gpt-5.4 model integration
- **Chat persistence** — Cosmos DB session and message storage
- **RAG with Azure AI Search** — Document upload, chunking, indexing, and retrieval
- **Server-Sent Events (SSE)** — Streaming tool lifecycle and retrieval events to UI
- **Infrastructure as Code** — Complete Bicep templates for deployable infrastructure

## 📋 Quick Start

### Prerequisites
- .NET 10+ SDK
- Azure subscription with resources in `australiaeast` region
- Azure CLI for deployment

### Local Development
```bash
# Clone and build
git clone https://github.com/russellmccloy/maf-demo.git
cd maf-demo
dotnet build

# Configure (see docs/spec.md for required settings)
# dotnet user-secrets set "AzureOpenAI:Endpoint" "https://..."
# dotnet user-secrets set "AzureOpenAI:Key" "..."

# Run
dotnet run --project src/MafDemo.Api
# Open http://localhost:5000
```

## 📚 Documentation

- **[`docs/spec.md`](docs/spec.md)** — Product specification and acceptance criteria
- **[`docs/plans/maf-demo-build-plan.md`](docs/plans/maf-demo-build-plan.md)** — 8-phase implementation roadmap
- **[`.github/copilot-instructions.md`](.github/copilot-instructions.md)** — Implementation and architecture guidelines
- **[`AGENTS.md`](AGENTS.md)** — Collaboration workflow and handoff rules
- **[`docs/assisting-docs/maf-technologies.md`](docs/assisting-docs/maf-technologies.md)** — MAF technology reference
- **[`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md)** — Deployment guide (manual and GitHub Actions)

## 🏗️ Architecture

```
maf-demo/
├── src/
│   └── MafDemo.Api/          # Single ASP.NET Core app (API + static UI)
├── infra/
│   ├── main.bicep            # Root deployment
│   └── modules/              # Resource modules (web, cosmos, search, openai, config)
├── docs/
│   ├── spec.md               # Requirements and acceptance criteria
│   ├── plans/
│   │   └── maf-demo-build-plan.md
│   ├── assisting-docs/
│   │   └── maf-technologies.md
│   └── DEPLOYMENT.md
└── .github/
    ├── workflows/            # CI/CD pipelines
    └── copilot-instructions.md
```

## 🔑 Key Features

### Streaming API
- **SSE endpoint** for real-time chat streaming
- **Tool lifecycle events** — toolStarted, toolCompleted, toolFailed
- **RAG events** — retrievalUsed with chunk metadata
- **Terminal events** — done or error

### Persistence
- **Cosmos DB** — Sessions and message history
- **Azure AI Search** — Document chunks indexed for retrieval

### Tools
- Simple **ToolRegistry** pattern with stable tool IDs
- Example tools: `utc_now`, `echo`, `simple_math`

### Infrastructure
- **Bicep templates** under `infra/`
- Target: `australiaeast` region, `MAFDemo-rg` resource group
- Resources: App Service, Cosmos DB, Azure AI Search, Azure OpenAI (gpt-5.4)

## 🚀 Deployment

See [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) for detailed deployment instructions.

Quick reference:
```bash
cd infra
az deployment group create \
  --resource-group MAFDemo-rg \
  --template-file main.bicep \
  --parameters environment=prod
```

## 🧪 Validation

All phases include validation steps. See [`docs/plans/maf-demo-build-plan.md`](docs/plans/maf-demo-build-plan.md#-verification-checklist) for the full verification checklist.

## 📝 License

TBD

## 👥 Contributing

Follow [`AGENTS.md`](AGENTS.md) for collaboration guidelines and handoff workflow.
