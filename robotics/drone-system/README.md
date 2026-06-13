
# Drone System

This module contains the drone implementation for BC Eats delivery.

## Purpose

The drone system is responsible for:

* Receiving delivery instructions
* Navigating autonomously
* Sending telemetry updates
* Completing deliveries
* Returning safely

---

## Directory Structure

| Folder       | Purpose                      |
| ------------ | ---------------------------- |
| firmware/    | Drone firmware configuration |
| navigation/  | Waypoint and route logic     |
| telemetry/   | GPS and battery monitoring   |
| simulations/ | Drone testing simulations    |
| tests/       | Automated and manual testing |

---

## Delivery Workflow

```txt
Order Confirmed
       │
       ▼
Receive GPS Coordinates
       │
       ▼
Generate Flight Path
       │
       ▼
Take Off
       │
       ▼
Navigate to Student
       │
       ▼
Delivery Complete
       │
       ▼
Return Home
```

---

## Safety Features

Includes:

* Low battery detection
* Return-home mode
* GPS validation
* Delivery cancellation
* Flight monitoring
