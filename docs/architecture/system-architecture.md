# System Architecture

## Overview

BC Smart Lifestyle is a centralized smart-campus platform designed to modernize navigation and tuckshop services at Belgium Campus.

The system consists of two major modules:

### BC Ways

Campus navigation and routing system.

### BC Eats

Digital tuckshop ordering and delivery system.

---

## High-Level Architecture

```txt id="y7zq5u"
+---------------------------------------------------+
|                   Client Layer                    |
|---------------------------------------------------|
| Flutter Mobile App | Visitor Web Access (QR)     |
+---------------------+-----------------------------+
                      |
                      | REST + WebSocket
                      v
+---------------------------------------------------+
|                  Backend Layer                    |
|---------------------------------------------------|
| Express.js API | Socket.IO | Authentication       |
| Order Logic | Pathfinding | Notifications         |
+---------------------------------------------------+
                      |
        ---------------------------------
        |               |               |
        v               v               v
+----------------+ +----------------+ +----------------+
|   MongoDB      | | Drone Control  | | Analytics      |
| Database       | | API            | | Monitoring     |
+----------------+ +----------------+ +----------------+
```

---

## Frontend Layer

Technology:

* Flutter (Dart)

Responsibilities:

* User authentication
* Campus navigation
* Food ordering
* Real-time order tracking
* Visitor QR access

---

## Backend Layer

Technology:

* Node.js
* Express.js
* TypeScript
* Socket.IO

Responsibilities:

* Authentication
* Navigation path computation
* Order processing
* Drone dispatch
* Notification handling

---

## Data Layer

Technology:

* MongoDB

Responsibilities:

* Store user data
* Store map graph nodes
* Manage orders
* Track drone dispatch records

---

## Robotics Layer

Technology:

* Pixhawk 4
* ArduPilot
* GPS Navigation

Responsibilities:

* Autonomous food delivery
* Telemetry reporting
* Return-to-home behavior

---

## Design Principles

The architecture follows:

### Separation of Concerns

Each module has independent responsibilities.

### Modularity

Features can evolve independently.

### Scalability

Real-time systems support concurrent users.

### Maintainability

Shared utilities reduce duplication.
