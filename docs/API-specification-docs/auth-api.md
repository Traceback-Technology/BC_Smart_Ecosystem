# Authentication API

## Base Route

```txt id="xj2vgt"
/api/v1/auth
```

---

## Login User

### Endpoint

```http id="kx3t3r"
POST /api/v1/auth/login
```

### Request Body

```json id="grn6oe"
{
  "studentNumber": "577168",
  "password": "********"
}
```

### Success Response

```json id="6q1o3k"
{
  "success": true,
  "token": "jwt_token_here",
  "user": {
    "id": "123",
    "name": "Ryan",
    "role": "student"
  }
}
```

### Error Response

```json id="n1rn7x"
{
  "success": false,
  "message": "Invalid credentials"
}
```

---

## Register User

### Endpoint

```http id="e3t99h"
POST /api/v1/auth/register
```

### Request Body

```json id="u6qj9n"
{
  "name": "John Doe",
  "studentNumber": "602679",
  "email": "john@bcstudent.be",
  "password": "securePassword"
}
```

---

## Get Current User

### Endpoint

```http id="j8cru9"
GET /api/v1/auth/me
```

### Authentication Required

Yes
