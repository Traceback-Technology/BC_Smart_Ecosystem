# API Contracts

## Standard Success Response

```json id="x5p2ms"
{
  "success": true,
  "data": {},
  "message": "Operation successful"
}
```

---

## Standard Error Response

```json id="0xjmnf"
{
  "success": false,
  "error": "Validation failed"
}
```

---

## Authentication Contract

Request:

```json id="w8w5bo"
{
  "studentNumber": "577168",
  "password": "password"
}
```

Response:

```json id="0f0fcb"
{
  "token": "jwt_token",
  "user": {
    "id": "123",
    "role": "student"
  }
}
```

---

## Order Contract

Request:

```json id="mx6p3r"
{
  "items": [
    {
      "menuItemId": "1",
      "quantity": 2
    }
  ]
}
```

Response:

```json id="n8k8d9"
{
  "orderId": "ORD-001",
  "status": "Received"
}
```
