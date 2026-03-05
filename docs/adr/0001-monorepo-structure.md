# ADR 0001: Monorepo Structure

## Status
Accepted

---

## Context

The Smart Campus Ecosystem includes:

- Platform application
- Robotics systems (Drone + Rover)
- Security services
- Real-time simulation
- Analytics components

We require clear architecture governance and centralized integration.

---

## Decision

We will use a monorepo structure with domain-based folder separation.

Each subsystem will exist within its own top-level directory.

---

## Alternatives Considered

1. Multiple repositories per subsystem
   - Pros: Isolation
   - Cons: Harder integration, fragmented CI

2. Hybrid model
   - Pros: Flexible
   - Cons: Increased complexity for student team

---

## Consequences

### Positive
- Unified CI/CD
- Easier integration testing
- Centralized governance

### Negative
- Larger repository size
- Requires strong code ownership rules