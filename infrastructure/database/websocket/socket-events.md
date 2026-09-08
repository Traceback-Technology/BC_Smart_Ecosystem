# Socket Events

## Client → Server

### location:update

Used for GPS tracking.

Payload:

```json id="gh0byx"
{
  "latitude": -25.7479,
  "longitude": 28.2293
}
```

---

### order:create

Used when placing an order.

---

## Server → Client

### navigation:update

Updated route data.

### order:update

Order status updates.

Statuses:

* Received
* Preparing
* Ready
* Delivered

### notification

General notifications.
