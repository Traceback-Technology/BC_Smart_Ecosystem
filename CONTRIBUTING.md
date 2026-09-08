# Contributing to Belgium ITVersity - Smart Campus Ecosystem

Welcome to the Smart Campus Ecosystem project.

This repository represents a multi-domain, enterprise-style smart campus platform integrating web applications, robotics systems, security modules, simulation engines, and analytics services.

To maintain architectural clarity, system stability, and team efficiency, all contributors must follow the guidelines outlined below.

---

## 1. Engineering Principles

We operate under the following principles:

- Modular architecture
- Clear subsystem boundaries
- No direct cross-domain coupling
- Code must be reviewed before merging
- Integration stability is prioritized over feature quantity
- Documentation is part of development

---

## 2. Repository Structure Rules

Each subsystem lives within its designated domain folder:

- platform/
- core/
- robotics/
- security/
- simulation/
- analytics/
- shared/
- infrastructure/

Contributors must not:

- Create new top-level folders without architectural review
- Move or rename domain folders without approval
- Introduce cross-domain imports without discussion

Shared data contracts must live in: 
- **shared/contracts/**

---

## 3. Branching Strategy

We use the following branch model:

- main → Stable release branch
- develop → Integration branch
- feature/* → Feature development
- fix/* → Bug fixes
- refactor/* → Refactoring work
- research/* → Experimental work (non-production)

### Example branch names:
`feature/robotics/drone-delivery-routing ` </br>
`feature/security/qr-authentication`  </br>
`fix/platform/login-validation` </br>
`refactor/analytics/data-pipeline` </br>

---
**Rules:**

- Never commit directly to `main`
- Never commit directly to `develop`
- All changes must go through Pull Requests

---

## 4. Pull Request Process

Every Pull Request must:

- Reference an Issue
- Specify subsystem affected
- Describe architectural impact
- Include testing notes
- Pass CI checks

PRs require:

- Minimum 2 approvals
- Approval from subsystem owner (via CODEOWNERS)
- Successful CI pipeline

PRs may be rejected if they:

- Break subsystem boundaries
- Introduce undocumented APIs
- Lack tests
- Reduce system clarity

---

## 5. Issue Workflow

All work must begin with an Issue.

Each Issue must include:

- Clear description
- Acceptance criteria
- Assigned subsystem
- Priority label
- Milestone assignment

No development work should begin without an Issue.

---

## 6. Subsystem Ownership

Each major domain has assigned leads.

Subsystem leads are responsible for:

- Reviewing domain-specific PRs
- Protecting architectural integrity
- Coordinating domain contributors
- Ensuring documentation is updated

Cross-domain changes require discussion with the System Architect [Architect name].

---

## 7. Code Standards

- Follow consistent naming conventions
- Write modular and testable code
- Avoid hard-coded secrets
- Avoid direct hardware calls from core modules
- Use shared contracts for integration

All secrets must use environment variables.
Never commit API keys, credentials, or private tokens.

---

## 8. Testing Requirements

Every subsystem must include:

- Unit tests
- Integration tests where applicable

New features must include relevant tests.

CI must pass before merging.

---

## 9. Architectural Changes

Any major architectural modification requires:

- An Architectural Decision Record (ADR)
- Documentation inside docs/adr/
- Review by System Architect

---

## 10. Large Assets Policy

Do NOT commit:

- Drone SDK binaries
- Large datasets
- AI model checkpoints
- Database files
- Logs
- Local environment folders

If large assets are required, discuss storage strategy first.

---

## 11. Communication

All technical discussions should occur through:

- GitHub Issues
- Pull Request discussions
- Documented ADRs

Avoid undocumented architecture decisions.

---

## 12. Licensing Agreement

By submitting a contribution to this repository, you agree that your contribution will be licensed under the MIT License of this project.

---

## 13. Professional Conduct

This is an enterprise-style academic project.

Contributors are expected to:

- Communicate clearly
- Respect subsystem boundaries
- Follow review processes
- Maintain professional engineering discipline
- Prioritize system stability

---

Thank you for contributing to the Belgium ITVersity - Smart Campus Ecosystem.

