# AGENTS

This repository is currently operated with the default coding agent.

## Working Rules

- Follow `docs/spec.md` as the product source of truth.
- Follow `.github/copilot-instructions.md` for implementation and structure.
- Prefer minimal, validated changes over broad scaffolding.
- Treat your audience, including me, as a junior developer who is quite smart and has been out of university for 2 years and has been working in the industry. They like simple English.

## Project Workflow

- Build and explain features in this order: spec -> plan -> implementation.
- Keep the app as a single ASP.NET Core deployable unit (API + static UI).
- Use Azure OpenAI Responses API with `gpt-5.4` as the required model deployment.
- Persist chat sessions/messages in Cosmos DB.
- Use Azure AI Search for document indexing and retrieval (RAG).
- Treat SSE event names as a stable contract between backend and UI.
- Keep code simple and spacious for demo purposes; avoid advanced abstractions unless requested.
- Keep `docs/spec.md`, `docs/plans/maf-demo-build-plan.md`, and `.github/copilot-instructions.md` in sync when requirements change.
- Infra changes must include Bicep updates under `infra/`.

## Chat Handoff

- When a user asks to "switch to a new chat" or says "handoff" or "handover", use `changing-context.txt`.
- Generate enough context in your chat window so the next chat session can continue without losing progress.