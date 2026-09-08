# Drone API

## Base Route

```txt id="8dgrlf"
/api/v1/drone
```

---

## Dispatch Drone

### Endpoint

```http id="xtxk4w"
POST /api/v1/drone/dispatch
```

### Request Body

```json id="r94lxy"
{
  "orderId": "ORD-001",
  "latitude": -25.7479,
  "longitude": 28.2293
}
```

### Response

```json id="w7l7o2"
{
  "success": true,
  "message": "Drone dispatched"
}
```

---

## Drone Status

### Endpoint

```http id="vhv36w"
GET /api/v1/drone/status/:id
```

### Response

```json id="jpn18g"
{
  "battery": 85,
  "status": "In Transit",
  "gps": {
    "lat": -25.7479,
    "lng": 28.2293
  }
}
```

---

## Telemetry WebSocket

Drone emits:

```json id="btr2tz"
{
  "event": "drone:telemetry",
  "battery": 80,
  "altitude": 6,
  "speed": 2.5
}
```

Server emits:

```json id="rxj9rw"
{
  "event": "drone:return-home"
}
```
