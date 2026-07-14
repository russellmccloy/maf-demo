# Copilot Instructions

## Purpose
These instructions define coding guardrails for agents and contributors.
They do not replace product requirements or the implementation plan.

## Source of Truth

- Product requirements: `docs/spec.md`
- Delivery sequence and verification: `docs/plans/maf-demo-build-plan.md`
- Coding guardrails (this file): `.github/copilot-instructions.md`

If this file conflicts with spec or plan, follow spec and plan.

## Scope of This File

This file should only contain:

- coding style and quality expectations
- guardrails for safe implementation
- repo-level change management rules

This file should not contain detailed implementation design that belongs in spec or plan.

## Coding Principles

- Keep code minimal, readable, and demo-friendly.
- Prefer simple, explicit code over deep abstraction.
- Keep files focused and small where practical.
- Add comments only when intent is not obvious.
- Prefer minimal patches over broad rewrites.

## Implementation Guardrails

- Treat tool inputs as untrusted and validate them.
- Keep system-role instructions developer-controlled.
- Sanitize model/tool outputs before rendering or using in sensitive sinks.
- Keep public event names and API contracts stable once integrated.
- Fail fast when required configuration is missing and log what is missing.

## Change Management

- Build in order: spec -> plan -> implementation.
- If requirements change, update `docs/spec.md` and `docs/plans/maf-demo-build-plan.md` first, then code.
- Keep infra changes under `infra/` when infrastructure is affected.
- Validate behavior with tests or runtime checks relevant to the changed area.

## Notes

Detailed implementation rules (event payloads, data model conventions, runtime wiring, and infra specifics) belong in `docs/spec.md` and `docs/plans/maf-demo-build-plan.md`.
