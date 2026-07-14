# MAF Demo Specification 🚀

## 1. Goal 🎯

Build a standalone, minimal demo app that shows the core Microsoft Agent Framework patterns used in Blueprints, especially the BuildAgentCore-style pipeline, while staying simple enough for live demos and onboarding.

The app must:

- Use Azure OpenAI Responses API for all model calls.
- Use direct Azure OpenAI endpoint-based integration in code (no Foundry agent runtime dependency).
- Allow the Azure OpenAI endpoint to be provisioned from Foundry, but treat it as a standard Azure OpenAI endpoint at runtime.
- Use gpt-5.4 as the required model deployment.
- Persist chat data in Cosmos DB through ChatHistoryProvider-based persistence.
- Use Azure AI Search for document indexing and retrieval (RAG).
- Stream full server events to the UI over SSE, including tool lifecycle events.
- Include infra Bicep in an infra folder at repo root.

## 2. Audience 👥

- Primary: internal developers and architects reviewing MAF patterns.
- Secondary: onboarding developers who need a small, readable reference implementation.

## 3. Scope 📌

### In scope ✅

- Single ASP.NET Core app hosting both API and static UI.
- BuildAgentCore-inspired runtime composition for chat, tools, and streaming.
- Tool registry with at least two dummy tools.
- Chat session and message persistence in Cosmos DB.
- Document upload, chunking, Azure AI Search indexing, and retrieval for RAG.
- SSE event stream from backend to UI with typed event names.
- Azure Bicep templates for deployable demo infrastructure.

### Out of scope (v1) 🚫

- Hosted Foundry agent runtime in application code.
- Complex or experimental safety frameworks beyond documented Agent Framework safety best practices.
- Multi-index or advanced search topology.
- Multi-region deployment patterns.

## 4. Functional Requirements ⚙️

### FR-1 Chat runtime 💬

- The backend shall run user turns through a MAF agent pipeline inspired by BuildAgentCore.
- The backend shall use the Azure OpenAI Responses API endpoint and deployment model configuration using direct endpoint calls.
- The backend shall fail startup or request execution when required OpenAI configuration is missing.
- The backend shall compose the runtime using a declarative builder pipeline pattern for agent, middleware, context providers, tools, and telemetry.

### FR-2 Streaming contract 📡

- The backend shall expose a streaming endpoint using text/event-stream.
- The backend shall emit these event types:
  - status
  - messageDelta
  - toolStarted
  - toolCompleted
  - toolFailed
  - retrievalUsed
  - tokenUsage (when available)
  - heartbeat
  - done
  - error
- The backend shall send heartbeat events during long-running turns.

### FR-3 Tooling 🛠️

- The app shall define a ToolRegistry abstraction with stable tool IDs.
- The app shall include at least two simple tools for demos (for example utc_now and echo).
- Tool lifecycle shall be surfaced in SSE events.

### FR-4 Chat persistence 💾

- The app shall store chat sessions and messages in Cosmos DB through ChatHistoryProvider-based persistence.
- The app shall support reloading an existing session history.
- The app shall implement chat history persistence through ChatHistoryProvider-based wiring.
- The ChatHistoryProvider implementation shall be stateless per provider instance and keep session-specific values in AgentSession state.
- The runtime shall support per-service-call history persistence behavior when needed for tool-loop resiliency.

### FR-4.1 Conversation compaction 🗜️

- The app shall include compaction as a mandatory runtime capability.
- The compaction design shall follow Agent Framework compaction guidance and be explicitly configured in the runtime pipeline.
- The app shall document trigger strategy and summarizer model usage for compaction behavior.

### FR-5 RAG with Azure AI Search 🔎

- The app shall allow upload of txt and md files.
- The app shall chunk uploaded text using a simple, deterministic strategy.
- The app shall index chunks and metadata into Azure AI Search.
- The app shall retrieve top-k chunks from Azure AI Search and attach retrieval metadata to retrievalUsed events.

### FR-5.1 Safety controls 🛡️

- The app shall apply Agent Framework safety best-practice controls as mandatory requirements.
- Tool arguments supplied by the model shall be treated as untrusted input and validated per tool.
- High-risk tools shall require explicit approval or equivalent guardrails.
- The app shall keep system-role instructions developer-controlled and never inject end-user input into system role messages.
- The app shall sanitize model and tool output before rendering in UI or passing into sensitive sinks.

### FR-6 Infrastructure 🏗️

- Bicep files shall exist under infra and support deployment to:
  - Subscription: 52afa81a-5223-421c-8240-097df590b9fe
  - Resource Group: MAFDemo-rg
  - Region: australiaeast
- Infra shall include:
  - App Service Plan (free tier where available)
  - Web App
  - Cosmos DB account, database, and containers
  - Azure AI Search service
  - Azure OpenAI resource and gpt-5.4 GlobalStandard deployment
- gpt-5.4 deployment is strict for v1. If deployment cannot be created, deployment fails (no fallback model).

## 5. Non-Functional Requirements 📏

- Code should be intentionally simple and spacious for demo readability.
- Keep architecture modular enough to add optional advanced features later.
- Use clear naming and small classes/files over dense abstractions.
- Ensure local and deployed environments follow the same event contract.

## 6. Data Model (minimum) 🗂️

- ChatSession
  - id
  - userId
  - createdAt
  - updatedAt
- ChatMessage
  - id
  - sessionId
  - role
  - content
  - createdAt
- RagDocument
  - id
  - filename
  - uploadedAt
- RagChunk (indexed in Azure AI Search)
  - chunkId
  - documentId
  - chunkText
  - metadata

## 7. API Surface (minimum) 🌐

- POST stream chat turn endpoint (SSE response).
- POST upload document endpoint.
- GET session history endpoint.

Exact routes are implementation-defined but must remain stable once first UI integration is complete.

## 8. Configuration ⚙️

Required app settings:

- Azure OpenAI Responses endpoint
- Azure OpenAI API key (v1 default auth mode)
- Model deployment name (gpt-5.4)
- Cosmos DB connection and container settings
- Azure AI Search endpoint, key, and index name

## 9. Acceptance Criteria ✅

The demo is accepted when all conditions are met:

1. A user can upload a txt or md file, and chunks are indexed in Azure AI Search.
2. A user can ask a question and receive streamed messageDelta events followed by done.
3. A tool invocation emits toolStarted and toolCompleted (or toolFailed).
4. A grounded prompt emits retrievalUsed with Azure AI Search context details.
5. Chat sessions and messages are persisted and can be reloaded.
6. Compaction is active and demonstrably reduces long-turn history according to configured triggers.
7. Safety controls are active: tool input validation and system-role isolation are verifiable in implementation.
8. Bicep deploys required resources to MAFDemo-rg in australiaeast.
9. The app successfully calls gpt-5.4 via Responses API.

## 10. Risks and Constraints ⚠️

- Azure OpenAI usage is not free tier.
- Azure AI Search has cost implications and should be sized minimally for the demo.
- Cosmos free tier eligibility is subscription-limited.

## 11. References 📚

- Plan document: docs/plans/maf-demo-build-plan.md
- MAF technology reference: docs/assisting-docs/maf-technologies.md
- Azure OpenAI Responses API docs: https://learn.microsoft.com/azure/foundry/openai/how-to/responses
- Agent Framework ChatHistoryProvider docs: https://learn.microsoft.com/dotnet/api/microsoft.agents.ai.chathistoryprovider?view=agent-framework-dotnet-latest
- Agent Framework compaction docs: https://learn.microsoft.com/agent-framework/agents/conversations/compaction
- Agent Framework safety docs: https://learn.microsoft.com/agent-framework/agents/safety
