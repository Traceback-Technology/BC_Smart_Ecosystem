# System Communication Flow

## Overview

The BC Smart Lifestyle system uses a hybrid communication architecture:

* REST APIs
* WebSockets (Socket.IO)
* MQTT
* HTTP callbacks

---

## REST Communication

REST is used for standard request-response operations.

Examples:

### Authentication

```http id="ul2g0i"
POST /auth/login
```

### Get Menu

```http id="c2xtn2"
GET /orders/menu
```

### Place Order

```http id="ph0gr0"
POST /orders
```

### Calculate Route

```http id="6jqh7q"
POST /navigation/path
```

---

## WebSocket Communication

Socket.IO handles real-time communication.

### Navigation Updates

Client sends:

```txt id="pghm0w"
location:update
```

Server returns:

```txt id="rz5i2r"
navigation:update
```

---

### Order Tracking

Server sends:

```txt id="4eqlzj"
order:update
```

Possible statuses:

* Received
* Preparing
* Ready
* Completed
* Out for Delivery

---

## MQTT Communication

MQTT is used for drone telemetry.

Drone publishes:

```txt id="b77n9v"
drone/telemetry
```

Backend subscribes to:

```txt id="lyx61v"
drone/status
```

---

## Communication Diagram

```txt id="uk0pvl"
Flutter App
      |
      | REST / WebSocket
      v
Node.js Backend
      |
 ---------------------------
 |            |             |
 v            v             v
MongoDB    Drone API      Analytics
                |
                v
            MQTT Broker
```

---

## Why Hybrid Communication?

REST:

* Reliable request-response
* Easier authentication

WebSockets:

* Real-time updates
* Low latency

MQTT:

* Lightweight IoT messaging
* Reliable telemetry
