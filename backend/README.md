# BC Eats Backend

BC Eats is a Node.js, Express and MongoDB backend for the BC Eats application.

The backend supports:

- Registered email/password authentication
- Microsoft student authentication
- Anonymous guest sessions
- Map/navigation features for both registered users and guests
- Food, category, order, review, cart, payment, drone and tracking features
- JWT-based stateless authentication
- MongoDB TTL cleanup for guest sessions

## 1. Guest authentication

Guests do not become records in the `User` collection.

When a user chooses **Login as Guest**, the frontend calls:

```text
POST /api/guests/session
```

No request body is required.

The backend creates a new document in the `Guest` collection:

```json
{}
```

MongoDB automatically generates the document `_id`.

That `_id` is the authoritative guest identifier. The backend does not create UUIDs, counters or other custom guest IDs.

Example response:

```json
{
  "success": true,
  "message": "Guest session created",
  "token": "JWT_TOKEN_HERE",
  "data": {
    "guestId": "68daef2c4d4fc7a14aa3b123"
  }
}
```

The JWT payload is equivalent to:

```json
{
  "guestId": "68daef2c4d4fc7a14aa3b123",
  "role": "guest"
}
```

The default guest JWT lifetime is 7 days.

## 2. Guest identity

A guest identity is always represented by the MongoDB-generated `_id`.

The application should send the returned JWT with protected requests:

```text
Authorization: Bearer JWT_TOKEN_HERE
```

The authentication middleware places the decoded token in:

```javascript
req.user
```

Registered users have:

```javascript
req.user.userId
```

Guests have:

```javascript
req.user.guestId
req.user.role === 'guest'
```

## 3. Stateless authentication

The backend does not maintain an in-memory guest session table.

The JWT contains the guest identifier and role, and the server verifies the signature and expiration on each protected request.

This allows many guests to authenticate concurrently without a custom guest-ID counter or locking mechanism.

MongoDB generates a unique `_id` for every inserted Guest document.

## 4. Guest cleanup

Guest documents contain a `createdAt` field with a MongoDB TTL index.

By default:

```text
GUEST_RETENTION_DAYS=7
```

MongoDB automatically removes expired guest documents after the TTL period. The application does not need a scheduled cleanup job.

The JWT also expires after 7 days by default:

```text
JWT_GUEST_EXPIRES_IN=7d
```

MongoDB's TTL monitor runs periodically, so deletion is automatic but is not guaranteed to happen at the exact second the retention period ends.

## 5. Guest map access

Guests are allowed to use the navigation/map API.

### Create a route preview

```text
POST /api/navigation/preview
```

The request must contain the guest JWT.

The created route stores:

```text
guestId = MongoDB Guest._id
```

Registered users instead store:

```text
userId = MongoDB User._id
```

This keeps guest data separate from registered-user data.

### Start a route

```text
PATCH /api/navigation/:id/start
```

The backend checks the route's `guestId` against the authenticated guest's `guestId`.

A guest therefore cannot use another guest's route ID with their own token.

### Get a route

```text
GET /api/navigation/:id
```

The same ownership check is applied.

## 6. Registered-user compatibility

Registered users continue to use the existing authentication flows:

```text
POST /api/users
POST /api/users/signin
POST /api/users/microsoft-login
```

Their JWT contains `userId` and their normal application role.

The shared authentication middleware accepts both token types.

Role-based admin/restaurant/drone permissions still require a registered-user `userId`, so a guest token cannot be used to access administrative endpoints.

## 7. Environment variables

```env
PORT=8000
MONGO_URI=mongodb://127.0.0.1:27017/bc_eats
TOKEN_SECRET=change_this_to_a_long_random_secret
JWT_EXPIRES_IN=8h
JWT_GUEST_EXPIRES_IN=7d
GUEST_RETENTION_DAYS=7
CLIENT_ORIGIN=http://localhost:3000

MICROSOFT_CLIENT_ID=your_microsoft_app_client_id
MICROSOFT_AUTHORITY=https://login.microsoftonline.com/common

STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=
STRIPE_CURRENCY=zar
DRONE_DELIVERY_FEE=0
```

## 8. Project structure for guest authentication

```text
bc_eats_work/
├── controllers/
│   ├── authController.js
│   └── guestController.js
├── middlewares/
│   ├── identification.js
│   └── mapAccess.js
├── models/
│   ├── guestModel.js
│   ├── usersModel.js
│   └── routeModel.js
├── routers/
│   ├── authRouter.js
│   ├── guestRouter.js
│   └── navigationRouter.js
└── utils/
    └── tokens.js
```

### How the files connect

```text
Flutter
   |
   | POST /api/guests/session
   v
routers/guestRouter.js
   |
   v
controllers/guestController.js
   |
   | creates document
   v
models/guestModel.js
   |
   | MongoDB generates _id
   v
Guest._id
   |
   | placed into JWT as guestId
   v
Flutter stores JWT
   |
   | Authorization: Bearer <JWT>
   v
middlewares/identification.js
   |
   | req.user.guestId
   v
navigationController.js
   |
   v
Route.guestId
```

## 9. Running the backend

Install dependencies:

```bash
npm install
```

Start MongoDB and then run:

```bash
npm run dev
```

The API runs on port `8000` by default.

## 10. Important security notes

Use a long random value for `TOKEN_SECRET` in production.

The guest JWT is intentionally stateless. If a guest loses their token, the backend cannot identify that browser as the same guest session unless the frontend still has the token.

Because guest records expire after the configured retention period, guest-related data should not be used as permanent account data.


## Recent integration hardening

- `POST /api/foods/upload-image` accepts a multipart `image` upload (JPEG/PNG/WebP/GIF, max 5 MB) for admin/restaurant roles and returns a public `imageUrl`. Food create/update accepts `imageUrl` and legacy `image` URL fields. Uploaded files are served from `/uploads/`; configure persistent storage or object storage before horizontal/ephemeral production deployment.
- CORS is restricted to the comma-separated `CLIENT_ORIGIN` allow-list. `TOKEN_SECRET` must be a unique random value of at least 32 characters. If Stripe is enabled, `STRIPE_WEBHOOK_SECRET` is required.
- Orders reject guest JWTs. Guests are for BC Ways navigation; BC Eats ordering requires a registered account.
- Payment records are unique per order and PaymentIntent creation uses a Stripe idempotency key. Client UI disables repeat submission while processing.
- Configure `SERVICE_FEE` and `DRONE_DELIVERY_FEE` in Rands; defaults are R5 and R15 respectively.

This repository has been statically patched but not run against a live MongoDB or Stripe account in this environment.
