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

## Data and Search Rules
- Store chat sessions and messages in Cosmos DB.
- Index document chunks in Azure AI Search.
- Keep chunking simple and deterministic.
- Attach retrieval metadata to retrievalUsed events.

## Simplicity Rules
- Keep files small and focused.
- Use clear names that read well in demos.
- Add comments only when intent is not obvious.
- Avoid premature abstraction and unnecessary layers.

## Configuration Rules
Expect configuration for:
- OpenAI endpoint and key
- model deployment name (gpt-5.4)
- Cosmos DB settings
- Azure AI Search endpoint, key, and index name

Fail fast when required configuration is missing.

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
- Tool lifecycle event emission.
- Chat persistence and reload.
- Upload/index/retrieve flow for Azure AI Search RAG.

## Change Management
- Prefer minimal patches over broad rewrites.
- Keep plan, spec, and implementation aligned.
- If a requirement changes, update docs/spec.md and docs/plans/maf-demo-build-plan.md first, then code.
