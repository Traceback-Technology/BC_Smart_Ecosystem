# ADR 0003: Navigation Algorithm

**Status:** Accepted
**Date:** 2026-06-12

---

## Context

BC Ways requires shortest-path navigation between campus locations.

The algorithm must:

* Compute optimal pedestrian routes
* Support rerouting
* Operate efficiently on campus-scale maps

---

## Decision

The system will use **Dijkstra's Algorithm** for shortest-path computation.

Campus locations will be represented as graph nodes.

Edges between nodes represent walkable paths.

---

## Alternatives Considered

### A* Algorithm

Pros:

* Faster in large graphs

Cons:

* Requires heuristics

### Breadth-First Search

Pros:

* Simple

Cons:

* Poor weighted path handling

### Dijkstra (Chosen)

Pros:

* Guaranteed shortest path
* Easy to implement
* Suitable for campus map size

Cons:

* Less efficient at large scale

---

## Consequences

### Positive

* Reliable shortest path
* Predictable routing

### Negative

* Potential performance limitations in very large maps
