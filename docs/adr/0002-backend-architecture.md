# ADR 0002: Backend Architecture

**Status:** Accepted
**Date:** 2026-06-12

---

## Context

The system requires:

* Real-time navigation updates
* Order lifecycle management
* Drone dispatch communication
* Multiple simultaneous users

The backend must support both RESTful APIs and persistent real-time communication.

---

## Decision

The backend will use:

* **Node.js**
* **Express.js**
* **TypeScript**
* **Socket.IO**
* **MongoDB**

Architecture structure:

```txt
/routes
/controllers
/services
/models
/sockets
/middleware
```

### Reasoning

Node.js provides asynchronous non-blocking I/O suitable for:

* GPS tracking
* Real-time updates
* Concurrent users

TypeScript reduces runtime errors in a multi-developer environment.

MongoDB supports flexible schemas and geospatial indexing.

---

## Alternatives Considered

### Java Spring Boot

Pros:

* Enterprise stability

Cons:

* Higher learning curve
* Slower iteration

### ASP.NET

Pros:

* Strong typing

Cons:

* Less familiarity in team

### Node.js + Express (Chosen)

Pros:

* Fast development
* Strong real-time support
* Large ecosystem

Cons:

* Requires disciplined architecture

---

## Consequences

### Positive

* Real-time support
* Faster development
* Easier frontend integration

### Negative

* Requires strict typing discipline
