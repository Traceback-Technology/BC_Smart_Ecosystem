# Contributing to BC-SmartLifestyle

Thank you for contributing to BC-SmartLifestyle, a modular smart-campus platform spanning web software, backend services, security, analytics and robotics.

## 1. Engineering principles

- Keep module boundaries and responsibilities clear.
- Treat documentation and tests as part of the change.
- Use code review before integration.
- Prefer explicit API/event contracts over undocumented cross-module dependencies.
- Keep secrets out of source control.
- Test robotics behaviour in simulation before controlled hardware tests.

## 2. Where work belongs

- `platform/`: browser experiences and user-facing flows.
- `core/`: domain capabilities such as BC Ways and BC Eats.
- `backend/`: MVC-oriented API routes, controllers, services, models and middleware.
- `robotics/`: drone system and control API.
- `security/`: access control, QR authentication and monitoring.
- `analytics/`: order, navigation and operational insights.
- `shared/`: contracts, DTOs, constants and reusable utilities.
- `infrastructure/`: database and communication infrastructure.
- `docs/`: architecture, ADRs, API specifications, deployment and testing guidance.

Do not introduce new top-level modules or move major boundaries without discussing the architectural impact and recording significant decisions in an ADR.

## 3. Branching strategy

- `main`: stable/release branch.
- `configuration`: shared integration branch.
- `feature/<description>`: new functionality.
- `fix/<description>`: bug fixes.
- `docs/<description>`: documentation-only changes.
- `config/<description>`: configuration and tooling changes.

Create task branches from the latest `configuration`. Submit normal work into `configuration` via Pull Request. Promotion from `configuration` to `main` is a separate Pull Request after validation.

Never push directly to `main` or `configuration` unless project maintainers explicitly authorise an exceptional operation.

See [`Git_workflow.md`](Git_workflow.md) for commands and step-by-step guidance.

## 4. Pull Requests

Every Pull Request should:

- Reference a GitHub Issue where applicable.
- Explain the change and why it is needed.
- Identify affected modules and API/event contracts.
- Include tests run and any manual verification.
- Update documentation when behaviour, configuration or architecture changes.
- Pass the required CI checks.
- Avoid unrelated formatting or generated files.
- Never contain secrets, credentials or production data.

Complete `.github/pull_request_template.md`. Review requirements are governed by repository branch protection and CODEOWNERS settings.

## 5. Testing expectations

Run the relevant checks for the area changed. For the Flutter web client, run `flutter analyze`, `flutter test` and `flutter build web --release` from `platform/web-app/frontend/`. Backend commands become available when its runtime package is added. Robotics integrations should have simulator/stub tests for failure cases and must not issue live hardware commands from routine CI.

## 6. API and architecture changes

Update `docs/api-specifications/` and `shared/contracts/` when an interface changes. Create or update an ADR under `docs/adr/` for significant architecture choices. Changes to authentication, QR access, payments or robotics control require particular attention to authorisation, logging and failure behaviour.

## 7. Commit messages

Use concise, descriptive messages, for example:

- `feat: add navigation destination search`
- `fix: handle unavailable GPS permission`
- `docs: clarify Cloudflare deployment steps`
- `config: update frontend CI workflow`
- `test: cover order state transitions`

## 8. Security

Never commit `.env` files, credentials, API keys, signing keys, tokens or private keys. Use safe `.env.example` files and configure production secrets through the deployment environment or secret manager.
