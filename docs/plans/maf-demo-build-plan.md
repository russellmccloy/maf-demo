# 🗺️ Plan: Standalone MAF Demo Chat App

Build a minimal, demo-friendly standalone ASP.NET Core app that mirrors the core BuildAgentCore pipeline from Blueprints, uses Azure OpenAI Responses API with gpt-5.4, persists chat data in Cosmos DB, and provides RAG via Azure AI Search.

---

## ✅ Implementation Phases

### Phase 1 - Product and Repo Contract *(blocks all later phases)*

Product and repo-level documentation to establish contract and constraints.

1.1. **Update `docs/spec.md`** with the product spec and non-negotiable requirements:
   - Responses API only
   - Cosmos persistence for chats
   - Azure AI Search-backed RAG
   - SSE streaming architecture

1.2. **Update `.github/copilot-instructions.md`** with implementation constraints:
   - Minimal code style
   - Event naming contract
   - Azure AI Search indexing/retrieval patterns

1.3. **Update `AGENTS.md`** with execution workflow guidance:
   - Specific to this demo project
   - Handoff expectations and collaboration workflow

---

### Phase 2 - Solution Skeleton and Core Domain *(depends on Phase 1)*

Foundation layer with app structure and core models.

2.1. **Create a single ASP.NET Core app** that serves API + static UI from one deployable unit

2.2. **Define minimal domain models** for:
   - Chat sessions and messages
   - SSE envelope and tool events
   - RAG document chunks

2.3. **Define options/config contract** for:
   - Azure OpenAI Responses endpoint/key/model
   - Cosmos DB settings
   - Azure AI Search endpoint/key/index
   - App feature toggles

---

### Phase 3 - MAF Agent Pipeline *(depends on Phase 2)*

Core agent orchestration, BuildAgentCore-inspired.

3.1. **Implement MAFAgentFactory equivalent** demonstrating the BuildAgentCore flow:
   - Azure Responses client creation (stored output disabled pattern)
   - Chat client builder pipeline
   - Function invocation middleware wiring
   - AIAgent construction with ChatClientAgentOptions and tools

3.2. **Keep optional concerns out of v1** (with documented extension seams):
   - Compaction
   - Advanced content safety middleware
   - Advanced caching

3.3. **Implement runtime adapter/orchestrator** exposing a single streaming turn API surface

---

### Phase 4 - Tool Registry and Dummy Tools *(parallel with Phase 5 after Phase 2)*

Tool factory, registry, and example tool implementations.

4.1. **Implement ToolRegistry** with AIFunctionFactory.Create and stable tool IDs

4.2. **Add at least two demo tools** (e.g., `utc_now`, `echo`, `simple_math`)

4.3. **Emit SSE tool lifecycle events**:
   - `toolStarted`
   - `toolCompleted`
   - `toolFailed`

---

### Phase 5 - Cosmos Persistence + Azure AI Search RAG *(parallel with Phase 4 after Phase 2)*

Data layer and retrieval infrastructure.

5.1. **Create Cosmos containers and repository/services** for:
   - Chat sessions and messages

5.2. **Create Azure AI Search index resources** and app-layer services for:
   - RAG documents and chunks

5.3. **Implement ingest flow**:
   - txt/md upload → chunk → push to Azure AI Search index with metadata

5.4. **Implement retrieval flow**:
   - Azure AI Search query with top-k selection
   - Produces short context snippets for prompt augmentation

5.5. **Persist turn events/audit metadata** needed for:
   - Replaying streamed conversations in the UI

---

### Phase 6 - SSE-first Chat API + Minimal UI *(depends on Phase 3, 4, 5)*

Streaming API and frontend interface.

6.1. **Implement streaming endpoint** (`text/event-stream`):
   - Use typed SSE or equivalent minimal API/controller pattern

6.2. **Define event contract for UI rendering**:
   - `status`
   - `messageDelta`
   - `toolStarted` / `toolCompleted` / `toolFailed`
   - `retrievalUsed` (Azure AI Search context attached)
   - `tokenUsage` (if available)
   - `done` / `error` / `heartbeat`

6.3. **Add heartbeat frames** for:
   - Idle-safe long streams
   - Cancellation handling

6.4. **Build lightweight static UI** (single page) showing:
   - Conversation pane
   - Event timeline pane
   - Tool calls/results
   - Uploaded docs list

---

### Phase 7 - Azure Infrastructure *(depends on Phase 1; validate after Phase 2)*

Infrastructure as Code and resource provisioning.

7.1. **Create full Bicep structure** under `infra/`:
   - Modules and main composition
   - Parameter definitions

7.2. **Provision resources** in:
   - Subscription: `52afa81a-5223-421c-8240-097df590b9fe`
   - Resource group: `MAFDemo-rg`
   - Region: `australiaeast`

   Resources to provision:
   - App Service Plan (Free tier F1 where available)
   - Web App for ASP.NET Core app
   - Cosmos DB account with free-tier capability enabled
   - Cosmos database + required containers
   - Azure AI Search service + index definitions
   - Azure OpenAI/Foundry resource + gpt-5.4 GlobalStandard deployment
   - App settings wiring (endpoints, credentials, connection strings)

7.3. **Add deployment scripts/commands docs** for:
   - Deterministic provisioning
   - Teardown notes

7.4. **Document pricing caveats**:
   - Azure OpenAI model usage is not free-tier
   - Azure AI Search does not provide guaranteed no-cost production tier

---

### Phase 8 - Verification and Demo Readiness *(depends on Phase 6 and 7)*

End-to-end validation and demo documentation.

8.1. **Verify local flow**:
   - Upload doc → ask grounded question → observe retrieval and tool events → persisted chat reload

8.2. **Verify deployed flow** with same checks against Azure resources

8.3. **Add smoke tests** for:
   - SSE event order and terminal `done`/`error` events
   - Cosmos persistence of session/messages
   - Tool invocation path
   - RAG ingestion/retrieval happy path

8.4. **Produce demo runbook** in `docs/plans/` for repeatable live demos

---

## 📂 Relevant Files

- `docs/spec.md` — Product source of truth, architecture boundaries, acceptance criteria
- `.github/copilot-instructions.md` — Coding + architecture implementation conventions
- `AGENTS.md` — Collaboration and handoff workflow updates
- `docs/assisting-docs/maf-technologies.md` — Reference list of MAF technologies to selectively include
- `infra/main.bicep` — Root deployment composition
- `infra/modules/*.bicep` — Modularized resources (web, cosmos, search, openai, config)
- `docs/plans/maf-demo-build-plan.md` — Execution checklist/runbook (this file)

---

## 🔍 Verification Checklist

### Infrastructure Validation
- [ ] Run Bicep validation and what-if against `MAFDemo-rg` before create
- [ ] Deploy infra and confirm resource SKUs/free-tier settings are applied as planned

### API/Runtime Validation
- [ ] Run local app and stream one chat turn; confirm SSE includes `messageDelta` + `done`
- [ ] Trigger a tool call and confirm `toolStarted`/`toolCompleted` events
- [ ] Upload a txt/md doc, ask a grounded prompt, and confirm `retrievalUsed` event appears

### Persistence Validation
- [ ] Confirm chat messages are stored in Cosmos containers
- [ ] Confirm document chunks are indexed in Azure AI Search
- [ ] Restart app and verify prior chat session reload works

### Deployed Environment Validation
- [ ] Execute same chat/tool/RAG checks on Azure-hosted app
- [ ] Confirm gpt-5.4 deployment invocation succeeds via Responses endpoint

---

## 🧭 Key Decisions

| Decision | Choice |
|----------|--------|
| App shape | Single ASP.NET Core app (API + static UI) |
| RAG scope | txt/md ingest and chunking indexed in Azure AI Search |
| Hosting shape | Backend-only App Service with UI served from same app |
| Auth default | API key in app settings for demo simplicity |
| Endpoint strategy | Provision new resource/deployment in infra (not rely on existing) |
| In scope | Full infra Bicep, SSE event-rich UX, tool registry, Cosmos persistence, Azure AI Search indexing/retrieval |
| Excluded from v1 | Advanced compaction, complex content safety, advanced caching, multi-index search |

---

## 💡 Further Considerations

- **gpt-5.4 deployment policy**: Strict mode — fail deployment if gpt-5.4 GlobalStandard cannot be provisioned (no fallback model for v1)
- **SSE contract stability**: Lock event names in spec before coding; keep envelope shape aligned with Blueprints chat stream pattern to avoid frontend/backend drift
