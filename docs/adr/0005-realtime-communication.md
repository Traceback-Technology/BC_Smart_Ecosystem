# ADR 0005: Real-Time Communication

**Status:** Accepted
**Date:** 2026-06-12

---

## Context

BC Smart Lifestyle requires live updates for:

* GPS navigation
* Order status tracking
* Drone telemetry
* Notifications

Traditional REST polling introduces latency.

---

## Decision

The system will use:

* REST APIs for request-response operations
* Socket.IO WebSockets for real-time updates
* MQTT for hardware communication

---

## Alternatives Considered

### REST Polling

Pros:

* Simple

Cons:

* High latency
* Inefficient

### WebSockets (Chosen)

Pros:

* Real-time
* Low latency
* Bidirectional communication

Cons:

* More infrastructure complexity

---

## Consequences

### Positive

* Smooth real-time experience
* Efficient updates

### Negative

* More complex debugging
