# BC-SmartLifestyle

**Smart-campus software platform | Web applications | Robotics | Connected services**

BC-SmartLifestyle is a modular smart-campus platform designed to bring campus navigation, food ordering, visitor access, notifications, operational analytics and robotics-enabled delivery into one coherent ecosystem. The project is maintained as a monorepo so that application, backend, domain, security, infrastructure and robotics work can evolve together while keeping clear boundaries.

> **Current delivery direction:** the primary user experience is a web application hosted on Cloudflare. The existing Flutter application is being prepared for web delivery; its Android/iOS project files are retained as a possible future distribution path, not as a commitment to app-store release.

## Product areas

| Area | Purpose | Main location |
|---|---|---|
| BC Ways | Campus navigation, pathfinding and GPS-aware route guidance | `core/bc-ways/` |
| BC Eats | Menus, orders, payment integration and delivery management | `core/bc-eats/` |
| Authentication | User identity and access decisions | `core/authentication/`, `security/` |
| Notifications | User-facing and operational event notifications | `core/notifications/` |
| Robotics | Drone control, telemetry, navigation and simulation | `robotics/` |


## Architecture at a glance

```text
Browser / Installable PWA
          |
          v
Cloudflare Pages (web delivery)
          |
          v
Backend API (MVC: routes -> controllers -> services/models)
          |
   +------+------+----------------+
   |             |                |
Domain core   Database       Real-time / MQTT
   |                              |
   +----------- Robotics ----------+
          |
     Telemetry / control
```

The diagram is a conceptual boundary map, not a claim that every integration is already implemented. The backend is organised around **Model–View–Controller (MVC)** responsibilities. For an API backend, the “View” is generally the HTTP/JSON response layer rather than server-rendered pages; controllers coordinate requests, services contain business use cases, and models/data-access modules handle persistence.

## Technology direction

- **Web client:** Flutter with Flutter Web support; assess browser compatibility for plugins and device APIs.
- **Web hosting:** Cloudflare Pages for static web assets and SPA routing.
- **Backend:** Node.js/Express-style API using MVC separation, subject to the actual backend package and runtime configuration.
- **Data:** MongoDB documentation and infrastructure are present in this repository; confirm the deployed database and connection strategy in environment-specific configuration before release.
- **Real-time / robotics messaging:** WebSockets and MQTT, where required by the implemented feature.
- **Robotics:** drone firmware, navigation, telemetry, control API and simulation remain first-class project areas.
- **Quality and collaboration:** GitHub Issues, Pull Requests, code review, automated checks and documented architecture decisions.

Do not assume a technology is production-ready solely because a directory or workflow exists. The module README and deployment configuration should describe the implemented state and known gaps.

## Repository map

```text
.github/                  Issue templates, PR template, ownership and CI workflows
docs/                     Architecture, ADRs, API specifications, testing and deployment docs
platform/                 User-facing web experiences and visitor-access entry points
backend/                  API implementation using MVC boundaries
diagrams/                 Architecture, flowcharts and ERDs
```

See [`docs/architecture/repo-structure.md`](docs/architecture/repo-structure.md) for the detailed map.

## Getting started

### Prerequisites

Install the tools required for the module you are working on. The web client currently uses Flutter/Dart. Backend and robotics prerequisites should be taken from their module READMEs and package manifests. You will also need Git and access to the project repository.

### Clone for the first time

```bash
git clone <REPOSITORY-URL>
cd BC-SmartLifestyle
git switch configuration
git pull origin configuration
```

### Update an existing checkout

```bash
cd BC-SmartLifestyle
git status
git switch configuration
git pull origin configuration
```

If `git status` reports uncommitted work, commit or stash it before switching branches or pulling. Never discard work just to update the branch.

### Run the Flutter web client

From the current client directory:

```bash
cd platform/web-app/frontend
flutter pub get
flutter run -d chrome
```

To build the static web bundle for deployment:

```bash
flutter build web --release
```

The default Flutter output is `build/web`. Verify that all plugins used by the application support web before treating the build as release-ready. Backend and robotics setup steps are documented in their respective READMEs.

## Deployment and app-like installation

The intended first release is a responsive web app on Cloudflare Pages. A Progressive Web App (PWA) can add an install/home-screen experience where supported by the browser and operating system. PWA capability must be configured and tested; it is not guaranteed merely by deploying a website.

A separately downloadable Android APK is a different deliverable: it must be built, signed, versioned, security-reviewed and distributed from a trusted download page. Direct website installation is not generally equivalent to installing an arbitrary iOS app; iOS distribution is subject to Apple's supported distribution routes and eligibility rules.

See [`docs/deployment/cloudflare-pages.md`](docs/deployment/cloudflare-pages.md) and [`docs/deployment/application-distribution.md`](docs/deployment/application-distribution.md).

## Engineering standards

- Work from short-lived branches created from `configuration`.
- Submit normal feature/fix/documentation Pull Requests into `configuration`; promote reviewed, tested changes from `configuration` to `main` through a separate Pull Request.
- Do not commit secrets, credentials, local `.env` files, generated build output or dependencies.
- Add tests for new behaviour and update documentation when interfaces or architecture change.
- Use an ADR for significant architectural choices.
- Keep robotics control and telemetry interfaces explicit, authenticated where appropriate, and observable.

See [`Git_workflow.md`](Git_workflow.md), [`CONTRIBUTING.md`](CONTRIBUTING.md), and the templates under `.github/`.

## Project status

This repository contains working application assets and documentation alongside planned module boundaries. Treat individual feature status as **in progress until verified** by implementation, tests and deployment. Do not store production credentials in the repository.

## License

See [`LICENSE`](LICENSE) for the terms that apply to this repository.
