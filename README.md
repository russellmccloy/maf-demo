# maf-demo

A docs-first repository for building a minimal, demo-friendly standalone ASP.NET Core application that showcases core Microsoft Agent Framework (MAF) patterns inspired by Blueprints.

## 🎯 What This Is

A planned reference implementation demonstrating:

- **MAF runtime composition** — BuildAgentCore-style agent pipeline
- **Azure OpenAI Responses API** — gpt-5.4 model integration
- **Chat persistence** — Cosmos DB via ChatHistoryProvider-based persistence
- **RAG with Azure AI Search** — Document upload, chunking, indexing, and retrieval
- **Server-Sent Events (SSE)** — Streaming tool lifecycle and retrieval events to UI
- **Infrastructure as Code** — Bicep templates under `infra/`

## 📋 Current Status

This repository currently contains product docs, plan docs, and workflow scaffolding.

- Product requirements are defined in `docs/spec.md`.
- Implementation order is defined in `docs/plans/maf-demo-build-plan.md`.
- Runtime and infrastructure code directories (`src/` and `infra/`) are planned but not yet present in this repo snapshot.

## 📋 Quick Start

### Prerequisites

- Markdown-capable editor (VS Code recommended)
- Azure subscription details ready for later implementation phases

### Docs-First Workflow

```bash
# Clone and review documentation
git clone https://github.com/russellmccloy/maf-demo.git
cd maf-demo
```

Read in this order:

1. `docs/spec.md`
2. `docs/plans/maf-demo-build-plan.md`
3. `.github/copilot-instructions.md`
4. `AGENTS.md`

## 📚 Documentation

- **[`docs/spec.md`](docs/spec.md)** — Product specification and acceptance criteria
- **[`docs/plans/maf-demo-build-plan.md`](docs/plans/maf-demo-build-plan.md)** — 8-phase implementation roadmap
- **[`.github/copilot-instructions.md`](.github/copilot-instructions.md)** — Coding guardrails for contributors and agents
- **[`AGENTS.md`](AGENTS.md)** — Collaboration workflow and handoff rules
- **[`docs/assisting-docs/maf-technologies.md`](docs/assisting-docs/maf-technologies.md)** — MAF technology reference
- **[`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md)** — Deployment guide (manual and GitHub Actions)

## 🏗️ Architecture

```markdown
maf-demo/
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

Planned directories (not yet present in this snapshot):

- `src/` for application code
- `infra/` for Bicep templates

## 🔑 Target Features

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

- **Bicep templates** under `infra/` (planned)
- Target: `australiaeast` region, `MAFDemo-rg` resource group
- Resources: App Service, Cosmos DB, Azure AI Search, Azure OpenAI (gpt-5.4)

## 🚀 Deployment

See [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) for deployment guidance and workflow intent.

Note: deployment commands assume `infra/` and application artifacts exist.

Quick reference becomes applicable once infrastructure templates are added.

## 🧪 Validation

All phases include validation steps. See [`docs/plans/maf-demo-build-plan.md`](docs/plans/maf-demo-build-plan.md#-verification-checklist) for the full verification checklist.

## 📝 License

TBD

## 👥 Contributing

Follow [`AGENTS.md`](AGENTS.md) for collaboration guidelines and handoff workflow.
