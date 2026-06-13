# MQTT Topics

## Published by Drone

```txt id="wk5i9u"
drone/telemetry
drone/status
drone/gps
```

---

## Subscribed by Backend

```txt id="j0h14s"
drone/dispatch
drone/return-home
```

---

## Example Payload

```json id="z2vbwb"
{
  "battery": 80,
  "altitude": 5,
  "speed": 2.4
}
```
