
# API Specification Documentation

This directory contains API specifications for the BC Smart Lifestyle platform.

## Purpose

These documents define:

* Available API endpoints
* Request and response structures
* Authentication requirements
* Error handling
* Real-time communication contracts

The API layer follows a RESTful architecture for standard operations and WebSocket communication for real-time updates.

---

## API Modules

| API                | Purpose                                             |
| ------------------ | --------------------------------------------------- |
| Authentication API | Login, token handling, access control               |
| BC Ways API        | Navigation, map retrieval, shortest-path generation |
| BC Eats API        | Menu retrieval, ordering, delivery tracking         |
| Drone API          | Drone dispatch and telemetry                        |

---

## Standards

### Base URL

```txt id="1b1y94"
https://api.bcsmartlifestyle.com/api/v1
```

Development:

```txt id="lrb2zg"
http://localhost:5000/api/v1
```

### Response Format

Success:

```json id="1g5kkm"
{
  "success": true,
  "data": {},
  "message": "Operation successful"
}
```

Error:

```json id="uykq8h"
{
  "success": false,
  "error": "Invalid request"
}
```

### Authentication

Protected routes require JWT authentication.

Header format:

```http id="d9k6b7"
Authorization: Bearer <token>
```
