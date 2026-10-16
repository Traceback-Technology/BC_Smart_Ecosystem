# Backend API

This directory contains the server-side API for BC-SmartLifestyle. The backend follows an **MVC-oriented structure**, with an additional service layer to keep business logic out of HTTP handlers.

## Responsibilities

- Expose versioned HTTP API endpoints to the web client and authorised integrations.
- Validate requests and apply authentication/authorisation middleware.
- Coordinate domain operations through controllers and services.
- Read/write persistent data through models or dedicated data-access modules.
- Publish real-time events where the relevant feature requires them.
- Provide structured logging, consistent errors and testable boundaries.

## MVC request flow

```text
HTTP request
   -> routes (URL + method mapping)
   -> middleware (validation, authentication, authorisation)
   -> controller (HTTP input/output coordination)
   -> service (business rules / use case)
   -> model / repository (persistence)
   -> controller response (JSON + HTTP status)
```

For a JSON API, MVC does not require server-rendered HTML views. The response representation is the API's view/output boundary. Keep controllers thin; business rules belong in services, and persistence details belong in models/repositories.

## Directory guide

| Directory | Responsibility |
|---|---|
| `routes/` | Route definitions and controller mapping |
| `controllers/` | HTTP request/response handling; no complex business rules |
| `services/` | Use cases, domain orchestration and business rules |
| `models/` | Persistence models/schemas and data-access logic |
| `middleware/` | Authentication, authorisation, validation, rate limiting and error handling |
| `config/` | Environment-driven application configuration |
| `sockets/` | WebSocket event handlers and real-time integration |
| `tests/` | Unit, integration and API tests |

## Implementation conventions

- Keep secrets in environment variables; commit only safe `.env.example` files.
- Validate and normalise all external input.
- Return consistent JSON error shapes without exposing stack traces in production.
- Enforce authorisation on the server, not only in the UI.
- Use explicit API contracts documented under `docs/api-specifications/` and `shared/contracts/`.
- Keep controllers thin and avoid database queries directly in route files.
- Add tests for access-control rules and failure paths as well as successful requests.

The backend folder is currently a structural boundary. Add package manifests, runtime code and exact start/test commands when the backend runtime and implementation are present; do not treat this README as evidence that endpoints already exist.
