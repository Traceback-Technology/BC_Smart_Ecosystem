# Control API

This module acts as the communication layer between the backend and the drone system.

## Purpose

The Control API is responsible for:

* Sending drone commands
* Receiving telemetry
* Synchronizing delivery status
* Managing drone lifecycle events

---

## Responsibilities

### Dispatch Commands

Examples:

* Start delivery
* Return home
* Cancel delivery

---

### Telemetry Collection

Receives:

* GPS coordinates
* Battery status
* Altitude
* Speed
* Delivery progress

---

## Communication Architecture

Backend → Drone

Protocols:

* REST API
* MQTT

Drone → Backend

Protocols:

* MQTT
* WebSocket Events

---

## Example Commands

Dispatch:

```json
{
  "orderId": "ORD-001",
  "destination": {
    "latitude": -25.7479,
    "longitude": 28.2293
  }
}
```

Return Home:

```json
{
  "command": "return-home"
}
```
