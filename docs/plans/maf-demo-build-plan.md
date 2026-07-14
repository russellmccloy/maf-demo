# 🗺️ Plan: Standalone MAF Demo Chat App

Build a minimal, demo-friendly standalone ASP.NET Core app that mirrors the core BuildAgentCore pipeline from Blueprints, uses Azure OpenAI Responses API with gpt-5.4, persists chat data in Cosmos DB, and provides RAG via Azure AI Search. Runtime code uses direct Azure OpenAI endpoint integration (no Foundry runtime dependency), even if the endpoint is provisioned via Foundry.

---

## ✅ Implementation Phases

### Phase 1 - Product and Repo Contract *(blocks all later phases)*

Product and repo-level documentation to establish contract and constraints.

1.1. **Update `docs/spec.md`** with the product spec and non-negotiable requirements:

- Responses API only based on these Microsoft Docs: <https://learn.microsoft.com/azure/foundry/openai/how-to/responses>
- Do not use Foundry hosted agent runtime APIs in this app. If endpoint details come from Foundry provisioning, still use standard Azure OpenAI endpoint integration in app code.
- Build up the agent declaratively using the builder pattern, also do this for the middleware, context providers, tools, reasoning (if we explicitly set it up, chatHistoryProvider, contextProviders, telemetry etc). Use this to see what I mean: <C:\Users\RussellMcCloy\code\Blueprints\backend\Runtime\MAFAgentFactory.cs>. Also I have put a code snipppet below to guide you:

    ```c#
            var agent = new LoggingAgent(
                reasoningAwareChatClient
                    .AsAIAgent(
                        new ChatClientAgentOptions
                        {
                            Name = definition.Name,
                            ChatOptions = new()
                            {
                                Instructions = definition.Instructions,
                                Tools = [.. tools],
                                // Reasoning models do not support Temperature; suppress it when reasoning effort is configured.
                                Temperature = reasoningEffort.HasValue ? null : 0.2f,
                                // Cap the visible output so reasoning tokens cannot starve the answer.
                                MaxOutputTokens = maxOutputTokens,
                                Reasoning = reasoningEffort.HasValue
                                    ? new ReasoningOptions
                                    {
                                        Effort = reasoningEffort,
                                        // Output = Summary asks the MAF→OpenAI bridge to request the
                                        // Azure "reasoning.summary", which the model returns as separate
                                        // streaming frames (mapped to reasoningSummary SSE events). Only
                                        // request it when explicitly enabled; otherwise leave it unset so
                                        // the provider default applies (no summary).
                                        Output = _options.EmitReasoningSummary
                                            ? ReasoningOutput.Summary
                                            : null,
                                    }
                                    : null,
                            },
                            ChatHistoryProvider = definition.PersistHistory
                                ? _historyProvider
                                : null,
                            AIContextProviders = [.. contextProviders],
                        }
                    )
                    .AsBuilder()
                    .Use(
                        runFunc: _contentSafetyMiddleware.RunMiddleware,
                        runStreamingFunc: _contentSafetyMiddleware.RunStreamingMiddleware
                    )
                    // Instrumenting the agent ensures an invoke_agent span is recorded, integrating
                    // agent telemetry with Grafana better. Sensitive payload capture is controlled via
                    // MAFRuntime:Telemetry:EnableSensitiveDataLogging.
                    .UseOpenTelemetry(
                        sourceName: AgentTelemetrySourceName,
                        configure: cfg =>
                            cfg.EnableSensitiveData = _options.Telemetry.EnableSensitiveDataLogging
                    )
                    .Build(),
                _logger
            );
    ```

- Azure AI Search-backed RAG
- SSE streaming architecture
- Cosmos persistence for chats using the chatHistoryProvider implementation as per here: <https://learn.microsoft.com/en-us/dotnet/api/microsoft.agents.ai.chathistoryprovider?view=agent-framework-dotnet-latest>. You can also look <C:\Users\RussellMcCloy\code\Blueprints\backend\Orchestration\CustomChatHistoryProvider.cs> for reference but use the Microsoft docs for the main guidance. Keep the provider instance stateless and place session-specific values in AgentSession state.
- Compaction as per the docs here: <https://learn.microsoft.com/en-us/agent-framework/agents/conversations/compaction?pivots=programming-language-csharp> and you can look at the existing code here for guidance: <C:\Users\RussellMcCloy\code\Blueprints\backend\Runtime\MAFAgentFactory.cs> and in particular this section of the code:

```c#
            if (_compactionOptions.Enabled)
            {
                var summariserModel = string.IsNullOrWhiteSpace(_options.SummariserModel)
                    ? _options.Model
                    : _options.SummariserModel;
                var summariserModelSource = string.IsNullOrWhiteSpace(_options.SummariserModel)
                    ? "MAFRuntime:Model"
                    : "MAFRuntime:SummariserModel";

                // Resolve the summariser here (not in the constructor) so its factory — which
                // requires a configured model — only runs when compaction is switched on.
                var summariserChatClient = _serviceProvider.GetRequiredKeyedService<IChatClient>(
                    "summariser"
                );
#pragma warning disable MEAI001
                var compactionProvider = CompactionPipelineFactory.Build(
                    _compactionOptions,
                    summariserChatClient,
                    _loggerFactory
                );
                instrumentedChatClient = instrumentedChatClient.UseAIContextProviders(
                    compactionProvider
```

- Content safety as per this Microsoft Doco: <https://learn.microsoft.com/en-us/agent-framework/agents/safety> and related links from that page. Treat this as mandatory baseline behavior (tool input validation, trust-boundary controls, system-role isolation, and output sanitization), with middleware used as one implementation mechanism where appropriate. You can also look here for guidance: <C:\Users\RussellMcCloy\code\Blueprints\backend\Middleware\ContentSafety.cs>

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
- App feature toggles. These might, for example, turn features on and off like caching or optional enhancements. Compaction is mandatory and should not be optional.

---

### Phase 3 - MAF Agent Pipeline *(depends on Phase 2)*

Core agent orchestration, BuildAgentCore-inspired.

3.1. **Implement MAFAgentFactory equivalent** demonstrating the BuildAgentCore flow:

- Azure Responses client creation (stored output disabled pattern)
- chatHistoryProvider implementation
- ChatHistoryProvider session-state semantics (provider instance is stateless; session-specific values live in AgentSession)
- Chat client builder pipeline
- Function invocation middleware wiring
- AIAgent construction with ChatClientAgentOptions and tools
- Mandatory compaction wired in the runtime pipeline with explicit trigger strategy and summarizer configuration
- Mandatory content safety controls aligned to Agent Framework safety guidance (input validation, approval/guardrails for high-risk tools, role isolation, output sanitization)
- Agent caching strategy for build reuse and telemetry. You can look here for guidance on this: <C:\Users\RussellMcCloy\code\Blueprints\backend\Runtime\MAFAgentFactory.cs> and in particular this code:

```c#
public AIAgent CreateAgent(AgentDefinition definition, IReadOnlyList<AITool> tools)
        {
            // Reuse the built agent when the cache key matches. The stopwatch measures the cache
            // lookup on a hit and the full build on a miss.
            var cacheKey = AgentCacheKey.Build(definition);
            var buildStopwatch = Stopwatch.StartNew();
            var (agent, cacheHit, builtAt) = _agentCache.GetOrBuild(
                cacheKey,
                () => BuildAgentCore(definition, tools)
            );
            buildStopwatch.Stop();

            var buildDurationMs = buildStopwatch.Elapsed.TotalMilliseconds;
            var cacheHitTag = new KeyValuePair<string, object?>("cacheHit", cacheHit);
            BackendTelemetry.AgentBuildDurationMs.Record(buildDurationMs, cacheHitTag);
            BackendTelemetry.AgentBuildCount.Add(1, cacheHitTag);

            _logger.LogInformation(
                "MAF agent acquisition complete. AgentName={AgentName} Model={Model} ToolCount={ToolCount} "
                    + "CacheHit={CacheHit} AgentBuildDurationMs={AgentBuildDurationMs} BuiltAt={BuiltAt} "
                    + "BlueprintId={BlueprintId} BlueprintUpdatedAtTicks={BlueprintUpdatedAtTicks} ReasoningEffort={ReasoningEffort} PersistHistory={PersistHistory}",
                definition.Name,
                definition.Model,
                tools.Count,
                cacheHit,
                buildDurationMs,
                builtAt,
                definition.BlueprintId,
                definition.BlueprintUpdatedAtTicks,
                definition.ReasoningEffort,
                definition.PersistHistory
            );

            return agent;
        }
```

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
- Azure OpenAI resource + gpt-5.4 GlobalStandard deployment
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
| Excluded from v1 | Complex or experimental safety frameworks beyond baseline controls, multi-index search |

---

## 💡 Further Considerations

- **gpt-5.4 deployment policy**: Strict mode — fail deployment if gpt-5.4 GlobalStandard cannot be provisioned (no fallback model for v1)
- **SSE contract stability**: Lock event names in spec before coding; keep envelope shape aligned with Blueprints chat stream pattern to avoid frontend/backend drift
