# MongoDB Index Strategy

## Users

Indexes:

```txt id="o5q4je"
studentNumber
email
```

---

## Orders

Indexes:

```txt id="k0vnlx"
studentId
status
createdAt
```

---

## Campus Nodes

Geospatial index:

```txt id="8qdf85"
2dsphere
```

Purpose:
Efficient nearest-node lookup for navigation.

---

## Drone Deliveries

Indexes:

```txt id="ukv6i2"
orderId
status
```
