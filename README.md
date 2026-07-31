# BC Eats Backend

Express + MongoDB backend created from the structure/style of the supplied BOOKVERSE API and mapped to the supplied BC Eats UI.

## UI-to-API mapping
- Home/profile header: `GET /api/users/me`
- Recent activity: `GET /api/activities?limit=5`
- BC Eats catalogue/categories/search: `GET /api/foods`
- Create order: `POST /api/orders`
- Orders tab: `GET /api/orders`
- Preparing/ready/live tracking screen: `GET /api/orders/:id`
- Edit delivery notes: `PATCH /api/orders/:id/notes`
- Cancel order: `PATCH /api/orders/:id/cancel`
- BC Ways route estimate: `POST /api/navigation/preview`
- Start navigation: `PATCH /api/navigation/:id/start`

## Setup
1. Copy `.env.example` to `.env` and set `MONGO_URI` and `TOKEN_SECRET`.
2. Run `npm install`.
3. Run `npm run dev`.

Authenticated requests accept `Authorization: Bearer <token>` or the auth cookie created by sign-in.

## Main request examples

Signup: `POST /api/users` with `{ "name":"Arnold", "email":"arnold@example.com", "password":"Password1" }`.

Create an order: `POST /api/orders` with `{ "items":[{"foodId":"...","quantity":1,"notes":"Extra cheese, no onions"}], "deliveryAddress":"221B Baker Street, London NW1 6XE, UK" }`.

Preview navigation: `POST /api/navigation/preview` with `{ "origin":"Current Location", "destination":"Central Station" }`.

Note: route estimates are placeholder backend logic. Connect Google Maps, Mapbox, or another routing provider for real distance, ETA, and live map coordinates.




##jUST A SIMPLE TEXT