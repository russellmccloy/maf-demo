# 🗺️ Plan: Standalone MAF Demo Chat App

Build a minimal, demo-friendly standalone ASP.NET Core app that mirrors the core BuildAgentCore pipeline from Blueprints, uses Azure OpenAI Responses API with gpt-5.4, persists chat data in Cosmos DB, indexes and retrieves documents with Azure AI Search for RAG, streams full SSE event traces to the UI (including tool lifecycle events), and includes complete low-cost Azure Bicep in /infra. Keep architecture intentionally small, readable, and "spacious," while preserving the key MAF concepts you want to showcase.

## ✅ Steps

1. 📘 Phase 1 - Product and Repo Contract (*blocks all later phases*)
1.1 Update c:\Users\RussellMcCloy\code\maf-demo\docs\spec.md with the product spec and non-negotiable requirements: Responses API only, Cosmos persistence for chats, Azure AI Search-backed RAG, SSE-first event stream, tool registry, gpt-5.4 deployment, free/lowest-cost infra defaults where possible.
1.2 Update c:\Users\RussellMcCloy\code\maf-demo\.github\copilot-instructions.md with implementation constraints for this repo: minimal code style, event naming contract, Azure AI Search indexing/retrieval boundaries, and architecture boundaries.
1.3 Update c:\Users\RussellMcCloy\code\maf-demo\AGENTS.md to include execution workflow guidance and handoff expectations specific to this demo project.

2. 🧱 Phase 2 - Solution Skeleton and Core Domain (*depends on 1*)
2.1 Create a single ASP.NET Core app that serves API + static UI from one deployable unit.
2.2 Define minimal domain models for chat sessions, messages, SSE envelope, tool events, and RAG document chunks.
2.3 Define options/config contract for Azure OpenAI Responses endpoint/key/model + Cosmos DB settings + Azure AI Search endpoint/key/index settings + app feature toggles.

3. 🤖 Phase 3 - MAF Agent Pipeline (BuildAgentCore-inspired) (*depends on 2*)
3.1 Implement a slim MAFAgentFactory equivalent that demonstrates the key BuildAgentCore flow:

- Azure Responses client creation (stored output disabled pattern where applicable)
- chat client builder pipeline
- function invocation middleware wiring
- AIAgent construction with ChatClientAgentOptions and tools
3.2 Keep optional concerns out of v1 (compaction, advanced content safety middleware, advanced caching), but leave extension seams documented.
3.3 Implement a simple runtime adapter/orchestrator that exposes a single streaming turn API surface.

1. 🛠️ Phase 4 - Tool Registry and Dummy Tools (*parallel with 5 after 2; consumed by 3 and 6*)
4.1 Implement ToolRegistry with AIFunctionFactory.Create and stable tool IDs.
4.2 Add at least two demo tools (example: utc_now, echo, simple_math).
4.3 Emit SSE tool lifecycle events: toolStarted, toolCompleted, toolFailed.

2. 💾 Phase 5 - Cosmos Persistence + Azure AI Search RAG (*parallel with 4 after 2; consumed by 6*)
5.1 Create Cosmos containers and repository/services for:

- chat sessions/messages
5.2 Create Azure AI Search index resources and app-layer indexing/retrieval services for RAG documents/chunks.
5.3 Implement ingest flow (txt/md upload -> chunk -> push chunks and metadata to Azure AI Search index).
5.4 Implement retrieval flow (Azure AI Search query with top-k selection) to produce short context snippets for prompt augmentation.
5.5 Persist turn events/audit metadata needed for replaying streamed conversations in the UI.

1. 🌊 Phase 6 - SSE-first Chat API + Minimal UI (*depends on 3, 4, 5*)
6.1 Implement streaming endpoint (text/event-stream) using typed SSE or equivalent minimal API/controller pattern.
6.2 Define event contract for UI rendering:

- status
- messageDelta
- toolStarted/toolCompleted/toolFailed
- retrievalUsed (Azure AI Search context attached)
- tokenUsage (if available)
- done/error/heartbeat
6.3 Add heartbeat frames (for idle-safe long streams) and cancellation handling.
6.4 Build lightweight static UI (single page) showing:
- conversation pane
- event timeline pane
- tool calls/results
- uploaded docs list

1. ☁️ Phase 7 - Azure Infrastructure in /infra (*depends on 1; can be built in parallel with 2-6 but validated after app config is fixed*)
7.1 Create full Bicep structure under c:\Users\RussellMcCloy\code\maf-demo\infra including modules + main + parameters.
7.2 Provision resources in subscription 52afa81a-5223-421c-8240-097df590b9fe, resource group MAFDemo-rg, region australiaeast:

- App Service Plan (Free tier F1 where available)
- Web App for the single ASP.NET Core app
- Cosmos DB account with free-tier capability enabled (where available in region/subscription constraints)
- Cosmos database + required containers
- Azure AI Search service and required index definitions for document retrieval
- Azure OpenAI/Foundry resource and deployment targeting gpt-5.4 GlobalStandard (if deployment APIs/capacity allow in this environment)
- App settings wiring (endpoint, model/deployment name, Cosmos connection values, Azure AI Search connection/index values)
7.3 Add deployment scripts/commands docs for deterministic provisioning and teardown notes.
7.4 Document unavoidable pricing caveat: Azure OpenAI model usage is not free-tier, and Azure AI Search does not provide a guaranteed no-cost production tier, even when other resources use free/lowest-cost SKUs.

1. 🧪 Phase 8 - Verification and Demo Readiness (*depends on 6 and 7*)
8.1 Verify local flow end-to-end: upload doc -> ask grounded question -> observe retrieval and tool events -> persisted chat reload.
8.2 Verify deployed flow with same checks against Azure resources.
8.3 Add smoke tests (or scripted checks) for:

- SSE event order and terminal done/error events
- Cosmos persistence of session/messages
- tool invocation path
- RAG ingestion/retrieval happy path
8.4 Produce short demo runbook in docs/plans for repeatable live demos.

## 📂 Relevant files

- c:\Users\RussellMcCloy\code\maf-demo\docs\spec.md - product source of truth, architecture boundaries, acceptance criteria.
- c:\Users\RussellMcCloy\code\maf-demo\.github\copilot-instructions.md - coding + architecture implementation conventions.
- c:\Users\RussellMcCloy\code\maf-demo\AGENTS.md - collaboration and handoff workflow updates.
- c:\Users\RussellMcCloy\code\maf-demo\docs\assisting-docs\maf-technologies.md - reference list of MAF technologies to selectively include.
- c:\Users\RussellMcCloy\code\maf-demo\infra\main.bicep - root deployment composition.
- c:\Users\RussellMcCloy\code\maf-demo\infra\modules\*.bicep - modularized resources (web, cosmos, search, openai, config).
- c:\Users\RussellMcCloy\code\maf-demo\docs\plans\maf-demo-build-plan.md - execution checklist/runbook from this plan.

## 🔍 Verification

1. Infrastructure validation
1.1 Run Bicep validation and what-if against MAFDemo-rg before create.
1.2 Deploy infra and confirm resource SKUs/free-tier settings are applied as planned.
2. API/runtime validation
2.1 Run local app and stream one chat turn; confirm SSE includes messageDelta + done.
2.2 Trigger a tool call and confirm toolStarted/toolCompleted events.
2.3 Upload a txt/md doc, ask a grounded prompt, and confirm retrievalUsed event appears from Azure AI Search results.
3. Persistence validation
3.1 Confirm chat messages are stored in Cosmos containers.
3.2 Confirm document chunks are indexed in Azure AI Search.
3.3 Restart app and verify prior chat session reload works.
4. Deployed environment validation
4.1 Execute the same chat/tool/RAG checks on Azure-hosted app.
4.2 Confirm gpt-5.4 deployment invocation succeeds via Responses endpoint.

## 🧭 Decisions

- App shape: single ASP.NET Core app (API + static UI).
- RAG scope: txt/md ingest and chunking indexed in Azure AI Search for retrieval.
- Hosting shape: backend-only App Service with UI served from same app.
- Auth default: API key in app settings for demo simplicity.
- Endpoint strategy: provision new resource/deployment in infra (not rely on existing screenshot endpoint).
- Include in scope: full infra Bicep under /infra, SSE event-rich UX, tool registry, Cosmos persistence for chats, Azure AI Search indexing and retrieval.
- Exclude from v1: advanced compaction pipeline, complex content safety middleware, advanced cache invalidation, multi-index search topologies.

## 💡 Further Considerations

1. gpt-5.4 deployment policy: strict mode, fail deployment if gpt-5.4 GlobalStandard cannot be provisioned (no fallback model for v1).
2. Cosmos free tier constraint note: free tier applies to one account per subscription and may be subject to region/account limits; template should expose a switch to disable free-tier flag when not eligible.
3. SSE contract stability: lock event names in spec before coding to avoid frontend/backend drift.
