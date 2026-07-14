# AGENTS

This repository is currently operated with the default coding agent.

## Purpose

This file defines collaboration workflow for humans and coding agents.
It is not an implementation spec.

## Source of Truth Order

Follow documents in this order when there is conflict:

1. `docs/spec.md` (product requirements)
2. `docs/plans/maf-demo-build-plan.md` (delivery order and verification)
3. `.github/copilot-instructions.md` (coding guardrails)
4. `AGENTS.md` (workflow and handoff)

## Working Rules

- Build and explain features in this order: spec -> plan -> implementation.
- Prefer minimal, validated changes over broad scaffolding.
- Keep explanations in simple English for a junior-but-capable developer audience.
- Avoid adding new behavior that is not justified by spec or plan.
- If requirements change, update spec and plan first, then implementation.
- Keep implementation constraints in one place: `.github/copilot-instructions.md`.

## MCP Tool Usage

Always use these MCP servers when relevant:

- `mcp_context7_query-docs` — fetch up-to-date library and framework documentation before writing or reviewing code that uses any external SDK, API, or framework.

Use these additional Azure MCP servers as needed:

- `mcp_azure_mcp_ser_cosmos` — query or manage Azure Cosmos DB resources.
- `mcp_azure_mcp_ser_monitor` — retrieve logs, metrics, and alerts from Azure Monitor.
- `mcp_azure_mcp_ser_deploy` — execute or inspect Azure deployments.
- `mcp_azure_mcp_ser_get_azure_bestpractices` — consult Azure best practices before generating Azure resource code or IaC.
- `mcp_azure_mcp_ser_cloudarchitect` — get architectural guidance for Azure solutions.

When in doubt about which Azure MCP to use, check the tool name prefix (`mcp_azure_mcp_ser_<service>`) that matches the Azure service being worked on.

## Chat Handoff

- When a user asks to "switch to a new chat" or says "handoff" or "handover", use `changing-context.txt`.
- Generate enough context in your chat window so the next chat session can continue without losing progress.