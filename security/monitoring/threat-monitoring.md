
---

# 10. `monitoring/threat-monitoring.md`

```md
# Threat Monitoring

## Threat Types

### Unauthorized Access

Detection:

- Invalid JWT
- Multiple failed logins

---

### API Abuse

Detection:

- Rate limiting
- Excessive requests

---

### Drone Security Risks

Detection:

- Signal loss
- GPS anomalies
- Battery failure

---

## Response Strategy

### Low Severity
Log incident.

### Medium Severity
Notify administrators.

### High Severity
Block request and alert admins.