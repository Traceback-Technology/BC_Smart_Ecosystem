# BC Smart Ecosystem (BC-SmartLifestyle)

**Campus navigation and tuck-shop ordering for Belgium Campus, delivered as a Flutter web app / PWA with a Node.js API.**

BC Smart Ecosystem brings two student-facing products together in one app:

- **BC Ways** – campus navigation: shortest-route pathfinding over a campus graph, destination search and GPS-aware guidance.
- **BC Eats** – tuck-shop ordering: menu, cart, checkout (cash or card), order tracking, plus staff tools (live order queue, inventory, sales dashboard).

The repository is a monorepo containing the Flutter client, the Express/MongoDB backend, and the project documentation.

## Project status

| Area | Status |
|---|---|
| Student sign-in, menu, cart, checkout (cash pickup and placeholder payment), tracking, order history | Working |
| Staff live-orders queue, inventory with image upload, admin analytics | Working |
| BC Ways routing (Dijkstra), destination search, GPS calibration, blocked-path rerouting | Working |
| Stripe card payments | Implemented; needs live/test-mode keys and verification |
| Order tracking updates | Working via polling (student ~8 s, staff ~10 s); not push-based |
| Drone delivery | Backend assignment logic only; no hardware integration (see ADR 0004, status *Proposed*) |
| WebSockets / MQTT | Planned (see ADR 0005); not implemented |

Treat anything not in the "Working" rows as in progress until verified by tests and deployment.

## Architecture

```text
Browser / installable PWA  (Flutter web)
          |
          v
Cloudflare (static web assets, SPA routing)
          |  HTTPS / JSON
          v
Express API  (routes -> controllers -> services / models)
          |
          +--> MongoDB
          +--> Stripe (card payments, webhook)
          +--> Microsoft Entra ID (token verification)
```

The backend follows an MVC-style layout with a small service layer (`services/paymentService.js` is the single place that decides whether an order counts as paid). Authentication uses stateless JWTs for registered users and guests; role checks for staff actions re-read the user's role from the database.

## Repository map

```text
backend/                 Express API (routers, controllers, models, middlewares, services, seed script, tests, Postman collection)
platform/
  mobile-interface/
    Frontend/            Flutter app (BC Ways + BC Eats), web PWA assets, Android/iOS projects
  web-platform/          Placeholder for a future dedicated web platform
shared/                  API / WebSocket / MQTT contract documents, constants and utility notes
docs/                    Architecture notes, ADRs, API specification docs
diagrams/                Architecture, flowchart and ERD placeholders
routers/                 Stray file (orderRoutes.js) - not used by the backend; safe to remove
.github/                 Issue/PR templates, CODEOWNERS, CI workflows
wrangler.toml            Cloudflare deployment config (serves the Flutter web build)
```

Inside `platform/mobile-interface/Frontend/lib/`:

```text
core/                    API client (base URL set at build time)
features/auth/           Welcome and student sign-in, session model
features/home/           Home screen
features/bc_ways/        Graph, Dijkstra, GPS, navigation and map screens
features/bc_eats/        Menu, cart, checkout, tracking, staff screens, repositories (API + mock)
features/profile/        Profile screen and local store
shared/widgets/          Reusable widgets
```

Backend route groups live under `backend/routers/` and are mounted in `backend/index.js` (users, foods, categories, orders, payments, drones, tracking, notifications, analytics, coupons and more). See `docs/API-specification-docs/` and `backend/POSTMAN_GUIDE.md`.

## Getting started

### Prerequisites

- Node.js 20.6 or newer (the dev script uses `node --env-file`)
- A MongoDB database (local or Atlas)
- Flutter SDK (Dart ^3.8.1) for the client
- Git

### Run the backend

```bash
cd backend
npm install
cp .env.example .env      # then fill in the values (see below)
node seed.js              # optional: loads demo categories, foods, coupons and test accounts
npm run dev               # API on http://localhost:8000 (or the PORT you set)
```

Check it is running: `GET http://localhost:8000/api/health` should report `database: connected`.

The `seed.js` script prints the development test accounts (student, restaurant, admin, drone operator) when it finishes. They are for local testing only.

### Run the Flutter client

```bash
cd platform/mobile-interface/Frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

Other targets: Android emulator uses `API_BASE_URL=http://10.0.2.2:8000`; a physical device needs your computer's LAN address or the deployed HTTPS URL. To enable card checkout, also pass `--dart-define=STRIPE_PUBLISHABLE_KEY=...`. See `platform/mobile-interface/Frontend/BACKEND_INTEGRATION.md` for behaviour when the API is offline or the user is not signed in.

### Run the tests

```bash
cd backend
node --test test/
```

The backend tests stub the database, so no MongoDB is needed. Flutter tests: `flutter test` from the Frontend folder.

## Configuration

Set these in `backend/.env` (never commit this file; `.env.example` lists the keys):

| Variable | Purpose |
|---|---|
| `MONGO_URI` | MongoDB connection string (required) |
| `TOKEN_SECRET` | JWT signing secret, at least 32 random characters (required). Generate with `node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"` |
| `JWT_EXPIRES_IN`, `JWT_GUEST_EXPIRES_IN` | Token lifetimes (defaults 8h and 7d) |
| `CLIENT_ORIGIN` | Comma-separated allowed browser origins for CORS |
| `PUBLIC_API_URL` | Public base URL of the API (used for uploaded image URLs) |
| `MICROSOFT_CLIENT_ID`, `MICROSOFT_AUTHORITY` | Microsoft Entra ID sign-in verification |
| `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `STRIPE_CURRENCY` | Card payments; the webhook secret is required whenever a Stripe key is set |
| `PAYMENT_MODE` | `stripe` (default), `placeholder` (auto-paid, **demo only**) or `sandbox` (reserved, behaves like `stripe`). Not listed in `.env.example`; add it if you need demo mode |
| `SERVICE_FEE`, `DRONE_DELIVERY_FEE` | Per-order fees (code defaults 5 and 15) |

Uploaded food images are stored on local disk under `backend/uploads/`. On hosts with ephemeral storage they are lost on redeploy; use object storage or image URLs in production.

## Deployment

- **Client:** build the Flutter web bundle, then deploy from the repository root with Wrangler (serves `platform/mobile-interface/Frontend/build/web` as a single-page app):

  ```bash
  cd platform/mobile-interface/Frontend
  flutter build web --release
  cd ../../..
  npx wrangler deploy
  ```

- **PWA install pop-up:** HTTPS is required. Android/desktop Chrome and Edge show the native install dialog; iPhone Safari users add the app via Share > Add to Home Screen. Details are in `platform/mobile-interface/Frontend/README.md`.
- **API:** deploy `backend/` to any Node host (the project has used Render's free tier, which sleeps when idle). Set all environment variables, and add the deployed client origin to `CLIENT_ORIGIN`.

## Engineering standards

- Work on short-lived branches created from `configuration`; open feature/fix/docs Pull Requests into `configuration`, and promote reviewed, tested changes to `main` through a separate Pull Request.
- Never commit secrets, `.env` files, build output or dependencies. Do not zip or share a project folder that contains a populated `.env`.
- Add tests for new behaviour and update documentation when interfaces or architecture change.
- Record significant architectural decisions as ADRs in `docs/adr/`.

See [`CONTRIBUTING.md`](CONTRIBUTING.md) and the templates under `.github/`.

## Documentation

- Architecture notes: `docs/architecture/`
- Architecture decisions: `docs/adr/`
- API specifications: `docs/API-specification-docs/`
- Ordering MVP notes and payment modes: `STEP1_ORDERING_NOTES.md`
- Backend change log: `backend/FIXES_APPLIED.md`; frontend change log: `platform/mobile-interface/Frontend/FIXES_APPLIED.md`

## License

See [`LICENSE`](LICENSE).