# BC Ways API

## Base Route

```txt id="e12kbn"
/api/v1/navigation
```

---

## Get Campus Map

### Endpoint

```http id="1laj94"
GET /api/v1/navigation/map
```

### Response

```json id="k9yz1k"
{
  "success": true,
  "data": {
    "buildings": [],
    "paths": [],
    "services": []
  }
}
```

---

## Find Shortest Path

### Endpoint

```http id="ym40pi"
POST /api/v1/navigation/path
```

### Request Body

```json id="j2hz8j"
{
  "startNodeId": 10,
  "destinationNodeId": 24
}
```

### Response

```json id="w4o8n5"
{
  "success": true,
  "data": {
    "path": [10, 12, 18, 24],
    "distance": 120
  }
}
```

---

## Get Nearby Services

### Endpoint

```http id="4b7vzn"
GET /api/v1/navigation/services
```

Query Params:

```txt id="lkrq3n"
?type=tuckshop
```

---

## WebSocket Events

### Live GPS Tracking

Client emits:

```json id="7fc0vf"
{
  "event": "location:update",
  "latitude": -25.7479,
  "longitude": 28.2293
}
```

Server emits:

```json id="1w1mzg"
{
  "event": "navigation:update",
  "updatedPath": []
}
```
