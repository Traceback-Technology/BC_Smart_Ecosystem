# BC Eats Postman Guide

## Base URL

```text
http://localhost:8000
```

## Guest session

Create a new anonymous guest session:

```text
POST /api/guests/session
```

No request body is required.

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

Copy the returned token and use it as a Bearer token for navigation requests.

## Guest session identity

```text
GET /api/guests/session
```

Header:

```text
Authorization: Bearer JWT_TOKEN_HERE
```

Example response:

```json
{
  "success": true,
  "data": {
    "guestId": "68daef2c4d4fc7a14aa3b123",
    "role": "guest"
  }
}
```

## Guest map/navigation

All of the following accept both registered-user JWTs and guest JWTs:

```text
POST /api/navigation/preview
PATCH /api/navigation/:id/start
GET /api/navigation/:id
```

For a guest, the backend stores the MongoDB Guest `_id` in `Route.guestId`.

For a registered user, the backend stores the User `_id` in `Route.userId`.

## Guest token payload

The guest JWT contains:

```json
{
  "guestId": "68daef2c4d4fc7a14aa3b123",
  "role": "guest"
}
```

The default expiration is 7 days.

## Registered authentication

Existing registered-user endpoints remain available:

```text
POST /api/users
POST /api/users/signin
POST /api/users/microsoft-login
GET /api/users/me
PUT /api/users/me
POST /api/users/signout
```

Guest sessions are intentionally separated into `/api/guests`.
