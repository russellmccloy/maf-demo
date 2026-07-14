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

## Chat Handoff

- When a user asks to "switch to a new chat" or says "handoff" or "handover", use `changing-context.txt`.
- Generate enough context in your chat window so the next chat session can continue without losing progress.