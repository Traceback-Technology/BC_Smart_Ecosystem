# ADR 0004: Drone Delivery Architecture

**Status:** Proposed
**Date:** 2026-06-12

---

## Context

BC Eats includes experimental food delivery using autonomous drones.

The system requires:

* GPS waypoint navigation
* Delivery confirmation
* Fail-safe return behavior

---

## Decision

The project will integrate:

* Pixhawk 4
* ArduCopter firmware
* NEO-M8N GPS module
* Backend GPS dispatching

The backend sends coordinates to the drone control interface.

Drone status updates are returned to the backend.

Simulation will be performed using:

* ArduPilot SITL
* Gazebo

---

## Alternatives Considered

### Manual Delivery

Pros:

* Lower risk

Cons:

* Does not meet innovation goals

### Autonomous Drone (Chosen)

Pros:

* Innovative
* Demonstrates IoT integration

Cons:

* Hardware cost
* Safety concerns

---

## Consequences

### Positive

* Strong innovation component
* Demonstrable prototype

### Negative

* Hardware dependency
* Regulatory considerations
