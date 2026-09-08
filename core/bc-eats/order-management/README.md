# Order Management

This module manages the order lifecycle.

## Responsibilities

Includes:

* Order creation
* Status updates
* Order tracking
* Order history

---

## Order Status Flow

```txt
Received
    │
    ▼
Preparing
    │
    ▼
Ready
    │
 ┌──┴─────────┐
 ▼            ▼
Collected   Drone Delivery
```
