# BC Eats API

## Base Route

```txt id="b0p2jz"
/api/v1/orders
```

---

## Get Menu

### Endpoint

```http id="3ql54i"
GET /api/v1/orders/menu
```

### Response

```json id="xwdxtf"
{
  "success": true,
  "data": [
    {
      "id": "1",
      "name": "Burger",
      "price": 55
    }
  ]
}
```

---

## Create Order

### Endpoint

```http id="h6i0s5"
POST /api/v1/orders
```

### Request Body

```json id="h90l31"
{
  "items": [
    {
      "menuItemId": "1",
      "quantity": 2
    }
  ],
  "deliveryMethod": "drone"
}
```

### Response

```json id="x3q9ep"
{
  "success": true,
  "orderId": "ORD-001",
  "status": "Received"
}
```

---

## Get Order Status

### Endpoint

```http id="g8qgzs"
GET /api/v1/orders/:id
```

### Response

```json id="n6d4i0"
{
  "success": true,
  "status": "Preparing"
}
```

---

## WebSocket Events

### Order Updates

Server emits:

```json id="1brn0s"
{
  "event": "order:update",
  "status": "Ready"
}
```
