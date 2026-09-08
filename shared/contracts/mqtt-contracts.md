# MQTT Contracts

## Topic: drone/telemetry

Payload:

```json id="5c9xtk"
{
  "battery": 80,
  "altitude": 6,
  "speed": 2.5,
  "gps": {
    "lat": -25.7479,
    "lng": 28.2293
  }
}
```

---

## Topic: drone/dispatch

Payload:

```json id="k6vth0"
{
  "orderId": "ORD-001",
  "destination": {
    "lat": -25.7479,
    "lng": 28.2293
  }
}
```

---

## Topic: drone/return-home

Payload:

```json id="lph4ql"
{
  "trigger": "low-battery"
}
```
