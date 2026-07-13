# Copilot Instructions

## Purpose
These instructions define how to implement and review code in this repository.

Follow docs/spec.md as the source of truth.

## Product Direction
- Build a standalone demo app that highlights MAF runtime composition patterns.
- Keep code minimal, readable, and demo-friendly.
- Prefer simple, explicit code over abstract frameworks.

## Required Stack and Architecture
- Backend: ASP.NET Core (single app that also serves static UI).
- LLM API: Azure OpenAI Responses API only.
- Required model: gpt-5.4 deployment.
- Chat persistence: Cosmos DB.
- RAG indexing and retrieval: Azure AI Search.
- Streaming protocol: SSE (text/event-stream) from backend to UI.

## Runtime Pattern Requirements
When implementing the runtime, mirror the BuildAgentCore style at a lightweight level:
- Create and configure the Azure Responses client.
- Build the chat client pipeline with tool invocation middleware.
- Build the agent with instructions and registered tools.
- Stream updates through a single orchestrator path.

Avoid adding v1 complexity unless explicitly requested:
- No advanced compaction pipeline.
- No heavy content safety middleware chain.
- No multi-index search topology.

## SSE Event Contract
Event names are part of the public contract. Keep them stable:
- status
- messageDelta
- toolStarted
- toolCompleted
- toolFailed
- retrievalUsed
- tokenUsage
- heartbeat
- done
- error

Rules:
- Include heartbeat events for long-running turns.
- Always send a terminal event (done or error).
- Include tool lifecycle metadata whenever tools are invoked.

### Tool Lifecycle Events
Tool events must include the following fields:

**toolStarted**
```json
{
  "type": "toolStarted",
  "toolId": "string (stable identifier)",
  "toolName": "string (human-readable name)",
  "timestamp": "ISO8601",
  "input": "object or string (tool arguments)"
}
```

**toolCompleted**
```json
{
  "type": "toolCompleted",
  "toolId": "string",
  "toolName": "string",
  "timestamp": "ISO8601",
  "durationMs": "number",
  "output": "object or string (tool result)",
  "status": "success"
}
```

**toolFailed**
```json
{
  "type": "toolFailed",
  "toolId": "string",
  "toolName": "string",
  "timestamp": "ISO8601",
  "durationMs": "number",
  "error": "string (error message)",
  "status": "failed"
}
```

## Tool Registry and Lifecycle
- Register tools with a stable tool ID (e.g., "utc_now", "echo", "simple_math").
- Tool IDs must remain consistent between client and runtime for the lifecycle of the demo.
- Implement ToolRegistry as a simple registry pattern that maps tool ID → AIFunction implementation.
- Tool functions must return deterministic, serializable results.
- Emit tool events synchronously with tool execution; ensure events are delivered before the tool result is included in the assistant response.

## Data and Search Rules

### Cosmos DB Model Conventions
- Entity IDs: use "entityType-guid" format (e.g., "session-abc123", "message-def456").
- Container names: plural and lowercase (e.g., "sessions", "messages", "documents").
- Partition keys:
  - "sessions" container: partition by sessionId.
  - "messages" container: partition by sessionId (for efficient per-session queries).
  - "documents" container: partition by uploadedBy or /id if single-user demo.
- Always include `createdAt` and `updatedAt` timestamps (ISO8601 UTC).

### Document Chunking Rules
- Use fixed-size chunks: **500 tokens or 1500 characters** (with overlap of **100 tokens or 300 characters**).
- Include metadata with every chunk:
  - `sourceFilename`: original filename uploaded.
  - `chunkIndex`: zero-based chunk number within document.
  - `documentId`: reference to parent document.
- Chunking must be **deterministic**: uploading the same file twice produces identical chunks with identical IDs.
- Chunk ID format: "chunk-{documentId}-{chunkIndex}".

### Azure AI Search Index Structure
- Index name: "rag-documents".
- Key field: "chunkId" (must be unique).
- Searchable fields: "chunkText", "metadata".
- Retrievable fields: "chunkId", "chunkText", "sourceFilename", "documentId", "chunkIndex".
- Default retrieval: top-k = 3 chunks sorted by search relevance score.
- Indexing must happen synchronously after chunking so chunks are immediately queryable.

### Retrieval Metadata in Events
When a RAG query is used, attach full retrieval context to `retrievalUsed` event:

```json
{
  "type": "retrievalUsed",
  "timestamp": "ISO8601",
  "query": "string (user question fragment used for search)",
  "chunks": [
    {
      "chunkId": "string",
      "sourceFilename": "string",
      "chunkIndex": "number",
      "chunkText": "string",
      "relevanceScore": "number (0.0-1.0 or search engine native score)"
    }
  ],
  "totalMatches": "number"
}
```

## Simplicity Rules
- Keep files small and focused.
- Use clear names that read well in demos.
- Add comments only when intent is not obvious.
- Avoid premature abstraction and unnecessary layers.

## Configuration Rules
Expect configuration for:
- OpenAI endpoint and key
- model deployment name (gpt-5.4)
- Cosmos DB settings (endpoint, key, database name)
- Azure AI Search endpoint, key, and index name

Fail fast when required configuration is missing. Log which config is missing at startup.

## Infrastructure Rules
- Infrastructure code must live under infra.
- Bicep must include App Service, Cosmos DB, Azure AI Search, and Azure OpenAI resources.
- Deployment target defaults:
	- Subscription: 52afa81a-5223-421c-8240-097df590b9fe
	- Resource Group: MAFDemo-rg
	- Region: australiaeast
- gpt-5.4 deployment is strict for v1. Do not add model fallback unless requested.

## Testing and Validation Rules
For new runtime features, verify:
- SSE event order and terminal behavior.
- Tool lifecycle event emission (toolStarted → toolCompleted/toolFailed).
- Chat persistence and reload (session reopen restores full history).
- Upload/index/retrieve flow for Azure AI Search RAG:
  - File upload triggers indexing.
  - Query finds indexed chunks within 1 second.
  - Chunk content appears correctly in UI.

## Change Management
- Prefer minimal patches over broad rewrites.
- Keep plan, spec, and implementation aligned.
- If a requirement changes, update docs/spec.md and docs/plans/maf-demo-build-plan.md first, then code.
