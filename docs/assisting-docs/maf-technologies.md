# MAF (Microsoft Agent Framework) Technologies Used in Blueprints

This document lists all the Microsoft Agent Framework (MAF) related technologies wired into the
Blueprints backend, grouped by area. It is a reference for onboarding and architecture reviews.

## NuGet packages (the foundation)

| Package | Version | Purpose |
|---------|---------|---------|
| `Microsoft.Agents.AI` | 1.10.0 | Core MAF SDK — agents, sessions, context providers, compaction |
| `Microsoft.Agents.AI.OpenAI` | 1.10.0 | OpenAI / Azure OpenAI adapter for MAF |
| `Microsoft.Agents.AI.Foundry` | 1.5.0 | Azure AI Foundry integration |
| `Microsoft.Extensions.AI.OpenAI` | 10.6.0 | `IChatClient` abstraction + OpenAI binding |
| `Azure.AI.OpenAI` | 2.9.0-beta.1 | `AzureOpenAIClient`, Responses API client |

## Core agent abstractions

- **`AIAgent`** — the agent instance built per turn (`MAFAgentFactory`, `AgentCache`).
- **`ChatClientAgent`** / **`CreateAIAgent`** — building an agent from an `IChatClient`.
- **`AgentSession`** + **`StateBag`** — per-turn session with bound metadata (`AgentSessionExtensions`:
  sessionId, userId, blueprintId, assistantMessageId, clientRulesId, userMessage).
- **`ChatClientAgentRunOptions`** / **`AgentRunOptions`** — per-run option bag passed through to the
  history provider.
- **`AIAgent.CurrentRunContext`** — ambient access to the current run options.

## Chat client pipeline (builder middleware)

Built via `.AsBuilder()` on the chat client:

- **`UseFunctionInvocation`** — the tool-calling loop.
- **`UseOpenTelemetry`** / agent instrumentation — records `invoke_agent` spans
  (`AgentTelemetrySourceName = "aiplatform.agentframework"`).
- **`UseAIContextProviders`** — wires context providers onto the chat client.
- **`GetResponsesClient().AsIChatClientWithStoredOutputDisabled(...)`** — Responses API with
  server-side conversation state disabled (we use a custom history provider instead) and encrypted
  reasoning content preserved across tool rounds.

## Chat history persistence

- **`ChatHistoryProvider`** (base class) → **`CustomChatHistoryProvider`** — maps MAF `ChatMessage`
  ↔ Cosmos-backed `ChatsService`; `ProvideChatHistoryAsync` / `StoreChatHistoryAsync`, with
  `InvokingContext` / `InvokedContext`.

## Context providers (retrieval)

- **`AIContextProvider`** — base abstraction.
- **`TextSearchProvider`** — MAF's built-in RAG provider, used by `SearchContextProvider` for
  blueprint knowledge-base search and chat file search.

## Compaction

From `Microsoft.Agents.AI.Compaction` (preview surface, gated behind `MAAI001`). Assembled in
`CompactionPipelineFactory` as a **`PipelineCompactionStrategy`** wrapped in a
**`CompactionProvider`**:

- **`ToolResultCompactionStrategy`** — collapse old tool chatter (token-cheap).
- **`SummarizationCompactionStrategy`** — replace older spans with a brief from a cheaper summariser
  `IChatClient`.
- **`SlidingWindowCompactionStrategy`** — group-aware turn window.
- **`ContextWindowCompactionStrategy`** — model-aware hard backstop using context-window math.
- **`CompactionTriggers`** (`TokensExceed`, `TurnsExceed`) — thresholds.
- **`CompactionStrategy`** (base) + custom **`RecordingCompactionStrategy`** decorator — records
  before/after counts for the audit trail.

## Tools

- **`AITool`** / **`AIFunction`** — tool contract.
- **`AIFunctionFactory.Create`** — registering tools in `ToolRegistry`.

## Middleware & customization

- Agent middleware via `.Use(runFunc, runStreamingFunc)` — **`ContentSafetyMiddleware`**.
- Custom **`ReasoningInjectingChatClient`** (a `DelegatingChatClient`) — stamps the resolved per-turn
  reasoning effort; uses **`ReasoningOutput.Summary`**.
- **`UsageDetails`** — token accounting, including `OutputTokenDetails.ReasoningTokenCount`.

## Adapter / orchestration seams

- **`IAgentRuntimeAdapter`** → **`MAFAgentRuntimeAdapter`** — bridges the app's runtime-agnostic chat
  contract to MAF and streams `AgentStreamUpdate`.
- **`IAgentFactory`** → **`MAFAgentFactory`** — builds and caches configured agents.
- **`AgentCache`** — LRU cache of built `AIAgent` instances.
