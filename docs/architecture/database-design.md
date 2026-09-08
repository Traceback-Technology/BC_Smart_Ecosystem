# Database Design

## Database Technology

Database:

* MongoDB

Reason:

* Flexible document schema
* Geospatial support
* Easy scaling

---

## Collections

### Users

```json id="9m5kgk"
{
  "_id": "ObjectId",
  "studentNumber": "577168",
  "name": "Ryan",
  "email": "student@bcstudent.be",
  "role": "student",
  "passwordHash": "hashed_password"
}
```

---

### Campus Nodes

Used for BC Ways navigation.

```json id="8mn3a8"
{
  "_id": "ObjectId",
  "nodeId": 1,
  "coordinates": {
    "type": "Point",
    "coordinates": [28.2293, -25.7479]
  },
  "neighbors": [
    {
      "nodeId": 2,
      "weight": 15
    }
  ]
}
```

---

### Menu Items

```json id="v5i7g7"
{
  "_id": "ObjectId",
  "name": "Burger",
  "price": 55,
  "available": true
}
```

---

### Orders

```json id="w1hzsq"
{
  "_id": "ObjectId",
  "studentId": "123",
  "items": [],
  "status": "Preparing",
  "deliveryMethod": "drone",
  "createdAt": "timestamp"
}
```

---

### Drone Deliveries

```json id="pkf96l"
{
  "_id": "ObjectId",
  "orderId": "ORD001",
  "status": "In Transit",
  "gps": {},
  "battery": 80
}
```

---

## Indexing Strategy

Indexes:

### Users

```txt id="efh7xq"
studentNumber
email
```

### Navigation

```txt id="tv81m2"
2dsphere geospatial index
```

### Orders

```txt id="zb3j0z"
studentId
status
createdAt
```
