# Repository Structure

## Overview

BC Smart Lifestyle follows a monorepo structure.

The repository is organised by domain responsibilities.

---

## Folder Structure

```txt id="ax4yqn"
platform/         → Flutter mobile and web applications
backend/          → Express.js backend services
core/             → Business logic modules
robotics/         → Drone systems
analytics/        → Monitoring and reports
security/         → Access control and QR authentication
shared/           → Shared contracts and utilities
infrastructure/   → Database and deployment configs
docs/             → Technical documentation
```

---

## Development Principles

### Domain Separation

Each feature exists within a dedicated domain.

### Shared Reusability

Common logic belongs inside `/shared`.

### Loose Coupling

Modules communicate via APIs.

### Documentation First

All architectural changes require ADR updates.

---

## Contribution Guidelines

Developers should:

1. Work inside their assigned domain.
2. Open pull requests to `develop`.
3. Include tests.
4. Update documentation when architecture changes.
