# WebSocket Contracts

## Navigation Update

Event:

```txt id="0m6dgo"
navigation:update
```

Payload:

```json id="fzt0pp"
{
  "path": [],
  "distance": 120
}
```

---

## Location Update

Event:

```txt id="v0pwgy"
location:update
```

Payload:

```json id="3zz0u8"
{
  "latitude": -25.7479,
  "longitude": 28.2293
}
```

---

## Order Update

Event:

```txt id="4svh0k"
order:update
```

Payload:

```json id="f0vgkr"
{
  "status": "Preparing"
}
```

---

## Drone Telemetry

Event:

```txt id="k9l7tw"
drone:telemetry
```

Payload:

```json id="m7c5wy"
{
  "battery": 85,
  "speed": 2.4,
  "altitude": 4
}
```
